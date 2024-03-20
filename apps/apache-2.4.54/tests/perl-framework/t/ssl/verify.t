use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestConfig ();

#if keepalives are on, renegotiation not happen again once
#a client cert is presented.  so on test #3, the cert from #2
#will be used.  this test scenerio would never
#happen in real-life, so just disable keepalives here.
Apache::TestRequest::user_agent_keepalive(0);

my $url = '/verify/index.html';

plan tests => 3, need_lwp;

Apache::TestRequest::scheme('https');

my $r;

sok {
    $r = GET $url, cert => undef;
    print $r->as_string;
    $r->code != 200;
};

sok {
    $r = GET $url, cert => 'client_ok';
    print $r->as_string;
    $r->code == 200;
};

sok {
    $r = GET $url, cert => 'client_revoked';
    print $r->as_string;
    $r->code != 200;
};

