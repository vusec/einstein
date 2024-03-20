#!perl

use strict;
use warnings FATAL=>'all';

use Test ();
use Config ();
unless ($Config::Config{useperlio}) {
    print "1..0 # need perlio\n";
    exit 0;
}

Test::plan tests=>8;

my $output;
{
    package X0;
    use Apache::Test;

    local ($Test::planned, $Test::ntest, %Test::todo);
    local *STDOUT;
    open STDOUT, '>', \$output;

    local $ENV{HTTPD_TEST_SUBTESTS}="";

    plan tests=>3;

    sok {1};
    sok {1};
    sok {1};
}
Test::ok $output=~/^ok 1$/m &&
         $output=~/^ok 2$/m &&
         $output=~/^ok 3$/m;

{
    package Y0;
    use Apache::Test qw/-withtestmore/;

    local *STDOUT;
    open STDOUT, '>', \$output;

    local $ENV{HTTPD_TEST_SUBTESTS}="";

    plan tests=>3;

    sok {1};
    sok {1};
    sok {1};
}
Test::ok $output=~/^ok 1$/m &&
         $output=~/^ok 2$/m &&
         $output=~/^ok 3$/m;

{
    package X0;

    local ($Test::planned, $Test::ntest, %Test::todo);
    local *STDOUT;
    open STDOUT, '>', \$output;

    local $ENV{HTTPD_TEST_SUBTESTS}="1 3";

    plan tests=>3;

    sok {1};
    sok {1};
    sok {1};
}
Test::ok $output=~/^ok 1$/m &&
         $output=~/^ok 2 # skip skipping this subtest$/mi &&
         $output=~/^ok 3$/m;

{
    package Y0;

    local *STDOUT;
    open STDOUT, '>', \$output;

    local $ENV{HTTPD_TEST_SUBTESTS}="1 3";

    plan tests=>3;

    sok {1};
    sok {1};
    sok {1};
}
Test::ok $output=~/^ok 1$/m &&
         $output=~/^ok 2 # skip skipping this subtest$/mi &&
         $output=~/^ok 3$/m;

{
    package X0;

    local ($Test::planned, $Test::ntest, %Test::todo);
    local *STDOUT;
    open STDOUT, '>', \$output;

    local $ENV{HTTPD_TEST_SUBTESTS}="";

    plan tests=>4;

    sok {1};
    sok {ok 1; 1} 2;
    sok {1};
}
Test::ok $output=~/^ok 1$/m &&
         $output=~/^ok 2$/m &&
         $output=~/^ok 3$/m &&
         $output=~/^ok 4$/m;

{
    package Y0;

    local *STDOUT;
    open STDOUT, '>', \$output;

    local $ENV{HTTPD_TEST_SUBTESTS}="";

    plan tests=>4;

    sok {1};
    sok {ok 1, "erwin"} 2;
    sok {1};
}
Test::ok $output=~/^ok 1$/m &&
         $output=~/^ok 2 - erwin$/m &&
         $output=~/^ok 3$/m &&
         $output=~/^ok 4$/m;

{
    package X0;

    local ($Test::planned, $Test::ntest, %Test::todo);
    local *STDOUT;
    open STDOUT, '>', \$output;

    local $ENV{HTTPD_TEST_SUBTESTS}="1 4";

    plan tests=>4;

    sok {1};
    sok {ok 1; 1} 2;
    sok {1};
}
Test::ok $output=~/^ok 1$/m &&
         $output=~/^ok 2 # skip skipping this subtest$/mi &&
         $output=~/^ok 3 # skip skipping this subtest$/mi &&
         $output=~/^ok 4$/m;

{
    package Y0;

    local *STDOUT;
    open STDOUT, '>', \$output;

    local $ENV{HTTPD_TEST_SUBTESTS}="1 4";

    plan tests=>4;

    sok {1};
    sok {ok 1} 2;
    sok {1};
}
Test::ok $output=~/^ok 1$/m &&
         $output=~/^ok 2 # skip skipping this subtest$/mi &&
         $output=~/^ok 3 # skip skipping this subtest$/mi &&
         $output=~/^ok 4$/m;
