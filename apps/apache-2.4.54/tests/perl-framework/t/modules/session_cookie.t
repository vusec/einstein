use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

plan tests => have_min_apache_version('2.5.0') ? 4 : 2,
              need_module 'session_cookie';

my $uri = '/modules/session_cookie/test404';
my $r = GET($uri);
my @set_cookie_headers = $r->header("Set-Cookie");
ok t_cmp($r->code, 404);

# See PR: 60910
if (have_min_apache_version('2.5.0')) {
    ok t_cmp(scalar(@set_cookie_headers), 1, "Set-Cookie header not duplicated in error response (404).");
}

$uri = '/modules/session_cookie/test';
$r = GET($uri);
@set_cookie_headers = $r->header("Set-Cookie");
ok t_cmp($r->code, 200);

# See PR: 60910
if (have_min_apache_version('2.5.0')) {
    ok t_cmp(scalar(@set_cookie_headers), 1, "Set-Cookie header not duplicated in successful response (200).");
}