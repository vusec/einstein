use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

my @codes = (404, 599);

plan tests => @codes + 0, need_php;

foreach my $code (@codes) {
    ok t_cmp(GET_RC("/php/status.php?code=$code"), $code,
             "regression test for http://bugs.php.net/bug.php?id=31519");
}
