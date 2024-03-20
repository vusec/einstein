from db.models import Report, Limits
from db.output import SYSARGCOUNTS_SECSENS
from db.analyze import get_report
from django.db.models.fields.json import KT
from django.db.models import Q
import json
import re
import subprocess
import os
import time
import signal
import atexit

PATH_CONFIG = "/build/einstein-config.json"
PATHS = {"nginx": "/apps/nginx-1.23.0", "httpd": "/apps/apache-2.4.54", "lighttpd": "/apps/lighttpd-1.4.65"}
TASKNAMES = {"nginx": "nginx", "httpd": "apache", "lighttpd": "lighttpd"}

BASE_CONF = {"hook_writes": True, "do_rewrites": True}

TIMEOUT_TEST = 120
REPORTS_LIMIT = 10

def EXIT_ERR(msg=""):
    if msg: print(msg)
    os._exit(1)

################################################################
#### Setting up the test

def parse_testcase(testcase, application):
    if application == "nginx" or application == "httpd":
        # "binary_upgrade.t:49:Test::Nginx::run" --> "binary_upgrade.t"
        # "t/modules/ext_filter.t:29:Apache::TestRequest::__ANON__" --> "t/modules/ext_filter.t"
        return re.split(r':', testcase)[0]
    if application == "lighttpd":
        # "./request.t:1304:LightyTest::handle_http" --> "request"
        return re.split(r'\.t|\.\/', testcase)[1]
    else:
        print("WARNING: Application '" + application + "' not handled by parse_testcase()")
        return testcase

def write_config(config):
    rewrites_no_bt = {'rewrites': [{i:tmpr[i] for i in tmpr if i!='backtrace'} for tmpr in config['rewrites']]}
    print("Setting config to have rewrites (excluding backtrace): " + json.dumps(rewrites_no_bt))
    with open(ROOT + PATH_CONFIG, "w") as f:
        f.write(json.dumps(config))

def write_testcase(application, testcase):
    print("Setting testcase: " + testcase)
    with open(ROOT + PATHS[application] + "/runbench.tests.tmp", "w") as f:
        f.write(testcase + "\n")

################################################################
#### Running the test

def run_test_killall(application, p):
    print("Killing " + application + " tests and server...")
    try:
        os.killpg(os.getpgid(p.pid), signal.SIGTERM) # Kill the test suite
    except ProcessLookupError:
        pass # The test suite probably exited on its own
    subprocess.run("cd " + ROOT + PATHS[application] + " && ./serverctl stop", shell=True) # Kill the server

def run_test_check_grep(application, s):
    cmd = 'grep -rI "' + s + '" ' + ROOT + PATHS[application] + '/.tmp/'
    proc = subprocess.run(cmd, shell=True, capture_output=True)
    if proc.returncode != 0 and proc.returncode != 1:
        EXIT_ERR("ERROR: Command returned an error: '" + cmd + "'")
    return proc.returncode, proc.stdout.decode()

def run_test_check_success(application):
    rc,outp = run_test_check_grep(application, "REWRITE_EVAL_FINISHED:SUCCESS")
    if rc == 0:
        print("Rewrite successful! Found: '" + outp + "'")
        return True
    return False

def run_test_check_failure(application):
    rc,outp = run_test_check_grep(application, "REWRITE_EVAL_FINISHED:FAIL")
    if rc == 0:
        print("Rewrite unsuccessful: failed to perform any rewrites. Found: '" + outp + "'")
        outp2 = subprocess.run('grep -nrIv "Found syscall\|thread finished\|thread started\|process started\|process finished" ' + ROOT + PATHS[application] + '/.tmp/ | sort', shell=True, capture_output=True).stdout.decode()
        print("***********")
        print("Full output: " + outp2)
        print("***********")
        return True
    return False

def run_test_finish(application, p):
    time.sleep(2) # Just to make sure 'reports-clean' finishes
    for _ in range(0, TIMEOUT_TEST):
        if run_test_check_success(application): return True
        if run_test_check_failure(application): return False
        if p.poll() is not None:
            print("Rewrite unsuccessful: test finished.")
            return False
        time.sleep(1)
    print("Rewrite unsuccessful: test timed out.")
    return False

def run_test(application):
    p = subprocess.Popen(["task", "reports-clean", TASKNAMES[application] + "-eval-tmp"], cwd=ROOT, env=dict(os.environ, PWD=ROOT), preexec_fn=os.setsid)
    atexit.register(run_test_killall, application, p)
    b = run_test_finish(application, p)
    run_test_killall(application, p)
    atexit.unregister(run_test_killall)
    return b

################################################################
#### Helpers: Saving/reverting reports

def reports_save():
    print("Saving current reports...")
    cmdarr = ["task", "reports-save"]
    try:
        subprocess.run(cmdarr, cwd=ROOT, env=dict(os.environ, PWD=ROOT), check=True)
    except subprocess.CalledProcessError as e:
        EXIT_ERR("Error running cmd '" + str(cmdarr) + "'.")
    atexit.register(reports_revert) # Let's make sure to revert the reports if this eval is killed early

def reports_revert():
    print("Reverting reports to be current...")
    subprocess.run(["task", "reports-revert"], cwd=ROOT, env=dict(os.environ, PWD=ROOT))
    atexit.unregister(reports_revert)

#### Helpers: done_iflows cache
done_iflows = {}
# TODO: Add testcase back into the done_iflows key?
def is_in_done_iflows(config_rewrites, testcase): return str(config_rewrites) in done_iflows
def get_done_iflows(config_rewrites, testcase): return done_iflows[str(config_rewrites)]
def add_to_done_iflows(config_rewrites, testcase, b): done_iflows[str(config_rewrites)] = b

# Saving uflows (maybe move this to models.py?)
def uflow_done(r, arg_num, config, save_uflow):
    if save_uflow:
        r.set_uflow(arg_num, config)
        r.set_uflow_eval_done(arg_num,True)
        r.save()
    return config

# Combine configs (for multiple uflows)
def configs_combine(c1,c2):
    if not c1: return c2
    if not c2: return c1
    return {"rewrites": c1["rewrites"]+c2["rewrites"],
                                    "options": BASE_CONF,
                                    "results": {k:(c1["results"][k] or c2["results"][k]) for k in sorted(set().union(c1["results"].keys(),c2["results"].keys()))}} # Take the boolean OR of each result

# Whether a syscall configures a type of FD
def can_be_file_fd(syscall): return syscall in ['creat', 'open', 'openat', 'openat2']
def can_be_socket_fd(syscall): return syscall in ['bind', 'connect', 'setsockopt', 'socket', 'socketpair']
def can_be_other_fd(syscall): return syscall in ['dup', 'dup2', 'dup3']

################################################################

# Returns {config} if uflow, or None if no uflow
def rewrite_eval_report_argval(r, arg_num, debug_str, save_uflow):
    if r.get_uflow_eval_done(arg_num): return r.get_uflow(arg_num) # No need to verify the same report again if we know it has a uflow
    iflows = r.get_iflows_list(arg_num)
    if not iflows: return uflow_done(r, arg_num, None, save_uflow)
    for iflow_num,iflow in enumerate(iflows,1):
        print("========================================")
        # TODO: Expand this to multiple simultaneous rewrites. For now, we'll just do one rewrite per conf.
        config = {  "rewrites": [{"type": iflow["type"], "application": r.application,
                        "syscall": r.syscall, "syscall_arg_num": arg_num,
                        "address": iflow["addr"], "expected_vals": iflow["vals"],
                        "ptr_depth": iflow["ptr_depth"], "write_vuln_count": r.application_corenum,
                        "backtrace": r.backtrace}],
                    "options": BASE_CONF,
                    "results": {"can_be_file_fd":can_be_file_fd(r.syscall), "can_be_socket_fd":can_be_socket_fd(r.syscall), "can_be_other_fd":can_be_other_fd(r.syscall)}}
        testcase = parse_testcase(r.application_testcase, r.application)
        if is_in_done_iflows(config["rewrites"], testcase):
            # No need to evalute the same iflow multiple times
            if get_done_iflows(config["rewrites"], testcase) == False: continue
            elif get_done_iflows(config["rewrites"], testcase) == True: return config
        write_config(config)
        write_testcase(r.application, testcase)
        print("Core: " + r.application_corepath)
        print("Testing " + debug_str + ", iflow " + str(iflow_num) + "/" + str(len(iflows)))
        #input("======================================== Press enter to continue...")
        iflow_has_uflow = run_test(r.application)
        print("Verified: " + str(iflow_has_uflow))
        add_to_done_iflows(config["rewrites"], testcase, iflow_has_uflow)
        #input("======================================== Press enter to continue...")
        if iflow_has_uflow: return uflow_done(r, arg_num, config, save_uflow) # No need to verify different iflows of the same report if we know it has one uflow
    return uflow_done(r, arg_num, None, save_uflow)

# Returns True if uflow, or False if no uflow
def rewrite_eval_report_arg(r, arg_num, debug_str):
    if 'fd_creators' not in r.syscall_args[arg_num]:
        # This is just a normal, non-chained argument
        argval_uflow = rewrite_eval_report_argval(r, arg_num, debug_str, True)
        return argval_uflow is not None

    # Perform rewrite eval for this FD arg val (i.e., not the I/O stream itself)
    all_uflow = rewrite_eval_report_argval(r, arg_num, debug_str, False)

    # Get list of fds_to_check
    if all_uflow: fds_to_check = r.syscall_args[arg_num]['fd_creators'] # This argument may be an indirectly-controllable FD (i.e., we can check _any_ fd_creator)
    else: fds_to_check = [r.syscall_args[arg_num]['this_fd_arg']] # This argument can only be a directly-controllable FD (i.e., we can _only_ check this_fd_arg)

    # Perform rewrite eval for each fd in fds_to_check (i.e., each potential I/O stream)
    for fd_to_check in fds_to_check:
        if all_uflow and ((all_uflow['results']['can_be_file_fd'] and fd_to_check['type'] == "FILE-FD") or \
           (all_uflow['results']['can_be_socket_fd'] and fd_to_check['type'] == "SOCKET-FD")):
            continue # No need to verify the same FD type multiple times if we already know this report has a uflow from that FD type
        if fd_to_check['type'] == "DUP-FD": print("TODO: Handle DUP-FD...")
        if fd_to_check['report_num'] == 0: continue
        fdc_r = get_report(fd_to_check['report_num'], r.application_corepath, (r.pid, r.ppid, r.tid, r.ptid))
        chain_arg_count = len(fdc_r.syscall_args)
        for chain_arg_num in range(0, chain_arg_count):
            chain_debug_str = "(FD-CONFIGURING SYSCALL) " + fdc_r.syscall + ": arg " + str(chain_arg_num+1) + "/" + str(chain_arg_count)
            argchain_uflow = rewrite_eval_report_argval(fdc_r, chain_arg_num, chain_debug_str, True)
            if argchain_uflow:
                all_uflow = configs_combine(all_uflow, argchain_uflow) # TODO: Evaluate the combined config?
                break # No need to verify the same fd-creator multiple times if we know it has a uflow
    uflow_done(r, arg_num, all_uflow, True)
    return all_uflow is not None

def rewrite_eval(LROOT):
    global ROOT
    ROOT=LROOT
    reports_save()
    # For each syscall --> for each syscall arg --> for each (app,bt) pair --> for each iflow
    for syscall, arg_count in SYSARGCOUNTS_SECSENS.items():
        for arg_num in range(0,arg_count):
            # TODO: Format done_iflows differently then clear the 'done_iflows' for THIS syscall arg num (but keep the FD-configuring 'done_iflows')
            rs_syscall = Report.objects.filter(syscall=syscall,**{Limits.liflow(arg_num,'match_len',Limits.MATCH_LEN_GET_IFLOWS):True})
            appbts_todo = rs_syscall.filter(**{'arg'+str(arg_num)+'_done_uflow_eval':False}).values_list('application', 'backtrace').distinct()
            appbts_done = rs_syscall.filter(**{'has_arg'+str(arg_num)+'_uflow__isnull':False}).values_list('application', 'backtrace').distinct()
            COUNT_APPBTS = len(appbts_todo)
            for appbt_nr,(app,bt) in enumerate(appbts_todo,1):
                if (app,bt) in appbts_done: continue # No need to evaluate this appbt if we already know it has a uflow
                rs_appbt = rs_syscall.filter(application=app,backtrace=bt)
                COUNT_THISAPPBT = rs_appbt.count()
                for r_num,r in enumerate(rs_appbt,1):
                    if r_num >= REPORTS_LIMIT: break # Let's only evaluate up REPORTS_LIMIT reports from the same appbt (some appbts have hundreds of reports)
                    debug_str = "(SEC-SENSITIVE SYSCALL) " + syscall + ": arg " + str(arg_num+1) + "/" + str(arg_count) + ", app+bt " + str(appbt_nr) + "/" + str(COUNT_APPBTS) + ", report " + str(r_num) + "/" + str(COUNT_THISAPPBT)
                    print("**************** " + debug_str)
                    appbt_has_uflow = rewrite_eval_report_arg(r, arg_num, debug_str)
                    #input("======================================== Press enter to continue...")
                    if appbt_has_uflow: break # No need to verify the same app+bt multiple times if we know it has a uflow
