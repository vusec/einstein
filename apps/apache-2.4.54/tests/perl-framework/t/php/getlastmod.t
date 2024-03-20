use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest qw(GET_BODY);
use Apache::TestUtil;
use File::Spec::Functions qw(catfile);

use POSIX qw(strftime);

plan tests => 1, need_php;

my $vars = Apache::Test::vars();
my $fname = catfile $vars->{documentroot}, "php", "getlastmod.php";
my $mtime = (stat($fname))[9] || die "could not find file";
my $month = strftime "%B", gmtime($mtime);

ok t_cmp(
    GET_BODY("/php/getlastmod.php"),
    $month,
    "getlastmod()"
);
