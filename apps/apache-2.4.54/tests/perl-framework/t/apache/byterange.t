use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest ();
use Apache::TestCommon ();

Apache::TestCommon::run_files_test(\&verify, 1);

sub verify {
    my($ua, $url, $file) = @_;
    my $debug = $Apache::TestRequest::DebugLWP;

    $url = Apache::TestRequest::resolve_url($url);
    my $req = HTTP::Request->new(GET => $url);

    my $total = 0;
    my $chunk_size = 8192;

    my $wanted = -s $file;

    while ($total < $wanted) {
        my $end = $total + $chunk_size;
        if ($end > $wanted) {
            $end = $wanted;
        }

        my $range = "bytes=$total-$end";
        $req->header(Range => $range);

        print $req->as_string if $debug;

        my $res = $ua->request($req);
        my $content_range = $res->header('Content-Range') || 'NONE';

        $res->content("") if $debug and $debug == 1;
        print $res->as_string if $debug;

        if ($content_range =~ m:^bytes\s+(\d+)-(\d+)/(\d+):) {
            my($start, $end, $total_bytes) = ($1, $2, $3);
            $total += ($end - $start) + 1;
        }
        elsif ($total == 0 && $end == $wanted &&
               $content_range eq 'NONE' && $res->code == 200) {
               $total += $wanted;
        }
        else {
            print "Range:         $range\n";
            print "Content-Range: $content_range\n";
            last;
        }
    }

    print "downloaded $total bytes, file is $wanted bytes\n";

    ok $total == $wanted;
}
