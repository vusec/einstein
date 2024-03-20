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
package Apache::TestHandler;

use strict;
use warnings FATAL => 'all';

use Apache::Test qw/!:DEFAULT/;	# call import() to tell about -withouttestmore
use Apache::TestRequest ();

use Apache2::Const -compile => qw(OK NOT_FOUND SERVER_ERROR);

#some utility handlers for testing hooks other than response
#see modperl-2.0/t/hooks/TestHooks/authen.pm

if ($ENV{MOD_PERL} && require mod_perl2) {
    require Apache2::RequestRec; # content_type
    require Apache2::RequestIO;  # puts
}

#compat with 1.xx
my $send_http_header = Apache->can('send_http_header') || sub {};
my $print = Apache2->can('print') || Apache2::RequestRec->can('puts');

sub ok {
    my ($r, $boolean) = @_;
    $r->$send_http_header;
    $r->content_type('text/plain');
    $r->$print((@_>1 && !$boolean ? "not " : '')."ok");
    0;
}

sub ok1 {
    my ($r, $boolean) = @_;
    Apache::Test::plan($r, tests => 1);
    Apache::Test::ok(@_==1 || $boolean);
    0;
}

# a fixup handler to be used when a few requests need to be run
# against the same perl interpreter, in situations where there is more
# than one client running. For an example of use see
# modperl-2.0/t/response/TestModperl/interp.pm and
# modperl-2.0/t/modperl/interp.t
#
# this handler expects the header X-PerlInterpreter in the request
# - if none is set, Apache::SERVER_ERROR is returned
# - if its value eq 'tie', instance's global UUID is assigned and
#   returned via the same header
# - otherwise if its value is not the same the stored instance's
#   global UUID Apache::NOT_FOUND is returned
#
# in addition $same_interp_counter counts how many times this instance of
# pi has been called after the reset 'tie' request (inclusive), this
# value can be retrieved with Apache::TestHandler::same_interp_counter()
my $same_interp_id = "";
# keep track of how many times this instance was called after the reset
my $same_interp_counter = 0;
sub same_interp_counter { $same_interp_counter }
sub same_interp_fixup {
    my $r = shift;
    my $interp = $r->headers_in->get(Apache::TestRequest::INTERP_KEY);

    unless ($interp) {
        # shouldn't be requesting this without an INTERP header
        die "can't find the interpreter key";
    }

    my $id = $same_interp_id;
    if ($interp eq 'tie') { #first request for an interpreter instance
        # unique id for this instance
        $same_interp_id = $id =
            unpack "H*", pack "Nnn", time, $$, int(rand(60000));
        $same_interp_counter = 0; #reset the counter
    }
    elsif ($interp ne $same_interp_id) {
        # this is not the request interpreter instance
        return Apache2::Const::NOT_FOUND;
    }

    $same_interp_counter++;

    # so client can save the created instance id or check the existing
    # value
    $r->headers_out->set(Apache::TestRequest::INTERP_KEY, $id);

    return Apache2::Const::OK;
}

1;
__END__

=encoding utf8

=head1 NAME

Apache::TestHandler - a few response handlers and helpers

=head1 SYNOPSIS

    package My::Test;
    use Apache::TestHandler ();
    sub handler {
        my ($r) = @_;
        my $result = do_my_test;
        Apache::TestHandler::ok1 $r, $result;
    }

    sub handler2 {
        my ($r) = @_;
        my $result = do_my_test;
        Apache::TestHandler::ok $r, $result;
    }

=head1 DESCRIPTION

C<Apache::TestHandler> provides 2 very simple response handler.

=head1 FUNCTIONS

=over 4

=item ok $r, $boolean

The handler simply prints out C<ok> or C<not ok> depending on the
optional C<$boolean> parameter.

If C<$boolean> is omitted C<true> is assumed.

=item ok1 $r, $boolean

This handler implements a simple response-only test. It can be used on its
own to check if for a certain URI the response phase is reached. Or it
can be called like a normal function to print out the test result. The
client side is automatically created as described in
L<http://perl.apache.org/docs/general/testing/testing.html#Developing_Response_only_Part_of_a_Test>.

C<$boolean> is optional. If omitted C<true> is assumed.

=item same_interp_counter

=item same_interp_fixup

TODO

=back

=head1 SEE ALSO

The Apache-Test tutorial:
L<http://perl.apache.org/docs/general/testing/testing.html>.

L<Apache::Test>.

=head1 AUTHOR

Doug MacEachern, Geoffrey Young, Stas Bekman, Torsten Förtsch and others.

Questions can be asked at the test-dev <at> httpd.apache.org list
For more information see: http://httpd.apache.org/test/.

=cut
