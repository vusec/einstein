use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

#test output of some other modules
my %urls = (
    mod_php4      => '/php/var3u.php',
    mod_cgi       => '/modules/cgi/perl_echo.pl',
    mod_echo_post => '/echo_post',
);

my @filter = ('X-AddInputFilter' => 'CaseFilterIn'); #mod_client_add_filter

for my $module (keys %urls) {
    delete $urls{$module} unless have_module($module);
}

my $tests = 1 + scalar keys %urls;

plan tests => $tests, need_module 'case_filter_in';

ok 1;

my $data = "v1=one&v3=two&v2=three";

for my $module (sort keys %urls) {
    my $r = POST $urls{$module}, @filter, content => $data;
    print "# testing $module with $urls{$module}\n";
    print "# expected 200\n";
    print "# received ".$r->code."\n";
    verify($r);
}

sub verify {
    my $r = shift;
    my $body = $r->content;

    ok $r->code == 200 and $body
      and $body =~ /[A-Z]/ and $body !~ /[a-z]/;
}
