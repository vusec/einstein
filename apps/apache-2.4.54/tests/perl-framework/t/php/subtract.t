use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 1, need_php;

## subtract.php source:
## <?php $a=27; $b=7; $c=10; $d=$a-$b-$c; echo $d?>
##
## result should be '10' (27-7-10=10)

my $result = GET_BODY "/php/subtract.php";
ok $result eq '10';
