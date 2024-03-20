use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 1, need_php;

my $expected = <<EXPECT;
This is class foo
a = 2
b = 5
10
-----
This is class bar
a = 4
b = 3
c = 12
12
EXPECT

my $result = GET_BODY "/php/inheritance.php";
ok $result eq $expected
