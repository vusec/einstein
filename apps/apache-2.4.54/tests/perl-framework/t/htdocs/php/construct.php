<?php
class obj {
	function method() {}
    }

function test($o_copy) {
	$o_copy->root->set_in_copied_o=TRUE;
 	var_dump($o_copy);?><BR><?php }

$o->root=new obj();

ob_start();
var_dump($o);
$x=ob_get_contents();
ob_end_clean();

$o->root->method();

ob_start();
var_dump($o);
$y=ob_get_contents();
ob_end_clean();

// $o->root->method() makes ob_get_contents() have a '&' in front of object
// so this does not work.
// echo ($x==$y) ? 'success':'failure';

echo "x = $x";
echo "y = $y";
?>
