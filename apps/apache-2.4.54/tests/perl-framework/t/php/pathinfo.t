use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 5, sub { need_php() && need_min_apache_version('2.0.0'); };

my $r;

$r = GET("/apache/acceptpathinfo/on/info.php/fish/food");
ok t_cmp($r->code, 200, "PATH_INFO accepted by default");
ok t_cmp($r->content, "_/fish/food_", "PATH_INFO parsed OK");

$r = GET("/apache/acceptpathinfo/off/info.php/fish/food");
ok t_cmp($r->code, 404, "PATH_INFO rejected if disabled");

$r = GET("/apache/acceptpathinfo/on/info.php/fish/food");
ok t_cmp($r->code, 200, "PATH_INFO accepted if enabled");
ok t_cmp($r->content, "_/fish/food_", "PATH_INFO parsed OK");

