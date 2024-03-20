use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my %headers;

my $hasfix = 0;
if (have_min_apache_version("2.4.0")) { 
  if (have_min_apache_version("2.4.24")) { 
    $hasfix = 1;
  }
}
elsif (have_min_apache_version("2.2.32")) {
    $hasfix = 1;
}
if ($hasfix) { 
    %headers = (
               "Hello:World\r\n" => ["Hello", "World"],
               "Hello:  World\r\n" => ["Hello", "World"],
               "Hello:  World   \r\n" => ["Hello", "World"],
               "Hello:  World \t \r\n" => ["Hello", "World"],
               "Hello: Foo\r\n Bar\r\n" => ["Hello", "Foo Bar"],
               "Hello: Foo\r\n\tBar\r\n" => ["Hello", "Foo Bar"],
               "Hello: Foo\r\n    Bar\r\n" => ["Hello", "Foo Bar"],
               "Hello: Foo \t \r\n Bar\r\n" => ["Hello", "Foo Bar"],
               "Hello: Foo\r\n  \t Bar\r\n" => ["Hello", "Foo Bar"],
               );
}
else {
    %headers = (
               "Hello:World\n" => ["Hello", "World"],
               "Hello  :  World\n" => ["Hello", "World"],
               "Hello  :  World   \n" => ["Hello", "World"],
               "Hello \t :  World  \n" => ["Hello", "World"],
               "Hello: Foo\n Bar\n" => ["Hello", "Foo Bar"],
               "Hello: Foo\n\tBar\n" => ["Hello", "Foo\tBar"],
               "Hello: Foo\n    Bar\n" => ["Hello", qr/Foo +Bar/],
               "Hello: Foo \n Bar\n" => ["Hello", qr/Foo +Bar/],
               );
}

my $uri = "/modules/cgi/env.pl";

plan tests => (scalar keys %headers) * 3, need_cgi;

foreach my $key (sort keys %headers) {

    print "testing: $key";

    my $sock = Apache::TestRequest::vhost_socket('default');
    ok $sock;

    Apache::TestRequest::socket_trace($sock);

    $sock->print("GET $uri HTTP/1.0\r\n");
    $sock->print($key);
    $sock->print("\r\n");
    
    # Read the status line
    chomp(my $response = Apache::TestRequest::getline($sock) || '');
    $response =~ s/\s$//;

    ok t_cmp($response, qr{HTTP/1\.. 200 OK}, "response success");
    
    my $line;

    do {
        chomp($line = Apache::TestRequest::getline($sock) || '');
        $line =~ s/\s$//;
    }
    while ($line ne "");
    
    my $found = 0;

    my ($name, $value) = ($headers{$key}[0], $headers{$key}[1]);

    do {
        chomp($line = Apache::TestRequest::getline($sock) || '');
        $line =~ s/\r?\n?$//;
        if ($line ne "" && !$found) {
            my @part = split(/ = /, $line);
            if (@part && $part[0] eq "HTTP_" . uc($name)) {
                print "header: [".$part[1]."] vs [".$value."]\n";
                ok t_cmp $part[1], $value, "compare header $name value";
                $found = 1;
            }
        }
    }
    while ($line ne "");

    ok 0 unless $found;
}
    
