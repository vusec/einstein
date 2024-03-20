use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 1, need_php4;

my $expected = <<EXPECT;
 0  a  1  a  2  a  3  a  4  a  5  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 6  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 5  a  5  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 6  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 4  a  4  a  5  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 6  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 5  a  5  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 6  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 3  a  3  a  4  a  5  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 6  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 5  a  5  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 6  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 4  a  4  a  5  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 6  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 5  a  5  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 6  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 2  a  2  a  3  a  4  a  5  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 6  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 5  a  5  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 6  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 4  a  4  a  5  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 6  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 5  a  5  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 6  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 3  a  3  a  4  a  5  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 6  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 5  a  5  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 6  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 4  a  4  a  5  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 6  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 5  a  5  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 6  a  6  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 7  a  7  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
 b 8  a  8  a  9 
 b 10 
 b 9  a  9 
 b 10 
EXPECT

my $result = GET_BODY "/php/regression3.php";

ok $result eq $expected;
