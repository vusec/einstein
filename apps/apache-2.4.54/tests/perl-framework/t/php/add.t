use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 1, need_php;

## add.php source:
## <?php $a=1; $b=2; $c=3; $d=$a+$b+$c; echo $d?>
##
## result should be '6' (1+2+3=6)

my $result = GET_BODY "/php/add.php";
ok $result eq '6';
