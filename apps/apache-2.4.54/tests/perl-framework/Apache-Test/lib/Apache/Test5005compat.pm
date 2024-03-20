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
package Apache::Test5005compat;

use strict;
use Symbol ();
use File::Basename;
use File::Path;

$Apache::Test5005compat::VERSION = '0.01';

my %compat_files = (
     'lib/warnings.pm' => \&warnings_pm,
);

sub import {
    if ($] >= 5.006) {
        #make sure old compat stubs dont wipe out installed versions
        unlink for keys %compat_files;
        return;
    }

    eval { require File::Spec::Functions; } or
      die "this is only Perl $], you need to install File-Spec from CPAN";

    my $min_version = 0.82;
    unless ($File::Spec::VERSION >= $min_version) {
        die "you need to install File-Spec-$min_version or higher from CPAN";
    }

    while (my($file, $sub) = each %compat_files) {
        $sub->($file);
    }
}

sub open_file {
    my $file = shift;

    unless (-d 'lib') {
        $file = "Apache-Test/$file";
    }

    my $dir = dirname $file;

    unless (-d $dir) {
        mkpath([$dir], 0, 0755);
    }

    my $fh = Symbol::gensym();
    print "creating $file\n";
    open $fh, ">$file" or die "open $file: $!";

    return $fh;
}

sub warnings_pm {
    return if eval { require warnings };

    my $fh = open_file(shift);

    print $fh <<'EOF';
package warnings;

sub import {}

1;
EOF

    close $fh;
}

1;
