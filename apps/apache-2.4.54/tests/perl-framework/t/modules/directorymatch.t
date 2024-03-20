use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;
use Apache::TestConfig ();

## 
## directorymatch tests
##

my @ts = (
    { url => "/index.html", code => 200, hname => "DMMATCH1"},
    # TODO: PR41867 (DirectoryMatch matches files)
);

plan tests => 2* scalar @ts, have_module 'headers';

for my $t (@ts) {
  my $r = GET $t->{'url'};
  ok t_cmp($r->code, $t->{code}, "code for " . $t->{'url'});
  ok t_cmp($r->header($t->{'hname'}), "1", "check for " . $t->{'hname'});
}


