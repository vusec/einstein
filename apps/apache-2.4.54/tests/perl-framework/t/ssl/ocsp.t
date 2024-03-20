use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestSSLCA;
use Apache::TestRequest;
use Apache::TestConfig ();

#if keepalives are on, renegotiation not happen again once
#a client cert is presented.  so on test #3, the cert from #2
#will be used.  this test scenerio would never
#happen in real-life, so just disable keepalives here.
Apache::TestRequest::user_agent_keepalive(0);

my $url = '/index.html';

Apache::TestRequest::scheme('https');
Apache::TestRequest::module('ssl_ocsp');

my $openssl = Apache::TestSSLCA::openssl();
if (!have_min_apache_version('2.4.26')
    or `$openssl list -commands 2>&1` !~ /ocsp/) {
    print "1..0 # skip: No OpenSSL or mod_ssl OCSP support";
    exit 0;
}

plan tests => 3, need_lwp;

my $r;

sok {
    $r = GET $url, cert => undef;
    my $message = $r->content() || '';
    my $warning = $r->header('Client-Warning') || '';
    print "warning: $warning\n";
    print "message: $message";
    print "response:\n";
    print $r->as_string;
    $r->code == 500 && $warning =~ 'Internal response' &&
        $message =~ /alert handshake failure|read failed|closed connection without sending any data/;
};

sok {
    $r = GET $url, cert => 'client_ok';
    my $warning = $r->header('Client-Warning') || '';
    my $message = $r->content() || '';
    print "warning: $warning\n";
    print "message: $message";
    print "response:\n";
    print $r->as_string;
    $r->code == 200;
};

sok {
    $r = GET $url, cert => 'client_revoked';
    my $message = $r->content() || '';
    my $warning = $r->header('Client-Warning') || '';
    print "warning: $warning\n";
    print "message: $message";
    print "response:\n";
    print $r->as_string;
    $r->code == 500 && $warning =~ 'Internal response' &&
        $message =~ /alert certificate revoked|read failed|closed connection without sending any data/;
};
