use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

##
## mod_status quick test
##

plan tests => 1, need_module 'status';

my $uri = '/server-status';
my $servername = Apache::Test::vars()->{servername};

my $title = "Apache Server Status for $servername";

my $status = GET_BODY $uri;
print "$status\n";
ok ($status =~ /$title/i);
