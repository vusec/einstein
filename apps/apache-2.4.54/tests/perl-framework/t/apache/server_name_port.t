use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Socket;

# send
#       arg #1: url prefix
#       arg #2: Host header (none if undef)
# expected results:
#       arg #3:  response code
#       arg #4:  SERVER_NAME
#       arg #5:  SERVER_PORT (canonical port if 'REMOTE')
#    undef == don't care

my $url_suffix = 'modules/cgi/env.pl';

my @test_cases = (
    [ "/",                     "righthost"     => 200, 'righthost', 'REMOTE' ],
    [ "/",                     "righthost:123" => 200, 'righthost', '123'    ],
    [ "/",                     "Righthost"     => 200, 'righthost', 'REMOTE' ],
    [ "/",                     "Righthost:123" => 200, 'righthost', '123'    ],
    [ "/",                     "128.0.0.1"     => 200, '128.0.0.1', 'REMOTE' ],
    [ "/",                     "128.0.0.1:123" => 200, '128.0.0.1', '123'    ],
    [ "/",                     "[::1]"         => 200, '[::1]',     'REMOTE' ],
    [ "/",                     "[::1]:123"     => 200, '[::1]',     '123'    ],
    [ "/",                     "[a::1]"        => 200, '[a::1]',    'REMOTE' ],
    [ "/",                     "[a::1]:123"    => 200, '[a::1]',    '123'    ],
    [ "/",                     "[A::1]"        => 200, '[a::1]',    'REMOTE' ],
    [ "/",                     "[A::1]:123"    => 200, '[a::1]',    '123'    ],
    [ "http://righthost/",     undef           => 200, 'righthost', 'REMOTE' ],
    [ "http://righthost:123/", undef           => 200, 'righthost', '123'    ],
    [ "http://Righthost/",     undef           => 200, 'righthost', 'REMOTE' ],
    [ "http://Righthost:123/", undef           => 200, 'righthost', '123'    ],
    [ "http://128.0.0.1/",     undef           => 200, '128.0.0.1', 'REMOTE' ],
    [ "http://128.0.0.1:123/", undef           => 200, '128.0.0.1', '123'    ],
    [ "http://[::1]/",         undef           => 200, '[::1]',     'REMOTE' ],
    [ "http://[::1]:123/",     undef           => 200, '[::1]',     '123'    ],
    [ "http://righthost/",     "wronghost"     => 200, 'righthost', 'REMOTE' ],
    [ "http://righthost:123/", "wronghost:321" => 200, 'righthost', '123'    ],
    [ "http://Righthost/",     "wronghost"     => 200, 'righthost', 'REMOTE' ],
    [ "http://Righthost:123/", "wronghost:321" => 200, 'righthost', '123'    ],
    [ "http://128.0.0.1/",     "126.0.0.1"     => 200, '128.0.0.1', 'REMOTE' ],
    [ "http://128.0.0.1:123/", "126.0.0.1:321" => 200, '128.0.0.1', '123'    ],
    [ "http://[::1]/",         "[::2]"         => 200, '[::1]',     'REMOTE' ],
    [ "http://[::1]:123/",     "[::2]:321"     => 200, '[::1]',     '123'    ],
);

my @todo;
if (!have_min_apache_version('2.4.24')) {
   # r1426827
   push @todo, 32, 35, 56, 59, 80, 83;
}
if (!have_min_apache_version('2.4')) {
   # r1147614, PR 26005
   push @todo, 20, 23, 26, 29;
}

plan tests => 3 * scalar(@test_cases), todo => \@todo, need need_min_apache_version('2.2'), need_cgi;

foreach my $t (@test_cases) {
    my $req = "GET $t->[0]$url_suffix HTTP/1.1\r\nConnection: close\r\n";
    $req .= "Host: $t->[1]\r\n" if defined $t->[1];
    $req .= "\r\n";
    	
    my %ex = (
        rc           => $t->[2],
        SERVER_NAME  => $t->[3],
        SERVER_PORT  => $t->[4],
    );

    my $sock = Apache::TestRequest::vhost_socket();
    if (!$sock) {
        print "# failed to connect\n";
        ok(0);
        next;
    }
    if (defined $ex{SERVER_PORT} && $ex{SERVER_PORT} eq 'REMOTE') {
        my $peername = getpeername($sock);
        my ($port) = sockaddr_in($peername);
        $ex{SERVER_PORT} = "$port";
    }

    $sock->print($req);
    $sock->shutdown(1);
    sleep(0.1);
    print "# SENDING:\n# ", escape($req), "\n";

    my $response_data = "";
    my $buf;
    while ($sock->read($buf, 10000) > 0) {
        $response_data .= $buf;
    }
    my $response = HTTP::Response->parse($response_data);
    if (! defined $response) {
        die "HTTP::Response->parse failed";
    }
    my $rc = $response->code;
    if (! defined $rc) {
        print "# HTTPD dropped the connection\n";
        ok(0);
    }
    else {
        print "# expecting $ex{rc}, got ", $rc, "\n";
        ok ($rc == $ex{rc});
    }

    foreach my $var (qw/SERVER_NAME SERVER_PORT/) {
        if (! defined $ex{$var}) {
            print "# don't care about $var\n";
            ok(1);
        }
        elsif ($response_data =~ /^$var = (.*)$/m) {
            my $val = $1;
            print "# got $var='$val', expected '$ex{$var}'\n";
            ok($val eq $ex{$var});
        }
        else {
            print "# no $var in response, expected '$ex{$var}'\n";
            ok(0);
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
