use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

## 
## mod_dir tests
##

my @index = qw(1 2 3 4 5 6 7 8 9 0);
my @bad_index = qw(foo goo moo bleh);
my $htdocs = Apache::Test::vars('documentroot');
my $htaccess = "$htdocs/modules/dir/htaccess/.htaccess";
my $url = "/modules/dir/htaccess/";
my ($actual, $expected);

#XXX: this is silly; need a better way to be portable
sub my_chomp {
    $actual =~ s/[\r\n]+$//s;
}

plan tests => @bad_index * @index * 5 + @bad_index + 5 + 3, need_module 'dir';

foreach my $bad_index (@bad_index) {

    print "expecting 403 (forbidden) using DirectoryIndex $bad_index\n";
    $expected = (have_module 'autoindex') ? 403 : 404;
    write_htaccess("$bad_index");
    $actual = GET_RC $url;
    ok ($actual == $expected);

    foreach my $index (@index) {

        print "running 5 test gambit for \"$index.html\"\n";
        ## $index will be expected for all
        ## tests at this level
        $expected = $index;

        write_htaccess("$index.html");
        $actual = GET_BODY $url;
        ok ($actual eq $expected);

        write_htaccess("$bad_index $index.html");
        $actual = GET_BODY $url;
        ok ($actual eq $expected);

        write_htaccess("$index.html $bad_index");
        $actual = GET_BODY $url;
        ok ($actual eq $expected);

        write_htaccess("/modules/alias/$index.html");
        $actual = GET_BODY $url;
        ok ($actual eq $expected);

        write_htaccess("$bad_index /modules/alias/$index.html");
        $actual = GET_BODY $url;
        ok ($actual eq $expected);
    }
}

print "DirectoryIndex /modules/alias/index.html\n";
$expected = "alias index";
write_htaccess("/modules/alias/index.html");
$actual = GET_BODY $url;
my_chomp();
ok ($actual eq $expected);

print "expecting 403 for DirectoryIndex @bad_index\n";
$expected = (have_module 'autoindex') ? 403 : 404;
write_htaccess("@bad_index");
$actual = GET_RC $url;
ok ($actual == $expected);

$expected = $index[0];
my @index_html = map { "$_.html" } @index;
print "expecting $expected with DirectoryIndex @index_html\n";
write_htaccess("@index_html");
$actual = GET_BODY $url;
ok ($actual eq $expected);

print "expecting $expected with DirectoryIndex @bad_index @index_html\n";
write_htaccess("@bad_index @index_html");
$actual = GET_BODY $url;
ok ($actual eq $expected);

unlink $htaccess;
print "removed .htaccess (no DirectoryIndex), expecting default (index.html)\n";
$expected = "dir index";
$actual = GET_BODY $url;
my_chomp();
ok ($actual eq $expected);

# DirectorySlash stuff
my $res = GET "/modules/dir", redirect_ok => 0;
ok ($res->code == 301);
$res = GET "/modules/dir/htaccess", redirect_ok => 0;
ok ($res->code == 403);

if (!have_min_apache_version('2.5.1')) { 
    skip("missing DirectorySlash NotFound");
}
else { 
    $res = GET "/modules/dir/htaccess/sub", redirect_ok => 0;
    ok ($res->code == 404);
}


sub write_htaccess {
    my $string = shift;

    open (HT, ">$htaccess") or die "cannot open $htaccess: $!";
    print HT "DirectoryIndex $string";
    close (HT);
}
