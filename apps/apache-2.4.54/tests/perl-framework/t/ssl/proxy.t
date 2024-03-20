use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;
use Apache::TestCommon ();

my %frontend = (
    proxy_http_https                => 'http',
    proxy_https_https               => 'https',
    proxy_https_http                => 'https',
    proxy_http_https_proxy_section  => 'http',
    proxy_https_https_proxy_section => 'https',
);
my %backend = (
    proxy_http_https                => 'https',
    proxy_https_https               => 'https',
    proxy_https_http                => 'http',
    proxy_http_https_proxy_section  => 'https',
    proxy_https_https_proxy_section => 'https',
);

my $num_modules = scalar keys %frontend;
my $post_module = 'eat_post';

my $post_tests = have_module($post_module) ?
  Apache::TestCommon::run_post_test_sizes() : 0;

my $num_http_backends = 0;
for my $module (sort keys %backend) {
    if ($backend{$module} eq "http") {
        $num_http_backends++;
    }
}

plan tests => (8 + $post_tests) * $num_modules - 5 * $num_http_backends,
              need need_lwp, [qw(mod_proxy proxy_http.c)];

for my $module (sort keys %frontend) {

    my $scheme = $frontend{$module};
    Apache::TestRequest::module($module);
    Apache::TestRequest::scheme($scheme);

    my $hostport = Apache::TestRequest::hostport();
    my $res;
    my %vars;

    sok {
        t_cmp(GET('/')->code,
              200,
              "/ with $module ($scheme)");
    };

    sok {
        t_cmp(GET('/modules/cgi/nph-foldhdr.pl')->code,
              200,
              "CGI script with folded headers");
    };

    if ($backend{$module} eq "https") {
        sok {
            t_cmp(GET('/verify')->code,
                  200,
                  "using valid proxyssl client cert");
        };

        sok {
            t_cmp(GET('/require/snakeoil')->code,
                  403,
                  "using invalid proxyssl client cert");
        };

        $res = GET('/require-ssl-cgi/env.pl');

        sok {
            t_cmp($res->code, 200, "protected cgi script");
        };

        my $body = $res->content || "";

        for my $line (split /\s*\r?\n/, $body) {
            my($key, $val) = split /\s*=\s*/, $line, 2;
            next unless $key;
            $vars{$key} = $val || "";
        }

        sok {
            t_cmp($vars{HTTP_X_FORWARDED_HOST},
                  $hostport,
                  "X-Forwarded-Host header");
        };

        sok {
            t_cmp($vars{SSL_CLIENT_S_DN_CN},
                  'client_ok',
                  "client subject common name");
        };
    }

    sok {
        #test that ProxyPassReverse rewrote the Location header
        #to use the frontend server rather than downstream server
        my $uri = '/modules';
        my $ruri = Apache::TestRequest::resolve_url($uri) . '/';

        #tell lwp not to follow redirect so we can see the Location header
        local $Apache::TestRequest::RedirectOK = 0;

        $res = GET($uri);

        my $location = $res->header('Location') || 'NONE';

        t_cmp($location, $ruri, 'ProxyPassReverse Location rewrite');
    };

    Apache::TestCommon::run_post_test($post_module) if $post_tests;
    Apache::TestRequest::user_agent(reset => 1);
}
