# see the description in t/more/all.t

use strict;
use warnings FATAL => qw(all);

use Apache::TestRequest 'GET_BODY_ASSERT';
print GET_BODY_ASSERT "/TestMore__testpm";

