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
package Bundle::ApacheTest;

$VERSION = '0.02';

1;

__END__

=head1 NAME

Bundle::ApacheTest - A bundle to install all Apache-Test related modules

=head1 SYNOPSIS

 perl -MCPAN -e 'install Bundle::ApacheTest'

=head1 CONTENTS

Crypt::SSLeay        - For https support

Devel::CoreStack     - For getting core stack info

Devel::Symdump       - For, uh, dumping symbols

Digest::MD5          - Needed for Digest authentication

URI                  - There are URIs everywhere

Net::Cmd             - For libnet

MIME::Base64         - Used in authentication headers

HTML::Tagset         - Needed by HTML::Parser

HTML::Parser         - Need by HTML::HeadParser

HTML::HeadParser     - To get the correct $res->base

LWP                  - For libwww-perl

LWP::Protocol::https - LWP plug-in for the https protocol

IPC::Run3            - Used in Apache::TestSmoke

=head1 DESCRIPTION

This bundle lists all the CPAN modules used by Apache-Test.

=cut
