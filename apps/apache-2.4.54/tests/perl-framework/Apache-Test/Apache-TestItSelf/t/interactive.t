#
# interactive testing (when A-T) can't figure out the configuration
#

use Test::More;

use strict;
use warnings FATAL => 'all';

use IPC::Run qw(start pump finish timeout);
use Cwd qw(cwd);
use File::Spec::Functions qw(catfile);

use MyTest::Util qw(myrun3 go_in go_out work_dir check_eval
                    test_configs);

use Apache::TestConfig ();
use Apache::TestTrace;

# in this test we don't want any cached preconfiguration to kick in
# A-T is aware of this env var and won't load neither custom config, nor
# Apache/Build.pm from mod_perl2.
local $ENV{APACHE_TEST_INTERACTIVE_CONFIG_TEST} = 1;

my @configs = test_configs();
if ($configs[0]{repos_type} eq 'mp2_core') {
    plan skip_all => "modperl2 doesn't run interactive config";
}
else {
    my $tests_per_config = 11;
    plan tests => $tests_per_config * @configs + 1;
}

my $orig_dir = go_in();

my $cwd = cwd();
my $expected_work_dir = work_dir();
is $cwd, $expected_work_dir, "working in $expected_work_dir";

debug "cwd: $cwd";

for my $c (@configs) {

    # install the sticky custom config
    install($c);

    # interactive config doesn't work with this var on
    $ENV{APACHE_TEST_NO_STICKY_PREFERENCES} = 0;
    basic($c);
}

go_out($orig_dir);

# 4 tests
sub install {
    my $c = shift;

    my($cmd, $out, $err);

    $cmd = "make clean";
    ($out, $err) = myrun3($cmd);
    # ignore the results

    my $makepl_arg = $c->{makepl_arg} || '';
    $cmd = "$c->{perl_exec} Makefile.PL $makepl_arg " .
        "-httpd $c->{httpd_exec} -apxs $c->{apxs_exec}";
    ($out, $err) = myrun3($cmd);
    my $makefile = catfile $expected_work_dir, "Makefile";
    is -e $makefile, 1, "generated $makefile";
    unlike $err, qr/\[  error\]/, "checking for errors";

    $cmd = "make";
    ($out, $err) = myrun3($cmd);
    is $err, "", $cmd;

    $cmd = "make install";
    ($out, $err) = myrun3($cmd);
    unlike $err, qr/\[  error\]/, $cmd;
}

# 7 tests
sub basic {
    my $c = shift;

    my($cmd, $out, $err);

    # clean and ignore the results
    $cmd = "make clean";
    ($out, $err) = myrun3($cmd);

    my $makepl_arg = $c->{makepl_arg} || '';
    $cmd = "$c->{perl_exec} Makefile.PL $makepl_arg";
    ($out, $err) = myrun3($cmd);
    unlike $err, qr/\[  error\]/, $cmd;

    $cmd = "make";
    ($out, $err) = myrun3($cmd);
    is $err, "", $cmd;

    {
        my $in;
        my $expected = '';
        my @cmd = qw(make test);
        push @cmd, "TEST_VERBOSE=1" if $c->{test_verbose};
        $cmd = join " ", @cmd;

        # bypass the -t STDIN checks to still ensure the interactive
        # config prompts
        $ENV{APACHE_TEST_INTERACTIVE_PROMPT_OK} = 1;

        $in  = '';
        $out = '';
        $err = '';
        my $h = start \@cmd, \$in, \$out, \$err, timeout($c->{timeout});

        # here the expect fails if the interactive config doesn't kick
        # in, but for example somehow figures out the needed
        # information (httpd/apxs) and runs the test suite normally
        $expected = "Please provide a full path to 'httpd' executable";
        eval { $h->pump until $out =~ /$expected/gc };
        my $reset_std = 1;
        check_eval($cmd, $out, $err, $reset_std,
                   "interactive config wasn't invoked");

        $in .= "$c->{httpd_exec}\n" ;
        $expected = "Please provide a full path to .*? 'apxs' executable";
        eval { $h->pump until $out =~ /$expected/gc };
        $reset_std = 1;
        check_eval($cmd, $out, $err, $reset_std,
                   "interactive config had a problem");

        $in .= "$c->{apxs_exec}\n" ;
        eval { $h->finish };
        $reset_std = 0; # needed for later sub-tests
        check_eval($cmd, $out, $err, $reset_std,
                   "failed to finish $cmd");
        like $out, qr/using $c->{httpd_version} \($c->{httpd_mpm} MPM\)/,
            "$cmd: using $c->{httpd_version} \($c->{httpd_mpm} MPM";
        like $out, qr/All tests successful/, "$cmd: All tests successful";
        unlike $err, qr/\[  error\]/, "$cmd: no error messages";
    }

    $cmd = "make install";
    ($out, $err) = myrun3($cmd);
    unlike $err, qr/\[  error\]/, $cmd;

    # test that httpd is found in t/REPORT (if exists)
    SKIP: {
        $cmd = "t/REPORT";
        skip "$cmd doesn't exist", 1 unless -e $cmd;

        ($out, $err) = myrun3($cmd);
        like $out, qr/Server version: $c->{httpd_version}/, $cmd;
    }
}

__END__

