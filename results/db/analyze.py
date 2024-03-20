from db.models import Report, RopReport, Limits
from db.output import SYSCALLS_SECSENS, SYSCALLS_FDCONF
from django.db.models import Count
from django import db
import struct
from tqdm import tqdm
import os.path
from pygdbmi.gdbcontroller import GdbController
from pygdbmi.constants import GdbTimeoutError
import multiprocessing.pool as mpool
import atexit
from time import sleep

DISABLE_PROGRESS_BAR_FOR_ANALYSIS = False
DISABLE_PROGRESS_BAR_PER_CORE = True

NUM_THREADS_PER_PROC = 32
GDB_MAX_TIMEOUTS = 10
GDB_TIMEOUT_SECS = 10

def EXIT_ERR(msg=""):
    if msg: print(msg)
    terminate_all_processes()
    close_all_gdbinsts()
    os._exit(1)

ppool = None
def terminate_all_processes():
    global ppool
    if ppool:
        print("Terminating all processes...")
        ppool.terminate()

################################################################
############################
#### Core management

ERR_VAL = float('inf')
WAIT_VAL = float('-inf')
LEN_CORE_READ = 32
assert LEN_CORE_READ > Limits.MATCH_LEN_MAX

corevals = {}
def is_in_corevals(addr, core): return addr in corevals[core]
def get_coreval(addr, core):
    while corevals[core][addr] == WAIT_VAL: sleep(0.2) # TODO: A better way of checking this
    return corevals[core][addr]
def add_to_corevals(addr, val, core): corevals[core][addr] = val

corestrs = {}
def is_in_corestrs(addr, core): return addr in corestrs[core]
def get_corestr(addr, core): return corestrs[core][addr]
def add_to_corestrs(addr, str, core): corestrs[core][addr] = str

gdbinsts = {}

def core_analysis_init(core):
    atexit.register(close_all_gdbinsts)
    if core == "": return
    global corevals, corestrs, gdbinsts
    if core in corevals or core in corestrs or core in gdbinsts: return # We've already started analyzing this core
    corevals[core] = {}
    corestrs[core] = {}
    gdbinsts[core] = []
    for i in range(NUM_THREADS_PER_PROC):
        # Create NUM_THREADS_PER_PROC gdb instances
        gdbinsts[core].append(GdbController())
        gdbinsts[core][i].write("core-file " + core, timeout_sec=5)
    sleep(6) # Lets these gdbinsts finish starting up. Otherwise, our first queries to the gdbinsts will receive startup messages rather than the query's result messages.

def core_analysis_done(core):
    if core == "": return
    global corevals, corestrs, gdbinsts
    for this_gdbinst in gdbinsts[core]:
        # Delete NUM_THREADS_PER_PROC gdb instances
        this_gdbinst.exit()
        del(this_gdbinst)
    del(gdbinsts[core])
    del(corevals[core])
    del(corestrs[core])

def close_all_gdbinsts():
    global gdbinsts
    for core in list(gdbinsts.keys()):
        print("Closing gdbinst for core " + core)
        core_analysis_done(core)

curr_gdb_inst = 0

def make_gdb_query(core, query):
    global curr_gdb_inst
    my_gdb_inst = curr_gdb_inst
    curr_gdb_inst = (curr_gdb_inst + 1) % NUM_THREADS_PER_PROC
    timeout_count = 0
    while timeout_count < GDB_MAX_TIMEOUTS:
        try:
            return gdbinsts[core][my_gdb_inst].write(query, timeout_sec=GDB_TIMEOUT_SECS)
        except GdbTimeoutError:
            timeout_count = timeout_count + 1
            print("GDB query timed out (timeout #" + str(timeout_count) + "). Trying again. (core: '" + core + "', query: '" + query + "')")
    EXIT_ERR("Error: GDB query timed out " + str(timeout_count) + " times. (core: " + core + ")")

############################
#### Core lookup

def core_addr_lookup(addr, core):
    if core == "": return ERR_VAL
    if is_in_corevals(addr, core): return get_coreval(addr, core)
    for i in range(0,LEN_CORE_READ-Limits.MATCH_LEN_MAX): add_to_corevals(addr + i, WAIT_VAL, core)
    tmpress = make_gdb_query(core, "-data-read-memory-bytes " + hex(addr) + " " + str(LEN_CORE_READ))

    bighex = None
    for tmpres in tmpress:
        try:
            bighex = tmpres['payload']['memory'][0]['contents']
        except:
            continue
        if bighex != None: break
    if bighex == None:
        print("Error looking up value in core: core_addr_lookup(" + hex(addr) + ", '" + core + "') yields " + str(tmpress))
        add_to_corevals(addr, ERR_VAL, core)
        return ERR_VAL

    vals_list = bytes.fromhex(bighex)
    for i in range(0,LEN_CORE_READ-Limits.MATCH_LEN_MAX): add_to_corevals(addr + i, vals_list[i:i+Limits.MATCH_LEN_MAX], core)
    vals_list += b'0' * (Limits.MATCH_LEN_MAX - len(vals_list)) # Pad with zeros up to length Limits.MATCH_LEN_MAX
    return vals_list

def core_addr_lookup_qword(addr, core):
    vals_list = core_addr_lookup(addr, core)
    if vals_list == ERR_VAL: return ERR_VAL
    vals_sublist = vals_list[0:8]
    return struct.unpack('<Q', vals_sublist)[0]
def core_addr_lookup_byte(addr, core):
    vals_list = core_addr_lookup(addr, core)
    if vals_list == ERR_VAL: return ERR_VAL
    vals_sublist = vals_list[0:1]
    return struct.unpack('<B', vals_sublist)[0]

def core_addr_has_byte(addr, exp_val, core):
    found_val = core_addr_lookup_byte(addr, core)
    if found_val == ERR_VAL: return False
    return found_val == exp_val

def core_addr_has_bytes(addr, exp_vals, core, ptr_depth_limit):
    if len(exp_vals) > Limits.MATCH_LEN_MAX: EXIT_ERR("Error: len(exp_vals) (" + str(len(exp_vals)) + ") should be less than or equal to Limits.MATCH_LEN_MAX (" + str(Limits.MATCH_LEN_MAX) + ")")
    found_vals_all = core_addr_lookup(addr, core)
    if found_vals_all == ERR_VAL: return False

    #print("Checking whether *" + hex(addr) + " == " + hex(int.from_bytes(found_vals_all[0:len(exp_vals)], 'little')) + " is equal to " + hex(int.from_bytes(exp_vals, 'little')))
    #print("   i.e., whether *" + hex(addr) + " == " + str(found_vals_all[0:len(exp_vals)]) + " is equal to " + str(exp_vals))

    # We found our value!
    if found_vals_all[0:len(exp_vals)] == exp_vals: return True

    # We're done following pointers
    if ptr_depth_limit == 0: return False

    # If this is a pointer, follow it
    found_vals_qword = core_addr_lookup_qword(addr, core)
    if found_vals_qword >= 0x7fff00000000 and found_vals_qword < 0x800000000000:
        return core_addr_has_bytes(found_vals_qword, exp_vals, core, ptr_depth_limit - 1)
    return False

####
# TODO:
# - Check if val is a pointer and if so, follow it up to N times.
#       I.e., let's be aggressive, because we need this for load ptr prop (e.g., for format strings that use a tainted pointer for %s).
# - Also, if val is a pointer, then perhaps don't even check if its 1-byte val (i.e., the lowest byte) equals our byte.
#       I.e., let's be conservative, under the assumption that the other bytes would have a dataflow too, if necessary (?).
# - Perhaps copy custom_get_core_str() but without all the extra string stuff?

################################################################
############################
#### get_iflow_of_len

# Adapted from has_iflow_of_len(), with differences where NOTE'ed
def get_iflow_of_len(tarr, arr, core, limits, type):
    if len(tarr) != len(arr): EXIT_ERR("Error: Expected len(tarr) (" + str(len(tarr)) + ") == len(arr) (" + str(len(arr)) + ")")
    if len(tarr) == 0: return []
    sub_tarrs = sublists(tarr, limits['match_len'])
    sub_arrs = sublists(arr, limits['match_len'])
    for sub_tarr, sub_arr in zip(sub_tarrs,sub_arrs):
        tagset = sub_tarr[0] # TODO: We're only looking at the first tagset of the sublist
        if tagset == "FULL" or tagset == [] or len(tagset) > limits['tags_per_tagset']: continue
        if not vals_are_interesting(sub_arr): continue
        for tag in tagset:
            # TODO: Check up to the pointer depth given by limits['ptr_depth_limit']. We're only trying pointer depths 0 and 1 for now.
            # TODO/NOTE: We're only returning the FIRST match, not ALL matches
            if core_addr_has_bytes(tag, sub_arr, core, 0): return [{'type':type, 'addr':tag, 'vals':sub_arr, 'ptr_depth':0}]
            if core_addr_has_bytes(tag, sub_arr, core, 1): return [{'type':type, 'addr':tag, 'vals':sub_arr, 'ptr_depth':1}]
    return [] # NOTE

############################
#### get_iflows

def get_iflows_fd_creator(arg, core, limits): return [] # TODO: Get iflows for gadget chains

def get_iflows_dword(arg, core, limits):
    return get_iflow_of_len(arg['dword_taint'], arg['dword'].to_bytes(4,'little'), core, Limits.lmax(limits, max_match_len=4), 'dword')

def get_iflows_qword(arg, core, limits, prefix):
    return get_iflow_of_len(arg['qword_taint'], arg['qword'].to_bytes(8,'little'), core, Limits.lmax(limits, max_match_len=8), prefix + 'qword')

def get_iflows_vptr(arg, core, limits, prefix):
    return get_iflows_qword(arg, core, Limits.lset(limits, new_match_len=8), prefix + 'vptr_') + \
        get_iflow_of_len(arg['buf_taint'], bytes(arg['buf']), core, Limits.lmax(limits, max_match_len=len(arg['buf'])), prefix + 'vptr_buf')

def get_iflows_ppchar(arg, core, limits):
    fl = get_iflows_qword(arg, core, Limits.lset(limits, new_match_len=8), 'ppchar_')
    for pchar in arg['pchars']: fl = fl + get_iflows_vptr(pchar, core, limits, 'ppchar_')
    return fl

def get_iflows_iovec(arg, core, limits):
    fl = get_iflows_qword(arg, core, Limits.lset(limits, new_match_len=8), 'iovec_')
    for vptr in arg['vptrs']: fl = fl + get_iflows_vptr(vptr, core, limits, 'iovec_')
    return fl

def get_iflows_handler(arg, core, limits):
    t = arg['type']
    match t:
        case "IOVEC": return get_iflows_iovec(arg, core, limits)
        case "PPCHAR": return get_iflows_ppchar(arg, core, limits)
        case "VPTR": return get_iflows_vptr(arg, core, limits, '')
        case "QWORD": return get_iflows_qword(arg, core, limits, '')
        case "DWORD": return get_iflows_dword(arg, core, limits) # NOTE: We get chained iflows in rewrite eval
    print("Error: Unhandled type " + t)
    return set()

def get_iflows(arg, core, limits):
    fl_dup = get_iflows_handler(arg, core, limits)
    fl = [dict(y) for y in set(tuple(x.items()) for x in fl_dup)] # Deduplicate flows in fl_dup
    for f in fl: f.update({'vals': list(f['vals'])}) # Convert bytearray to int array (so that it is proper JSON)
    return fl

################################################################
############################
#### Report chaining lookup

def get_report(report_num, core, ids):
    pid, ppid, tid, ptid = ids

    # The previous 'chained' report came from this thread
    try: return Report.objects.get(report_num=report_num,application_corepath=core,pid=pid,ppid=ppid,tid=tid,ptid=ptid)
    except Report.MultipleObjectsReturned: EXIT_ERR("Error: Multiple reports with report_num:" + str(report_num) + ", core:\"" + core + "\", pid:" + str(pid) + ", ppid:" + str(ppid) + ", tid:" + str(tid) + ", ptid:" + str(ptid))
    except Report.DoesNotExist: pass

    # The previous 'chained' report came from another thread
    try: return Report.objects.get(report_num=report_num,application_corepath=core,pid=pid,ppid=ppid)
    except Report.MultipleObjectsReturned: EXIT_ERR("Error: Multiple reports with report_num:" + str(report_num) + ", core:\"" + core + "\", pid:" + str(pid) + ", ppid:" + str(ppid))
    except Report.DoesNotExist: pass

    # The previous 'chained' report came from the parent process
    try: return Report.objects.get(report_num=report_num,application_corepath=core)
    except Report.DoesNotExist: pass
    # EXIT_ERR("Error: Cannot find report with report_num:" + str(report_num) + ", core:\"" + core + "\"")

    try: return Report.objects.get(report_num=report_num)
    except Report.MultipleObjectsReturned: EXIT_ERR("Error: Multiple reports with report_num:" + str(report_num))
    except Report.DoesNotExist: EXIT_ERR("Error: Cannot find report with report_num:" + str(report_num))

def report_has_iflow_arg(r, arg_num, limits):
    b = r.get_iflow(arg_num, limits['eval_field'], limits['eval_val'])
    if b == None: EXIT_ERR("Error: Chained to report that hasn't been analyzed yet:" + str(r))
    return b

def report_has_iflow(report_num, core, limits, ids):
    if report_num == 0: return False
    r = get_report(report_num, core, ids)
    return report_has_iflow_arg(r, 0, limits) or report_has_iflow_arg(r, 1, limits) or  report_has_iflow_arg(r, 2, limits) or \
           report_has_iflow_arg(r, 3, limits) or report_has_iflow_arg(r, 4, limits) or  report_has_iflow_arg(r, 5, limits)

############################
#### Report chaining callers

def has_iflow_fd_creator(fd_creators, core, limits, ids):
    for fd_creator in fd_creators:
        if report_has_iflow(fd_creator['report_num'], core, limits, ids): return True
    return False

################################################################
############################
#### Helpers

def val_is_interesting(val):
    # These values lead to high FPs
    return val != 0 and val != 0xff and val != 0x7f

def vals_are_interesting(vals):
    for val in vals:
        if val_is_interesting(val): return True
    return False

def sublists(list, sublist_len):
    return [list[pos:pos + sublist_len] for pos in range(0, len(list) - sublist_len + 1)]

############################
#### has_iflowtag generic

def has_iflow_of_len(tarr, arr, core, limits):
    if len(tarr) != len(arr): EXIT_ERR("Error: Expected len(tarr) (" + str(len(tarr)) + ") == len(arr) (" + str(len(arr)) + ")")
    if len(tarr) == 0: return False
    sub_tarrs = sublists(tarr, limits['match_len'])
    sub_arrs = sublists(arr, limits['match_len'])
    for sub_tarr, sub_arr in zip(sub_tarrs,sub_arrs):
        tagset = sub_tarr[0] # TODO: We're only looking at the first tagset of the sublist
        if tagset == "FULL" or tagset == [] or len(tagset) > limits['tags_per_tagset']: continue
        if not vals_are_interesting(sub_arr): continue
        for tag in tagset:
            if core_addr_has_bytes(tag, sub_arr, core, limits['ptr_depth_limit']):
                return True
    return False

################################
#### has_iflow of type

def has_iflow_qword(arg, core, limits):
    return has_iflow_of_len(arg['qword_taint'], arg['qword'].to_bytes(8,'little'), core, Limits.lmax(limits, max_match_len=8))

def has_iflow_dword(arg, core, limits, ids):
    argval_has_iflow = has_iflow_of_len(arg['dword_taint'], arg['dword'].to_bytes(4,'little'), core, Limits.lmax(limits, max_match_len=4))
    if 'fd_creators' not in arg: return argval_has_iflow # This is just a normal dword arg
    if argval_has_iflow: return has_iflow_fd_creator(arg['fd_creators'], core, limits, ids) # This may be an indirectly-controllable FD (i.e., we can check _any_ fd_creator)
    return has_iflow_fd_creator([arg['this_fd_arg']], core, limits, ids) # This can only be a directly-controllable FD (i.e., we can _only_ check this_fd_arg)

def has_iflow_vptr(arg, core, limits):
    return has_iflow_qword(arg, core, Limits.lset(limits, new_match_len=8)) or \
        has_iflow_of_len(arg['buf_taint'], bytes(arg['buf']), core, Limits.lmax(limits, max_match_len=len(arg['buf'])))

def has_iflow_ppchar(arg, core, limits):
    if has_iflow_qword(arg, core, Limits.lset(limits, new_match_len=8)): return True
    if len(arg['pchars']) == 0: return False
    for pchar in arg['pchars']:
        if has_iflow_vptr(pchar, core, limits): return True
    return False

def has_iflow_iovec(arg, core, limits):
    if has_iflow_qword(arg, core, Limits.lset(limits, new_match_len=8)): return True
    for vptr in arg['vptrs']:
        if has_iflow_vptr(vptr, core, limits): return True
    return False

def has_iflow(arg, core, limits, ids):
    t = arg['type']
    match t:
        case "IOVEC": return has_iflow_iovec(arg, core, limits)
        case "PPCHAR": return has_iflow_ppchar(arg, core, limits)
        case "VPTR": return has_iflow_vptr(arg, core, limits)
        case "QWORD": return has_iflow_qword(arg, core, limits)
        case "DWORD": return has_iflow_dword(arg, core, limits, ids)
    print("Error: Unhandled type " + t)
    return False

################################################################
############################
#### Helper

def has_taint_fd_creator(fd_creators):
    for fd_creator in fd_creators:
        if fd_creator['report_num'] != 0: return True
    return False

############################
#### has_taint*

def tagn_has_any_tag(tarr):
    for t in tarr:
        if len(t) != 0: return True
    return False

def has_taint_qword(arg):
    return tagn_has_any_tag(arg['qword_taint'])

def has_taint_dword(arg):
    argval_has_taint = tagn_has_any_tag(arg['dword_taint'])
    if 'fd_creators' not in arg: return argval_has_taint # This is just a normal dword arg
    if argval_has_taint: return has_taint_fd_creator(arg['fd_creators']) # This may be an indirectly-controllable FD (i.e., we can check _any_ fd_creator)
    return has_taint_fd_creator([arg['this_fd_arg']]) # This can only be a directly-controllable FD (i.e., we can _only_ check this_fd_arg)

def has_taint_vptr(arg):
    return has_taint_qword(arg) or \
        tagn_has_any_tag(arg['buf_taint'])

def has_taint_ppchar(arg):
    if has_taint_qword(arg): return True
    for pchar in arg['pchars']:
        if has_taint_vptr(pchar): return True
    return False

def has_taint_iovec(arg):
    if has_taint_qword(arg): return True
    for vptr in arg['vptrs']:
        if has_taint_vptr(vptr): return True
    return False

def has_taint(arg):
    t = arg['type']
    match t:
        case "IOVEC": return has_taint_iovec(arg)
        case "PPCHAR": return has_taint_ppchar(arg)
        case "VPTR": return has_taint_vptr(arg)
        case "QWORD": return has_taint_qword(arg)
        case "DWORD": return has_taint_dword(arg)
        case "none": return False
    print("Error: Unhandled type " + t)
    return False

################################################################

def analyze_syscall_arg(r, argnum):
    syscall_args = r.syscall_args
    if argnum >= len(syscall_args) or not r.tainted:
        # This argnum is outside the range of args, so set all flags to false
        r.arg_taint(argnum, False)
        r.arg_no_iflow(argnum)
        return
    arg = syscall_args[argnum]

    any_taint = has_taint(arg)
    r.arg_taint(argnum, any_taint)
    if not any_taint:
        r.arg_no_iflow(argnum)
        return

    if not os.path.isfile(r.application_corepath):
        print("Error: Cannot analyze iflow for report because because its core dump does not exist at: " + r.application_corepath)
        return

    # First, let's simply check whether there is an iflow for different limits
    for match_len in range(Limits.MATCH_LEN_MIN,Limits.MATCH_LEN_MAX+1):
        iflow = has_iflow(arg, r.application_corepath, Limits.lnew(match_len, Limits.PTR_DEPTH_LIMIT_DEFAULT, Limits.TAGS_PER_TAGSET_DEFAULT, 'match_len', match_len), (r.pid, r.ppid, r.tid, r.ptid))
        r.arg_iflow(argnum, iflow, 'match_len', match_len)
    for ptr_depth_limit in range(Limits.PTR_DEPTH_LIMIT_MIN,Limits.PTR_DEPTH_LIMIT_MAX+1):
        iflow = has_iflow(arg, r.application_corepath, Limits.lnew(Limits.MATCH_LEN_DEFAULT, ptr_depth_limit, Limits.TAGS_PER_TAGSET_DEFAULT, 'ptr_depth_limit', ptr_depth_limit), (r.pid, r.ppid, r.tid, r.ptid))
        r.arg_iflow(argnum, iflow, 'ptr_depth_limit', ptr_depth_limit)
    for tags_per_tagset in range(Limits.TAGS_PER_TAGSET_MIN,Limits.TAGS_PER_TAGSET_MAX+1):
        iflow = has_iflow(arg, r.application_corepath, Limits.lnew(Limits.MATCH_LEN_DEFAULT, Limits.PTR_DEPTH_LIMIT_DEFAULT, tags_per_tagset, 'tags_per_tagset', tags_per_tagset), (r.pid, r.ppid, r.tid, r.ptid))
        r.arg_iflow(argnum, iflow, 'tags_per_tagset', tags_per_tagset)

    # Second, let's get the full list of iflows
    if r.get_iflow(argnum, 'match_len', Limits.MATCH_LEN_GET_IFLOWS):
        fl = get_iflows(arg, r.application_corepath, Limits.lnew(Limits.MATCH_LEN_GET_IFLOWS, Limits.PTR_DEPTH_LIMIT_DEFAULT, Limits.TAGS_PER_TAGSET_DEFAULT, 'match_len', Limits.MATCH_LEN_GET_IFLOWS))
        r.set_iflows_list(argnum, fl)

def analyze_syscall(r):
    r.has_syscallnr_taint = tagn_has_any_tag(r.syscall_nr_taint)
    for i in range(0, 6):
        analyze_syscall_arg(r, i)
    r.done_analyzing = True

################################################################

def analyze_fd_reports_from_core(core):
    db.connections.close_all() # Not sure if this is necessary. Just trying to avoid hitting max_connections...

    # Analyze "fd creating" syscalls sequentially
    rs = Report.objects.filter(done_analyzing=False,tainted=True,application_corepath=core,syscall__in=SYSCALLS_FDCONF).order_by('application_corepath', 'ppid', 'pid', 'report_num')
    COUNT = rs.count()
    if COUNT == 0: return
    core_analysis_init(core)

    for r in tqdm(rs, desc="fd-creating:"+core, total=COUNT, disable=DISABLE_PROGRESS_BAR_PER_CORE):
        analyze_syscall(r)
        r.save()

    core_analysis_done(core)
    db.connections.close_all() # Not sure if this is necessary. Just trying to avoid hitting max_connections...

def analyze_sec_reports_from_core(core):
    db.connections.close_all() # Not sure if this is necessary. Just trying to avoid hitting max_connections...

    rs = Report.objects.filter(done_analyzing=False,tainted=True,application_corepath=core,syscall__in=SYSCALLS_SECSENS).order_by('application_corepath', 'ppid', 'pid', 'report_num')
    COUNT = rs.count()
    if COUNT == 0: return
    core_analysis_init(core)

    # Analyze "sec sensitive" syscalls in parallel
    systpool = mpool.ThreadPool(NUM_THREADS_PER_PROC)
    for _ in tqdm(systpool.imap_unordered(analyze_syscall, rs), desc="sec-sensitive:"+core, total=COUNT, disable=DISABLE_PROGRESS_BAR_PER_CORE): pass
    systpool.terminate()
    Report.objects.bulk_update(rs, ['has_syscallnr_taint',
        'has_arg0_taint', 'has_arg0_iflow', 'arg0_iflows_list',
        'has_arg1_taint', 'has_arg1_iflow', 'arg1_iflows_list',
        'has_arg2_taint', 'has_arg2_iflow', 'arg2_iflows_list',
        'has_arg3_taint', 'has_arg3_iflow', 'arg3_iflows_list',
        'has_arg4_taint', 'has_arg4_iflow', 'arg4_iflows_list',
        'has_arg5_taint', 'has_arg5_iflow', 'arg5_iflows_list',
        'done_analyzing'], batch_size=1000)
    core_analysis_done(core)
    db.connections.close_all() # Not sure if this is necessary. Just trying to avoid hitting max_connections...

def analyze_untainted_reports():
    rs = Report.objects.filter(tainted=False,done_analyzing=False)
    print("Updating " + str(rs.count()) + " untainted reports...")
    limits_tbl = {'match_len': [False for i in range(Limits.MATCH_LEN_MAX+1)],
                  'ptr_depth_limit': [False for i in range(Limits.PTR_DEPTH_LIMIT_MAX+1)],
                  'tags_per_tagset': [False for i in range(Limits.TAGS_PER_TAGSET_MAX+1)]}
    rs.update(has_syscallnr_taint=False,
              has_arg0_taint=False, has_arg0_iflow=limits_tbl,
              has_arg1_taint=False, has_arg1_iflow=limits_tbl,
              has_arg2_taint=False, has_arg2_iflow=limits_tbl,
              has_arg3_taint=False, has_arg3_iflow=limits_tbl,
              has_arg4_taint=False, has_arg4_iflow=limits_tbl,
              has_arg5_taint=False, has_arg5_iflow=limits_tbl,
              done_analyzing=True)

################################################################

def print_cores_counts_exit(cores_counts):
    for cc in cores_counts: print(str(cc))
    EXIT_ERR("Done")

def analyze_reports(nproc):
    atexit.register(close_all_gdbinsts)
    atexit.register(terminate_all_processes)

    # Print status
    NUM_REPORTS = Report.objects.count()
    num_analyzed = Report.objects.filter(done_analyzing=True).count()
    print("Already analyzed " + str(num_analyzed) + " / " + str(NUM_REPORTS) + " reports")

    # First, update the untainted reports (requires no actual analysis)
    analyze_untainted_reports()
    num_analyzed = Report.objects.filter(done_analyzing=True).count()
    print("Now already analyzed " + str(num_analyzed) + " / " + str(NUM_REPORTS) + " reports")

    # Start with the cores that have the most reports first
    cores_counts = list(Report.objects.values('application_corepath').annotate(core_count=Count('application_corepath')).order_by('-core_count'))
    #print_cores_counts_exit(cores_counts)
    cores = [core_count['application_corepath'] for core_count in cores_counts]
    NUM_CORES = len(cores)

    db.connections.close_all() # Not sure if this is necessary. Just trying to avoid hitting max_connections...
    global ppool
    ppool = mpool.Pool(nproc)

    NUM_FD_REPORTS = Report.objects.filter(tainted=True,syscall__in=SYSCALLS_FDCONF).count()
    for _ in tqdm(ppool.imap_unordered(analyze_fd_reports_from_core, cores), total=NUM_CORES, desc="Analyzing " + str(NUM_FD_REPORTS) + " FD-configuring reports from " + str(NUM_CORES) +" snapshots", disable=DISABLE_PROGRESS_BAR_FOR_ANALYSIS): pass
    NUM_SEC_REPORTS = Report.objects.filter(tainted=True,syscall__in=SYSCALLS_SECSENS).count()
    for _ in tqdm(ppool.imap_unordered(analyze_sec_reports_from_core, cores), total=NUM_CORES, desc="Analyzing " + str(NUM_SEC_REPORTS) + " sec-sensitive reports from " + str(NUM_CORES) +" snapshots", disable=DISABLE_PROGRESS_BAR_FOR_ANALYSIS): pass

    atexit.unregister(terminate_all_processes)
    atexit.unregister(close_all_gdbinsts)

################################################################################################################################
################################################################################################################################

def analyze_rop_report(r):
    has_taint = False
    has_iflow = False
    if r.operand_type == "memory":
        has_taint = has_taint_qword(r.target['base']) or has_taint_qword(r.target['indx']) or has_taint_qword(r.target['cptr'])
        has_iflow = has_taint and \
                    (has_iflow_qword(r.target['base'], r.application_corepath, Limits.lnew(Limits.MATCH_LEN_DEFAULT, Limits.PTR_DEPTH_LIMIT_DEFAULT, Limits.TAGS_PER_TAGSET_DEFAULT, 'match_len', Limits.MATCH_LEN_DEFAULT)) or \
                      has_iflow_qword(r.target['indx'], r.application_corepath, Limits.lnew(Limits.MATCH_LEN_DEFAULT, Limits.PTR_DEPTH_LIMIT_DEFAULT, Limits.TAGS_PER_TAGSET_DEFAULT, 'match_len', Limits.MATCH_LEN_DEFAULT)) or \
                     has_iflow_qword(r.target['cptr'], r.application_corepath, Limits.lnew(Limits.MATCH_LEN_DEFAULT, Limits.PTR_DEPTH_LIMIT_DEFAULT, Limits.TAGS_PER_TAGSET_DEFAULT, 'match_len', Limits.MATCH_LEN_DEFAULT)))
    elif r.operand_type == "register":
        has_taint = has_taint_qword(r.target['reg'])
        has_iflow = has_taint and has_iflow_qword(r.target['reg'], r.application_corepath, Limits.lnew(Limits.MATCH_LEN_DEFAULT, Limits.PTR_DEPTH_LIMIT_DEFAULT, Limits.TAGS_PER_TAGSET_DEFAULT, 'match_len', Limits.MATCH_LEN_DEFAULT))
    else:
        EXIT_ERR("Unexpected operand type: " + r)
    r.has_taint = has_taint
    r.has_iflow = has_iflow
    r.done_analyzing = True

def analyze_rop_reports_from_core(core):
    db.connections.close_all() # Not sure if this is necessary. Just trying to avoid hitting max_connections...
    rs = RopReport.objects.filter(application_corepath=core,done_analyzing=False)
    core_analysis_init(core)
    systpool = mpool.ThreadPool(NUM_THREADS_PER_PROC)
    COUNT = rs.count()
    for _ in tqdm(systpool.imap_unordered(analyze_rop_report, rs), desc="rop-reports:"+core, total=COUNT, disable=DISABLE_PROGRESS_BAR_PER_CORE): pass
    systpool.terminate()
    core_analysis_done(core)
    RopReport.objects.bulk_update(rs, ['has_taint', 'has_iflow', 'done_analyzing'], batch_size=10000) # We can use bulk_update for ROP reports because they do not use chaining, and hence we do not need to lookup previous reports
    db.connections.close_all() # Not sure if this is necessary. Just trying to avoid hitting max_connections...

def analyze_rop_reports(nproc):
    atexit.register(close_all_gdbinsts)
    atexit.register(terminate_all_processes)

    # Print status
    NUM_REPORTS = RopReport.objects.all().count()
    num_analyzed = RopReport.objects.filter(done_analyzing=True).count()
    print("Already analyzed " + str(num_analyzed) + " / " + str(NUM_REPORTS) + " ROP reports")

    # Start with the cores that have the most reports first
    cores_counts = list(RopReport.objects.values('application_corepath').annotate(core_count=Count('application_corepath')).order_by('-core_count'))
    #for cc in cores_counts: print(str(cc))
    cores = [core_count['application_corepath'] for core_count in cores_counts]
    NUM_CORES = len(cores)

    db.connections.close_all() # Not sure if this is necessary. Just trying to avoid hitting max_connections...
    global ppool
    ppool = mpool.Pool(nproc)
    for _ in tqdm(ppool.imap_unordered(analyze_rop_reports_from_core, cores), total=NUM_CORES, desc="Analyzing " + str(NUM_REPORTS) + " total ROP reports from " + str(NUM_CORES) +" snapshots", disable=DISABLE_PROGRESS_BAR_FOR_ANALYSIS): pass
    atexit.unregister(terminate_all_processes)
    atexit.unregister(close_all_gdbinsts)
