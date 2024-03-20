use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;
use MIME::Base64;
use Data::Dumper;
use HTTP::Response;
use Socket;

use LWP::UserAgent ();
 

my @testcases = (
    ['/apache/ratelimit/'                    => '200', "ratelimited small file"],
    ['/apache/ratelimit/autoindex/'          => '200', "ratelimited small autoindex output"],
    ['/apache/ratelimit/chunk?0,8192'        => '200', "ratelimited chunked response"],
);

plan tests => scalar @testcases, need need_lwp,
                 need_module('mod_ratelimit'),
                 need_module('mod_autoindex'),
                 need_min_apache_version('2.4.35');

my $ua = LWP::UserAgent->new;
$ua->timeout(4);

foreach my $t (@testcases) {
    my $r;

    # trap a die() in WLP when the the status line is invalid to avoid
    # 'dubious test...' instead of just a failure.
    eval { $r = GET($t->[0]) ;
        chomp $r;
        t_debug "Status Line: '" .  $r->status_line . "'";
        ok t_cmp($r->code, $t->[1], $t->[2]);
    }; 
    # Check if the eval() die'ed
    ok t_cmp($@, undef, $t->[2]) if $@
 
}

