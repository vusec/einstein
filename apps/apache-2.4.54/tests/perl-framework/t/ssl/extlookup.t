use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

Apache::TestRequest::scheme("https");

my %exts = (
   "2.16.840.1.113730.1.13" => "This Is A Comment"
);

if (have_min_apache_version("2.4.0")) { 
   $exts{"1.3.6.1.4.1.18060.12.0"} = "Lemons",
}

plan tests => 2 * (keys %exts), need 'test_ssl', need_min_apache_version(2.1);

my ($actual, $expected, $r, $c);

foreach (sort keys %exts) {
    $r = GET("/test_ssl_ext_lookup?$_", cert => 'client_ok');
    
    ok t_cmp($r->code, 200, "ssl_ext_lookup works for $_");

    $c = $r->content;
    chomp $c;

    ok t_cmp($c, $exts{$_}, "Extension value match for $_");
}

