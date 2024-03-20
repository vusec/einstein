use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
#
# Regression test for PR 18757.
#
# Annoyingly awkward to write because LWP is a poor excuse for an HTTP
# interface and will lie about what response headers are sent, so this
# must be yet another test which speaks TCP directly.
#

use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

plan tests => 3, need 'proxy', need_min_apache_version('2.2.1'), need_cgi;

Apache::TestRequest::module("mod_proxy");

my $path = "/index.html";

my $r = GET($path);

ok t_cmp($r->code, 200, "200 response from GET");

my $clength = $r->content_length;

t_debug("expected C-L is $clength");

my $url = Apache::TestRequest::resolve_url($path);
my $hostport = Apache::TestRequest::hostport();
my $sock = Apache::TestRequest::vhost_socket("mod_proxy");

t_debug "URL via proxy is $url";

ok $sock;

$sock->print("HEAD $url HTTP/1.1\r\n");
$sock->print("Host: $hostport\r\n");
$sock->print("\r\n");

my $ok = 0;
my $response;

do {
    chomp($response = Apache::TestRequest::getline($sock) || '');
    $response =~ s/\s$//;

    t_debug("line: $response");
    
    if ($response =~ /Content-Length: $clength/) {
        $ok = 1;
    }

}
while ($response ne "");

ok t_cmp($ok, 1, "whether proxy strips Content-Length header");
