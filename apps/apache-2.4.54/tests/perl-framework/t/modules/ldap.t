use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

#
# To run tests for mod_authnz_ldap:
#
# a) run an LDAP server with root DN of dc=example,dc=com on localhost port 8389
# b) populate the directory with the LDIF from scripts/httpd.ldif
# c) configure & run the test suite passing "--defines LDAP" to ./t/TEST
#

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;
use Apache::TestConfig;

my $defs = Apache::Test->vars('defines');
my $ldap_defined = $defs =~ /LDAP/;

# URL -> username, password, expected-status
my @cases = (
    ['/modules/ldap/simple/' => '', '', 401],
    ['/modules/ldap/simple/' => 'alpha', 'badpass', 401],
    ['/modules/ldap/simple/' => 'alpha', 'Alpha', 200],
    ['/modules/ldap/simple/' => 'gamma', 'Gamma', 200],
    ['/modules/ldap/group/' => 'gamma', 'Gamma', 401],
    ['/modules/ldap/group/' => 'delta', 'Delta', 200],
    ['/modules/ldap/refer/' => 'alpha', 'Alpha', 401],
    ['/modules/ldap/refer/' => 'beta', 'Beta', 200],
);

plan tests => scalar @cases,
    need need_module('authnz_ldap'), { "LDAP testing not configured" => $ldap_defined };

foreach my $t (@cases) {
    my $url = $t->[0];
    my $username = $t->[1];
    my $password = $t->[2];
    my $response;
    my $creds;

    if ($username) {
        $response = GET $url, username => $username, password => $password;
        $creds = "$username/$password";
    }
    else {
        $response = GET $url;
        $creds = "no credentials";
    }

    ok t_cmp($response->code, $t->[3], "test for $url with $creds");
}
