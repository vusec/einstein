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
package Apache::TestSSLCA;

use strict;
use warnings FATAL => 'all';

use Cwd ();
use DirHandle ();
use File::Path ();
use File::Copy 'cp';
use File::Basename;
use File::Spec::Functions qw(devnull);
use Apache::TestConfig ();
use Apache::TestTrace;

use constant SSLCA_DB => 'index.txt';

use vars qw(@EXPORT_OK &import);

use subs qw(symlink);

@EXPORT_OK = qw(dn dn_vars dn_oneline);
*import = \&Exporter::import;

my $openssl = $ENV{APACHE_TEST_OPENSSL_CMD} || 'openssl';
my $version = version();

my $CA = 'asf';
my $Config; #global Apache::TestConfig object

my $days     = '-days 365';
my $cakey    = 'keys/ca.pem';
my $cacert   = 'certs/ca.crt';
my $capolicy = '-policy policy_anything';
my $cacrl    = 'crl/ca-bundle.crl';
my $dgst     = 'sha256';

#we use the same password for everything
my $pass    = 'httpd';
my $passin  = "-passin pass:$pass";
my $passout = "-passout pass:$pass";

# (limited) subjectAltName otherName testing
my $san_msupn  = ', otherName:msUPN;UTF8:$mail';
my $san_dnssrv = ', otherName:1.3.6.1.5.5.7.8.7;IA5:_https.$CN';

# in 0.9.7 s/Email/emailAddress/ in DN
my $email_field = Apache::Test::normalize_vstring($version) <
                  Apache::Test::normalize_vstring("0.9.7") ?
                  "Email" : "emailAddress";

# downgrade to SHA-1 for OpenSSL before 0.9.8
if (Apache::Test::normalize_vstring($version) <
    Apache::Test::normalize_vstring("0.9.8")) {
    $dgst = 'sha1';
    # otherNames in x509v3_config are not supported either
    $san_msupn = $san_dnssrv = "";
}

my $sslproto = "all";

eval { require Net::SSLeay; };
if (Apache::Test::normalize_vstring($version) >= 
    Apache::Test::normalize_vstring("1.1.1")
    && !defined(&Net::SSLeay::CTX_set_post_handshake_auth)) {
    # OpenSSL 1.1.1 disables PHA by default client-side in TLSv1.3 but
    # most clients are not updated to enable it (at time of writing).
    # Many mod_ssl tests require working PHA, so disable v1.3 unless
    # using an updated Net::SSLeay. This is strictly insufficient
    # since an updated IO::Socket::SSL is also needed; to be
    # continued.  Ref: https://github.com/openssl/openssl/issues/6933
    $sslproto = "all -TLSv1.3";
}

my $ca_dn = {
    asf => {
        C  => 'US',
        ST => 'California',
        L  => 'San Francisco',
        O  => 'ASF',
        OU => 'httpd-test',
        CN => '',
        $email_field => 'test-dev@httpd.apache.org',
    },
};

my $cert_dn = {
    client_snakeoil => {
        C  => 'AU',
        ST => 'Queensland',
        L  => 'Mackay',
        O  => 'Snake Oil, Ltd.',
        OU => 'Staff',
    },
    client_ok => {
    },
    client_colon => {
        CN => "user:colon",
    },
    client_revoked => {
    },
    server => {
        CN => 'localhost',
        OU => 'httpd-test/rsa-test',
    },
    server2 => {
        CN => 'localhost',
        OU => 'httpd-test/rsa-test-2',
    },
    server_des3 => {
        CN => 'localhost',
        OU => 'httpd-test/rsa-des3-test',
    },
    server2_des3 => {
        CN => 'localhost',
        OU => 'httpd-test/rsa-des3-test-2',
    },
};

#generate DSA versions of the server certs/keys
for my $key (keys %$cert_dn) {
    next unless $key =~ /^server/;
    my $val = $$cert_dn{$key};
    my $name = join '_', $key, 'dsa';
    $cert_dn->{$name} = { %$val }; #copy
    $cert_dn->{$name}->{OU} =~ s/rsa/dsa/;
}

sub ca_dn {
    $ca_dn = shift if @_;
    $ca_dn;
}

sub cert_dn {
    $cert_dn = shift if @_;
    $cert_dn;
}

sub dn {
    my $name = shift;

    my %dn = %{ $ca_dn->{$CA} }; #default values
    $dn{CN} ||= $name; #try make sure each Common Name is different

    my $default_dn = $cert_dn->{$name};

    if ($default_dn) {
        while (my($key, $value) = each %$default_dn) {
            #override values
            $dn{$key} = $value;
        }
    }

    return wantarray ? %dn : \%dn;
}

sub dn_vars {
    my($name, $type) = @_;

    my $dn = dn($name);
    my $prefix = join '_', 'SSL', $type, 'DN';

    return { map { $prefix ."_$_", $dn->{$_} } keys %$dn };
}

sub dn_oneline {
    my($dn, $rfc2253) = @_;

    unless (ref $dn) {
        $dn = dn($dn);
    }

    my $string = "";
    my @parts = (qw(C ST L O OU CN), $email_field);
    @parts = reverse @parts if $rfc2253;

    for my $k (@parts) {
        next unless $dn->{$k};
        if ($rfc2253) {
            my $tmp = $dn->{$k};
            $tmp =~ s{([,+"\\<>;])}{\\$1}g;
            $tmp =~ s{^([ #])}{\\$1};
            $tmp =~ s{ $}{\\ };
            $string .= "," if $string;
            $string .= "$k=$tmp";
        }
        else {
            $string .= "/$k=$dn->{$k}";
        }
    }

    $string;
}

sub openssl {
    return $openssl unless @_;

    my $cmd = "$openssl @_";

    info $cmd;

    unless (system($cmd) == 0) {
        my $status = $? >> 8;
        die "system @_ failed (exit status=$status)";
    }
}

my @dirs = qw(keys newcerts certs crl export csr conf proxy);

sub init {
    for my $dir (@dirs) {
        gendir($dir);
    }
}

sub config_file {
    my $name = shift;

    my $file = "conf/$name.cnf";
    return $file if -e $file;

    my $dn = dn($name);
    my $db = SSLCA_DB;

    writefile($db, '', 1) unless -e $db;

    writefile($file, <<EOF);
mail                   = $dn->{$email_field}
CN                     = $dn->{CN}

[ req ]
distinguished_name     = req_distinguished_name
attributes             = req_attributes
prompt                 = no
default_bits           = 2048
output_password        = $pass

[ req_distinguished_name ]
C                      = $dn->{C}
ST                     = $dn->{ST}
L                      = $dn->{L}
O                      = $dn->{O}
OU                     = $dn->{OU}
CN                     = \$CN
$email_field           = \$mail

[ req_attributes ]
challengePassword      = $pass

[ ca ]
default_ca             = CA_default

[ CA_default ]
certs            = certs        # Where the issued certs are kept
new_certs_dir    = newcerts     # default place for new certs.
crl_dir          = crl          # Where the issued crl are kept
database         = $db          # database index file.
serial           = serial       # The current serial number

certificate      = $cacert      # The CA certificate
crl              = $cacrl       # The current CRL
private_key      = $cakey       # The private key

default_days     = 365          # how long to certify for
default_crl_days = 365          # how long before next CRL
default_md       = $dgst        # which md to use.
preserve         = no           # keep passed DN ordering

[ policy_anything ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
$email_field            = optional

[ client_ok_ext ]
nsComment = This Is A Comment
1.3.6.1.4.1.18060.12.0 = DER:0c064c656d6f6e73
subjectAltName = email:\$mail$san_msupn

[ server_ext ]
subjectAltName = DNS:\$CN$san_dnssrv
EOF

    return $file;
}

sub config {
    my $name = shift;

    my $file = config_file($name);

    my $config = "-config $file";

    $config;
}

use constant PASSWORD_CLEARTEXT =>
    Apache::TestConfig::WIN32 || Apache::TestConfig::NETWARE;

#http://www.modssl.org/docs/2.8/ssl_reference.html#ToC21
my $basic_auth_password =
    PASSWORD_CLEARTEXT ? 'password': 'xxj31ZMTZzkVA';
my $digest_auth_hash    = '$1$OXLyS...$Owx8s2/m9/gfkcRVXzgoE/';

sub new_ca {
    writefile('serial', "01\n", 1);

    writefile('ssl.htpasswd',
              join ':', dn_oneline('client_snakeoil'),
              $basic_auth_password);

    openssl req => "-new -x509 -keyout $cakey -out $cacert $days",
                   config('ca');

    export_cert('ca'); #useful for importing into IE
}

sub new_key {
    my $name = shift;

    my $encrypt = @_ ? "@_ $passout" : "";

    my $out = "-out keys/$name.pem $encrypt";

    if ($name =~ /dsa/) {
        #this takes a long time so just do it once
        #don't do this in real life
        unless (-e 'dsa-param') {
            openssl dsaparam => '-inform PEM -out dsa-param 2048';
        }
        openssl gendsa => "$out dsa-param";
    }
    else {
        openssl genrsa => "$out 2048";
    }
}

sub new_cert {
    my $name = shift;

    openssl req => "-new -key keys/$name.pem -out csr/$name.csr",
                   $passin, $passout, config($name);

    sign_cert($name);

    export_cert($name);
}

sub sign_cert {
    my $name = shift;
    my $exts = '';

    $exts = ' -extensions client_ok_ext' if $name =~ /client_ok/;

    $exts = ' -extensions server_ext' if $name =~ /server/;

    openssl ca => "$capolicy -in csr/$name.csr -out certs/$name.crt",
                  $passin, config($name), '-batch', $exts;
}

#handy for importing into a browser such as netscape
sub export_cert {
    my $name = shift;

    return if $name =~ /^server/; #no point in exporting server certs

    openssl pkcs12 => "-export -in certs/$name.crt -inkey keys/$name.pem",
                      "-out export/$name.p12", $passin, $passout;
}

sub revoke_cert {
    my $name = shift;

    my @args = (config('cacrl'), $passin);

    #revokes in the SSLCA_DB database
    openssl ca => "-revoke certs/$name.crt", @args;

    #generates crl from the index.txt database
    openssl ca => "-gencrl -out $cacrl", @args;
}

sub symlink {
    my($file, $symlink) = @_;

    my $what = 'linked';

    if (Apache::TestConfig::WINFU) {
        cp $file, $symlink;
        $what = 'copied';
    }
    else {
        CORE::symlink($file, $symlink);
    }

    info "$what $file to $symlink";
}

sub hash_certs {
    my($type, $dir) = @_;

    chdir $dir;

    my $dh = DirHandle->new('.') or die "opendir $dir: $!";
    my $n = 0;

    for my $file ($dh->read) {
        next unless $file =~ /\.cr[tl]$/;
        chomp(my $hash = `$openssl $type -noout -hash < $file`);
        next unless $hash;
        my $symlink = "$hash.r$n";
        $n++;
        symlink $file, $symlink;
    }

    close $dh;

    chdir $CA;
}

sub make_proxy_cert {
    my $name = shift;

    my $from = "certs/$name.crt";
    my $to = "proxy/$name.pem";

    info "generating proxy cert: $to";

    my $fh_to = Symbol::gensym();
    my $fh_from = Symbol::gensym();

    open $fh_to, ">$to" or die "open $to: $!";
    open $fh_from, $from or die "open $from: $!";

    cp $fh_from, $fh_to;

    $from = "keys/$name.pem";

    open $fh_from, $from or die "open $from: $!";

    cp $fh_from, $fh_to;

    close $fh_from;
    close $fh_to;
}

sub setup {
    $CA = shift;

    unless ($ca_dn->{$CA}) {
        die "unknown CA $CA";
    }

    gendir($CA);

    chdir $CA;

    init();
    new_ca();

    my @names = keys %$cert_dn;

    for my $name (@names) {
        my @key_args = ();
        if ($name =~ /_des3/) {
            push @key_args, '-des3';
        }

        new_key($name, @key_args);
        new_cert($name);

        if ($name =~ /_revoked$/) {
            revoke_cert($name);
        }

        if ($name =~ /^client_/) {
            make_proxy_cert($name);
        }
    }

    hash_certs(crl => 'crl');
}

sub generate {
    $Config = shift;

    $CA = shift || $Config->{vars}->{sslcaorg};

    my $root = $Config->{vars}->{sslca};

    return if -d $root;

    my $pwd  = Cwd::cwd();
    my $base = dirname $root;
    my $dir  = basename $root;

    chdir $base;

    # Ensure the CNs used in the server certs match up with the
    # hostname being used for testing.
    while (my($key, $val) = each %$cert_dn) {
        next unless $key =~ /^server/;
        $val->{CN} = $Config->{vars}->{servername};
    }        

    #make a note that we created the tree
    $Config->clean_add_path($root);

    gendir($dir);

    chdir $dir;

    warning "generating SSL CA for $CA";

    setup($CA);

    chdir $pwd;
}

sub clean {
    my $config = shift;

    #rel2abs adds same drive letter for win32 that clean_add_path added
    my $dir = File::Spec->rel2abs($config->{vars}->{sslca});

    unless ($config->{clean}->{dirs}->{$dir}) {
        return; #we did not generate this ca
    }

    unless ($config->{clean_level} > 1) {
        #skip t/TEST -conf
        warning "skipping regeneration of SSL CA; run t/TEST -clean to force";
        return;
    }

    File::Path::rmtree([$dir], 1, 1);
}

#not using Apache::TestConfig methods because the openssl commands
#will generate heaps of files we cannot keep track of

sub writefile {
    my($file, $content) = @_;

    my $fh = Symbol::gensym();
    open $fh, ">$file" or die "open $file: $!";
    print $fh $content;
    close $fh;
}

sub gendir {
    my($dir) = @_;

    return if -d $dir;
    mkdir $dir, 0755;
}

sub version {
    my $devnull = devnull();
    my $version = qx($openssl version 2>$devnull);
    return $1 if $version =~ /^\S+SSL (\S+)/;
    die "FATAL: unable to determine openssl version via `$openssl version` from: $version";
}

sub dgst {
    return $dgst;
}

sub email_field {
    return $email_field;
}

sub sslproto {
    return $sslproto;
}

1;
__END__
