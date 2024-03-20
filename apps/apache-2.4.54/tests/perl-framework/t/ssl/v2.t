use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
BEGIN {
    $ENV{HTTPS_VERSION} = 2; #use SSLv2 instead of SSLv3
}

use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 1, need need_lwp,
                      { "SSLv2 test(s) not applicable" =>
                        sub { !need_min_apache_version('2.4.0') } };

Apache::TestRequest::scheme('https');

#just make sure the basics work for SSLv2
ok GET_OK('/');

#per-dir renegotiation does not work with SSLv2,
#same breakage with apache-1.3.22+mod_ssl-2.8.5
my $url = '/require/asf/index.html';

#ok GET_RC($url, cert => undef) != 200;

#ok GET_RC($url, cert => 'client_ok') == 200;

#ok GET_RC($url, cert => 'client_revoked') != 200;
