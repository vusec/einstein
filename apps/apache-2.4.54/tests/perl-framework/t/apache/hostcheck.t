use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;
use MIME::Base64;
use Data::Dumper;
use HTTP::Response;
use Socket;

#   undef:   HTTPD should drop connection without error message

my @test_cases = (
    # request, status code global, status code strict VH, msg
  [ "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n"      => 200, 400, "ok"],
  [ "GET / HTTP/1.1\r\nHost: localhost:1\r\n\r\n"    => 200, 400, "port ignored"],
  [ "GET / HTTP/1.1\r\nHost: notlisted\r\n\r\n"      => 200, 400, "name not listed"],
  [ "GET / HTTP/1.1\r\nHost: 127.0.0.1\r\n\r\n"      => 200, 400, "IP not in serveralias/servername"],
  [ "GET / HTTP/1.1\r\nHost: default-strict\r\n\r\n" => 200, 200, "NVH matches in default server"],
  [ "GET / HTTP/1.1\r\nHost: nvh-strict\r\n\r\n"     => 200, 200, "NVH matches"],
  [ "GET / HTTP/1.1\r\nHost: nvh-strict:1\r\n\r\n"   => 200, 200, "NVH matches port ignored"],
);
plan tests => scalar(@test_cases) * 2, need_min_apache_version('2.5.1');


foreach my $vhosts ((["default" => 1], ["core" => 2])) {
  my $vhost = $vhosts->[0];
  my $expect_column = $vhosts->[1];

  foreach my $t (@test_cases) {
    my $req = $t->[0];
    my $expect = $t->[$expect_column];
    my $desc = $t->[3];
    my $decoded;

    my $sock = Apache::TestRequest::vhost_socket($vhost);
    if (!$sock) {
        print "# failed to connect\n";
        ok(0);
        next;
    }

    print "# SENDING to " . peer($sock) . "\n# $req\n";
    $sock->print($req);
    $sock->shutdown(1);
    $req = escape($req);

    my $response_data = "";
    my $buf;
    while ($sock->read($buf, 10000) > 0) {
        $response_data .= $buf;
    }
    my $response = HTTP::Response->parse($response_data);
    if ($decoded) {
        $response_data =~ s/<title>.*/.../s;
        my $out = escape($response_data);
        $out =~ s{\\n}{\\n\n# }g;
        print "# RESPONSE:\n# $out\n";
    }
    if (! defined $response) {
        die "HTTP::Response->parse failed";
    }
    my $rc = $response->code;
    if (! defined $rc) {
        if (! defined $expect) {
            print "# expecting dropped connection and HTTPD dropped connection\n";
            ok(1);
        }
        else {
            print "# expecting $expect, but HTTPD dropped the connection\n";
            ok(0);
        }
    }
    elsif ($expect > 100) {
        print "# expected $expect, got " . $response->code . " for $desc\n";
        ok ($response->code, $expect, $desc );
    }
    elsif ($expect == 90) {
        print "# expecting headerless HTTP/0.9 body, got response\n";
        ok (1);
    }
    elsif ($expect) {
        print "# expecting success, got ", $rc, ": $desc\n";
        ok ($rc >= 200 && $rc < 400);
    }
    else {
        print "# expecting error, got ", $rc, ": $desc\n";
        ok ($rc >= 400);
    }
  }
}

sub escape
{
    my $in = shift;
    $in =~ s{\\}{\\\\}g;
    $in =~ s{\r}{\\r}g;
    $in =~ s{\n}{\\n}g;
    $in =~ s{\t}{\\t}g;
    $in =~ s{([\x00-\x1f])}{sprintf("\\x%02x", ord($1))}ge;
    return $in;
}

sub peer
{
   my $sock = shift;
   my $hersockaddr    = getpeername($sock);
   my ($port, $iaddr) = sockaddr_in($hersockaddr);
   my $herhostname    = gethostbyaddr($iaddr, AF_INET);
   my $herstraddr     = inet_ntoa($iaddr);
   return "$herstraddr:$port";
}
