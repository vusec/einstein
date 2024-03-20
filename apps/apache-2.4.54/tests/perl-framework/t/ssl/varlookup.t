use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;
use Apache::TestSSLCA qw(dn dn_oneline);

unless (have_lwp) {
    # bail out early, since the parser below relies on $LWP::VERSION
    plan tests => 0, need_lwp;
}

use Time::localtime;

my $config = Apache::Test::config();
my $vars   = Apache::Test::vars();
my $server = $config->server;
my $time = localtime();

(my $mmn = $config->{httpd_info}->{MODULE_MAGIC_NUMBER}) =~ s/:\d+$//;

#Apache::TestRequest::scheme('https');
local $vars->{scheme} = 'https';
my $port = $config->port;
my $rfc2253 = have_min_apache_version('2.3.11');

my $url = '/test_ssl_var_lookup';
my(%lookup, @vars);

my %client_dn = dn('client_ok');

my $client_dn = dn_oneline(\%client_dn, $rfc2253);

my %client_i_dn = dn('ca');

my $client_i_dn = dn_oneline(\%client_i_dn, $rfc2253);

my %server_dn = dn('server');

my $dgst = Apache::TestSSLCA::dgst();

my $email_field = Apache::TestSSLCA::email_field();

my $san_email = "$client_dn{$email_field}";

my $san_dns = "$server_dn{CN}";

my $san_msupn  = $san_email;

my $san_dnssrv = "_https.$server_dn{CN}";

if (not have_min_apache_version('2.4.13')) {
    $san_email = $san_dns = "NULL";
}

if (not have_min_apache_version('2.4.17') or
    Apache::Test::normalize_vstring(Apache::TestSSLCA::version()) <
    Apache::Test::normalize_vstring("0.9.8")) {
    $san_msupn = $san_dnssrv = "NULL";
}

# YYY will be turned into a pattern match: httpd-test/([-\w]+)
# so we can test with different server keys/certs
$server_dn{OU} = 'httpd-test/YYY';
$server_dn{CN} = $vars->{servername};

my $server_dn = dn_oneline(\%server_dn, $rfc2253);

$server_dn     =~ s{(httpd-test.*?)YYY}{$1([-\\w]+)};
$server_dn{OU} =~ s{(httpd-test.*?)YYY}{$1([-\\w]+)};

my %server_i_dn = %client_i_dn;
my $server_i_dn = $client_i_dn;

my $cert_datefmt = '^\w{3} {1,2}\d{1,2} \d{2}:\d{2}:\d{2} \d{4} GMT$';

while (<DATA>) {
    chomp;
    s/^\s+//; s/\s+$//;
    s/\#.*//;
    next unless $_;
    my($key, $val) = split /\s+/, $_, 2;
    next unless $key and $val;

    if ($val =~ /^\"/) {
        $val = eval qq($val);
    }
    elsif ($val =~ /^\'([^\']+)\'$/) {
        $val = $1;
    }
    else {
        $val = eval $val;
    }

    die $@ if $@;

    $lookup{$key} = $val;
    push @vars, $key;
}

if (not have_min_apache_version('2.4.32')) {
    @vars = grep(!/_RAW/, @vars);
}

if (not have_min_apache_version('2.5.1')) {
    @vars = grep(!/_B64CERT/, @vars);
}

plan tests => scalar (@vars), need need_lwp, need_module('test_ssl');

for my $key (@vars) {
    sok { verify($key); };
}

sub verify {
    my $key = shift;
    my @headers;
    if ($key eq 'HTTP_REFERER') {
        push @headers, Referer => $0;
    }
    my $str = GET_BODY("$url?$key", cert => 'client_ok',
                       @headers);
    t_cmp($str, $lookup{$key}, "$key");
}

__END__
#http://www.modssl.org/docs/2.8/ssl_reference.html#ToC23
HTTP_USER_AGENT             "libwww-perl/$LWP::VERSION",
HTTP:User-Agent             "libwww-perl/$LWP::VERSION",
HTTP_REFERER                "$0"
HTTP_COOKIE
HTTP_FORWARDED
HTTP_HOST                    Apache::TestRequest::hostport()
HTTP_PROXY_CONNECTION
HTTP_ACCEPT

#standard CGI variables
PATH_INFO
AUTH_TYPE
QUERY_STRING                'QUERY_STRING'
SERVER_SOFTWARE             qr(^$server->{version})
SERVER_ADMIN                $vars->{serveradmin}
SERVER_PORT                 "$port"
SERVER_NAME                 $vars->{servername}
SERVER_PROTOCOL             qr(^HTTP/1\.\d$)
REMOTE_IDENT
REMOTE_ADDR                 $vars->{remote_addr}
REMOTE_HOST
REMOTE_USER
DOCUMENT_ROOT               $vars->{documentroot}
REQUEST_METHOD              'GET'
REQUEST_URI                 $url

#mod_ssl specific variables
TIME_YEAR                    $time->year()+1900
TIME_MON                     sprintf "%02d", $time->mon()+1
TIME_DAY                     sprintf "%02d", $time->mday()
TIME_WDAY                    $time->wday()
TIME
TIME_HOUR
TIME_MIN
TIME_SEC

IS_SUBREQ                    'false'
API_VERSION                  "$mmn"
THE_REQUEST                  qr(^GET $url\?THE_REQUEST HTTP/1\.\d$)
REQUEST_SCHEME               $vars->{scheme}
REQUEST_FILENAME
HTTPS                        'on'
ENV:THE_ARGS                 'ENV:THE_ARGS'

#XXX: should use Net::SSLeay to parse the certs
#rather than just pattern match and hardcode

SSL_CLIENT_M_VERSION         qr(^\d+$)
SSL_SERVER_M_VERSION         qr(^\d+$)
SSL_CLIENT_M_SERIAL          qr(^[0-9A-F]+$)
SSL_SERVER_M_SERIAL          qr(^[0-9A-F]+$)
SSL_PROTOCOL                 qr((TLS|SSL)v([1-3]|1\.[0-3])$)
SSL_CLIENT_V_START           qr($cert_datefmt);
SSL_SERVER_V_START           qr($cert_datefmt);
SSL_SESSION_ID
SSL_CLIENT_V_END             qr($cert_datefmt);
SSL_SERVER_V_END             qr($cert_datefmt);
SSL_CIPHER                   qr(^[A-Z0-9_-]+$)
SSL_CIPHER_EXPORT            'false'
SSL_CIPHER_ALGKEYSIZE        qr(^\d+$)
SSL_CIPHER_USEKEYSIZE        qr(^\d+$)
SSL_SECURE_RENEG             qr(^(false|true)$)

SSL_CLIENT_S_DN              "$client_dn"
SSL_SERVER_S_DN              qr(^$server_dn$)
SSL_CLIENT_S_DN_C            "$client_dn{C}"
SSL_SERVER_S_DN_C            "$server_dn{C}"
SSL_CLIENT_S_DN_ST           "$client_dn{ST}"
SSL_SERVER_S_DN_ST           "$server_dn{ST}"
SSL_CLIENT_S_DN_L            "$client_dn{L}"
SSL_SERVER_S_DN_L            "$server_dn{L}"
SSL_CLIENT_S_DN_O            "$client_dn{O}"
SSL_SERVER_S_DN_O            "$server_dn{O}"
SSL_CLIENT_S_DN_OU           "$client_dn{OU}"
SSL_SERVER_S_DN_OU           qr(^$server_dn{OU})
SSL_CLIENT_S_DN_CN           "$client_dn{CN}"
SSL_SERVER_S_DN_CN           "$server_dn{CN}"
SSL_CLIENT_S_DN_T
SSL_SERVER_S_DN_T
SSL_CLIENT_S_DN_I
SSL_SERVER_S_DN_I
SSL_CLIENT_S_DN_G
SSL_SERVER_S_DN_G
SSL_CLIENT_S_DN_S
SSL_SERVER_S_DN_S
SSL_CLIENT_S_DN_D
SSL_SERVER_S_DN_D
SSL_CLIENT_S_DN_UID
SSL_SERVER_S_DN_UID
SSL_CLIENT_S_DN_Email        "$client_dn{$email_field}"
SSL_SERVER_S_DN_Email        "$server_dn{$email_field}"
SSL_CLIENT_SAN_Email_0       "$san_email"
SSL_SERVER_SAN_DNS_0         "$san_dns"
SSL_CLIENT_SAN_OTHER_msUPN_0 "$san_msupn"
SSL_SERVER_SAN_OTHER_dnsSRV_0 "$san_dnssrv"

SSL_CLIENT_I_DN              "$client_i_dn"
SSL_SERVER_I_DN              "$server_i_dn"
SSL_CLIENT_I_DN_C            "$client_i_dn{C}"
SSL_SERVER_I_DN_C            "$server_i_dn{C}"
SSL_CLIENT_I_DN_ST           "$client_i_dn{ST}"
SSL_SERVER_I_DN_ST           "$server_i_dn{ST}"
SSL_CLIENT_I_DN_L            "$client_i_dn{L}"
SSL_SERVER_I_DN_L            "$server_i_dn{L}"
SSL_CLIENT_I_DN_O            "$client_i_dn{O}"
SSL_SERVER_I_DN_O            "$server_i_dn{O}"
SSL_CLIENT_I_DN_OU           "$client_i_dn{OU}"
SSL_SERVER_I_DN_OU           "$server_i_dn{OU}"
SSL_CLIENT_I_DN_CN           "$client_i_dn{CN}"
SSL_SERVER_I_DN_CN           "$server_i_dn{CN}"
SSL_SERVER_I_DN_CN_RAW       "$server_i_dn{CN}"
SSL_SERVER_I_DN_CN_0_RAW     "$server_i_dn{CN}"
SSL_CLIENT_I_DN_T
SSL_SERVER_I_DN_T
SSL_CLIENT_I_DN_I
SSL_SERVER_I_DN_I
SSL_CLIENT_I_DN_G
SSL_SERVER_I_DN_G
SSL_CLIENT_I_DN_S
SSL_SERVER_I_DN_S
SSL_CLIENT_I_DN_D
SSL_SERVER_I_DN_D
SSL_CLIENT_I_DN_UID
SSL_SERVER_I_DN_UID
SSL_CLIENT_I_DN_Email        "$client_i_dn{$email_field}"
SSL_SERVER_I_DN_Email        "$server_i_dn{$email_field}"
SSL_CLIENT_A_SIG             "${dgst}WithRSAEncryption"
SSL_SERVER_A_SIG             "${dgst}WithRSAEncryption"
SSL_CLIENT_A_KEY             'rsaEncryption'
SSL_SERVER_A_KEY             qr(^[rd]saEncryption$)
SSL_CLIENT_CERT              qr(^-----BEGIN CERTIFICATE-----)
SSL_SERVER_CERT              qr(^-----BEGIN CERTIFICATE-----)
SSL_CLIENT_B64CERT           qr(^[a-zA-Z0-9+/]{64,}={0,2}$)
SSL_SERVER_B64CERT           qr(^[a-zA-Z0-9+/]{64,}={0,2}$)
SSL_CLIENT_VERIFY            'SUCCESS'
SSL_VERSION_LIBRARY
SSL_VERSION_INTERFACE

