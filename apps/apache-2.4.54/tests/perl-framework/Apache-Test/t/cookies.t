# this test tests how a cookie jar can be passed (needs lwp)

use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 2, need [qw(CGI CGI::Cookie)],
                      need_cgi, need_lwp, need need_module('mod_alias.c');

Apache::TestRequest::user_agent( cookie_jar => {} );

my $url = '/cgi-bin/cookies.pl';

ok t_cmp GET_BODY($url), 'new', "new cookie";
ok t_cmp GET_BODY($url), 'exists', "existing cookie";
