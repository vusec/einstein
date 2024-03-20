use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

Apache::TestRequest::user_agent(keep_alive => 1);

my $iters = 10;
if (!have_min_apache_version("2.4.0")) { 
  # Not interested in 2.2
  $iters = 0;
}
my $tests = 4 + $iters * 2;

plan tests => $tests, need 
    need_module('ext_filter'), need_cgi;

my $content = GET_BODY("/apache/extfilter/out-foo/foobar.html");
chomp $content;
ok t_cmp($content, "barbar", "sed output filter");

$content = GET_BODY("/apache/extfilter/out-slow/foobar.html");
chomp $content;    
ok t_cmp($content, "foobar", "slow filter process");

my $r = POST "/apache/extfilter/in-foo/modules/cgi/perl_echo.pl", content => "foobar\n";
ok t_cmp($r->code, 200, "echo worked");
ok t_cmp($r->content, "barbar\n", "request body filtered");



# PR 60375 -- appears to be intermittent failure with 2.4.x ... but works with trunk?
foreach (1..$iters) {
    $r = POST "/apache/extfilter/out-limit/modules/cgi/perl_echo.pl", content => "foo and bar\n";
    
    ok t_cmp($r->code, 413, "got 413 error");
    ok t_cmp($r->content, qr/413 Request Entity Too Large/, "got 413 error body");
}
