# This is a config file for testing modperl 2.0 Apache:: 3rd party modules

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

%Apache::TestItSelf::Config = (
    repos_type    => 'mp2_cpan_modules',
    perl_exec     => $PERL,
    mp_gen        => $mp_gen,
    httpd_gen     => $httpd_gen,
    httpd_version => $httpd_ver,
    timeout       => 200,
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
         makepl_arg    => "MOD_PERL=2 -libmodperl $httpd_base/$mpm/modules/$mod_perl_so",
        };
}

1;
