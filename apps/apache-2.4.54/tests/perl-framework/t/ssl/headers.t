use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

my $tests = 3;

plan tests => $tests, need need_lwp, need_module('headers', 'ssl');

Apache::TestRequest::scheme('https');

my $h = HEAD_STR "/modules/headers/ssl/";

# look for 500 when mod_headers doesn't grok the %s tag
if ($h =~ /^HTTP\/1.1 500 Internal Server Error\n/) {   
    foreach (1..$tests) {
        skip "Skipping because mod_headers doesn't grok %s\n";
    }
    exit 0;
}

$h =~ s/Client-Bad-Header-Line:.*$//g;

ok t_cmp($h, qr/X-SSL-Flag: on/, "SSLFlag header set");
ok t_cmp($h, qr/X-SSL-Cert:.*END CERTIFICATE-----/, "SSL certificate is unwrapped");
ok t_cmp($h, qr/X-SSL-None: \(null\)\n/, "unknown SSL variable not given");
