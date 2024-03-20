use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
#
# Regression test for PR 37166
#
# r370692 determined that a CGI script which outputs an explicit
# "Status: 200" will not be subject to conditional request processing.
# Previous behaviour was the opposite, but fell foul of the r->status
# vs r->status_line issue fixed in r385581.
#
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 4, \&need_cgi;

my $uri = '/modules/cgi/pr37166.pl';

my $r = GET $uri;

ok t_cmp($r->code, 200, "SSI was allowed for location");
ok t_cmp($r->content, "Hello world\n", "file was served with correct content");

$r = GET $uri, "If-Modified-Since" => "Tue, 15 Feb 2005 15:00:00 GMT";

ok t_cmp($r->code, 200, "explicit 200 response");
ok t_cmp($r->content, "Hello world\n", 
         "file was again served with correct content");
