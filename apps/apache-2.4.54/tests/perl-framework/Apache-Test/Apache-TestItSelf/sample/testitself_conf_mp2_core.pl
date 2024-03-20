# This is a config file for testing modperl 2.0 core

use strict;
use warnings FATAL => 'all';

my $base = "/home/$ENV{USER}";

my $perl_base    = "$base/perl";
my $perl_ver     = "5.8.8-ithread";
my $PERL         = "$perl_base/$perl_ver/bin/perl$perl_ver";

my $httpd_base   = "$base/httpd/svn";
my $httpd_gen    = '2.0';
my $httpd_ver    = 'Apache/2.2.3';
my @mpms         = (qw(prefork worker));

my $mp_gen       = 2.0;
my $mod_perl_so  = "mod_perl-$perl_ver.so";
my $common_makepl_arg = "MP_MAINTAINER=1";

%Apache::TestItSelf::Config = (
    repos_type    => 'mp2_core',
    perl_exec     => $PERL,
    mp_gen        => $mp_gen,
    httpd_gen     => $httpd_gen,
    httpd_version => $httpd_ver,,
    timeout       => 900, # make test may take a long time
    test_verbose  => 0,
);

@Apache::TestItSelf::Configs = ();
foreach my $mpm (@mpms) {
    push @Apache::TestItSelf::Configs,
        {
         apxs_exec     => "$httpd_base/$mpm/bin/apxs",
         httpd_exec    => "$httpd_base/$mpm/bin/httpd",
         httpd_conf    => "$httpd_base/$mpm/conf/httpd.conf",
         httpd_mpm     => $mpm,
         makepl_arg    => "MP_APXS=$httpd_base/$mpm/bin/apxs $common_makepl_arg",
        };
}

1;
