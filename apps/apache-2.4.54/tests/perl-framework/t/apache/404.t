use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 2;

my $four_oh_four = GET_STR "/404/not/found/test";

print "# GET_STR Response:\n# ",
      join("\n# ", split(/\n/, $four_oh_four)), "\n";

ok (($four_oh_four =~ /HTTP\/1\.[01] 404 Not Found/)
    || ($four_oh_four =~ /RC:\s+404.*Message:\s+Not Found/s));
ok ($four_oh_four =~ /Content-Type: text\/html/);
