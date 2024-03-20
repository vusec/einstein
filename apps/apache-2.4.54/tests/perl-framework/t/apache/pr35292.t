use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

$SIG{PIPE} = 'IGNORE';

plan tests => 3, need_min_apache_version('2.1.8');

my $sock = Apache::TestRequest::vhost_socket('default');
ok $sock;

Apache::TestRequest::socket_trace($sock);

$sock->print("POST /apache/limits/ HTTP/1.1\r\n");
$sock->print("Host: localhost\r\n");
$sock->print("Content-Length: 1048576\r\n");
$sock->print("\r\n");

foreach (1..128) {
    $sock->print('x'x8192) if $sock->connected;
}

# Before the PR 35292 fix, the socket would already have been reset by
# this point and most clients will have stopped sending and gone away.

ok $sock->connected;

my $line = Apache::TestRequest::getline($sock) || '';

ok t_cmp($line, qr{^HTTP/1\.. 413}, "read response-line");
