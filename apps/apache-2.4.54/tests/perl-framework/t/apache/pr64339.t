use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my @testcases = (
    # Backend sends Content-Type: application/xml; charset=utf-8
    ['/doc.xml', "application/xml; charset=utf-8", "fóó\n" ],

    # Backend sends Content-Type: application/foo+xml; charset=utf-8
    ['/doc.fooxml', "application/foo+xml; charset=utf-8", "fóó\n" ],

    # Backend sends Content-Type: application/notreallyxml (no charset)
    # This should NOT be transformed or have a charset added.
    ['/doc.notxml', "application/notreallyxml", "f\xf3\xf3\n" ],

    # Sent with charset=ISO-8859-1 - should be transformed to utf-8
    ['/doc.isohtml', "text/html;charset=utf-8", "<html><body><p>fóó\n</p></body></html>" ],
);

# mod_xml2enc on trunk behaves quite differently to the 2.4.x version
# after r1785780, and does NOT transform the response body. Unclear if
# this is a regression, so restricting this test to 2.4.x (for now).

if (have_min_apache_version('2.5.0')) {
    print "1..0 # skip: Test only valid for 2.4.x";
    exit 0;
}

# todo: amend to 2.4.59
if (not have_min_apache_version('2.4.60')) {
    print "1..0 # skip: Test not valid before 2.4.60";
    exit 0;
}

plan tests => (3*scalar @testcases), need [qw(xml2enc alias proxy_html proxy)];

foreach my $t (@testcases) {
    my $r = GET("/modules/xml2enc/front".$t->[0]);
    
    ok t_cmp($r->code, 200, "fetching ".$t->[0]);
    ok t_cmp($r->header('Content-Type'), $t->[1], "content-type header test for ".$t->[0]);
    ok t_cmp($r->content, $t->[2], "content test for ".$t->[0]);
}
