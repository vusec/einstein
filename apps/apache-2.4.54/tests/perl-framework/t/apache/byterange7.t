use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_write_file);

# test content-length header in byterange-requests
# test invalid range headers

my $url = "/apache/chunked/byteranges.txt";
my $file = Apache::Test::vars('serverroot') . "/htdocs$url";

my $content = "";
$content .= sprintf("%04d", $_) for (1 .. 10000);
t_write_file($file, $content);
my $real_clen = length($content);


#
# test cases
#

# check content-length for (multi-)range responses
my @tc_ranges_cl = ( 1, 2, 10, 50, 100);
# send 200 response if range invalid
my @tc_invalid = ("", ",", "7-1", "foo", "1-4,x", "1-4,5-2",
                  "100000-110000,5-2");
# send 416 if no range satisfiable
my %tc_416 = (
        "100000-110000" => 416,
        "100000-110000,200000-" => 416,
        "1000-200000"   => 206,           # should be truncated until end
        "100000-110000,1000-2000" => 206, # should ignore unsatifiable range
        "100000-110000,2000-1000" => 200, # invalid, should ignore whole header
    );

plan tests => scalar(@tc_ranges_cl) +
              2 * scalar(@tc_invalid) +
              scalar(keys %tc_416),
              need need_lwp;

foreach my $num (@tc_ranges_cl) {
    my @ranges;
    foreach my $i (0 .. ($num-1)) {
        push @ranges, sprintf("%d-%d", $i * 100, $i * 100 + 1);
    }
    my $range = join(",", @ranges);
    my $result = GET $url, "Range" => "bytes=$range";
    print_result($result);
    if ($result->code != 206) {
        print "did not get 206\n";
        ok(0);
        next;
    }
    my $clen = $result->header("Content-Length");
    my $body = $result->content;
    my $blen = length($body);
    if ($blen == $real_clen) {
        print "Did get full content, should have gotten only parts\n";
        ok(0);
        next;
    }
    print "body length $blen\n";
    if (defined $clen) {
        print "Content-Length: $clen\n";
        if ($blen != $clen) {
            print "Content-Length does not match body\n";
            ok(0);
            next;
        }
    }
    ok(1);
}

# test invalid range headers, with and without "bytes="
my @tc_invalid2 = map { "bytes=" . $_ } @tc_invalid;
foreach my $range (@tc_invalid, @tc_invalid2) {
    my $result = GET $url, "Range" => "$range";
    print_result($result);
    my $code = $result->code;
    if ($code == 206) {
        print "got partial content response with invalid range header '$range'\n";
        ok(0);
    }
    elsif ($code == 200) {
        my $body = $result->content;
        if ($body != $content) {
            print "Body did not match expected content\n";
            ok(0);
        }
        ok(1);
    }
    else {
        print "Huh?\n";
        ok(0);
    }
}

# test unsatisfiable ranges headers
foreach my $range (sort keys %tc_416) {
    print "Sending '$range', expecting $tc_416{$range}\n";
    my $result = GET $url, "Range" => "bytes=$range";
    print_result($result);
    ok($result->code == $tc_416{$range});
}

sub print_result
{
    my $result = shift;
    my $code = $result->code;
    my $cr = $result->header("Content-Range");
    my $ct = $result->header("Content-Type");
    my $msg = "Got $code";
    $msg .= " multipart/byteranges"
        if (defined $ct && $ct =~ m{^multipart/byteranges});
    $msg .= " Range: '$cr'" if defined $cr;
    print "$msg\n";
}
