use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my @urls = qw(/);

plan tests => @urls * 2, \&need_lwp;

for my $url (@urls) {
    my $res = OPTIONS $url;
    ok t_cmp $res->code, 200, "code";
    my $allow = $res->header('Allow') || '';
    ok t_cmp $allow, qr/OPTIONS/, "OPTIONS";
}
