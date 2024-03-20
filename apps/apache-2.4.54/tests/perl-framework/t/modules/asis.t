use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

## 
## mod_asis tests
##

plan tests => 3, need_module 'asis';

my $body = GET_BODY "/modules/asis/foo.asis";
ok t_cmp($body, "This is asis content.\n", "asis content OK");

my $rc = GET_RC "/modules/asis/notfound.asis";
ok t_cmp($rc, 404, "asis gave 404 error");

$rc = GET_RC "/modules/asis/forbid.asis";
ok t_cmp($rc, 403, "asis gave 403 error");
