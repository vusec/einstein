use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

## 
## mod_action tests
##
my @tests_action = (
    [ "mod_actions/",				200, 	"nada"],	# Handler for this location

    [ "modules/actions/action/test.xyz",	404],			# No handler for .xyz
    [ "modules/actions/action/test.xyz1",	404],			# Handler for .xyz1, but not virtual
    [ "modules/actions/action/test.xyz22",	404],			# No Handler for .xyz2x (but one for .xyz2)

    [ "modules/actions/action/test.xyz2",	200, 	"nada"],	# Handler for .xyz2, and virtual
);

my @tests_script = (
    [ "modules/actions/script/test.x",		404],
    [ "modules/actions/script/test.x?foo=bar",	200,	"foo=bar"],
);

my $r;

plan tests => scalar @tests_action*2 + scalar @tests_script*(2+2+1), need_module('mod_actions');

foreach my $test (@tests_action) {
	$r = GET($test->[0]);
	ok t_cmp($r->code, $test->[1]);
	if ($test->[1] == 200) {
		ok t_cmp($r->content, $test->[2]);
	}
	else {
		skip "RC=404, no need to check content", 1;
	}
}

foreach my $test (@tests_script) {
	$r = GET($test->[0]);
	ok t_cmp($r->code, $test->[1]);
	if ($test->[1] == 200) {
		ok t_cmp($r->content, $test->[2]);
	}
	else {
		skip "RC=404, no need to check content", 1;
	}

	$r = POST($test->[0], content => "foo2=bar2");
	ok t_cmp($r->code, 200);
	ok t_cmp($r->content, "POST\nfoo2: bar2\n");

	# Method not allowed
	$r = PUT($test->[0], content => "foo2=bar2");
	ok t_cmp($r->code, 405);
}

