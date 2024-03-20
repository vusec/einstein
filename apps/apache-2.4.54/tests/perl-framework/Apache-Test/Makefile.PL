use 5.005;

use lib qw(lib);
use Apache::Test5005compat;

use strict;
use warnings;

# was this file invoked directly via perl, or via the top-level
# (mp2) Makefile.PL? if top-level, this env var will be set
use constant TOP_LEVEL => $ENV{MOD_PERL_2_BUILD};

if (!TOP_LEVEL) {
    # see if we are building from within mp root, add src lib if we are
    eval { require File::Spec };
    unless ($@) {
        if ( -e File::Spec->catdir('..', 'lib') ) {

            # building A-T from mp subdirectory, use the mp lib
            unshift @INC, File::Spec->catdir('..', 'lib');
        }
    }
}

use ExtUtils::MakeMaker;
use Symbol;
use File::Find qw(finddepth);

use Apache::TestMM qw(test clean); #enable 'make test and make clean'
use Apache::TestRun;
use Apache::TestTrace;
use Apache::TestReport;
use Apache::TestConfig ();
use Apache::TestRunPerl;

my $VERSION;
set_version();

Apache::TestMM::filter_args();

my @scripts = qw(t/TEST);

finddepth(sub {
    return if $_ eq 'Apache-TestItSelf';
    return unless /(.*?\.pl)\.PL$/;
    push @scripts, "$File::Find::dir/$1";
}, '.');

for (@scripts) {
    Apache::TestMM::generate_script($_);
}
Apache::TestReport->generate_script;

my @clean_files =
    qw(.mypacklist
       t/TEST
       t/REPORT
       Makefile.old
      );

my %prereq = (
    'File::Spec' => '0.8',
    'Cwd'        => '2.06',
);

# Apache::TestServer uses Win32::Process on Windows.
if ($^O =~ /MSWin32/i) {
    $prereq{'Win32::Process'} = '0'
}

# Apache-Test/META.yml is excluded from mp2 distro to make PAUSE
# indexer happy, but then perl Makefile.PL complains about a missing
# META.yml, so autogenerate it if it wasn't in the distro
my $no_meta = TOP_LEVEL ? 1 : 0;

WriteMakefile(
    NAME      => 'Apache::Test',
    VERSION   => $VERSION,
    PREREQ_PM => \%prereq,
    NO_META   => $no_meta,
    dist      => {
        COMPRESS => 'gzip -9f', SUFFIX => 'gz',
        PREOP   => 'find $(DISTVNAME) -type d -print|xargs chmod 0755 && ' .
                   'find $(DISTVNAME) -type f -print|xargs chmod 0644',
        TO_UNIX => 'find $(DISTVNAME) -type f -print|xargs dos2unix'
    },
    clean     => {
        FILES => "@clean_files",
    },
);

# after CPAN/CPANPLUS had a chance to satisfy the requirements,
# enforce those (for those who run things manually)
check_prereqs();

sub check_prereqs {
    my %fail = ();
    for (sort keys %prereq) {
        unless (chk_version($_, $prereq{$_})) {
            $fail{$_} = $prereq{$_};
        }
    }
    if (%fail) {
        error "\nThe following Apache-Test dependencies aren't satisfied:",
            map { "\t$_: $fail{$_}" } sort keys %fail;
        error "Install those from http://search.cpan.org and try again";
        exit 0;
    }
}

sub chk_version {
    my($pkg, $wanted) = @_;

    no strict 'refs';
    local $| = 1;

    print "Checking for $pkg...";
    (my $p = $pkg . ".pm") =~ s#::#/#g;
    eval { require $p;};
    print("not ok\n$@"), return if $@;

    my $vstr = ${"${pkg}::VERSION"} ? "found v" . ${"${pkg}::VERSION"}
        : "not found";
    my $vnum = eval(${"${pkg}::VERSION"}) || 0;

    print $vnum >= $wanted ? "ok\n" : " " . $vstr . "\n";

    $vnum >= $wanted;
}

sub set_version {
    $VERSION = $Apache::Test::VERSION;

    my $fh = Symbol::gensym();
    open $fh, 'Changes' or die "Can't open Changes: $!";
    while (<$fh>) {
        if(/^=item.*-(dev|rc\d+)/) {
            $VERSION .= "-$1";
            last;
        }
        last if /^=item/;
    }
    close $fh;
}

sub add_dep {
    my($string, $targ, $add) = @_;
    $$string =~ s/($targ\s+::)/$1 $add/;
}

no warnings 'redefine';
sub MY::postamble {
    my $self = shift;

    my $q = ($^O =~ /MSWin32/i ? '"' : "'");

    my $string = $self->MM::postamble;

    $string .= <<"EOF";
tag :
	svn copy -m $q\$(VERSION_SYM) tag$q https://svn.apache.org/repos/asf/perl/Apache-Test/trunk https://svn.apache.org/repos/asf/perl/Apache-Test/tags/\$(VERSION_SYM)
EOF

    return $string;
}



sub MY::test {
    my $self = shift;

    # run tests normally if non root user
    return $self->Apache::TestMM::test(@_) if (($> != 0) # root user
        or (Apache::TestConfig::WINFU)); # win users
        # or win32

    return <<EOF
test::
\t\@echo
\t\@echo Apache::Test tests cannot be run as the root user.
\t\@echo Apache cannot spawn child processes as 'root', therefore
\t\@echo the test suite must be run with a non privileged user.
\t\@echo Please build Apache::Test as a non-privileged user to
\t\@echo run the test suite.
\t\@echo
EOF
}

sub MY::constants {
    my $self = shift;

    my $string = $self->MM::constants;

    # mp2 installs this into INSTALLSITEARCH, so in order to avoid
    # problems when users forget 'make install UNINST=1', trick MM into
    # installing pure perl modules to the sitearch location, when this is
    # not installed as a part of mp2 build
    if (!$ENV{MOD_PERL_2_BUILD}) {
        $string .= <<'EOI';

# install into the same location as mod_perl 2.0
INSTALLSITELIB = $(INSTALLSITEARCH)
DESTINSTALLSITELIB = $(DESTINSTALLSITEARCH)
EOI
    }

    $string;
}
