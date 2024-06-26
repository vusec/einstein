use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 1, need_php4;

my $expected = <<EXPECT;
Before function declaration...
After function declaration...
Calling function for the first time...
----
In function, printing the string "This works!" 10 times
0) This works!
1) This works!
2) This works!
3) This works!
4) This works!
5) This works!
6) This works!
7) This works!
8) This works!
9) This works!
Done with function...
-----
Returned from function call...
Calling the function for the second time...
----
In function, printing the string "This like, really works and stuff..." 3 times
0) This like, really works and stuff...
1) This like, really works and stuff...
2) This like, really works and stuff...
Done with function...
-----
Returned from function call...
This is some other function, to ensure more than just one function works fine...

EXPECT

my $result = GET_BODY "/php/func4.php";
ok $result eq $expected;
