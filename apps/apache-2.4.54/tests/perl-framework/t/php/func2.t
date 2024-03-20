use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 1, need_php4;

my $expected = <<EXPECT;
hey=0, 0
hey=1, -1
hey=2, -2
EXPECT

my $result = GET_BODY "/php/func2.php";
ok $result eq $expected;
