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
package Apache::TestHarnessPHP;

use strict;
use warnings FATAL => 'all';

use File::Spec::Functions qw(catfile catdir);
use File::Find qw(finddepth);
use Apache::TestHarness ();
use Apache::TestTrace;
use Apache::TestConfig ();

use vars qw(@ISA);
@ISA = qw(Apache::TestHarness);
use TAP::Formatter::Console;
use TAP::Harness;

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
                push(@tests, sort <$base/$_/*.php>);
            }
            else {
                $_ .= ".t" unless /(\.t|\.php)$/;
                push(@tests, $_);
            }
        }
    }
    else {
        if ($args->{tdirs}) {
            push @tests, map { sort <$base/$_/*.t> } @{ $args->{tdirs} };
            push @tests, map { sort <$base/$_/*.php> } @{ $args->{tdirs} };
        }
        else {
            finddepth(sub {
                          return unless /\.(t|php)$/;
                          return if $File::Find::dir =~ m/\b(conf|htdocs|logs|response)\b/;
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

    # remove *.php tests unless we can run them with php
    if (! Apache::TestConfig::which('php')) {
        warning(join ' - ', 'skipping *.php tests',
                            'make sure php is in your PATH');
        @tests = grep { not /\.php$/ } @tests;
    }
    elsif (! $phpclient) {
        warning(join ' - ', 'skipping *.php tests',
                            'Test::Harness 2.38 not available');
        @tests = grep { not /\.php$/ } @tests;
    }

    return @tests;
}

sub run {
    my $self = shift;
    my $args = shift || {};
    my $formatter = TAP::Formatter::Console->new;
    my $agg       = TAP::Parser::Aggregator->new;
    my $verbose   = $args->{verbose} && $args->{verbose};
    my $php_harness = TAP::Harness->new
      ({exec      => $self->command_line(),
       verbosity  => $verbose});
    my $perl_harness = TAP::Harness->new
      ({verbosity  => $verbose});
    my @tests = $self->get_tests($args, @_);

    $agg->start();
    $php_harness->aggregate_tests($agg, grep {m{\.php$}} @tests);
    $perl_harness->aggregate_tests($agg, grep {m{\.t$}} @tests);
    $agg->stop();

    $formatter->summary($agg);
}

sub command_line {
    my $self = shift;

    my $server_root = Apache::Test::vars('serverroot');

    my $conf = catfile($server_root, 'conf');

    my $ini = catfile($conf, 'php.ini');

    my $php = Apache::TestConfig::which('php') ||
        die 'no php executable found in ' . $ENV{PATH};

    return ["env", "SERVER_ROOT=$server_root",
            $php, "--php-ini",  $ini, "--define", "include_path=$conf"];
}

1;
