use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

my $vars = Apache::Test::vars();
my $htdocs = Apache::Test::vars('documentroot');
my $body;

##
## mod_setenvif tests
##

my $good_ua = '^libwww-perl/.*';
my $bad_ua = 'foo-browser/0.1';

my $page = "/modules/setenvif/htaccess/setenvif.shtml";
my %var_att =
    (
        'Remote_Host' =>
            {
                'pass' => $vars->{remote_addr},
                'fail' => 'some.where.else.com'
            },
        'Remote_Addr' =>
            {
                'pass' => $vars->{remote_addr},
                'fail' => '63.125.18.195'
            },
        'Request_Method' =>
            {
                'pass' => 'GET',
                'fail' => 'POST'
            },
        'Request_Protocol' =>
            {
                'pass' => 'HTTP',
                'fail' => 'FTP'
            },
        'Request_URI' =>
            {
                'pass' => $page,
                'fail' => 'foo.html'
            },
        # Test with a regex. Looking for 'User-Agent'
        '^User-Ag' =>
            {
                'pass' => $good_ua,
                'fail' => $bad_ua
            }
    );

my @var = qw(VAR_ONE VAR_TWO VAR_THREE);

my $htaccess = "$htdocs/modules/setenvif/htaccess/.htaccess";

plan tests => @var * 10 + (keys %var_att) * 6 * @var + 4,
    have_module qw(setenvif include);

sub write_htaccess {
    my $string = shift;
    open (HT, ">$htaccess") or die "can't open $htaccess: $!";
    print HT $string;
    close(HT);
}

sub test_all_vars {
    my $exp_modifier = shift;
    my $conf_str = shift;
    my $set = 'set';

    my ($actual, $expected);
    foreach my $var (@var) {
        $conf_str .= " $var=$set";
        write_htaccess($conf_str);
        $expected = set_expect($exp_modifier, $conf_str);
        $actual = GET_BODY $page;
        $actual =~ s/\r//sg; #win32

        print "---\n";
        print "conf:\n$conf_str\n";
        print "expecting:\n->$expected<-\n";
        print "got:\n->$actual<-\n";

        ok ($actual eq $expected);
    }
}

sub set_expect {
    my $not = shift;
    my $conf_str = shift;
    my ($v, $exp_str) = ('','');

    my %exp =
    (
        1 => 'VAR_ONE',
        2 => 'VAR_TWO',
        3 => 'VAR_THREE'
    );

    foreach (sort keys %exp) {
        my $foo = $exp{$_};
        $v = '(none)';
        if ($conf_str =~ /$foo=(\S+)/) {
            $v = $1 unless $not;
        }

        $exp_str .= "$_:$v\n";
    }

    return $exp_str;
}

## test simple browser match ##
test_all_vars(0,"BrowserMatch $good_ua");
test_all_vars(1,"BrowserMatch $bad_ua");

## test SetEnvIf with variable attributes ##
foreach my $attribute (sort keys %var_att) {
    test_all_vars(0,"SetEnvIf $attribute $var_att{$attribute}{pass}");
    test_all_vars(1,"SetEnvIf $attribute $var_att{$attribute}{fail}");

    ## some 'relaying' variables ##
    test_all_vars(0,
        "SetEnvIf $attribute $var_att{$attribute}{pass} RELAY=1\nSetEnvIf RELAY 1");
    test_all_vars(1,
        "SetEnvIf $attribute $var_att{$attribute}{pass} RELAY=1\nSetEnvIf RELAY 0");

    ## SetEnvIfNoCase tests ##
    my $uc = uc $var_att{$attribute}{pass};
    test_all_vars(0,"SetEnvIfNoCase $attribute $uc");
    $uc = uc $var_att{$attribute}{fail};
    test_all_vars(1,"SetEnvIfNoCase $attribute $uc");
}

## test 'relaying' variables ##
test_all_vars(0,"BrowserMatch $good_ua RELAY=1\nSetEnvIf RELAY 1");
test_all_vars(0,
    "BrowserMatch $good_ua RELAY=1\nSetEnvIf RELAY 1 R2=1\nSetEnvIf R2 1");
test_all_vars(1,
    "BrowserMatch $good_ua RELAY=1\nSetEnvIf RELAY 1 R2=1\nSetEnvIf R2 0");
test_all_vars(1,"BrowserMatch $good_ua RELAY=0\nSetEnvIf RELAY 1");
test_all_vars(1,"BrowserMatch $good_ua RELAY=1\nSetEnvIf RELAY 0");

## test '!' ##
# We set then unset 'R2' (see a few lines above for the corresponding test, without the 'unset'
test_all_vars(1,
    "BrowserMatch $good_ua RELAY=1\nSetEnvIf RELAY 1 R2=1\nSetEnvIf RELAY 1 !R2\nSetEnvIf R2 1");

## test SetEnvIfExpr ##
test_all_vars(0, "SetEnvIfExpr \"%{REQUEST_URI} =~ /\.shtml\$/\"");
test_all_vars(1, "SetEnvIfExpr \"%{REQUEST_URI} =~ /\.foo\$/\"");

## test SetEnvIfExpr with replacement ##
write_htaccess("SetEnvIfExpr \"%{REQUEST_URI} =~ /\.\(sh\)tml\$/\" VAR_ONE=\$0 VAR_TWO=\$1");
$body = GET_BODY $page;
ok t_cmp($body, "1:.shtml\n2:sh\n3:(none)\n");

write_htaccess("SetEnvIfExpr \"%{REQUEST_URI} !~ /\.\(sh\)tml\$/\" VAR_ONE=\$0 VAR_TWO=\$1");
$body = GET_BODY $page;
ok t_cmp($body, "1:(none)\n2:(none)\n3:(none)\n");

## test SetEnvIfExpr with replacement when regex does NOT match ##
write_htaccess("SetEnvIfExpr \"%{REQUEST_URI} =~ /\.\(sh\)tmlXXX\$/\" VAR_ONE=\$0 VAR_TWO=\$1");
$body = GET_BODY $page;
ok t_cmp($body, "1:(none)\n2:(none)\n3:(none)\n");

if (need_min_apache_version("2.4.38")) {
    ## test SetEnvIfExpr with replacement when regex is REQUIRED to NOT match ##
    write_htaccess("SetEnvIfExpr \"%{REQUEST_URI} !~ /\.\(sh\)tmlXXX\$/\" VAR_ONE=\$0 VAR_TWO=\$1");
    $body = GET_BODY $page;
    ok t_cmp($body, "1:\$0\n2:\$1\n3:(none)\n");
}
else {
    # Skip for versions without r1786235 backported
    skip "skipping inverted match test with version <2.4.38"
}

## i think this should work, but it doesnt.
## leaving it commented now pending investigation.
## seems you cant override variables that have been previously set.
##
## test_all_vars(0,
##     "SetEnv RELAY 1\nSetEnvIf RELAY 1 RELAY=2\nSetEnvIf RELAY 2");
## test_all_vars(0,
##     "BrowserMatch $good_ua RELAY=1\nSetEnvIf RELAY 1 RELAY=2\nSetEnvIf RELAY 2");
##
##

## clean up ##
unlink $htaccess if -e $htaccess;
