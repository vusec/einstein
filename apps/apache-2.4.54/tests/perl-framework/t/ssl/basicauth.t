use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';
use Apache::Test;
use Apache::TestRequest;
use Apache::TestConfig ();
use Apache::TestUtil;

#if keepalives are on, renegotiation not happen again once
#a client cert is presented.  so on test #3, the cert from #2
#will be used.  this test scenerio would never
#happen in real-life, so just disable keepalives here.
Apache::TestRequest::user_agent_keepalive(0);

my $url = '/ssl-fakebasicauth/index.html';

plan tests => 4, need need_auth, need_lwp;

Apache::TestRequest::scheme('https');

# With TLSv1.3 mod_ssl may return a better 403 error here, otherwise
# expect a TLS alert which is represented as a 500 by LWP.
ok t_cmp (GET_RC($url, cert => undef),
          qr/^(500|403)$/,
          "Getting $url with no cert"
         );

ok t_cmp (GET_RC($url, cert => 'client_snakeoil'),
          200,
          "Getting $url with client_snakeoil cert"
         );

ok t_cmp (GET_RC($url, cert => 'client_ok'),
          401,
          "Getting $url with client_ok cert"
         );

if (!have_min_apache_version("2.5.1")) {
    skip "Colon in username test skipped.";
}
else {
    ok t_cmp (GET_RC($url, cert => 'client_colon'),
              403,
              "Getting $url with client_colon cert"
        );
}
