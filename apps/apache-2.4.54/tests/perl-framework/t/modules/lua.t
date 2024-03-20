use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;
use Apache::TestConfig ();

my $config = Apache::Test::config();
my $server = $config->server;
my $version = $server->{version};
my $scheme = Apache::Test::vars()->{scheme};
my $hostport = Apache::TestRequest::hostport();

my $https = "nope";
$https = "yep" if $scheme eq "https";

my $pfx = "/modules/lua";

my @ts = (
    { url => "$pfx/hello.lua", rcontent => "Hello Lua World!\n", 
      ctype => "text/plain" },
    { url => "$pfx/404?translateme=1", rcontent => "Hello Lua World!\n" },

    { url => "$pfx/translate-inherit-before/404?translateme=1", rcontent => "other lua handler\n" },
    { url => "$pfx/translate-inherit-default-before/404?translateme=1", rcontent => "other lua handler\n" },
    { url => "$pfx/translate-inherit-after/404?translateme=1", rcontent => "Hello Lua World!\n" },

    { url => "$pfx/translate-inherit-before/404?translateme=1&ok=1", rcontent => "other lua handler\n" },
    { url => "$pfx/translate-inherit-default-before/404?translateme=1&ok=1", rcontent => "other lua handler\n" },
    # the more specific translate_name handler will run first and return OK.
    { url => "$pfx/translate-inherit-after/404?translateme=1&ok=1", rcontent => "other lua handler\n" },

    { url => "$pfx/version.lua", rcontent => qr(^$version) },
    { url => "$pfx/method.lua", rcontent => "GET" },
    { url => "$pfx/201.lua", rcontent => "", code => 201 },
    { url => "$pfx/https.lua", rcontent => $https },
    { url => "$pfx/setheaders.lua", rcontent => "",
                                    headers => { "X-Header" => "yes",
                                                 "X-Host"   => $hostport } },
    { url => "$pfx/setheaderfromparam.lua?HeaderName=foo&HeaderValue=bar",
                                    rcontent => "Header set",
                                    headers => { "foo" => "bar" } },
    { url => "$pfx/filtered/foobar.html",
          rcontent => "prefix\nbucket:foobar\nsuffix\n" },
);

plan tests => 4 * scalar @ts, need 'lua';

for my $t (@ts) {
    my $url = $t->{"url"};
    my $r = GET $url;
    my $code = $t->{"code"} || 200;
    my $headers = $t->{"headers"};

    ok t_cmp($r->code, $code, "code for $url");
    ok t_cmp($r->content, $t->{"rcontent"}, "response content for $url");

    if ($t->{"ctype"}) {
        ok t_cmp($r->header("Content-Type"), $t->{"ctype"}, "c-type for $url");
    }
    else {
        skip 1;
    }

    if ($headers) {
        my $correct = 1;
        while (my ($name, $value) = each %{$headers}) {
            my $actual = $r->header($name) || "<unset>";
            t_debug "'$name' header value is '$actual' (expected '$value')";

            if ($actual ne $value) {
                $correct = 0;
            }
        }
        ok $correct;
    }
    else {
        skip 1;
    }
}
