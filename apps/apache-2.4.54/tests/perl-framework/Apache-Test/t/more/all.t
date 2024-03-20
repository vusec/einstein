# skip all the Test::More tests if Test::More is
# not of a sufficient version;

use strict;
use warnings FATAL => 'all';

use Apache::Test;

plan tests => 1, need need_min_module_version(qw(Test::More 0.48_01)),
    need_module('mod_perl.c');

ok 1;


# the t/more/ directory is testing a few things.
#
# first, it is testing that the special
#    Apache::Test qw(-withtestmore);
# import works, which allows Apache::Test to use
# Test::More as the backend (in place of Test.pm)
# for server-side tests.
#
# secondly, it is testing that we can intermix
# scripts that use Test.pm and Test::More as the
# backend, which was a bug that needed to be worked
# around in early implementations of -withtestmore.
# hence the reason for the specific ordering of the
# tests in t/more/.
