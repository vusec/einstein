use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my @testcases = (
    ['/apache/buffer_in/', 'foo'],
    ['/apache/buffer_out/', 'foo'],
    ['/apache/buffer_in_out/', 'foo'],
);

plan tests => scalar @testcases * 4, need 'mod_reflector', 'mod_buffer';

foreach my $t (@testcases) {
    ## Small query ##
    my $r = POST($t->[0], content => $t->[1]);

    # Checking for return code
    ok t_cmp($r->code, 200, "Checking return code is '200'");
    # Checking for content
    ok t_is_equal($r->content, $t->[1]);
    
    ## Big query ##
    # 'foo' is 3 bytes, so 'foo' x 1000000 is ~3M, which is way over the default 'BufferSize'
    ### FIXME - testing with to x 10000 is confusing LWP's full-duplex
    ### handling: https://github.com/libwww-perl/libwww-perl/issues/299
    ### throttled down to a size which seems to work reliably for now
    my $bigsize = 100000;

    $r = POST($t->[0], content => $t->[1] x $bigsize);

    # Checking for return code
    ok t_cmp($r->code, 200, "Checking return code is '200'");
    # Checking for content
    ok t_is_equal($r->content, $t->[1] x $bigsize);
}
