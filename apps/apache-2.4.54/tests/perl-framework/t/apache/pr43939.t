use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

plan tests => 4, need [need_cgi, qw(include deflate case_filter)];
my $inflator = "/modules/deflate/echo_post";

my @deflate_headers;
push @deflate_headers, "Accept-Encoding" => "gzip";

my @inflate_headers;
push @inflate_headers, "Content-Encoding" => "gzip";

# The SSI script has the DEFLATE filter applied.
# The SSI includes directory index page.
# The directory index page is processed with a fast internal redirect.

# The test is that filter chain survives across the redirect.

my $uri = "/modules/deflate/ssi/ssi2.shtml";

my $content = GET_BODY($uri);

my $expected = "begin-default-end\n";

ok t_cmp($content, $expected);

my $r = GET($uri, @deflate_headers);

ok t_cmp($r->code, 200);

my $renc = $r->header("Content-Encoding") || "";

ok t_cmp($renc, "gzip", "response was gzipped");

if ($renc eq "gzip") {
    my $deflated = POST_BODY($inflator, @inflate_headers,
                             content => $r->content);
    
    ok t_cmp($deflated, $expected);
}
else {
    skip "response not gzipped";
}
