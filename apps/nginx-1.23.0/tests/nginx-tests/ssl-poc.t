#!/usr/bin/perl

# (C) Sergey Kandaurov
# (C) Andrey Zelenkov
# (C) Nginx, Inc.

# Tests for http ssl module.

###############################################################################

use warnings;
use strict;

use Test::More;

use Socket qw/ CRLF /;

BEGIN { use FindBin; chdir($FindBin::Bin); }

use lib 'lib';
use Test::Nginx;

use Time::Stopwatch;

###############################################################################

select STDERR; $| = 1;
select STDOUT; $| = 1;

eval { require IO::Socket::SSL; };
plan(skip_all => 'IO::Socket::SSL not installed') if $@;
eval { IO::Socket::SSL::SSL_VERIFY_NONE(); };
plan(skip_all => 'IO::Socket::SSL too old') if $@;

my $t = Test::Nginx->new()->has(qw/http http_ssl rewrite proxy/)
	->has_daemon('openssl')->plan(0);

$t->write_file_expand('nginx.conf', <<'EOF');

%%TEST_GLOBALS%%

daemon off;

events {
}

http {
    %%TEST_GLOBALS_HTTP%%

    ssl_certificate_key localhost.key;
    ssl_certificate localhost.crt;
    ssl_session_tickets off;

    log_format ssl $ssl_protocol;

    server {
        listen       127.0.0.1:8085 ssl;
        listen       127.0.0.1:8080;
        server_name  localhost;

        ssl_certificate_key inner.key;
        ssl_certificate inner.crt;
        ssl_session_cache shared:SSL:1m;
        ssl_verify_client optional_no_ca;

        keepalive_requests 1000;

        location / {
            return 200 "body $ssl_session_reused";
        }
        location /id {
            return 200 "body $ssl_session_id";
        }
        location /cipher {
            return 200 "body $ssl_cipher";
        }
        location /ciphers {
            return 200 "body $ssl_ciphers";
        }
        location /client_verify {
            return 200 "body $ssl_client_verify";
        }
        location /protocol {
            return 200 "body $ssl_protocol";
        }
        location /issuer {
            return 200 "body $ssl_client_i_dn:$ssl_client_i_dn_legacy";
        }
        location /subject {
            return 200 "body $ssl_client_s_dn:$ssl_client_s_dn_legacy";
        }
        location /time {
            return 200 "body $ssl_client_v_start!$ssl_client_v_end!$ssl_client_v_remain";
        }

        location /body {
            add_header X-Body $request_body always;
            proxy_pass http://127.0.0.1:8080/;

            access_log %%TESTDIR%%/ssl.log ssl;
        }
    }
}

EOF

$t->write_file('openssl.conf', <<EOF);
[ req ]
default_bits = 2048
encrypt_key = no
distinguished_name = req_distinguished_name
[ req_distinguished_name ]
EOF

my $d = $t->testdir();

$t->write_file('ca.conf', <<EOF);
[ ca ]
default_ca = myca

[ myca ]
new_certs_dir = $d
database = $d/certindex
default_md = sha256
policy = myca_policy
serial = $d/certserial
default_days = 3

[ myca_policy ]
commonName = supplied
EOF

$t->write_file('certserial', '1000');
$t->write_file('certindex', '');

system('openssl req -x509 -new '
	. "-config $d/openssl.conf -subj /CN=issuer/ "
	. "-out $d/issuer.crt -keyout $d/issuer.key "
	. ">>$d/openssl.out 2>&1") == 0
	or die "Can't create certificate for issuer: $!\n";

system("openssl req -new "
	. "-config $d/openssl.conf -subj /CN=subject/ "
	. "-out $d/subject.csr -keyout $d/subject.key "
	. ">>$d/openssl.out 2>&1") == 0
	or die "Can't create certificate for subject: $!\n";

system("openssl ca -batch -config $d/ca.conf "
	. "-keyfile $d/issuer.key -cert $d/issuer.crt "
	. "-subj /CN=subject/ -in $d/subject.csr -out $d/subject.crt "
	. ">>$d/openssl.out 2>&1") == 0
	or die "Can't sign certificate for subject: $!\n";

foreach my $name ('localhost', 'inner') {
	system('openssl req -x509 -new '
		. "-config $d/openssl.conf -subj /CN=$name/ "
		. "-out $d/$name.crt -keyout $d/$name.key "
		. ">>$d/openssl.out 2>&1") == 0
		or die "Can't create certificate for $name: $!\n";
}

# suppress deprecation warning

print(STDERR __FILE__, ":", __LINE__, "\n");
open OLDERR, ">&", \*STDERR; close STDERR;
$t->run();
open STDERR, ">&", \*OLDERR;
print(STDERR __FILE__, ":", __LINE__, "\n");
tie my $timer, 'Time::Stopwatch';

###############################################################################

get('/protocol', 8085);

print(STDERR __FILE__, ":", __LINE__, " -- $timer seconds\n");

###############################################################################

sub get {
	print(STDERR "-- ", __FILE__, ":", __LINE__, " -- $timer seconds\n");
	my ($uri, $port, $ctx) = @_;
	print(STDERR "-- ", __FILE__, ":", __LINE__, " -- $timer seconds\n");
	my $s = get_ssl_socket($port, $ctx) or return;
	print(STDERR "-- ", __FILE__, ":", __LINE__, " -- $timer seconds\n");
	my $r = http_get($uri, socket => $s);
	print(STDERR "-- ", __FILE__, ":", __LINE__, " -- $timer seconds\n");
	$s->close();
	print(STDERR "-- ", __FILE__, ":", __LINE__, " -- $timer seconds\n");
	return $r;
}

sub get_ssl_socket {
	my ($port, $ctx, %extra) = @_;
	my $s;

	print(STDERR "-- ", __FILE__, ":", __LINE__, " -- $timer seconds\n");
	eval {
		print(STDERR "-- ", __FILE__, ":", __LINE__, " -- $timer seconds\n");
		local $SIG{ALRM} = sub { die "timeout\n" };
		print(STDERR "-- ", __FILE__, ":", __LINE__, " -- $timer seconds\n");
		local $SIG{PIPE} = sub { die "sigpipe\n" };
		print(STDERR "-- ", __FILE__, ":", __LINE__, " -- $timer seconds\n");
		#alarm(8);
		print(STDERR "-- ", __FILE__, ":", __LINE__, " -- $timer seconds\n");
		$s = IO::Socket::SSL->new(
			Proto => 'tcp',
			PeerAddr => '127.0.0.1',
			PeerPort => port($port),
			SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE(),
			SSL_reuse_ctx => $ctx,
			SSL_error_trap => sub { die $_[1] },
			%extra
		);
		print(STDERR "-- ", __FILE__, ":", __LINE__, " -- $timer seconds\n");
		alarm(0);
	print(STDERR "-- ", __FILE__, ":", __LINE__, " -- $timer seconds\n");
	};
	alarm(0);

	print(STDERR "-- ", __FILE__, ":", __LINE__, " -- $timer seconds\n");
	if ($@) {
		print(STDERR "-- ", __FILE__, ":", __LINE__, " -- $timer seconds\n");
		log_in("died: $@");
		return undef;
	}

	print(STDERR "-- ", __FILE__, ":", __LINE__, " -- $timer seconds\n");
	return $s;
}

###############################################################################
