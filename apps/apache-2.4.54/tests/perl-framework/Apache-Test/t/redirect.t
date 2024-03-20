use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 6, need need_module('mod_alias.c'), need_lwp;

my $url = '/redirect';

# Allow request to be redirected.
ok my $res = GET $url;
ok ! $res->is_redirect;

# Don't let request be redirected.
ok $res = GET($url, redirect_ok => 0);
ok $res->is_redirect;

# Allow no more requests to be redirected.
Apache::TestRequest::user_agent(reset => 1,
                                requests_redirectable => 0);
ok $res = GET $url;
ok $res->is_redirect;
