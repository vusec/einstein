use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my @qvalue = (
    [ ''          , 1],
    [ ' '         , 1],
    [ ';'         , 1],
    [';q='        , 1],
    [';q=0'       , 0],
    [';q=0.'      , 0],
    [';q=0.0'     , 0],
    [';q=0.00'    , 0],
    [';q=0.000'   , 0],
    [';q=0.0000'  , 1],   # invalid qvalue format
);

plan tests => (6 * scalar @qvalue) + 4, need_module 'brotli', need_module 'alias';

my $r;

foreach my $q (@qvalue) {
    # GET request against the location with Brotli.
    print "qvalue: " . $q->[0] . "\n";
    $r = GET("/only_brotli/index.html", "Accept-Encoding" => "br" . $q->[0]);
    ok t_cmp($r->code, 200);
    if ($q->[1] == 1) {
        ok t_cmp($r->header("Content-Encoding"), "br", "response Content-Encoding is OK");
    }
    else {
        ok t_cmp($r->header("Content-Encoding"), undef, "response without Content-Encoding is OK");
    }
    
    if (!defined($r->header("Content-Length"))) {
        t_debug "Content-Length was expected";
        ok 0;
    }
    if (!defined($r->header("ETag"))) {
        t_debug "ETag field was expected";
        ok 0;
    }

    # GET request for a zero-length file.
    print "qvalue: " . $q->[0] . "\n";
    $r = GET("/only_brotli/zero.txt", "Accept-Encoding" => "br" . $q->[0]);
    ok t_cmp($r->code, 200);
    if ($q->[1] == 1) {
        ok t_cmp($r->header("Content-Encoding"), "br", "response Content-Encoding is OK");
    }
    else {
        ok t_cmp($r->header("Content-Encoding"), undef, "response without Content-Encoding is OK");
    }

    if (!defined($r->header("Content-Length"))) {
        t_debug "Content-Length was expected";
        ok 0;
    }
    if (!defined($r->header("ETag"))) {
        t_debug "ETag field was expected";
        ok 0;
    }

    # HEAD request against the location with Brotli.
    print "qvalue: " . $q->[0] . "\n";
    $r = HEAD("/only_brotli/index.html", "Accept-Encoding" => "br" . $q->[0]);
    ok t_cmp($r->code, 200);
    if ($q->[1] == 1) {
        ok t_cmp($r->header("Content-Encoding"), "br", "response Content-Encoding is OK");
    }
    else {
        ok t_cmp($r->header("Content-Encoding"), undef, "response without Content-Encoding is OK");
    }

    if (!defined($r->header("Content-Length"))) {
        t_debug "Content-Length was expected";
        ok 0;
    }
    if (!defined($r->header("ETag"))) {
        t_debug "ETag field was expected";
        ok 0;
    }
}


if (have_module('deflate')) {
    # GET request against the location with fallback to deflate (test that
    # Brotli is chosen due to the order in SetOutputFilter).
    $r = GET("/brotli_and_deflate/apache_pb.gif", "Accept-Encoding" => "gzip,br");
    ok t_cmp($r->code, 200);
    ok t_cmp($r->header("Content-Encoding"), "br", "response Content-Encoding is OK");
    if (!defined($r->header("Content-Length"))) {
        t_debug "Content-Length was expected";
        ok 0;
    }
    if (!defined($r->header("ETag"))) {
        t_debug "ETag field was expected";
        ok 0;
    }
    $r = GET("/brotli_and_deflate/apache_pb.gif", "Accept-Encoding" => "gzip");
    ok t_cmp($r->code, 200);
    ok t_cmp($r->header("Content-Encoding"), "gzip", "response Content-Encoding is OK");
    if (!defined($r->header("Content-Length"))) {
        t_debug "Content-Length was expected";
        ok 0;
    }
    if (!defined($r->header("ETag"))) {
        t_debug "ETag field was expected";
        ok 0;
    }
} else {
    skip "skipping tests without mod_deflate" foreach (1..4);
}
