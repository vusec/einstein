use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;
use Misc;

my $have_fcgisetenvif    = have_min_apache_version('2.4.26');
my $have_fcgibackendtype = have_min_apache_version('2.4.26');
# NOTE: This will fail if php-fpm is installed but not in $PATH
my $have_php_fpm = `php-fpm -v` =~ /fpm-fcgi/;

plan tests => (7 * $have_fcgisetenvif) + (2 * $have_fcgibackendtype) +
               (2 * $have_fcgibackendtype * have_module('rewrite')) +
               (7 * have_module('rewrite')) + (7 * have_module('actions')) +
               (15 * $have_php_fpm * have_module('actions')) + 2,
     need (
        'mod_proxy_fcgi',
        'FCGI',
        'IO::Select'
     );

require FCGI;
require IO::Select;

Apache::TestRequest::module("proxy_fcgi");

# Launches a short-lived FCGI daemon that will handle exactly one request with
# the given handler function. Returns the child PID; exits on failure.

sub run_fcgi_handler($$)
{
    my $fcgi_port    = shift;
    my $handler_func = shift;

    # Use a pipe for ready-signalling between the child and parent. Much faster
    # (and more reliable) than just sleeping for a few seconds.
    pipe(READ_END, WRITE_END);
    my $pid = fork();

    unless (defined $pid) {
        t_debug "couldn't fork FCGI process";
        ok 0;
        exit;
    }

    if ($pid == 0) {
        # Child process. Open up a listening socket.
        my $sock = FCGI::OpenSocket(":$fcgi_port", 10);

        # Signal the parent process that we're ready.
        print WRITE_END 'x';
        close WRITE_END;

        # Listen for and respond to exactly one request from the client.
        my $request = FCGI::Request(\*STDIN, \*STDOUT, \*STDERR, \%ENV,
                                    $sock, &FCGI::FAIL_ACCEPT_ON_INTR);

        if ($request->Accept() == 0) {
            # Run the handler.
            $handler_func->();
            $request->Finish();
        }

        # Clean up and exit.
        FCGI::CloseSocket($sock);
        exit;
    }

    # Parent process. Wait for the daemon to launch.
    unless (IO::Select->new((\*READ_END,))->can_read(2)) {
        t_debug "timed out waiting for FCGI process to start";
        ok 0;

        kill 'TERM', $pid;
        # Note that we don't waitpid() here because Perl's fork() implementation
        # on some platforms (Windows) doesn't guarantee that the pseudo-TERM
        # signal will be delivered. Just wait for the child to be cleaned up
        # when we exit.

        exit;
    }

    return $pid;
}

# Convenience wrapper for run_fcgi_handler() that will echo back the envvars in
# the response. Returns the child PID; exits on failure.
sub launch_envvar_echo_daemon($)
{
    my $fcgi_port = shift;

    return run_fcgi_handler($fcgi_port, sub {
        # Echo all the envvars back to the client.
        print("Content-Type: text/plain\r\n\r\n");
        foreach my $key (sort(keys %ENV)) {
            print($key, "=", $ENV{$key}, "\n");
        }
    });
}

# Runs a single request using launch_envvar_echo_daemon(), then returns a
# hashref containing the environment variables that were echoed by the FCGI
# backend.
#
# Calling this function will run one test that must be accounted for in the test
# plan.
sub run_fcgi_envvar_request
{
    my $fcgi_port = shift;
    my $uri       = shift;
    my $backend   = shift || "FCGI";

    # Launch the FCGI process.
    my $child = launch_envvar_echo_daemon($fcgi_port) unless ($fcgi_port <= 0) ;

    # Hit the backend.
    my $r = GET($uri);
    ok t_cmp($r->code, 200, "proxy to $backend backend works (" . $uri . ")");

    # Split the returned envvars into a dictionary.
    my %envs = ();

    foreach my $line (split /\n/, $r->content) {
        t_debug("> $line"); # log the response lines for debugging

        my @components = split /=/, $line, 2;
        $envs{$components[0]} = $components[1];
    }

    if ($fcgi_port > 0) {
        if ($r->code eq '500') {
            # Unknown failure, probably the request didn't hit the FCGI child
            # process, so it will hang waiting for our request
            kill 'TERM', $child;
        } else {
            # Rejoin the child FCGI process.
            waitpid($child, 0);
        }
    }

    return \%envs;
}

#
# MAIN
#

# XXX There appears to be no way to get the value of a dynamically-reserved
# @NextAvailablePort@ from Apache::Test. We assume here that the port reserved
# for the proxy_fcgi vhost is one greater than the reserved FCGI_PORT, but
# depending on the test conditions, that may not always be the case...
my $fcgi_port = Apache::Test::vars('proxy_fcgi_port') - 1;
my $envs;
my $docroot = Apache::Test::vars('documentroot');
my $servroot = Apache::Test::vars('serverroot');

if ($have_fcgisetenvif) {
    # ProxyFCGISetEnvIf tests. Query the backend.
    $envs = run_fcgi_envvar_request($fcgi_port, "/fcgisetenv?query");

    # Check the response values.
    ok t_cmp($envs->{'QUERY_STRING'},     'test_value', "ProxyFCGISetEnvIf can override an existing variable");
    ok t_cmp($envs->{'TEST_NOT_SET'},     undef,        "ProxyFCGISetEnvIf does not set variables if condition is false");
    ok t_cmp($envs->{'TEST_EMPTY'},       '',           "ProxyFCGISetEnvIf can set empty values");
    ok t_cmp($envs->{'TEST_DOCROOT'},     $docroot,     "ProxyFCGISetEnvIf can replace with request variables");
    ok t_cmp($envs->{'TEST_CGI_VERSION'}, 'v1.1',       "ProxyFCGISetEnvIf can replace with backreferences");
    ok t_cmp($envs->{'REMOTE_ADDR'},      undef,        "ProxyFCGISetEnvIf can unset var");
}

# Tests for GENERIC backend type behavior.
if ($have_fcgibackendtype) {
    # Regression test for PR59618.
    $envs = run_fcgi_envvar_request($fcgi_port, "/modules/proxy/fcgi-generic/index.php?query");

    ok t_cmp($envs->{'SCRIPT_FILENAME'},
             $docroot . '/modules/proxy/fcgi-generic/index.php',
             "GENERIC SCRIPT_FILENAME should have neither query string nor proxy: prefix");
}

if ($have_fcgibackendtype && have_module('rewrite')) {
    # Regression test for PR59815.
    $envs = run_fcgi_envvar_request($fcgi_port, "/modules/proxy/fcgi-generic-rewrite/index.php?query");

    ok t_cmp($envs->{'SCRIPT_FILENAME'},
             $docroot . '/modules/proxy/fcgi-generic-rewrite/index.php',
             "GENERIC SCRIPT_FILENAME should have neither query string nor proxy: prefix");
}

if (have_module('rewrite')) {
    # Regression test for general FPM breakage when using mod_rewrite for
    # nice-looking URIs; see
    # https://github.com/apache/httpd/commit/cab0bfbb2645bb8f689535e5e2834e2dbc23f5a5#commitcomment-20393588
    $envs = run_fcgi_envvar_request($fcgi_port, "/modules/proxy/fcgi-rewrite-path-info/path/info?query");

    # Not all of these values make sense, but unfortunately FPM expects some
    # breakage and doesn't function properly without it, so we can't fully fix
    # the problem by default. These tests verify that we follow the 2.4.20 way
    # of doing things for the "rewrite-redirect PATH_INFO to script" case.
    ok t_cmp($envs->{'SCRIPT_FILENAME'}, "proxy:fcgi://127.0.0.1:" . $fcgi_port
                                         . $docroot
                                         . '/modules/proxy/fcgi-rewrite-path-info/index.php',
             "Default SCRIPT_FILENAME has proxy:fcgi prefix for compatibility");
    ok t_cmp($envs->{'SCRIPT_NAME'}, '/modules/proxy/fcgi-rewrite-path-info/index.php',
             "Default SCRIPT_NAME uses actual path to script");
    ok t_cmp($envs->{'PATH_INFO'}, '/path/info',
             "Default PATH_INFO is correct");
    ok t_cmp($envs->{'PATH_TRANSLATED'}, $docroot . '/path/info',
             "Default PATH_TRANSLATED is correct");
    ok t_cmp($envs->{'QUERY_STRING'}, 'query',
             "Default QUERY_STRING is correct");
    ok t_cmp($envs->{'REDIRECT_URL'}, '/modules/proxy/fcgi-rewrite-path-info/path/info',
             "Default REDIRECT_URL uses original client URL");
}

if (have_module('actions')) {
    # Regression test to ensure that the bizarre Action invocation for FCGI
    # still works as it did in 2.4.20. Almost none of this follows any spec at
    # all. As far as I can tell, this method does not work with FPM.
    $envs = run_fcgi_envvar_request($fcgi_port, "/modules/proxy/fcgi-action/index.php/path/info?query");

    ok t_cmp($envs->{'SCRIPT_FILENAME'}, "proxy:fcgi://127.0.0.1:" . $fcgi_port
                                         . $docroot
                                         . '/fcgi-action-virtual',
             "Action SCRIPT_FILENAME has proxy:fcgi prefix and uses virtual action Location");
    ok t_cmp($envs->{'SCRIPT_NAME'}, '/fcgi-action-virtual',
             "Action SCRIPT_NAME is the virtual action Location");
    ok t_cmp($envs->{'PATH_INFO'}, '/modules/proxy/fcgi-action/index.php/path/info',
             "Action PATH_INFO contains full URI path");
    ok t_cmp($envs->{'PATH_TRANSLATED'}, $docroot . '/modules/proxy/fcgi-action/index.php/path/info',
             "Action PATH_TRANSLATED contains full URI path");
    ok t_cmp($envs->{'QUERY_STRING'}, 'query',
             "Action QUERY_STRING is correct");
    ok t_cmp($envs->{'REDIRECT_URL'}, '/modules/proxy/fcgi-action/index.php/path/info',
             "Action REDIRECT_URL uses original client URL");

    # Testing using php-fpm directly
    if ($have_php_fpm) {
        my $pid_file = "/tmp/php-fpm-" . $$ . "-" . time . ".pid";
        my $pid = fork();
        unless (defined $pid) {
            t_debug "couldn't start PHP-FPM";
            ok 0;
            exit;
        }
        if ($pid == 0) {
            system "php-fpm -n -D -g $pid_file -p $servroot/php-fpm";
            exit;
        }
        # Wait for php-fpm to start-up
        unless ( Misc::cwait('-e "'.$pid_file.'"', 10, 50) ) {
            ok 0;
            exit;
        }
        sleep(1);
        $envs = run_fcgi_envvar_request(0, "/php/fpm/action/sub2/test.php/foo/bar?query", "PHP-FPM");
        ok t_cmp($envs->{'SCRIPT_NAME'}, '/php/fpm/action/sub2/test.php',
                "Handler PHP-FPM sets correct SCRIPT_NAME");
        ok t_cmp($envs->{'PATH_INFO'}, '/foo/bar',
                "Handler PHP-FPM sets correct PATH_INFO");
        ok t_cmp($envs->{'QUERY_STRING'}, 'query',
                "Handler PHP-FPM sets correct QUERY_STRING");
        ok t_cmp($envs->{'PATH_TRANSLATED'}, $docroot . '/foo/bar',
                "Handler PHP-FPM sets correct PATH_TRANSLATED");
        ok t_cmp($envs->{'FCGI_ROLE'}, 'RESPONDER',
                "Handler PHP-FPM sets correct FCGI_ROLE");

        $envs = run_fcgi_envvar_request(0, "/php-fpm-pp/php/fpm/pp/sub1/test.php/foo/bar?query", "PHP-FPM");
        ok t_cmp($envs->{'SCRIPT_NAME'}, '/php-fpm-pp/php/fpm/pp/sub1/test.php',
                "ProxyPass PHP-FPM sets correct SCRIPT_NAME");
        ok t_cmp($envs->{'PATH_INFO'}, '/foo/bar',
                "ProxyPass PHP-FPM sets correct PATH_INFO");
        ok t_cmp($envs->{'QUERY_STRING'}, 'query',
                "ProxyPass PHP-FPM sets correct QUERY_STRING");
        ok t_cmp($envs->{'PATH_TRANSLATED'}, $docroot . '/foo/bar',
                "ProxyPass PHP-FPM sets correct PATH_TRANSLATED");
        ok t_cmp($envs->{'FCGI_ROLE'}, 'RESPONDER',
                "ProxyPass PHP-FPM sets correct FCGI_ROLE");

        $envs = run_fcgi_envvar_request(0, "/php-fpm-pp/php/fpm/pp/sub1/test.php", "PHP-FPM");
        ok t_cmp($envs->{'PATH_INFO'}, undef,
                "ProxyPass PHP-FPM sets correct empty PATH_INFO");
        ok t_cmp($envs->{'PATH_TRANSLATED'}, undef,
                "ProxyPass PHP-FPM does not set PATH_TRANSLATED w/ empty PATH_INFO");

        # TODO: Add more tests here

        # Clean up php-fpm process(es)
        kill 'TERM', $pid;   # Kill child process
        kill 'TERM', `cat $pid_file`;   # Kill php-fpm daemon
        waitpid($pid, 0);
    }

}

# Regression test for PR61202.
$envs = run_fcgi_envvar_request($fcgi_port, "/modules/proxy/fcgi/index.php");
ok t_cmp($envs->{'SCRIPT_NAME'}, '/modules/proxy/fcgi/index.php', "Server sets correct SCRIPT_NAME by default");

