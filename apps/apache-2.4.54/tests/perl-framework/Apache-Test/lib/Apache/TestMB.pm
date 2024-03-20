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

package Apache::TestMB;

use strict;
use vars qw(@ISA);
use Module::Build 0.18;
use Apache::Test ();
use Apache::TestConfig ();
@ISA = qw(Module::Build);

sub new {
    my $pkg = shift;
    my($argv, $vars) =
        Apache::TestConfig::filter_args(\@ARGV, \%Apache::TestConfig::Usage);
    @ARGV = @$argv;
    my $self = $pkg->SUPER::new(@_);
    $self->{properties}{apache_test_args} = $vars;
    $self->{properties}{apache_test_script} ||= 't/TEST';
    $self->generate_script;
    return $self;
}

sub valid_property {
    return 1 if defined $_[1] &&
        ($_[1] eq 'apache_test_args' || $_[1] eq 'apache_test_script');
    shift->SUPER::valid_property(@_);
}

sub apache_test_args {
    my $self = shift;
    $self->{properties}{apache_test_args} = shift if @_;
    return $self->{properties}{apache_test_args};
}

sub apache_test_script {
    my $self = shift;
    $self->{properties}{apache_test_script} = shift if @_;
    return $self->{properties}{apache_test_script};
}

sub ACTION_test_clean {
    my $self = shift;
    # XXX I'd love to do this without t/TEST.
    $self->do_system( $self->perl, $self->_bliblib,
                      $self->localize_file_path($self->apache_test_script),
                      '-clean');
}

sub ACTION_clean {
    my $self = shift;
    $self->depends_on('test_clean');
    $self->SUPER::ACTION_clean(@_);
}

sub ACTION_run_tests {
    my $self = shift;
    $self->depends_on('test_clean');
    # XXX I'd love to do this without t/TEST.
    $self->do_system($self->perl, $self->_bliblib,
                     $self->localize_file_path($self->apache_test_script),
                     '-bugreport', '-verbose=' . ($self->verbose || 0));
}

sub ACTION_testcover {
    my $self = shift;

    unless ($self->find_module_by_name('Devel::Cover', \@INC)) {
        warn("Cannot run testcover action unless Devel::Cover "
             . "is installed.\n" .
             "Don't forget to rebuild your Makefile after "
             . "installing Devel::Cover\n");
        return;
    }

    $self->add_to_cleanup('coverage', 'cover_db');

    my $atdir = $self->localize_file_path("$ENV{HOME}/.apache-test");
    local $Test::Harness::switches    =
    local $Test::Harness::Switches    =
    local $ENV{HARNESS_PERL_SWITCHES} = "-MDevel::Cover=+inc,'$atdir'";
    local $ENV{APACHE_TEST_EXTRA_ARGS} = "-one-process";

    $self->depends_on('test');
    $self->do_system('cover');
}

sub ACTION_test_config {
    my $self = shift;
    $self->do_system($self->perl, $self->_bliblib,
                     $self->localize_file_path($self->apache_test_script),
                     '-conf', '-verbose=' . ($self->verbose || 0));
}

sub _bliblib {
    my $self = shift;
    return (
        '-I', File::Spec->catdir($self->base_dir, $self->blib, 'lib'),
        '-I', File::Spec->catdir($self->base_dir, $self->blib, 'arch'),
    );
}

sub ACTION_test {
    my $self = shift;
    $self->depends_on('code');
    $self->depends_on('run_tests');
    $self->depends_on('test_clean');
}

sub _cmodules {
    my ($self, $action) = @_;
    die "The cmodules" . ( $action ne 'all' ? "_$action" : '')
      . " action is not yet implemented";
    # XXX TBD.
    $self->depends_on('test_config');
    my $start_dir = $self->cwd;
    chdir $self->localize_file_path('c-modules');
    # XXX How do we get Build.PL to be generated instead of Makefile?
    # Subclass Apache::TestConfigC, perhaps?
    $self->do_system('Build.PL', $action);
    chdir $start_dir;
}

sub ACTION_cmodules       { shift->_cmodues('all')   }
sub ACTION_cmodules_clean { shift->_cmodues('clean') }

# XXX I'd love to make this optional.
sub generate_script {
    my $self = shift;

    # If a file name has been passed in, use it. Otherwise, use the
    # one set up when the Apache::TestMB object was created.
    my $script = $self->localize_file_path($_[0]
        ? $self->apache_test_script(shift)
        : $self->apache_test_script
    );

    # We need a class to run the tests from t/TEST.
    my $class = pop || 'Apache::TestRunPerl';

    # Delete any existing instance of the file.
    unlink $script if -e $script;

    # Start the contents of t/TEST.
    my $body = "BEGIN { eval { require blib && blib->import; } }\n";

    # Configure the arguments for t/TEST.
    while (my($k, $v) = each %{ $self->apache_test_args }) {
        $v =~ s/\|/\\|/g;
        $body .= "\n\$Apache::TestConfig::Argv{'$k'} = q|$v|;\n";
    }

    my $infile = "$script.PL";
    if (-f $infile) {
        # Use the existing t/TEST.PL.
        my $in = Symbol::gensym();
        open $in, "$infile" or die "Couldn't open $infile: $!";
        local $/;
        $body .= <$in>;
        close $in;
    } else {
        # Create t/TEST from scratch.
        $body .= join "\n",
            Apache::TestConfig->perlscript_header,
            "use $class ();",
            "$class->new->run(\@ARGV);";
    }

    # Make it so!
    print "Generating test running script $script\n" if $self->verbose;
    Apache::Test::basic_config()->write_perlscript($script, $body);
    $self->add_to_cleanup($self->apache_test_script);
}


1;
__END__

=head1 NAME

Apache::TestMB - Subclass of Module::Build to support Apache::Test

=head1 SYNOPSIS

Standard process for building & installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the "./"
notation, you can do this:

  perl Build.PL
  perl Build
  perl Build test
  perl Build install

=head1 DESCRIPTION

This class subclasses C<Module::Build> to add support for testing
Apache integration with Apache::Test. It is broadly based on
C<Apache::TestMM>, and as such adds a number of build actions to a the
F<Build> script, while simplifying the process of creating F<Build.PL>
scripts.

Here's how to use C<Apache::TestMB> in a F<Build.PL> script:

  use Module::Build;

  my $build_pkg = eval { require Apache::TestMB }
      ? 'Apache::TestMB' : 'Module::Build';

  my $build = $build_pkg->new(
      module_name => 'My::Module',
  );
  $build->create_build_script;

This is identical to how C<Module::Build> is used. Not all target
systems may have C<Apache::Test> (and therefore C<Apache::TestMB>
installed, so we test for it to be installed, first. But otherwise,
its use can be exactly the same. Consult the
L<Module::Build|Module::Build> documentation for more information on
how to use it; L<Module::Build::Cookbook|Module::Build::Cookbook> may
be especially useful for those looking to migrate from
C<ExtUtils::MakeMaker>.

=head1 INTERFACE

=head2 Build

With the above script, users can build your module in the usual
C<Module::Build> way:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

If C<Apache::TestMB> is installed, then Apache will be started before
tests are run by the C<test> action, and shut down when the tests
complete. Note that C<Build.PL> can be called C<Apache::Test>-specific
options in addition to the usual C<Module::Build> options. For
example:

  perl Build.PL -apxs /usr/local/apache/bin/apxs

Consult the L<Apache::Test|Apache::Test> documentation for a complete
list of options.

In addition to the actions provided by C<Module::Build> (C<build>,
C<clean>, C<code>, C<test>, etc.), C<Apache::TestMB> adds a few extra
actions:

=over 4

=item test_clean

This action cleans out the files generated by the test script,
F<t/TEST>. It is also executed by the C<clean> action.

=item run_tests

This action actually the tests by executing the test script,
F<t/TEST>. It is executed by the C<test> action, so most of the time
it won't be executed directly.

=item testcover

C<Apache::TestMB> overrides this action from C<Module::Build> in order to
prevent the C<Apache::Test> preference files from being included in the test
coverage.

=back

=head2 Constructor

=head3 new

The C<new()> constructor takes all the same arguments as its parent in
C<Module::Build>, but can optionally accept one other parameter:

=over

=item apache_test_script

The name of the C<Apache::Test> test script. The default value is
F<t/TEST>, which will work in the vast majority of cases. If you wish
to specify your own file name, do so with a relative file name using
Unix-style paths; the file name will automatically be converted for
the local platform.

=back

When C<new()> is called it does the following:

=over 4

=item *

Processes the C<Apache::Test>-specific options in C<@ARGV>. See the
L<Apache::Test|Apache::Test> documentation for a complete list of
options.

=item *

Sets the name of the C<Apache::Test> test script to F<t/TEST>, unless
it was explicitly specified by the C<apache_test_script> parameter.

=item *

Calls C<generate_script()> to generate C<Apache::Test> test script,
usually F<t/TEST>.

=back

=head2 Instance Methods

=head3 apache_test_args

Returns a hash reference containing all of the settings specified by
options passed to F<Build.PL>, or explicitly added to C<@ARGV> in
F<Build.PL>. Consult the L<Apache::Test|Apache::Test> documentation
for a complete list of options.

=head3 apache_test_script

Gets or sets the file name of the C<Apache::Test> test script.

=head3 generate_script

  $build->generate_script;
  $build->generate_script('t/FOO');
  $build->generate_script(undef, 'Apache::TestRun');

This method is called by C<new()>, so in most cases it can be
ignored. If you'd like it to use other than the default arguments, you
can call it explicitly in F<Build.PL> and pass it the arguments you
desire. It takes two optional arguments:

=over 4

=item *

The name of the C<Apache::Test> test script. Defaults to the value
returned by C<apache_test_script()>.

=item *

The name of an C<Apache::Test> test running class. Defaults to
C<Apache::TestRunPerl>.

=back

If there is an existing F<t/TEST.PL> (or a script with the same name
as specified by the C<apache_test_script> parameter but with F<.PL>
appended to it), then that script will be used as the template for the
test script.  Otherwise, a simple test script will be written similar
to what would be written by C<Apache::TestRun::generate_script()>
(although that function is not aware of the arguments passed to
F<Build.PL>, so use this one instead!).

=head1 SEE ALSO

=over 4

=item L<Apache::TestRequest|Apache::TestRequest>

Demonstrates how to write tests to send requests to the Apache server
run by C<./Build test>.

=item L<Module::Build|Module::Build>

The parent class for C<Apache::TestMB>; consult it's documentation for
more on its interface.

=item L<http://www.perl.com/pub/a/2003/05/22/testing.html>

This article by Geoffrey Young explains how to configure Apache and
write tests for your module using Apache::Test. Just use
C<Apache::TestMB> instead of C<Apache::TestMM> to update it for use
with C<Module::Build>.

=back

=head1 AUTHOR

David Wheeler

Questions can be asked at the test-dev <at> httpd.apache.org list. For
more information see: I<http://httpd.apache.org/test/> and
I<http://perl.apache.org/docs/general/testing/testing.html>.

=cut

