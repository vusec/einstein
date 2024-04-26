from db.models import Report, RopReport, Limits
from django.db.models.fields.json import KT
from django.db.models import Q
from db.analyze import rs_in_app, SYSARGCOUNTS_SECSENS, SYSARGCOUNTS_FDCONF, SYSCALLS_SECSENS, SYSCALLS_FDCONF
import yaml, re
from itertools import chain, combinations

################

def print_rewrite_primitives_codeexec():
    # NOTE: We could probably also include execveat's arg0. (Although, we'd need to modify einstein_syscalls.cpp to ensure it's a dirfd.)
    c = Report.objects.filter(syscall='execve').filter(Q(has_arg0_uflow__isnull=False)|Q(has_arg1_uflow__isnull=False)|Q(has_arg2_uflow__isnull=False)).values('application', 'backtrace').distinct().count()
    c += Report.objects.filter(syscall='execveat').filter(Q(has_arg1_uflow__isnull=False)|Q(has_arg2_uflow__isnull=False)|Q(has_arg3_uflow__isnull=False)).values('application', 'backtrace').distinct().count()
    return c

def print_rewrite_primitives_depbypass():
    c = Report.objects.filter(Q(syscall='mmap')|Q(syscall='mprotect')).filter(has_arg0_uflow__isnull=False,syscall_args__2__dword__gte=4).values('application', 'backtrace').distinct().count() # Checking whether the prot argument is >= 4 is not a great way to check whether it has PROT_EXEC set...
    c += Report.objects.filter(Q(syscall='mmap')|Q(syscall='mprotect')).filter(has_arg2_uflow__isnull=False).values('application', 'backtrace').distinct().count()
    return c

def print_rewrite_primitives_filewhatwhere():
    return Report.objects.filter(Q(syscall='write')|Q(syscall='writev')|Q(syscall='pwrite64')|Q(syscall='pwritev')|Q(syscall='pwritev')|Q(syscall='pwritev2')|Q(syscall='sendfile')).filter(has_arg0_uflow__isnull=False,has_arg1_uflow__isnull=False,has_arg0_uflow__results__can_be_file_fd=True).values('application', 'backtrace').distinct().count()
def print_rewrite_primitives_filewhat():
    return Report.objects.filter(Q(syscall='write')|Q(syscall='writev')|Q(syscall='pwrite64')|Q(syscall='pwritev')|Q(syscall='pwritev')|Q(syscall='pwritev2')|Q(syscall='sendfile')).filter(has_arg0_uflow__isnull=True,has_arg1_uflow__isnull=False,syscall_args__0__this_fd_arg__type="FILE-FD").values('application', 'backtrace').distinct().count()
def print_rewrite_primitives_filewhere():
    return Report.objects.filter(Q(syscall='write')|Q(syscall='writev')|Q(syscall='pwrite64')|Q(syscall='pwritev')|Q(syscall='pwritev')|Q(syscall='pwritev2')|Q(syscall='sendfile')).filter(has_arg0_uflow__isnull=False,has_arg1_uflow__isnull=True,has_arg0_uflow__results__can_be_file_fd=True).values('application', 'backtrace').distinct().count()

def print_rewrite_primitives_socketwhatwhere():
    c = Report.objects.filter(Q(syscall='write')|Q(syscall='writev')|Q(syscall='pwrite64')|Q(syscall='pwritev')|Q(syscall='pwritev')|Q(syscall='pwritev2')|Q(syscall='sendfile')).filter(has_arg0_uflow__isnull=False,has_arg1_uflow__isnull=False,has_arg0_uflow__results__can_be_socket_fd=True).values('application', 'backtrace').distinct().count()
    c += Report.objects.filter(Q(syscall='sendmsg')|Q(syscall='sendmmsg')|Q(syscall='sendto')).filter(has_arg0_uflow__isnull=False,has_arg1_uflow__isnull=False).values('application', 'backtrace').distinct().count()
    c += Report.objects.filter(syscall='sendto').filter(has_arg1_uflow__isnull=False,has_arg4_uflow__isnull=False).values('application', 'backtrace').distinct().count()
    return c
def print_rewrite_primitives_socketwhat():
    c = Report.objects.filter(Q(syscall='write')|Q(syscall='writev')|Q(syscall='pwrite64')|Q(syscall='pwritev')|Q(syscall='pwritev')|Q(syscall='pwritev2')|Q(syscall='sendfile')).filter(has_arg0_uflow__isnull=True,has_arg1_uflow__isnull=False,syscall_args__0__this_fd_arg__type="SOCKET-FD").values('application', 'backtrace').distinct().count()
    c += Report.objects.filter(Q(syscall='sendmsg')|Q(syscall='sendmmsg')|Q(syscall='sendto')).filter(has_arg0_uflow__isnull=True,has_arg1_uflow__isnull=False).values('application', 'backtrace').distinct().count()
    c += Report.objects.filter(syscall='sendto').filter(has_arg1_uflow__isnull=False,has_arg4_uflow__isnull=True).values('application', 'backtrace').distinct().count()
    return c
def print_rewrite_primitives_socketwhere():
    c = Report.objects.filter(Q(syscall='write')|Q(syscall='writev')|Q(syscall='pwrite64')|Q(syscall='pwritev')|Q(syscall='pwritev')|Q(syscall='pwritev2')|Q(syscall='sendfile')).filter(has_arg0_uflow__isnull=False,has_arg1_uflow__isnull=True,has_arg0_uflow__results__can_be_socket_fd=True).values('application', 'backtrace').distinct().count()
    c += Report.objects.filter(Q(syscall='sendmsg')|Q(syscall='sendmmsg')|Q(syscall='sendto')).filter(has_arg0_uflow__isnull=False,has_arg1_uflow__isnull=True).values('application', 'backtrace').distinct().count()
    c += Report.objects.filter(syscall='sendto').filter(has_arg1_uflow__isnull=True,has_arg4_uflow__isnull=False).values('application', 'backtrace').distinct().count()
    return c

def print_rewrite_primitives():
    print("\033[4m" + "Confirmed exploit primitives:" + "\033[0m")
    fmtstr = '{0: <28}'
    total = 0
    this_count = print_rewrite_primitives_codeexec(); total += this_count; print(fmtstr.format("- Code-execution: ") + str(this_count))
    this_count = print_rewrite_primitives_depbypass(); total += this_count; print(fmtstr.format("- DEP-bypass: ") + str(this_count))
    this_count = print_rewrite_primitives_filewhatwhere(); total += this_count; print(fmtstr.format("- Write-what-where: ") + str(this_count))
    this_count = print_rewrite_primitives_filewhat(); total += this_count; print(fmtstr.format("- Write-what: ") + str(this_count))
    this_count = print_rewrite_primitives_filewhere(); total += this_count; print(fmtstr.format("- Write-where: ") + str(this_count))
    this_count = print_rewrite_primitives_socketwhatwhere(); total += this_count; print(fmtstr.format("- Send-what-where: ") + str(this_count))
    this_count = print_rewrite_primitives_socketwhat(); total += this_count; print(fmtstr.format("- Send-what: ") + str(this_count))
    this_count = print_rewrite_primitives_socketwhere(); total += this_count; print(fmtstr.format("- Send-where: ") + str(this_count))
    #print(fmtstr.format("- (TODO: Primitives using FDs besides files and sockets?)"))
    print(fmtstr.format("* TOTAL: ") + str(total))
    print()

################

def print_syscall_rewrite_table_get_arg(syscall, arg_num, arg_count):
    fmt_str = '{0: ^13}'
    if arg_num >= arg_count: return fmt_str.format(" ")
    f = Report.objects.filter(syscall=syscall,**{Limits.liflow(arg_num,'match_len',Limits.MATCH_LEN_GET_IFLOWS):True}).values('application', 'backtrace', 'has_arg'+str(arg_num)+'_uflow')
    f_count = f.values('application', 'backtrace').distinct().count()
    fu_count = f.exclude(**{'has_arg'+str(arg_num)+'_uflow':None}).values('application', 'backtrace').distinct().count()
    if f_count == 0: s = " - "
    elif fu_count == 0: s = str(f_count)
    else: s = str(f_count) + " (" + str(round(100*float(fu_count)/float(f_count))) + "%)"
    return fmt_str.format(s)

def print_syscall_rewrite_table(sys_arg_counts):
    table_s = "\033[4m" + "Syscalls  | " + '{0: ^95}'.format("Total found where this arg has an identity flow of length ≥ " + str(Limits.MATCH_LEN_GET_IFLOWS) +" (% that are practically unconstrained, if any)") + "\033[0m\n"
    skipped_syscalls = []
    for syscall, arg_count in sys_arg_counts.items():
        #this_syscall_count = Report.objects.filter(syscall=syscall).values('application', 'backtrace').distinct().count()
        this_syscall_count = Report.objects.filter(syscall=syscall).annotate(
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
                Q(curr_limit5='true')).values('application', 'backtrace').distinct().count()
        if (this_syscall_count == 0):
            skipped_syscalls += [syscall]
            continue
        table_s += '{0: <9}'.format(syscall)
        for arg_num in range(0, 6):
            table_s += " | " + print_syscall_rewrite_table_get_arg(syscall, arg_num, arg_count)
        table_s += "\n"
    if skipped_syscalls:
        table_s += "* Syscalls with no identity flow of length ≥ " + str(Limits.MATCH_LEN_GET_IFLOWS) + ": "
        for syscall in skipped_syscalls:
            table_s += syscall + " "
    print(table_s + "\n")

def print_syscall_rewrite_table_secsens():
    print("Identity flows of length ≥ 4, per security-sensitive syscall argument:")
    print_syscall_rewrite_table(SYSARGCOUNTS_SECSENS)

def print_syscall_rewrite_table_fdconf():
    print("Identity flows of length ≥ 4, per FD-configuring syscall argument:")
    print_syscall_rewrite_table(SYSARGCOUNTS_FDCONF)

################

def print_syscall_table_get_arg(syscall, arg_num, arg_count):
    fmt_str = '{0: ^13}'
    if arg_num >= arg_count: return fmt_str.format(" ")
    tainted_count = Report.objects.filter(syscall=syscall,**{'has_arg'+str(arg_num)+'_taint':True}).values('application', 'backtrace').distinct().count()
    iflow_count = Report.objects.filter(syscall=syscall,**{Limits.liflow_default(arg_num):True}).values('application', 'backtrace').distinct().count()
    if tainted_count == 0: s = " - "
    elif iflow_count == 0: s = str(tainted_count)
    else: s = str(tainted_count) + " (" + str(round(100*float(iflow_count)/float(tainted_count))) + "%)"
    return fmt_str.format(s)

def print_syscall_table():
    print("Vulnerable gadgets found per syscall and argument type:")
    table_s = "\033[4m" + "Syscalls | Total covered |" + '{0: ^95}'.format("Total found where this arg has a dataflow from attacker data (% that are identity dataflows, if any)") + "\033[0m\n"
    skipped_syscalls = []
    for syscall, arg_count in SYSARGCOUNTS_SECSENS.items():
        this_syscall_count = Report.objects.filter(syscall=syscall).values('application', 'backtrace').distinct().count()
        if (this_syscall_count == 0):
            skipped_syscalls += [syscall]
            continue
        table_s += '{0: <9}'.format(syscall) + "|"
        table_s += '{0: ^14}'.format(str(this_syscall_count))
        for arg_num in range(0, 6):
            table_s += " | " + print_syscall_table_get_arg(syscall, arg_num, arg_count)
        table_s += "\n"
    if skipped_syscalls:
        table_s += "* Syscalls not covered: "
        for syscall in skipped_syscalls:
            table_s += syscall + " "
    print(table_s + "\n")

################

def app_to_table_string(app):
    if (app == "memcached-debug"): return "memcached"
    if (app == "redis-server"): return "redis"
    if (app == "httpd"): return "apache"
    return app

def print_apps_table_line(app_prefix, taints, iflows):
    pct = '' if taints == 0 else " (" + str(round(100 * float(iflows) / float(taints))) + "% with an iflow)"
    print(app_prefix + ": " + str(taints) + " gadgets" + pct)

def print_apps_table():
    print("Vulnerable gadgets found per target application:")
    appnames = sorted([(app_to_table_string(app), app) for app in Report.objects.values_list('application', flat=True).distinct()])
    total_tainted = 0
    total_iflow = 0
    for appname,app in appnames:
        this_app_rs = Report.objects.filter(syscall__in=SYSCALLS_SECSENS,tainted=True,application=app)
        taints = this_app_rs.values('backtrace').distinct().count()
        iflows = this_app_rs.annotate(
            curr_limit0=KT(Limits.liflow_default(0)),
            curr_limit1=KT(Limits.liflow_default(1)),
            curr_limit2=KT(Limits.liflow_default(2)),
            curr_limit3=KT(Limits.liflow_default(3)),
            curr_limit4=KT(Limits.liflow_default(4)),
            curr_limit5=KT(Limits.liflow_default(5))).filter(
                Q(curr_limit0='true') |
                Q(curr_limit1='true') |
                Q(curr_limit2='true') |
                Q(curr_limit3='true') |
                Q(curr_limit4='true') |
                Q(curr_limit5='true')).values('backtrace').distinct().count()
        print_apps_table_line("- " + appname, taints, iflows)
        total_tainted += taints
        total_iflow += iflows
    print_apps_table_line("* TOTAL", total_tainted, total_iflow)
    print()

################

def print_execves():
    print("Arguments to tainted execves (TODO: include execveat):")
    sl = []
    rs = Report.objects.filter(syscall='execve', tainted=True).values('syscall_args__0__str', 'syscall_args__1__pchars__0__str', 'syscall_args__1__pchars__1__str', 'syscall_args__1__pchars__2__str').distinct()
    for r in rs:
        s = '- '
        if r['syscall_args__0__str'] != r['syscall_args__1__pchars__0__str']: s += "(filename is different from argv[0]; filename = " + str(r['syscall_args__0__str'] or '') + ") "
        s += str(r['syscall_args__1__pchars__0__str'] or '')
        if r['syscall_args__1__pchars__1__str']: s += " " + r['syscall_args__1__pchars__1__str']
        if r['syscall_args__1__pchars__2__str']: s += " " + r['syscall_args__1__pchars__2__str'] + " ..."
        s = re.sub(r'/.*/apps/', './', s)
        sl.append(s)
    for s in sorted(sl): print(s)
    print()

################

def print_tainted_syscall_num():
    rs = Report.objects.filter(has_syscallnr_taint=True).values('application', 'syscall', 'syscall_nr_taint').distinct()
    if not rs:
        print("Found no cases with a tainted syscall number (as expected).\n")
        return
    s = "*** FOUND CASE(S) WITH A TAINTED SYSCALL NUMBER: ***\n"
    for r in rs: s += "- application: " + r['application'] + ", syscall: " + r['syscall'] + ", syscall_nr_taint: " + yaml.dump(r['syscall_nr_taint'], default_flow_style=True, width=200)
    print(s)

################

BANNER="=======================================================================\n"

def print_candidates():
    print(BANNER + "Candidate exploit tables:\n")
    #print_execves()
    print_syscall_table()
    #print_tainted_syscall_num()
    print_apps_table()
    print(BANNER)

def print_exploits():
    print(BANNER + "Confirmed exploit tables:\n")
    print_syscall_rewrite_table_secsens()
    print_syscall_rewrite_table_fdconf()
    print_rewrite_primitives()
    print(BANNER)

################################################################################################################################

def get_per_syscall_count(syscall, limit_field, limit_val):
    rs = Report.objects.filter(syscall=syscall,tainted=True)
    return rs.annotate(curr_limit0=KT(Limits.liflow(0, limit_field, limit_val)),
                       curr_limit1=KT(Limits.liflow(1, limit_field, limit_val)),
                       curr_limit2=KT(Limits.liflow(2, limit_field, limit_val)),
                       curr_limit3=KT(Limits.liflow(3, limit_field, limit_val)),
                       curr_limit4=KT(Limits.liflow(4, limit_field, limit_val)),
                       curr_limit5=KT(Limits.liflow(5, limit_field, limit_val))).filter(Q(curr_limit0='true') |
                                                                                        Q(curr_limit1='true') |
                                                                                        Q(curr_limit2='true') |
                                                                                        Q(curr_limit3='true') |
                                                                                        Q(curr_limit4='true') |
                                                                                        Q(curr_limit5='true')).values('application', 'backtrace').distinct().count()

def get_per_syscall_arg_count(syscall, limit_field, limit_val):
    rs = Report.objects.filter(syscall=syscall,tainted=True)
    return rs.annotate(curr_limit=KT(Limits.liflow(0, limit_field, limit_val))).filter(curr_limit='true').values('application', 'backtrace').distinct().count() + \
           rs.annotate(curr_limit=KT(Limits.liflow(1, limit_field, limit_val))).filter(curr_limit='true').values('application', 'backtrace').distinct().count() + \
           rs.annotate(curr_limit=KT(Limits.liflow(2, limit_field, limit_val))).filter(curr_limit='true').values('application', 'backtrace').distinct().count() + \
           rs.annotate(curr_limit=KT(Limits.liflow(3, limit_field, limit_val))).filter(curr_limit='true').values('application', 'backtrace').distinct().count() + \
           rs.annotate(curr_limit=KT(Limits.liflow(4, limit_field, limit_val))).filter(curr_limit='true').values('application', 'backtrace').distinct().count() + \
           rs.annotate(curr_limit=KT(Limits.liflow(5, limit_field, limit_val))).filter(curr_limit='true').values('application', 'backtrace').distinct().count()

################

def print_graphs_matchlen():
    graph = []
    for match_len in range(Limits.MATCH_LEN_MIN,Limits.MATCH_LEN_MAX+1):
        this_match_len = {'match_len': match_len, 'syscall_counts': {}}
        for syscall,_ in SYSARGCOUNTS_SECSENS.items():
            this_match_len['syscall_counts'][syscall] = get_per_syscall_arg_count(syscall, 'match_len', match_len)
        #print(this_match_len)
        graph.append(this_match_len)
    #graph = [{'match_len': 1, 'syscall_counts': {'execve': 13, 'execveat': 0, 'mmap': 18, 'mprotect': 55, 'mremap': 0, 'remap_file_pages': 0, 'sendmmsg': 0, 'sendmsg': 11, 'sendto': 125, 'write': 5068}},{'match_len': 2, 'syscall_counts': {'execve': 13, 'execveat': 0, 'mmap': 18, 'mprotect': 13, 'mremap': 0, 'remap_file_pages': 0, 'sendmmsg': 0, 'sendmsg': 10, 'sendto': 114, 'write': 4980}},{'match_len': 3, 'syscall_counts': {'execve': 13, 'execveat': 0, 'mmap': 18, 'mprotect': 13, 'mremap': 0, 'remap_file_pages': 0, 'sendmmsg': 0, 'sendmsg': 10, 'sendto': 114, 'write': 4980}},{'match_len': 4, 'syscall_counts': {'execve': 13, 'execveat': 0, 'mmap': 18, 'mprotect': 13, 'mremap': 0, 'remap_file_pages': 0, 'sendmmsg': 0, 'sendmsg': 10, 'sendto': 113, 'write': 4955}},{'match_len': 5, 'syscall_counts': {'execve': 13, 'execveat': 0, 'mmap': 18, 'mprotect': 13, 'mremap': 0, 'remap_file_pages': 0, 'sendmmsg': 0, 'sendmsg': 10, 'sendto': 113, 'write': 4946}},{'match_len': 6, 'syscall_counts': {'execve': 13, 'execveat': 0, 'mmap': 18, 'mprotect': 13, 'mremap': 0, 'remap_file_pages': 0, 'sendmmsg': 0, 'sendmsg': 10, 'sendto': 58, 'write': 2724}},{'match_len': 7, 'syscall_counts': {'execve': 13, 'execveat': 0, 'mmap': 8, 'mprotect': 10, 'mremap': 0, 'remap_file_pages': 0, 'sendmmsg': 0, 'sendmsg': 9, 'sendto': 57, 'write': 2694}},{'match_len': 8, 'syscall_counts': {'execve': 13, 'execveat': 0, 'mmap': 8, 'mprotect': 5, 'mremap': 0, 'remap_file_pages': 0, 'sendmmsg': 0, 'sendmsg': 8, 'sendto': 52, 'write': 2688}},{'match_len': 9, 'syscall_counts': {'execve': 13, 'execveat': 0, 'mmap': 8, 'mprotect': 5, 'mremap': 0, 'remap_file_pages': 0, 'sendmmsg': 0, 'sendmsg': 7, 'sendto': 51, 'write': 2685}},{'match_len': 10, 'syscall_counts': {'execve': 13, 'execveat': 0, 'mmap': 8, 'mprotect': 5, 'mremap': 0, 'remap_file_pages': 0, 'sendmmsg': 0, 'sendmsg': 7, 'sendto': 50, 'write': 2678}},{'match_len': 11, 'syscall_counts': {'execve': 13, 'execveat': 0, 'mmap': 8, 'mprotect': 5, 'mremap': 0, 'remap_file_pages': 0, 'sendmmsg': 0, 'sendmsg': 7, 'sendto': 49, 'write': 2669}},{'match_len': 12, 'syscall_counts': {'execve': 13, 'execveat': 0, 'mmap': 8, 'mprotect': 5, 'mremap': 0, 'remap_file_pages': 0, 'sendmmsg': 0, 'sendmsg': 7, 'sendto': 49, 'write': 2668}},{'match_len': 13, 'syscall_counts': {'execve': 13, 'execveat': 0, 'mmap': 8, 'mprotect': 5, 'mremap': 0, 'remap_file_pages': 0, 'sendmmsg': 0, 'sendmsg': 7, 'sendto': 49, 'write': 2667}},{'match_len': 14, 'syscall_counts': {'execve': 13, 'execveat': 0, 'mmap': 8, 'mprotect': 5, 'mremap': 0, 'remap_file_pages': 0, 'sendmmsg': 0, 'sendmsg': 7, 'sendto': 49, 'write': 2667}},{'match_len': 15, 'syscall_counts': {'execve': 13, 'execveat': 0, 'mmap': 8, 'mprotect': 5, 'mremap': 0, 'remap_file_pages': 0, 'sendmmsg': 0, 'sendmsg': 7, 'sendto': 49, 'write': 2619}},{'match_len': 16, 'syscall_counts': {'execve': 13, 'execveat': 0, 'mmap': 8, 'mprotect': 5, 'mremap': 0, 'remap_file_pages': 0, 'sendmmsg': 0, 'sendmsg': 7, 'sendto': 48, 'write': 2619}}]
    maxes = graph[0]['syscall_counts']
    print("IFlows vs. match length:")
    s = 'match_len'
    for syscall in graph[0]['syscall_counts']:
        if maxes[syscall] == 0: continue
        s += ";" + syscall + " (of "+ str(maxes[syscall]) +" iflow args across " + str(get_per_syscall_count(syscall,'match_len',1)) + " syscalls)"
    print(s)
    for ml in graph:
        s = str(ml['match_len'])
        for syscall in ml['syscall_counts']:
            if maxes[syscall] == 0: continue
            s += ";" + str(100 * float(ml['syscall_counts'][syscall]) / float(maxes[syscall]))
        print(s)

def print_graphs_ptrdepth():
    graph = []
    for ptr_depth_limit in range(Limits.PTR_DEPTH_LIMIT_MIN,Limits.PTR_DEPTH_LIMIT_MAX+1):
        count = Report.objects.exclude(syscall='write').annotate(curr_limit=KT(Limits.liflow(0, 'ptr_depth_limit', ptr_depth_limit))).filter(curr_limit='true').values('application', 'backtrace').distinct().count() + \
                Report.objects.exclude(syscall='write').annotate(curr_limit=KT(Limits.liflow(1, 'ptr_depth_limit', ptr_depth_limit))).filter(curr_limit='true').values('application', 'backtrace').distinct().count() + \
                Report.objects.exclude(syscall='write').annotate(curr_limit=KT(Limits.liflow(2, 'ptr_depth_limit', ptr_depth_limit))).filter(curr_limit='true').values('application', 'backtrace').distinct().count() + \
                Report.objects.exclude(syscall='write').annotate(curr_limit=KT(Limits.liflow(3, 'ptr_depth_limit', ptr_depth_limit))).filter(curr_limit='true').values('application', 'backtrace').distinct().count() + \
                Report.objects.exclude(syscall='write').annotate(curr_limit=KT(Limits.liflow(4, 'ptr_depth_limit', ptr_depth_limit))).filter(curr_limit='true').values('application', 'backtrace').distinct().count() + \
                Report.objects.exclude(syscall='write').annotate(curr_limit=KT(Limits.liflow(5, 'ptr_depth_limit', ptr_depth_limit))).filter(curr_limit='true').values('application', 'backtrace').distinct().count()
        graph += [(ptr_depth_limit, count)]
    print("IFlows vs. pointer depth:")
    for x, y in graph: print(str(x) + ";" + str(y))

def print_graphs_tagspertagset():
    graph = []
    for tags_per_tagset in range(Limits.TAGS_PER_TAGSET_MIN,Limits.TAGS_PER_TAGSET_MAX+1):
        count = Report.objects.exclude(syscall='write').annotate(curr_limit=KT(Limits.liflow(0, 'tags_per_tagset', tags_per_tagset))).filter(curr_limit='true').values('application', 'backtrace').distinct().count() + \
                Report.objects.exclude(syscall='write').annotate(curr_limit=KT(Limits.liflow(1, 'tags_per_tagset', tags_per_tagset))).filter(curr_limit='true').values('application', 'backtrace').distinct().count() + \
                Report.objects.exclude(syscall='write').annotate(curr_limit=KT(Limits.liflow(2, 'tags_per_tagset', tags_per_tagset))).filter(curr_limit='true').values('application', 'backtrace').distinct().count() + \
                Report.objects.exclude(syscall='write').annotate(curr_limit=KT(Limits.liflow(3, 'tags_per_tagset', tags_per_tagset))).filter(curr_limit='true').values('application', 'backtrace').distinct().count() + \
                Report.objects.exclude(syscall='write').annotate(curr_limit=KT(Limits.liflow(4, 'tags_per_tagset', tags_per_tagset))).filter(curr_limit='true').values('application', 'backtrace').distinct().count() + \
                Report.objects.exclude(syscall='write').annotate(curr_limit=KT(Limits.liflow(5, 'tags_per_tagset', tags_per_tagset))).filter(curr_limit='true').values('application', 'backtrace').distinct().count()
        graph += [(tags_per_tagset, count)]
    print("IFlows vs. tags per tagset:")
    for x, y in graph: print(str(x) + ";" + str(y))

################

def powerset(iterable):
    "powerset([1,2,3]) --> () (1,) (2,) (3,) (1,2) (1,3) (2,3) (1,2,3)"
    s = list(iterable)
    return chain.from_iterable(combinations(s, r) for r in range(len(s)+1))

def get_syscall_iflow_args_count(syscall, args_combo):
    return Report.objects.filter(syscall=syscall).annotate(curr_limit0=KT(Limits.liflow_default(0)),
                                                           curr_limit1=KT(Limits.liflow_default(1)),
                                                           curr_limit2=KT(Limits.liflow_default(2)),
                                                           curr_limit3=KT(Limits.liflow_default(3)),
                                                           curr_limit4=KT(Limits.liflow_default(4)),
                                                           curr_limit5=KT(Limits.liflow_default(5)),).filter(curr_limit0='true' if 0 in args_combo else 'false',
                                                                                                             curr_limit1='true' if 1 in args_combo else 'false',
                                                                                                             curr_limit2='true' if 2 in args_combo else 'false',
                                                                                                             curr_limit3='true' if 3 in args_combo else 'false',
                                                                                                             curr_limit4='true' if 4 in args_combo else 'false',
                                                                                                             curr_limit5='true' if 5 in args_combo else 'false').values('application', 'backtrace').distinct().count()

def print_syscall_arg_combos():
    combo_counts = []
    for syscall,num_args in SYSARGCOUNTS_SECSENS.items():
        all_combos = powerset(list(range(0,num_args)))
        for combo in all_combos:
            if combo == (): continue # Skip case where no arg has an iflow
            count = get_syscall_iflow_args_count(syscall, combo)
            if count == 0: continue # Skip if no iflows for this arg combo
            combo_count = {'syscall':syscall, 'args':combo, 'count':count}
            #print(combo_count)
            combo_counts.append(combo_count)
    combo_counts = sorted(combo_counts, key=lambda d: (d['syscall'], -d['count']))
    #combo_counts = [{'syscall': 'execve', 'args': (0, 1), 'count': 5}, {'syscall': 'execve', 'args': (0, 1, 2), 'count': 1}, {'syscall': 'mmap', 'args': (1,), 'count': 14}, {'syscall': 'mmap', 'args': (2,), 'count': 1}, {'syscall': 'mmap', 'args': (3,), 'count': 1}, {'syscall': 'mmap', 'args': (1, 3), 'count': 1}, {'syscall': 'mprotect', 'args': (0,), 'count': 40}, {'syscall': 'mprotect', 'args': (1,), 'count': 10}, {'syscall': 'mprotect', 'args': (0, 1), 'count': 3}, {'syscall': 'mprotect', 'args': (1, 2), 'count': 1}, {'syscall': 'sendmsg', 'args': (0,), 'count': 4}, {'syscall': 'sendmsg', 'args': (0, 1), 'count': 4}, {'syscall': 'sendto', 'args': (1,), 'count': 95}, {'syscall': 'sendto', 'args': (1, 2), 'count': 15}, {'syscall': 'sendto', 'args': (2,), 'count': 6}, {'syscall': 'sendto', 'args': (0,), 'count': 2}, {'syscall': 'sendto', 'args': (0, 1), 'count': 1}, {'syscall': 'write', 'args': (0, 1), 'count': 2286}, {'syscall': 'write', 'args': (0,), 'count': 2221}, {'syscall': 'write', 'args': (1,), 'count': 249}, {'syscall': 'write', 'args': (0, 1, 2), 'count': 24}, {'syscall': 'write', 'args': (0, 2), 'count': 19}, {'syscall': 'write', 'args': (1, 2), 'count': 2}]
    for combo_count in combo_counts:
        arg_s = 'i' if 0 in combo_count['args'] else '-'
        for i in range(1,SYSARGCOUNTS_SECSENS[combo_count['syscall']]): arg_s += ',i' if i in combo_count['args'] else ',-'
        print(combo_count['syscall'] + "(" + arg_s + "): " + str(combo_count['count']))

################

def print_graphs():
    print_graphs_matchlen()
    print_graphs_ptrdepth()
    print_graphs_tagspertagset()
    print_syscall_arg_combos()

################################################################################################################################
################################################################################################################################

def print_rop_line(ctx, app, btype):
    num_reg_taint = RopReport.objects.filter(application=app, tainted=True, has_taint=True, operand_type=btype).values(ctx).distinct().count()
    num_reg_iflow = RopReport.objects.filter(application=app, tainted=True, has_iflow=True, operand_type=btype).values(ctx).distinct().count()
    s = "- " + app + " (" + btype + " operand): " + str(num_reg_iflow) + "/"  + str(num_reg_taint)
    if num_reg_iflow != 0: s += " = " + str(round(100 * float(num_reg_iflow)/float(num_reg_taint))) + "%"
    print(s)

def print_rop_candidates():
    for ctx in ['backtrace', 'rip']:
        print("num_iflow/num_taint per app (by " + ctx +")...")
        for app in RopReport.objects.values_list('application', flat=True).distinct():
            print_rop_line(ctx, app, "register")
            print_rop_line(ctx, app, "memory")
        print("")
