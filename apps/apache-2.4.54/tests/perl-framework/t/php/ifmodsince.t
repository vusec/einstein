use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw(GET_RC);

use POSIX qw(strftime);

plan tests => 1, need_php;

# Test for bug where Apache serves a 304 if the PHP file (on disk) has
# not been modified since the date given in an If-Modified-Since
# header; http://bugs.php.net/bug.php?id=17098

ok t_cmp(
    GET_RC("/php/hello.php",
        "If-Modified-Since" => strftime("%a, %d %b %Y %T GMT", gmtime)),
    200,
    "not 304 if the php file has not been modified since If-Modified-Since"
);

