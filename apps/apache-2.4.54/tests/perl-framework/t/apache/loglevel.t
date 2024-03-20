use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw/t_start_error_log_watch t_finish_error_log_watch/;

plan tests => 8, need_min_apache_version('2.3.6');

my $base = "/apache/loglevel";

t_start_error_log_watch();

my @error_expected =qw{
    core_info
    info
    crit/core_info
    info/core_crit/info
};
my @error_not_expected =qw{
    core_crit
    crit
    info/core_crit
    crit/core_info/crit
};

my $dir;
foreach $dir (@error_expected) {
    GET "$base/$dir/not_found_error_expected";
}
foreach $dir (@error_not_expected) {
    GET "$base/$dir/not_found_error_NOT_expected";
}

my @loglines = t_finish_error_log_watch();
my $log = join("\n", @loglines);

foreach $dir (@error_expected) {
  ok($log =~ m{does not exist.*?$base/$dir/not_found_error_expected});
}
foreach $dir (@error_not_expected) {
  ok($log !~ m{does not exist.*?$base/$dir/not_found_error_NOT_expected});
}
