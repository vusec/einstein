use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

use File::Spec::Functions qw(catfile splitpath);

Apache::TestRequest::scheme('http'); #ssl not listening on this vhost
Apache::TestRequest::module('mod_include'); #use this module's port

use constant WINFU => Apache::TestConfig::WINFU;

## mod_include tests
my($res, $str, $doc);
my $dir = "/modules/include/";
my $have_apache_1 = have_apache 1;
my $have_apache_2 = have_apache 2;
my $have_apache_21 = have_min_apache_version "2.1.0";
my $have_apache_20 = $have_apache_2 && ! $have_apache_21;
my $htdocs = Apache::Test::vars('documentroot');

# these match the SSI files with their expected results.
# the expectations are set by the current 2.1 mod_include
# implementation.

my %test = (
"echo.shtml"            =>    "echo.shtml",
"set.shtml"             =>    "set works",
"comment.shtml"         =>    "No  comment  here",
"include1.shtml"        =>    "inc-two.shtml body  include.shtml body",
"include2.shtml"        =>    "inc-two.shtml body  include.shtml body",
"include3.shtml"        =>    "inc-two.shtml body  inc-one.shtml body  ".
                              "include.shtml body",
"include4.shtml"        =>    "inc-two.shtml body  inc-one.shtml body  ".
                              "include.shtml body",
"include5.shtml"        =>    "inc-two.shtml body  inc-one.shtml body  ".
                              "inc-three.shtml body  include.shtml body",
"include6.shtml"        =>    "inc-two.shtml body  inc-one.shtml body  ".
                              "inc-three.shtml body  include.shtml body",
"foo.shtml"             =>    "[an error occurred while processing this ".
                              "directive] foo.shtml body",
"foo1.shtml"            =>    "[an error occurred while processing this ".
                              "directive] foo.shtml body",
"foo2.shtml"            =>    "[an error occurred while processing this ".
                              "directive] foo.shtml body",
"encode.shtml"          =>    "\# \%\^ \%23\%20\%25\%5e",
"errmsg1.shtml"         =>    "errmsg",
"errmsg2.shtml"         =>    "errmsg",
"errmsg3.shtml"         =>    "errmsg",
"errmsg4.shtml"         =>    "pass errmsg",
"errmsg5.shtml"         =>    "<!-- pass -->",
"if1.shtml"             =>    "pass",
"if2.shtml"             =>    "pass   pass",
"if3.shtml"             =>    "pass   pass   pass",
"if4.shtml"             =>    "pass   pass",
"if5.shtml"             =>    "pass  pass  pass",
"if6.shtml"             =>    "[an error occurred while processing this ".
                              "directive]",
"if7.shtml"             =>    "[an error occurred while processing this ".
                              "directive]",
"if8.shtml"             =>    "pass",
"if9.shtml"             =>    "pass   pass",
"if10.shtml"            =>    "pass",
"if11.shtml"            =>    "pass",
"big.shtml"             =>    "hello   pass  pass   pass     hello",
"newline.shtml"         =>    "inc-two.shtml body",
"inc-rfile.shtml"       =>    "inc-extra2.shtml body  inc-extra1.shtml body  ".
                              "inc-rfile.shtml body",
"inc-rvirtual.shtml"    =>    "inc-extra2.shtml body  inc-extra1.shtml body  ".
                              "inc-rvirtual.shtml body",
"extra/inc-bogus.shtml" =>    "[an error occurred while processing this ".
                              "directive] inc-bogus.shtml body",
"abs-path.shtml"        =>    "inc-extra2.shtml body  inc-extra1.shtml body  ".
                              "abs-path.shtml body",
"parse1.shtml"          =>    "-->",
"parse2.shtml"          =>    '"',
"regex.shtml"           =>    "(none)  1 (none)",
"retagged1.shtml"       =>    ["retagged1.shtml",                   "retagged1"],
"retagged2.shtml"       =>    ["----retagged2.shtml",               "retagged1"],
"echo1.shtml"           =>    ["<!-- pass undefined echo -->",      "echo1"    ],
"echo2.shtml"           =>    ["<!-- pass undefined echo -->  pass  config ".
                              " echomsg  pass", "echo1"],
"echo3.shtml"           =>    ['<!--#echo var="DOCUMENT_NAME" -->', "retagged1"], 
"notreal.shtml"         =>    "pass <!--",
"malformed.shtml"       =>    "[an error occurred while processing this ".
                              "directive] malformed.shtml",
"exec/off/cmd.shtml"    =>    "[an error occurred while processing this ".
                              "directive]",
"exec/on/cmd.shtml"     =>    "pass",
"exec/off/cgi.shtml"    =>    "[an error occurred while processing this ".
                              "directive]",
"exec/on/cgi.shtml"     =>    "perl cgi",
"ranged-virtual.shtml"  =>    "x"x32768,
"var128.shtml"          =>    "x"x126 . "yz",  # PR#32985
"virtualq.shtml?foo=bar" =>   "foo=bar  pass    inc-two.shtml body  foo=bar", # PR#12655

"inc-nego.shtml"        =>    "index.html.en", # requires mod_negotiation
"mod_request/echo.shtml"=>    "echo.shtml",
"mod_request/post.shtml?foo=bar&foo2=bar2"
                        =>    "GET foo: bar foo2: bar2",
"mod_request/post.shtml"=>    "POST foo: bar foo2: bar2",   # will be twice, only the first one succeed
);

my %ap_expr_test = (
"apexpr/if1.shtml"      =>    "pass",
"apexpr/err.shtml"      =>    "[an error occurred while processing this ".
                              "directive] err.shtml",
"apexpr/restrict.shtml" =>    "[an error occurred while processing this ".
                              "directive] restrict.shtml",
"apexpr/var.shtml"      =>    "pass   pass   pass",
"apexpr/lazyvar.shtml"  =>    "pass",
);

if (have_min_apache_version "2.3.13") {
    %test = (%test, %ap_expr_test);
}

# now, assuming 2.1 has the proper behavior across the board,
# let's adjust our expectations for other versions

# these tests are known to be broken in 2.0
# we'll mark them as TODO tests in the hopes
# that the 2.1 fixes will be backported

my %todo = (
);

# some behaviors will never be backported, for various
# reasons.  these are the 1.3 legacy tests and expectations
my %legacy_1_3 = (
"errmsg4.shtml"         =>    "pass",
"malformed.shtml"       =>    "",
"if6.shtml"             =>    "",
"if7.shtml"             =>    "",
);

# 2.0 has no legacy tests at the moment
# but when it does, they will go here
my %legacy_2_0 = ();

# ok, now that we have our hashes established, here are
# the manual tweaks
if ($have_apache_1) {
    # apache 1.3 uses different semantics for some
    # of the if.*shtml tests to achieve the same results
    $test{"if8a.shtml"}  = delete $test{"if8.shtml"};
    $test{"if9a.shtml"}  = delete $test{"if9.shtml"};
    $test{"if10a.shtml"} = delete $test{"if10.shtml"};

    # while other tests are for entirely new behaviors
    # and don't make sense to test at all in 1.3
    delete $test{"echo1.shtml"};
    delete $test{"echo2.shtml"};
    delete $test{"echo3.shtml"};
    delete $test{"retagged1.shtml"};
    delete $test{"retagged2.shtml"};
    delete $test{"regex.shtml"};

    # finally, these tests are only broken in 1.3
    $todo{"notreal.shtml"} = delete $test{"notreal.shtml"};
}

unless ($have_apache_20) {
    # these tests are broken only in 2.0 - 
    # in 1.3 they work fine so shift them from %todo to %test

    # none at the moment, but the syntax here would be
    # $test{"errmsg5.shtml"} = delete $todo{"errmsg5.shtml"};
}

unless (have_min_apache_version "2.0.53") {
    # this test doesn't work in 2.0 yet but should work in 1.3 and 2.1
    delete $test{"ranged-virtual.shtml"};
}

unless ($have_apache_21) {
    # apache 1.3 and 2.0 do not support these tests
    delete $test{"echo2.shtml"};
}

unless (have_module 'mod_negotiation') {
    delete $test{"inc-nego.shtml"};
}

# this test does not work on win32 (<!--#exec cmd="echo pass"-->)
if (WINFU) {
    delete $test{'exec/on/cmd.shtml'};
}

my @patterns = (
    'mod_include test',
    'Hello World',
    'footer',
);

# with the tweaks out of the way, we can get on
# with planning the tests

# first, total the number of hashed tests
# note that some legacy tests will redefine the main
# %test hash, so the total is not necessarily the sum
# of all the keys 
my %tests = ();

if ($have_apache_21) {
    %tests = (%test, %todo);
}
elsif ($have_apache_2) {
    %tests = (%test, %todo, %legacy_2_0);
}
else {
    %tests = (%test, %todo, %legacy_1_3);
}

# now for the TODO tests
my @todo = ();
unless ($have_apache_21) {
    # if 1.3 or 2.0, dynamically determine which of %test
    # will end up being TODO tests.  

    my $counter = 0;
    foreach my $test (sort keys %tests) {
      $counter++;
      push @todo, $counter if $todo{$test};
    }
}

unless ($have_apache_2) {
    # fsize comes immediately after the hashed tests
    push @todo, (scalar keys %tests) + 1;
}

# in addition to %tests, there are 1 mod_request expected failure,
# 1 fsize and 1 flastmod test,
# 1 GET test, 2 query string tests, 14 XBitHack tests and 14 
# tests that use mod_bucketeer to construct brigades for mod_include

my $tests = (scalar keys %tests) + 1 + @patterns + 1 + 1 + 1 + 2 + 14 + 14;

plan tests => $tests,
              todo => \@todo,
              need 'DateTime', need_lwp, need_module 'include';

foreach $doc (sort keys %tests) {
    # do as much from %test as we can
    if (ref $tests{$doc}) {
        ok t_cmp(super_chomp(GET_BODY "$dir$doc", Host => $tests{$doc}[1]),
                 $tests{$doc}[0],
                 "GET $dir$doc"
                );
    }
    elsif ($doc =~ m/ranged/) {
        if (have_cgi) {
            ok t_cmp(GET_BODY("$dir$doc", Range => "bytes=0-"),
                     $tests{$doc},
                     "GET $dir$doc with Range"
                     );
        }
        else {
            skip "Skipping virtual-range test; no cgi module", 1;
        }
    }
    elsif ($doc =~ m/cgi/) {
        if (have_cgi) {
            ok t_cmp(super_chomp(GET_BODY "$dir$doc"),
                     $tests{$doc},
                     "GET $dir$doc"
                    );
        }
        else {
            skip "Skipping 'exec cgi' test; no cgi module.", 1;
        }
    }
    elsif ($doc =~ m/mod_request.*\?/) {
        # param in the url ==> use GET
        if (have_cgi) {
            ok t_cmp(super_chomp(GET_BODY "$dir$doc"),
                     $tests{$doc},
                     "GET $dir$doc"
                    );
        }
        else {
            skip "Skipping 'exec cgi' test; no cgi module.", 1;
        }
    }
    elsif ($doc =~ m/mod_request/) {
        # no param in the url ==> use POST with a content
        if (have_cgi) {
            ok t_cmp(super_chomp(POST_BODY "$dir$doc", content => "foo=bar&foo2=bar2"),
                     $tests{$doc},
                     "POST $dir$doc"
                    );
            if ($doc =~ m/mod_request.*post/) {
                # KeptBodySize is 32
                my $r = POST("$dir$doc", content => "foo=bar&foo2=bar2&foo3=bar3&foo4=bar4");
                ok t_cmp($r->code, 413, "sizeof(body) > KeptBodySize");
            }
        }
        else {
            skip "Skipping 'exec cgi' test; no cgi module.", 2;
        }
    }
    else {
        ok t_cmp(super_chomp(GET_BODY "$dir$doc"),
                 $tests{$doc},
                 "GET $dir$doc"
                );
    }
}

### FLASTMOD/FSIZE TESTS

# marked as TODO in 1.3 - hoping for a format backport
{
    my $file = catfile($htdocs, splitpath($dir), "size.shtml");
    my $size = (stat $file)[7];

    # round perl's stat size for <!--#config sizefmt="abbrev"-->
    # this assumes the size of size.shtml is such that it is
    # rendered in K (which it is).  if size.shtml is made much
    # larger or smaller this formatting will need to change too
    my $abbrev = sprintf("%.1fK", $size/1024);

    # and commify for <!--#config sizefmt="bytes"-->
    my $bytes = commify($size);

    my $expected = join ' ', $bytes, $bytes, $abbrev, $abbrev;

    my $result = super_chomp(GET_BODY "${dir}size.shtml");

    # trim output
    $result =~ s/X//g;   # the Xs were there just to pad the filesiez
    $result = single_space($result);

    ok t_cmp("$result",
             "$expected",
             "GET ${dir}size.shtml"
            );
}

unless(eval "require POSIX") {
    skip "POSIX module not found", 1;
}
else {
    # use DateTime and avoid the system locale messing things up
    use DateTime;
    # Only for checking, whether system strftime supports %s
    use POSIX;
    my $strftime_gnu = (POSIX::strftime("%s", gmtime()) eq '%s' ? 0 : 1);

    my $result = super_chomp(GET_BODY "${dir}file.shtml");
    $result = single_space($result);

    my $httpdtz = $1 if $result =~ /\w+, \d+-\w+-\d+ \d+:\d+:\d+ (\w+) /;

    my $file = catfile($htdocs, splitpath($dir), "file.shtml");
    my $mtime = (stat $file)[9];

    my $dt = DateTime->from_epoch( epoch => $mtime,
                locale => 'en_US', time_zone => $httpdtz||'UTC' );
    
    my $expected = join ' ' =>
        $dt->strftime("%A, %B %e, %G"),
        $dt->strftime("%A, %B %e, %G"),
        $strftime_gnu ? $dt->strftime("%s") : '%s',
        $strftime_gnu ? $dt->strftime("%s") : '%s';

    # trim output
    $expected = single_space($expected);

    ok t_cmp("$result",
             "$expected",
             "GET ${dir}file.shtml"
            );
}

# some tests that can't be easily assimilated

$doc = "printenv.shtml";
ok t_cmp(GET("$dir$doc")->code,
         "200",
         "GET $dir$doc"
        );

### test include + query string
$res = GET "${dir}virtual.shtml";

ok $res->is_success;

$str = $res->content;

ok $str;

for my $pat (@patterns) {
    ok t_cmp($str, qr/$pat/, "/$pat/");
}

### MOD_BUCKETEER+MOD_INCLUDE TESTS
if (WINFU) {
    for (1..13) {
        skip "Skipping XBitHack tests on this platform", 1;
    }
}
else {
    ### XBITHACK TESTS
    # test xbithack off
    $doc = "xbithack/off/test.html";
    foreach ("0444", "0544", "0554") {
        chmod oct($_), "$htdocs/$dir$doc";
        ok t_cmp(super_chomp(GET_BODY "$dir$doc"),,
                 "<BODY> <!--#include virtual=\"../../inc-two.shtml\"--> </BODY>",
                 "XBitHack off [$_]"
                );
    }

    # test xbithack on
    $doc = "xbithack/on/test.html";
    chmod 0444, "$htdocs$dir$doc";
    ok t_cmp(super_chomp(GET_BODY "$dir$doc"),
             "<BODY> <!--#include virtual=\"../../inc-two.shtml\"--> </BODY>",
             "XBitHack on [0444]"
            );

    foreach ("0544", "0554") {
        chmod oct($_), "$htdocs/$dir$doc";
        ok t_cmp(check_xbithack(GET "$dir$doc"),
                 "No Last-modified date ; <BODY> inc-two.shtml body  </BODY>",
                 "XBitHack on [$_]"
                );
    }

    # test timefmt - make sure filter only inserted once
    # if Option Include and xbithack both say to process
    $doc = "xbithack/both/timefmt.shtml";
    my @now = localtime();
    my $year = $now[5] + 1900;
    chmod 0555, "$htdocs/$dir$doc";
    ok t_cmp(super_chomp(GET_BODY "$dir$doc"),
             "xx${year}xx",
             "XBitHack both [timefmt]"
             );

    # test xbithack full
    $doc = "xbithack/full/test.html";
    chmod 0444, "$htdocs/$dir$doc";
    ok t_cmp(super_chomp(GET_BODY "$dir$doc"),
             "<BODY> <!--#include virtual=\"../../inc-two.shtml\"--> </BODY>",
             "XBitHack full [0444]"
            );
    chmod 0544, "$htdocs/$dir$doc";
    ok t_cmp(check_xbithack(GET "$dir$doc"),
             "No Last-modified date ; <BODY> inc-two.shtml body  </BODY>",
             "XBitHack full [0544]"
            );

    my $lm;

    chmod 0554, "$htdocs/$dir$doc";
    ok t_cmp(check_xbithack(GET("$dir$doc"), \$lm),
             "Has Last-modified date ; <BODY> inc-two.shtml body  </BODY>",
             "XBitHack full [0554]"
            );

    ok t_cmp(check_xbithack_etag(GET("$dir$doc", 'If-Modified-Since' => $lm)),
             "No ETag ; ",
             "XBitHack full [0554] / ETag"
            );

    ok t_cmp(GET("$dir$doc", 'If-Modified-Since' => $lm)->code, 304,
             "XBitHack full [0554] / If-Modified-Since"
            );

    chmod 0544, "$htdocs/$dir$doc";
    ok t_cmp(GET("$dir$doc", 'If-Modified-Since' => $lm)->code, 200,
             "XBitHack full [0544] / If-Modified-Since"
            );

    ok t_cmp(check_xbithack_etag(GET("$dir$doc", 'If-Modified-Since' => $lm)),
             "No ETag ; <BODY> inc-two.shtml body  </BODY>",
             "XBitHack full [0544] / ETag"
            );
}

# we can use mod_bucketeer to create edge conditions for mod_include, since
# it allows us to create bucket and brigade boundaries wherever we want
if (have_module 'mod_bucketeer') {

    my $expected = "____ _____ _____ ___________________ </table>  ".
                   "##################################1/8</tr> ".
                   "##################################2/8</tr> ".
                   "##################################3/8</tr> ".
                   "##################################4/8</tr> ".
                   "##################################5/8</tr> ".
                   "##################################6/8$htdocs</tr> ".
                   "##################################7/8</tr> ".
                   "##################################8/8</tr> ".
                   "@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@";

    $doc = "bucketeer/y.shtml";
    ok t_cmp(super_chomp(GET_BODY "$dir$doc"),
             $expected,
             "GET $dir$doc"
            );

    $expected = "____ ___________________________________".
                "________________________________________".
                "___ ____________________________________".
                "________________________________________".
                "__________ ___________________ </table>  ".
                "#####################################</tr> ".
                "#####################################</tr> ".
                "#####################################</tr> ".
                "#####################################</tr> ".
                "#####################################</tr> ".
                "#####################################</tr> ".
                "#####################################</tr> ".
                "#####################################</tr> ".
                "@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@";

    for (0..3) {
        $doc = "bucketeer/y$_.shtml";
        my ($body) = super_chomp(GET_BODY "$dir$doc");
        $body =~ s/\002/^B/g;
        $body =~ s/\006/^F/g;
        $body =~ s/\020/^P/g;
        ok t_cmp($body,
                 $expected,
                 "GET $dir$doc"
                );
    }

    $expected = "[an error occurred while processing this directive]";
    $doc = "bucketeer/y4.shtml";
    ok t_cmp(super_chomp(GET_BODY "$dir$doc"),
             $expected,
             "GET $dir$doc"
            );


    $expected= "pass [an error occurred while processing this directive]  ".
               "pass pass1";
    $doc = "bucketeer/y5.shtml";
    ok t_cmp(super_chomp(GET_BODY "$dir$doc"),
             $expected,
             "GET $dir$doc"
            );

    $expected= "BeforeIfElseBlockAfterIf";
    $doc = "bucketeer/y6.shtml";
    ok t_cmp(super_chomp(GET_BODY "$dir$doc"),
             $expected,
             "GET $dir$doc"
            );

    $expected= "Before If <!-- comment -->SomethingElse".
               "<!-- right after if -->After if";
    $doc = "bucketeer/y7.shtml";
    ok t_cmp(super_chomp(GET_BODY "$dir$doc"),
             $expected,
             "GET $dir$doc"
            );

    $expected= "FalseSetDone";
    $doc = "bucketeer/y8.shtml";
    ok t_cmp(super_chomp(GET_BODY "$dir$doc"),
             $expected,
             "GET $dir$doc"
            );

    $expected= "FalseSetDone";
    $doc = "bucketeer/y9.shtml";
    ok t_cmp(super_chomp(GET_BODY "$dir$doc"),
             $expected,
             "GET $dir$doc"
            );

    $expected= "\"pass\"";
    $doc = "bucketeer/y10.shtml";
    ok t_cmp(super_chomp(GET_BODY "$dir$doc"),
             $expected,
             "GET $dir$doc"
            );

    ### exotic SSI(Start|End)Tags

    $expected= "----retagged3.shtml";
    $doc = "bucketeer/retagged3.shtml";
    ok t_cmp(super_chomp(GET_BODY "$dir$doc", Host => 'retagged1'),
             $expected,
             "GET $dir$doc"
            );

    $expected= "---pass";
    $doc = "bucketeer/retagged4.shtml";
    ok t_cmp(super_chomp(GET_BODY "$dir$doc", Host => 'retagged2'),
             $expected,
             "GET $dir$doc"
            );
}
else {
    for (1..14) {
        skip "Skipping bucket boundary tests, no mod_bucketeer", 1;
    }
}

sub super_chomp {
    my ($body) = shift;

    ## super chomp - all leading and trailing \n (and \r for win32)
    $body =~ s/^[\n\r]*//;
    $body =~ s/[\n\r]*$//;
    ## and all the rest change to spaces
    $body =~ s/\n/ /g;
    $body =~ s/\r//g; #rip out all remaining \r's

    $body;
}

sub check_xbithack {
    my ($resp) = shift;
    my ($body) = super_chomp($resp->content);
    my ($lastmod) = ($resp->last_modified)
                      ? "Has Last-modified date" : "No Last-modified date";

    my $data = shift;
    $$data = $resp->header('Last-Modified') if $data;

    "$lastmod ; $body";
}

sub check_xbithack_etag {
    my ($resp) = shift;
    my ($body) = super_chomp($resp->content);
    my ($etag) = ($resp->header('ETag'))
                   ? "Has ETag" : "No ETag";

    my $data = shift;
    $$data = $etag if $data;

    "$etag ; $body";
}

sub commify {
    # add standard commas to numbers.  from perlfaq5

    local $_  = shift;
    1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
    return $_;
}

sub single_space {
    # condense multiple spaces between values to a single
    # space.  also trim initial and trailing whitespace

    local $_ = shift; 
    s/\s+/ /g;
    s/(^ )|( $)//;
    return $_;
}
