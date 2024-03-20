use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
#testing that the server can respond right after client connects,
#before client sends any request data

use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my $tests = 5;
my $vars = Apache::Test::vars();
my @modules = qw(mod_nntp_like);

if (have_ssl && ! have_module('http2')) {
    $tests *= 2;
    unshift @modules, 'mod_nntp_like_ssl';
    Apache::TestRequest::set_ca_cert();
}

plan tests => $tests, need('mod_nntp_like',
                           { "deferred accept() prohibits testing with >=2.1.0 and OS $^O" =>
                                 sub { !have_min_apache_version('2.1.0') 
                                           || ($^O ne "linux" && $^O ne "darwin")} } );
                               
for my $module (@modules) {
    print "testing $module\n";

    my $sock = Apache::TestRequest::vhost_socket($module);
    ok $sock;

    Apache::TestRequest::socket_trace($sock);

    my $response = Apache::TestRequest::getline($sock);

    $response =~ s/[\r\n]+$//;
    ok t_cmp($response, '200 localhost - ready',
             'welcome response');

    for my $data ('LIST', 'GROUP dev.httpd.apache.org', 'ARTICLE 401') {
        $sock->print("$data\n");

        $response = Apache::TestRequest::getline($sock);
        chomp($response) if (defined($response));
        ok t_cmp($response, $data, 'echo');
    }
}
