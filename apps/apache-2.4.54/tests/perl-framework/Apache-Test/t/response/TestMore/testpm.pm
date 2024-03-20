package TestMore::testpm;

use strict;
use warnings FATAL => qw(all);

use Apache::Test;
use Apache::TestUtil;

sub handler {

  plan shift, tests => 1;

  ok t_cmp(1, 1, 'called Apache::Test::ok()');

  0;
}

1;
