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
package Apache::TestSmoke;

use strict;
use warnings FATAL => 'all';

use Apache::Test ();
use Apache::TestConfig ();
use Apache::TestTrace;

use Apache::TestHarness ();
use Apache::TestRun (); # for core scan functions
use Apache::TestSort;

use Getopt::Long qw(GetOptions);
use File::Spec::Functions qw(catfile);
use FindBin;
use POSIX ();
use Symbol ();

#use constant DEBUG => 1;

# how many times to run all tests at the first iteration
use constant DEFAULT_TIMES  => 10;

# if after this number of tries to reduce the number of tests fails we
# give up on more tries
use constant MAX_REDUCTION_TRIES => 50;

my @num_opts  = qw(times);
my @string_opts  = qw(order report);
my @flag_opts = qw(help verbose bug_mode);

my %order = map {$_ => 1} qw(random repeat);

my %usage = (
   'times=N'         => 'how many times to run the entire test suite' .
                        ' (default: ' . DEFAULT_TIMES . ')',
   'order=MODE'      => 'modes: random, repeat' .
                        ' (default: random)',
   'report=FILENAME' => 'save report in a filename' .
                        ' (default: smoke-report-<date>.txt)',
   'verbose[=1]'     => 'verbose output' .
                        ' (default: 0)',
   'bug_mode'        => 'bug report mode' .
                        ' (default: 0)',
);

sub new {
    my($class, @argv) = @_;

    my $self = bless {
        seen    => {}, # seen sequences and tried them md5 hash
        results => {}, # final reduced sequences md5 hash
        smoking_completed         => 0,
        tests                     => [],
        total_iterations          => 0,
        total_reduction_attempts  => 0,
        total_reduction_successes => 0,
        total_tests_run           => 0,
    }, ref($class)||$class;

    $self->{test_config} = Apache::TestConfig->thaw;

    $self->getopts(\@argv);
    my $opts = $self->{opts};

    chdir "$FindBin::Bin/..";
    $self->{times} = $opts->{times} || DEFAULT_TIMES;
    $self->{order}   = $opts->{order}   || 'random';
    $self->{verbose} = $opts->{verbose} || 0;

    $self->{run_iter} = $self->{times};

    # this is like 'make test' but produces an output to be used in
    # the bug report
    if ($opts->{bug_mode}) {
        $self->{bug_mode} = 1;
        $self->{run_iter} = 1;
        $self->{times}    = 1;
        $self->{verbose}  = 1;
        $self->{order}    = 'random';
        $self->{trace}    = 'debug';
    }

    # specific tests end up in $self->{tests} and $self->{subtests};
    # and get removed from $self->{argv}
    $self->Apache::TestRun::split_test_args();

    my $test_opts = {
        verbose  => $self->{verbose},
        tests    => $self->{tests},
        order    => $self->{order},
        subtests => $self->{subtests} || [],
    };

    @{ $self->{tests} } = $self->get_tests($test_opts);

    $self->{base_command} = "$^X $FindBin::Bin/TEST";

    # options common to all
    $self->{base_command} .= " -verbose" if $self->{verbose};

    # options specific to the startup
    $self->{start_command} = "$self->{base_command} -start";
    $self->{start_command} .= " -trace=" . $self->{trace} if $self->{trace};

    # options specific to the run
    $self->{run_command} = "$self->{base_command} -run";

    # options specific to the stop
    $self->{stop_command} = "$self->{base_command} -stop";

    $self;
}

sub getopts {
    my($self, $argv) = @_;
    my %opts;
    local *ARGV = $argv;

    # permute      : optional values can come before the options
    # pass_through : all unknown things are to be left in @ARGV
    Getopt::Long::Configure(qw(pass_through permute));

    # grab from @ARGV only the options that we expect
    GetOptions(\%opts, @flag_opts,
               (map "$_=s", @string_opts),
               (map "$_=i", @num_opts));

    if (exists $opts{order}  && !exists $order{$opts{order}}) {
        error "unknown -order mode: $opts{order}";
        $self->opt_help();
        exit;
    }

    if ($opts{help}) {
        $self->opt_help;
        exit;
    }

    # min
    $self->{opts} = \%opts;

    $self->{argv} = [@ARGV];
}

# XXX: need proper sub-classing
# from Apache::TestHarness
sub skip      { Apache::TestHarness::skip(@_); }
sub prune     { Apache::TestHarness::prune(@_); }
sub get_tests { Apache::TestHarness::get_tests(@_);}

sub install_sighandlers {
    my $self = shift;

    $SIG{INT} = sub {
        # make sure that there the server is down
        $self->kill_proc();

        $self->report_finish;
        exit;
    };
}

END {
    local $?; # preserve the exit status
    eval {
        Apache::TestRun->new(test_config =>
                             Apache::TestConfig->thaw)->scan_core;
    };
}

sub run {
    my($self) = shift;

    $self->Apache::TestRun::warn_core();
    local $SIG{INT};
    $self->install_sighandlers;

    $self->report_start();

    if ($self->{bug_mode}) {
        # 'make test', but useful for bug reports
        $self->run_bug_mode();
    }
    else {
         # normal smoke
        my $iter = 0;
        while ($iter++ < $self->{run_iter}) {
            my $last = $self->run_iter($iter);
            last if $last;
        }
    }
    $self->{smoking_completed} = 1;
    $self->report_finish();
    exit;
}

sub sep {
    my($char, $title) = @_;
    my $width = 60;
    if ($title) {
        my $side = int( ($width - length($title) - 2) / 2);
        my $pad  = ($side+1) * 2 + length($title) < $width ? 1 : 0;
        return $char x $side . " $title " . $char x ($side+$pad);
    }
    else {
        return $char x $width;
    }
}

my %log_files = ();
use constant FH  => 0;
use constant POS => 1;
sub logs_init {
    my($self, @log_files) = @_;

    for my $path (@log_files) {
        my $fh = Symbol::gensym();
        open $fh, "<$path" or die "Can't open $path: $!";
        seek $fh, 0, POSIX::SEEK_END();
        $log_files{$path}[FH]  = $fh;
        $log_files{$path}[POS] = tell $fh;
    }
}

sub logs_end {
    for my $path (keys %log_files) {
        close $log_files{$path}[FH];
    }
}

sub log_diff {
    my($self, $path) = @_;

    my $log = $log_files{$path};
    die "no such log file: $path" unless $log;

    my $fh = $log->[FH];
    # no checkpoints were made yet?
    unless (defined $log->[POS]) {
        seek $fh, 0, POSIX::SEEK_END();
        $log->[POS] = tell $fh;
        return '';
    }

    seek $fh, $log->[POS], POSIX::SEEK_SET(); # not really needed
    local $/; # slurp mode
    my $diff = <$fh>;
    seek $fh, 0, POSIX::SEEK_END(); # not really needed
    $log->[POS] = tell $fh;

    return $diff || '';
}

# this is a special mode, which really just runs 't/TEST -start;
# t/TEST -run; t/TEST -stop;' but it runs '-run' separately for each
# test, and checks whether anything bad has happened after the run
# of each test (i.e. either a test has failed, or a test may be successful,
# but server may have dumped a core file, we detect that).
sub run_bug_mode {
    my($self) = @_;

    my $iter = 0;

    warning "running t/TEST in the bug report mode";

    my $reduce_iter = 0;
    my @good = ();

    # first time run all tests, or all specified tests
    my @tests = @{ $self->{tests} }; # copy
    my $bad = $self->run_test($iter, $reduce_iter, \@tests, \@good);
    $self->{total_iterations}++;

}


# returns true if for some reason no more iterations should be made
sub run_iter {
    my($self, $iter) = @_;
    my $stop_now = 0;
    my $reduce_iter = 0;
    my @good = ();
    warning "\n" . sep("-");
    warning sprintf "[%03d-%02d-%02d] running all tests",
        $iter, $reduce_iter, $self->{times};


    # first time run all tests, or all specified tests
    my @tests = @{ $self->{tests} }; # copy

    # hack to ensure a new random seed is generated
    Apache::TestSort->run(\@tests, $self);

    my $bad = $self->run_test($iter, $reduce_iter, \@tests, \@good);
    unless ($bad) {
        $self->{total_iterations}++;
        return $stop_now;
    }
    error "recorded a positive failure ('$bad'), " .
        "will try to minimize the input now";

    my $command = $self->{base_command};

    # does the test fail on its own
    {
        $reduce_iter++;
        warning sprintf "[%03d-%02d-%02d] trying '$bad' on its own",
            $iter, $reduce_iter, 1;
        my @good = ();
        my @tests = ($bad);
        my $bad = $self->run_test($iter, $reduce_iter, \@tests, \@good);
        # if a test is failing on its own there is no point to
        # continue looking for other sequences
        if ($bad) {
            $stop_now = 1;
            $self->{total_iterations}++;
            unless ($self->sequence_seen($self->{results}, [@good, $bad])) {
                $self->report_success($iter, $reduce_iter, "$command $bad", 1);
            }
            return $stop_now;
        }
    }

    # positive failure
    my $ok_tests = @good;
    my $reduction_success = 0;
    my $done = 0;
    while (@good > 1) {
        my $tries = 0;
        my $reduce_sub = $self->reduce_stream(\@good);
        $reduce_iter++;
        while ($tries++ < MAX_REDUCTION_TRIES) {
            $self->{total_reduction_attempts}++;
            my @try = @{ $reduce_sub->() };

            # reduction stream is empty (tried all?)
            unless (@try) {
                $done = 1;
                last;
            }

            warning sprintf "\n[%03d-%02d-%02d] trying %d tests",
                $iter, $reduce_iter, $tries, scalar(@try);
            my @ok = ();
            my @tests = (@try, $bad);
            my $new_bad = $self->run_test($iter, $reduce_iter, \@tests, \@ok);
            if ($new_bad) {
                # successful reduction
                $reduction_success++;
                @good = @ok;
                $tries = 0;
                my $num = @ok;
                error "*** reduction $reduce_iter succeeded ($num tests) ***";
                $self->{total_reduction_successes}++;
                $self->log_successful_reduction($iter, \@ok);
                last;
            }
        }

        # last round of reducing has failed, so we give up
        if ($done || $tries >= MAX_REDUCTION_TRIES){
            error "no further reductions were made";
            $done = 1;
            last;
        }

    }

    # we have a minimal failure sequence at this point (to the extend
    # of success of our attempts to reduce)

    # report the sequence if we didn't see such one yet in the
    # previous iterations
    unless ($self->sequence_seen($self->{results}, [@good, $bad])) {
        # if no reduction succeeded, it's 0
        $reduce_iter = 0 unless $reduction_success;
        $self->report_success($iter, $reduce_iter,
                              "$command @good $bad", @good + 1);
    }

    $self->{total_iterations}++;

    return $stop_now;
}

# my $sub = $self->reduce_stream(\@items);
sub reduce_stream {
    my($self) = shift;
    my @items = @{+shift};

    my $items = @items;
    my $odd   = $items % 2 ? 1 : 0;
    my $middle = int($items/2) - 1;
    my $c = 0;

    return sub {
        $c++; # remember stream's state

        # a single item is not reduce-able
        return \@items if $items == 1;

        my @try = ();
        my $max_repeat_tries = 50; # avoid seen sequences
        my $repeat = 0;
        while ($repeat++ <= $max_repeat_tries) {

            # try to use a binary search
            if ($c == 1) {
                # right half
                @try = @items[($middle+1)..($items-1)];
            }
            elsif ($c == 2) {
                # left half
                @try = @items[0..$middle];
            }

            # try to use a random window size alg
            else {
                my $left = int rand($items);
                $left = $items - 1 if $left == $items - 1;
                my $right = $left + int rand($items - $left);
                $right = $items - 1 if $right >= $items;
                @try = @items[$left..$right];
            }

            if ($self->sequence_seen($self->{seen}, \@try)) {
                @try = ();
            }
            else {
                last; # found an unseen sequence
            }
        }
        return \@try;
    }
}

sub sequence_seen {
    my ($self, $rh_store, $ra_tests) = @_;

    require Digest::MD5;
    my $digest = Digest::MD5::md5_hex(join '', @$ra_tests);
    #error $self->{seen};
    return $rh_store->{$digest}++ ? 1 : 0

}

sub run_test {
    require IPC::Run3;
    my($self, $iter, $count, $tests, $ra_ok) = @_;
    my $bad = '';
    my $ra_nok = [];

    #warning "$self->{base_command} @$tests";

    #$SIG{PIPE} = 'IGNORE';
    $SIG{PIPE} = sub { die "pipe broke" };

    # start server
    {
        my $command = $self->{start_command};
        my $log = '';
        IPC::Run3::run3($command, undef, \$log, \$log);
        my $started_ok = ($log =~ /started/) ? 1 : 0;
        unless ($started_ok) {
            error "failed to start server\n $log";
            exit 1;
        }
    }

    my $t_logs  = $self->{test_config}->{vars}->{t_logs};
    my @log_files = map { catfile $t_logs, $_ } qw(error_log access_log);
    $self->logs_init(@log_files);

    # run tests
    {
        my $command = $self->{run_command};

        my $max_len = 1;
        for my $test (@$tests) {
            $max_len = length $test if length $test > $max_len;
        }

        for my $test (@$tests) {
            (my $test_name = $test) =~ s/\.t$//;
            my $fill = "." x ($max_len - length $test_name);
            $self->{total_tests_run}++;

            my $test_command = "$command $test";
            my $log = '';
            IPC::Run3::run3($test_command, undef, \$log, \$log);
            my $ok = ($log =~ /All tests successful|NOTESTS/) ? 1 : 0;

            my @core_files_msg = $self->Apache::TestRun::scan_core_incremental(1);

            # if the test has caused core file(s) it's not ok
            $ok = 0 if @core_files_msg;

            if ($ok == 1) {
                push @$ra_ok, $test;
                if ($self->{verbose}) {

                    if ($log =~ m/NOTESTS/) {
                        print STDERR "$test_name${fill}skipped\n";
                    } else {
                        print STDERR "$test_name${fill}ok\n";
                    }
                }
                # need to run log_diff to reset the position of the fh
                my %log_diffs = map { $_ => $self->log_diff($_) } @log_files;

            }
            elsif ($ok == 0) {
                push @$ra_nok, $test;
                $bad = $test;

                if ($self->{verbose}) {
                    print STDERR "$test_name${fill}FAILED\n";
                    error sep("-");

                    # give server some time to finish the
                    # logging. it's ok to wait long time since we have
                    # to deal with an error
                    sleep 5;
                    my %log_diffs = map { $_ => $self->log_diff($_) } @log_files;

                    # client log
                    error "\t\t*** run log ***";
                    $log =~ s/^/    /mg;
                    print STDERR "$log\n";

                    # server logs
                    for my $path (@log_files) {
                        next unless length $log_diffs{$path};
                        error "\t\t*** $path ***";
                        $log_diffs{$path} =~ s/^/    /mg;
                        print STDERR "$log_diffs{$path}\n";
                    }
                }
                if (@core_files_msg) {
                    unless ($self->{verbose}) {
                        # currently the output of 'run log' already
                        # includes the information about core files once
                        # Test::Harness::Straps allows us to run callbacks
                        # after each test, and we move back to run all
                        # tests at once, we will log the message here
                        error "$test_name caused core";
                        print STDERR join "\n", @core_files_msg, "\n";
                    }
                }

                if ($self->{verbose}) {
                    error sep("-");
                }

                unless ($self->{bug_mode}) {
                    # normal smoke stop the run, but in the bug_mode
                    # we want to complete all the tests
                    last;
                }
            }


        }
    }

    $self->logs_end();

    # stop server
    $self->kill_proc();

    if ($self->{bug_mode}) {
        warning sep("-");
        if (@$ra_nok == 0) {
            printf STDERR "All tests successful (%d)\n", scalar @$ra_ok;
        }
        else {
            error sprintf "error running %d tests out of %d\n",
                scalar(@$ra_nok), scalar @$ra_ok + @$ra_nok;
        }
    }
    else {
        return $bad;
    }


}

sub report_start {
    my($self) = shift;

    my $time = scalar localtime;
    $self->{start_time} = $time;
    $time =~ s/\s/_/g;
    $time =~ s/:/-/g; # winFU
    my $file = $self->{opts}->{report} ||
        catfile Apache::Test::vars('top_dir'), "smoke-report-$time.txt";
    $self->{runtime}->{report} = $file;
    info "Report file: $file";

    open my $fh, ">$file" or die "cannot open $file for writing: $!";
    $self->{fh} = $fh;
    my $sep = sep("-");
    my $title = sep('=', "Special Tests Sequence Failure Finder Report");

        print $fh <<EOM;
$title
$sep
First iteration used:
$self->{base_command} @{$self->{tests}}
$sep
EOM

}

sub report_success {
    my($self, $iter, $reduce_iter, $sequence, $tests) = @_;

    my @report = ("iteration $iter ($tests tests):\n",
        "\t$sequence\n",
        "(made $reduce_iter successful reductions)\n\n");

    print @report;
    if (my $fh = $self->{fh}) {
        print $fh @report;
    }
}

sub report_finish {
    my($self) = @_;

    my $start_time = $self->{start_time};
    my $end_time   = scalar localtime;
    if (my $fh = delete $self->{fh}) {
        my $failures = scalar keys %{ $self->{results} };

        my $sep = sep("-");
        my $cfg_as_string = $self->build_config_as_string;
        my $unique_seqs   = scalar keys %{ $self->{results} };
        my $attempts      = $self->{total_reduction_attempts};
        my $successes     = $self->{total_reduction_successes};
        my $completion    = $self->{smoking_completed}
            ? "Completed"
            : "Not Completed (aborted by user)";

        my $status = "Unknown";
        if ($self->{total_iterations} > 0) {
            if ($failures) {
                $status = "*** NOT OK ***";
            }
            else {
                $status = "+++ OK +++";
            }
        }

        my $title = sep('=', "Summary");

        my $iter_made = sprintf "Iterations (%s) made : %d",
            $self->{order}, $self->{total_iterations};

        print $fh <<EOM;

$title
Completion               : $completion
Status                   : $status
Tests run                : $self->{total_tests_run}
$iter_made
EOM

        if ($attempts > 0 && $failures) {
            my $reduction_stats = sprintf "%d/%d (%d%% success)",
                $attempts, $successes, $successes / $attempts * 100;

            print $fh <<EOM;
Unique sequences found  : $unique_seqs
Reduction tries/success : $reduction_stats
EOM
        }

        print $fh <<EOM;
$sep
--- Started at: $start_time ---
--- Ended   at: $end_time ---
$sep
The smoke testing was run on the system with the following
parameters:

$cfg_as_string

-- this report was generated by $0
EOM
        close $fh;
    }
}

# in case the smoke gets killed before it had a chance to finish and
# write the report, at least we won't lose the last successful reduction
# XXX: this wasn't needed before we switched to IPC::Run3, since
# Ctrl-C would log the collected data, but it doesn't work with
# IPC::Run3. So if that gets fixed, we can remove that function
sub log_successful_reduction {
    my($self, $iter, $tests) = @_;

    my $file = $self->{runtime}->{report} . ".$iter.temp";
    debug "saving in $file";
    open my $fh, ">$file" or die "cannot open $file for writing: $!";
    print $fh join " ", @$tests;
    close $fh;
}

sub build_config_as_string {
    Apache::TestConfig::as_string();
}

sub kill_proc {
    my($self) = @_;

    my $command = $self->{stop_command};
    my $log = '';
    require IPC::Run3;
    IPC::Run3::run3($command, undef, \$log, \$log);

    my $stopped_ok = ($log =~ /shutdown/) ? 1 : 0;
    unless ($stopped_ok) {
        error "failed to stop server\n $log";
    }
}

sub opt_help {
    my $self = shift;

    print <<EOM;
usage: t/SMOKE [options ...] [tests]
    where the options are:
EOM

    for (sort keys %usage){
        printf "   -%-16s %s\n", $_, $usage{$_};
    }
    print <<EOM;

    if 'tests' argument is not provided all available tests will be run
EOM
}

# generate t/SMOKE script (or a different filename) which will drive
# Apache::TestSmoke
sub generate_script {
    my ($class, $file) = @_;

    $file ||= catfile 't', 'SMOKE';

    my $content = join "\n",
        "BEGIN { eval { require blib && blib->import; } }",
        Apache::TestConfig->perlscript_header,
        "use $class;",
        "$class->new(\@ARGV)->run;";

    Apache::Test::basic_config()->write_perlscript($file, $content);
}

1;
__END__

=head1 NAME

Apache::TestSmoke - Special Tests Sequence Failure Finder

=head1 SYNOPSIS

  # get the usage and the default values
  % t/SMOKE -help

  # repeat all tests 5 times and save the report into
  # the file 'myreport'
  % t/SMOKE -times=5 -report=myreport

  # run all tests default number of iterations, and repeat tests
  # default number of times
  % t/SMOKE

  # same as above but work only the specified tests
  % t/SMOKE foo/bar foo/tar

  # run once a sequence of tests in a non-random mode
  # e.g. when trying to reduce a known long sequence that fails
  % t/SMOKE -order=rotate -times=1 foo/bar foo/tar

  # show me each currently running test
  # it's not the same as running the tests in the verbose mode
  % t/SMOKE -verbose

  # run t/TEST, but show any problems after *each* tests is run
  # useful for bug reports (it actually runs t/TEST -start, then
  # t/TEST -run for each test separately and finally t/TEST -stop
  % t/SMOKE -bug_mode

  # now read the created report file

=head1 DESCRIPTION

=head2 The Problem

When we try to test a stateless machine (i.e. all tests are
independent), running all tests once ensures that all tested things
properly work. However when a state machine is tested (i.e. where a
run of one test may influence another test) it's not enough to run all
the tests once to know that the tested features actually work. It's
quite possible that if the same tests are run in a different order
and/or repeated a few times, some tests may fail.  This usually
happens when some tests don't restore the system under test to its
pristine state at the end of the run, which may influence other tests
which rely on the fact that they start on pristine state, when in fact
it's not true anymore. In fact it's possible that a single test may
fail when run twice or three times in a sequence.

=head2 The Solution

To reduce the possibility of such dependency errors, it's helpful to
run random testing repeated many times with many different srand
seeds. Of course if no failures get spotted that doesn't mean that
there are no tests inter-dependencies, which may cause a failure in
production. But random testing definitely helps to spot many problems
and can give better test coverage.

=head2 Resolving Sequence Problems

When this kind of testing is used and a failure is detected there are
two problems:

=over

=item 1

First is to be able to reproduce the problem so if we think we fixed
it, we could verify the fix. This one is easy, just remember the
sequence of tests run till the failed test and rerun the same sequence
once again after the problem has been fixed.

=item 2

Second is to be able to understand the cause of the problem. If during
the random test the failure has happened after running 400 tests, how
can we possibly know which previously running tests has caused to the
failure of the test 401. Chances are that most of the tests were clean
and don't have inter-dependency problem. Therefore it'd be very
helpful if we could reduce the long sequence to a minimum. Preferably
1 or 2 tests. That's when we can try to understand the cause of the
detected problem.

=back

This utility attempts to solve both problems, and at the end of each
iteration print a minimal sequence of tests causing to a failure. This
doesn't always succeed, but works in many cases.

This utility:

=over

=item 1

Runs the tests randomly until the first failure is detected. Or
non-randomly if the option I<-order> is set to I<repeat> or I<rotate>.

=item 2

Then it tries to reduce that sequence of tests to a minimum, and this
sequence still causes to the same failure.

=item 3

(XXX: todo): then it reruns the minimal sequence in the verbose mode
and saves the output.

=item 4

It reports all the successful reductions as it goes to STDOUT and
report file of the format: smoke-report-<date>.txt.

In addition the systems build parameters are logged into the report
file, so the detected problems could be reproduced.

=item 5

Goto 1 and run again using a new random seed, which potentially should
detect different failures.

=back

=head1 Reduction Algorithm

Currently for each reduction path, the following reduction algorithms
get applied:

=over

=item 1

Binary search: first try the upper half then the lower.

=item 2

Random window: randomize the left item, then the right item and return
the items between these two points.

=back

=head1 t/SMOKE.PL

I<t/SMOKE.PL> is driving this module, if you don't have it, create it:

  #!perl

  use strict;
  use warnings FATAL => 'all';

  use FindBin;
  use lib "$FindBin::Bin/../Apache-Test/lib";
  use lib "$FindBin::Bin/../lib";

  use Apache::TestSmoke ();

  Apache::TestSmoke->new(@ARGV)->run;

usually I<Makefile.PL> converts it into I<t/SMOKE> while adjusting the
perl path, but you create I<t/SMOKE> in first place as well.

=head1 AUTHOR

Stas Bekman

=cut
