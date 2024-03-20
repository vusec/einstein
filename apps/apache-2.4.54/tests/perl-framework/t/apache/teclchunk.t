use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestCommon ();
use Apache::TestRequest ();

my $module = 'default';

if (!have_min_apache_version('2.5.0')) {
    print "1..0 # skip: Not supported yet";
    exit 0;
}

plan tests => 4, ['echo_post_chunk'];

my $sock = Apache::TestRequest::vhost_socket($module);
ok $sock;

Apache::TestRequest::socket_trace($sock);
$sock->print("POST /echo_post_chunk HTTP/1.1\r\n");
$sock->print("Host: localhost\r\n");
$sock->print("Content-Length: 77\r\n");
$sock->print("Transfer-Encoding: chunked\r\n");
$sock->print("\r\n");
$sock->print("0\r\n");
$sock->print("X-Chunk-Trailer: $$\r\n");
$sock->print("\r\n");
$sock->print("GET /i_do_not_exist_in_your_wildest_imagination HTTP/1.1\r\n");
$sock->print("Host: localhost\r\n");

# Read the status line
chomp(my $response = Apache::TestRequest::getline($sock) || '');
$response =~ s/\s$//;
ok t_cmp($response, "HTTP/1.1 200 OK", "response codes");

# Read the rest
do {
    chomp($response = Apache::TestRequest::getline($sock));
    $response =~ s/\s$//;
}
while ($response ne "");

# Do the next request... that MUST fail.
$sock->print("\r\n");
$sock->print("\r\n");

# read the trailer (pid)
$response = Apache::TestRequest::getline($sock);
chomp($response) if (defined($response));
ok t_cmp($response, "$$", "trailer (pid)");

# Make sure we have not received a 404.
chomp($response = Apache::TestRequest::getline($sock) || 'NO');
$response =~ s/\s$//;
ok t_cmp($response, "NO", "no response");
