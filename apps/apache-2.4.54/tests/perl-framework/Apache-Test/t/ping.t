use strict;
use warnings FATAL => 'all';

use Apache::Test;

plan tests => 3;

my $config = Apache::Test::config();

ok $config;

my $server = $config->server;

ok $server;

ok $server->ping;

