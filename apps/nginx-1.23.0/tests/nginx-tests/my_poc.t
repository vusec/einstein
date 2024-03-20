#!/usr/bin/perl

use warnings;
use strict;

use Test::More;

BEGIN { use FindBin; chdir($FindBin::Bin); }

use lib 'lib';
use Test::Nginx;

###############################################################################

select STDERR; $| = 1;
select STDOUT; $| = 1;

my $t = Test::Nginx->new()->has(qw/http rewrite gzip/)->plan(0)
	->write_file_expand('nginx.conf', <<'EOF');

%%TEST_GLOBALS%%

daemon off;

events {
}

http {
    %%TEST_GLOBALS_HTTP%%

    log_format test "$uri:$status";

    error_log /tmp/poc-error.log debug;

    server {
        listen       127.0.0.1:8080;
        server_name  localhost;

        location /cache {
            open_log_file_cache max=3;
            access_log %%TESTDIR%%/dir/cache_${arg_logname} test;
            return 200 OK;
        }
    }
}

EOF

my $d = $t->testdir();

mkdir "$d/dir";

$t->run();

###############################################################################

http_get('/cache');
http_get('/does-not-exist');

###############################################################################
