from db_manage import NPROC, NUM_THREADS_PER_PROC
from db.models import Report, RopReport, Limits
from django.db.models import Count
from django import db
import struct
from tqdm import tqdm
import os.path
from pygdbmi.gdbcontroller import GdbController
from pygdbmi.constants import GdbTimeoutError
import multiprocessing.pool as mpool
import atexit
from functools import cache
from time import sleep

DISABLE_PROGRESS_BAR_FOR_ANALYSIS = False
DISABLE_PROGRESS_BAR_PER_CORE = True

GDB_MAX_QUERY_FAILURES = 10
GDB_MAX_TIMEOUTS = 50
GDB_TIMEOUT_SECS = 5

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

SYSARGCOUNTS_SECSENS = dict(sorted({'execve':3, 'execveat':5, 'mmap':6, 'mprotect':3, 'mremap':5,
                                    'remap_file_pages':5, 'sendmmsg':4, 'sendmsg':3, 'sendto':6,
                                    'write':3, 'pwrite64':4, 'pwritev':4, 'pwritev2':5,
                                    'sendfile':4, 'writev':3}.items()))
# NOTE: Update SYSARGCOUNTS_FDCONF whenever another arg is added to *_get_details in einstein_syscalls.cpp
SYSARGCOUNTS_FDCONF = dict(sorted({'creat':2, 'open':3, 'openat':4, 'openat2':4, 'dup':1, 'dup2':2,
                                   'dup3':3, 'bind':3, 'connect':3, 'setsockopt':5, 'socket':3,
                                   'socketpair':4}.items()))

SYSCALLS_SECSENS=list(SYSARGCOUNTS_SECSENS.keys()) # I.e., ['execve', 'execveat', 'mmap', ...]
SYSCALLS_FDCONF=list(SYSARGCOUNTS_FDCONF.keys()) # I.e., ['creat', 'open', 'openat', ...]

################################################################
############################
#### Core management

ERR_VAL = float('inf')
WAIT_VAL = float('-inf')
PAGE_SIZE = 4096
assert PAGE_SIZE > Limits.MATCH_LEN_MAX

corevals = {}
def is_in_corevals(addr, core, size): return size > 0 and addr in corevals[core] and addr+size-1 in corevals[core] # TODO: Check every single addr in range, rather than just the beginning/ending?
def get_corevals(addr, core, size): return [corevals[core][this_addr] for this_addr in range(addr,addr+size)]
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
        for _ in range(GDB_MAX_TIMEOUTS):
            try:
                gdbinsts[core][i].write("core-file " + core, timeout_sec=60)
                success = True
                break
            except GdbTimeoutError: pass
        if not success: EXIT_ERR("Could not load core file into gdb: " + core)

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

def make_gdb_query(core, query, size):
    global curr_gdb_inst
    my_gdb_inst = curr_gdb_inst
    curr_gdb_inst = (curr_gdb_inst + 1) % NUM_THREADS_PER_PROC
    timeout_count = 0
    failed_queries = 0
    while timeout_count < GDB_MAX_TIMEOUTS and failed_queries < GDB_MAX_QUERY_FAILURES:
        try:
            tmp_responses = gdbinsts[core][my_gdb_inst].write(query, timeout_sec=GDB_TIMEOUT_SECS)
        except GdbTimeoutError:
            timeout_count = timeout_count + 1
            #print("GDB query timed out (timeout #" + str(timeout_count) + "). Trying again. (core: '" + core + "', query: '" + query + "')")
            continue
        for tmp_response in tmp_responses:
            try:
                if tmp_response['payload']['msg'] == 'Unable to read memory.': return None
            except: pass
            try:
                if isinstance(tmp_response['payload']['memory'][0]['contents'], list): continue # To work around some weird error that occurs (due to a bug in pygdbmi?)...
                bighex = tmp_response['payload']['memory'][0]['contents']
                vals_list = bytes.fromhex(bighex)
                if len(vals_list) != size: continue # To work around some weird error that occurs (due to multi-threading?)
                return vals_list
            except: pass
        failed_queries = failed_queries + 1
        #print("Failed query " + str(failed_queries) + ": query: '" + query + "', core: '" + core + "', returned: '" + str(tmp_responses) + "'")
    EXIT_ERR("Error: GDB query timed out " + str(timeout_count) + " times and failed " + str(failed_queries) + " times. (core: " + core + ")")

############################
#### Core lookup

def core_addr_prep(reg_tup):
    addr = reg_tup['start']
    size = reg_tup['size']
    core = reg_tup['core']
    vals_list = make_gdb_query(core, "-data-read-memory-bytes " + hex(addr) + " " + str(size), size)
    if vals_list == None:
        for i in range(0, size): add_to_corevals(addr + i, ERR_VAL, core)
    else:
        for i in range(0, size): add_to_corevals(addr + i, vals_list[i], core)

def core_addr_lookup(addr, core, size):
    if core == "": return ERR_VAL
    while is_in_corevals(addr, core, size):
        vals_list = get_corevals(addr, core, size)
        if WAIT_VAL in vals_list: sleep(0.1) # TODO: A better way of checking this
        else: return bytearray(vals_list)
    core_addr_prep({'start': addr - addr % PAGE_SIZE, 'size': PAGE_SIZE, 'core': core})
    vals_list = get_corevals(addr, core, size)
    if ERR_VAL in vals_list: return ERR_VAL
    if WAIT_VAL in vals_list:
        print("Warning: WAIT_VAL is in vals_list. Something went wrong.")
        return ERR_VAL
    return bytearray(vals_list)

def core_addr_lookup_qword(addr, core):
    vals_list = core_addr_lookup(addr, core, 8)
    if vals_list == ERR_VAL: return ERR_VAL
    return struct.unpack('<Q', vals_list)[0]
def core_addr_lookup_byte(addr, core):
    vals_list = core_addr_lookup(addr, core, 1)
    if vals_list == ERR_VAL: return ERR_VAL
    return struct.unpack('<B', vals_list)[0]

def core_addr_has_byte(addr, exp_val, core):
    found_val = core_addr_lookup_byte(addr, core)
    if found_val == ERR_VAL: return False
    return found_val == exp_val

def core_addr_has_bytes(addr, exp_vals, core, ptr_depth_limit):
    if len(exp_vals) > Limits.MATCH_LEN_MAX: EXIT_ERR("Error: len(exp_vals) (" + str(len(exp_vals)) + ") should be less than or equal to Limits.MATCH_LEN_MAX (" + str(Limits.MATCH_LEN_MAX) + ")")
    found_vals_all = core_addr_lookup(addr, core, len(exp_vals))
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
    print("Error: Unhandled type " + t, flush=True)
    return set()

def get_iflows(arg, core, limits):
    fl_dup = get_iflows_handler(arg, core, limits)
    fl = [dict(y) for y in set(tuple(x.items()) for x in fl_dup)] # Deduplicate flows in fl_dup
    for f in fl: f.update({'vals': list(f['vals'])}) # Convert bytearray to int array (so that it is proper JSON)
    return fl

################################################################
############################
#### Report chaining lookup

# NOTE: Cache should be invalidated when DB connection is closed (e.g., when forking)
@cache
def get_report(report_num, core, ids):
    pid, ppid, tid, ptid = ids

    # The previous 'chained' report came from this thread
    try: return Report.objects.get(report_num=report_num,application_corepath=core,pid=pid,ppid=ppid,tid=tid,ptid=ptid)
    except Report.MultipleObjectsReturned: EXIT_ERR("Error: Multiple reports with report_num:" + str(report_num) + ", core:\"" + core + "\", pid:" + str(pid) + ", ppid:" + str(ppid) + ", tid:" + str(tid) + ", ptid:" + str(ptid))
    except Report.DoesNotExist: pass

    # The previous 'chained' report came from this process
    try: return Report.objects.get(report_num=report_num,application_corepath=core,pid=pid,ppid=ppid)
    except Report.MultipleObjectsReturned: EXIT_ERR("Error: Multiple reports with report_num:" + str(report_num) + ", core:\"" + core + "\", pid:" + str(pid) + ", ppid:" + str(ppid))
    except Report.DoesNotExist: pass

    # The previous 'chained' report came from this snapshot
    try: return Report.objects.get(report_num=report_num,application_corepath=core)
    except Report.DoesNotExist: pass
    # EXIT_ERR("Error: Cannot find report with report_num:" + str(report_num) + ", core:\"" + core + "\"")

    # The previous 'chained' report came from a different snapshot in this process
    try: return Report.objects.get(report_num=report_num,pid=pid)
    except Report.DoesNotExist: pass

    # The previous 'chained' report came from a different snapshot in the parent process
    try: return Report.objects.get(report_num=report_num,pid=ppid)
    except Report.DoesNotExist: pass

    # TODO: Look sequentially (backwards) through this process's snapshots, then the parent process's snapshots, then the (grand?)parent proces's snapshots, etc...

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
    print("Error: Unhandled type " + t, flush=True)
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
    print("Error: Unhandled type " + t, flush=True)
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
        print("Error: Cannot analyze iflow for report because because its core dump does not exist at: " + r.application_corepath, flush=True)
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

def analyze_fd_reports_from_core_internal(core, rs, COUNT):
    # Analyze "fd creating" syscalls sequentially
    for r in tqdm(rs, desc="fd-creating:"+core, total=COUNT, disable=DISABLE_PROGRESS_BAR_PER_CORE):
        analyze_syscall(r)
        r.save()

def analyze_sec_reports_from_core_internal(core, rs, COUNT):
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

################################################################

def get_core_addrs_arg(obj):
    taints = set()

    def get_core_addrs_arg_recursive(obj):
        if isinstance(obj, dict):
            for key, value in obj.items():
                if key.endswith('_taint'):
                    for taint in value:
                        if taint != "FULL": taints.update(taint)
                get_core_addrs_arg_recursive(value)
        elif isinstance(obj, list):
            for item in obj:
                get_core_addrs_arg_recursive(item)

    get_core_addrs_arg_recursive(obj)
    return taints

def get_core_addrs(rs):
    core_addrs = set()
    for r in rs:
        for sa in r.syscall_args:
            core_addrs.update(get_core_addrs_arg(sa))
    return core_addrs

def get_core_pages(core_addrs):
    core_pages = set()
    for addr in core_addrs: core_pages.add(addr - addr%PAGE_SIZE)
    return core_pages

def prep_corevals(core, rs):
    core_addrs = get_core_addrs(rs)
    core_pages = get_core_pages(core_addrs)
    core_pages_tups = [{'start': core_page, 'size': PAGE_SIZE, 'core': core} for core_page in core_pages]
    systpool = mpool.ThreadPool(NUM_THREADS_PER_PROC)
    for _ in tqdm(systpool.imap_unordered(core_addr_prep, core_pages_tups), disable=True): pass
    systpool.terminate()

################################################################

def analyze_reports_from_core(core, is_fd_conf):
    if is_fd_conf: rs = Report.objects.filter(done_analyzing=False,tainted=True,application_corepath=core,syscall__in=SYSCALLS_FDCONF).order_by('ppid', 'pid', 'report_num')
    else:          rs = Report.objects.filter(done_analyzing=False,tainted=True,application_corepath=core,syscall__in=SYSCALLS_SECSENS).order_by('ppid', 'pid', 'report_num')

    COUNT = rs.count()
    if COUNT == 0: return

    core_analysis_init(core)
    prep_corevals(core, rs)
    if is_fd_conf: analyze_fd_reports_from_core_internal(core, rs, COUNT)
    else:          analyze_sec_reports_from_core_internal(core, rs, COUNT)
    core_analysis_done(core)

def analyze_fd_reports_from_core(core):  analyze_reports_from_core(core, True)
def analyze_sec_reports_from_core(core): analyze_reports_from_core(core, False)

################################################################

def analyze_untainted_reports(rs):
    rs = rs.filter(tainted=False,done_analyzing=False)
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

def print_cores_counts_exit(cores_counts):
    for cc in cores_counts: print(str(cc))
    EXIT_ERR("Done")

def appname_to_dbname(app):
    if (app == "memcached"): return "memcached-debug"
    if (app == "redis"): return "redis-server"
    if (app == "apache"): return "httpd"
    return app

def rs_in_app(rs, app):
    if app is None: return rs
    return rs.filter(application=app)

def print_update(app, NUM_REPORTS):
    num_analyzed = rs_in_app(Report.objects.filter(done_analyzing=True),app).count()
    print("Analyzed " + str(num_analyzed) + " / " + str(NUM_REPORTS) + " reports", flush=True)

def analyze_reports(app):
    atexit.register(close_all_gdbinsts)
    atexit.register(terminate_all_processes)

    print("Beginning reports analysis...", flush=True)
    app = appname_to_dbname(app)
    NUM_REPORTS = rs_in_app(Report.objects,app).count()

    # 0. Check how many reports have already been analyzed
    print_update(app, NUM_REPORTS)

    # 1: Update the untainted reports (requires no actual analysis)
    analyze_untainted_reports(rs_in_app(Report.objects,app))
    print_update(app, NUM_REPORTS)

    # Uncomment to see the report count for each core
    #print_cores_counts_exit(rs_in_app(Report.objects,app).values('application_corepath').annotate(core_count=Count('application_corepath')).order_by('-core_count')))

    # Prep: Order cores by their PIDs, so we can be sure to finish evaluating any FD-configuring syscalls in a parent process before evaluating the child process (because parent_pid < child_pid)
    cores = list(dict.fromkeys(rs_in_app(Report.objects,app).values('application_corepath', 'pid').distinct().order_by('pid').values_list('application_corepath', flat=True)))
    NUM_CORES = len(cores)
    NUM_FD_REPORTS = rs_in_app(Report.objects.filter(done_analyzing=False,tainted=True,syscall__in=SYSCALLS_FDCONF),app).count()
    NUM_SEC_REPORTS = rs_in_app(Report.objects.filter(done_analyzing=False,tainted=True,syscall__in=SYSCALLS_SECSENS),app).count()

    # 2: Analyze FD-configuring syscalls sequentially
    for core in tqdm(cores, desc="Analyzing (sequentially) " + str(NUM_FD_REPORTS) + " FD-configuring syscalls from " + str(NUM_CORES) + " snapshot", total=NUM_CORES, disable=DISABLE_PROGRESS_BAR_FOR_ANALYSIS): analyze_fd_reports_from_core(core)
    print_update(app, NUM_REPORTS)

    # 3: Analyze sec-sensitive syscalls in parallel
    db.connections.close_all() # setup: close DB connection
    get_report.cache_clear()   # setup: clear cache, which has QuerySets that are now invalid
    global ppool
    ppool = mpool.Pool(NPROC)
    for _ in tqdm(ppool.imap_unordered(analyze_sec_reports_from_core, cores), desc="Analyzing (in parallel) " + str(NUM_SEC_REPORTS) + " sec-sensitive syscalls from " + str(NUM_CORES) +" snapshots", total=NUM_CORES, disable=DISABLE_PROGRESS_BAR_FOR_ANALYSIS): pass
    print_update(app, NUM_REPORTS)

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

def analyze_rop_reports():
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
    ppool = mpool.Pool(NPROC)
    for _ in tqdm(ppool.imap_unordered(analyze_rop_reports_from_core, cores), total=NUM_CORES, desc="Analyzing " + str(NUM_REPORTS) + " total ROP reports from " + str(NUM_CORES) +" snapshots", disable=DISABLE_PROGRESS_BAR_FOR_ANALYSIS): pass
    atexit.unregister(terminate_all_processes)
    atexit.unregister(close_all_gdbinsts)

################################################################################################################################
################################################################################################################################

def analysis_reset():
    db.connections.close_all() # Not sure if this is necessary. Just trying to avoid hitting max_connections...
    print("Resetting reports analysis...")
    Report.objects.filter(done_analyzing=True).update(done_analyzing=False)
    print("Resetting ROP reports analysis...")
    RopReport.objects.filter(done_analyzing=True).update(done_analyzing=False)
    db.connections.close_all() # Not sure if this is necessary. Just trying to avoid hitting max_connections...