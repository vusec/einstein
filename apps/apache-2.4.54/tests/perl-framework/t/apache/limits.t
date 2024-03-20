use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
#
# Test the LimitRequestLine, LimitRequestFieldSize, LimitRequestFields,
# and LimitRequestBody directives.
#
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

#
# These values are chosen to exceed the limits in extra.conf, namely:
#
# LimitRequestLine      @limitrequestline@
# LimitRequestFieldSize 1024
# LimitRequestFields    32
# <Directory @SERVERROOT@/htdocs/apache/limits>
#     LimitRequestBody  65536
# </Directory>
#

my $limitrequestlinex2 = Apache::Test::config()->{vars}->{limitrequestlinex2};

my @conditions = qw(requestline fieldsize fieldcount bodysize merged_fieldsize);

my %params = ('requestline-succeed' => "/apache/limits/",
              'requestline-fail'    => ("/apache/limits/" . ('a' x $limitrequestlinex2)),
              'fieldsize-succeed'   => 'short value',
              'fieldsize-fail'      => ('a' x 2048),
              'fieldcount-succeed'  => 1,
              'fieldcount-fail'     => 64,
              'bodysize-succeed'    => ('a' x 1024),
              'bodysize-fail'       => ('a' x 131072),
              'merged_fieldsize-succeed' => ('a' x 500),
              'merged_fieldsize-fail'    => ('a' x 600),
              );
my %xrcs = ('requestline-succeed' => 200,
            'requestline-fail'    => 414,
            'fieldsize-succeed'   => 200,
            'fieldsize-fail'      => 400,
            'fieldcount-succeed'  => 200,
            'fieldcount-fail'     => 400,
            'bodysize-succeed'    => 200,
            'bodysize-fail'       => 413,
            'merged_fieldsize-succeed' => 200,
            'merged_fieldsize-fail'    => 400,
            );

my $res;

if (!have_min_apache_version("2.2.32")) { 
    $xrcs{"merged_fieldsize-fail"} = 200;
}

#
# Two tests for each of the conditions, plus two more for the
# chunked version of the body-too-large test IFF we have the
# appropriate level of LWP support.
#

my $no_chunking = defined($LWP::VERSION) && $LWP::VERSION < 5.60;
if ($no_chunking) {
    print "# Chunked upload tests will NOT be performed;\n",
          "# LWP 5.60 or later is required and you only have ",
          "$LWP::VERSION installed.\n";
}

my $subtests = (@conditions * 2) + 2;
plan tests => $subtests, \&need_lwp;

use vars qw($expected_rc);

my $testnum = 1;
foreach my $cond (@conditions) {
    foreach my $goodbad (qw(succeed fail)) {
        my $param = $params{"$cond-$goodbad"};
        $expected_rc = $xrcs{"$cond-$goodbad"};
        my $resp;
        if ($cond eq 'fieldcount') {
            my %fields;
            for (my $i = 1; $i <= $param; $i++) {
                $fields{"X-Field-$i"} = "Testing field $i";
            }
            print "# Testing LimitRequestFields; should $goodbad\n";
            $resp = GET('/apache/limits/', %fields, 'X-Subtest' => $testnum);
            ok t_cmp($resp->code,
                     $expected_rc,
                     "Test #$testnum");
            if ($resp->code != $expected_rc) {
                print_response($resp);
            }
            $testnum++;
        }
        elsif ($cond eq 'bodysize') {
            #
            # Make sure the last situation is keepalives off..
            #
            foreach my $chunked (qw(1 0)) {
                print "# Testing LimitRequestBody; should $goodbad\n";
                set_chunking($chunked);
                #
                # Note that this tests different things depending upon
                # the chunking state.  The content-body will not even
                # be counted if the Content-Length of an unchunked
                # request exceeds the server's limit; it'll just be
                # drained and discarded.
                #
                if ($chunked) {
                    if ($no_chunking) {
                        my $msg = 'Chunked upload not tested; '
                            . 'not supported by this version of LWP';
                        print "#  $msg\n";
                        skip $msg, 1;
                    }
                    else {
                        my ($req, $resp, $url);
                        $url = Apache::TestRequest::resolve_url('/apache/limits/');
                        $req = HTTP::Request->new(GET => $url);
                        $req->content_type('text/plain');
                        $req->header('X-Subtest' => $testnum);
                        $req->content(chunk_it($param));
                        $resp = Apache::TestRequest::user_agent->request($req);

                        # limit errors with chunked request bodies get
                        # 400 with 1.3, not 413 - see special chunked
                        # request handling in ap_get_client_block in 1.3

                        local $expected_rc = 400 if $goodbad eq 'fail' &&
                                                    have_apache(1); 

                        ok t_cmp($resp->code,
                                 $expected_rc,
                                 "Test #$testnum");
                        if ($resp->code != $expected_rc) {
                            print_response($resp);
                        }
                    }
                }
                else {
                    $resp = GET('/apache/limits/', content_type => 'text/plain',
                                content => $param, 'X-Subtest' => $testnum);
                    ok t_cmp($resp->code,
                             $expected_rc,
                             "Test #$testnum");
                    if ($resp->code != $expected_rc) {
                        print_response($resp);
                    }
                }
                $testnum++;
            }
        }
        elsif ($cond eq 'merged_fieldsize') {
            print "# Testing LimitRequestFieldSize; should $goodbad\n";
            $resp = GET('/apache/limits/', 'X-Subtest' => $testnum,
                        'X-overflow-field' => $param,
                        'X-overflow-field' => $param);
            ok t_cmp($resp->code,
                     $expected_rc,
                     "Test #$testnum");
            if ($resp->code != $expected_rc) {
                print_response($resp);
            }
            $testnum++;
        }
        elsif ($cond eq 'fieldsize') {
            print "# Testing LimitRequestFieldSize; should $goodbad\n";
            $resp = GET('/apache/limits/', 'X-Subtest' => $testnum,
                        'X-overflow-field' => $param);
            ok t_cmp($resp->code,
                     $expected_rc,
                     "Test #$testnum");
            if ($resp->code != $expected_rc) {
                print_response($resp);
            }
            $testnum++;
        }
        elsif ($cond eq 'requestline') {
            print "# Testing LimitRequestLine; should $goodbad\n";
            $resp = GET($param, 'X-Subtest' => $testnum);
            ok t_cmp($resp->code,
                     $expected_rc,
                     "Test #$testnum");
            if ($resp->code != $expected_rc) {
                print_response($resp);
            }
            $testnum++;
        }
    }
}

sub chunk_it {
    my $str = shift;
    my $delay = shift;

    $delay = 1 unless defined $delay;
    return sub {
        select(undef, undef, undef, $delay) if $delay;
        my $l = length($str);
        return substr($str, 0, ($l > 102400 ? 102400 : $l), "");
    }
}

sub set_chunking {
    my ($setting) = @_;
    $setting = $setting ? 1 : 0;
    print "# Chunked transfer-encoding ",
          ($setting ? "enabled" : "disabled"), "\n";
    Apache::TestRequest::user_agent(keep_alive => ($setting ? 1 : 0));
}

sub print_response {
    my ($resp) = @_;
    my $str = $resp->as_string;
    $str =~ s:\n:\n# :gs;
    print "# Server response:\n# $str\n";
}
