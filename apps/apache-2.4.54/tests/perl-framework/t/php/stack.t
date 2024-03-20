use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

## testing stack after early function return

plan tests => 1, need_php4;

my $expected = "HelloHello";

my $result = GET_BODY "/php/stack.php";
ok $result eq $expected;
