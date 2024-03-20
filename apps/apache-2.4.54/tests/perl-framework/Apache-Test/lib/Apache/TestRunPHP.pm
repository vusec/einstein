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
package Apache::TestRunPHP;

use strict;
use warnings FATAL => 'all';

use File::Spec::Functions qw(catfile canonpath);

use Apache::TestRun ();
use Apache::TestConfigParse ();
use Apache::TestTrace;
use Apache::TestConfigPHP ();
use Apache::TestHarnessPHP ();

use vars qw($VERSION);
$VERSION = '1.00'; # make CPAN.pm's r() version scanner happy

use File::Spec::Functions qw(catfile);

# subclass of Apache::TestRun that configures php things
use vars qw(@ISA);
@ISA = qw(Apache::TestRun);

sub start {
    my $self = shift;

    # point php to our own php.ini file
    $ENV{PHPRC} = catfile $self->{test_config}->{vars}->{serverroot},
                          'conf';

    $self->SUPER::start(@_);
}

sub new_test_config {
    my $self = shift;

    Apache::TestConfigPHP->new($self->{conf_opts});
}

sub configure_php {
    my $self = shift;

    my $test_config = $self->{test_config};

    $test_config->postamble_register(qw(configure_php_inc
                                        configure_php_ini
                                        configure_php_functions
                                        configure_php_tests));
}

sub configure {
    my $self = shift;

    $self->configure_php;

    $self->SUPER::configure;
}

#if Apache::TestRun refreshes config in the middle of configure
#we need to re-add php configure hooks
sub refresh {
    my $self = shift;
    $self->SUPER::refresh;
    $self->configure_php;
}

my @request_opts = qw(get post head);

sub run_tests {
    my $self = shift;

    my $test_opts = {
        verbose => $self->{opts}->{verbose},
        tests   => $self->{tests},
        order   => $self->{opts}->{order},
        subtests => $self->{subtests} || [],
    };

    if (grep { exists $self->{opts}->{$_} } @request_opts) {
        run_request($self->{test_config}, $self->{opts});
    }
    else {
        Apache::TestHarnessPHP->run($test_opts)
            if $self->{opts}->{'run-tests'};
    }
}

sub split_test_args {
    my($self) = @_;

    my(@tests);
    my $top_dir = $self->{test_config}->{vars}->{top_dir};
    my $t_dir = $self->{test_config}->{vars}->{t_dir};

    my $argv = $self->{argv};
    my @leftovers = ();
    for (@$argv) {
        my $arg = $_;
        # need the t/ (or t\) for stat-ing, but don't want to include
        # it in test output
        $arg =~ s@^(?:\.[\\/])?t[\\/]@@;
        my $file = catfile $t_dir, $arg;
        if (-d $file and $_ ne '/') {
            my @files = <$file/*.t>;
            push @files, <$file/*.php>;
            my $remove = catfile $top_dir, "";
            if (@files) {
                push @tests, map { s,^\Q$remove,,; $_ } @files;
                next;
            }
        }
        else {
            if (($file =~ /\.t$/ || $file =~ /\.php$/) and -e $file) {
                push @tests, "t/$arg";
                next;
            }
            elsif (-e "$file.t") {
                push @tests, "t/$arg.t";
                next;
            }
            elsif (/^[\d.]+$/) {
                my @t = $_;
                #support range of subtests: t/TEST t/foo/bar 60..65
                if (/^(\d+)\.\.(\d+)$/) {
                    @t =  $1..$2;
                }

                push @{ $self->{subtests} }, @t;
                next;
            }
        }
        push @leftovers, $_;
    }

    $self->{tests} = [ map { canonpath($_) } @tests ];
    $self->{argv}  = \@leftovers;
}
1;
__END__

=head1 NAME

Apache::TestRunPHP - configure and run a PHP-based test suite

=head1 SYNOPSIS

  use Apache::TestRunPHP;
  Apache::TestRunPHP->new->run(@ARGV);

=head1 DESCRIPTION

The C<Apache::TestRunPHP> package controls the configuration and
running of the test suite for PHP-based tests.  It's a subclass
of C<Apache::TestRun> and similar in function to C<Apache::TestRunPerl>.

Refer to the C<Apache::TestRun> manpage for information on the
available API.

=head1 EXAMPLE

C<TestRunPHP> works almost identially to C<TestRunPerl>, but in
case you are new to C<Apache-Test> here is a quick getting started
guide.  be sure to see the links at the end of this document for
places to find additional details.

because C<Apache-Test> is a Perl-based testing framework we start
from a C<Makefile.PL>, which should have the following lines (in
addition to the standard C<Makefile.PL> parts):

  use Apache::TestMM qw(test clean);
  use Apache::TestRunPHP ();

  Apache::TestMM::filter_args();

  Apache::TestRunPHP->generate_script();

C<generate_script()> will create a script named C<t/TEST>, the gateway
to the Perl testing harness and what is invoked when you call
C<make test>.  C<filter_args()> accepts some C<Apache::Test>-specific
arguments and passes them along.  for example, to point to a specific
C<httpd> installation you would invoke C<Makefile.PL> as follows

  $ perl Makefile.PL -httpd /my/local/apache/bin/httpd

and C</my/local/apache/bin/httpd> will be propagated throughout the
rest of the process.  note that PHP needs to be active within Apache
prior to configuring the test framework as shown above, either by
virtue of PHP being compiled into the C<httpd> binary statically or
through an active C<LoadModule> statement within the configuration
located in C</my/local/apache/conf/httpd.conf>.  Other required modules
are the (very common) mod_alias and mod_env.

now, like with C<Apache::TestRun> and C<Apache::TestRunPerl>, you can
place client-side Perl test scripts under C<t/>, such as C<t/01basic.t>,
and C<Apache-Test> will run these scripts when you call C<make test>.
however, what makes C<Apache::TestRunPHP> unique is some added magic
specifically tailored to a PHP environment.  here are the mechanics.

C<Apache::TestRunPHP> will look for PHP test scripts in that match
the following pattern

  t/response/TestFoo/bar.php

where C<Foo> and C<bar> can be anything you like, and C<t/response/Test*>
is case sensitive.  when this format is adhered to, C<Apache::TestRunPHP>
will create an associated Perl test script called C<t/foo/bar.t>, which
will be executed when you call C<make test>.  all C<bar.t> does is issue
a simple GET to C<bar.php>, leaving the actual testing to C<bar.php>.  in
essence, you can forget that C<bar.t> even exists.

what does C<bar.php> look like?  here is an example:

  <?php
    print "1..1\n";
    print "ok 1\n"
  ?>

if it looks odd, that's ok because it is.  I could explain to you exactly
what this means, but it isn't important to understand the gory details.
instead, it is sufficient to understand that when C<Apache::Test> calls
C<bar.php> it feeds the results directly to C<Test::Harness>, a module
that comes with every Perl installation, and C<Test::Harness> expects
what it receives to be formated in a very specific way.  by itself, all
of this is pretty useless, so C<Apache::Test> provides PHP testers with
something much better.  here is a much better example:

  <?php
    # import the Test::More emulation layer
    # see
    #   http://search.cpan.org/dist/Test-Simple/lib/Test/More.pm
    # for Perl's documentation - these functions should behave
    # in the same way
    require 'test-more.php';

    # plan() the number of tests
    plan(6);

    # call ok() for each test you plan
    ok ('foo' == 'foo', 'foo is equal to foo');
    ok ('foo' != 'foo', 'foo is not equal to foo');

    # ok() can be other things as well
    is ('bar', 'bar', 'bar is bar');
    is ('baz', 'bar', 'baz is baz');
    isnt ('bar', 'beer', 'bar is not beer');
    like ('bar', '/ar$/', 'bar matches ar$');

    diag("printing some debugging information");

    # whoops! one too many tests.  I wonder what will happen...
    is ('biff', 'biff', 'baz is a baz');
  ?>

the include library C<test-more.php> is automatically generated by
C<Apache::TestConfigPHP> and configurations tweaked in such a
a way that your PHP scripts can find it without issue.  the
functions provided by C<test-more.php> are equivalent in name and
function to those in C<Test::More>, a standard Perl testing
library, so you can see that manpage for details on the syntax
and functionality of each.

at this point, we have enough in place to run some tests from
PHP-land - a C<Makefile.PL> to configure Apache for us, and
a PHP script in C<t/response/TestFoo/bar.php> to send some
results out to the testing engine.  issuing C<make test>
would start Apache, issue the request to C<bar.php>, generate
a report, and shut down Apache.  the report would look like
something like this after running the tests in verbose mode
(eg C<make test TEST_VERBOSE=1>):

  t/php/bar....1..6
  ok 1 - foo is equal to foo
  not ok 2 - foo is not equal to foo
  #     Failed test (/src/devel/perl-php-test/t/response/TestFoo/bar.php at line 13)
  ok 3 - bar is bar
  not ok 4 - baz is baz
  #     Failed test (/src/devel/perl-php-test/t/response/TestFoo/bar.php at line 17)
  #           got: 'baz'
  #      expected: 'bar'
  ok 5 - bar is not beer
  ok 6 - bar matches ar$
  # printing some debugging information
  ok 7 - baz is a baz
  FAILED tests 2, 4, 7
          Failed 3/6 tests, 50.00% okay
  Failed Test Stat Wstat Total Fail  Failed  List of Failed
  -------------------------------------------------------------------------------
  t/php/bar.t                6    3  50.00%  2 4 7
  Failed 1/1 test scripts, 0.00% okay. 1/6 subtests failed, 83.33% okay.

note that the actual test file that was run was C<t/php/bar.t>.  this
file is autogenerated based on the C<t/response/TestFoo/bar.php>
pattern of your PHP script.  C<t/php/bar.t> happens to be written in
Perl, but you really don't need to worry about it too much.

as an interesting aside, if you are using perl-5.8.3 or later you can
actually create your own C<t/foo.php> client-side scripts and they
will be run via php (using our C<php.ini>).  but more on that later...

=head1 SEE ALSO

the best source of information about using Apache-Test with
PHP (at this time) is probably the talk given at ApacheCon 2004
(L<http://xrl.us/phpperl>), as well as the code from the talk
(L<http://xrl.us/phpperlcode>).  there is also the online tutorial
L<http://perl.apache.org/docs/general/testing/testing.html>
which has all of the mod_perl-specific syntax and features have been
ported to PHP with this class.

=head1 AUTHOR

C<Apache-Test> is a community effort, maintained by a group of
dedicated volunteers.

Questions can be asked at the test-dev <at> httpd.apache.org list
For more information see: http://httpd.apache.org/test/.

=cut
