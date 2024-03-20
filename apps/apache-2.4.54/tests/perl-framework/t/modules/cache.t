use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;
use Apache::TestConfig ();

plan tests => 3, need 'cache', need_cache_disk, need_min_apache_version('2.1.9');

Apache::TestRequest::module('mod_cache');

t_mkdir(Apache::Test::vars('serverroot') . '/conf/cacheroot/');

my $r = GET("/cache/");
ok t_cmp($r->code, 200, "non-cached call to index.html");

$r = GET("/cache/index.html");
ok t_cmp($r->code, 200, "call to cache index.html");

$r = GET("/cache/");
ok t_cmp($r->code, 200, "cached call to index.html");
