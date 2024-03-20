package TestBasic::Hello;

use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK);

# XXX: adjust the test that it'll work under mp1 as well

sub handler {

  my $r = shift;

  $r->content_type('text/plain');
  $r->print('Hello');

  return Apache2::OK;
}

1;
