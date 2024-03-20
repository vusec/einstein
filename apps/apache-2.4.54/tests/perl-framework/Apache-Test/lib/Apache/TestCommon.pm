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
package Apache::TestCommon;

use strict;
use warnings FATAL => 'all';

use File::Basename;

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;
use Apache::TestCommonPost ();

#this module contains common tests that are called from different .t files

#t/apache/passbrigade.t
#t/apache/rwrite.t

sub run_write_test {
    my $module = shift;

    #1k..9k, 10k..50k, 100k, 300k, 500k, 2Mb, 4Mb, 6Mb, 10Mb
    my @sizes = (1..9, 10..50, 100, 300, 500, 2000, 4000, 6000, 10_000);
    my @buff_sizes = (1024, 8192);

    plan tests => @sizes * @buff_sizes, [$module, 'LWP'];

    my $location = "/$module";
    my $ua = Apache::TestRequest::user_agent();

    for my $buff_size (@buff_sizes) {
        for my $size (@sizes) {
            my $length = $size * 1024;
            my $received = 0;

            $ua->do_request(GET => "$location?$buff_size,$length",
                            sub {
                                my($chunk, $res) = @_;
                                $received += length $chunk;
                            });

            ok t_cmp($received, $length, 'bytes in body');
        }
    }
}

sub run_files_test {
    my($verify, $skip_other) = @_;

    my $vars = Apache::Test::vars();
    my $perlpod = $vars->{perlpod};

    my %pod = (
        files => [],
        num   => 0,
        url   => '/getfiles-perl-pod',
        dir   => "",
    );

    if (-d $perlpod) {
        my @files = map { basename $_ } <$perlpod/*.pod>;
        $pod{files} = \@files;
        $pod{num} = scalar @files;
        $pod{dir} = $perlpod;
    }
    else {
        push @Apache::Test::SkipReasons,
          "dir $vars->{perlpod} does not exist";
    }

    my %other_files = ();

    unless ($skip_other) { #allow to skip the large binary files
        %other_files = map {
            ("/getfiles-binary-$_", $vars->{$_})
        } qw(httpd perl);
    }

    my $tests = $pod{num} + keys(%other_files);

    plan tests => $tests, sub { $pod{num} and have_lwp() };

    my $ua = Apache::TestRequest::user_agent();

    for my $file (@{ $pod{files} }) {
        $verify->($ua, "$pod{url}/$file", "$pod{dir}/$file");
    }

    for my $url (sort keys %other_files) {
        $verify->($ua, $url, $other_files{$url});
    }
}

1;
__END__
