from db.analyze import core_analysis_init, is_in_corestrs, get_corestr, core_addr_lookup_qword, \
        ERR_VAL, add_to_corestrs, get_report, make_gdb_query
from db.models import Report, Limits
from django.db.models.fields.json import KT
from django.db.models import Q
import re
import yaml

# So that yaml.dump() prints numbers in hex (https://stackoverflow.com/a/42504639)
def hexint_presenter(dumper, data): return dumper.represent_int(hex(data))
yaml.add_representer(int, hexint_presenter)

############################
#### Custom string lookup

def bytestr_to_str(bs):
    s = ""
    has_printable_char = False
    for b in bs:
        ba = b.split(" ", 1)
        n,c = int(ba[0]), ba[1][1:-1]
        if n == 0: break # null-terminator
        if n >= 32 and n <= 126:
            # printable character
            s += c
            has_printable_char = True
        else: s += "." # non-printable character
    return s if has_printable_char else ''
def core_addr_lookup_string(addr, core):
    if core == "": return ""
    if is_in_corestrs(addr, core): return get_corestr(addr, core)
    tmpres = make_gdb_query(core, "-data-read-memory " + hex(addr) + " c 1 1 128")[0] # Looking up 128 characters because our string limit is 128 characters
    if tmpres['type'] != 'result' or tmpres['message'] == 'error':
        print("Error looking up string in core: core_addr_lookup_string(" + hex(addr) + ", '" + core + ")")
        return ""
    bs = tmpres['payload']['memory'][0]['data']
    return bytestr_to_str(bs)

def custom_get_core_str(addr, core, application, rec_count):
    if rec_count >= 5: return "?"
    if core == "": return ""
    if is_in_corestrs(addr, core): return get_corestr(addr, core)
    s = ""
    val = core_addr_lookup_qword(addr, core)
    if val == ERR_VAL: return ""
    if val >= 0x7fff00000000 and val < 0x800000000000:
        suffix_s = custom_get_core_str(val, core, application, rec_count+1)
        if (suffix_s == ''): s = ''
        else: s = "{addr: " + hex(addr) + "} <-- " + custom_get_core_str(val, core, application, rec_count+1)
    else:
        addr_str = core_addr_lookup_string(addr, core)
        if (addr_str == ''): s = ''
        else:
            s = "{addr: " + hex(addr) + ", str: '" + addr_str + "'}"
            for i in range(0, len(addr_str)):
                tmp_addr = addr + i
                tmp_addr_str = addr_str[i:]
                tmp_s = "{addr: " + hex(tmp_addr) + ", str: '" + tmp_addr_str + "'}"
                add_to_corestrs(tmp_addr, tmp_s, core)
    add_to_corestrs(addr, s, core)
    return s

################################################################

def custom_taint_print_buf(core, application, buf_str, buf_tsarr):
    print("buf_taint:")
    assert len(buf_tsarr) == len(buf_str)
    buf_tdic = {}
    for idx, ts in enumerate(buf_tsarr):
        if ts == "FULL": continue
        for t in ts:
            if t in buf_tdic: buf_tdic[t] += [idx]
            else: buf_tdic[t] = [idx]
    for addr,char_idxs in sorted(buf_tdic.items()):
        flow_str = ""
        for idx, c in enumerate(buf_str):
            if idx in char_idxs: flow_str += c
            else: flow_str += "_"
        #print("addr: " + hex(addr) + ", chars: " + str(char_idxs) + ", flow_str: '" + flow_str + "'")
        l = custom_get_core_str(addr, core, application, 0)
        if l != "": print("   - '" + flow_str + "' <= " + l)

def custom_taint_print_qword(core, application, qword_tsarr, qword):
    print("qword:       " + hex(qword))
    print("qword_taint:")
    qword_tset = set()
    for ts in qword_tsarr:
        if ts == "FULL": continue
        for t in ts: qword_tset.add(t)
    for addr in sorted(qword_tset):
        l = custom_get_core_str(addr, core, application, 0)
        if l != "": print("   -  " + l)


def custom_taint_print(arg, core, application, header_str):
    buf_str = arg['str'] if 'str' in arg else ''
    print("==============")
    print(header_str)
    if 'str' in arg: buf_str = arg['str']; print("str: '" + buf_str + "'")
    else: buf_str = ''
    inp = input("Print taint details? (Press enter for yes, or 'n' for no).")
    if inp != 'n':
        core_analysis_init(core)
        if 'buf_taint' in arg: custom_taint_print_buf(core, application, buf_str, arg['buf_taint'])
        if 'qword_taint' in arg: custom_taint_print_qword(core, application, arg['qword_taint'], arg['qword'])
    print("==============")

def custom_report_print(r):
    print("============================")
    for i in range(0, len(r.syscall_args)):
        print("syscall_args[" + str(i) + "]:")
        for k,v in sorted(r.syscall_args[i].items()): print("      " + k + ": " + yaml.dump(v, default_flow_style=True, width=120).strip('\n').strip('.').strip('\n').replace('\n', '\n' + ' ' * (7 + len(k))))
    print("backtrace: " + yaml.dump([re.sub(r'(.*):\((.*)\) ', '\\2(\\1)',re.sub(r'\+0x.* at [^ ]* ', ':', re.sub(r'/.*/apps/', './', l))) for l in r.backtrace], default_flow_style=True, indent=4, sort_keys=False, width=10), end='')
    print("application_corepath:   " + r.application_corepath)
    print("application_testcase:   " + r.application_testcase)
    print("pid, ppid, tid, ptid:   " + str(r.pid) + ", " + str(r.ppid) + ", " + str(r.tid) + ", " + str(r.ptid))
    print("report_num:             " + str(r.report_num))
    print("application:            " + r.application)
    print("syscall:                " + r.syscall)
    print("args taint:             " + str([int(r.get_taint(argnum)) for argnum in range(0, len(r.syscall_args))]))
    print("args iflow:             " + str([int(r.get_iflow(argnum)) for argnum in range(0, len(r.syscall_args))]))
    for arg_num in range(0,len(r.syscall_args)): print("arg[" + str(arg_num) + "].iflow_list:      " + yaml.dump(r.get_iflows_list(arg_num), default_flow_style=True, width=120).strip('\n'))
    if r.syscall == 'write': custom_taint_print(r.syscall_args[1], r.application_corepath, r.application, "write's buf...")
    if r.syscall == 'writev':
        iovcnt = r.syscall_args[2]['dword']
        print('writev with iovcnt = ' + str(iovcnt) + '...')
        for i in range(iovcnt): custom_taint_print(r.syscall_args[1]['vptrs'][i], r.application_corepath, r.application, 'writev iov[' + str(i) + ']...')
    if r.syscall == 'openat': custom_taint_print(r.syscall_args[0], r.application_corepath, r.application, "openat's filename...")
    if r.syscall == 'execve':
        custom_taint_print(r.syscall_args[0], r.application_corepath, r.application, "execve's filename...")
        custom_taint_print(r.syscall_args[1], r.application_corepath, r.application, "execve's argv...")
        for arg_num, arg in enumerate(r.syscall_args[1]['pchars']):
            custom_taint_print(arg, r.application_corepath, r.application, "execve's argv[" + str(arg_num) + "]...")
        custom_taint_print(r.syscall_args[2], r.application_corepath, r.application, "execve's envp...")
        for arg_num, arg in enumerate(r.syscall_args[2]['pchars']):
            custom_taint_print(arg, r.application_corepath, r.application, "execve's envp[" + str(arg_num) + "]...")
    print()

def is_empty_taint(bft):
    for ts in bft:
        if ts == []: continue
        return False
    return True

skip_backtrace = ''
def set_skip_backtrace(bt): global skip_backtrace; skip_backtrace = bt
def is_skip_backtrace(bt):
    global skip_backtrace
    if skip_backtrace != '':
        if skip_backtrace == bt: return True
        skip_backtrace = ''
    return False

def is_uninteresting_string(str):
    uninteresting_strs = ["cmdsvr: ready"]
    #uninteresting_strs += [" [debug] ", " [info] ", " [notice] ", " [alert] ", " [error] ", " [warn] ", " [crit] "]
    uninteresting_strs += ["127.0.0.1 - - [26/Mar/2023:"]
    for u_str in uninteresting_strs:
        if u_str in str: return True
    return False

def has_interesting_string(str):
    interesting_strs = []
    interesting_strs += [" [debug] ", " [info] ", " [notice] ", " [alert] ", " [error] ", " [warn] ", " [crit] "]
    for i_str in interesting_strs:
        if i_str in str: return True
    return False

def has_interesting_fd_creator(fd_creators):
    uninteresting_file_res = ['^/tmp/nginx-test-.*/error.log$', '^/tmp/nginx-test-.*/access.log$']
    for fd_creator in fd_creators:
        name = fd_creator['name']
        name_is_uninteresting = False
        for uninteresting_file_re in uninteresting_file_res:
            if re.match(uninteresting_file_re, name):
                name_is_uninteresting = True
                break
        if not name_is_uninteresting: return True
    return False

def has_nonfull_taint(tsarr):
    for ts in tsarr:
        if ts == "FULL": continue
        for t in ts: return True
    return False

def has_tainted_fd_creator(fd_creators):
    for fd_info in fd_creators:
        if fd_info['report_num'] != 0: return True
    return False

def print_write_strs(tmprs):
    strs = tmprs.values_list('syscall_args__1__str', flat=True).distinct()
    #strs = sorted(set([s.split(':')[3] for s in strs]))
    print("strs: ")
    for s in strs: print("- " + s)

def custom():
    #### execve ####
    # argv has an iflow
    #tmprs = Report.objects.filter(syscall='execve', tainted=True).annotate(curr_limit=KT(Limits.liflow_default(1))).filter(curr_limit='true')
    #tmprs = Report.objects.filter(syscall='execve', application='lighttpd', application_testcase__contains='./request.t:1271', tainted=True
    # binary_upgrade case study
    #tmprs = Report.objects.filter(syscall='execve', application='nginx', application_testcase__contains='binary_upgrade.t', tainted=True)

    #### mprotect ####
    # prot has an iflow ==> 2 gadgets buried in pthread_create, and addr is not controllable :(
    #tmprs = Report.objects.filter(syscall='mprotect', tainted=True).annotate(curr_limit=KT(Limits.liflow_default(2))).filter(curr_limit='true')
    # prot has PROT_EXEC ==> None :(
    #tmprs = Report.objects.filter(syscall='mprotect', syscall_args__2__dword__gte=4)

    #### mmap ####
    # prot has an iflow ==> 1 case buried in pthread_exit :(
    #tmprs = Report.objects.filter(syscall='mmap', tainted=True).annotate(curr_limit=KT(Limits.liflow_default(2))).filter(curr_limit='true')
    # prot has PROT_EXEC ==> 1 case buried in pthread_exit, and addr is not controllable :(
    #tmprs = Report.objects.filter(syscall='mmap', syscall_args__2__dword__gte=4)

    #### OLD write ####
    # [emerg], [alert], [crit], [error], [warn], [notice], [info], [debug]
    #tmprs = Report.objects.filter(syscall='write', has_arg1_taint=True, application='nginx', syscall_args__1__str__icontains='[debug]', application_testcase__icontains='access_log.t:178')
    #tmprs = Report.objects.filter(syscall='write', has_arg1_taint=True, application='nginx', syscall_args__0__fd_creators__icontains='cache_first')
    #print_write_strs(tmprs)
    #tmprs = Report.objects.filter(syscall='openat', application='nginx', syscall_args__0__str__icontains='/tmp/nginx-test-u8zzjNgC0q/error.log')
    #tmprs = Report.objects.filter(syscall='openat', application='nginx', syscall_args__0__str__icontains='/tmp/nginx-test-u8zzjNgC0q/dir/cache_first')
    #tmprs = Report.objects.filter(syscall='write', has_arg1_taint=True, application='nginx', syscall_args__1__str__icontains='18:05:38 [debug] 8432#0: accept on 127.0.0.1:8080, ready: 0.')
    #tmprs = Report.objects.filter(syscall='write', has_arg1_taint=True, application='nginx', syscall_args__1__str__icontains='dir/cache_lru" failed')
    #tmprs = Report.objects.filter(syscall='write', has_arg1_taint=True, application='nginx', syscall_args__1__str__icontains='18:05:39 [notice] 8432#0: exiting.')

    #### NEW write ####
    #tmprs = Report.objects.filter(application='nginx', syscall='write', tainted=True).exclude(syscall_args__1__str__icontains='[debug]').exclude(syscall_args__1__str__icontains='[notice]').exclude(
    #    syscall_args__1__str__icontains='[emerg]').exclude(syscall_args__1__str__icontains='[alert]').exclude(syscall_args__1__str__icontains='[info]').exclude(syscall_args__1__str__icontains='[error]').exclude(
    #    syscall_args__1__str__icontains='[warn]').exclude(syscall_args__1__str__icontains='[crit]')
    #tmprs = Report.objects.filter(application='nginx', syscall='write', tainted=True, syscall_args__1__str__icontains='[error]')
    #tmprs = Report.objects.filter(application='nginx', syscall='openat', has_arg0_taint=True)
    #tmprs = Report.objects.filter(syscall='write', has_arg1_taint=True, application='nginx', syscall_args__1__str__icontains='[error]')

    #### Debugging Table 3 vs Table 4 issue ####
    # Part 1: Finding 'write' a gadget that appears twice in Table 4 (as write(fd,_,_) and write(fd,buf,_))
    """
    tmprs1 = Report.objects.filter(syscall='write').annotate(
            curr_limit0=KT(Limits.liflow_default(0)),
            curr_limit1=KT(Limits.liflow_default(1)),
            curr_limit2=KT(Limits.liflow_default(2))).filter(
                    curr_limit0='true' if 0 in (0, 1) else 'false',
                    curr_limit1='true' if 1 in (0, 1) else 'false',
                    curr_limit2='true' if 2 in (0, 1) else 'false').values('application', 'backtrace').distinct()
    tmprs2 = Report.objects.filter(syscall='write').annotate(
            curr_limit0=KT(Limits.liflow_default(0)),
            curr_limit1=KT(Limits.liflow_default(1)),
            curr_limit2=KT(Limits.liflow_default(2))).filter(
                    curr_limit0='true' if 0 in (0,) else 'false',
                    curr_limit1='true' if 1 in (0,) else 'false',
                    curr_limit2='true' if 2 in (0,) else 'false').values('application', 'backtrace').distinct()
    print(tmprs1.intersection(tmprs2))
    return
    """
    # Part 2: Examining reports of the gadget
    """
    mybt = ['__write+0x00000004d at /lib/x86_64-linux-gnu/libc.so.6+0x000114a6d ', 'ngx_log_error_core+0x0000002d0 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff00144c2d (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/os/unix/ngx_files.h:147) ', 'ngx_create_temp_file+0x00000013a at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff0014d150 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/core/ngx_file.c:204) ', 'ngx_write_chain_to_temp_file+0x000000063 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff0014d2ea (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/core/ngx_file.c:114) ', 'ngx_http_write_request_body+0x00000003e at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff00196272 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/http/ngx_http_request_body.c:583) ', 'ngx_http_request_body_save_filter+0x000000186 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff00197834 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/http/ngx_http_request_body.c:1313) ', 'ngx_http_v2_filter_request_body+0x00000017f at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff001c71ce (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/http/v2/ngx_http_v2.c:4370) ', 'ngx_http_v2_process_request_body+0x0000000a6 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff001c7e8d (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/http/v2/ngx_http_v2.c:4194) ', 'ngx_http_v2_state_read_data+0x0000000d4 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff001ca361 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/http/v2/ngx_http_v2.c:1143) ', 'ngx_http_v2_state_data+0x0000003d2 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff001ca97f (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/http/v2/ngx_http_v2.c:1087) ', 'ngx_http_v2_state_head+0x000000084 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff001c8f8c (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/http/v2/ngx_http_v2.c:947) ', 'ngx_http_v2_read_handler+0x00000024a at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff001cb0d0 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/http/v2/ngx_http_v2.c:435) ', 'ngx_http_v2_idle_handler+0x000000157 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff001cb767 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/http/v2/ngx_http_v2.c:4865) ', 'ngx_epoll_process_events+0x00000032e at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff00171933 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/event/modules/ngx_epoll_module.c:901) ', 'ngx_process_events_and_timers+0x00000008f at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff00165ad3 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/event/ngx_event.c:248) ', 'ngx_worker_process_cycle+0x00000012e at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff0016f93a (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/os/unix/ngx_process_cycle.c:721) ', 'ngx_spawn_process+0x000000585 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff0016d83a (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/os/unix/ngx_process.c:199) ', 'ngx_start_worker_processes+0x000000043 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff0016ebf7 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/os/unix/ngx_process_cycle.c:344) ', 'ngx_master_process_cycle+0x0000001f4 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff001701d0 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/os/unix/ngx_process_cycle.c:130) ', 'main+0x00000042d at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff00143f28 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/core/nginx.c:383) ', '__libc_init_first+0x000000090 at /lib/x86_64-linux-gnu/libc.so.6+0x000029d90 ', '__libc_start_main+0x000000080 at /lib/x86_64-linux-gnu/libc.so.6+0x000029e40 ', '_start+0x000000025 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff00142425 ']
    tmprs = Report.objects.filter(syscall='write', application='nginx', backtrace=mybt).distinct()
    #{'application': 'nginx', 'backtrace': ['__write+0x00000004d at /lib/x86_64-linux-gnu/libc.so.6+0x000114a6d ', 'ngx_log_error_core+0x0000002d0 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff00144c2d (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/os/unix/ngx_files.h:147) ', 'ngx_create_temp_file+0x00000013a at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff0014d150 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/core/ngx_file.c:204) ', 'ngx_write_chain_to_temp_file+0x000000063 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff0014d2ea (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/core/ngx_file.c:114) ', 'ngx_http_write_request_body+0x00000003e at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff00196272 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/http/ngx_http_request_body.c:583) ', 'ngx_http_request_body_save_filter+0x000000186 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff00197834 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/http/ngx_http_request_body.c:1313) ', 'ngx_http_v2_filter_request_body+0x00000017f at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff001c71ce (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/http/v2/ngx_http_v2.c:4370) ', 'ngx_http_v2_process_request_body+0x0000000a6 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff001c7e8d (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/http/v2/ngx_http_v2.c:4194) ', 'ngx_http_v2_state_read_data+0x0000000d4 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff001ca361 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/http/v2/ngx_http_v2.c:1143) ', 'ngx_http_v2_state_data+0x0000003d2 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff001ca97f (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/http/v2/ngx_http_v2.c:1087) ', 'ngx_http_v2_state_head+0x000000084 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff001c8f8c (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/http/v2/ngx_http_v2.c:947) ', 'ngx_http_v2_read_handler+0x00000024a at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff001cb0d0 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/http/v2/ngx_http_v2.c:435) ', 'ngx_http_v2_idle_handler+0x000000157 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff001cb767 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/http/v2/ngx_http_v2.c:4865) ', 'ngx_epoll_process_events+0x00000032e at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff00171933 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/event/modules/ngx_epoll_module.c:901) ', 'ngx_process_events_and_timers+0x00000008f at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff00165ad3 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/event/ngx_event.c:248) ', 'ngx_worker_process_cycle+0x00000012e at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff0016f93a (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/os/unix/ngx_process_cycle.c:721) ', 'ngx_spawn_process+0x000000585 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff0016d83a (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/os/unix/ngx_process.c:199) ', 'ngx_start_worker_processes+0x000000043 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff0016ebf7 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/os/unix/ngx_process_cycle.c:344) ', 'ngx_master_process_cycle+0x0000001f4 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff001701d0 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/os/unix/ngx_process_cycle.c:130) ', 'main+0x00000042d at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff00143f28 (/home/brian/Research/newton-ng/apps/nginx-1.23.0/src/core/nginx.c:383) ', '__libc_init_first+0x000000090 at /lib/x86_64-linux-gnu/libc.so.6+0x000029d90 ', '__libc_start_main+0x000000080 at /lib/x86_64-linux-gnu/libc.so.6+0x000029e40 ', '_start+0x000000025 at /home/brian/Research/newton-ng/apps/nginx-1.23.0/install/sbin/nginx+0x7fff00142425 ']}
    """

    # Test
    #tmprs = Report.objects.all(); print("Found " + str(tmprs.count()) + " reports..."); return

    #tmprs = Report.objects.filter(syscall='connect',tainted=True).annotate(curr_limit=KT(Limits.liflow_default(1))).filter(curr_limit='true')
    #tmprs = Report.objects.filter(syscall_args__0__this_fd_arg__type="SOCKET-FD")
    tmprs = Report.objects.filter(application='httpd',syscall='execve').annotate(curr_limit=KT(Limits.liflow_default(1))).filter(curr_limit='true')


    """
    tmprs = Report.objects.filter(syscall='openat').annotate(
                curr_limit0=KT(Limits.liflow(0,'match_len',Limits.MATCH_LEN_GET_IFLOWS)),
                curr_limit1=KT(Limits.liflow(1,'match_len',Limits.MATCH_LEN_GET_IFLOWS)),
                curr_limit2=KT(Limits.liflow(2,'match_len',Limits.MATCH_LEN_GET_IFLOWS)),
                curr_limit3=KT(Limits.liflow(3,'match_len',Limits.MATCH_LEN_GET_IFLOWS)),
                curr_limit4=KT(Limits.liflow(4,'match_len',Limits.MATCH_LEN_GET_IFLOWS)),
                curr_limit5=KT(Limits.liflow(5,'match_len',Limits.MATCH_LEN_GET_IFLOWS))).filter(
                    Q(curr_limit0='true') |
                    Q(curr_limit1='true') |
                    Q(curr_limit2='true') |
                    Q(curr_limit3='true') |
                    Q(curr_limit4='true') |
                    Q(curr_limit5='true'))
    """

    rs = tmprs.distinct().order_by('syscall','application','backtrace','application_corepath','application_testcase')[:100000]
    print("Found " + str(rs.count()) + " reports...")
    i = 0
    for r in rs:
        i = i + 1
        #if i < 31271: continue
        ##if is_uninteresting_string(r.syscall_args[1]['str']): continue
        ##if not has_interesting_string(r.syscall_args[1]['str']): continue
        #if not has_tainted_fd_creator(r.syscall_args[0]['fd_creators']): continue
        ##if not has_interesting_fd_creator(r.syscall_args[0]['fd_creators']): continue
        ##if not has_nonfull_taint(r.syscall_args[0]['dword_taint']): continue
        #if is_empty_taint(r.syscall_args[1]['buf_taint']): continue
        if is_skip_backtrace(r.backtrace): continue
        print("========================================================")
        print("Report " + str(i) + " of " + str(len(rs)) + "...")
        custom_report_print(r)
        while True:
            inp = input("Either enter: (1) an empty string to continue, (2) an 's' to skip this backtrace or (3) a report number (hex) to view it...")
            if inp == '': break
            if inp == 's': set_skip_backtrace(r.backtrace); break
            try: report_num = int(inp, 16)
            except: continue
            print("Looking up report " + hex(report_num) + "...")
            tmpr = get_report(report_num, r.application_corepath, (r.pid, r.ppid, r.tid, r.ptid))
            custom_report_print(tmpr)
