#!perl

use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil qw/t_start_file_watch t_file_watch_for
			t_cmp t_catfile t_append_file/;

plan tests => 5, need_fork;

my $fn=t_catfile(Apache::Test::vars->{t_logs}, 'watch');
unlink $fn;

t_start_file_watch 'watch';

my $pid;
select undef, undef, undef, 0.1 until defined($pid=fork);
unless ($pid) {			# child
    t_append_file $fn, "\nhuhu\n4 5 6 \nblabla\n";
    for(1..3) {
	select undef, undef, undef, 0.3;
	t_append_file $fn, "$_ ";
    }
    t_append_file $fn, "\nhuhu\n4 5 6 \nblabla";
    exit 0;
}

ok t_cmp t_file_watch_for('watch', qr/^1 2 3 $/, 2),
    "1 2 3 \n", 'incomplete line';

my @lines=t_file_watch_for('watch', qr/^\d \d \d $/, 2);
ok t_cmp @lines, 2, '2 lines';
ok t_cmp $lines[0], "huhu\n", '1st line';
ok t_cmp $lines[1], "4 5 6 \n", 'found it';

ok t_cmp t_file_watch_for('watch', qr/^\d \d \d $/, 0.3),
    undef, 'timeout';

waitpid $pid, 0;
