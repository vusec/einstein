use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest ();

my @test_strings = ("",
                    "0",
                    "0000000000000000000000000000000000",
                    "1000000000000000000000000000000000",
                    "-1",
                    "123abc",
                    );
my @req_strings =  ("/echo_post",
                    "/i_do_not_exist_in_your_wildest_imagination");

my $resp_failure;
if (have_min_apache_version('2.2.30')
    && (!have_min_apache_version('2.3.0')
        || have_min_apache_version('2.4.14'))) {
    $resp_failure = "HTTP/1.1 400 Bad Request";
}
else {
    $resp_failure = "HTTP/1.1 413 Request Entity Too Large";
}
# This is expanded out.
my @resp_strings = ($resp_failure,
                    $resp_failure,
                    "HTTP/1.1 200 OK",
                    "HTTP/1.1 404 Not Found",
                    "HTTP/1.1 200 OK",
                    "HTTP/1.1 404 Not Found",
                    $resp_failure,
                    $resp_failure,
                    $resp_failure,
                    $resp_failure,
                    $resp_failure,
                    $resp_failure,
                   );

my $tests = 4 * @test_strings;
my $vars = Apache::Test::vars();
my $module = 'default';
my $cycle = 0;

plan tests => $tests, ['eat_post'];

print "testing $module\n";

for my $data (@test_strings) {
  for my $request_uri (@req_strings) {
    my $sock = Apache::TestRequest::vhost_socket($module);
    ok $sock;

    Apache::TestRequest::socket_trace($sock);

    $sock->print("POST $request_uri HTTP/1.0\r\n");
    $sock->print("Content-Length: $data\r\n");
    $sock->print("\r\n");
    $sock->print("\r\n");

    # Read the status line
    chomp(my $response = Apache::TestRequest::getline($sock) || '');
    $response =~ s/\s$//;

    # Tests with empty content-length have platform-specific behaviour
    # until 2.1.0.
    skip 
      $data eq "" && !have_min_apache_version('2.1.0') ? 
         "skipping tests with empty C-L for httpd < 2.1.0" : 0,
      t_cmp($response, $resp_strings[$cycle],
             "response codes POST for $request_uri with Content-Length: $data");

    $cycle++;

    do {
        chomp($response = Apache::TestRequest::getline($sock) || '');
        $response =~ s/\s$//;
    }
    while ($response ne "");
  }
}
