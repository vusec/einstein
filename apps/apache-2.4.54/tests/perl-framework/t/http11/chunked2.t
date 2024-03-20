use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

plan tests => 2, need 'bucketeer';

Apache::TestRequest::user_agent(keep_alive => 1);

# Regression test for ap_http_chunk_filter bug.

my $r = GET("/apache/chunked/flush.html");

ok t_cmp($r->code, 200, "successful response");

ok t_cmp($r->content, "aaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbb");
