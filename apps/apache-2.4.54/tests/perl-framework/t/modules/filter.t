use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp t_write_file);
use File::Spec;

my @testcases = (
    ['/modules/cgi/xother.pl'           => 'HELLOWORLD'],
    ['/modules/filter/bytype/test.txt'  => 'HELLOWORLD'],
    ['/modules/filter/bytype/test.xml'  => 'HELLOWORLD'],
    ['/modules/filter/bytype/test.css'  => 'helloworld'],
    ['/modules/filter/bytype/test.html' => 'helloworld'],
);

plan tests => scalar @testcases, need need_cgi,
                 need_module('mod_filter'),
                 need_module('mod_case_filter');

foreach my $t (@testcases) {
    my $r = GET_BODY($t->[0]);
    chomp $r;
    ok t_cmp($r, $t->[1]);
}
