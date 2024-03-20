use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

## testing eval function

plan tests => 1, need_php;

my $expected = "Hello";

my $result = GET_BODY "/php/eval.php";
ok $result eq $expected;
