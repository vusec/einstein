use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

## 
## mod_headers tests
##

my $htdocs = Apache::Test::vars('documentroot');
my $htaccess = "$htdocs/modules/headers/htaccess/.htaccess";
my @header_types = ('set', 'append', 'add', 'unset');

my @testcases = (
    ## htaccess
    ## Header to set in the request
    ## Expected result

    # echo
    [
       "Header echo Test-Header\nHeader echo ^Aaa\$\nHeader echo ^Aa\$",
       [ 'Test-Header' => 'value', 'Aaa' => 'b' , 'Aa' => 'bb' ],
       [ 'Test-Header' => 'value', 'Aaa' => 'b' , 'Aa' => 'bb' ],
    ],
    [
       "Header echo Test-Header\nHeader echo XXX\nHeader echo ^Aa\$",
       [ 'Test-Header' => 'foo', 'aaa' => 'b', 'aa' => 'bb' ],
       [ 'Test-Header' => 'foo', 'aa' => 'bb' ],
    ],
    [
       "Header echo Test-Header.*",                                     # regex
       [ 'Test-Header' => 'foo', 'Test-Header1' => 'value1', 'Test-Header2' => 'value2' ],
       [ 'Test-Header' => 'foo', 'Test-Header1' => 'value1', 'Test-Header2' => 'value2' ],
    ],
    # edit
    [
       "Header echo Test-Header\nHeader edit Test-Header foo bar",      # sizeof(foo) = sizeof(bar)
       [ 'Test-Header' => 'foofoo' ],
       [ 'Test-Header' => 'barfoo' ],
    ],
    [
       "Header echo Test-Header\nHeader edit Test-Header foo2 bar",     # sizeof(foo2) > sizeof(bar)
       [ 'Test-Header' => 'foo2foo2' ],
       [ 'Test-Header' => 'barfoo2' ],
    ],
    [
       "Header echo Test-Header\nHeader edit Test-Header foo bar2",     # sizeof(foo) < sizeof(bar2)
       [ 'Test-Header' => 'foofoo' ],
       [ 'Test-Header' => 'bar2foo' ],
    ],
    # edit*
    [
       "Header echo Test-Header\nHeader edit* Test-Header foo bar",     # sizeof(foo) = sizeof(bar)
       [ 'Test-Header' => 'foofoo' ],
       [ 'Test-Header' => 'barbar' ],
    ],
    [
       "Header echo Test-Header\nHeader edit* Test-Header foo2 bar",    # sizeof(foo2) > sizeof(bar)
       [ 'Test-Header' => 'foo2foo2' ],
       [ 'Test-Header' => 'barbar' ],
    ],
    [
       "Header echo Test-Header\nHeader edit* Test-Header foo bar2",    # sizeof(foo) < sizeof(bar2)
       [ 'Test-Header' => 'foofoo' ],
       [ 'Test-Header' => 'bar2bar2' ],
    ],
    # merge
    [
       "Header merge Test-Header foo",                                  # missing header
       [  ],
       [ 'Test-Header' => 'foo' ],
    ],
    [
       "Header echo Test-Header\nHeader merge Test-Header foo",         # already existing, same value
       [ 'Test-Header' => 'foo' ],
       [ 'Test-Header' => 'foo' ],
    ],
    [
       "Header echo Test-Header\nHeader merge Test-Header foo",         # already existing, same value, but with ""
       [ 'Test-Header' => '"foo"' ],
       [ 'Test-Header' => '"foo", foo' ],
    ],
    [
       "Header echo Test-Header\nHeader merge Test-Header bar",         # already existing, different value
       [ 'Test-Header' => 'foo' ],
       [ 'Test-Header' => 'foo, bar' ],
    ],
    # setifempty
    [
       "Header echo Test-Header\nHeader setifempty Test-Header bar",    # already existing
       [ 'Test-Header' => 'foo' ],
       [ 'Test-Header' => 'foo' ],
    ],
    [
       "Header echo Test-Header\nHeader setifempty Test-Header2 bar",   # missing header
       [ 'Test-Header' => 'foo' ],
       [ 'Test-Header' => 'foo', 'Test-Header2' => 'bar' ],
    ],
    # env=
    [
       "SetEnv MY_ENV\nHeader set Test-Header foo env=MY_ENV",          # env defined
       [  ],
       [ 'Test-Header' => 'foo' ],
    ],
    [
       "Header set Test-Header foo env=!MY_ENV",                        # env NOT defined
       [  ],
       [ 'Test-Header' => 'foo' ],
    ],
    # expr=
    [
       "Header set Test-Header foo \"expr=%{REQUEST_URI} =~ m#htaccess#\"", # expr
       [  ],
       [ 'Test-Header' => 'foo' ],
    ],
);
   
plan tests => 
    @header_types**4 + @header_types**3 + @header_types**2 + @header_types**1 + scalar @testcases * 2,
    have_module 'headers';

# Test various configurations
foreach my $header1 (@header_types) {

    ok test_header($header1);
    foreach my $header2 (@header_types) {

        ok test_header($header1, $header2);
        foreach my $header3 (@header_types) {

            ok test_header($header1, $header2, $header3);
            foreach my $header4 (@header_types) {

                ok test_header($header1, $header2, $header3, $header4);

            }

        }

    }

}

# Test some other Header directives, including regex
my $ua = LWP::UserAgent->new();
my $hostport = Apache::TestRequest::hostport();
foreach my $t (@testcases) {
    test_header2($t);
}

## clean up ##
unlink $htaccess;

sub test_header {
    my @h = @_;
    my $test_header = "Test-Header";
    my (@expected_value, @actual_value) = ((),());
    my ($expected_exists, $expected_value, $actual_exists) = (0,0,0);

    open (HT, ">$htaccess");
    foreach (@h) {

        ## create a unique header value ##
        my $r = int(rand(9999));
        my $test_value = "mod_headers test header value $r";
        
        ## evaluate $_ to come up with expected results
        ## and write out the .htaccess file
        if ($_ eq 'unset') {
            print HT "Header $_ $test_header\n";
            @expected_value = ();
            $expected_exists = 0;
            $expected_value = 0;
        } else {
            print HT "Header $_ $test_header \"$test_value\"\n";

            if ($_ eq 'set') {

                ## should 'set' work this way?
                ## currently, even if there are multiple headers
                ## with the same name, 'set' blows them all away
                ## and sets a single one with this value.
                @expected_value = ();
                $expected_exists = 1;

                $expected_value = $test_value;
            } elsif ($_ eq 'append') {

                ## should 'append' work this way?
                ## currently, if there are multiple headers
                ## with the same name, 'append' appends the value
                ## to the FIRST instance of that header.
                if (@expected_value) {
                    $expected_value[0] .= ", $test_value";

                } elsif ($expected_value) {
                    $expected_value .= ", $test_value";
                } else {
                    $expected_value = $test_value;
                }
                $expected_exists++ unless $expected_exists;

            } elsif ($_ eq 'add') {
                if ($expected_value) {
                    push(@expected_value, $expected_value);
                    $expected_value = 0;
                }
                $expected_value = $test_value;
                $expected_exists++;
            }
        }
    }
    close(HT);

    push(@expected_value, $expected_value) if $expected_value;

    ## get the actual headers ##
    my $h = HEAD_STR "/modules/headers/htaccess/";

    ## parse response headers looking for our headers
    ## and save the value(s)
    my $exists = 0;
    my $actual_value;
    foreach my $head (split /\n/, $h) {
        if ($head =~ /^$test_header: (.*)$/) {
            $actual_exists++;
            push(@actual_value, $1);
        }
    }

    ## ok if 'unset' and there are no headers ##
    return 1 if ($actual_exists == 0 and $expected_exists == 0);

    if (($actual_exists == $expected_exists) &&
        (@actual_value == @expected_value)) {

        ## go through each actual header ##
        foreach my $av (@actual_value) {
            my $matched = 0;

            ## and each expected header ##
            for (my $i = 0 ; $i <= @expected_value ; $i++) {

                if ($av eq $expected_value[$i]) {

                    ## if we match actual and expected,
                    ## record it, and remove the header
                    ## from the expected list
                    $matched++;
                    splice(@expected_value, $i, 1);
                    last;

                }
            }

            ## not ok if actual value does not match expected ##
            return 0 unless $matched;
        }

        ## if we made it this far, all is well. ##
        return 1;

    } else {

        ## not ok if the number of expected and actual
        ## headers do not match
        return 0;

    }
}

sub test_header2 {
    my @test = @_;
    my $h = HTTP::Headers->new;
    
    print "\n\n\n";
    for (my $i = 0; $i < scalar @{$test[0][1]}; $i += 2) {
        print "Header sent n°" . $i/2 . ":\n";
        print "  header: " . $test[0][1][$i] . "\n";
        print "  value:  " . $test[0][1][$i+1] . "\n";
        $h->header($test[0][1][$i] => $test[0][1][$i+1]);
    }
    
    open (HT, ">$htaccess");
    print HT $test[0][0];
    close(HT);

    ## 
    my $r = HTTP::Request->new('GET', "http://$hostport/modules/headers/htaccess/", $h);
    my $res = $ua->request($r);
    ok t_cmp($res->code, 200, "Checking return code is '200'");
    
    my $isok = 1;
    for (my $i = 0; $i < scalar @{$test[0][2]}; $i += 2) {
        print "\n";
        print "Header received n°" . $i/2 . ":\n";
        print "  header:   " . $test[0][2][$i] . "\n";
        print "  expected: " . $test[0][2][$i+1] . "\n";
        if ($res->header($test[0][2][$i])) {
            print "  received: " . $res->header($test[0][2][$i]) . "\n";
        } else {
            print "  received: <undefined>\n";
        }
        $isok = $isok && $res->header($test[0][2][$i]) && $test[0][2][$i+1] eq $res->header($test[0][2][$i]);
    }
    print "\nResponse received is:\n" . $res->as_string;

    ok $isok;
}
