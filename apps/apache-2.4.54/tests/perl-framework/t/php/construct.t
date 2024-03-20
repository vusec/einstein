use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 2, need_php4;

## testing PHP OO bug (#7515)
## php src:
## <?php
## class obj {
##         function method() {}
##     }
## 
## function test($o_copy) {
##         $o_copy->root->set_in_copied_o=TRUE;
##         var_dump($o_copy);?><BR><?php }
## 
## $o->root=new obj();
## 
## ob_start();
## var_dump($o);
## $x=ob_get_contents();
## ob_end_clean();
## 
## $o->root->method();
## 
## ob_start();
## var_dump($o);
## $y=ob_get_contents();
## ob_end_clean();
## 
## // $o->root->method() makes ob_get_contents() have a '&' in front of object
## // so this does not work.
## // echo ($x==$y) ? 'success':'failure';
## 
## echo "x = $x";
## echo "y = $y";
## ?>
## 
## output should be:
## x = object(stdClass)(1) {
##  ["root"]=>
##  object(obj)(0) {
##  }
## }
## y = object(stdClass)(1) {
##  ["root"]=>
##  &object(obj)(0) {
##  }
## }

my $result = GET_BODY "/php/construct.php";

## get rid of newlines to make compairon easier.
$result =~ s/\n//g;

my ($x, $y);
if ($result =~ /x = (.*)y = (.*)/) {
    $x = $1;
    $y = $2;
}

ok $x eq "object(stdClass)(1) {  [\"root\"]=>  object(obj)(0) {  }}";
ok $y eq "object(stdClass)(1) {  [\"root\"]=>  &object(obj)(0) {  }}";
