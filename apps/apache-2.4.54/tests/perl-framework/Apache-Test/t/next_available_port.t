# this test tests how a cookie jar can be passed (needs lwp)

use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 1, need need_cgi,
                 need_module('mod_env.c');

my $url = '/cgi-bin/next_available_port.pl';

my $port = GET_BODY($url) || '';
ok $port, qr/^\d+$/, "next available port number";
