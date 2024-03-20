use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

plan tests => 1, need [qw(filter include deflate)];

my $inflator = "/modules/deflate/echo_post";

my @deflate_headers;
push @deflate_headers, "Accept-Encoding" => "gzip";

my @inflate_headers;
push @inflate_headers, "Content-Encoding" => "gzip";

my $uri = "/modules/filter/pr49328/pr49328.shtml";

my $content = GET_BODY($uri, @deflate_headers);

my $deflated = POST_BODY($inflator, @inflate_headers,
                         content => $content);

ok t_cmp($deflated, "before\nincluded\nafter\n");
