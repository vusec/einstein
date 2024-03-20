use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 2, need_php;

my $path = Apache::Test::vars()->{t_logs};
my $file = "$path/func5.php.ran";
unlink $file if -e $file;

my $expected = <<EXPECT;
foo() will be called on shutdown...
EXPECT

my $result = GET_BODY "/php/func5.php?$file";
ok t_cmp($result,
         $expected,
         "GET request for /php/func5.php?$file"
        );

sleep 1;
ok t_cmp(-e $file,
         1,
         "$file exists"
        );

# Clean up
unlink $file if -e $file;


