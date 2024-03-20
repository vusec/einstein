# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
package Apache::TestServer;

use strict;
use warnings FATAL => 'all';

use Config;
use Socket ();
use File::Spec::Functions qw(catfile);

use Apache::TestTrace;
use Apache::TestRun;
use Apache::TestConfig ();
use Apache::TestRequest ();

use lib "$ENV{'ROOT'}/apps/scripts/perl-tests";
require EinsteinTests;

use constant COLOR => Apache::TestConfig::COLOR;
use constant WIN32 => Apache::TestConfig::WIN32;

my $CTRL_M = COLOR ? "\r" : "\n";

# some debuggers use the same syntax as others, so we reuse the same
# code by using the following mapping
my %debuggers = (
    gdb      => 'gdb',
    ddd      => 'gdb',
    valgrind => 'valgrind',
    strace   => 'strace',
);

sub new {
    my $class = shift;
    my $config = shift;

    my $self = bless {
        config => $config || Apache::TestConfig->thaw,
    }, $class;

    $self->{name} = join ':',
      map { $self->{config}->{vars}->{$_} } qw(servername port);

    $self->{port_counter} = $self->{config}->{vars}->{port};

    $self;
}

# call this when you already know where httpd is
sub post_config {
    my($self) = @_;

    $self->{version} = $self->{config}->httpd_version || '';
    $self->{mpm}     = $self->{config}->httpd_mpm     || '';

    # try to get the revision number from the standard Apache version
    # string and various variations made by distributions which mangle
    # that string

    # Foo-Apache-Bar/x.y.z
    ($self->{rev}) = $self->{version} =~ m|/(\d)\.|;

    if ($self->{rev}) {
        debug "Matched Apache revision $self->{version} $self->{rev}";
    }
    else {
        # guessing is not good as it'll only mislead users
        # and we can't die since a config object is required
        # during Makefile.PL's write_perlscript when path to httpd may
        # be unknown yet. so default to non-existing version 0 for now.
        # and let TestRun.pm figure out the required pieces
        debug "can't figure out Apache revision, from string: " .
            "'$self->{version}', using a non-existing revision 0";
        $self->{rev} = 0; # unknown
    }

    ($self->{revminor}) = $self->{version} =~ m|/\d\.(\d)|;

    if ($self->{revminor}) {
        debug "Matched Apache revminor $self->{version} $self->{revminor}";
    }
    else {
        $self->{revminor} = 0;
    }

    $self;
}

sub version_of {
    my($self, $thing) = @_;
    die "Can't figure out what Apache server generation we are running"
        unless $self->{rev};

    $thing->{$self->{rev}};
}

my @apache_logs = qw(
error_log access_log httpd.pid
apache_runtime_status rewrite_log
ssl_engine_log ssl_request_log
cgisock
);

sub clean {
    my $self = shift;

    my $dir = $self->{config}->{vars}->{t_logs};

    for (@apache_logs) {
        my $file = catfile $dir, $_;
        if (unlink $file) {
            debug "unlink $file";
        }
    }
}

sub pid_file {
    my $self = shift;

    my $vars = $self->{config}->{vars};

    return $vars->{t_pid_file} || catfile $vars->{t_logs}, 'httpd.pid';
}

sub dversion {
    my $self = shift;

    my $dv = "-D APACHE$self->{rev}";

    if ($self->{rev} == 2 and $self->{revminor} == 4) {
        $dv .= " -D APACHE2_4";
    }

    return $dv;
}

sub config_defines {
    my $self = shift;

    my @defines = ();

    for my $item (qw(useithreads)) {
        next unless $Config{$item} and $Config{$item} eq 'define';
        push @defines, "-D PERL_\U$item";
    }

    if (my $defines = $self->{config}->{vars}->{defines}) {
        push @defines, map { "-D $_" } split " ", $defines;
    }

    "@defines";
}

sub args {
    my $self = shift;
    my $vars = $self->{config}->{vars};
    my $dversion = $self->dversion; #for .conf version conditionals
    my $defines = $self->config_defines;

    "-d $vars->{serverroot} -f $vars->{t_conf_file} $dversion $defines";
}

my %one_process = (1 => '-X', 2 => '-D ONE_PROCESS');

sub start_cmd {
    my $self  = shift;

    my $args   = $self->args;
    my $config = $self->{config};
    my $vars   = $config->{vars};
    my $httpd  = $vars->{httpd};

    my $one_process = $self->{run}->{opts}->{'one-process'}
        ? $self->version_of(\%one_process)
        : '';

    #XXX: threaded mpm does not respond to SIGTERM with -D ONE_PROCESS

    return "$httpd $one_process $args";
}

sub default_gdbinit {
    my $gdbinit = "";
    my @sigs = qw(PIPE);

    for my $sig (@sigs) {
        for my $flag (qw(pass nostop)) {
            $gdbinit .= "handle SIG$sig $flag\n";
        }
    }

    $gdbinit;
}

sub strace_cmd {
    my($self, $strace, $file) = @_;
    #XXX truss, ktrace, etc.
    "$strace -f -o $file -s1024";
}

sub valgrind_cmd {
    my($self, $valgrind) = @_;
    "$valgrind -v --leak-check=yes --show-reachable=yes --error-limit=no";
}

sub start_valgrind {
    my $self = shift;
    my $opts = shift;

    my $config       = $self->{config};
    my $args         = $self->args;
    my $one_process  = $self->version_of(\%one_process);
    my $valgrind_cmd = $self->valgrind_cmd($opts->{debugger});
    my $httpd        = $config->{vars}->{httpd};

    my $command = "$valgrind_cmd $httpd $one_process $args";

    debug $command;
    system $command;
}

sub start_strace {
    my $self = shift;
    my $opts = shift;

    my $config      = $self->{config};
    my $args        = $self->args;
    my $one_process = $self->version_of(\%one_process);
    my $file        = catfile $config->{vars}->{t_logs}, 'strace.log';
    my $strace_cmd  = $self->strace_cmd($opts->{debugger}, $file);
    my $httpd       = $config->{vars}->{httpd};

    $config->genfile($file); #just mark for cleanup

    my $command = "$strace_cmd $httpd $one_process $args";

    debug $command;
    system $command;
}

sub start_gdb {
    my $self = shift;
    my $opts = shift;

    my $debugger    = $opts->{debugger};
    my @breakpoints = @{ $opts->{breakpoint} || [] };
    my $config      = $self->{config};
    my $args        = $self->args;
    my $one_process = $self->version_of(\%one_process);

    my $file = catfile $config->{vars}->{serverroot}, '.gdb-test-start';
    my $fh   = $config->genfile($file);

    print $fh default_gdbinit();

    if (@breakpoints) {
        print $fh "b ap_run_pre_config\n";
        print $fh "run $one_process $args\n";
        print $fh "finish\n";
        for (@breakpoints) {
            print $fh "b $_\n"
        }
        print $fh "continue\n";
    }
    else {
        print $fh "run $one_process $args\n";
    }
    close $fh;

    my $command;
    my $httpd = $config->{vars}->{httpd};

    if ($debugger eq 'ddd') {
        $command = qq{ddd --gdb --debugger "gdb -command $file" $httpd};
    }
    else {
        ## defaults to gdb if not set in %ENV or via -debug
        $command = "$debugger $httpd -command $file";
    }

    $self->note_debugging;
    debug  $command;
    system $command;

    unlink $file;
}

sub debugger_file {
    my $self = shift;
    catfile $self->{config}->{vars}->{serverroot}, '.debugging';
}

#make a note that the server is running under the debugger
#remove note when this process exits via END

sub note_debugging {
    my $self = shift;
    my $file = $self->debugger_file;
    my $fh   = $self->{config}->genfile($file);
    eval qq(END { unlink "$file" });
}

sub start_debugger {
    my $self = shift;
    my $opts = shift;

    $opts->{debugger} ||= $ENV{MP_DEBUGGER} || 'gdb';

    # XXX: FreeBSD 5.2+
    #      gdb 6.1 and before segfaults when trying to
    #      debug httpd startup code. 6.5 has been proven
    #      to work.  FreeBSD typically installs this as
    #      gdb65.
    #      Is it worth it to check the debugger and os version
    #      and die ?

    unless (grep { /^$opts->{debugger}/ } keys %debuggers) {
        error "$opts->{debugger} is not a supported debugger",
              "These are the supported debuggers: ".
              join ", ", sort keys %debuggers;
        die("\n");
    }

    my $debugger = $opts->{debugger};
    $debugger =~ s/\d+$//;

    my $method = "start_" . $debuggers{$debugger};

    ## $opts->{debugger} is passed through unchanged
    ## so when we try to run it next, its found.
    $self->$method($opts);
}

sub pid {
    my $self = shift;
    my $file = $self->pid_file;
    my $fh = Symbol::gensym();
    open $fh, $file or do {
        return 0;
    };

    # try to avoid the race condition when the pid file was created
    # but not yet written to
    for (1..8) {
        last if -s $file > 0;
        select undef, undef, undef, 0.25;
    }

    chomp(my $pid = <$fh> || '');
    $pid;
}

sub select_next_port {
    my $self = shift;

    my $max_tries = 100; #XXX
    while ($max_tries-- > 0) {
        return $self->{port_counter}
            if $self->port_available(++$self->{port_counter});
    }

    return 0;
}

sub port_available {
    my $self = shift;
    my $port = shift || $self->{config}->{vars}->{port};
    local *S;

    my $proto = getprotobyname('tcp');

    socket(S, Socket::PF_INET(),
           Socket::SOCK_STREAM(), $proto) || die "socket: $!";
    setsockopt(S, Socket::SOL_SOCKET(),
               Socket::SO_REUSEADDR(),
               pack("l", 1)) || die "setsockopt: $!";

    if (bind(S, Socket::sockaddr_in($port, Socket::INADDR_ANY()))) {
        close S;
        return 1;
    }
    else {
        return 0;
    }
}

=head2 stop()

attempt to stop the server.

returns:

  on success: $pid of the server
  on failure: -1

=cut

sub stop {
    my $self = shift;
    my $aborted = shift;

    if (WIN32) {
        require Win32::Process;
        my $obj = $self->{config}->{win32obj};
        my $pid = -1;
        if ($pid = $obj ? $obj->GetProcessID : $self->pid) {
            if (kill(0, $pid)) {
                Win32::Process::KillProcess($pid, 0);
                warning "server $self->{name} shutdown";
            }
        }
        unlink $self->pid_file if -e $self->pid_file;
        return $pid;
    }

    my $pid = 0;
    my $tries = 3;
    my $tried_kill = 0;

    my $port = $self->{config}->{vars}->{port};

    while ($self->ping) {
        #my $state = $tried_kill ? "still" : "already";
        #print "Port $port $state in use\n";

        if ($pid = $self->pid and !$tried_kill++) {
            if (kill TERM => $pid) {
                warning "server $self->{name} shutdown";
                sleep 1;

                for (1..6) {
                    if (! $self->ping) {
                        if ($_ == 1) {
                            unlink $self->pid_file if -e $self->pid_file;
                            return $pid;
                        }
                        last;
                    }
                    if ($_ == 1) {
                        warning "port $port still in use...";
                    }
                    else {
                        print "...";
                    }
                    sleep $_;
                }

                if ($self->ping) {
                    error "\nserver was shutdown but port $port ".
                          "is still in use, please shutdown the service ".
                          "using this port or select another port ".
                          "for the tests";
                }
                else {
                    print "done\n";
                }
            }
            else {
                error "kill $pid failed: $!";
            }
        }
        else {
            error "port $port is in use, ".
                  "cannot determine server pid to shutdown";
            return -1;
        }

        if (--$tries <= 0) {
            error "cannot shutdown server on Port $port, ".
                  "please shutdown manually";
            unlink $self->pid_file if -e $self->pid_file;
            return -1;
        }
    }

    unlink $self->pid_file if -e $self->pid_file;
    return $pid;
}

sub ping {
    my $self = shift;
    my $pid = $self->pid;

    if ($pid and kill 0, $pid) {
        return $pid;
    }
    elsif (! $self->port_available) {
        return -1;
    }

    return 0;
}

sub failed_msg {
    my $self = shift;
    my($log, $rlog) = $self->{config}->error_log;
    my $log_file_info = -e $log ?
        "please examine $rlog" :
        "$rlog wasn't created, start the server in the debug mode";
    error "@_ ($log_file_info)";
}

#this doesn't work well on solaris or hpux at the moment
use constant USE_SIGCHLD => $^O eq 'linux';

sub start {
    my $self = shift;

    my $old_pid = -1;
    if (WIN32) {
        # Stale PID files (e.g. left behind from a previous test run
        # that crashed) cannot be trusted on Windows because PID's are
        # re-used too frequently, so just remove it. If there is an old
        # server still running then the attempt to start a new one below
        # will simply fail because the port will be unavailable.
        if (-f $self->pid_file) {
            error "Removing old PID file -- " .
                "Unclean shutdown of previous test run?\n";
            unlink $self->pid_file;
        }
        $old_pid = 0;
    }
    else {
        $old_pid = $self->stop;
    }
    my $cmd = $self->start_cmd;
    my $config = $self->{config};
    my $vars = $config->{vars};
    my $httpd = $vars->{httpd} || 'unknown';

    if ($old_pid == -1) {
        return 0;
    }

    local $| = 1;

    unless (-x $httpd) {
        my $why = -e $httpd ? "is not executable" : "does not exist";
        error "cannot start server: httpd ($httpd) $why";
        return 0;
    }

    print "$cmd\n";
    my $old_sig;

    if (WIN32) {
        #make sure only 1 process is started for win32
        #else Kill will only shutdown the parent
        my $one_process = $self->version_of(\%one_process);
        require Win32::Process;
        my $obj;
        # We need the "1" below to inherit the calling processes
        # handles when running Apache::TestSmoke so as to properly
        # dup STDOUT/STDERR
        Win32::Process::Create($obj,
                               $httpd,
                               "$cmd $one_process",
                               1,
                               Win32::Process::NORMAL_PRIORITY_CLASS(),
                               '.');
        unless ($obj) {
            die "Could not start the server: " .
                Win32::FormatMessage(Win32::GetLastError());
        }
        $config->{win32obj} = $obj;
    }
    else {
        $old_sig = $SIG{CHLD};

        if (USE_SIGCHLD) {
            # XXX: try not to be POSIX dependent
            require POSIX;

            #XXX: this is not working well on solaris or hpux
            $SIG{CHLD} = sub {
                while ((my $child = waitpid(-1, POSIX::WNOHANG())) > 0) {
                    my $status = $? >> 8;
                    #error "got child exit $status";
                    if ($status) {
                        my $msg = "server has died with status $status";
                        $self->failed_msg("\n$msg");
                        Apache::TestRun->new(test_config => $config)->scan_core;
                        kill SIGTERM => $$;
                    }
                }
            };
        }

        defined(my $pid = fork) or die "Can't fork: $!";
        unless ($pid) { # child
            # Original command
            #$cmd = "$ENV{'ROOT'}/apps/apache-2.4.54/install/bin/httpd -D ONE_PROCESS  -d $ENV{'ROOT'}/apps/apache-2.4.54/tests/perl-framework/t -f $ENV{'ROOT'}/apps/apache-2.4.54/tests/perl-framework/t/conf/httpd.conf -D APACHE2 -D APACHE2_4 -D PERL_USEITHREADS";
	    # New command
            $cmd = "env -C ../.. RUN_EINSTEIN=1 V=1 USE_LOG_DIR=1 LOG_SUB_DIR=testsuite ./serverctl start -D ONE_PROCESS -d $ENV{'ROOT'}/apps/apache-2.4.54/tests/perl-framework/t -f $ENV{'ROOT'}/apps/apache-2.4.54/tests/perl-framework/t/conf/httpd.conf -D APACHE2 -D APACHE2_4 -D PERL_USEITHREADS";
	    print (STDERR "\n==== TestServer:rerun: Executing command: '" . $cmd . "'\n");
            my $status = system "$cmd";
            if ($status) {
                $status  = $? >> 8;
                #error "httpd didn't start! $status";
            }
            CORE::exit $status;
        }
    }

    while ($old_pid and $old_pid == $self->pid) {
        warning "old pid file ($old_pid) still exists";
        sleep 1;
    }

    my $version = $self->{version};
    my $mpm = $config->{mpm} || "";
    $mpm = "($mpm MPM)" if $mpm;
    print "using $version $mpm\n";

    my $timeout = $vars->{startup_timeout} ||
                  $ENV{APACHE_TEST_STARTUP_TIMEOUT} ||
                  60;

    my $start_time = time;
    my $preamble = "${CTRL_M}waiting $timeout seconds for server to start: ";
    print $preamble unless COLOR;
    while (1) {
        my $delta = time - $start_time;
        print COLOR
            ? ($preamble, sprintf "%02d:%02d", (gmtime $delta)[1,0])
            : '.';
        sleep 1;
        if ($self->pid) {
            print $preamble, "ok (waited $delta secs)\n";
            last;
        }
        elsif ($delta > $timeout) {
            my $suggestion = $timeout + 300;
            print $preamble, "not ok\n";
            error <<EOI;
giving up after $delta secs. If you think that your system
is slow or overloaded try again with a longer timeout value.
by setting the environment variable APACHE_TEST_STARTUP_TIMEOUT
to a high value (e.g. $suggestion) and repeat the last command.
EOI
            last;
        }
    }

    # now that the server has started don't abort the test run if it
    # dies
    $SIG{CHLD} = $old_sig || 'DEFAULT';

    if (my $pid = $self->pid) {
        print "server $self->{name} started\n";

        my $vh = $config->{vhosts};
        my $by_port = sub { $vh->{$a}->{port} <=> $vh->{$b}->{port} };

        for my $module (sort $by_port keys %$vh) {
            print "server $vh->{$module}->{name} listening ($module)\n",
        }

        if ($config->configure_proxy) {
            print "tests will be proxied through $vars->{proxy}\n";
        }
    }
    else {
        $self->failed_msg("server failed to start!");
        return 0;
    }

    return 1 if $self->wait_till_is_up($timeout);

    $self->failed_msg("failed to start server!");
    return 0;
}


# wait till the server is up and return 1
# if the waiting times out returns 0
sub wait_till_is_up {
    my($self, $timeout) = @_;
    my $config = $self->{config};
    my $sleep_interval = 1; # secs

    my $server_up = sub {
        local $SIG{__WARN__} = sub {}; #avoid "cannot connect ..." warnings
        # avoid fatal errors when LWP is not available
        return eval {
	    my $r=Apache::TestRequest::GET('/index.html');
	    $r->code!=500 or $r->header('client-warning')!~/internal/i;
	} || 0;
    };

    if ($server_up->()) {
        return 1;
    }

    my $start_time = time;
    my $preamble = "${CTRL_M}still waiting for server to warm up: ";
    print $preamble unless COLOR;
    while (1) {
        my $delta = time - $start_time;
        print COLOR
            ? ($preamble, sprintf "%02d:%02d", (gmtime $delta)[1,0])
            : '.';
        sleep $sleep_interval;
        if ($server_up->()) {
            print "${CTRL_M}the server is up (waited $delta secs)             \n";
            return 1;
        }
        elsif ($delta > $timeout) {
            print "${CTRL_M}the server is down, giving up after $delta secs\n";
            return 0;
        }
        else {
            # continue
        }
    }
}

1;
