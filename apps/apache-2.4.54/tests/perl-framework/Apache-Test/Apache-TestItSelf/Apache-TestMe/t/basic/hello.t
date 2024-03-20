use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 3, have_lwp;

my $response = GET '/TestBasic__Hello';

ok t_cmp $response->code, 200, '/handler returned HTTP_OK';

ok t_cmp $response->header('Content-Type'), 'text/plain',
    '/handler set proper Content-Type';

chomp(my $content = $response->content);

ok t_cmp $content, 'Hello', '/handler returned proper content';

