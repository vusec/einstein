use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil qw/t_start_file_watch
                        t_read_file_watch
                        t_finish_file_watch
                        t_write_file
                        t_append_file
                        t_catfile
                        t_cmp/;

plan tests => 11;

my $fn=t_catfile(Apache::Test::vars->{t_logs}, 'watch');
unlink $fn;

t_start_file_watch 'watch';

t_write_file $fn, "1\n2\n";

ok t_cmp [t_read_file_watch 'watch'], ["1\n", "2\n"],
    "t_read_file_watch on previously non-existing file";

t_append_file $fn, "3\n4\n";

ok t_cmp [t_read_file_watch 'watch'], ["3\n", "4\n"],
    "subsequent t_read_file_watch";

t_append_file $fn, "5\n6\n";

ok t_cmp [t_finish_file_watch 'watch'], ["5\n", "6\n"],
    "subsequent t_finish_file_watch";

ok t_cmp [t_finish_file_watch 'watch'], ["1\n","2\n","3\n","4\n","5\n","6\n"],
    "t_finish_file_watch w/o start";

ok t_cmp [t_read_file_watch 'watch'], ["1\n","2\n","3\n","4\n","5\n","6\n"],
    "t_read_file_watch w/o start";

ok t_cmp [t_read_file_watch 'watch'], [],
    "subsequent t_read_file_watch";

t_append_file $fn, "7\n8\n";
unlink $fn;

ok t_cmp [t_read_file_watch 'watch'], ["7\n","8\n"],
    "subsequent t_read_file_watch file unlinked";

t_write_file $fn, "1\n2\n3\n4\n5\n6\n7\n8\n";

ok t_cmp [t_finish_file_watch 'watch'], [],
    "subsequent t_finish_file_watch - new file exists but fh is cached";

t_start_file_watch 'watch';

ok t_cmp [t_read_file_watch 'watch'], [],
    "t_read_file_watch at EOF";

# Make sure the file is closed before deleting it on Windows.
t_finish_file_watch 'watch' if $^O eq 'MSWin32';

unlink $fn;
t_start_file_watch 'watch';

t_write_file $fn, "1\n2\n3\n4\n5\n6\n7\n8\n";

{
    local $/=\4;

    ok t_cmp [scalar t_read_file_watch 'watch'], ["1\n2\n"],
        "t_read_file_watch fixed record length / scalar context";

    ok t_cmp [t_finish_file_watch 'watch'], ["3\n4\n","5\n6\n","7\n8\n"],
        "t_finish_file_watch fixed record length";
}
