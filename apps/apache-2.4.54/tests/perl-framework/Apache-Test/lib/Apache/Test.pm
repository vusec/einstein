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
package Apache::Test;

use strict;
use warnings FATAL => 'all';

use Exporter ();
use Config;
use Apache::TestConfig ();
use Test qw/ok skip/;

BEGIN {
    # Apache::Test loads a bunch of mp2 stuff while getting itself
    # together.  because we need to choose one of mp1 or mp2 to load
    # check first (and we choose mp2) $mod_perl::VERSION == 2.0
    # just because someone loaded Apache::Test.  This Is Bad.  so,
    # let's try to correct for that here by removing mod_perl from
    # %INC after the above use() statements settle in.  nobody
    # should be relying on us loading up mod_perl.pm anyway...

    delete $INC{'mod_perl.pm'};
}

use vars qw(@ISA @EXPORT %EXPORT_TAGS $VERSION %SubTests @SkipReasons);

$VERSION = '1.44';

my @need = qw(need_lwp need_http11 need_cgi need_access need_auth
              need_module need_apache need_min_apache_version need_min_apache_fix
              need_apache_version need_perl need_min_perl_version
              need_min_module_version need_threads need_fork need_apache_mpm
              need_php need_php4 need_ssl need_imagemap need_cache_disk);

my @have = map { (my $need = $_) =~ s/need/have/; $need } @need;

@ISA = qw(Exporter);
@EXPORT = (qw(sok plan skip_reason under_construction need),
           @need, @have);

%SubTests = ();
@SkipReasons = ();

sub cp {
    my @l;
    for( my $i=1; (@l=caller $i)[0] eq __PACKAGE__; $i++ ) {};
    return wantarray ? @l : $l[0];
}

my $Config;
my %wtm;
sub import {
    my $class=$_[0];
    my $wtm=0;
    my @base_exp;
    my @exp;
    my %my_exports;
    undef @my_exports{@EXPORT};

    my ($caller,$f,$l)=cp;

    for( my $i=1; $i<@_; $i++ ) {
	if( $_[$i] eq '-withtestmore' ) {
	    $wtm=1;
	}
	elsif( $_[$i] eq ':DEFAULT' ) {
	    push @exp, $_[$i];
	    push @base_exp, $_[$i];
	}
	elsif( $_[$i] eq '!:DEFAULT' ) {
	    push @exp, $_[$i];
	    push @base_exp, $_[$i];
	}
	elsif( $_[$i]=~m@^[:/!]@ ) {
	    warn("Ignoring import spec $_[$i] ".
		 "at $f line $l\n")
	}
	elsif( exists $my_exports{$_[$i]} ) {
	    push @exp, $_[$i];
	}
	else {
	    push @base_exp, $_[$i];
	}
    }
    if (!@exp and @base_exp) {
	@exp=('!:DEFAULT');
    }
    elsif (@exp and !@base_exp) {
	@base_exp=('!:DEFAULT');
    }

    $wtm{$caller}=[$wtm,$f,$l] unless exists $wtm{$caller};

    warn("Ignoring -withtestmore due to a previous call ".
	 "($wtm{$caller}->[1]:$wtm{$caller}->[2]) without it ".
	 "at $f line $l\n")
	if $wtm{$caller}->[0]==0 and $wtm==1;

    $class->export_to_level(1, $class, @exp);

    push @base_exp, '!plan';
    if( $wtm{$caller}->[0] ) {	# -withtestmore
	eval <<"EVAL"
package $caller;
#line $l $f
use Test::More import=>\\\@base_exp;
EVAL
    }
    else {			# -withouttestmore
	eval <<"EVAL";
package $caller;
#line $l $f
use Test \@base_exp;
EVAL
    }
    die $@ if $@;
}

sub config {
    $Config ||= Apache::TestConfig->thaw->httpd_config;
}

my $Basic_config;

# config bits which doesn't require httpd to be found
sub basic_config {
    $Basic_config ||= Apache::TestConfig->thaw();
}

sub vars {
    @_ ? @{ config()->{vars} }{ @_ } : config()->{vars};
}

sub sok (&;$) {
    my $sub = shift;
    my $nok = shift || 1; #allow sok to have 'ok' within

    my ($caller,$f,$l)=cp;

    if (exists $wtm{$caller} and $wtm{$caller}->[0]==1) { # -withtestmore
	require Test::Builder;
	my $tb=Test::Builder->new;

	if (%SubTests and not $SubTests{ 1+$tb->current_test }) {
	    $tb->skip("skipping this subtest") for (1..$nok);
	    return;
	}

	# trick ok() into reporting the caller filename/line when a
	# sub-test fails in sok()
	return eval <<EOE;
#line $l $f
    Test::More::ok(\$sub->());
EOE
    }
    else {
	if (%SubTests and not $SubTests{ $Test::ntest }) {
	    skip("skipping this subtest", 0) for (1..$nok);
	    return;
	}

	# trick ok() into reporting the caller filename/line when a
	# sub-test fails in sok()
	return eval <<EOE;
#line $l $f
    Test::ok(\$sub->());
EOE
    }
}

#so Perl's Test.pm can be run inside mod_perl
sub test_pm_refresh {
    my ($caller,$f,$l)=cp;

    if (exists $wtm{$caller} and $wtm{$caller}->[0]==1) { # -withtestmore
	require Test::Builder;
        my $builder = Test::Builder->new;

        $builder->reset;

        $builder->output(\*STDOUT);
        $builder->todo_output(\*STDOUT);

        # this is STDOUT because Test::More seems to put
        # most of the stuff we want on STDERR, so it ends
        # up in the error_log instead of where the user can
        # see it.   consider leaving it alone based on
        # later user reports.
        $builder->failure_output(\*STDOUT);
    }
    else {                                                # -withouttestmore
	unless (exists $wtm{$caller}) {
	    warn "You forgot to 'use Apache::Test' in package $caller\n";
	    $wtm{$caller}=[0,$f,$l];
	}
	if (defined &Test::_reset_globals) {
	    Test::_reset_globals();
	    # Test.pm uses $TESTOUT=*STDOUT{IO}. We cannot do that
	    # due to the way SetupEnv works.
	    $Test::TESTOUT = \*STDOUT;
	}
	else {
	    $Test::TESTOUT = \*STDOUT;
	    $Test::planned = 0;
	    $Test::ntest = 1;
	    %Test::todo = ();
	}
    }
}

sub init_test_pm {
    my $r = shift;

    # needed to load Apache2::RequestRec::TIEHANDLE
    eval {require Apache2::RequestIO};
    if (defined &Apache2::RequestRec::TIEHANDLE) {
        untie *STDOUT;
        tie *STDOUT, $r;
        require Apache2::RequestRec; # $r->pool
        require APR::Pool;
        $r->pool->cleanup_register(sub { untie *STDOUT });
    }
    else {
        $r->send_http_header; #1.xx
    }

    $r->content_type('text/plain');
}

sub plan {
    init_test_pm(shift) if ref $_[0];
    test_pm_refresh();

    # extending Test::plan's functionality, by using the optional
    # single value in @_ coming after a ballanced %hash which
    # Test::plan expects
    if (@_ % 2) {
        my $condition = pop @_;
        my $ref = ref $condition;
        my $meets_condition = 0;
        if ($ref) {
            if ($ref eq 'CODE') {
                #plan tests $n, \&has_lwp
                $meets_condition = $condition->();
            }
            elsif ($ref eq 'ARRAY') {
                #plan tests $n, [qw(php4 rewrite)];
                $meets_condition = need_module($condition);
            }
            else {
                die "don't know how to handle a condition of type $ref";
            }
        }
        else {
            # we have the verdict already: true/false
            $meets_condition = $condition ? 1 : 0;
        }

        # trying to emulate a dual variable (ala errno)
        unless ($meets_condition) {
            my $reason = join ', ',
              @SkipReasons ? @SkipReasons : "no reason given";
            print "1..0 # skipped: $reason\n";
            @SkipReasons = (); # reset
            exit; #XXX: Apache->exit
        }
    }
    @SkipReasons = (); # reset

    my ($caller,$f,$l)=cp;

    %SubTests=();
    if (my $subtests=$ENV{HTTPD_TEST_SUBTESTS}) {
	%SubTests=map { $_, 1 } split /\s+/, $subtests;
    }

    if (exists $wtm{$caller} and $wtm{$caller}->[0]==1) { # -withtestmore
	Test::More::plan(@_);
    }
    else {                                                # -withouttestmore
	unless (exists $wtm{$caller}) {
	    warn "You forgot to 'use Apache::Test' in package $caller\n";
	    $wtm{$caller}=[0,$f,$l];
	}
	Test::plan(@_);
    }

    # add to Test.pm verbose output
    print "# Using Apache/Test.pm version $VERSION\n";
}

sub need_http11 {
    require Apache::TestRequest;
    if (Apache::TestRequest::install_http11()) {
        return 1;
    }
    else {
        push @SkipReasons,
           "LWP version 5.60+ required for HTTP/1.1 support";
        return 0;
    }
}

sub need_ssl {
    my $vars = vars();
    need_module([$vars->{ssl_module_name}, 'IO::Socket::SSL']);
}

sub need_lwp {
    require Apache::TestRequest;
    if (Apache::TestRequest::has_lwp()) {
        return 1;
    }
    else {
        push @SkipReasons, "libwww-perl is not installed";
        return 0;
    }
}

sub need {
    my $need_all = 1;
    for my $cond (@_) {
        if (ref $cond eq 'HASH') {
            while (my($reason, $value) = each %$cond) {
                $value = $value->() if ref $value eq 'CODE';
                next if $value;
                push @SkipReasons, $reason;
                $need_all = 0;
            }
        }
        elsif ($cond =~ /^(0|1)$/) {
            $need_all = 0 if $cond == 0;
        }
        else {
            $need_all = 0 unless need_module($cond);
        }
    }
    return $need_all;

}

sub need_module {
    my $cfg = config();

    my @modules = grep defined $_,
        ref($_[0]) eq 'ARRAY' ? @{ $_[0] } : @_;

    my @reasons = ();
    for (@modules) {
        if (/^[a-z0-9_.]+$/) {
            my $mod = $_;
            $mod .= '.c' unless $mod =~ /\.c$/;
            next if $cfg->{modules}->{$mod};
            $mod = 'mod_' . $mod unless $mod =~ /^mod_/;
            next if $cfg->{modules}->{$mod};
            if (exists $cfg->{cmodules_disabled}->{$mod}) {
                push @reasons, $cfg->{cmodules_disabled}->{$mod};
                next;
            }
        }
        die "bogus module name $_" unless /^[\w:.]+$/;

        # if the module was explicitly passed with a .c extension,
        # do not try to eval it as a Perl module
        my $not_found = 1;
        unless (/\.c$/) {
            eval "require $_";
            $not_found = 0 unless $@;
            #print $@ if $@;
        }
        push @reasons, "cannot find module '$_'" if $not_found;

    }
    if (@reasons) {
        push @SkipReasons, @reasons;
        return 0;
    }
    else {
        return 1;
    }
}

sub need_min_perl_version {
    my $version = shift;

    return 1 if $] >= $version;

    push @SkipReasons, "perl >= $version is required";
    return 0;
}

# currently supports only perl modules
sub need_min_module_version {
    my($module, $version) = @_;

    # need_module requires the perl module
    return 0 unless need_module($module);

    # support dev versions like 0.18_01
    return 1
        if eval { no warnings qw(numeric); $module->VERSION($version) };

    push @SkipReasons, "$module version $version or higher is required";
    return 0;
}

sub need_cgi {
    return _need_multi(qw(cgi.c cgid.c));
}

sub need_cache_disk {
    return _need_multi(qw(cache_disk.c disk_cache.c));
}


sub need_php {
    return _need_multi(qw(php4 php5 sapi_apache2.c));
}

sub need_php4 {
    return _need_multi(qw(php4 sapi_apache2.c));
}

sub need_access {
    return _need_multi(qw(access authz_host));
}

sub need_auth {
    return _need_multi(qw(auth auth_basic));
}

sub need_imagemap {
    return need_module("imagemap") || need_module("imap");
}

sub _need_multi {

    my @check = @_;

    my $rc = 0;

    {
        local @SkipReasons;

        foreach my $module (@check) {
          $rc ||= need_module($module);
        }
    }

    my $reason = join ' or ', @check;

    push @SkipReasons, "cannot find one of $reason"
        unless $rc;

    return $rc;
}

sub need_apache {
    my $version = shift;
    my $cfg = Apache::Test::config();
    my $rev = $cfg->{server}->{rev};

    if ($rev == $version) {
        return 1;
    }
    else {
        push @SkipReasons,
          "apache version $version required, this is version $rev";
        return 0;
    }
}

sub need_min_apache_version {
    my $wanted = shift;
    my $cfg = Apache::Test::config();
    (my $current) = $cfg->{server}->{version} =~ m:^Apache/(\d\.\d+\.\d+):;

    if (normalize_vstring($current) < normalize_vstring($wanted)) {
        push @SkipReasons,
          "apache version $wanted or higher is required," .
          " this is version $current";
        return 0;
    }
    else {
        return 1;
    }
}

sub need_min_apache_fix {
    my @wantlevels = @_;
    my $cfg = Apache::Test::config();
    (my $current) = $cfg->{server}->{version} =~ m:^Apache/((\d)\.(\d+)\.(\d+)):;
    my $current_major = $2;
    my $current_minor = $3;
    my $current_micro = $4;

    foreach(@wantlevels) { 
        if ($_ =~ m/(\d)\.(\d+)\.(\d+)/) { 
            my $wanted_major = $1;
            my $wanted_minor = $2;
            my $wanted_micro = $3;
            if ($wanted_major eq $current_major && $wanted_minor eq $current_minor) { 
                if ($wanted_micro > $current_micro) {
                    push @SkipReasons,
                         "apache version $_ or higher is required," .
                             " this is version $current";
                    return 0;
                }
                else { 
                    return 1;
                }
            }
        }
    }

    # We didn't match major+minor, run the test and let the author sort it out
    return 1;
}

sub need_apache_version {
    my $wanted = shift;
    my $cfg = Apache::Test::config();
    (my $current) = $cfg->{server}->{version} =~ m:^Apache/(\d\.\d+\.\d+):;

    if (normalize_vstring($current) != normalize_vstring($wanted)) {
        push @SkipReasons,
          "apache version $wanted or higher is required," .
          " this is version $current";
        return 0;
    }
    else {
        return 1;
    }
}

sub need_apache_mpm {
    my $wanted = shift;
    my $cfg = Apache::Test::config();
    my $current = $cfg->{server}->{mpm};

    if ($current ne $wanted) {
        push @SkipReasons,
          "apache $wanted mpm is required," .
          " this is the $current mpm";
        return 0;
    }
    else {
        return 1;
    }
}

sub config_enabled {
    my $key = shift;
    defined $Config{$key} and $Config{$key} eq 'define';
}

sub need_perl_iolayers {
    if (my $ext = $Config{extensions}) {
        #XXX: better test?  might need to test patchlevel
        #if support depends bugs fixed in bleedperl
        return $ext =~ m:PerlIO/scalar:;
    }
    0;
}

sub need_perl {
    my $thing = shift;
    #XXX: $thing could be a version
    my $config;

    my $have = \&{"need_perl_$thing"};
    if (defined &$have) {
        return 1 if $have->();
    }
    else {
        for my $key ($thing, "use$thing") {
            if (exists $Config{$key}) {
                $config = $key;
                return 1 if config_enabled($key);
            }
        }
    }

    push @SkipReasons, $config ?
      "Perl was not built with $config enabled" :
        "$thing is not available with this version of Perl";

    return 0;
}

sub need_threads {
    my $status = 1;

    # check APR support
    my $build_config = Apache::TestConfig->modperl_build_config;

    if ($build_config) {
        my $apr_config = $build_config->get_apr_config();
        unless ($apr_config->{HAS_THREADS}) {
            $status = 0;
            push @SkipReasons, "Apache/APR was built without threads support";
        }
    }

    # check Perl's useithreads
    my $key = 'useithreads';
    unless (exists $Config{$key} and config_enabled($key)) {
        $status = 0;
        push @SkipReasons, "Perl was not built with 'ithreads' enabled";
    }

    return $status;
}

sub need_fork {
    my $have_fork = $Config{d_fork} ||
                    $Config{d_pseudofork} ||
                    (($^O eq 'MSWin32' || $^O eq 'NetWare') &&
                     $Config{useithreads} &&
                     $Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/);

     if (!$have_fork) {
         push @SkipReasons, 'The fork function is unimplemented';
         return 0;
     }
     else {
         return 1;
     }
}

sub under_construction {
    push @SkipReasons, "This test is under construction";
    return 0;
}

sub skip_reason {
    my $reason = shift || 'no reason specified';
    push @SkipReasons, $reason;
    return 0;
}

# normalize Apache-style version strings (2.0.48, 0.9.4)
# for easy numeric comparison.  note that 2.1 and 2.1.0
# are considered equivalent.
sub normalize_vstring {

    my @digits = shift =~ m/(\d+)\.?(\d*)\.?(\d*)/;

    return join '', map { sprintf("%03d", $_ || 0) } @digits;
}

# have_ functions are the same as need_ but they don't populate
# @SkipReasons
for my $func (@have) {
    no strict 'refs';
    (my $real_func = $func) =~ s/^have_/need_/;
    *$func = sub {
        # be nice to poor souls calling functions with $_ argument in
        # the foreach loop, etc.!
        local $_;
        local @SkipReasons;
        return $real_func->(@_);
    };
}

package Apache::TestToString;

Apache::Test->import('!:DEFAULT');

sub TIEHANDLE {
    my $string = "";
    bless \$string;
}

sub PRINT {
    my $string = shift;
    $$string .= join '', @_;
}

sub start {
    tie *STDOUT, __PACKAGE__;
    Apache::Test::test_pm_refresh();
}

sub finish {
    my $s;
    {
        my $o = tied *STDOUT;
        $s = $$o;
    }
    untie *STDOUT;
    $s;
}

1;
__END__


=head1 NAME

Apache::Test - Test.pm wrapper with helpers for testing Apache

=head1 SYNOPSIS

    use Apache::Test;

=head1 DESCRIPTION

B<Apache::Test> is a wrapper around the standard C<Test.pm> with
helpers for testing an Apache server.

=head1 FUNCTIONS

=over 4

=item plan

This function is a wrapper around C<Test::plan>:

    plan tests => 3;

just like using Test.pm, plan 3 tests.

If the first argument is an object, such as an C<Apache::RequestRec>
object, C<STDOUT> will be tied to it. The C<Test.pm> global state will
also be refreshed by calling C<Apache::Test::test_pm_refresh>. For
example:

    plan $r, tests => 7;

ties STDOUT to the request object C<$r>.

If there is a last argument that doesn't belong to C<Test::plan>
(which expects a balanced hash), it's used to decide whether to
continue with the test or to skip it all-together. This last argument
can be:

=over

=item * a C<SCALAR>

the test is skipped if the scalar has a false value. For example:

  plan tests => 5, 0;

But this won't hint the reason for skipping therefore it's better to
use need():

  plan tests => 5,
      need 'LWP',
           { "not Win32" => sub { $^O eq 'MSWin32'} };

see C<need()> for more info.

=item * an C<ARRAY> reference

need_module() is called for each value in this array. The test is
skipped if need_module() returns false (which happens when at least
one C or Perl module from the list cannot be found).

Watch out for case insensitive file systems or duplicate modules
with the same name.  I.E.  If you mean mod_env.c
   need_module('mod_env.c')
Not
   need_module('env')

=item * a C<CODE> reference

the tests will be skipped if the function returns a false value. For
example:

    plan tests => 5, need_lwp;

the test will be skipped if LWP is not available

=back

All other arguments are passed through to I<Test::plan> as is.

=item ok

Same as I<Test::ok>, see I<Test.pm> documentation.

=item sok

Allows to skip a sub-test, controlled from the command line.  The
argument to sok() is a CODE reference or a BLOCK whose return value
will be passed to ok(). By default behaves like ok(). If all sub-tests
of the same test are written using sok(), and a test is executed as:

  % ./t/TEST -v skip_subtest 1 3

only sub-tests 1 and 3 will be run, the rest will be skipped.

=item skip

Same as I<Test::skip>, see I<Test.pm> documentation.

=item test_pm_refresh

Normally called by I<Apache::Test::plan>, this function will refresh
the global state maintained by I<Test.pm>, allowing C<plan> and
friends to be called more than once per-process.  This function is not
exported.

=back

Functions that can be used as a last argument to the extended plan().
Note that for each C<need_*> function there is a C<have_*> equivalent
that performs the exact same function except that it is designed to
be used outside of C<plan()>.  C<need_*> functions have the side effect
of generating skip messages, if the test is skipped.  C<have_*> functions
don't have this side effect.  In other words, use C<need_apache()>
with C<plan()> to decide whether a test will run, but C<have_apache()>
within test logic to adjust expectations based on older or newer
server versions.

=over

=item need_http11

  plan tests => 5, need_http11;

Require HTTP/1.1 support.

=item need_ssl

  plan tests => 5, need_ssl;

Require SSL support.

Not exported by default.

=item need_lwp

  plan tests => 5, need_lwp;

Require LWP support.

=item need_cgi

  plan tests => 5, need_cgi;

Requires mod_cgi or mod_cgid to be installed.

=item need_cache_disk

  plan tests => 5, need_cache_disk

Requires mod_cache_disk or mod_disk_cache to be installed.


=item need_php

  plan tests => 5, need_php;

Requires a PHP module to be installed (version 4 or 5).

=item need_php4

  plan tests => 5, need_php4;

Requires a PHP version 4 module to be installed.

=item need_imagemap

  plan tests => 5, need_imagemap;

Requires a mod_imagemap or mod_imap be installed

=item need_apache

  plan tests => 5, need_apache 2;

Requires Apache 2nd generation httpd-2.x.xx

  plan tests => 5, need_apache 1;

Requires Apache 1st generation (apache-1.3.xx)

See also C<need_min_apache_version()>.

=item need_min_apache_version

Used to require a minimum version of Apache.

For example:

  plan tests => 5, need_min_apache_version("2.0.40");

requires Apache 2.0.40 or higher.

=item need_apache_version

Used to require a specific version of Apache.

For example:

  plan tests => 5, need_apache_version("2.0.40");

requires Apache 2.0.40.

=item need_min_apache_fix

Used to require a particular micro version from corresponding minor release

For example:

  plan tests => 5, need_min_apache_fix("2.0.40", "2.2.30", "2.4.18");

requires Apache 2.0.40 or higher.

=item need_apache_mpm

Used to require a specific Apache Multi-Processing Module.

For example:

  plan tests => 5, need_apache_mpm('prefork');

requires the prefork MPM.

=item need_perl

  plan tests => 5, need_perl 'iolayers';
  plan tests => 5, need_perl 'ithreads';

Requires a perl extension to be present, or perl compiled with certain
capabilities.

The first example tests whether C<PerlIO> is available, the second
whether:

  $Config{useithread} eq 'define';

=item need_min_perl_version

Used to require a minimum version of Perl.

For example:

  plan tests => 5, need_min_perl_version("5.008001");

requires Perl 5.8.1 or higher.

=item need_fork

Requires the perl built-in function C<fork> to be implemented.

=item need_module

  plan tests => 5, need_module 'CGI';
  plan tests => 5, need_module qw(CGI Find::File);
  plan tests => 5, need_module ['CGI', 'Find::File', 'cgid'];

Requires Apache C and Perl modules. The function accept a list of
arguments or a reference to a list.

In case of C modules, depending on how the module name was passed it
may pass through the following completions:

=over

=item 1 need_module 'proxy_http.c'

If there is the I<.c> extension, the module name will be looked up as
is, i.e. I<'proxy_http.c'>.

=item 2 need_module 'mod_cgi'

The I<.c> extension will be appended before the lookup, turning it into
I<'mod_cgi.c'>.

=item 3 need_module 'cgi'

The I<.c> extension and I<mod_> prefix will be added before the
lookup, turning it into I<'mod_cgi.c'>.

=back

=item need_min_module_version

Used to require a minimum version of a module

For example:

  plan tests => 5, need_min_module_version(CGI => 2.81);

requires C<CGI.pm> version 2.81 or higher.

Currently works only for perl modules.

=item need

  plan tests => 5,
      need 'LWP',
           { "perl >= 5.8.0 and w/ithreads is required" =>
             ($Config{useperlio} && $] >= 5.008) },
           { "not Win32"                 => sub { $^O eq 'MSWin32' },
             "foo is disabled"           => \&is_foo_enabled,
           },
           'cgid';

need() is more generic function which can impose multiple requirements
at once. All requirements must be satisfied.

need()'s argument is a list of things to test. The list can include
scalars, which are passed to need_module(), and hash references. If
hash references are used, the keys, are strings, containing a reason
for a failure to satisfy this particular entry, the values are the
condition, which are satisfaction if they return true. If the value is
0 or 1, it used to decide whether the requirements very satisfied, so
you can mix special C<need_*()> functions that return 0 or 1. For
example:

  plan tests => 1, need 'Compress::Zlib', 'deflate',
      need_min_apache_version("2.0.49");

If the scalar value is a string, different from 0 or 1, it's passed to
I<need_module()>.  If the value is a code reference, it gets executed
at the time of check and its return value is used to check the
condition. If the condition check fails, the provided (in a key)
reason is used to tell user why the test was skipped.

In the presented example, we require the presence of the C<LWP> Perl
module, C<mod_cgid>, that we run under perl E<gt>= 5.7.3 on Win32.

It's possible to put more than one requirement into a single hash
reference, but be careful that the keys will be different.

It's also important to mention to avoid using:

  plan tests => 1, requirement1 && requirement2;

technique. While test-wise that technique is equivalent to:

  plan tests => 1, need requirement1, requirement2;

since the test will be skipped, unless all the rules are satisfied,
it's not equivalent for the end users. The second technique, deploying
C<need()> and a list of requirements, always runs all the requirement
checks and reports all the missing requirements. In the case of the
first technique, if the first requirement fails, the second is not
run, and the missing requirement is not reported. So let's say all the
requirements are missing Apache modules, and a user wants to satisfy
all of these and run the test suite again. If all the unsatisfied
requirements are reported at once, she will need to rebuild Apache
once. If only one requirement is reported at a time, she will have to
rebuild Apache as many times as there are elements in the C<&&>
statement.

Also see plan().

=item under_construction

  plan tests => 5, under_construction;

skip all tests, noting that the tests are under construction

=item skip_reason

  plan tests => 5, skip_reason('my custom reason');

skip all tests.  the reason you specify will be given at runtime.
if no reason is given a default reason will be used.

=back

=head1 Additional Configuration Variables

=over 4

=item basic_config

  my $basic_cfg = Apache::Test::basic_config();
  $basic_cfg->write_perlscript($file, $content);

C<basic_config()> is similar to C<config()>, but doesn't contain any
httpd-specific information and should be used for operations that
don't require any httpd-specific knowledge.

=item config

  my $cfg = Apache::Test::config();
  my $server_rev = $cfg->{server}->{rev};
  ...

C<config()> gives an access to the configuration object.

=item vars

  my $serverroot = Apache::Test::vars->{serverroot};
  my $serverroot = Apache::Test::vars('serverroot');
  my($top_dir, $t_dir) = Apache::Test::vars(qw(top_dir t_dir));

C<vars()> gives an access to the configuration variables, otherwise
accessible as:

  $vars = Apache::Test::config()->{vars};

If no arguments are passed, the reference to the variables hash is
returned. If one or more arguments are passed the corresponding values
are returned.

=back

=head1 Test::More Integration

There are a few caveats if you want to use I<Apache::Test> with
I<Test::More> instead of the default I<Test> backend.  The first is
that I<Test::More> requires you to use its own C<plan()> function
and not the one that ships with I<Apache::Test>.  I<Test::More> also
defines C<ok()> and C<skip()> functions that are different, and
simply C<use>ing both modules in your test script will lead to redefined
warnings for these subroutines.

To assist I<Test::More> users we have created a special I<Apache::Test>
import tag, C<:withtestmore>, which will export all of the standard
I<Apache::Test> symbols into your namespace except the ones that collide
with I<Test::More>.

    use Apache::Test qw(:withtestmore);
    use Test::More;

    plan tests => 1;           # Test::More::plan()

    ok ('yes', 'testing ok');  # Test::More::ok()

Now, while this works fine for standard client-side tests
(such as C<t/basic.t>), the more advanced features of I<Apache::Test>
require using I<Test::More> as the sole driver behind the scenes.

Should you choose to use I<Test::More> as the backend for
server-based tests (such as C<t/response/TestMe/basic.pm>) you will
need to use the C<-withtestmore> action tag:

    use Apache::Test qw(-withtestmore);

    sub handler {

        my $r = shift;

        plan $r, tests => 1;           # Test::More::plan() with
                                       # Apache::Test features

        ok ('yes', 'testing ok');      # Test::More::ok()
    }

C<-withtestmore> tells I<Apache::Test> to use I<Test::More>
instead of I<Test.pm> behind the scenes.  Note that you are not
required to C<use Test::More> yourself with the C<-withtestmore>
option and that the C<use Test::More tests =E<gt> 1> syntax
may have unexpected results.

Note that I<Test::More> version 0.49, available within the
I<Test::Simple> 0.49 distribution on CPAN, or greater is required
to use this feature.

Because I<Apache:Test> was initially developed using I<Test> as
the framework driver, complete I<Test::More> integration is
considered experimental at this time - it is supported as best as
possible but is not guaranteed to be as stable as the default I<Test>
interface at this time.

=head1 Apache::TestToString Class

The I<Apache::TestToString> class is used to capture I<Test.pm> output
into a string.  Example:

    Apache::TestToString->start;

    plan tests => 4;

    ok $data eq 'foo';

    ...

    # $tests will contain the Test.pm output: 1..4\nok 1\n...
    my $tests = Apache::TestToString->finish;

=head1 SEE ALSO

The Apache-Test tutorial:
L<http://perl.apache.org/docs/general/testing/testing.html>.

L<Apache::TestRequest|Apache::TestRequest> subclasses LWP::UserAgent and
exports a number of useful functions for sending request to the Apache test
server. You can then test the results of those requests.

Use L<Apache::TestMM|Apache::TestMM> in your F<Makefile.PL> to set up your
distribution for testing.

=head1 AUTHOR

Doug MacEachern with contributions from Geoffrey Young, Philippe
M. Chiasson, Stas Bekman and others.

Questions can be asked at the test-dev <at> httpd.apache.org list
For more information see: http://httpd.apache.org/test/.

=cut
