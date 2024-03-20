use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

#test basic auth with keepalives

Apache::TestRequest::user_agent(keep_alive => 1);

Apache::TestRequest::scheme('http')
  unless have_module 'LWP::Protocol::https10'; #lwp 5.60

plan tests => 3, need_module 'authany';

my $url = '/authany/index.html';

my $res = GET $url;

ok $res->code == 401;

$res = GET $url, username => 'guest', password => 'guest';

ok $res->code == 200;

my $request_num = Apache::TestRequest::user_agent_request_num($res);

ok $request_num == 3; #1 => no credentials
                      #2 => 401 response with second request
                      #3 => 200 with guest/guest credentials


