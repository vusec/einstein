use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

# This test tests how good Apache-Test deals with bad coding practices
# of its users

plan tests => 1;

{
    # passing $_ to a non-core function inside a foreach loop or
    # similar, may affect $_ on return -- badly breaking things and
    # making it hard to figure out where the problem is coming from.
    #
    # have_* macros localize $_ for these bad programming cases
    # let's test that:
    my @list = ('mod_dir');
    my %modules = map { $_, have_module($_) } @list;
    ok 1;
}
