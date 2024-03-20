use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

## testing include

plan tests => 1, need_php;

my $expected = "Hello";

my $result = GET_BODY "/php/include.php";
ok $result eq $expected;
