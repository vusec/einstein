use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_write_file);
use File::Spec;

# test the possibility of doing authz by user id or envvar in conjunction
# with the different AuthTypes

Apache::TestRequest::user_agent(keep_alive => 1);

my @headers = qw(WWW-Authenticate Authentication-Info Location);

my %do_tests = ( basic  => 11,
                 digest => 11,
                 form   => 16,
                );

my $tests = 2;	# AuthzSendForbiddenOnFailure tests
foreach my $t (keys %do_tests) {
    $tests += $do_tests{$t};
}

plan tests => $tests,
                  need need_lwp,
                  need_module('mod_authn_core'),
                  need_module('mod_authz_core'),
                  need_module('mod_authn_file'),
                  need_module('mod_authz_host'),
                  need_min_apache_version('2.3.7');

foreach my $t (sort keys %do_tests) {
    if (!have_module("mod_auth_$t")) {
        skip("skipping mod_auth_$t tests") for (1 .. $do_tests{$t});
        delete $do_tests{$t};
    }
}

write_htpasswd();

# the auth type we are currently testing
my $type;

foreach my $t (qw/basic digest/) {
    next unless exists $do_tests{$t};
    $type = $t;
    my $url   = "/authz/$type/index.html";

    {
      my $response = GET $url;

      ok($response->code,
         401,
         "$type: no user to authenticate and no env to authorize");
    }

    {
      # bad pass
      my $response = GET $url,
                       username => "u$type", password => 'foo';

      ok($response->code,
         401,
         "$type: u$type:foo not found");
    }

    {
      # authenticated
      my $response = GET $url,
                       username => "u$type", password => "p$type";

      ok($response->code,
         200,
         "$type: u$type:p$type found");
    }

    {
      # authorized by env
      my $response = GET $url, 'X-Allowed' => 'yes';

      ok($response->code,
         200,
         "$type: authz by envvar");

      check_headers($response, 200);
    }

    {
      # authorized by env / with error
      my $response = GET "$url.foo", 'X-Allowed' => 'yes';

      ok($response->code,
         404,
         "$type: not found");

      check_headers($response, 404);
    }
}

#
# Form based authentication works a bit differently
#
if (exists $do_tests{form} && !have_module("mod_session_cookie")) {
    skip("skipping mod_auth_form tests (mod_session_cookie required)")
    	for (1 .. $do_tests{form});
}
elsif (exists $do_tests{form}) {
    $type = 'form';
    my $url   = "/authz/$type/index.html";
    my $login_form_url='/authz/login.html';
    my $login_url='/authz/form/dologin.html';

    my @params = ( reset => 1, cookie_jar => {}, requests_redirectable => 0 );
    Apache::TestRequest::user_agent(@params);

    {
        my $response = GET $url;

        ok($response->code,
           302,
           "$type: access without user/env should redirect with 302");

        my $loc = $response->header("Location");
        if (defined $loc && $loc =~ m{^http://[^/]+(/.*)$}) {
           $loc = $1;
        }
        ok($loc,
           "/authz/login.html",
           "form: login without user/env should redirect to login form");
    }

    {
        Apache::TestRequest::user_agent(@params);
        # bad pass
        my $response = POST $login_url,
                            content => "httpd_username=uform&httpd_password=foo";
        ok($response->code,
           302,
           "form: login with wrong passwd should redirect with 302");

        my $loc = $response->header("Location");
        if (defined $loc && $loc =~ m{^http://[^/]+(/.*)$}) {
           $loc = $1;
        }
        ok($loc,
           "/authz/login.html",
           "form: login with wrong passwd should redirect to login form");

        $response = GET $url;
        ok($response->code,
           302,
           "$type: wrong passwd should not allow access");
    }

    {
        # authenticated
        Apache::TestRequest::user_agent(@params);
        my $response = POST $login_url,
                            content => "httpd_username=uform&httpd_password=pform";
        ok($response->code,
           302,
           "form: login with correct passwd should redirect with 302");

        my $loc = $response->header("Location");
        if (defined $loc && $loc =~ m{^http://[^/]+(/.*)$}) {
            $loc = $1;
        }
        ok($1,
           "/authz/form/",
           "form: login with correct passwd should redirect to SuccessLocation");

        $response = GET $url;
        ok($response->code,
           200,
           "$type: correct passwd did not allow access");
    }

    {
        # authorized by env
        Apache::TestRequest::user_agent(@params);
        my $response = GET $url, 'X-Allowed' => 'yes';

        ok($response->code,
           200,
           "$type: authz by envvar");

        check_headers($response, 200);
    }

    {
      # authorized by env / with error
      my $response = GET "$url.foo", 'X-Allowed' => 'yes';

      ok($response->code,
         404,
         "$type: not found");

      check_headers($response, 404);
    }
}

#
# Test AuthzSendForbiddenOnFailure
#
if (have_min_apache_version("2.3.11")) {
    foreach my $want (401, 403) {
        my $response = GET "/authz/fail/$want",
                           username => "ubasic",
                           password => "pbasic";
        my $got = $response->code;
        ok($got, $want, "Expected code $want, got $got");
    }
}
else {
    skip "skipping tests with httpd <2.3.11" foreach (1..2);
}

#
# check that none of the authentication related headers exists
#
sub check_headers
{
    my $response = shift;
    my $code = shift;

    foreach my $h (@headers) {
        ok($response->header($h),
           undef,
           "$type: $code response should have no $h header");
    }
}

#
# write out the htpasswd files
#
sub write_htpasswd
{
    my $digest_file = File::Spec->catfile(Apache::Test::vars('serverroot'), 'realm2');
    t_write_file($digest_file, << 'EOF' );
# udigest/pdigest
udigest:realm2:bccffb0d42943019acfbebf2039b8a3a
EOF

    my $basic_file = File::Spec->catfile(Apache::Test::vars('serverroot'), 'basic1');
    t_write_file($basic_file, << 'EOF' );
# ubasic:pbasic
ubasic:$apr1$opONH1Fj$dX0sZdZ0rRWEk0Wj8y.Qv1
EOF

    my $form_file = File::Spec->catfile(Apache::Test::vars('serverroot'), 'form1');
    t_write_file($form_file, << 'EOF' );
# uform:pform
uform:$apr1$BzhDZ03D$U598kbSXGy/R7OhYXu.JJ0
EOF
}
