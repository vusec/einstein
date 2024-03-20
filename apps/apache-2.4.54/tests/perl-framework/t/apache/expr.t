use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_write_file t_start_error_log_watch t_finish_error_log_watch);

use File::Spec;

# test ap_expr

Apache::TestRequest::user_agent(keep_alive => 1);

my $file_foo = Apache::Test::vars('serverroot') . '/htdocs/expr/index.html';
my $dir_foo = Apache::Test::vars('serverroot') . '/htdocs/expr';
my $file_notexist = Apache::Test::vars('serverroot') . '/htdocs/expr/none';
my $file_zero = Apache::Test::vars('serverroot') . '/htdocs/expr/zero';
my $url_foo = '/apache/';
my $url_notexist = '/apache/expr/none';
my @test_cases = (
    [ 'true'  => 1     ],
    [ 'false' => 0     ],
    [ 'foo'   => undef ],
    # integer comparison
    [ '1 -eq 01' => 1 ],
    [ '1 -eq  2' => 0 ],
    [ '1 -ne  2' => 1 ],
    [ '1 -ne  1' => 0 ],
    [ '1 -lt 02' => 1 ],
    [ '1 -lt  1' => 0 ],
    [ '1 -le  2' => 1 ],
    [ '1 -le  1' => 1 ],
    [ '2 -gt  1' => 1 ],
    [ '1 -gt  1' => 0 ],
    [ '2 -ge  1' => 1 ],
    [ '1 -ge  1' => 1 ],
    [ '1 -gt -1' => 1 ],
    # string comparison
    [ q{'aa' == 'aa'}  => 1 ],
    [ q{'aa' == 'b'}   => 0 ],
    [ q{'aa' =  'aa'}  => 1 ],
    [ q{'aa' =  'b'}   => 0 ],
    [ q{'aa' != 'b'}   => 1 ],
    [ q{'aa' != 'aa'}  => 0 ],
    [ q{'aa' <  'b'}   => 1 ],
    [ q{'aa' <  'aa'}  => 0 ],
    [ q{'aa' <= 'b'}   => 1 ],
    [ q{'aa' <= 'aa'}  => 1 ],
    [ q{'b'  >  'aa'}  => 1 ],
    [ q{'aa' >  'aa'}  => 0 ],
    [ q{'b'  >= 'aa'}  => 1 ],
    [ q{'aa' >= 'aa'}  => 1 ],
    # string operations/whitespace handling
    [ q{'a' . 'b' . 'c' = 'abc'}              => 1 ],
    [ q{'a' .'b'. 'c' = 'abc'}                => 1 ],
    [ q{ 'a' .'b'. 'c'='abc' }                => 1 ],
    [ q{'a1c' = 'a'. 1. 'c'}                  => 1 ],
    [ q{req('foo') . 'bar' = 'bar'}           => 1 ],
    [ q[%{req:foo} . 'bar' = 'bar']           => 1 ],
    [ q['x'.%{req:foo} . 'bar' = 'xbar']      => 1 ],
    [ q[%{req:User-Agent} . 'bar' != 'bar']   => 1 ],
    [ q['%{req:User-Agent}' . 'bar' != 'bar'] => 1 ],
    [ q['%{TIME}' . 'bar' != 'bar']           => 1 ],
    [ q[%{TIME} != '']                        => 1 ],
    # string lists
    [ q{'a' -in { 'b', 'a' } } => 1 ],
    [ q{'a' -in { 'b', 'c' } } => 0 ],
    # regexps
    [ q[ 'abc' =~ /bc/ ]                 => 1 ],
    [ q[ 'abc' =~ /BC/i ]                => 1 ],
    [ q[ 'abc' !~ m!bc! ]                => 0 ],
    [ q[ 'abc' !~ m!BC!i ]               => 0 ],
    [ q[ $0 == '' ]                      => 1 ],
    [ q[ $1 == '' ]                      => 1 ],
    [ q[ $9 == '' ]                      => 1 ],
    [ q[ '$0' == '' ]                    => 1 ],
    [ q[ 'abc' =~ /(bc)/ && $0 == 'bc' ] => 1 ],
    [ q[ 'abc' =~ /(bc)/ && $1 == 'bc' ] => 1 ],
    [ q[ 'abc' =~ /b(.)/ && $1 == 'c' ]  => 1 ],
    # $0 .. $9 are only populated if there are capturing parens
    [ q[ 'abc' =~ /bc/ && $0 == '' ]                    => 1 ],
    [ q[ 'abc' =~ /(bc)/ && 'xy' =~ /x/ && $0 == 'bc' ] => 1 ],
    # Attempt to blow up when more matches are present than 'typical' $0 .. $9 
    [ q[ 'abcdefghijklm' =~ /(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)/ && $2 == 'c' ] => 1 ],
    # variables
    [ q[%{TIME_YEAR} =~ /^\d{4}$/]               => 1 ],
    [ q[%{TIME_YEAR} =~ /^\d{3}$/]               => 0 ],
    [ q[%{TIME_MON}  -gt 0 && %{TIME_MON}  -le 12 ] => 1 ],
    [ q[%{TIME_DAY}  -gt 0 && %{TIME_DAY}  -le 31 ] => 1 ],
    [ q[%{TIME_HOUR} -ge 0 && %{TIME_HOUR} -lt 24 ] => 1 ],
    [ q[%{TIME_MIN}  -ge 0 && %{TIME_MIN}  -lt 60 ] => 1 ],
    [ q[%{TIME_SEC}  -ge 0 && %{TIME_SEC}  -lt 60 ] => 1 ],
    [ q[%{TIME} =~ /^\d{14}$/]                   => 1 ],
    [ q[%{API_VERSION} -gt 20101001 ]            => 1 ],
    [ q[%{REQUEST_METHOD} == 'GET' ]             => 1 ],
    [ q['x%{REQUEST_METHOD}' == 'xGET' ]         => 1 ],
    [ q['x%{REQUEST_METHOD}y' == 'xGETy' ]       => 1 ],
    [ q[%{REQUEST_SCHEME} == 'http' ]            => 1 ],
    [ q[%{HTTPS} == 'off' ]                      => 1 ],
    [ q[%{REQUEST_URI} == '/apache/expr/index.html' ] => 1 ],
    # request headers
    [ q[%{req:referer}     = 'SomeReferer' ] => 1 ],
    [ q[req('Referer')     = 'SomeReferer' ] => 1 ],
    [ q[http('Referer')    = 'SomeReferer' ] => 1 ],
    [ q[%{HTTP_REFERER}    = 'SomeReferer' ] => 1 ],
    [ q[req('User-Agent')  = 'SomeAgent'   ] => 1 ],
    [ q[%{HTTP_USER_AGENT} = 'SomeAgent'   ] => 1 ],
    [ q[req('SomeHeader')  = 'SomeValue'   ] => 1 ],
    [ q[req('SomeHeader2') = 'SomeValue'   ] => 0 ],
    # functions
    [ q[toupper('abC12d') = 'ABC12D' ] => 1 ],
    [ q[tolower('abC12d') = 'abc12d' ] => 1 ],
    [ q[escape('?')       = '%3f' ]    => 1 ],
    [ q[unescape('%3f')   = '?' ]      => 1 ],
    [ q[toupper(escape('?')) = '%3F' ] => 1 ],
    [ q[tolower(toupper(escape('?'))) = '%3f' ] => 1 ],
    [ q[%{toupper:%{escape:?}} = '%3F' ] => 1 ],
    [ q[file('] . $file_foo . q[') = 'foo\n' ]  => 1 ],
    # unary operators
    [ q[-n '']  => 0 ],
    [ q[-z '']  => 1 ],
    [ q[-n '1'] => 1 ],
    [ q[-z '1'] => 0 ],
    # IP match
    [ q[-R 'abc']                   => undef ],
    [ q[-R %{REMOTE_ADDR}]          => undef ],
    [ q[-R '240.0.0.0']             => 0 ],
    [ q[-R '240.0.0.0/8']           => 0 ],
    [ q[-R 'ff::/8']                => 0 ],
    [ q[-R '127.0.0.1' || -R '::1'] => 1 ],
    [ q['127.0.0.1' -ipmatch 'abc']          => undef ],
    [ q['127.0.0.1' -ipmatch %{REMOTE_ADDR}] => undef ],
    [ q['127.0.0.1' -ipmatch '240.0.0.0']    => 0 ],
    [ q['127.0.0.1' -ipmatch '240.0.0.0/8']  => 0 ],
    [ q['127.0.0.1' -ipmatch 'ff::/8']       => 0 ],
    [ q['127.0.0.1' -ipmatch '127.0.0.0/8']  => 1 ],
    # fn/strmatch
    [ q['foo' -strmatch '*o']      => 1 ],
    [ q['fo/o' -strmatch 'f*']     => 1 ],
    [ q['foo' -strmatch 'F*']      => 0 ],
    [ q['foo' -strcmatch 'F*']     => 1 ],
    [ q['foo' -strmatch 'g*']      => 0 ],
    [ q['foo' -strcmatch 'g*']     => 0 ],
    [ q['a/b' -fnmatch 'a*']       => 0 ],
    [ q['a/b' -fnmatch 'a/*']      => 1 ],
    # error handling
    [ q['%{foo:User-Agent}' != 'bar'] => undef ],
    [ q[%{foo:User-Agent} != 'bar']   => undef ],
    [ q[foo('bar') = 'bar']           => undef ],
    [ q[%{FOO} != 'bar']              => undef ],
    [ q['bar' = bar]                  => undef ],
);

#
# Bool logic:
# Test all combinations with 0 to 2 '||' or '&&' operators
#
my @bool_base  = (
    [ q[true]   => 1 ],
);
push @bool_base, (
    [ q[-z '']  => 1 ],
    [ q[-n 'x'] => 1 ],
    [ q[false]  => 0 ],
    [ q[-n '']  => 0 ],
    [ q[-z 'x'] => 0 ],
) if 0; # This produces an exessive number of tests for normal operation

# negation function: perl's "!" returns undef for false, but we need 0
sub neg
{
    return (shift) ? 0 : 1;
}
# also test combinations with '!' operator before each operand
@bool_base = (@bool_base, map { ["!$_->[0]" => neg($_->[1]) ] } @bool_base);
# now create the test cases
my @bool_test_cases;
foreach my $ex1 (@bool_base) {
    my ($e1, $r1) = @$ex1;
    push @bool_test_cases, [ $e1 => $r1 ];
    foreach my $ex2 (@bool_base) {
        my ($e2, $r2) = @$ex2;
        push @bool_test_cases, [ "$e1 && $e2" => ($r1 && $r2) ];
        push @bool_test_cases, [ "$e1 || $e2" => ($r1 || $r2) ];
        foreach my $ex3 (@bool_base) {
            my ($e3, $r3) = @$ex3;
            foreach my $op1 ("||", "&&") {
                foreach my $op2 ("||", "&&") {
                    my $r = eval "$r1 $op1 $r2 $op2 $r3";
                    push @bool_test_cases, [ "$e1 $op1 $e2 $op2 $e3" => $r];
                }
            }
        }
    }
}
push @test_cases, @bool_test_cases;
# also test combinations with '!' operator before the whole expression
push @test_cases, map { ["!($_->[0])" => neg($_->[1]) ] } @bool_test_cases;

if (have_min_apache_version("2.3.13")) {
    push(@test_cases, (
        # functions
        [ q[filesize('] . $file_foo      . q[') = 4 ]  => 1 ],
        [ q[filesize('] . $file_notexist . q[') = 0 ]  => 1 ],
        [ q[filesize('] . $file_zero     . q[') = 0 ]  => 1 ],
        # unary operators
        [ qq[-d '$file_foo' ] => 0 ],
        [ qq[-e '$file_foo' ] => 1 ],
        [ qq[-f '$file_foo' ] => 1 ],
        [ qq[-s '$file_foo' ] => 1 ],
        [ qq[-d '$file_zero' ] => 0 ],
        [ qq[-e '$file_zero' ] => 1 ],
        [ qq[-f '$file_zero' ] => 1 ],
        [ qq[-s '$file_zero' ] => 0 ],
        [ qq[-d '$dir_foo' ] => 1 ],
        [ qq[-e '$dir_foo' ] => 1 ],
        [ qq[-f '$dir_foo' ] => 0 ],
        [ qq[-s '$dir_foo' ] => 0 ],
        [ qq[-d '$file_notexist' ] => 0 ],
        [ qq[-e '$file_notexist' ] => 0 ],
        [ qq[-f '$file_notexist' ] => 0 ],
        [ qq[-s '$file_notexist' ] => 0 ],
        [ qq[-F '$file_foo' ] => 1 ],
        [ qq[-F '$file_notexist' ] => 0 ],
        [ qq[-U '$url_foo' ] => 1 ],
        [ qq[-U '$url_notexist' ] => 0 ],
    ));
}

if (have_min_apache_version("2.4.5")) {
    push(@test_cases, (
        [ qq[sha1('foo') = '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33' ] => 1 ],
        [ qq[md5('foo') = 'acbd18db4cc2f85cedef654fccc4a4d8' ]          => 1 ],
        [ qq[base64('foo') = 'Zm9v' ]                                   => 1 ],
        [ qq[unbase64('Zm9vMg==') = 'foo2' ]                            => 1 ],
    ));
}

if (have_min_apache_version("2.5")) {
    my $SAN_one         = "email:<redacted1>, email:<redacted2>, " .
                          "IP Address:127.0.0.1, IP Address:0:0:0:0:0:0:0:1, " .
                          "IP Address:192.168.169.170";
    my $SAN_tuple       = "'email:<redacted1>', 'email:<redacted2>', " .
                          "'IP Address:127.0.0.1', 'IP Address:0:0:0:0:0:0:0:1', " .
                          "'IP Address:192.168.169.170'";
    my $SAN_list_one    = "{ '$SAN_one' }";
    my $SAN_list_tuple  = "{ $SAN_tuple }";

    my $SAN_split = '.*?IP Address:([^,]+)';

    push(@test_cases, (
        [ "join {'a', 'b', 'c'} == 'abc'"                                       => 1 ],
        [ "join($SAN_list_tuple, ', ') == " .
             "'email:<redacted1>, email:<redacted2>, " .
              "IP Address:127.0.0.1, IP Address:0:0:0:0:0:0:0:1, " .
              "IP Address:192.168.169.170'"                                     => 1 ],
        [ "join($SAN_list_tuple, ', ') == join $SAN_list_one"                   => 1 ],
        [ "join(split(s/$SAN_split/\$1/, $SAN_list_tuple), ', ') == " .
             "'email:<redacted1>, email:<redacted2>, " .
              "127.0.0.1, 0:0:0:0:0:0:0:1, 192.168.169.170'"                    => 1 ],
        [ "join(split(s/$SAN_split/\$1/, $SAN_list_one), ', ') == " .
             "'127.0.0.1, 0:0:0:0:0:0:0:1, 192.168.169.170'"                    => 1 ],
        [ "'IP Address:192.168.169.170' -in $SAN_list_tuple"                    => 1 ],
        [ "'192.168.169.170' -in split s/$SAN_split/\$1/, $SAN_list_tuple"      => 1 ],
        [ "'0:0:0:0:0:0:0:1' -in split s/$SAN_split/\$1/, $SAN_list_one"        => 1 ],
        [ "%{REMOTE_ADDR} -in split s/$SAN_split/\$1/, $SAN_list_one"           => 1 ],
        [ "'email:<redacted1>' -in split s/$SAN_split/\$1/, $SAN_list_tuple"    => 1 ],
        [ "'email:<redacted2>' -in split s/$SAN_split/\$1/, $SAN_list_one"      => 0 ],
        [ "'IP Address:%{REMOTE_ADDR}' -in split/, /, join $SAN_list_one"
                                                                                => 1 ],
        [ "replace(%{REQUEST_METHOD},  'E', 'O') == 'GOT'" => 1],
        [ "replace(%{REQUEST_METHOD},  'E', 'O') == 'GET'" => 0],
    ));
}

plan tests => scalar(@test_cases) + 1,
                  need need_lwp,
                  need_module('mod_authz_core'),
                  need_min_apache_version('2.3.9');

t_start_error_log_watch();

my %rc_map = ( 500 => 'parse error', 403 => 'true', 200 => 'false');
foreach my $t (@test_cases) {
    my ($expr, $expect) = @{$t};

    write_htaccess($expr);

    my $response = GET('/apache/expr/index.html',
                       'SomeHeader' => 'SomeValue',
                       'User-Agent' => 'SomeAgent',
                       'Referer'    => 'SomeReferer');
    my $rc = $response->code;
    if (!defined $expect) {
        print qq{Should get parse error for "$expr", got $rc_map{$rc}\n};
        ok($rc == 500);
    }
    elsif ($expect) {
        print qq{"$expr" should evaluate to true, got $rc_map{$rc}\n};
        ok($rc == 403);
    }
    else {
        print qq{"$expr" should evaluate to false, got $rc_map{$rc}\n};
        ok($rc == 200);
    }
}

my @loglines = t_finish_error_log_watch();
my @evalerrors = grep { /internal evaluation error/i } @loglines;
my $num_errors = scalar @evalerrors;
print "Error log should not have 'Internal evaluation error' entries, found $num_errors\n";
ok($num_errors == 0);

exit 0;

### sub routines
sub write_htaccess
{
    my $expr = shift;
    my $file = File::Spec->catfile(Apache::Test::vars('serverroot'), 'htdocs', 'apache', 'expr', '.htaccess');
    t_write_file($file, << "EOF" );
<If "$expr">
    Require all denied
</If>
EOF
}

