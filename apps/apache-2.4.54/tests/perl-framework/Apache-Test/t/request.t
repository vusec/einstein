use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 9, \&need_lwp;

my $url = '/index.html';

ok GET_OK   $url;
ok GET_RC   $url;
ok GET_STR  $url;
ok GET_BODY $url;

ok HEAD_OK  $url;
ok HEAD_RC  $url;
ok HEAD_STR $url;

ok GET_OK   $url, username => 'dougm', password => 'XXXX'; #e.g. for auth

ok GET_OK   $url, Referer => $0;   #add headers

#post a string
#ok POST_OK  $url, content => 'post body data';

#or key/value pairs (see HTTP::Request::Common
#ok POST_OK  $url, [university => 'arizona', team => 'wildcats']
