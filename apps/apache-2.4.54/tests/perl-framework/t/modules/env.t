use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

##
## mod_env tests
##

my %test = (
    'host' => $ENV{APACHE_TEST_HOSTNAME},
    'set' => "mod_env test environment variable",
    'setempty' => '',
    'unset' => '(none)',
    'type' => '(none)',
    'nothere' => '(none)'
);

if (Apache::TestConfig::WIN32) {
    #what looks like a bug in perl 5.6.1 prevents %ENV
    #settings to be inherited by process created with
    #Win32::Process::Create.  the test works fine if APACHE_TEST_HOSTNAME
    #is set in the command shell environment
    delete $test{'host'};
}

plan tests => (keys %test) * 1, need_module('env', 'include');

my ($actual, $expected);
foreach (sort keys %test) {
    $expected = $test{$_};
    sok {
        $actual = GET_BODY "/modules/env/$_.shtml";
        $actual =~ s/[\r\n]+$//s;
        print "# $_: /modules/env/$_.shtml\n",
              "# $_: EXPECT ->$expected<- ACTUAL ->$actual<-\n";
        return $actual eq $expected;
    };
}
