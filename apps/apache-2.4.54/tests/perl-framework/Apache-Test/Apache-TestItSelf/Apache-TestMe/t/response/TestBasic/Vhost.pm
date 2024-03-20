package TestBasic::Vhost;

use Apache2::Const -compile => qw(OK);
use Apache::Test;

# XXX: adjust the test that it'll work under mp1 as well

sub handler {

  my $r = shift;

  plan $r, tests => 1;

  ok 1;

  return Apache2::OK;
}

1;
__END__
<NoAutoConfig>
<VirtualHost TestBasic::Vhost>
    <Location /TestBasic__Vhost>
        SetHandler modperl
        PerlResponseHandler TestBasic::Vhost
    </Location>
</VirtualHost>
</NoAutoConfig>
