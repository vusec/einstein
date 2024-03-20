use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw/t_start_error_log_watch t_finish_error_log_watch/;

my $r;
my $line;
my $count = 0;
my $nb_seconds = 5;
# Because of timing, we may see less than what could be expected
my $nb_expected = $nb_seconds - 2;

plan tests => 1, sub { need_module('mod_heartbeat', 'mod_heartmonitor') && !need_apache_mpm('prefork') };

# Give some time to the heart to beat a few times
t_start_error_log_watch();
sleep($nb_seconds);
my @loglines = t_finish_error_log_watch();

# Heartbeat sent by mod_heartbeat and received by mod_heartmonitor are logged with DEBUG AH02086 message
foreach $line (@loglines) {
    if ($line =~ "AH02086") {
        $count++;
    }
}

print "Expecting at least " . $nb_expected . " heartbeat ; Seen: " . $count . "\n";
ok($count >= $nb_expected);
