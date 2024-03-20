use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 10, need 'ssl', need_min_apache_version('2.0');

my $r;

Apache::TestRequest::user_agent(ssl_opts => {SSL_version => 'TLSv13'});
Apache::TestRequest::scheme('https');

$r = GET "/";
my $tls13_works = $r->is_success;

# Forget the above user agent settings, start fresh
Apache::TestRequest::user_agent(reset => 1);

# If TLS 1.3 worked, downgrade to TLS 1.2, otherwise use what works.
if ($tls13_works) {
    t_debug "Downgrading to TLSv12";
    Apache::TestRequest::user_agent(ssl_opts => {SSL_cipher_list => 'ALL', SSL_version => 'TLSv12'});
} else {
    Apache::TestRequest::user_agent(ssl_opts => {SSL_cipher_list => 'ALL'});
}
Apache::TestRequest::user_agent_keepalive(1);
Apache::TestRequest::scheme('https');

# Send a series of POST requests with varying size request bodies.
# Alternate between the location which requires a AES128-SHA ciphersuite
# and one which requires AES256-SHA; mod_ssl will attempt to perform the
# renegotiation between each request, and hence needs to perform the
# buffering of request body data.

$r = POST "/require-aes256-cgi/perl_echo.pl", content => "hello world";

ok t_cmp($r->code, 200, "renegotiation on POST works");
ok t_cmp($r->content, "hello world", "request body matches response");

$r = POST "/require-aes128-cgi/perl_echo.pl", content => "hello world";

ok t_cmp($r->code, 200, "renegotiation on POST works");
ok t_cmp($r->content, "hello world", "request body matches response");

$r = POST "/require-aes256-cgi/perl_echo.pl", content => 'x'x10000;

ok t_cmp($r->code, 200, "renegotiation on POST works");
ok t_cmp($r->content, $r->request->content, "request body matches response");

$r = POST "/require-aes128-cgi/perl_echo.pl", content => 'x'x60000;

ok t_cmp($r->code, 200, "renegotiation on POST works");
ok t_cmp($r->content, $r->request->content, "request body matches response");

# Test that content-level input filters are still run as expected by
# using a request which triggers the mod_case_filter_in:

my @filter = ('X-AddInputFilter' => 'CaseFilterIn'); #mod_client_add_filter

if (have_module('case_filter_in')) {
    $r = POST "/require-aes256-cgi/perl_echo.pl", @filter, content => "hello";
    
    ok t_cmp($r->code, 200, "renegotiation on POST works");
    ok t_cmp($r->content, "HELLO", "request body matches response");
} else {
    skip "mod_case_filter_in not available" foreach (1..2);
}

