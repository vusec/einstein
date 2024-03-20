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
package Apache::TestRunParrot;

use strict;
use warnings FATAL => 'all';

use File::Spec::Functions qw(catfile canonpath);

use Apache::TestRun ();
use Apache::TestConfigParse ();
use Apache::TestTrace;
use Apache::TestConfigParrot ();

use vars qw($VERSION);
$VERSION = '1.00'; # make CPAN.pm's r() version scanner happy

use File::Spec::Functions qw(catfile);

# subclass of Apache::TestRun that configures parrot things
use vars qw(@ISA);
@ISA = qw(Apache::TestRun);

sub new_test_config {
    my $self = shift;

    Apache::TestConfigParrot->new($self->{conf_opts});
}

sub configure_parrot {
    my $self = shift;

    my $test_config = $self->{test_config};

    $test_config->postamble_register(qw(configure_parrot_tests));
}

sub configure {
    my $self = shift;

    $self->configure_parrot;

    $self->SUPER::configure;
}

#if Apache::TestRun refreshes config in the middle of configure
#we need to re-add parrotconfigure hooks
sub refresh {
    my $self = shift;
    $self->SUPER::refresh;
    $self->configure_parrot;
}

1;
__END__
