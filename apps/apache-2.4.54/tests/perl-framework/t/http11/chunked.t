use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

Apache::TestRequest::user_agent(keep_alive => 1);

Apache::TestRequest::scheme('http')
  unless have_module 'LWP::Protocol::https10'; #lwp 5.60

#In httpd-2.0, chunked encoding is optional and will only be used
#if response is > 4*AP_MIN_BYTES_TO_WRITE (see server/protocol.c)

my @small_sizes = (100, 5000);
my @chunk_sizes = (25432, 75962, 100_000, 300_000);

my $tests = (@chunk_sizes + @small_sizes) * 5;

if (! have_module 'random_chunk') {
    print "# Skipping; missing prerequisite module 'random_chunk'\n";
}
plan tests => $tests, need_module 'random_chunk';

my $location = '/random_chunk';
my $requests = 0;

sub expect_chunked {
    my $size = shift;
    sok sub {
        my $res = GET "/random_chunk?0,$size";
        my $body = $res->content;
        my $length = 0;

        if ($body =~ s/__END__:(\d+)$//) {
            $length = $1;
        }

        ok t_cmp($res->protocol,
                 "HTTP/1.1",
                 "response protocol"
                );

        my $enc = $res->header('Transfer-Encoding') || 
                  $res->header('Client-Transfer-Encoding') || #lwp 5.61+
                  '';
        my $ct  = $res->header('Content-Length') || 0;

        ok t_cmp($enc,
                 "chunked",
                 "response Transfer-Encoding"
                );

        ok t_cmp($ct,
                 0,
                 "no Content-Length"
                );

        ok t_cmp(length($body),
                 $length,
                 "body length"
                );

        $requests++;
        my $request_num =
          Apache::TestRequest::user_agent_request_num($res);

        return t_cmp($request_num,
                     $requests,
                     "number of requests"
                    );
    }, 5;
}

sub expect_not_chunked {
    my $size = shift;
    sok sub {
        my $res = GET "/random_chunk?0,$size";
        my $body = $res->content;
        my $content_length = length $res->content;
        my $length = 0;

        if ($body =~ s/__END__:(\d+)$//) {
            $length = $1;
        }

        ok t_cmp($res->protocol,
                 "HTTP/1.1",
                 "response protocol"
                );

        my $enc = $res->header('Transfer-Encoding') || '';
        my $ct  = $res->header('Content-Length') || '';

        ok !t_cmp($enc,
                  "chunked",
                  "no Transfer-Encoding (test result inverted)"
                 );

        ok t_cmp($ct,
                 (($ct eq '') ? $ct : $content_length),
                 "content length"
                );

        ok t_cmp(length($body),
                 $length,
                 "body length"
                );

        $requests++;
        my $request_num =
          Apache::TestRequest::user_agent_request_num($res);

        return t_cmp($request_num,
                     $requests,
                     "number of requests"
                    );
    }, 5;
}

for my $size (@chunk_sizes) {
    expect_chunked $size;
}

for my $size (@small_sizes) {
    if (have_apache 1) {
        expect_chunked $size;
    }
    else {
        expect_not_chunked $size;
    }
}
