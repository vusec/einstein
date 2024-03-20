use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 4, need_php;

my $expect = "status=200:method=GET:uri=/php/target.php";

my $r = GET_BODY "/php/lookup.php";

chomp $r;

ok t_cmp($r, $expect, "apache_lookup_uri results OK");

# regression test for http://bugs.php.net/bug.php?id=31645
$r = GET("/php/lookup2.php");

ok t_cmp($r->header("X-Before"), "foobar", "header set before apache_lookup_uri");
ok t_cmp($r->header("X-After"), "foobar", "header set after apache_lookup_uri");

my $c = $r->content;

chomp $c;

ok t_cmp($c, $expect, "second apache_lookup_uri results");

