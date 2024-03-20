use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestCommon ();

local $ENV{APACHE_TEST_HTTP11} = 1;

#same as t/apache/post but turn on HTTP/1.1
Apache::TestRequest::user_agent(keep_alive => 1);

my $module = 'eat_post';
my $num = Apache::TestCommon::run_post_test_sizes();

plan tests => $num, [$module];

Apache::TestCommon::run_post_test($module);
