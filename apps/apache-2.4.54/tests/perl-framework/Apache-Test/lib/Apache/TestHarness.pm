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
package Apache::TestHarness;

use strict;
use warnings FATAL => 'all';

use Test::Harness ();
use Apache::Test ();
use Apache::TestSort ();
use Apache::TestTrace;
use File::Spec::Functions qw(catfile catdir);
use File::Find qw(finddepth);
use File::Basename qw(dirname);

use Data::Dumper;
use lib "$ENV{'ROOT'}/apps/scripts/perl-tests";
require EinsteinTests;

sub inc_fixup {
    # use blib
    unshift @INC, map "blib/$_", qw(lib arch);

    # fix all relative library locations
    for (@INC) {
        $_ = "../$_" unless m,^(/)|([a-f]:),i;
    }
}

#skip tests listed in t/SKIP
sub skip {
    my($self, $file) = @_;
    $file ||= catfile Apache::Test::vars('serverroot'), 'SKIP';

    return unless -e $file;

    my $fh = Symbol::gensym();
    open $fh, $file or die "open $file: $!";
    my @skip;
    local $_;

    while (<$fh>) {
        chomp;
        s/^\s+//; s/\s+$//; s/^\#.*//;
        next unless $_;
        s/\*/.*/g;
        push @skip, $_;
    }

    close $fh;
    return join '|', @skip;
}

#test if all.t would skip tests or not
{
    my $source_lib = '';

    sub run_t {
        my($self, $file) = @_;
        my $ran = 0;

        if (Apache::TestConfig::IS_APACHE_TEST_BUILD and !length $source_lib) {
            # so we can find Apache/Test.pm from both the perl-framework/
            # and Apache-Test/

            my $top_dir = Apache::Test::vars('top_dir');
            foreach my $lib (catfile($top_dir, qw(Apache-Test lib)),
                             catfile($top_dir, qw(.. Apache-Test lib)),
                             catfile($top_dir, 'lib')) {

                if (-d $lib) {
                    info "adding source lib $lib to \@INC";
                    $source_lib = qq[-Mlib="$lib"];
                    last;
                }
            }
        }

        my $cmd = qq[$^X $source_lib $file];

        my $h = Symbol::gensym();
        open $h, "$cmd|" or die "open $cmd: $!";

        local $_;
        while (<$h>) {
            if (/^1\.\.(\d)/) {
                $ran = $1;
                last;
            }
        }

        close $h;

        $ran;
     }
}

#if a directory has an all.t test
#skip all tests in that directory if all.t prints "1..0\n"
sub prune {
    my($self, @tests) = @_;
    my(@new_tests, %skip_dirs);

    foreach my $test (@tests) {
        next if $test =~ /\.#/; # skip temp emacs files
        my $dir = dirname $test;
        if ($test =~ m:\Wall\.t$:) {
            unless (__PACKAGE__->run_t($test)) {
                $skip_dirs{$dir} = 1;
                @new_tests = grep { m:\Wall\.t$: ||
                                    not $skip_dirs{dirname $_} } @new_tests;
                push @new_tests, $test;
            }
        }
        elsif (!$skip_dirs{$dir}) {
            push @new_tests, $test;
        }
    }

    @new_tests;
}

sub get_tests {
    my $self = shift;
    my $args = shift;
    my @tests = ();

    my $base = -d 't' ? catdir('t', '.') : '.';

    my $ts = $args->{tests} || [];

    if (@$ts) {
        for (@$ts) {
            if (-d $_) {
                push(@tests, sort <$base/$_/*.t>);
            }
            else {
                $_ .= ".t" unless /\.t$/;
                push(@tests, $_);
            }
        }
    }
    else {
        if ($args->{tdirs}) {
            push @tests, map { sort <$base/$_/*.t> } @{ $args->{tdirs} };
        }
        else {
            finddepth(sub {
                          return unless /\.t$/;
                          my $t = catfile $File::Find::dir, $_;
                          my $dotslash = catfile '.', "";
                          $t =~ s:^\Q$dotslash::;
                          push @tests, $t
                      }, $base);
            @tests = sort @tests;
        }
    }

    @tests = $self->prune(@tests);

    if (my $skip = $self->skip) {
        # Allow / \ and \\ path delimiters in SKIP file
        $skip =~ s![/\\\\]+![/\\\\]!g;

        @tests = grep { not /(?:$skip)/ } @tests;
    }

    Apache::TestSort->run(\@tests, $args);

    #when running 't/TEST t/dir' shell tab completion adds a /
    #dir//foo output is annoying, fix that.
    s:/+:/:g for @tests;

    return @tests;
}

sub run {
    my $self = shift;
    my $args = shift || {};

    $Test::Harness::verbose ||= $args->{verbose};

    if (my(@subtests) = @{ $args->{subtests} || [] }) {
        $ENV{HTTPD_TEST_SUBTESTS} = "@subtests";
    }

    my (@tests_to_run) = $self->get_tests($args, @_);
    print (STDERR "---- tests_to_run:" . Dumper(@tests_to_run) . "\n");

    foreach my $test_to_run (@tests_to_run) {
        sleep(0.5);
        print(STDERR "==== TestHarness:run: Tainting all memory...\n");
        EinsteinTests::send_test_info('../..');
        system('env -C ../.. ./serverctl udscmd pids dbt taintall');
        sleep(0.5);
        print (STDERR "==== TestHarness:run: Running test '" . $test_to_run . "'...\n");
        Test::Harness::runtests($test_to_run);
    }
}

1;
