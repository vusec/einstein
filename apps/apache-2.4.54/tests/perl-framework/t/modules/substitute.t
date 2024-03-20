use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_write_file);

Apache::TestRequest::user_agent(keep_alive => 1);

my $debug = 0;
my $url = '/modules/substitue/test.txt';

# mod_bucketeer control chars
my $B = chr(0x02);
my $F = chr(0x06);
my $P = chr(0x10);

my @simple_cases = ();

my @test_cases = (
    [ "f${B}o${P}ofoo" => 's/foo/bar/' ],
    [ "f${B}o${P}ofoo" => 's/fo/fa/', 's/fao/bar/' ],
    [ "foofoo"         => 's/Foo/bar/' ],
    [ "fo${F}ofoo"     => 's/Foo/bar/i' ],
    [ "foOFoo"         => 's/OF/of/', 's/foo/bar/' ],
    [ "fofooo"         => 's/(.)fo/$1of/', 's/foo/bar/' ],
    [ "foof\noo"       => 's/f.oo/bar/' ],
    [ "xfooo"          => 's/foo/fo/' ],
    [ "xfoo" x 4000    => 's/foo/bar/', 's/FOO/BAR/' ],
    [ "foox\n" x 4000  => 's/foo/bar/', 's/FOO/BAR/' ],
    [ "a.baxb("        => 's/a.b/a$1/n' ],
    [ "a.baxb("        => 's/a.b/a$1/n', 's/1axb(/XX/n' ],
    [ "xfoo" x 4000    => 's/foo/bar/n', 's/FOO/BAR/n' ],
);

if (have_min_apache_version("2.3.5")) {
    # tests for r1307067
    push @test_cases, [ "x<body>x" => 's/<body>/&/' ],
                      [ "x<body>x" => 's/<body>/$0/' ],
                      [ "foobar"   => 's/(oo)b/c$1/' ],
                      [ "foobar"   => 's/(oo)b/c\$1/' ],
                      [ "foobar"   => 's/(oo)b/\d$1/' ];
}

if (have_min_apache_version("2.4.42")) {
    push @simple_cases, [ "foo\nbar" => 's/foo.*/XXX$0XXX', "XXXfooXXX\nbar" ],
}
plan tests => scalar @test_cases + scalar @simple_cases,
              need need_lwp,
              need_module('mod_substitute'),
              need_module('mod_bucketeer');

foreach my $t (@test_cases) {
    my ($content, @rules) = @{$t};

    write_testfile($content);
    write_htaccess(@rules);

    # We assume that perl does the right thing (TM) and compare that with
    # mod_substitute's result.
    my $expect = $content;
    $expect =~ s/[$B$F$P]+//g;
    foreach my $rule (@rules) {
        if ($rule =~ s/n$//) {
            # non-regex match, escape specials for perl
            my @parts = split('/', $rule);
            $parts[1] = quotemeta($parts[1]);
            $parts[2] = quotemeta($parts[2]);
            $rule = join('/', @parts);
            $rule .= '/' if (scalar @parts == 3);
        }
        else {
            # special case: HTTPD uses $0 for the whole match, perl uses $&
            $rule =~ s/\$0/\$&/g;
        }
        $rule .= "g";   # mod_substitute always does global search & replace

	# "no warnings" because the '\d' in one of the rules causes a warning,
	# which we have set to be fatal.
        eval "{\n no warnings ; \$expect =~ $rule\n}";
    }

    my $response = GET('/modules/substitute/test.txt');
    my $rc = $response->code;
    my $got = $response->content;
    my $ok = ($rc == 200) && ($got eq $expect);
    print "got $rc '$got'", ($ok ? ": OK\n" : ", expected '$expect'\n");

    ok($ok);
}

foreach my $t (@simple_cases) {
    my ($content, $rule, $expect) = @{$t};
    write_testfile($content);
    write_htaccess($rule);
    my $response = GET('/modules/substitute/test.txt');
    my $rc = $response->code;
    my $got = $response->content;
    my $ok = ($rc == 200) && ($got eq $expect);
    print "got $rc '$got'", ($ok ? ": OK\n" : ", expected '$expect'\n");

    ok($ok);
}
exit 0;

### sub routines
sub write_htaccess
{
    my @rules = @_;
    my $file = File::Spec->catfile(Apache::Test::vars('serverroot'), 'htdocs',
                                   'modules', 'substitute', '.htaccess');
    my $content = "SetOutputFilter BUCKETEER;SUBSTITUTE\n";
    $content .= "Substitute $_\n" for @rules;
    t_write_file($file, $content);
    print "$content<===\n" if $debug;
}

sub write_testfile
{
    my $content = shift;
    my $file = File::Spec->catfile(Apache::Test::vars('serverroot'), 'htdocs',
                                   'modules', 'substitute', 'test.txt');
    t_write_file($file, $content);
    print "$content<===\n" if $debug;
}
