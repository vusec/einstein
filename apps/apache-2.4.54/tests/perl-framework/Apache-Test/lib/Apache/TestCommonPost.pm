# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
package Apache::TestCommonPost;

use strict;
use warnings FATAL => 'all';

use constant POST_HUGE => $ENV{APACHE_TEST_POST_HUGE} || 0;

use Apache::TestRequest ();
use Apache::TestUtil qw(t_cmp t_debug);
use Apache::Test qw(sok);

use lib "$ENV{'ROOT'}/apps/scripts/perl-tests";
require EinsteinTests;

BEGIN {
    my $use_inline = 0;

    eval {
        #if Inline.pm and libcurl are available
        #we can make this test about 3x faster,
        #after the inlined code is compiled that is.
        require Inline;
        Inline->import(C => 'DATA', LIBS => ['-lcurl'],
                       #CLEAN_AFTER_BUILD => 0,
                       PREFIX => 'aptest_post_');
        *request_init = \&curl_init;
        *request_do   = \&curl_do;
        $use_inline = 1;
    } if POST_HUGE;

    if (POST_HUGE) {
        if ($@) {
            t_debug "tests will run faster with Inline and curl installed";
            print $@;
        }
        else {
            t_debug "using Inline and curl client";
        }
    }

    unless ($use_inline) {
        t_debug "using LWP client";
        #fallback to lwp
        *request_init = \&lwp_init;
        *request_do   = \&lwp_do;
    }
}

sub lwp_init {
    use vars qw($UA $Location);
    $UA = Apache::TestRequest::user_agent();
    $Location = shift;
}

sub lwp_do {
    EinsteinTests::send_test_info('../..');

    my $length = shift;

    my $request = HTTP::Request->new(POST => $Location);
    $request->header('Content-length' => $length);

    if (LWP->VERSION >= 5.800) {
        $request->content_ref(\('a' x $length));
    } else {
        # before LWP 5.800 there was no way to tell HTTP::Message not
        # to copy the string, there is a settable content_ref since
        # 5.800
        use constant BUF_SIZE => 8192;

        my $remain = $length;
        my $content = sub {
            my $bytes = $remain < BUF_SIZE ? $remain : BUF_SIZE;
            my $buf = 'a' x $bytes;
            $remain -= $bytes;
            $buf;
        };

        $request->content($content);
    }



    my $response = $UA->request($request);

    Apache::TestRequest::lwp_trace($response);

    return $response->content;
}

my @run_post_test_small_sizes =
  #1k..9k, 10k..50k, 100k
  (1..9, 10..50, 100);

my @run_post_test_sizes = @run_post_test_small_sizes;

if (POST_HUGE) {
    push @run_post_test_sizes,
      #300k, 500k, 2Mb, 4Mb, 6Mb, 10Mb
      300, 500, 2000, 4000, 6000, 10_000;
}

sub Apache::TestCommon::run_post_test_sizes { @run_post_test_sizes }

sub Apache::TestCommon::run_post_test {
    my $module = shift;
    my $sizes = shift || \@run_post_test_sizes;

    my $location = Apache::TestRequest::resolve_url("/$module");

    request_init($location);

    for my $size (@$sizes) {
        sok {
            my $length = ($size * 1024);

            my $str = request_do($length);
            chomp $str;

            t_cmp($length, $str, "length posted");
        };
    }
}

1;
__DATA__

__C__

#include <curl/curl.h>
#include <curl/easy.h>

static CURL *curl = NULL;
static SV *response = (SV *)NULL;
static long total = 0;

static size_t my_curl_read(char *buffer, size_t size,
                           size_t nitems, void *data)
{
    size_t bytes = nitems < total ? nitems : total;
    memset(buffer, 'a', bytes);
    total -= bytes;
    return bytes;
}

static size_t my_curl_write(char *buffer, size_t size,
                            size_t nitems, void *data)
{
    sv_catpvn(response, buffer, nitems);
    return nitems;
}

void aptest_post_curl_init(char *url)
{
    char *proto = "HTTP/1.1"; /* curl default */
    curl = curl_easy_init();
    curl_easy_setopt(curl, CURLOPT_MUTE, 1);
    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "POST");
    curl_easy_setopt(curl, CURLOPT_UPLOAD, 1);
    curl_easy_setopt(curl, CURLOPT_READFUNCTION, my_curl_read);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, my_curl_write);
    if (!getenv("APACHE_TEST_HTTP11")) {
        curl_easy_setopt(curl, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_1_0);
        proto = "HTTP/1.0";
    }
    fprintf(stdout, "#CURL using protocol %s\n", proto);
    fflush(stdout);
    response = newSV(0);
}

SV *aptest_post_curl_do(long len)
{
    sv_setpv(response, "");
    total = len;
    curl_easy_setopt(curl, CURLOPT_INFILESIZE, len);
    curl_easy_perform(curl);
    return SvREFCNT_inc(response);
}

void aptest_post_END(void)
{
    if (response) {
        SvREFCNT_dec(response);
    }
    if (curl) {
        curl_easy_cleanup(curl);
    }
}
