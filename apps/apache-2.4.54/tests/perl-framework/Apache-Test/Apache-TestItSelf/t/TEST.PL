use strict;

use lib qw(../../lib ../lib ./lib);

use strict;
use warnings FATAL => 'all';

use Test::Harness;
use FindBin;
use File::Spec::Functions qw(catdir);
use Apache::TestTrace;
use Cwd qw(cwd);

use Getopt::Long qw(GetOptions);

my %usage = (
   'base-dir'     => 'which dir to run the tests in (default: Apache-TestMe)',
   'config-file'  => 'which config file to use',
   'help'         => 'display this message',
   'trace=T'      => 'change tracing default to: warning, notice, ' .
                        'info, debug, ...',
   'verbose[=1]'  => 'verbose output',
);

my @flag_opts    = qw(verbose help);
my @string_opts  = qw(config-file base-dir trace);

my %opts;
# grab from @ARGV only the options that we expect
GetOptions(\%opts, @flag_opts, (map "$_=s", @string_opts));

# t/TEST -v -base /home/$ENV{USER}/apache.org/Apache-Test \
# -config /home/$ENV{USER}/.apache-test/apache_test_config.pm
#

$Test::Harness::verbose = 1 if $opts{verbose};

opt_help() if $opts{help};
opt_help() unless $opts{'config-file'};

if ($opts{'base-dir'}) {
    unless (-d $opts{'base-dir'}) {
        error "can't find $opts{'base-dir'}";
        opt_help();
    }
}
else {
    my $dir = catdir $FindBin::Bin, qw(.. Apache-TestMe);
    # get rid of relative paths
    die "can't find the default dir $dir" unless -d $dir;
    my $from = cwd();
    chdir $dir or die "can't chdir to $dir: $!";
    $dir = cwd();
    chdir $from or die "can't chdir to $from: $!";
    $opts{'base-dir'} = $dir;
}


unless (-r $opts{'config-file'}) {
    error "can't read $opts{'config-file'}";
    opt_help();
}

    if ($opts{trace}) {
        my %levels = map {$_ => 1} @Apache::TestTrace::Levels;
        if (exists $levels{ $opts{trace} }) {
            $Apache::TestTrace::Level = $opts{trace};
            # propogate the override for the server-side.
            # -trace overrides any previous APACHE_TEST_TRACE_LEVEL settings
            $ENV{APACHE_TEST_TRACE_LEVEL} = $opts{trace};
        }
        else {
            error "unknown trace level: $opts{trace}",
                "valid levels are: @Apache::TestTrace::Levels";
            opt_help();
        }
    }

# forward the data to the sub-processes run by Test::Harness
$ENV{APACHE_TESTITSELF_CONFIG_FILE} = $opts{'config-file'};
$ENV{APACHE_TESTITSELF_BASE_DIR}    = $opts{'base-dir'};

run_my_tests();

sub run_my_tests {

    my $base = "t";
    unless (-d $base) {
        # try to move into the top-level directory
        chdir ".." or die "Can't chdir: $!";
    }

    my @tests;
    if (@ARGV) {
        for (@ARGV) {
            if (-d $_) {
                push @tests, <$_/*.t>;
            } else {
                $_ .= ".t" unless /\.t$/;
                push @tests, $_;
            }
        }
    } else {
        chdir $base;
        @tests = sort (<*.t>);
        chdir "..";
        @tests = map { "$base/$_" } @tests;
    }

    runtests @tests;
}

sub opt_help {
    print <<EOM;
usage: TEST [options ...]
   where options include:
EOM

    for (sort keys %usage){
        printf "  -%-13s %s\n", $_, $usage{$_};
    }
    exit;
}
