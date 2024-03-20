use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my $result = GET_BODY "/php/strings3.php";
my @res = split /\n/, $result;
my $count = @res;

plan tests => $count + 1, need_php;

my $expected = <<EXPECT;
printf test 1:simple string
printf test 2:42
printf test 3:3.333333
printf test 4:3.3333333333
printf test 5:2.50      
printf test 6:2.50000000
printf test 7:0000002.50
printf test 8:<                 foo>
printf test 9:<bar                 >
printf test 10: 123456789012345
printf test 10:<høyesterettsjustitiarius>
printf test 11: 123456789012345678901234567890
printf test 11:<      høyesterettsjustitiarius>
printf test 12:-12.34
printf test 13:  -12
printf test 14:@
printf test 15:10101010
printf test 16:aa
printf test 17:AA
printf test 18:        10101010
printf test 19:              aa
printf test 20:              AA
printf test 21:0000000010101010
printf test 22:00000000000000aa
printf test 23:00000000000000AA
printf test 24:abcde
printf test 25:gazonk
printf test 26:2 1
printf test 27:3 1 2
printf test 28:02  1
printf test 29:2   1
EXPECT

my @exp = split /\n/, $expected;
my $count2 = @exp;

ok $count eq $count2;

foreach (my $i = 0 ; $i < $count ; $i++) {
    ok t_cmp("[".$res[$i]."]", "[".$exp[$i]."]", "test $i");
}
