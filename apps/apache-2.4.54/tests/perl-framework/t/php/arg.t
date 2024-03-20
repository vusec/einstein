use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 1, need_php;

## arg.php source:
## <?php
##        for($i=0;$i<$argc;$i++) {
##                echo "$i: ".$argv[$i]."\n";
##        }
## ?>
##
## result should be '<arg number>: <arg>' for each arg sent.

my @testargs = ('foo', 'b@r', 'testarg123-456-fu', 'ARGV', 'hello%20world');
my ($expected, $testargs) = ('','');
my $count = 0;

foreach (@testargs) {
    $testargs .= "$_+";
    $expected .= "$count: $_\n";
    $count++;
}
chop($testargs); ## get rid of trailing '+'

my $result = GET_BODY "/php/arg.php?$testargs";
ok t_cmp($result,
         $expected,
         "GET request for /php/arg.php?$testargs"
        );
