use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 2, [qw(input_body_filter)];

my $location = '/input_body_filter';

for my $x (1,2) {
    my $expected = "ok $x";
    my $data = scalar reverse $expected;
    my $response = POST_BODY $location, content => $data;
    ok t_cmp($response,
             $expected,
             "Posted \"$data\"");
}
