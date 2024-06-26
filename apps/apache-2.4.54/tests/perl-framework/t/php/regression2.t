use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 1, need_php;

my $expected = <<EXPECT;
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
<html>
<head>
*** Testing assignments and variable aliasing: ***
This should read "blah": blah
This should read "this is nifty": this is nifty
*************************************************

*** Testing integer operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing real operators ***
Correct result - 8:  8
Correct result - 8:  8
Correct result - 2:  2
Correct result - -2:  -2
Correct result - 15:  15
Correct result - 15:  15
Correct result - 2:  2
Correct result - 3:  3
*********************************

*** Testing if/elseif/else control ***

This  works
this_still_works
should_print


*** Seriously nested if's test ***
** spelling correction by kluzz **
Only two lines of text should follow:
this should be displayed. should be:  \$i=1, \$j=0.  is:  \$i=1, \$j=0
this is supposed to be displayed. should be:  \$i=2, \$j=4.  is:  \$i=2, \$j=4
3 loop iterations should follow:
2 4
3 4
4 4
**********************************

*** C-style else-if's ***
This should be displayed
*************************

*** WHILE tests ***
0 is smaller than 20
1 is smaller than 20
2 is smaller than 20
3 is smaller than 20
4 is smaller than 20
5 is smaller than 20
6 is smaller than 20
7 is smaller than 20
8 is smaller than 20
9 is smaller than 20
10 is smaller than 20
11 is smaller than 20
12 is smaller than 20
13 is smaller than 20
14 is smaller than 20
15 is smaller than 20
16 is smaller than 20
17 is smaller than 20
18 is smaller than 20
19 is smaller than 20
20 equals 20
21 is greater than 20
22 is greater than 20
23 is greater than 20
24 is greater than 20
25 is greater than 20
26 is greater than 20
27 is greater than 20
28 is greater than 20
29 is greater than 20
30 is greater than 20
31 is greater than 20
32 is greater than 20
33 is greater than 20
34 is greater than 20
35 is greater than 20
36 is greater than 20
37 is greater than 20
38 is greater than 20
39 is greater than 20
*******************


*** Nested WHILEs ***
Each array variable should be equal to the sum of its indices:
\${test00}[0] = 0
\${test00}[1] = 1
\${test00}[2] = 2
\${test01}[0] = 1
\${test01}[1] = 2
\${test01}[2] = 3
\${test02}[0] = 2
\${test02}[1] = 3
\${test02}[2] = 4
\${test10}[0] = 1
\${test10}[1] = 2
\${test10}[2] = 3
\${test11}[0] = 2
\${test11}[1] = 3
\${test11}[2] = 4
\${test12}[0] = 3
\${test12}[1] = 4
\${test12}[2] = 5
\${test20}[0] = 2
\${test20}[1] = 3
\${test20}[2] = 4
\${test21}[0] = 3
\${test21}[1] = 4
\${test21}[2] = 5
\${test22}[0] = 4
\${test22}[1] = 5
\${test22}[2] = 6
*********************

*** hash test... ***
commented out...
**************************

*** Hash resizing test ***
ba
baa
baaa
baaaa
baaaaa
baaaaaa
baaaaaaa
baaaaaaaa
baaaaaaaaa
baaaaaaaaaa
ba
10
baa
9
baaa
8
baaaa
7
baaaaa
6
baaaaaa
5
baaaaaaa
4
baaaaaaaa
3
baaaaaaaaa
2
baaaaaaaaaa
1
**************************


*** break/continue test ***
\$i should go from 0 to 2
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=0
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=1
\$j should go from 3 to 4, and \$q should go from 3 to 4
  \$j=3
    \$q=3
    \$q=4
  \$j=4
    \$q=3
    \$q=4
\$j should go from 0 to 2
  \$j=0
  \$j=1
  \$j=2
\$k should go from 0 to 2
    \$k=0
    \$k=1
    \$k=2
\$i=2
***********************

*** Nested file include test ***
<html>
This is Finish.phtml.  This file is supposed to be included
from regression_test.phtml.  This is normal HTML.
and this is PHP code, 2+2=4
</html>
********************************

Tests completed.
EXPECT

my $result = GET_BODY "/php/regression2.php";

ok $result eq $expected;
