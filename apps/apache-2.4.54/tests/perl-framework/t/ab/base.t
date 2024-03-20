use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestConfig;
use Apache::TestUtil qw(t_debug);
use IPC::Open3;
use Symbol;
use File::Spec::Functions qw(catfile);
use Data::Dumper;

my $vars = Apache::Test::vars();

plan tests => ($vars->{ssl_module_name} ? 5 : 2);

sub run_and_gather_output {
    my $command = shift;
    t_debug "# running: ", $command, "\n";
    my ($cin, $cout, $cerr);
    $cerr = gensym();
    my $pid = open3($cin, $cout, $cerr, $command);
    waitpid( $pid, 0 );
    my $status = $? >> 8;
    my @cstdout = <$cout>;
    my @cstderr = <$cerr>;
    return { status => $status, stdout => \@cstdout, stderr => \@cstderr };
}

my $ab_path = catfile $vars->{bindir}, "ab";

my $http_url = Apache::TestRequest::module2url("core", {scheme => 'http', path => '/'});
my $http_results = run_and_gather_output("ASAN_OPTIONS='detect_leaks=0' $ab_path -B 127.0.0.1 -q -n 10 $http_url");
ok $http_results->{status}, 0;
ok scalar(@{$http_results->{stderr}}), 0;

if ($vars->{ssl_module_name}) {
    my $https_url = Apache::TestRequest::module2url($vars->{ssl_module_name}, {scheme => 'https', path => '/'});
    my $https_results = run_and_gather_output("ASAN_OPTIONS='detect_leaks=0' $ab_path -B 127.0.0.1 -q -n 10 $https_url");
    ok $https_results->{status}, 0;
    ok (scalar(@{$https_results->{stderr}}), 0, 
        "https had stderr output:" . Dumper $https_results->{stderr});

    #XXX: For some reason, stderr is getting pushed into stdout. This test will at least catch known SSL failures
    ok (scalar(grep(/SSL.*(fail|err)/i, @{$https_results->{stdout}})), 0, 
        "https stdout had some possibly alarming content:" .  Dumper $https_results->{stdout} );
}
