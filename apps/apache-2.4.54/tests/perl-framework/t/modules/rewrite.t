use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

## mod_rewrite tests
##
## extra.conf.in:

my @map = qw(txt rnd prg); #dbm XXX: howto determine dbm support is available?
my @num = qw(1 2 3 4 5 6);
my @url = qw(forbidden gone perm temp);
my @todo;
my $r;

if (!have_min_apache_version('2.4.19')) {
    # PR 50447, server context
    push @todo, 26
}
if (!have_min_apache_version('2.4')) {
    # PR 50447, directory context (r1044673)
    push @todo, 24
}

# Specific tests for PR 58231
my $vary_header_tests = (have_min_apache_version("2.4.30") ? 9 : 0) + (have_min_apache_version("2.4.29") ? 4 : 0);
my $cookie_tests = have_min_apache_version("2.4.47") ? 6 : 0;

plan tests => @map * @num + 16 + $vary_header_tests + $cookie_tests, todo => \@todo, need_module 'rewrite';

foreach (@map) {
    foreach my $n (@num) {
        ## throw $_ into upper case just so we can test out internal
        ## 'tolower' map in mod_rewrite
        $_=uc($_);

        $r = GET_BODY("/modules/rewrite/$n", 'Accept' => $_);
        chomp $r;
	$r =~ s/\r//g;

        if ($_ eq 'RND') {
            ## check that $r is just a single digit.
            unless ($r =~ /^[\d]$/) {
                ok 0;
                next;
            }

            ok ($r =~ /^[$r-6]$/);
        } else {
            ok ($r eq $n);
        }
    }
}

$r = GET_BODY("/modules/rewrite/", 'Accept' => 7);
chomp $r;
$r =~ s/\r//g;
ok ($r eq "BIG");
$r = GET_BODY("/modules/rewrite/", 'Accept' => 0);
chomp $r;
$r =~ s/\r//g;
ok ($r eq "ZERO");
$r = GET_BODY("/modules/rewrite/", 'Accept' => 'lucky13');
chomp $r;
$r =~ s/\r//g;
ok ($r eq "JACKPOT");

$r = GET_BODY("/modules/rewrite/qsa.html?baz=bee");
chomp $r;
ok t_cmp($r, qr/\nQUERY_STRING = foo=bar\&baz=bee\n/s, "query-string append test");

# PR 50447 (double URL-escaping of the query string)
my $hostport = Apache::TestRequest::hostport();

$r = GET("/modules/rewrite/redirect-dir.html?q=%25", redirect_ok => 0);
ok t_cmp($r->code, 301, "per-dir redirect response code is OK");
ok t_cmp($r->header("Location"), "http://$hostport/foobar.html?q=%25",
         "per-dir query-string escaping is OK");

$r = GET("/modules/rewrite/redirect.html?q=%25", redirect_ok => 0);
ok t_cmp($r->code, 301, "redirect response code is OK");
ok t_cmp($r->header("Location"), "http://$hostport/foobar.html?q=%25",
         "query-string escaping is OK");

if (have_module('mod_proxy')) {
    $r = GET_BODY("/modules/rewrite/proxy.html");
    chomp $r;
    ok t_cmp($r, "JACKPOT", "request was proxied");

    # PR 46428
    $r = GET_BODY("/modules/proxy/rewrite/foo bar.html");
    chomp $r;
    ok t_cmp($r, "foo bar", "per-dir proxied rewrite escaping worked");
} else {
    skip "Skipping rewrite to proxy; no proxy module." foreach (1..2);
}

if (have_module('mod_proxy') && have_cgi) {
    # regression in 1.3.32, see PR 14518
    $r = GET_BODY("/modules/rewrite/proxy2/env.pl?fish=fowl");
    chomp $r;
    ok t_cmp($r, qr/QUERY_STRING = fish=fowl\n/s, "QUERY_STRING passed OK");

    ok t_cmp(GET_RC("/modules/rewrite/proxy3/env.pl?horse=norman"), 404,
             "RewriteCond QUERY_STRING test");
    
    $r = GET_BODY("/modules/rewrite/proxy3/env.pl?horse=trigger");
    chomp $r;
    ok t_cmp($r, qr/QUERY_STRING = horse=trigger\n/s, "QUERY_STRING passed OK");

    $r = GET("/modules/rewrite/proxy-qsa.html?bloo=blar");
    ok t_cmp($r->code, 200, "proxy/QSA test success");
    
    ok t_cmp($r->as_string, qr/QUERY_STRING = foo=bar\&bloo=blar\n/s,
             "proxy/QSA test appended args correctly");
} else {
    skip "Skipping rewrite QUERY_STRING test; missing proxy or CGI module" foreach (1..5);
}

if (have_min_apache_version('2.4')) {
    # See PR 60478 and the corresponding config in extra.conf
    $r = GET("/modules/rewrite/pr60478-rewrite-loop/a/X/b/c");
    ok t_cmp($r->code, 500, "PR 60478 rewrite loop is halted");
} else {
    skip "Skipping PR 60478 test; requires ap_expr in version 2.4"
}

if (have_min_apache_version("2.4.29")) {
    # PR 58231: Vary:Host header (was) mistakenly added to the response
    $r = GET("/modules/rewrite/vary1.html", "Host" => "test1");
    ok t_cmp($r->content, qr/VARY2/, "Correct internal redirect happened, OK");
    ok t_cmp($r->header("Vary"), qr/(?!.*Host.*)/, "Vary:Host header not added, OK");

    $r = GET("/modules/rewrite/vary1.html", "Host" => "test2");
    ok t_cmp($r->content, qr/VARY2/, "Correct internal redirect happened, OK");
    ok t_cmp($r->header("Vary"), qr/(?!.*Host.*)/, "Vary:Host header not added, OK");
}

if (have_min_apache_version("2.4.30")) {
    # PR 58231: Vary header added when a condition evaluates to true and
    # the RewriteRule happens in a directory context.
    $r = GET("/modules/rewrite/vary3.html", "User-Agent" => "directory-agent");
    ok t_cmp($r->content, qr/VARY4/, "Correct internal redirect happened, OK");
    ok t_cmp($r->header("Vary"), qr/User-Agent/, "Vary:User-Agent header added, OK");

    # Corner cases in which two RewriteConds are joined using the [OR]
    # operator (or similar).
    # 1) First RewriteCond condition evaluates to true, so only the related
    #    header value is added to the Vary list even though the second condition
    #    evaluates to true as well.
    $r = GET("/modules/rewrite/vary3.html",
             "Referer" => "directory-referer",
             "Accept" => "directory-accept");
    ok t_cmp($r->content, qr/VARY4/, "Correct internal redirect happened, OK");
    ok t_cmp($r->header("Vary"), qr/Accept/, "Vary:Accept header added, OK");
    # 2) First RewriteCond condition evaluates to false and the second to true,
    #    so only the second condition's header value is added to the Vary list.
    $r = GET("/modules/rewrite/vary3.html",
             "Referer" => "directory-referer",
             "Accept" => "this-is-not-the-value-in-the-rewritecond");
    ok t_cmp($r->content, qr/VARY4/, "Correct internal redirect happened, OK");
    ok t_cmp($r->header("Vary"), qr/Referer/, "Vary:Referer header added, OK");
    ok t_cmp($r->header("Vary"), qr/(?!.*Accept.*)/, "Vary:Accept header not added, OK");

    # Vary:Host header (was) mistakenly added to the response
    $r = GET("/modules/rewrite/vary3.html", "Host" => "directory-domain");
    ok t_cmp($r->content, qr/VARY4/, "Correct internal redirect happened, OK");
    ok t_cmp($r->header("Vary"), qr/(?!.*Host.*)/, "Vary:Host header not added, OK");
}

if (have_min_apache_version("2.4.47")) {
    $r = GET("/modules/rewrite/cookie/");
    ok t_cmp($r->header("Set-Cookie"), qr/(?!.*SameSite=.*)/, "samesite not present with no arg");
    $r = GET("/modules/rewrite/cookie/0");
    ok t_cmp($r->header("Set-Cookie"), qr/(?!.*SameSite=.*)/, "samesite not present with 0");
    $r = GET("/modules/rewrite/cookie/false");
    ok t_cmp($r->header("Set-Cookie"), qr/(?!.*SameSite=.*)/, "samesite not present with false");
    $r = GET("/modules/rewrite/cookie/none");
    ok t_cmp($r->header("Set-Cookie"), qr/SameSite=none/, "samesite=none");
    $r = GET("/modules/rewrite/cookie/lax");
    ok t_cmp($r->header("Set-Cookie"), qr/SameSite=lax/, "samesite=lax");
    $r = GET("/modules/rewrite/cookie/foo");
    ok t_cmp($r->header("Set-Cookie"), qr/SameSite=foo/, "samesite=foo");
}
