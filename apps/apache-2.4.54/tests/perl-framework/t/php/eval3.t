use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

## testing eval function

plan tests => 1, need_php;

my $expected = <<EXPECT;
hey
0
hey
1
hey
2
hey
3
hey
4
hey
5
hey
6
hey
7
hey
8
hey
9
EXPECT

my $result = GET_BODY "/php/eval3.php";
ok $result eq $expected;
