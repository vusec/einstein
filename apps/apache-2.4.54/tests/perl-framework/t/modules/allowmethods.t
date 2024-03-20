use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

my $r;
my $get = "Get";
my $head = "Head";
my $post = "Post";
my $options = "Options";

##
## mod_allowmethods test
##
my @test_cases = (
    [ $get, $get, 200 ],
    [ $head, $get, 200 ],
    [ $post, $get, 405 ],
    [ $get, $head, 200 ],
    [ $head, $head, 200 ],
    [ $post, $head, 405 ],
    [ $get, $post, 405 ],
    [ $head, $post, 405 ],
    [ $post, $post, 200 ],
);

my @new_test_cases = (
    [ $get, $post . '/reset', 200 ],
    [ $post, $get . '/post', 200 ],
    [ $get, $get . '/post', 200 ],
    [ $options, $get . '/post', 405 ],
    [ $get, $get . '/none', 405 ],
    [ $get, "NoPost", 200 ],
    [ $post, "NoPost", 405 ],
    [ $options, "NoPost" , 200 ],
);

if (have_min_apache_version('2.5.1')) { 
    push(@test_cases, @new_test_cases);
}

plan tests => (scalar @test_cases), have_module 'allowmethods';

foreach my $case (@test_cases) {
    my ($fct, $allowed, $rc) = @{$case};

    if ($fct eq $get) {
        $r = GET('/modules/allowmethods/' . $allowed . '/');
    }
    elsif ($fct eq $head) {
        $r = HEAD('/modules/allowmethods/' . $allowed . '/');
    }
    elsif ($fct eq $post) {
        $r = POST('/modules/allowmethods/' . $allowed . '/foo.txt');
    }
    elsif ($fct eq $options) {
        $r = OPTIONS('/modules/allowmethods/' . $allowed . '/');
    }

    ok t_cmp($r->code, $rc, "$fct request to /$allowed responds $rc");
}

