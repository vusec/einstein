use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

#test output of some other modules
my %urls = (
    mod_php4        => '/php/hello.php',
    mod_cgi         => '/modules/cgi/perl.pl',
    mod_test_rwrite => '/test_rwrite',
    mod_alias       => '/getfiles-perl-pod/perlsub.pod',
);

my @filter = ('X-AddOutputFilter' => 'CaseFilter'); #mod_client_add_filter

for my $module (keys %urls) {
    delete $urls{$module} unless have_module($module);
}

my $tests = 1 + scalar keys %urls;

plan tests => $tests, need_module 'case_filter';

verify(GET '/', @filter);

for my $module (sort keys %urls) {
    my $r = GET $urls{$module}, @filter;
    print "# testing $module with $urls{$module}\n";
    print "# expected 200\n";
    print "# received ".$r->code."\n";
    print "# body: ".$r->content."\n";
    verify($r);
}

sub verify {
    my $r = shift;
    my $body = $r->content;

    ok $r->code == 200 and $body
      and $body =~ /[A-Z]/ and $body !~ /[a-z]/;
}
