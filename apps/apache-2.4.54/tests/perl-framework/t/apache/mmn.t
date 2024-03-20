use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;

#
# check that the comment and the #define in ap_mmn.h are equal 
#

plan tests => 2, need_apache 2;

my $config = Apache::TestConfig->thaw();
my $filename = $config->apxs('INCLUDEDIR') . '/ap_mmn.h';

my $cmajor;
my $cminor;
my $major;
my $minor;
my $skip;
if (open(my $fh, "<", $filename)) {
    while (defined (my $line = <$fh>)) {
        if ($line =~ m/^\s+[*]\s+(\d{8})[.](\d+)\s+\([\d.]+(?:-dev)?\)\s/ ) {
            $cmajor = $1;
            $cminor = $2;
        }
        elsif ($line =~ m{^#define\s+MODULE_MAGIC_NUMBER_MAJOR\s+(\d+)(?:\s|$)}) 
        {
            $major = $1;
        }
        elsif ($line =~ m{^#define\s+MODULE_MAGIC_NUMBER_MINOR\s+(\d+)(?:\s|$)}) 
        {
            $minor = $1;
        }
    }
    close($fh);
}
else {
    $skip = "Skip if can't read $filename";
}

skip($skip, $major, $cmajor);
skip($skip, $minor, $cminor);
