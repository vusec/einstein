use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;
use Apache::TestConfig ();
use Apache::TestSSLCA ();

#if keepalives are on, renegotiation not happen again once
#a client cert is presented.
Apache::TestRequest::user_agent_keepalive(0);

my $cert = 'client_snakeoil';

my $server_expect =
  Apache::TestSSLCA::dn_vars('ca', 'SERVER_I');

my $client_expect =
  Apache::TestSSLCA::dn_vars($cert, 'CLIENT_S');

my $url = '/ssl-cgi/env.pl';

my $tests = (keys(%$server_expect) + keys(%$client_expect) + 1) * 2;
plan tests => $tests, need need_cgi, need_lwp;

Apache::TestRequest::scheme('https');

my $r = GET($url);

ok t_cmp($r->code, 200, "response status OK");

my $env = getenv($r->as_string);

verify($env, $server_expect);
verify($env, $client_expect, 1);

$url = '/require-ssl-cgi/env.pl';

$r = GET($url, cert => $cert);

ok t_cmp($r->code, 200, "second response status OK");

$env = getenv($r->as_string);

verify($env, $server_expect);
verify($env, $client_expect);

sub verify {
    my($env, $expect, $ne) = @_;

    while (my($key, $val) = each %$expect) {
        # the emailAddress attribute is still exported using the name
        # _DN_Email by mod_ssl, even when using OpenSSL 0.9.7.
        if ($key =~ /(.*)_emailAddress/) {
            $key = $1 . "_Email";
        }
        if (Apache::TestConfig::WIN32) {
            #perl uppercases all %ENV keys
            #which causes SSL_*_DN_Email lookups to fail
            $key = uc $key;
        }
        unless ($ne || $env->{$key}) {
            print "#$key does not exist\n";
            $env->{$key} = ""; #prevent use of unitialized value
        }
        if ($ne) {
            print "#$key should not exist\n";
            ok not exists $env->{$key};
        }
        else {
            print "#$key: expect '$val', got '$env->{$key}'\n";
            ok $env->{$key} eq $val;
        }
    }
}

sub getenv {
    my $str = shift;

    my %env;

    for my $line (split /[\r\n]+/, $str) {
        my($key, $val) = split /\s*=\s*/, $line, 2;
        next unless $key and $val;
        $env{$key} = $val;
    }

    \%env;
}
