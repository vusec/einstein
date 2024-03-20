use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 1, need_module 'test_apr_uri';

my $body = GET_BODY '/test_apr_uri';

ok $body =~ /TOTAL\s+FAILURES\s*=\s*0/;
