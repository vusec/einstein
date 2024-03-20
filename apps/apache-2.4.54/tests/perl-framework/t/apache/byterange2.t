use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

plan tests => 1, need need_min_apache_version('2.0.51'), need_cgi;

my $resp;

$resp = GET_BODY "/modules/cgi/ranged.pl",
    Range => 'bytes=5-10/10';

ok t_cmp($resp, "hello\n", "return correct content");
