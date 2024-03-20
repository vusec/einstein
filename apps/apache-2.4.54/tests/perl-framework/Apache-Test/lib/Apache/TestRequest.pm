# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
package Apache::TestRequest;

use strict;
use warnings FATAL => 'all';

BEGIN {
    $ENV{PERL_LWP_USE_HTTP_10}   = 1;    # default to http/1.0
    $ENV{APACHE_TEST_HTTP_09_OK} ||= 0;  # 0.9 responses are ok
}

use Apache::Test ();
use Apache::TestConfig ();

use lib "$ENV{'ROOT'}/apps/scripts/perl-tests";
require EinsteinTests;

use Carp;

use constant TRY_TIMES => 200;
use constant INTERP_KEY => 'X-PerlInterpreter';
use constant UA_TIMEOUT => 60 * 10; #longer timeout for debugging

my $have_lwp = 0;

# APACHE_TEST_PRETEND_NO_LWP=1 pretends that LWP is not available so
# one can test whether the test suite survives if the user doesn't
# have lwp installed
unless ($ENV{APACHE_TEST_PRETEND_NO_LWP}) {
    $have_lwp = eval {
        require LWP::UserAgent;
        require HTTP::Request::Common;

        unless (defined &HTTP::Request::Common::OPTIONS) {
            package HTTP::Request::Common;
            no strict 'vars';
            *OPTIONS = sub { _simple_req(OPTIONS => @_) };
            push @EXPORT, 'OPTIONS';
        }
        1;
    };
}

unless ($have_lwp) {
    require Apache::TestClient;
}

sub has_lwp { $have_lwp }

unless ($have_lwp) {
    #need to define the shortcuts even though the wont be used
    #so Perl can parse test scripts
    @HTTP::Request::Common::EXPORT = qw(GET HEAD POST PUT OPTIONS);
}

sub install_http11 {
    eval {
        die "no LWP" unless $have_lwp;
        LWP->VERSION(5.60); #minimal version
        require LWP::Protocol::http;
        #LWP::Protocol::http10 is used by default
        LWP::Protocol::implementor('http', 'LWP::Protocol::http');
    };
}

use vars qw(@EXPORT @ISA $RedirectOK $DebugLWP);

require Exporter;
*import = \&Exporter::import;
@EXPORT = @HTTP::Request::Common::EXPORT;

@ISA = qw(LWP::UserAgent);

my $UA;
my $REDIR = $have_lwp ? undef : 1;
my $conn_opts = {};

sub module {
    my $module = shift;
    $Apache::TestRequest::Module = $module if $module;
    $Apache::TestRequest::Module;
}

sub scheme {
    my $scheme = shift;
    $Apache::TestRequest::Scheme = $scheme if $scheme;
    $Apache::TestRequest::Scheme;
}

sub module2path {
    my $package = shift;

    # httpd (1.3 && 2) / winFU have problems when the first path's
    # segment includes ':' (security precaution which breaks the rfc)
    # so we can't use /TestFoo::bar as path_info
    (my $path = $package) =~ s/::/__/g;

    return $path;
}

sub module2url {
    my $module   = shift;
    my $opt      = shift || {};
    my $scheme   = $opt->{scheme} || 'http';
    my $path     = exists $opt->{path} ? $opt->{path} : module2path($module);

    module($module);

    my $config   = Apache::Test::config();
    my $hostport = hostport($config);

    $path =~ s|^/||;
    return "$scheme://$hostport/$path";
}

sub user_agent {
    my $args = {@_};

    if (delete $args->{reset}) {
        $UA = undef;
    }

    if (exists $args->{requests_redirectable}) {
        my $redir = $args->{requests_redirectable};
        if (ref $redir and (@$redir > 1 or $redir->[0] ne 'POST')) {
            # Set our internal flag if there's no LWP.
            $REDIR = $have_lwp ? undef : 1;
        } elsif ($redir) {
            if ($have_lwp) {
                $args->{requests_redirectable} = [ qw/GET HEAD POST/ ];
                $REDIR = undef;
            } else {
                # Set our internal flag.
                $REDIR = 1;
            }
        } else {
            # Make sure our internal flag is false if there's no LWP.
            $REDIR = $have_lwp ? undef : 0;
        }
    }

    $args->{keep_alive} ||= $ENV{APACHE_TEST_HTTP11};

    if ($args->{keep_alive}) {
        install_http11();
        eval {
            require LWP::Protocol::https; #https10 is the default
            LWP::Protocol::implementor('https', 'LWP::Protocol::https');
        };
    }

    # in LWP 6, verify_hostname defaults to on, so SSL_ca_file
    # needs to be set accordingly
    if ($have_lwp and $LWP::VERSION >= 6.0 and not exists $args->{ssl_opts}->{SSL_ca_file}) {
        my $vars = Apache::Test::vars();
        my $cafile = "$vars->{sslca}/$vars->{sslcaorg}/certs/ca.crt";
        $args->{ssl_opts}->{SSL_ca_file} = $cafile;
        # IO::Socket:SSL raw socket compatibility
        $conn_opts->{SSL_ca_file} = $cafile;
    }

    eval { $UA ||= __PACKAGE__->new(%$args); };
}

sub user_agent_request_num {
    my $res = shift;
    $res->header('Client-Request-Num') ||  #lwp 5.60
        $res->header('Client-Response-Num'); #lwp 5.62+
}

sub user_agent_keepalive {
    $ENV{APACHE_TEST_HTTP11} = shift;
}

sub do_request {
    EinsteinTests::send_test_info('../..');
    my($ua, $method, $url, $callback) = @_;
    my $r = HTTP::Request->new($method, resolve_url($url));
    my $response = $ua->request($r, $callback);
    lwp_trace($response);
}

sub hostport {
    my $config = shift || Apache::Test::config();
    my $vars = $config->{vars};
    local $vars->{scheme} =
        $Apache::TestRequest::Scheme || $vars->{scheme};
    my $hostport = $config->hostport;

    my $default_hostport = join ':', $vars->{servername}, $vars->{port};
    if (my $module = $Apache::TestRequest::Module) {
        $hostport = $module eq 'default'
            ? $default_hostport
            : $config->{vhosts}->{$module}->{hostport};
    }

    $hostport || $default_hostport;
}

sub resolve_url {
    my $url = shift;
    Carp::croak("no url passed") unless defined $url;

    return $url if $url =~ m,^(\w+):/,;
    $url = "/$url" unless $url =~ m,^/,;

    my $vars = Apache::Test::vars();

    local $vars->{scheme} =
      $Apache::TestRequest::Scheme || $vars->{scheme} || 'http';

    scheme_fixup($vars->{scheme});

    my $hostport = hostport();

    return "$vars->{scheme}://$hostport$url";
}

my %wanted_args = map {$_, 1} qw(username password realm content filename
                                 redirect_ok cert);

sub wanted_args {
    \%wanted_args;
}

sub redirect_ok {
    my $self = shift;
    if ($have_lwp) {
        # Return user setting or let LWP handle it.
        return $RedirectOK if defined $RedirectOK;
        return $self->SUPER::redirect_ok(@_);
    }

    # No LWP. We don't support redirect on POST.
    return 0 if $self->method eq 'POST';
    # Return user setting or our internal calculation.
    return $RedirectOK if defined $RedirectOK;
    return $REDIR;
}

my %credentials;

#subclass LWP::UserAgent
sub new {
    my $self = shift->SUPER::new(@_);

    lwp_debug(); #init from %ENV (set by Apache::TestRun)

    my $config = Apache::Test::config();
    if (my $proxy = $config->configure_proxy) {
        #t/TEST -proxy
        $self->proxy(http => "http://$proxy");
    }

    $self->timeout(UA_TIMEOUT);

    $self;
}

sub credentials {
    my $self = shift;
    return $self->get_basic_credentials(@_);
}

sub get_basic_credentials {
    my($self, $realm, $uri, $proxy) = @_;

    for ($realm, '__ALL__') {
        next unless $_ && $credentials{$_};
        return @{ $credentials{$_} };
    }

    return (undef,undef);
}

sub vhost_socket {
    my $module = shift;
    local $Apache::TestRequest::Module = $module if $module;

    my $hostport = hostport(Apache::Test::config());

    my($host, $port) = split ':', $hostport;
    my(%args) = (PeerAddr => $host, PeerPort => $port);

    if ($module and ($module =~ /ssl/ || $module eq 'h2')) {
        require IO::Socket::SSL;
        # Add all conn_opts to args
        map {$args{$_} = $conn_opts->{$_}} keys %{$conn_opts};
        return IO::Socket::SSL->new(%args, Timeout => UA_TIMEOUT);
    }
    else {
        require IO::Socket;
        return IO::Socket::INET->new(%args);
    }
}

#IO::Socket::SSL::getline does not correctly handle OpenSSL *_WANT_*.
#Could care less about performance here, just need a getline()
#that returns the same results with or without ssl.
#Inspired from Net::SSLeay::ssl_read_all().
my %getline = (
    'IO::Socket::SSL' => sub {
        my $self = shift;
        # _get_ssl_object in IO::Socket::SSL only meant for internal use!
        # But we need to compensate for unsufficient getline impl there.
        my $ssl = $self->_get_ssl_object;
        my ($got, $rv, $errs);
        my $reply = '';
    
        while (1) {
            ($got, $rv) = Net::SSLeay::read($ssl, 1);
            if (! defined $got) {
                my $err = Net::SSLeay::get_error($ssl, $rv);
                if ($err != Net::SSLeay::ERROR_WANT_READ() and
                    $err != Net::SSLeay::ERROR_WANT_WRITE()) {
                    $errs = Net::SSLeay::print_errs('SSL_read');
                    last;
                }
                next;
            }
            last if $got eq '';  # EOF
            $reply .= $got;
            last if $got eq "\n";
        }

        wantarray ? ($reply, $errs) : $reply;
    },
);

sub getline {
    my $sock = shift;
    my $class = ref $sock;
    my $method = $getline{$class} || 'getline';
    $sock->$method();
}

sub socket_trace {
    my $sock = shift;
    return unless $sock->can('get_peer_certificate');

    #like having some -v info
    my $cert = $sock->get_peer_certificate;
    print "#Cipher:  ", $sock->get_cipher, "\n";
    print "#Peer DN: ", $cert->subject_name, "\n";
}

sub prepare {
    my $url = shift;

    if ($have_lwp) {
        user_agent();
        $url = resolve_url($url);
    }
    else {
        lwp_debug() if $ENV{APACHE_TEST_DEBUG_LWP};
    }

    my($pass, $keep) = Apache::TestConfig::filter_args(\@_, \%wanted_args);

    %credentials = ();
    if (defined $keep->{username}) {
        $credentials{$keep->{realm} || '__ALL__'} =
          [$keep->{username}, $keep->{password}];
    }
    if (defined(my $content = $keep->{content})) {
        if ($content eq '-') {
            $content = join '', <STDIN>;
        }
        elsif ($content =~ /^x(\d+)$/) {
            $content = 'a' x $1;
        }
        push @$pass, content => $content;
    }
    if (exists $keep->{cert}) {
        set_client_cert($keep->{cert});
    }

    return ($url, $pass, $keep);
}

sub UPLOAD {
    my($url, $pass, $keep) = prepare(@_);

    local $RedirectOK = exists $keep->{redirect_ok}
        ? $keep->{redirect_ok}
        : $RedirectOK;

    if ($keep->{filename}) {
        return upload_file($url, $keep->{filename}, $pass);
    }
    else {
        return upload_string($url, $keep->{content});
    }
}

sub UPLOAD_BODY {
    UPLOAD(@_)->content;
}

sub UPLOAD_BODY_ASSERT {
    content_assert(UPLOAD(@_));
}

#lwp only supports files
sub upload_string {
    my($url, $data) = @_;

    my $CRLF = "\015\012";
    my $bound = 742617000027;
    my $req = HTTP::Request->new(POST => $url);

    my $content = join $CRLF,
      "--$bound",
      "Content-Disposition: form-data; name=\"HTTPUPLOAD\"; filename=\"b\"",
      "Content-Type: text/plain", "",
      $data, "--$bound--", "";

    $req->header("Content-Length", length($content));
    $req->content_type("multipart/form-data; boundary=$bound");
    $req->content($content);

    $UA->request($req);
}

sub upload_file {
    my($url, $file, $args) = @_;

    my $content = [@$args, filename => [$file]];

    $UA->request(HTTP::Request::Common::POST($url,
                 Content_Type => 'form-data',
                 Content      => $content,
    ));
}

#useful for POST_HEAD and $DebugLWP (see below)
sub lwp_as_string {
    my($r, $want_body) = @_;
    my $content = $r->content;

    unless ($r->isa('HTTP::Request') or
            $r->header('Content-Length') or
            $r->header('Transfer-Encoding'))
    {
        $r->header('Content-Length' => length $content);
        $r->header('X-Content-length-note' => 'added by Apache::TestRequest');
    }

    $r->content('') unless $want_body;

    (my $string = $r->as_string) =~ s/^/\#/mg;
    $r->content($content); #reset
    $string;
}

$DebugLWP = 0; #1 == print METHOD URL and header response for all requests
               #2 == #1 + response body
               #other == passed to LWP::Debug->import

sub lwp_debug {
    package main; #wtf: else package in perldb changes
    my $val = $_[0] || $ENV{APACHE_TEST_DEBUG_LWP};

    return unless $val;

    if ($val =~ /^\d+$/) {
        $Apache::TestRequest::DebugLWP = $val;
        return "\$Apache::TestRequest::DebugLWP = $val\n";
    }
    else {
        my(@args) = @_ ? @_ : split /\s+/, $val;
        require LWP::Debug;
        LWP::Debug->import(@args);
        return "LWP::Debug->import(@args)\n";
    }
}

sub lwp_trace {
    my $r = shift;

    unless ($r->request->protocol) {
        #lwp always sends a request, but never sets
        #$r->request->protocol, happens deeper in the
        #LWP::Protocol::http* modules
        my $proto = user_agent_request_num($r) ? "1.1" : "1.0";
        $r->request->protocol("HTTP/$proto");
    }

    my $want_body = $DebugLWP > 1;
    print "#lwp request:\n",
      lwp_as_string($r->request, $want_body);

    print "#server response:\n",
      lwp_as_string($r, $want_body);
}

sub lwp_call {
    EinsteinTests::send_test_info('../..');

    my($name, $shortcut) = (shift, shift);

    my $r = (\&{$name})->(@_);

    Carp::croak("$name(@_) didn't return a response object") unless $r;

    my $error = "";
    unless ($shortcut) {
        #GET, HEAD, POST
        if ($r->method eq "POST" && !defined($r->header("Content-Length"))) {
            $r->header('Content-Length' => length($r->content));
        }
        $r = $UA ? $UA->request($r) : $r;
        my $proto = $r->protocol;
        if (defined($proto)) {
            if ($proto !~ /^HTTP\/(\d\.\d)$/) {
                $error = "response had no protocol (is LWP broken or something?)";
            }
            if ($1 ne "1.0" && $1 ne "1.1") {
                $error = "response had protocol HTTP/$1 (headers not sent?)"
                    unless ($1 eq "0.9" && $ENV{APACHE_TEST_HTTP_09_OK});
            }
        }
    }

    if ($DebugLWP and not $shortcut) {
        lwp_trace($r);
    }

    Carp::croak($error) if $error;

    return $shortcut ? $r->$shortcut() : $r;
}

my %shortcuts = (RC   => sub { shift->code },
                 OK   => sub { shift->is_success },
                 STR  => sub { shift->as_string },
                 HEAD => sub { lwp_as_string(shift, 0) },
                 BODY => sub { shift->content },
                 BODY_ASSERT => sub { content_assert(shift) },
);

for my $name (@EXPORT) {
    my $package = $have_lwp ?
      'HTTP::Request::Common': 'Apache::TestClient';

    my $method = join '::', $package, $name;
    no strict 'refs';

    next unless defined &$method;

    *$name = sub {
        my($url, $pass, $keep) = prepare(@_);
        local $RedirectOK = exists $keep->{redirect_ok}
            ? $keep->{redirect_ok}
            : $RedirectOK;
        return lwp_call($method, undef, $url, @$pass);
    };

    while (my($shortcut, $cv) = each %shortcuts) {
        my $alias = join '_', $name, $shortcut;
        *$alias = sub { lwp_call($name, $cv, @_) };
    }
}

my @export_std = @EXPORT;
for my $method (@export_std) {
    push @EXPORT, map { join '_', $method, $_ } keys %shortcuts;
}

push @EXPORT, qw(UPLOAD UPLOAD_BODY UPLOAD_BODY_ASSERT);

sub to_string {
    my $obj = shift;
    ref($obj) ? $obj->as_string : $obj;
}

# request an interpreter instance and use this interpreter id to
# select the same interpreter in requests below
sub same_interp_tie {
    my($url) = @_;

    my $res = GET($url, INTERP_KEY, 'tie');
    unless ($res->code == 200) {
        die sprintf "failed to init the same_handler data (url=%s). " .
            "Failed with code=%s, response:\n%s",
                $url, $res->code, $res->content;
    }
    my $same_interp = $res->header(INTERP_KEY);

    return $same_interp;
}

# run the request though the selected perl interpreter, by polling
# until we found it
# currently supports only GET, HEAD, PUT, POST subs
sub same_interp_do {
    my($same_interp, $sub, $url, @args) = @_;

    die "must pass an interpreter id, obtained via same_interp_tie()"
        unless defined $same_interp and $same_interp;

    push @args, (INTERP_KEY, $same_interp);

    my $res      = '';
    my $times    = 0;
    my $found_same_interp = '';
    do {
        #loop until we get a response from our interpreter instance
        $res = $sub->($url, @args);
        die "no result" unless $res;
        my $code = $res->code;
        if ($code == 200) {
            $found_same_interp = $res->header(INTERP_KEY) || '';
        }
        elsif ($code == 404) {
            # try again
        }
        else {
            die sprintf "failed to run the request (url=%s):\n" .
                "code=%s, response:\n%s", $url, $code, $res->content;
        }

        unless ($found_same_interp eq $same_interp) {
            $found_same_interp = '';
        }

        if ($times++ > TRY_TIMES) { #prevent endless loop
            die "unable to find interp $same_interp\n";
        }
    } until ($found_same_interp);

    return $found_same_interp ? $res : undef;
}


sub set_client_cert {
    my $name = shift;
    my $vars = Apache::Test::vars();
    my $dir = join '/', $vars->{sslca}, $vars->{sslcaorg};

    if ($name) {
        my ($cert, $key) = ("$dir/certs/$name.crt", "$dir/keys/$name.pem");
        # IO::Socket:SSL raw socket compatibility
        $conn_opts->{SSL_cert_file} = $cert;
        $conn_opts->{SSL_key_file} = $key;
        if ($LWP::VERSION >= 6.0) {
            # IO::Socket:SSL doesn't look at environment variables
            if ($UA) {
                $UA->ssl_opts(SSL_cert_file => $cert);
                $UA->ssl_opts(SSL_key_file  => $key);
            } else {
                user_agent(ssl_opts => { SSL_cert_file => $cert,
                                         SSL_key_file  => $key });
            }
        }
    }
    else {
        # IO::Socket:SSL raw socket compatibility
        $conn_opts->{SSL_cert_file} = undef;
        $conn_opts->{SSL_key_file} = undef;
        if ($LWP::VERSION >= 6.0 and $UA) {
            $UA->ssl_opts(SSL_cert_file => undef);
            $UA->ssl_opts(SSL_key_file  => undef);
        }
    }
}

# Only for IO::Socket:SSL raw socket compatibility,
# when using user_agent() already done in its
# constructor.
sub set_ca_cert {
    my $vars = Apache::Test::vars();
    my $cafile = "$vars->{sslca}/$vars->{sslcaorg}/certs/ca.crt";
    $conn_opts->{SSL_ca_file} = $cafile;
}

#want news: urls to work with the LWP shortcuts
#but cant find a clean way to override the default nntp port
#by brute force we trick Net::NTTP into calling FixupNNTP::new
#instead of IO::Socket::INET::new, we fixup the args then forward
#to IO::Socket::INET::new

#also want KeepAlive on for Net::HTTP
#XXX libwww-perl 5.53_xx has: LWP::UserAgent->new(keep_alive => 1);

sub install_net_socket_new {
    my($module, $code) = @_;

    return unless Apache::Test::have_module($module);

    no strict 'refs';

    my $new;
    my $isa = \@{"$module\::ISA"};

    for (@$isa) {
        last if $new = $_->can('new');
    }

    my $fixup_class = "Apache::TestRequest::$module";
    unshift @$isa, $fixup_class;

    *{"$fixup_class\::new"} = sub {
        my $class = shift;
        my $args = {@_};
        $code->($args);
        return $new->($class, %$args);
    };
}

my %scheme_fixups = (
    'news' => sub {
        return if $INC{'Net/NNTP.pm'};
        eval {
            install_net_socket_new('Net::NNTP' => sub {
                my $args = shift;
                my($host, $port) = split ':',
                  Apache::TestRequest::hostport();
                $args->{PeerPort} = $port;
                $args->{PeerAddr} = $host;
            });
        };
    },
);

sub scheme_fixup {
    my $scheme = shift;
    my $fixup = $scheme_fixups{$scheme};
    return unless $fixup;
    $fixup->();
}

# when the client side simply prints the response body which should
# include the test's output, we need to make sure that the request
# hasn't failed, or the test will be skipped instead of indicating the
# error.
sub content_assert {
    my $res = shift;

    return $res->content if $res->is_success;

    die join "\n",
        "request has failed (the response code was: " . $res->code . ")",
        "see t/logs/error_log for more details\n";
}

1;

=head1 NAME

Apache::TestRequest - Send requests to your Apache test server

=head1 SYNOPSIS

  use Apache::Test qw(ok have_lwp);
  use Apache::TestRequest qw(GET POST);
  use Apache::Constants qw(HTTP_OK);

  plan tests => 1, have_lwp;

  my $res = GET '/test.html';
  ok $res->code == HTTP_OK, "Request is ok";

=head1 DESCRIPTION

B<Apache::TestRequest> provides convenience functions to allow you to
make requests to your Apache test server in your test scripts. It
subclasses C<LWP::UserAgent>, so that you have access to all if its
methods, but also exports a number of useful functions likely useful
for majority of your test requests. Users of the old C<Apache::test>
(or C<Apache::testold>) module, take note! Herein lie most of the
functions you'll need to use to replace C<Apache::test> in your test
suites.

Each of the functions exported by C<Apache::TestRequest> uses an
C<LWP::UserAgent> object to submit the request and retrieve its
results. The return value for many of these functions is an
HTTP::Response object. See L<HTTP::Response|HTTP::Response> for
documentation of its methods, which you can use in your tests. For
example, use the C<code()> and C<content()> methods to test the
response code and content of your request. Using C<GET>, you can
perform a couple of tests using these methods like this:

  use Apache::Test qw(ok have_lwp);
  use Apache::TestRequest qw(GET POST);
  use Apache::Constants qw(HTTP_OK);

  plan tests => 2, have_lwp;

  my $uri = "/test.html?foo=1&bar=2";
  my $res = GET $uri;
  ok $res->code == HTTP_OK, "Check that the request was OK";
  ok $res->content eq "foo => 1, bar => 2", "Check its content";

Note that you can also use C<Apache::TestRequest> with
C<Test::Builder> and its derivatives, including C<Test::More>:

  use Test::More;
  # ...
  is $res->code, HTTP_OK, "Check that the request was OK";
  is $res->content, "foo => 1, bar => 2", "Check its content";

=head1 CONFIGURATION FUNCTION

You can tell C<Apache::TestRequest> what kind of C<LWP::UserAgent>
object to use for its convenience functions with C<user_agent()>. This
function uses its arguments to construct an internal global
C<LWP::UserAgent> object that will be used for all subsequent requests
made by the convenience functions. The arguments it takes are the same
as for the C<LWP::UserAgent> constructor. See the
C<L<LWP::UserAgent|LWP::UserAgent>> documentation for a complete list.

The C<user_agent()> function only creates the internal
C<LWP::UserAgent> object the first time it is called. Since this
function is called internally by C<Apache::TestRequest>, you should
always use the C<reset> parameter to force it to create a new global
C<LWP::UserAgent> Object:

  Apache::TestRequest::user_agent(reset => 1, %params);

C<user_agent()> differs from C<< LWP::UserAgent->new >> in two
additional ways. First, it supports an additional parameter,
C<keep_alive>, which enables connection persistence, where the same
connection is used to process multiple requests (and, according to the
C<L<LWP::UserAgent|LWP::UserAgent>> documentation, has the effect of
loading and enabling the new experimental HTTP/1.1 protocol module).

And finally, the semantics of the C<requests_redirectable> parameter is
different than for C<LWP::UserAgent> in that you can pass it a boolean
value as well as an array for C<LWP::UserAgent>. To force
C<Apache::TestRequest> not to follow redirects in any of its convenience
functions, pass a false value to C<requests_redirectable>:

  Apache::TestRequest::user_agent(reset => 1,
                                  requests_redirectable => 0);

If LWP is not installed, then you can still pass in an array reference
as C<LWP::UserAgent> expects. C<Apache::TestRequest> will examine the
array and allow redirects if the array contains more than one value or
if there is only one value and that value is not "POST":

  # Always allow redirection.
  my $redir = have_lwp() ? [qw(GET HEAD POST)] : 1;
  Apache::TestRequest::user_agent(reset => 1,
                                  requests_redirectable => $redir);

But note that redirection will B<not> work with C<POST> unless LWP is
installed. It's best, therefore, to check C<have_lwp> before running
tests that rely on a redirection from C<POST>.

Sometimes it is desireable to have C<Apache::TestRequest> remember
cookies sent by the pages you are testing and send them back to the
server on subsequent requests. This is especially necessary when
testing pages whose functionality relies on sessions or the presence
of preferences stored in cookies.

By default, C<LWP::UserAgent> does B<not> remember cookies between
requests. You can tell it to remember cookies between request by
adding:

  Apache::TestRequest::user_agent(cookie_jar => {});

before issuing the requests.


=head1 FUNCTIONS

C<Apache::TestRequest> exports a number of functions that will likely
prove convenient for use in the majority of your request tests.




=head2 Optional Parameters

Each function also takes a number of optional arguments.

=over 4

=item redirect_ok

By default a request will follow redirects retrieved from the server. To
prevent this behavior, pass a false value to a C<redirect_ok>
parameter:

  my $res = GET $uri, redirect_ok => 0;

Alternately, if all of your tests need to disable redirects, tell
C<Apache::TestRequest> to use an C<LWP::UserAgent> object that
disables redirects:

  Apache::TestRequest::user_agent( reset => 1,
                                   requests_redirectable => 0 );

=item cert

If you need to force an SSL request to use a particular SSL
certificate, pass the name of the certificate via the C<cert>
parameter:

  my $res = GET $uri, cert => 'my_cert';

=item content

If you need to add content to your request, use the C<content>
parameter:

  my $res = GET $uri, content => 'hello world!';

=item filename

The name of a local file on the file system to be sent to the Apache
test server via C<UPLOAD()> and its friends.

=back

=head2 The Functions

=head3 GET

  my $res = GET $uri;

Sends a simple GET request to the Apache test server. Returns an
C<HTTP::Response> object.

You can also supply additional headers to be sent with the request by
adding their name/value pairs after the C<url> parameter, for example:

  my $res = GET $url, 'Accept-Language' => 'de,en-us,en;q=0.5';

=head3 GET_STR

A shortcut function for C<GET($uri)-E<gt>as_string>.

=head3 GET_BODY

A shortcut function for C<GET($uri)-E<gt>content>.

=head3 GET_BODY_ASSERT

Use this function when your test is outputting content that you need
to check, and you want to make sure that the request was successful
before comparing the contents of the request. If the request was
unsuccessful, C<GET_BODY_ASSERT> will return an error
message. Otherwise it will simply return the content of the request
just as C<GET_BODY> would.

=head3 GET_OK

A shortcut function for C<GET($uri)-E<gt>is_success>.

=head3 GET_RC

A shortcut function for C<GET($uri)-E<gt>code>.

=head3 GET_HEAD

Throws out the content of the request, and returns the string
representation of the request. Since the body has been thrown out, the
representation will consist solely of the headers. Furthermore,
C<GET_HEAD> inserts a "#" at the beginning of each line of the return
string, so that the contents are suitable for printing to STDERR
during your tests without interfering with the workings of
C<Test::Harness>.

=head3 HEAD

  my $res = HEAD $uri;

Sends a HEAD request to the Apache test server. Returns an
C<HTTP::Response> object.

=head3 HEAD_STR

A shortcut function for C<HEAD($uri)-E<gt>as_string>.

=head3 HEAD_BODY

A shortcut function for C<HEAD($uri)-E<gt>content>. Of course, this
means that it will likely return nothing.

=head3 HEAD_BODY_ASSERT

Use this function when your test is outputting content that you need
to check, and you want to make sure that the request was successful
before comparing the contents of the request. If the request was
unsuccessful, C<HEAD_BODY_ASSERT> will return an error
message. Otherwise it will simply return the content of the request
just as C<HEAD_BODY> would.

=head3 HEAD_OK

A shortcut function for C<GET($uri)-E<gt>is_success>.

=head3 HEAD_RC

A shortcut function for C<GET($uri)-E<gt>code>.

=head3 HEAD_HEAD

Throws out the content of the request, and returns the string
representation of the request. Since the body has been thrown out, the
representation will consist solely of the headers. Furthermore,
C<GET_HEAD> inserts a "#" at the beginning of each line of the return
string, so that the contents are suitable for printing to STDERR
during your tests without interfering with the workings of
C<Test::Harness>.

=head3 PUT

  my $res = PUT $uri;

Sends a simple PUT request to the Apache test server. Returns an
C<HTTP::Response> object.

=head3 PUT_STR

A shortcut function for C<PUT($uri)-E<gt>as_string>.

=head3 PUT_BODY

A shortcut function for C<PUT($uri)-E<gt>content>.

=head3 PUT_BODY_ASSERT

Use this function when your test is outputting content that you need
to check, and you want to make sure that the request was successful
before comparing the contents of the request. If the request was
unsuccessful, C<PUT_BODY_ASSERT> will return an error
message. Otherwise it will simply return the content of the request
just as C<PUT_BODY> would.

=head3 PUT_OK

A shortcut function for C<PUT($uri)-E<gt>is_success>.

=head3 PUT_RC

A shortcut function for C<PUT($uri)-E<gt>code>.

=head3 PUT_HEAD

Throws out the content of the request, and returns the string
representation of the request. Since the body has been thrown out, the
representation will consist solely of the headers. Furthermore,
C<PUT_HEAD> inserts a "#" at the beginning of each line of the return
string, so that the contents are suitable for printing to STDERR
during your tests without interfering with the workings of
C<Test::Harness>.

=head3 POST

  my $res = POST $uri, [ arg => $val, arg2 => $val ];

Sends a POST request to the Apache test server and returns an
C<HTTP::Response> object. An array reference of parameters passed as
the second argument will be submitted to the Apache test server as the
POST content. Parameters corresponding to those documented in
L<Optional Parameters|/Optional
Parameters> can follow the optional array reference of parameters, or after
C<$uri>.

To upload a chunk of data, simply use:

  my $res = POST $uri, content => $data;

=head3 POST_STR

A shortcut function for C<POST($uri, @args)-E<gt>content>.

=head3 POST_BODY

A shortcut function for C<POST($uri, @args)-E<gt>content>.

=head3 POST_BODY_ASSERT

Use this function when your test is outputting content that you need
to check, and you want to make sure that the request was successful
before comparing the contents of the request. If the request was
unsuccessful, C<POST_BODY_ASSERT> will return an error
message. Otherwise it will simply return the content of the request
just as C<POST_BODY> would.

=head3 POST_OK

A shortcut function for C<POST($uri, @args)-E<gt>is_success>.

=head3 POST_RC

A shortcut function for C<POST($uri, @args)-E<gt>code>.

=head3 POST_HEAD

Throws out the content of the request, and returns the string
representation of the request. Since the body has been thrown out, the
representation will consist solely of the headers. Furthermore,
C<POST_HEAD> inserts a "#" at the beginning of each line of the return
string, so that the contents are suitable for printing to STDERR
during your tests without interfering with the workings of
C<Test::Harness>.

=head3 UPLOAD

  my $res = UPLOAD $uri, \@args, filename => $filename;

Sends a request to the Apache test server that includes an uploaded
file. Other POST parameters can be passed as a second argument as an
array reference.

C<Apache::TestRequest> will read in the contents of the file named via
the C<filename> parameter for submission to the server. If you'd
rather, you can submit use the C<content> parameter instead of
C<filename>, and its value will be submitted to the Apache server as
file contents:

  my $res = UPLOAD $uri, undef, content => "This is file content";

The name of the file sent to the server will simply be "b". Note that
in this case, you cannot pass other POST arguments to C<UPLOAD()> --
they would be ignored.

=head3 UPLOAD_BODY

A shortcut function for C<UPLOAD($uri, @params)-E<gt>content>.

=head3 UPLOAD_BODY_ASSERT

Use this function when your test is outputting content that you need
to check, and you want to make sure that the request was successful
before comparing the contents of the request. If the request was
unsuccessful, C<UPLOAD_BODY_ASSERT> will return an error
message. Otherwise it will simply return the content of the request
just as C<UPLOAD_BODY> would.

=head3 OPTIONS

  my $res = OPTIONS $uri;

Sends an C<OPTIONS> request to the Apache test server. Returns an
C<HTTP::Response> object with the I<Allow> header, indicating which
methods the server supports. Possible methods include C<OPTIONS>,
C<GET>, C<HEAD> and C<POST>. This function thus can be useful for
testing what options the Apache server supports. Consult the HTTPD 1.1
specification, section 9.2, at
I<http://www.faqs.org/rfcs/rfc2616.html> for more information.





=head2 URL Manipulation Functions

C<Apache::TestRequest> also includes a few helper functions to aid in
the creation of urls used in the functions above.



=head3 C<module2path>

  $path = Apache::TestRequest::module2path($module_name);

Convert a module name to a path, safe for use in the various request
methods above. e.g. C<::> can't be used in URLs on win32. For example:

  $path = Apache::TestRequest::module2path('Foo::Bar');

returns:

  /Foo__Bar




=head3 C<module2url>

  $url = Apache::TestRequest::module2url($module);
  $url = Apache::TestRequest::module2url($module, \%options);

Convert a module name to a full URL including the current
configurations C<hostname:port> and sets C<module> accordingly.

  $url = Apache::TestRequest::module2url('Foo::Bar');

returns:

  http://$hostname:$port/Foo__Bar

The default scheme used is C<http>. You can override this by passing
your preferred scheme into an optional second param. For example:

  $module = 'MyTestModule::TestHandler';
  $url = Apache::TestRequest::module2url($module, {scheme => 'https'});

returns:

  https://$hostname:$port/MyTestModule__TestHandler

You may also override the default path with a path of your own:

  $module = 'MyTestModule::TestHandler';
  $url = Apache::TestRequest::module2url($module, {path => '/foo'});

returns:

  http://$hostname:$port/foo





=head1 ENVIRONMENT VARIABLES

The following environment variables can affect the behavior of
C<Apache::TestRequest>:

=over

=item APACHE_TEST_PRETEND_NO_LWP

If the environment variable C<APACHE_TEST_PRETEND_NO_LWP> is set to a
true value, C<Apache::TestRequest> will pretend that LWP is not
available so one can test whether the test suite will survive on a
system which doesn't have libwww-perl installed.

=item APACHE_TEST_HTTP_09_OK

If the environment variable C<APACHE_TEST_HTTP_09_OK> is set to a
true value, C<Apache::TestRequest> will allow HTTP/0.9 responses
from the server to proceed.  The default behavior is to die if
the response protocol is not either HTTP/1.0 or HTTP/1.1.

=back

=head1 SEE ALSO

L<Apache::Test|Apache::Test> is the main Apache testing module. Use it
to set up your tests, create a plan, and to ensure that you have the
Apache version and modules you need.

Use L<Apache::TestMM|Apache::TestMM> in your I<Makefile.PL> to set up
your distribution for testing.

=head1 AUTHOR

Doug MacEachern with contributions from Geoffrey Young, Philippe
M. Chiasson, Stas Bekman and others. Documentation by David Wheeler.

Questions can be asked at the test-dev <at> httpd.apache.org list. For
more information see: I<http://httpd.apache.org/test/> and
I<http://perl.apache.org/docs/general/testing/testing.html>.
