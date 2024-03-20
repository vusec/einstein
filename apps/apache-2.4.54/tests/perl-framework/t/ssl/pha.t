use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;
use IO::Socket::SSL;

# This is the equivalent of pr12355.t for TLSv1.3.

Apache::TestRequest::user_agent(ssl_opts => {SSL_version => 'TLSv13'});
Apache::TestRequest::scheme('https');
Apache::TestRequest::user_agent_keepalive(1);

my $r = GET "/";

if (!$r->is_success) {
    print "1..0 # skip: TLSv1.3 not supported";
    exit 0;
}

if (!defined &IO::Socket::SSL::can_pha || !IO::Socket::SSL::can_pha()) {
    print "1..0 # skip: PHA not supported by IO::Socket::SSL < 2.061";
    exit 0;
}

plan tests => 4, need_min_apache_version("2.4.47");

$r = GET("/verify/", cert => undef);
ok t_cmp($r->code, 403, "access must be denied without client certificate");

# SSLRenegBufferSize 10 for this location which should mean a 413
# error.
$r = POST("/require/small/perl_echo.pl", content => 'y'x101,
          cert => 'client_ok');
ok t_cmp($r->code, 413, "PHA reneg body buffer size restriction works");

# Reset to use a new connection.
Apache::TestRequest::user_agent(reset => 1);
Apache::TestRequest::user_agent(ssl_opts => {SSL_version => 'TLSv13'});
Apache::TestRequest::scheme('https');

$r = POST("/verify/modules/cgi/perl_echo.pl", content => 'x'x10000,
          cert => 'client_ok');

ok t_cmp($r->code, 200, "PHA works with POST body");
ok t_cmp($r->content, $r->request->content, "request body matches response");
