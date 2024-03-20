use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 1, need_php;

my $expected = <<EXPECT;
zero
one
2
3
4
5
6
7
8
9
zero
one
2
3
4
5
6
7
8
9
zero
one
2
3
4
5
6
7
8
9
EXPECT

my $result = GET_BODY "/php/switch4.php";
ok $result eq $expected;
