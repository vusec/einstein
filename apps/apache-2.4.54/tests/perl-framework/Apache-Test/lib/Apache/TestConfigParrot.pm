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
package Apache::TestConfigParrot;

#things specific to mod_parrot

use strict;
use warnings FATAL => 'all';
use File::Spec::Functions qw(catfile splitdir abs2rel);
use File::Find qw(finddepth);
use Apache::TestTrace;
use Apache::TestRequest;
use Apache::TestConfig;
use Apache::TestConfigPerl;
use Config;

@Apache::TestConfigParrot::ISA = qw(Apache::TestConfig);

sub new {
    return shift->SUPER::new(@_);
}

sub configure_parrot_tests_pick {
    my($self, $entries) = @_;

    for my $subdir (qw(Response)) {
        my $dir = catfile $self->{vars}->{t_dir}, lc $subdir;
        next unless -d $dir;

        finddepth(sub {
            return unless /\.pir$/;

            my $file = catfile $File::Find::dir, $_;
            my $module = abs2rel $file, $dir;
            my $status = $self->run_apache_test_config_scan($file);
            push @$entries, [$file, $module, $subdir, $status];
        }, $dir);
    }
}

sub configure_parrot_tests {
    my $self = shift;

    my @entries = ();
    $self->configure_parrot_tests_pick(\@entries);
    $self->configure_pm_tests_sort(\@entries);

    my %seen = ();

    for my $entry (@entries) {
        my ($file, $module, $subdir, $status) = @$entry;

        my @args = ();

        my $directives = $self->add_module_config($file, \@args);

        $module =~ s,\.pir$,,;
        $module =~ s/^[a-z]://i; #strip drive if any
        $module = join '::', splitdir $module;

        my @base = map { s/^test//i; $_ } split '::', $module;

        my $sub = pop @base;

        debug "configuring mod_parrot test file $file";

        push @args, SetHandler => 'parrot-code';
        push @args, ParrotHandler => $module;

        $self->postamble(ParrotLoad => $file);
        $self->postamble($self->location_container($module), \@args);

        $self->write_pm_test($module, lc $sub, map { lc } @base);
    }
}

1;

__DATA__
