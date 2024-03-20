package TestMore::testmorepm;

use strict;
use warnings FATAL => qw(all);

use Test::More;
use Apache::Test qw(-withtestmore);

sub handler {

  plan shift, tests => 2;

  is (1, 1, 'called Test::More::is()');

  like ('wow', qr/wow/, 'called Test::More::like()');

  0;

}

1;
