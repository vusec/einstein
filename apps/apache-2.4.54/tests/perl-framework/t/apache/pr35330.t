use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
#
# Regression test for PR 35330
#
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 2, need 'include';

my $r = GET '/apache/htaccess/override/hello.shtml';

ok t_cmp($r->code, 200, "SSI was allowed for location");
ok t_cmp($r->content, "hello", "file was served with correct content");
