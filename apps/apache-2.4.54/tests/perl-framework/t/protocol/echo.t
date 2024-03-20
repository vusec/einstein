use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest ();

my @test_strings = (
    $0,
    $^X,
    $$ x 5,
);

my $tests = 1 + @test_strings;
my $vars = Apache::Test::vars();
my @modules = qw(mod_echo);

if (have_ssl) {
    $tests *= 2;
    unshift @modules, 'mod_echo_ssl';
    Apache::TestRequest::set_ca_cert();
}

plan tests => $tests, ['mod_echo'];

for my $module (@modules) {
    print "testing $module\n";

    my $sock = Apache::TestRequest::vhost_socket($module);
    ok $sock;

    Apache::TestRequest::socket_trace($sock);

    for my $data (@test_strings) {
        $sock->print("$data\n");

        chomp(my $response = Apache::TestRequest::getline($sock));
        ok t_cmp($response, $data, 'echo');
    }
}
