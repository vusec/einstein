use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;
use HTTP::Response;

## 
## mod_remoteip tests
##
## PROXY protocol: https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt
##
Apache::TestRequest::module("remote_ip");
plan tests => 12,
    need(
        need_module('remoteip'),
        need_min_apache_version('2.4.30')
    );

sub slurp
{
    my $s = shift;
    my $r = "";
    my $b;
    while ($s->read($b, 10000) > 0) {
        $r .= $b;
    }
    return $r;
}

ok(my $sock = Apache::TestRequest::vhost_socket("remote_ip"));

#
# Test human readable format: TCP4
#
my $proxy = "PROXY TCP4 192.168.192.66 192.168.192.77 1111 2222\r\n";
my $url = "GET /index.html HTTP/1.1\r\nConnection: close\r\n";
$url .= "Host: dummy\r\n\r\n";

$sock->print($proxy . $url);
$sock->shutdown(1);

my $response_data = slurp($sock);
my $r = HTTP::Response->parse($response_data);
chomp(my $content = $r->content);
ok t_cmp($r->code, 200, "PROXY human readable TCP4 protocol check");
ok t_cmp($content, "PROXY-OK", "Content check");
$sock->shutdown(2);

#
# BAD format test
#
$proxy = "PROXY FOO 192.168.192.66 192.168.192.77 1111 2222\r\n";
ok ($sock = Apache::TestRequest::vhost_socket("remote_ip"));
$sock->print($proxy . $url);
$sock->shutdown(1);

# In httpd, a bad PROXY format simply results in the connection
# being dropped. So ensure we don't get anything that looks
# like a response
$response_data = slurp($sock);
$r = HTTP::Response->parse($response_data);
chomp($content = $r->content);
ok t_cmp($r->code, undef, "broken PROXY human readable protocol check");
ok t_cmp($content, "", "Content check");
$sock->shutdown(2);

#
# Test human readable format: TCP6
#
$proxy = "PROXY TCP6 2001:DB8::21f:5bff:febf:ce22:8a2e 2001:DB8::12f:8baa:eafc:ce29:6b2e 3333 4444\r\n";
ok ($sock = Apache::TestRequest::vhost_socket("remote_ip"));
$sock->print($proxy . $url);
$sock->shutdown(1);
$response_data = slurp($sock);
$r = HTTP::Response->parse($response_data);
chomp($content = $r->content);
ok t_cmp($r->code, 200, "PROXY human readable TCP6 protocol check");
ok t_cmp($content, "PROXY-OK", "Content check");
$sock->shutdown(2);

# Test binary format
$proxy = "\x0D\x0A\x0D\x0A\x00\x0D\x0A\x51\x55\x49\x54\x0A"; # header
$proxy .= "\x21"; # protocol version and command (AF_INET STREAM)
$proxy .= "\x11"; # transport protocol and address family (TCP over IPv4)
$proxy .= "\x00\x0C"; # 12 bytes coming up
$proxy .= "\xC0\xA8\xC0\x42\xC0\xA8\xC0\x4D\x01\xF0\x01\xF1"; # IP addresses and ports
ok ($sock = Apache::TestRequest::vhost_socket("remote_ip"));
$sock->print($proxy . $url);
$sock->shutdown(1);
$response_data = slurp($sock);
$r = HTTP::Response->parse($response_data);
chomp($content = $r->content);
ok t_cmp($r->code, 200, "PROXY binary protocol TCP4 check");
ok t_cmp($content, "PROXY-OK", "Content check");
$sock->shutdown(2);
