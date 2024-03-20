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
#no 'package Apache::TestPerlDB.pm' here, else we change perldb's package
use strict;

sub Apache::TestPerlDB::lwpd {
    print Apache::TestRequest::lwp_debug(shift || 1);
}

sub Apache::TestPerlDB::bok {
    my $n = shift || 1;
    print "breakpoint set at test $n\n";
    DB::cmd_b_sub('ok', "\$Test::ntest == $n");
}

my %help = (
    lwpd => 'Set the LWP debug level for Apache::TestRequest',
    bok  => 'Set breakpoint at test n',
);

my $setup_db_aliases = sub {
    my $package = 'Apache::TestPerlDB';
    my @cmds;
    no strict 'refs';

    while (my($name, $val) = each %{"$package\::"}) {
        next unless defined &$val;
        *{"main::$name"} = \&{$val};
        push @cmds, $name;
    }

    print "$package added perldb commands:\n",
      map { "   $_ - $help{$_}\n" } @cmds;

};

$setup_db_aliases->();

1;
__END__
