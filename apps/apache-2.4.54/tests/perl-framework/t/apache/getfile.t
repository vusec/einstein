use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest ();
use Apache::TestCommon ();

Apache::TestCommon::run_files_test(\&verify);

sub verify {
    my($ua, $url, $file) = @_;

    my $flen = -s $file;
    my $received = 0;

    $ua->do_request(GET => $url,
                    sub {
                        my($chunk, $res) = @_;
                        $received += length $chunk;
                    });

    ok t_cmp($received, $flen, "download of $url");
}
