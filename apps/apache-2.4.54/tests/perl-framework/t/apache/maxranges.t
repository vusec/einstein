use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_write_file);

# test multi-byterange-requests with overlaps (merges)

my $url = "/apache/chunked/byteranges.txt";
my $file = Apache::Test::vars('serverroot') . "/htdocs$url";

my $content = "";
$content .= sprintf("%04d", $_) for (1 .. 2000);
t_write_file($file, $content);
my $clen = length($content);


my $medrange = "";
my $longrange = "";
my $i;

for (0 .. 50) { 
 $longrange .= "0-1,3-4,0-1,3-4,";
 if ($_ % 2) { 
   $medrange .= "0-1,3-4,0-1,3-4,";
 }
}

my @test_cases = (
    { url => "/maxranges/default/byteranges.txt" , h => "0-100", status => "206"},
    { url => "/maxranges/default/byteranges.txt" , h => $medrange, status => "206"},
    { url => "/maxranges/default/byteranges.txt" , h => $longrange, status => "200"},

    { url => "/maxranges/default-explicit/byteranges.txt" , h => "0-100", status => "206"},
    { url => "/maxranges/default-explicit/byteranges.txt" , h => $medrange, status => "206"},
    { url => "/maxranges/default-explicit/byteranges.txt" , h => $longrange, status => "200"},

    { url => "/maxranges/none/byteranges.txt" ,       h => "0-100", status => "200"},
    { url => "/maxranges/none/byteranges.txt" ,       h => "$medrange", status => "200"},
    { url => "/maxranges/none/byteranges.txt" ,       h => "$longrange", status => "200"},

    { url => "/maxranges/1/merge/none/byteranges.txt" ,       h => "0-100", status => "200"},
    { url => "/maxranges/1/merge/none/byteranges.txt" ,       h => "$medrange", status => "200"},
    { url => "/maxranges/1/merge/none/byteranges.txt" ,       h => "$longrange", status => "200"},

    { url => "/maxranges/1/byteranges.txt" ,       h => "0-100", status => "206"},
    { url => "/maxranges/1/byteranges.txt" ,       h => "0-100,200-300", status => "200"},
    { url => "/maxranges/2/byteranges.txt" ,       h => "0-100,200-300", status => "206"},
    { url => "/maxranges/2/byteranges.txt" ,       h => "0-100,200-300,400-500", status => "200"},
    { url => "/maxranges/unlimited/byteranges.txt" ,       h => "0-100", status => "206"},
    { url => "/maxranges/unlimited/byteranges.txt" ,       h => "$medrange", status => "206"},
    { url => "/maxranges/unlimited/byteranges.txt" ,       h => "$longrange", status => "206"},

);
plan tests => scalar(@test_cases), need need_lwp, need_min_apache_version('2.3.15') || need_min_apache_version('2.2.21'),
              need_module('mod_alias');


foreach my $test (@test_cases) {
    my $result = GET $test->{"url"}, "Range" => "bytes=" . $test->{"h"} ;
    my $boundary;
    my $ctype = $result->header("Content-Type");
    if ($test->{"status"} ne $result->code()) { 
        print "Wrong status code: " . $result->code() ."\n";
        ok(0);
        next;
    }
    ok (1);
}
