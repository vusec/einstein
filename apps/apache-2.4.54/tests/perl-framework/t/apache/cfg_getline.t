use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_write_file);

use File::Spec;

# test ap_cfg_getline / ap_varbuf_cfg_getline

Apache::TestRequest::user_agent(keep_alive => 1);

my $dir_foo = Apache::Test::vars('serverroot') . '/htdocs/cfg_getline';

# XXX: htaccess is limited to 8190 chars, would need different test
# XXX: method to test longer lines
my @test_cases = (100, 196 .. 202, 396 .. 402 , 596 .. 602 , 1016 .. 1030,
                  8170 .. 8190);
plan tests => 2 * scalar(@test_cases), need need_lwp,
                                       need_module('mod_include'),
                                       need_module('mod_setenvif');

foreach my $len (@test_cases) {
    my $prefix = 'SetEnvIf User-Agent ^ testvar=';
    my $expect = 'a' x ($len - length($prefix));
    my $file = File::Spec->catfile(Apache::Test::vars('serverroot'), 'htdocs',
                                   'apache', 'cfg_getline', '.htaccess');
    t_write_file($file, "$prefix$expect\n");

    my $response = GET('/apache/cfg_getline/index.shtml');
    my $rc = $response->code;
    print "Got rc $rc for length $len\n";
    ok($rc == 200);

    my $got = $response->content;
    my $match;
    if ($got =~ /^'$expect'/) {
        $match = 1;
    }
    else {
        print "Got      $got\n",
              "expected '$expect'\n";
    }
    ok($match);
}
