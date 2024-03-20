use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 1, need_php;

my $expected = <<EXPECT;
i=0
In branch 0
i=1
In branch 1
i=2
In branch 2
i=3
In branch 3
hi
EXPECT

my $result = GET_BODY "/php/switch3.php";
ok $result eq $expected;
