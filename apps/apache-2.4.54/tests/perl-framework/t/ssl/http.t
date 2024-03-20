use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';
use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

BEGIN {
   # prevent TestRequest from croaking on an HTTP/0.9 response
   $ENV{APACHE_TEST_HTTP_09_OK} = 1;
}

#verify we can send an non-ssl http request to the ssl port
#without dumping core.

my $url = '/index.html';

my @todo;

if (Apache::TestConfig::WIN32) {
    print "\n#ap_core_translate() chokes on ':' here\n",
          "#where r->uri = /mod_ssl:error:HTTP-request\n";
    @todo = (todo => [2]);
}

plan tests => 2, @todo, need_lwp;

my $config = Apache::Test::config();
my $ssl_module = $config->{vars}->{ssl_module_name};
my $hostport = $config->{vhosts}->{$ssl_module}->{hostport};
my $rurl = "http://$hostport$url";

my $res = GET($rurl);
my $proto = $res->protocol;

if ($proto and $proto eq "HTTP/0.9") {
    skip "server gave HTTP/0.9 response";
} else {    
    ok t_cmp($res->code,
             400,
             "Expected bad request from 'GET $rurl'"
            );
}

ok t_cmp($res->content,
         qr{speaking plain HTTP to an SSL-enabled server port},
         "that error document contains the proper hint"
        );

