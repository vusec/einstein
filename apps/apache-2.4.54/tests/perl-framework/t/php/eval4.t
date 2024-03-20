use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

## testing eval function

plan tests => 1, need_php;

my $expected = <<EXPECT;
hey, this is a regular echo'd eval()
hey, this is a function inside an eval()!
hey, this is a regular echo'd eval()
hey, this is a function inside an eval()!
hey, this is a regular echo'd eval()
hey, this is a function inside an eval()!
hey, this is a regular echo'd eval()
hey, this is a function inside an eval()!
hey, this is a regular echo'd eval()
hey, this is a function inside an eval()!
hey, this is a regular echo'd eval()
hey, this is a function inside an eval()!
hey, this is a regular echo'd eval()
hey, this is a function inside an eval()!
hey, this is a regular echo'd eval()
hey, this is a function inside an eval()!
hey, this is a regular echo'd eval()
hey, this is a function inside an eval()!
hey, this is a regular echo'd eval()
hey, this is a function inside an eval()!
EXPECT

my $result = GET_BODY "/php/eval4.php";
ok $result eq $expected;
