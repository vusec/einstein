use 5.005;

use lib qw(../lib); # Apache-Test/lib
use Apache::Test5005compat;

use strict;
use warnings;

use ExtUtils::MakeMaker;

use Apache::TestMM ();

Apache::TestMM::generate_script('t/TEST');

my @clean_files =
    qw(t/TEST
       Makefile.old
      );

my %prereq = (
    # needed to be able to use one perl version to drive the test
    # suite, but a different version from the tests themselves
    'Test::Harness' => '2.44',
);

WriteMakefile(
    NAME      => 'Apache::TestItSelf',
    PREREQ_PM => \%prereq,
    VERSION   => "0.01",
    NORECURS  => 1, # don't descend into Apache-TestMe
    DIR       => [], # NORECURS is broken in older MM
    dist      => {
        COMPRESS => 'gzip -9f', SUFFIX=>'gz',
    },
    clean     => {
        FILES => "@clean_files",
    },
);


