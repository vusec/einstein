use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

plan tests => 2,
     need(
        need_module('mod_headers'),
        need_min_apache_version('2.5.0')
     );

my @headers;
push @headers, "Range" => "bytes=6549-";

my $uri = "/modules/filter/byterange/pr61860/test.html";

my $response = GET($uri, @headers);

ok t_cmp($response->code, 416, "Out of Range bytes in header should return HTTP 416");

my @duplicate_header = $response->header("TestDuplicateHeader");

ok t_cmp(@duplicate_header, 1, "Headers should not be duplicated on HTTP 416 responses");