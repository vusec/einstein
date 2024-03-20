use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

## 
## mod_unique_id tests
##

my $iters = 100;
my $url = "/modules/cgi/unique-id.pl";
my %idx = ();

plan tests => 3 * $iters, need need_cgi, need_module('unique_id');

foreach (1..$iters) {
    my $r = GET $url;
    ok t_cmp($r->code, 200, "fetch unique ID");
    my $v = $r->content;
    print "# unique id: $v\n";
    chomp $v;
    ok length($v) >= 20;
    ok !exists($idx{$v});
    $idx{$v} = 1;
}
