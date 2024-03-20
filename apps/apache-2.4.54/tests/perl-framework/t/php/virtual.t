use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 1, sub { need_php() && need_module('negotiation') };

my $result = GET_BODY "/php/virtual.php";
chomp $result;
ok t_cmp($result, "before file.html after",
         "regression test for http://bugs.php.net/bug.php?id=30446");
