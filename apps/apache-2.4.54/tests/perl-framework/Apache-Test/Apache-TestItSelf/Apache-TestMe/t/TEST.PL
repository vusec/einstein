use strict;

use FindBin;
# test against the A-T source lib for easier dev
use lib "$FindBin::Bin/../../../lib";

use lib qw(lib ../lib);

use warnings FATAL => 'all';

use Apache::TestRunPerl ();

package MyTest;

use vars qw(@ISA);
@ISA = qw(Apache::TestRunPerl);

sub new_test_config {
    my $self = shift;

    #$self->{conf_opts}->{authname}      = 'gold club';

    return $self->SUPER::new_test_config;
}

sub bug_report {
    my $self = shift;

    print <<EOI;
+-----------------------------------------------------+
| To report problems please refer to the SUPPORT file |
+-----------------------------------------------------+
EOI
}

MyTest->new->run(@ARGV);

