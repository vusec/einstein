use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my @testcases = (
    ['/apache/reflector_nodeflate/', "Text that will not reach the DEFLATE filter"],
    ['/apache/reflector_deflate/', "Text that should be gzipped"],
);

my @headers;
push @headers, "header2reflect" => "1";
push @headers, "header2update" => "1";
push @headers, "header2delete" => "1";
push @headers, "Content-Encoding" => "gzip";
push @headers, "Accept-Encoding" => "gzip";

plan tests => scalar @testcases * 7, need 'mod_reflector', 'mod_deflate';

foreach my $t (@testcases) {
    my $r = POST($t->[0], @headers, content => $t->[1]);

    # Checking for return code
    ok t_cmp($r->code, 200, "Checking return code is '200'");

    # Checking for content
    if (index($t->[0], "_nodeflate") != -1) {
        # With no filter, we should receive what we have sent
        ok t_is_equal($r->content, $t->[1]);
        ok t_cmp($r->header("Content-Encoding"), undef, "'Content-Encoding' has not been added because there was no filter");
    } else {
        # With DEFLATE, input should have been updated and 'Content-Encoding' added
        ok not t_is_equal($r->content, $t->[1]);
        ok t_cmp($r->header("Content-Encoding"), "gzip", "'Content-Encoding' has been added by the DEFLATE filter");
    }

    # Checking for headers
    ok t_cmp($r->header("header2reflect"), "1", "'header2reflect' is present");
    ok t_cmp($r->header("header2update"), undef, "'header2update' is absent");
    ok t_cmp($r->header("header2updateUpdated"), "1", "'header2updateUpdated' is present");
    ok t_cmp($r->header("header2delete"), undef, "'header2delete' is absent");
}
