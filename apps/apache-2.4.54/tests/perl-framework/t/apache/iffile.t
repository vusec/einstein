use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

# Available since 2.4.34, but quoted paths in <IfFile> fixed in 2.4.35
plan tests => 2,
     need(
         need_module('mod_headers'),
         need_min_apache_version('2.4.35')
     );

my $resp = GET('/apache/iffile/document');
ok t_cmp($resp->code, 200);
ok t_cmp($resp->header('X-Out'), "success1, success2, success3, success4, success5");
