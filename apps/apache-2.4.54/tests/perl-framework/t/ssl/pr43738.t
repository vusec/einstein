use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 4, 
    need 'ssl', need_module('actions'),
    need_min_apache_version('2.2.7');

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

# Variation of the PR 12355 test which breaks per PR 43738.

$r = POST "/modules/ssl/aes128/empty.pfa", content => "hello world";

ok t_cmp($r->code, 200, "renegotiation on POST works");
ok t_cmp($r->content, "/modules/ssl/aes128/empty.pfa\nhello world", "request body matches response");

$r = POST "/modules/ssl/aes256/empty.pfa", content => "hello world";

ok t_cmp($r->code, 200, "renegotiation on POST works");
ok t_cmp($r->content, "/modules/ssl/aes256/empty.pfa\nhello world", "request body matches response");
