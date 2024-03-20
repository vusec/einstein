use 5.005;

use lib qw(../../lib); # Apache-Test/lib

use Apache::TestMM qw(test clean);
use Apache::TestMM ();
use Apache::TestReport;

use ExtUtils::MakeMaker ();

my $mp_gen = satisfy_mp_generation();
warn "Goind to build against mod_perl/$mod_perl::VERSION Perl/$]\n";

Apache::TestMM::filter_args();

my @scripts = qw(t/TEST);
for (@scripts) {
    Apache::TestMM::generate_script($_);
}
Apache::TestReport->generate_script;

my @clean_files = (@scripts, qw(t/REPORT));


my %common_opts = (
    NAME      => 'Apache-TestMe',
    VERSION   => '0.01',
    clean     => {
        FILES => "@clean_files",
    },
);

if ($mp_gen == 1) {
    require ExtUtils::MakeMaker;
    ExtUtils::MakeMaker::WriteMakefile(
        %common_opts,
    );

}
else {
    require ModPerl::MM;
    ModPerl::MM::WriteMakefile(
        %common_opts,
    );
}
# If a specific generation was passed as an argument,
#     if satisfied
#         return the same generation
#     else
#         die
# else @ARGV and %ENV will be checked for specific orders
#     if the specification will be found
#         if satisfied
#             return the specified generation
#         else
#             die
#     else if any mp generation is found
#              return it
#           else
#              die

sub satisfy_mp_generation {
    my $wanted = shift || wanted_mp_generation();

    unless ($wanted == 1 || $wanted == 2) {
        die "don't know anything about mod_perl generation: $wanted\n" .
            "currently supporting only generations 1 and 2";
    }

    my $selected = 0;

    if ($wanted == 1) {
        require_mod_perl();
        if ($mod_perl::VERSION >= 1.99) {
            # so we don't pick 2.0 version if 1.0 is wanted
            die "You don't seem to have mod_perl 1.0 installed";
        }
        $selected = 1;
    }
    elsif ($wanted == 2) {
        #warn "Looking for mod_perl 2.0";
        require_mod_perl2();
        if ($mod_perl::VERSION < 1.99) {
            die "You don't seem to have mod_perl 2.0 installed";
        }
        $selected = 2;
    }
    else {
        $selected = eval { require_mod_perl2() or require_mod_perl() };
        warn "Using $mod_perl::VERSION\n";
    }

    return $selected;
}

sub require_mod_perl {
    eval { require mod_perl };
    die "Can't find mod_perl installed\nThe error was: $@" if $@;
    1;
}

sub require_mod_perl2 {
    eval { require mod_perl2 };
    die "Can't find mod_perl installed\nThe error was: $@" if $@;
    2;
}


# the function looks at %ENV and Makefile.PL option to figure out
# whether a specific mod_perl generation was requested.
# It uses the following logic:
# via options:
# perl Makefile.PL MOD_PERL=2
# or via %ENV:
# env MOD_PERL=1 perl Makefile.PL
#
# return value is:
# 1 or 2 if the specification was found (mp 1 and mp 2 respectively)
# 0 otherwise
sub wanted_mp_generation {

    # check if we have a command line specification
    # flag: 0: unknown, 1: mp1, 2: mp2
    my $flag = 0;
    my @pass;
    while (@ARGV) {
        my $key = shift @ARGV;
        if ($key =~ /^MOD_PERL=(\d)$/) {
            $flag = $1;
        }
        else {
            push @pass, $key;
        }
    }
    @ARGV = @pass;

    # check %ENV
    my $env = exists $ENV{MOD_PERL} ? $ENV{MOD_PERL} : 0;

    # check for contradicting requirements
    if ($env && $flag && $flag != $env) {
        die <<EOF;
Can\'t decide which mod_perl version should be used, since you have
supplied contradicting requirements:
    enviroment variable MOD_PERL=$env
    Makefile.PL option  MOD_PERL=$flag
EOF
    }

    my $wanted = 0; 
    $wanted = 2 if $env == 2 || $flag == 2;
    $wanted = 1 if $env == 1 || $flag == 1;

    unless ($wanted) {
        # if still unknown try to require mod_perl.pm
        eval { require mod_perl2 or require mod_perl };
        unless ($@) {
            $wanted = $mod_perl::VERSION >= 1.99 ? 2 : 1;
        }
    }

    return $wanted;
}


# the function looks at %ENV and Makefile.PL option to figure out
# whether a specific mod_perl generation was requested.
# It uses the following logic:
# via options:
# perl Makefile.PL MOD_PERL=2
# or via %ENV:
# env MOD_PERL=1 perl Makefile.PL
#
# return value is:
# 1 or 2 if the specification was found (mp 1 and mp 2 respectively)
# 0 otherwise
sub wanted_mp_generation {

    # check if we have a command line specification
    # flag: 0: unknown, 1: mp1, 2: mp2
    my $flag = 0;
    my @pass;
    while (@ARGV) {
        my $key = shift @ARGV;
        if ($key =~ /^MOD_PERL=(\d)$/) {
            $flag = $1;
        }
        else {
            push @pass, $key;
        }
    }
    @ARGV = @pass;

    # check %ENV
    my $env = exists $ENV{MOD_PERL} ? $ENV{MOD_PERL} : 0;

    # check for contradicting requirements
    if ($env && $flag && $flag != $env) {
        die <<EOF;
Can\'t decide which mod_perl version should be used, since you have
supplied contradicting requirements:
    enviroment variable MOD_PERL=$env
    Makefile.PL option  MOD_PERL=$flag
EOF
    }

    my $wanted = 0;
    $wanted = 2 if $env == 2 || $flag == 2;
    $wanted = 1 if $env == 1 || $flag == 1;

    unless ($wanted) {
        # if still unknown try to require mod_perl.pm
        eval { require mod_perl2 or require mod_perl };
        unless ($@) {
            $wanted = $mod_perl::VERSION >= 1.99 ? 2 : 1;
        }
    }

    return $wanted;
}

