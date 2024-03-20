use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 1, need_php;

my $result = GET_BODY "/php/globals.php";
ok $result eq "1 5 2 2 10 5  2 5 3 2 10 5  3 5 4 2 \n";
