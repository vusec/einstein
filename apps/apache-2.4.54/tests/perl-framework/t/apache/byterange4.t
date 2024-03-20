use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_write_file);

# test byteranges if range boundaries are near bucket boundaries

my $url = "/apache/chunked/byteranges.txt";
my $file = Apache::Test::vars('serverroot') . "/htdocs$url";

my $content = "";
$content .= sprintf("%04d", $_) for (1 .. 2000);
my $clen = length($content);

# make mod_bucketeer create buckets of size 200 from our 4000 bytes
my $blen = 200;
my $B = chr(0x02);
my @buckets = ($content =~ /(.{1,$blen})/g);
my $file_content = join($B, @buckets);
t_write_file($file, $file_content);


my @range_boundaries = (
    0, 1, 2,
    $blen-2,       $blen-1,       $blen,       $blen+1,
    3*$blen-2,     3*$blen-1,     3*$blen,     3*$blen+1,
    $clen-$blen-2, $clen-$blen-1, $clen-$blen, $clen-$blen+1,
    $clen-2, $clen-1,
);
my @test_cases;
for my $start (@range_boundaries) {
    for my $end (@range_boundaries) {
        push @test_cases, [$start, $end] unless ($end < $start);
    }
}

plan tests => scalar(@test_cases), need need_lwp,
                                   need_module('mod_bucketeer');

foreach my $test (@test_cases) {
    my ($start, $end) = @$test;
    my $r = "$start-$end";
    print "range: $r\n";
    my $result = GET $url, "Range" => "bytes=$r";
    my $expect = substr($content, $start, $end - $start + 1);
    my $got = $result->content;
    print("rc " . $result->code . "\n");
    print("expect: '$expect'\ngot:    '$got'\n");
    ok ($got eq $expect);
}
