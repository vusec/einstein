use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my @server_deflate_uris=("/modules/deflate/index.html",
                         "/modules/deflate/apache_pb.gif",
                         "/modules/deflate/asf_logo_wide.jpg",
                         "/modules/deflate/zero.txt",
                        );
my $server_inflate_uri="/modules/deflate/echo_post";
my @server_bucketeer_uri = ("/modules/deflate/bucketeer/P.txt",
                            "/modules/deflate/bucketeer/F.txt",
                            "/modules/deflate/bucketeer/FP.txt",
                            "/modules/deflate/bucketeer/FBP.txt",
                            "/modules/deflate/bucketeer/BB.txt",
                            "/modules/deflate/bucketeer/BBF.txt",
                            "/modules/deflate/bucketeer/BFB.txt"
                           );

my $cgi_tests = 3;
my $tests_per_uri = 4;
my $tests = $tests_per_uri * (@server_deflate_uris + @server_bucketeer_uri) + $cgi_tests;
my $vars = Apache::Test::vars();
my $module = 'default';

plan tests => $tests, need 'deflate', 'echo_post';

print "testing $module\n";

my @deflate_headers;
push @deflate_headers, "Accept-Encoding" => "gzip";

my @deflate_headers_q0;
push @deflate_headers_q0, "Accept-Encoding" => "gzip;q=0";

my @inflate_headers;
push @inflate_headers, "Content-Encoding" => "gzip";

if (have_module('bucketeer')) {
    push @server_deflate_uris, @server_bucketeer_uri;
}
else {
    skip "skipping bucketing deflate tests without mod_bucketeer"
        foreach (1 .. ($tests_per_uri * @server_bucketeer_uri));
}
for my $server_deflate_uri (@server_deflate_uris) {
    my $original_str = GET_BODY($server_deflate_uri);

    my $deflated_str = GET_BODY($server_deflate_uri, @deflate_headers);
    my $deflated_str_q0 = GET_BODY($server_deflate_uri, @deflate_headers_q0);

    my $inflated_str = POST_BODY($server_inflate_uri, @inflate_headers,
                                 content => $deflated_str);

    ok $original_str eq $inflated_str;
    ok $original_str eq $deflated_str_q0;
    my $resp = POST($server_inflate_uri, @inflate_headers,
                    content => "foo123456789012346");
    if (have_min_apache_version("2.5")) {
        ok($resp->code, 400, "did not detect invalid compressed request body for $server_deflate_uri");
    }
    elsif (have_min_apache_version("2.4.5")) {
        ok($resp->content, '!!!ERROR!!!', "did not detect invalid compressed request body for $server_deflate_uri");
    }
    else {
        ok($resp->code, 200, "invalid response for $server_deflate_uri");
    }
    
    # Disabled because not working reliably.
    # If the compressed data it big enough, a partial response
    # will get flushed to the client before the trailing spurious data
    # is found.
    #
    #if (have_min_apache_version("2.5")) {
    #    $resp = POST($server_inflate_uri, @inflate_headers,
    #                 content => $deflated_str . "foobarfoo");
    #    ok($resp->code, 400, "did not detect spurious data after compressed request body for $server_deflate_uri");
    #}
    #elsif (have_min_apache_version("2.4.5")) {
    #    # The "x 1000" can be removed, once r1502772 is ported back to 2.4.x
    #    $resp = POST($server_inflate_uri, @inflate_headers,
    #                 content => $deflated_str . ("foobarfoo" x 1000));
    #    ok($resp->content, '/.*!!!ERROR!!!$/', "did not detect spurious data after compressed request body for $server_deflate_uri");
    #}
    #else {
    #    ok($resp->code, 200, "invalid response for $server_deflate_uri");
    #}

    my $broken = $deflated_str;
    my $offset = (length($broken) > 35) ? 20 : -15;
    substr($broken, $offset, 15, "123456789012345");
    $resp = POST($server_inflate_uri, @inflate_headers,
                  content => $broken);
    if (have_min_apache_version("2.5")) {
        ok($resp->code, 400, "did not detect broken compressed request body for $server_deflate_uri");
    }
    elsif (have_min_apache_version("2.4.5")) {
        ok($resp->content, '/.*!!!ERROR!!!$/', "did not detect broken compressed request body for $server_deflate_uri");
    }
    else {
        ok($resp->code, 200, "invalid response for $server_deflate_uri");
    }
}

# mod_deflate fixes still pending to make this work...
if (have_module('cgi') && have_min_apache_version('2.1.0')) {
    my $sock = Apache::TestRequest::vhost_socket('default');

    ok $sock;

    Apache::TestRequest::socket_trace($sock);

    $sock->print("GET /modules/cgi/not-modified.pl HTTP/1.0\r\n");
    $sock->print("Accept-Encoding: gzip\r\n");
    $sock->print("\r\n");

    # Read the status line
    chomp(my $response = Apache::TestRequest::getline($sock) || '');
    $response =~ s/\s$//;

    ok t_cmp($response, qr{HTTP/1\.. 304}, "response was 304");
    
    do {
        chomp($response = Apache::TestRequest::getline($sock) || '');
        $response =~ s/\s$//;
    }
    while ($response ne "");
    
    # now try and read any body: should return 0, EOF.
    my $ret = $sock->read($response, 1024);
    ok t_cmp($ret, 0, "expect EOF after 304 header");
} else {
    skip "skipping 304/deflate tests without mod_cgi and httpd >= 2.1.0" foreach (1..$cgi_tests);
}
