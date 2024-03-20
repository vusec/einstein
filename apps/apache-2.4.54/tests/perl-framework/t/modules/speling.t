use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

my @testcasespaths = (
    ['/modules/speling/nocase/'], 
    ['/modules/speling/caseonly/'], 
);

my @testcases = (
    ## File        Test        CheckCaseOnly Off   On
    ['good.html',  "normal",                 200, 200], 
    ['god.html',   "omission",               301, 404],
    ['goood.html', "insertion",              301, 404],
    ['godo.html',  "transposition",          301, 404],
    ['go_d.html',  "wrong character",        301, 404],

    ['good.wrong_ext', "wrong extension",    300, 300],
    ['GOOD.wrong_ext', "NC wrong extension", 300, 300],

    ['Bad.html',  "wrong filename",          404, 404],
    ['dogo.html', "double transposition",    404, 404],
    ['XooX.html', "double wrong character",  404, 404],

    ['several0.html', "multiple choice",     300, 404],
);

# macOS HFS is case-insensitive but case-preserving so the below tests
# would cause misleading failures
if ($^O ne "darwin") {
    push (@testcases, ['GOOD.html',  "case",                   301, 301]);
}

plan tests => scalar @testcasespaths * scalar @testcases * 2, need 'mod_speling';

my $r;
my $code = 2;

# Disable redirect
local $Apache::TestRequest::RedirectOK = 0;

foreach my $p (@testcasespaths) {
    foreach my $t (@testcases) {
        ## 
        #local $Apache::TestRequest::RedirectOK = 0;
        $r = GET($p->[0] . $t->[0]);

        # Checking for return code
        ok t_cmp($r->code, $t->[$code], "Checking " . $t->[1] . ". Expecting: ". $t->[$code]);
        
        # Checking that the expected filename is in the answer
        if ($t->[$code] != 200 && $t->[$code] != 404) {
            ok t_cmp($r->content, qr/good\.html|several1\.html/, "Redirect ok");
        }
        else {
            skip "Skipping. No redirect with status " . $t->[$code];
        }
    }
    
    $code = $code+1;
}
