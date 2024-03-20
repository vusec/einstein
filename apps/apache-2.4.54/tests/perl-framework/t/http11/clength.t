use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my %tests = (
    "/foobar.html" => "foobar",
    # flushheap0 inserts a single FLUSH bucket after the content, before EOS
    "/apache/chunked/flushheap0.html" => "bbbbbbbbbb",
    );

plan tests => 3*scalar keys %tests, need 'bucketeer';

Apache::TestRequest::user_agent(keep_alive => 1);

foreach my $path (sort keys %tests) {
    my $expected = $tests{$path};
    my $r = GET($path);

    ok t_cmp($r->code, 200, "successful response");

    ok t_cmp($r->header("Content-Length"), length $expected);
    
    ok t_cmp($r->content, $expected);
}
