use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest ();

my @test_strings = ("0",
                    "A\r\n1234567890\r\n0",
                    "A; ext=val\r\n1234567890\r\n0",
                    "A    \r\n1234567890\r\n0",        # <10 BWS
                    "A :: :: :: \r\n1234567890\r\n0",  # <10 BWS multiple send
                    "A           \r\n1234567890\r\n0", # >10 BWS
                    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\r\n",
                    "A; ext=\x7Fval\r\n1234567890\r\n0",
                    " A",
                    );
my @req_strings =  ("/echo_post_chunk",
                    "/i_do_not_exist_in_your_wildest_imagination");

# This is expanded out as these results...
my @resp_strings = ("HTTP/1.1 200 OK",        # "0"
                    "HTTP/1.1 404 Not Found",
                    "HTTP/1.1 200 OK",        # "A"
                    "HTTP/1.1 404 Not Found",
                    "HTTP/1.1 200 OK",        # "A; ext=val"
                    "HTTP/1.1 404 Not Found",
                    "HTTP/1.1 200 OK",        # "A    "
                    "HTTP/1.1 404 Not Found",
                    "HTTP/1.1 200 OK",        # "A " + " " + " "  + " " pkts 
                    "HTTP/1.1 404 Not Found",
                    "HTTP/1.1 400 Bad Request", # >10 BWS
                    "HTTP/1.1 400 Bad Request",
                    "HTTP/1.1 413 Request Entity Too Large", # Overflow size
                    "HTTP/1.1 413 Request Entity Too Large",
                    "HTTP/1.1 400 Bad Request",    # Ctrl in data
                    "HTTP/1.1 400 Bad Request",
                    "HTTP/1.1 400 Bad Request",    # Invalid LWS
                    "HTTP/1.1 400 Bad Request",
                   );

my $tests = 4 * @test_strings + 1;
my $vars = Apache::Test::vars();
my $module = 'default';
my $cycle = 0;

plan tests => $tests, ['echo_post_chunk'];

print "testing $module\n";

for my $data (@test_strings) {
  for my $request_uri (@req_strings) {
    my $sock = Apache::TestRequest::vhost_socket($module);
    ok $sock;

    Apache::TestRequest::socket_trace($sock);

    my @elts = split("::", $data);

    $sock->print("POST $request_uri HTTP/1.0\r\n");
    $sock->print("Transfer-Encoding: chunked\r\n");
    $sock->print("\r\n");
    if (@elts > 1) {
        for my $elt (@elts) {
            $sock->print("$elt");
            sleep 0.5;
        }
        $sock->print("\r\n");
    }
    else {
        $sock->print("$data\r\n");
    }
    $sock->print("X-Chunk-Trailer: $$\r\n");
    $sock->print("\r\n");

    #Read the status line
    chomp(my $response = Apache::TestRequest::getline($sock));
    $response =~ s/\s$//;
    ok t_cmp($response, $resp_strings[$cycle++], "response codes");

    do {
        chomp($response = Apache::TestRequest::getline($sock));
        $response =~ s/\s$//;
    }
    while ($response ne "");

    if ($cycle == 1) {
        $response = Apache::TestRequest::getline($sock);
        chomp($response) if (defined($response));
        ok t_cmp($response, "$$", "trailer (pid)");
    }
  }
}
