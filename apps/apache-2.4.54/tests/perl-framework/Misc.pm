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
package Misc;

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;
use Apache::TestConfig ();
use Time::HiRes qw(usleep);

use strict;
use warnings FATAL => 'all';

BEGIN {
    # Just a bunch of useful subs
}
	
sub cwait
{
    my $condition = shift;
    my $wait = shift || 2;
    my $inc = shift || 50;
    my $timer = time() + $wait;
    while (! eval $condition) {
        usleep($inc);
        last if (time() >= $timer);
    }
    if ( eval $condition ) {
        return 1;
    } else {
        return 0;
    }
}

1;
__END__