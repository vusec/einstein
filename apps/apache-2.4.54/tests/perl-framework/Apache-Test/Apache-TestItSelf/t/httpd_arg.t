#
# basic testing with -httpd argument passed explicitly (to
# Makefile.PL, to t/TEST, etc.)
#

# XXX: -apxs should be really the same test but passing -apxs instead
# of -httpd, so consider to just run both in this test

use strict;
use warnings FATAL => 'all';

use Test::More;
use MyTest::Util qw(myrun3 go_in go_out test_configs);
use Apache::TestConfig ();

my @configs = test_configs();
my $tests_per_config = 18;
plan tests => $tests_per_config * @configs;

my $orig_dir = go_in();

for my $c (@configs) {
    Apache::TestConfig::custom_config_nuke();
    $ENV{APACHE_TEST_NO_STICKY_PREFERENCES} = 1;
    makefile_pl_plus_httpd_arg($c);

    # this one will have custom config, but it shouldn't interrupt
    # with the explicit one
    # XXX: useless at the moment, since the previously stored custom
    # config and the explicit config both point to the same config
    $ENV{APACHE_TEST_NO_STICKY_PREFERENCES} = 0;
    makefile_pl_plus_httpd_arg($c);

    Apache::TestConfig::custom_config_nuke();
    t_TEST_plus_httpd_arg($c);
}

go_out($orig_dir);

# 6 tests
# explicit Makefile.PL -httpd argument
sub makefile_pl_plus_httpd_arg {
    my $c = shift;

    my($cmd, $out, $err);

    # clean and ignore the results
    $cmd = "make clean";
    ($out, $err) = myrun3($cmd);

    my $makepl_arg = $c->{makepl_arg} || '';
    $cmd = "$c->{perl_exec} Makefile.PL $makepl_arg " .
        "-httpd $c->{httpd_exec} -httpd_conf $c->{httpd_conf}";
    ($out, $err) = myrun3($cmd);
    unlike $err, qr/\[  error\]/, $cmd;

    $cmd = "make";
    ($out, $err) = myrun3($cmd);
    is $err, "", $cmd;

    my $test_verbose = $c->{test_verbose} ? "TEST_VERBOSE=1" : "";
    $cmd = "make test $test_verbose";
    ($out, $err) = myrun3($cmd);
    like $out, qr/using $c->{httpd_version} \($c->{httpd_mpm} MPM\)/, $cmd;
    like $out, qr/All tests successful/, $cmd;
    unlike $err, qr/\[  error\]/, $cmd;

    # test that httpd is found in t/REPORT (if exists)
    SKIP: {
        $cmd = "t/REPORT";
        skip "$cmd doesn't exist", 1 unless -e $cmd;

        ($out, $err) = myrun3($cmd);
        like $out, qr/Server version: $c->{httpd_version}/, $cmd;
    }
}

# explicit t/TEST -httpd argument
sub t_TEST_plus_httpd_arg {
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

    my $test_verbose = $c->{test_verbose} ? "-v " : "";
    $cmd = "t/TEST -httpd $c->{httpd_exec} $test_verbose";
    ($out, $err) = myrun3($cmd);
    like $out,
        qr/using $c->{httpd_version} \($c->{httpd_mpm} MPM\)/,
        $cmd;
    like $out, qr/All tests successful/, $cmd;
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

