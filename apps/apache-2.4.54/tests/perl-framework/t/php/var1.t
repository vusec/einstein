use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 2, need_php;

## var1.php source:
## <?php echo $variable?>
##
## result should be variable echoed back.

my $page = '/php/var1.php';
my $data = "blah1+blah2+FOO";
#my @data = (variable => $data);
my $expected = $data;
$expected =~ s/\+/ /g;

## POST
#my $return = POST_BODY $page, \@data;
#print STDERR "\n\n$return\n\n";
#ok $return eq $expected;
my $return = POST_BODY $page, content => "variable=$data";
ok t_cmp($return,
         $expected,
         "POST request for $page, content=\"variable=$data\""
        );

## GET
$return = GET_BODY "$page?variable=$data";
ok t_cmp($return,
         $expected,
         "GET request for $page?variable=$data"
        );
