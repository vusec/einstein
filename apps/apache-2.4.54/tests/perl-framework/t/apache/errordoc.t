use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

Apache::TestRequest::module('error_document');

plan tests => 14, need_lwp;

# basic ErrorDocument tests

{
    my $response = GET '/notfound.html';
    chomp(my $content = $response->content);

    ok t_cmp($response->code,
             404,
             'notfound.html code');

    ok t_cmp($content,
             qr'per-server 404',
             'notfound.html content');
}

{
    my $response = GET '/inherit/notfound.html';
    chomp(my $content = $response->content);

    ok t_cmp($response->code,
             404,
             '/inherit/notfound.html code');

    ok t_cmp($content,
             qr'per-server 404',
             '/inherit/notfound.html content');
}

{
    my $response = GET '/redefine/notfound.html';
    chomp(my $content = $response->content);

    ok t_cmp($response->code,
             404,
             '/redefine/notfound.html code');

    ok t_cmp($content,
             'per-dir 404',
             '/redefine/notfound.html content');
}

{
    my $response = GET '/restore/notfound.html';
    chomp(my $content = $response->content);

    ok t_cmp($response->code,
             404,
             '/redefine/notfound.html code');

    # 1.3 requires quotes for hard-coded messages
    my $expected = have_min_apache_version('2.0.51') ? qr/Not Found/ :
                   have_apache(2)                    ? 'default'     : 
                   qr/Additionally, a 500/;

    ok t_cmp($content,
             $expected,
             '/redefine/notfound.html content');
}

{
    my $response = GET '/apache/notfound.html';
    chomp(my $content = $response->content);

    ok t_cmp($response->code,
             404,
             '/merge/notfound.html code');

    ok t_cmp($content,
             'testing merge',
             '/merge/notfound.html content');
}

{
    my $response = GET '/apache/etag/notfound.html';
    chomp(my $content = $response->content);

    ok t_cmp($response->code,
             404,
             '/merge/merge2/notfound.html code');

    ok t_cmp($content,
             'testing merge',
             '/merge/merge2/notfound.html content');
}

{
    my $response = GET '/bounce/notfound.html';
    chomp(my $content = $response->content);

    ok t_cmp($response->code,
             404,
             '/bounce/notfound.html code');

    ok t_cmp($content,
             qr!expire test!,
             '/bounce/notfound.html content');
}
