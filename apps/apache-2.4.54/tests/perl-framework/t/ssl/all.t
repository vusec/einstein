use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
my $vars = Apache::Test::vars();

#skip all tests in this directory unless ssl is enabled
#and LWP has https support
plan tests => 1, [$vars->{ssl_module_name}, qw(LWP::Protocol::https)];

ok 1;

