use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;
use File::stat;

my $have_apache_2 = have_apache 2;
my $have_apache_2050 = have_min_apache_version "2.0.50";

my $script_log_length = 40960;

## mod_cgi test
##
## extra.conf.in:
## <IfModule mod_cgi.c>
## AddHandler cgi-script .sh
## AddHandler cgi-script .pl
## ScriptLog logs/mod_cgi.log
## ScriptLogLength 40960
## ScriptLogBuffer 256
## <Directory @SERVERROOT@/htdocs/modules/cgi>
## Options +ExecCGI
## [some AcceptPathInfo stuff]
## </Directory>
## </IfModule>
## 

my @post_content = (10, 99, 250, 255, 256, 257, 258, 1024);

my %test = (
    'perl.pl' => {
        'rc' => 200,
        'expect' => 'perl cgi'
    },
    'bogus-perl.pl' => {
        'rc' => 500,
        'expect' => 'none'
    },
    'nph-test.pl' => {
        'rc' => 200,
        'expect' => 'ok'
    },
    'sh.sh' => {
        'rc' => 200,
        'expect' => 'sh cgi'
    },
    'bogus-sh.sh' => {
        'rc' => 500,
        'expect' => 'none'
    },
    'acceptpathinfoon.sh' => {
        'rc' => 200,
        'expect' => ''
    },
    'acceptpathinfoon.sh/foo' => {
        'rc' => 200,
        'expect' => '/foo'
    },
    'acceptpathinfooff.sh' => {
        'rc' => 200,
        'expect' => ''
    },
    'acceptpathinfooff.sh/foo' => {
        'rc' => 404,
        'expect' => 'none'
    },
    'acceptpathinfodefault.sh' => {
        'rc' => 200,
        'expect' => ''
    },
    'acceptpathinfodefault.sh/foo' => {
        'rc' => 200,
        'expect' => '/foo'
    },
    'stderr1.pl' => {
        'rc' => 200,
        'expect' => 'this is stdout'
    },
    'stderr2.pl' => {
        'rc' => 200,
        'expect' => 'this is also stdout'
    },
    'stderr3.pl' => {
        'rc' => 200,
        'expect' => 'this is more stdout'
    },
    'nph-stderr.pl' => {
        'rc' => 200,
        'expect' => 'this is nph-stdout'
    },
);

#XXX: find something that'll on other platforms (/bin/sh aint it)
if (Apache::TestConfig::WINFU()) {
    delete @test{qw(sh.sh bogus-sh.sh)};
}
if (Apache::TestConfig::WINFU() || !$have_apache_2) {
    delete @test{qw(acceptpathinfoon.sh acceptpathinfoon.sh/foo)};
    delete @test{qw(acceptpathinfooff.sh acceptpathinfooff.sh/foo)};
    delete @test{qw(acceptpathinfodefault.sh acceptpathinfodefault.sh/foo)};
}

# CGI stderr handling works in 2.0.50 and later only on Unixes.
if (!$have_apache_2050 || Apache::TestConfig::WINFU()) {
    delete @test{qw(stderr1.pl stderr2.pl stderr3.pl nph-stderr.pl)};
}

my $tests = ((keys %test) * 2) + (@post_content * 3) + 4;
plan tests => $tests, \&need_cgi;

my ($expected, $actual);
my $path = "/modules/cgi";
my $vars = Apache::Test::vars();
my $t_logs = $vars->{t_logs};
my $cgi_log = "$t_logs/mod_cgi.log";
my ($bogus,$log_size,$stat) = (0,0,0);

unlink $cgi_log if -e $cgi_log;

foreach (sort keys %test) {
    $expected = $test{$_}{rc};
    $actual = GET_RC "$path/$_";
    ok t_cmp($actual,
             $expected,
             "return code for $_"
            );

    if ($test{$_}{expect} ne 'none') {
        $expected = $test{$_}{expect};
        $actual = GET_BODY "$path/$_";
        chomp $actual if $actual =~ /\n$/;

        ok t_cmp($actual,
                 $expected,
                 "body for $_"
                );
    }
    elsif ($_ !~ /^bogus/) {
        print "# no body test for this one\n";
        ok 1;
    }

    ## verify bogus cgi's get handled correctly
    ## logging to the cgi log
    if ($_ =~ /^bogus/) {
        $bogus++;
        if ($bogus == 1) {

            ## make sure cgi log got created, get size.
            if (-e $cgi_log) {
                print "# cgi log created ok.\n";
                ok 1;
                $stat = stat($cgi_log);
                $log_size = $$stat[7];
            } else {
                print "# error: cgi log not created!\n";
                ok 0;
            }
        } else {

            ## make sure log got bigger.
            if (-e $cgi_log) {
                $stat = stat($cgi_log);
                print "# checking that log size ($$stat[7]) is bigger than it used to be ($log_size)\n";
                ok ($$stat[7] > $log_size);
                $log_size = $$stat[7];
            } else {
                print "# error: cgi log does not exist!\n";
                ok 0;
            }
        }
    }
}

## post lots of content to a bad cgi, so we can verify
## ScriptLogBuffer is working.
my $content = 0;
foreach my $length (@post_content) {
    $content++;
    $expected = '500';
    $actual = POST_RC "$path/bogus-perl.pl", content => "$content"x$length;

    print "# posted content (length $length) to bogus-perl.pl\n";
    ## should get rc 500
    ok t_cmp($actual, $expected, "POST to $path/bogus-perl.pl [content: $content x $length]");

    if (-e $cgi_log) {
        ## cgi log should be bigger.
        ## as long as it's under ScriptLogLength
        $stat = stat($cgi_log);
        if ($log_size < $script_log_length) {
            print "# checking that log size ($$stat[7]) is greater than $log_size\n";
            ok ($$stat[7] > $log_size);
        } else {
            ## should not fall in here at this point,
            ## but just in case...
            print "# verifying log did not increase in size...\n";
            ok t_cmp($$stat[7], $log_size, "log size should not have increased");
        }
        $log_size = $$stat[7];
    
        ## there should be less than ScriptLogBuffer (256)
        ## characters logged from the post content
        open (LOG, $cgi_log) or die "died opening cgi log: $!";
        my $multiplier = 256;
        my $log;
        {
            local $/;
            $log = <LOG>;
        }
        close (LOG);
        $multiplier = $length unless $length > $multiplier;
        print "# verifying that logged content is $multiplier characters\n";
        if ($log =~ /^(?:$content){$multiplier}\n?$/m) {
            ok 1;
        }
        else {
            $log =~ s{^}{# }m;
            print "# no log line found with $multiplier '$content' characters\n";
            print "# log is:\n'$log'\n";
            ok 0;
        }
    } else {
        ## log does not exist ##
        print "# cgi log does not exist, test fails.\n";
        ok 0;
    }
}

## make sure cgi log does not 
## keep logging after it is bigger
## than ScriptLogLength
for (my $i=1 ; $i<=40 ; $i++) {

    ## get out if log does not exist ##
    last unless -e $cgi_log;

    ## request the 1k bad cgi
    ## (1k of data logged per request)
    GET_RC "$path/bogus1k.pl";

    ## when log goes over max size stop making requests
    $stat = stat($cgi_log);
    $log_size = $$stat[7];
    last if ($log_size > $script_log_length);

}
## make sure its over (or equal) our ScriptLogLength
print "# verifying log is greater than $script_log_length bytes.\n";
ok ($log_size >= $script_log_length);

## make sure it does not grow now.
GET_RC "$path/bogus1k.pl";
print "# verifying log did not grow after making bogus request.\n";
if (-e $cgi_log) {
    $stat = stat($cgi_log);
    ok ($log_size eq $$stat[7]);
} else {
    print "# log does not exist!\n";
    ok 0;
}

GET_RC "$path/bogus-perl.pl";
print "# verifying log did not grow after making another bogus request.\n";
if (-e $cgi_log) {
    $stat = stat($cgi_log);
    ok ($log_size eq $$stat[7]);
} else {
    print "# log does not exist!\n";
    ok 0;
}

print "# checking that HEAD $path/perl.pl returns 200.\n";
ok HEAD_RC("$path/perl.pl") == 200;

## clean up
unlink $cgi_log;
