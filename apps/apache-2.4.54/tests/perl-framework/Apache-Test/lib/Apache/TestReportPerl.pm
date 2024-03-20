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
package Apache::TestReportPerl;

use strict;
use warnings FATAL => 'all';

use Apache::TestReport ();
use ModPerl::Config ();

# a subclass of Apache::TestReport that generates a bug report script
use vars qw(@ISA);
@ISA = qw(Apache::TestReport);

sub config {
    ModPerl::Config::as_string();
}

sub report_to {
    my $self = shift;
    my $pkg  = ref $self;
    die "you need to implement $pkg\::report_to() to return the " .
        "contact email address of your project";
}

1;
__END__
