use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

## test that umask() is reset after script execution

plan tests => 4, need_php4;

my $first = GET_BODY "/php/umask.php";

foreach my $n (1..4) {
    my $try = GET_BODY "/php/umask.php";

    ok t_cmp($try, $first, "umask was $try not $first for request $n");
}

