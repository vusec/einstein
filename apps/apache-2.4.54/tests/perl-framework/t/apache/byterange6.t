use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_write_file t_debug);

# test multi-byterange-requests with overlaps (merges)

my $url = "/apache/chunked/byteranges.txt";
my $file = Apache::Test::vars('serverroot') . "/htdocs$url";

my $content = "";
$content .= sprintf("%04d", $_) for (1 .. 2000);
t_write_file($file, $content);
my $clen = length($content);


my @test_cases = (
    { h => "0-100,70-100,1000-1001", actlike => "0-100,1000-1001"},
    { h => "0-90,70-100,1000-1001", actlike => "0-100,1000-1001"},
    { h => "0-70,70-100,1000-1001", actlike => "0-100,1000-1001"},
    { h => "1-100,70-100,1000-1001", actlike => "1-100,1000-1001"},
    { h => "1-90,70-100,1000-1001", actlike => "1-100,1000-1001"},
    { h => "1-90,70-100,1000-1001", actlike => "1-100,1000-1001"},
    { h => "0-100,70-100,1000-1001,5-6", actlike => "0-100,1000-1001,5-6"},
    { h => "0-90,70-100,1000-1001,5-6", actlike => "0-100,1000-1001,5-6"},
    { h => "0-70,70-100,1000-1001,5-6", actlike => "0-100,1000-1001,5-6"},
    { h => "1-100,70-100,1000-1001,5-6", actlike => "1-100,1000-1001,5-6"},

    { h => "1-90,70-100,1000-1001,5-6", actlike => "1-100,1000-1001,5-6"},
    { h => "1-90,70-100,1000-1001,5-6", actlike => "1-100,1000-1001,5-6"},
    { h => "1-70,70-100,1000-1001", actlike => "1-100,1000-1001"},
    { h => "1-70,71-100,1000-1001", actlike => "1-100,1000-1001"},
    { h => "1-70,69-100,1000-1001", actlike => "1-100,1000-1001"},
    { h => "1-70,0-100,1000-1001", actlike => "1-100,1000-1001"},
    { h => "0-70,72-100,1000-1001", actlike => "0-70,72-100,1000-1001"},
    { h => "1-70,0-100,1000-1001", actlike => "0-100,1000-1001"},
    { h => "1-70,1-100,1000-1001", actlike => "1-100,1000-1001"},
    { h => "1-70,2-100,1000-1001", actlike => "1-100,1000-1001"},

    { h => "0-100,0-99,1000-1001", actlike => "0-100,1000-1001"},
    { h => "0-100,0-100,1000-1001", actlike => "0-100,1000-1001"},
    { h => "0-100,0-101,1000-1001", actlike => "0-101,1000-1001"},
    { h => "0-100,1-99,1000-1001", actlike => "0-100,1000-1001"},
    { h => "0-100,1-100,1000-1001", actlike => "0-100,1000-1001"},
    { h => "0-100,1-101,1000-1001", actlike => "0-101,1000-1001"},
    { h => "0-100,50-99,1000-1001", actlike => "0-100,1000-1001"},
    { h => "0-100,50-100,1000-1001", actlike => "0-100,1000-1001"},
    { h => "0-100,50-101,1000-1001", actlike => "0-101,1000-1001"},
    { h => "1-10,1-9,99-99", actlike => "1-10,99-99"},

    { h => "1-10,1-10,99-99", actlike => "1-10,99-99"},
    { h => "1-10,1-11,99-99", actlike => "1-11,99-99"},
    { h => "1-10,0-9,99-99", actlike => "0-10,99-99"},
    { h => "1-10,0-10,99-99", actlike => "0-10,99-99"},
    { h => "1-10,0-11,99-99", actlike => "0-11,99-99"},
    { h => "1-10,0-12,99-99", actlike => "0-12,99-99"},
    { h => "1-10,0-13,99-99", actlike => "0-13,99-99"},
    { h => "1-10,2-11,99-99", actlike => "1-11,99-99"},
    { h => "1-10,2-12,99-99", actlike => "1-12,99-99"},
    { h => "1-10,2-13,99-99", actlike => "1-13,99-99"},

    { h => "1-10,1-9,99-99", actlike => "1-10,99-99"},
    { h => "1-11,1-10,99-99", actlike => "1-11,99-99"},
    { h => "1-9,1-10,99-99", actlike => "1-10,99-99"},
    { h => "0-11,1-10,99-99", actlike => "0-11,99-99"},
    { h => "1-9,1-10,99-99", actlike => "1-10,99-99"},
    { h => "10-20,1-9,99-99", actlike => "1-20,99-99"},
    { h => "10-20,1-10,99-99", actlike => "1-20,99-99"},
    { h => "10-20,1-11,99-99", actlike => "1-20,99-99"},
    { h => "10-20,1-21,99-99", actlike => "1-21,99-99"},

    { h => "5-10,11-12,99-99", actlike => "5-12,99-99"},
    { h => "5-10,1-4,99-99", actlike => "1-10,99-99"},
    { h => "5-10,1-3,99-99", actlike => "5-10,1-3,99-99"},

    { h => "0-1,-1", actlike => "0-1,-1"}, # PR 51748

);
plan tests => scalar(@test_cases), need need_lwp, 
                                   need_min_apache_version('2.3.15');


foreach my $test (@test_cases) {
    my $result = GET $url, "Range" => "bytes=" . $test->{"h"} ;
    my $boundary;
    my $ctype = $result->header("Content-Type");
    if ($ctype =~ m{multipart/byteranges; boundary=(.*)}) {
        $boundary = $1;
    }
    else {
        print "Wrong Content-Type: $ctype, for ".$test->{"h"}."\n"; 
        ok(0);
        next;
    }

    my @want = split(",", $test->{"actlike"});
    foreach my $w (@want) {
        $w =~ /(\d*)-(\d*)/ or die;
        if ($1 eq "") {
            $w = [ $clen - $2, $clen - 1 ];
        }
        elsif ($2 eq "") {
            $w = [ $1, $clen - 1 ];
        }
        else {
            $w = [ $1, $2 ];
        }
        t_debug("expecting range ". $w->[0]. "-". $w->[1]);
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
            print "Data for '$w->[0]-$w->[1]' not found in response\n" . $result->content. "\n";
            $error = 1;
        }
    }
    if ($error) {
        ok(0);
        next;
    }

    ok (1);
}
