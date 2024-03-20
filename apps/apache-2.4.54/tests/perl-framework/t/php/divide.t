use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 1, need_php;

## divide.php source:
## <?php $a=27; $b=3; $c=3; $d=$a/$b/$c; echo $d?>
##
## result should be '3' (27/3/3=3)

my $result = GET_BODY "/php/divide.php";
ok $result eq '3';
