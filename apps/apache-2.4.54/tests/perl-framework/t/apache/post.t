use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestCommon ();

my $module = 'eat_post';
my $num = Apache::TestCommon::run_post_test_sizes();

plan tests => $num, need need_lwp, need_module($module);

Apache::TestCommon::run_post_test($module);
