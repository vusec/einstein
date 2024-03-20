use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::TestRequest;
use Apache::Test;

#skip all tests in this directory unless we have client http/1.1 support
plan tests => 1, \&need_http11;

ok 1;
