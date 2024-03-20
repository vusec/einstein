use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my @testcases = (
    ['/modules/usertrack/foo.html'],
    ['/modules/usertrack/bar.html'],
    ['/modules/usertrack/foo.html'],
    ['/modules/usertrack/bar.html'],
);

my $iters = 100;
my %cookiex = ();

plan tests => (scalar (@testcases) * 2 + 2) * $iters + 1 + 3, need 'mod_usertrack';

foreach (1..$iters) {
    my $nb_req = 1;
    my $cookie = "";
    
    foreach my $t (@testcases) {
        ## 
        my $r = GET($t->[0], "Cookie" => $cookie);

        # Checking for return code
        ok t_cmp($r->code, 200, "Checking return code is '200'");

        # Checking for content
        my $setcookie = $r->header('Set-Cookie');

        # Only the first and third requests of an iteration must have a Set-Cookie
        if ((($nb_req == 1) || ($nb_req == 3)) && (defined $setcookie)) {
            ok defined $setcookie;

            print "Set-Cookie: " . $setcookie . "\n";
            # Copy the cookie in order to send it back in the next requests
            $cookie = substr($setcookie, 0, index($setcookie, ";") );
            print "Cookie: " . $cookie . "\n";

            # This cookie must not have been already seen
            ok !exists($cookiex{$cookie});
            $cookiex{$cookie} = 1;
        }
        else {
            ok !(defined $setcookie);
        }

        # After the 2nd request, we lie and send a modified cookie.
        # So the 3rd request whould receive a new cookie
        if ($nb_req == 2) {
            $cookie = "X" . $cookie;
        }

        $nb_req++;
    }
}

# Check the overall number of cookies generated
ok ((scalar (keys %cookiex)) == ($iters * 2));

# Check that opt-in flags aren't set
my $r = GET("/modules/usertrack/foo.html");
ok t_cmp($r->code, 200, "Checking return code is '200'");
# Checking for content
my $setcookie = $r->header('Set-Cookie');
t_debug("$setcookie");
ok defined $setcookie;
$setcookie =~ m/(Secure|HTTPonly|SameSite)/i;
ok t_cmp($1, undef);

 
