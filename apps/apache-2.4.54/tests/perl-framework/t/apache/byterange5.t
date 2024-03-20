use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_write_file);

# test multi-byterange-requests while allowing re-ordering

my $url = "/apache/chunked/byteranges.txt";
my $file = Apache::Test::vars('serverroot') . "/htdocs$url";

my $content = "";
$content .= sprintf("%04d", $_) for (1 .. 2000);
t_write_file($file, $content);
my $clen = length($content);


my @test_cases = (
    "0-1,1000-1001",
    "1000-1100,100-200",
    "1000-1100,100-200,2000-2200",
    "1000-1100,100-200,2000-",
    "3000-,100-200,2000-2200",
);
plan tests => scalar(@test_cases), need need_lwp;

foreach my $test (@test_cases) {
    my $result = GET $url, "Range" => "bytes=$test";
    my $boundary;
    my $ctype = $result->header("Content-Type");
    if ($ctype =~ m{multipart/byteranges; boundary=(.*)}) {
        $boundary = $1;
    }
    else {
        print "Wrong Content-Type: $ctype\n"; 
        ok(0);
        next;
    }

    my @want = split(",", $test);
    foreach my $w (@want) {
        $w =~ /(\d*)-(\d*)/ or die;
        if (defined $1 eq "") {
            $w = [ $clen - $2, $clen - 1 ];
        }
        elsif ($2 eq "") {
            $w = [ $1, $clen - 1 ];
        }
        else {
            $w = [ $1, $2 ];
        }
    }

    my @got;
    my $rcontent = $result->content;
    my $error;
    while ($rcontent =~ s{^[\n\s]*--$boundary\s*?\n(.+?)\r\n\r\n}{}s ) {
        my $headers = $1;
        my ($from, $to);
        if ($headers =~ m{^Content-range: bytes (\d+)-(\d+)/\d*$}mi ) {
            $from = $1;
            $to = $2;
        }
        else {
            print "Can't parse Content-range in '$headers'\n";
            $error = 1;
        }
        push @got, [$from, $to];
        my $chunk = substr($rcontent, 0, $to - $from + 1, "");
        my $expect = substr($content, $from, $to - $from + 1);
        if ($chunk ne $expect) {
            print "Wrong content in range. Got: \n",
                  $headers, $content,
                  "Expected:\n$expect\n";
            $error = 1;
        }
    }
    if ($error) {
        ok(0);
        next;
    }
    if ($rcontent !~ /^[\s\n]*--${boundary}--[\s\n]*$/) {
        print "error parsing final boundary: '$rcontent'\n";
        ok(0);
        next;
    }
    foreach my $w (@want) {
        my $found;
        foreach my $g (@got) {
            $found = 1 if ($g->[0] <= $w->[0] && $g->[1] >= $w->[1]);
        }
        if (!$found) {
            print "Data for '$w->[0]-$w->[1]' not found in response\n";
            $error = 1;
        }
    }
    if ($error) {
        ok(0);
        next;
    }

    ok (1);
}
