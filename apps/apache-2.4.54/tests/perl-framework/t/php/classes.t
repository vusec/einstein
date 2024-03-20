use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 1, need_php;

my $expected = <<EXPECT;
User information
----------------

First name:    Zeev
Family name:    Suraski
Address:    Ben Gourion 3, Kiryat Bialik, Israel
Phone:    	+972-4-8713139


User information
----------------

First name:    Andi
Family name:    Gutmans
Address:    Haifa, Israel
Phone:    	+972-4-8231621


User information
----------------

First name:    Andi
Family name:    Gutmans
Address:    Haifa, Israel
Phone:    	+972-4-8231621


User information
----------------

First name:    Andi
Family name:    Gutmans
Address:    New address...
Phone:    	+972-4-8231621


EXPECT

my $result = GET_BODY "/php/classes.php";

## get rid of whitespace so that does not cause failure in the comparison.
$expected =~ s/\s//g;
$result =~ s/\s//g;

ok $result eq $expected
