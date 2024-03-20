#
# -minclients / -maxclients argument passed explicitly (to
# Makefile.PL, to t/TEST, etc.)
#

use strict;
use warnings FATAL => 'all';

use Test::More;
use MyTest::Util qw(myrun3 go_in go_out test_configs);
use Apache::TestConfig ();

my @configs = test_configs();
my $tests_per_config = 18;
plan tests => $tests_per_config * @configs;

my $orig_dir = go_in();

# min/maxclients of 10 should work for pretty much any test suite, so
# for now hardcoded the number in this test
my $clients = 10;
for my $c (@configs) {
    for my $opt_name (qw(minclients maxclients)) {
        my $opt = "-$opt_name $clients";
        makefile_pl_plus_opt($c, $opt);
        t_TEST_plus_opt($c, $opt);
    }
}

go_out($orig_dir);

# 4 sub tests
# explicit Makefile.PL -(mix|max)clients
sub makefile_pl_plus_opt {
    my $c = shift;
    my $opt = shift;

    my($cmd, $out, $err);

    # clean and ignore the results
    $cmd = "make clean";
    ($out, $err) = myrun3($cmd);

    my $makepl_arg = $c->{makepl_arg} || '';
    $cmd = "$c->{perl_exec} Makefile.PL $makepl_arg $opt " .
        "-httpd $c->{httpd_exec} -httpd_conf $c->{httpd_conf}";
    ($out, $err) = myrun3($cmd);
    unlike $err, qr/\[  error\]/, $cmd;

    $cmd = "make";
    ($out, $err) = myrun3($cmd);
    is $err, "", $cmd;

    my $test_verbose = $c->{test_verbose} ? "TEST_VERBOSE=1" : "";
    $cmd = "make test $test_verbose";
    ($out, $err) = myrun3($cmd);
    like $out, qr/All tests successful/, $cmd;
    unlike $err, qr/\[  error\]/, $cmd;
}

# 5 tests
# explicit t/TEST -(mix|max)clients
sub t_TEST_plus_opt {
    my $c = shift;
    my $opt = shift;

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

    # the bug was:
    # t/TEST -conf
    # t/TEST -maxclients 1
    #default_ VirtualHost overlap on port 8530, the first has precedence
    #(98)Address already in use: make_sock: could not bind to address
    #0.0.0.0:8530 no listening sockets available, shutting down

    my $test_verbose = $c->{test_verbose} ? "-v " : "";
    $cmd = "t/TEST -httpd $c->{httpd_exec} $test_verbose -conf";
    ($out, $err) = myrun3($cmd);
    unlike $err, qr/\[  error\]/, $cmd;

    $cmd = "t/TEST -httpd $c->{httpd_exec} $test_verbose $opt";
    ($out, $err) = myrun3($cmd);
    like $out, qr/All tests successful/, $cmd;
    unlike $err, qr/\[  error\]/, $cmd;
}

__END__

