use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 1, need_php;

## ops.php source:
## <?php $a=8; $b=4; $c=8; echo $a|$b&$c?>
##
## result should be '8'

my $result = GET_BODY "/php/ops.php";
ok $result eq '8';
