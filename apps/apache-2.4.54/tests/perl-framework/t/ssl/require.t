use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

#if keepalives are on, renegotiation not happen again once
#a client cert is presented.  so on test #3, the cert from #2
#will be used.  this test scenerio would never
#happen in real-life, so just disable keepalives here.
Apache::TestRequest::user_agent_keepalive(0);

my $sslrequire_oid_needed_version = '2.1.7';
my $have_sslrequire_oid = have_min_apache_version($sslrequire_oid_needed_version);

plan tests => 10, need_lwp;

Apache::TestRequest::scheme('https');

my $url = '/require/asf/index.html';

ok GET_RC($url, cert => undef) != 200;

ok GET_RC($url, cert => 'client_ok') == 200;

ok GET_RC($url, cert => 'client_revoked') != 200;

$url = '/require/snakeoil/index.html';

ok GET_RC($url, cert => 'client_ok') != 200;

ok GET_RC($url, cert => 'client_snakeoil') == 200;

ok GET_RC('/require/strcmp/index.html', cert => undef) == 200;

ok GET_RC('/require/intcmp/index.html', cert => undef) == 200;

if ($have_sslrequire_oid) {

    $url = '/require/certext/index.html';

    ok GET_RC($url, cert => undef) != 200;

    if (!have_min_apache_version("2.4.0")) { 
       skip "not backported, see 2.2.19 vote thread for analysis";
    }
    else { 
        ok GET_RC($url, cert => 'client_ok') == 200;
    }

    ok GET_RC($url, cert => 'client_snakeoil') != 200;

} else {
    skip "skipping certificate extension test (httpd < $sslrequire_oid_needed_version)" foreach (1..3);
}
