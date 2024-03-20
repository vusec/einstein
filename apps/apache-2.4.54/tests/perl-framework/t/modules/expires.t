use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Time::Local;

## mod_expires tests
##
## extra.conf.in:
## 
## <Directory @SERVERROOT@/htdocs/modules/expires>
## ExpiresActive On
## ExpiresDefault "modification plus 10 years 6 months 2 weeks 3 days 12 hours 30 minutes 19 seconds"
## ExpiresByType text/plain M60
## ExpiresByType image/gif A120
## ExpiresByType image/jpeg A86400
## </Directory>
##

## calculate "modification plus 10 years 6 months 2 weeks 3 days 12 hours 30 minutes 19 seconds"
my $expires_default = calculate_seconds(10,6,2,3,12,30,19);

my $htdocs = Apache::Test::vars('documentroot');
my $htaccess = "$htdocs/modules/expires/htaccess/.htaccess";
my @page = qw(index.html text.txt image.gif foo.jpg);
my @types = qw(text/plain image/gif image/jpeg);
my @directive = qw(ExpiresDefault ExpiresByType);

## first the settings in extra.conf.in (server level)
my %exp  = default_exp();

my %names =
    (
     'Date'          => 'access',
     'Expires'       => 'expires',
     'Last-Modified' => 'modified',
     'Content-Type'  => 'type',
    );

my %month = ();
my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
@month{@months} = 0..@months-1;

plan tests => (@page * 2) + ((((@page * 3) * @types) + @page) * 2) + @page,
    have_module 'expires';

foreach my $page (@page) {
    my $head = HEAD_STR "/modules/expires/$page";
    $head = '' unless defined $head;
    print "# debug: $page\n$head\n";
    ok ($head =~ /^HTTP\/1\.[1|0] 200 OK/);
    ok expires_test(1,$head);
}

unlink $htaccess if -e $htaccess;
## with no .htaccess file, everything should be inherited here ##
foreach my $page (@page) {
    my $head = HEAD_STR "/modules/expires/htaccess/$page";
    ok expires_test(1,$head);
}

## testing with .htaccess ##
foreach my $on_off (qw(On Off)) {

    my $ExpiresActive = "ExpiresActive $on_off\n";
    write_htaccess($ExpiresActive);
    %exp = default_exp();

    ## if ExpiresActive is 'On', everything else will be inherited ##
    foreach my $page (@page) {
        my $head = HEAD_STR "/modules/expires/htaccess/$page";
        print "# ---\n# $ExpiresActive";
        ok expires_test(($on_off eq 'On'),$head);
    }

    foreach my $t (@types) {

        my ($head, $directive_string, $gmsec, $a_m,
            $ExpiresDefault, $ExpiresByType);

        ## testing with just ExpiresDefault directive ##
        $a_m = (qw(A M))[int(rand(2))];
        ($gmsec, $ExpiresDefault) = get_rand_time_str($a_m);
        %exp = default_exp();
        set_exp('default', "$a_m$gmsec");
        $directive_string = $ExpiresActive .
                            "ExpiresDefault $ExpiresDefault\n";
        write_htaccess($directive_string);
        foreach my $page (@page) {
            $head = HEAD_STR "/modules/expires/htaccess/$page";
            print "#---\n# $directive_string";
            ok expires_test(($on_off eq 'On'), $head);
        }

        ## just ExpiresByType directive ##
        $a_m = (qw(A M))[int(rand(2))];
        ($gmsec, $ExpiresByType) = get_rand_time_str($a_m);
        %exp = default_exp();
        set_exp($t, "$a_m$gmsec");
        $directive_string = $ExpiresActive .
                            "ExpiresByType $t $ExpiresByType\n";
        write_htaccess($directive_string);
        foreach my $page (@page) {
            $head = HEAD_STR "/modules/expires/htaccess/$page";
            print "# ---\n# $directive_string";
            ok expires_test(($on_off eq 'On'), $head);
        }

        ## both ##
        $a_m = (qw(A M))[int(rand(2))];
        ($gmsec, $ExpiresDefault) = get_rand_time_str($a_m);
        %exp = default_exp();
        set_exp('default', "$a_m$gmsec");
        $a_m = (qw(A M))[int(rand(2))];
        ($gmsec, $ExpiresByType) = get_rand_time_str($a_m);
        set_exp($t, "$a_m$gmsec");
        $directive_string = $ExpiresActive .
                            "ExpiresDefault $ExpiresDefault\n" .
                            "ExpiresByType $t $ExpiresByType\n";
        write_htaccess($directive_string);
        foreach my $page (@page) {
            $head = HEAD_STR "/modules/expires/htaccess/$page";
            print "# ---\n# $directive_string";
            ok expires_test(($on_off eq 'On'), $head);
        }
    }
}

## clean up ##
unlink $htaccess if -e $htaccess;

sub set_exp {
    my $key = shift;
    my $exp = shift;

    if ($key eq 'all') {
        foreach (keys %exp) {
            $exp{$_} = $exp;
        }
    } else {
        $exp{$key} = $exp;
    }
}

sub get_rand_time_str {
    my $a_m = shift;
    my ($y, $m, $w, $d, $h, $mi, $s, $rand_time_str);
    $y = int(rand(2));
    $m = int(rand(4));
    $w = int(rand(3));
    $d = int(rand(20));
    $h = int(rand(9));
    $mi = int(rand(50));
    $s = int(rand(50));
    my $gmsec = calculate_seconds($y,$m,$w,$d,$h,$mi,$s);

    ## whether to write it out or not ##
    if (int(rand(2))) {
        ## write it out ##

        ## access or modification ##
        if ($a_m eq 'A') {
            $rand_time_str = "\"access plus";
        } else {
            $rand_time_str = "\"modification plus";
        }

        $rand_time_str .= " $y years"    if $y;
        $rand_time_str .= " $m months"   if $m;
        $rand_time_str .= " $w weeks"    if $w;
        $rand_time_str .= " $d days"     if $d;
        $rand_time_str .= " $h hours"    if $h;
        $rand_time_str .= " $mi minutes" if $mi;
        $rand_time_str .= " $s seconds"  if $s;
        $rand_time_str .= "\"";
        
    } else {
        ## easy format ##
        $rand_time_str = "$a_m$gmsec";
    }

    return ($gmsec, $rand_time_str);
}

sub write_htaccess {
    open (HT, ">$htaccess") or die "cant open $htaccess: $!";
    print HT shift;
    close(HT);
}

sub expires_test {
    my $expires_active = shift;
    my $head_str = shift;
    my %headers = ();

    foreach my $header (split /\n/, $head_str) {
        if ($header =~ /^([\-\w]+): (.*)$/) {
            print "# debug: [$1] [$2]\n";
            $headers{$names{$1}} = $2 if exists $names{$1};
        }
    }

    ## expires header should not exist if ExpiresActive is Off ##
    return !$headers{expires} unless ($expires_active);

    for my $h (grep !/^type$/, values %names) {
        print "# debug: $h @{[$headers{$h}||'']}\n";
        if ($headers{$h}) {
            $headers{$h} = convert_to_time($headers{$h}) || 0;
        } else {
            $headers{$h} = 0;
        }
        print "# debug: $h $headers{$h}\n";
    }

    my $exp_conf = '';
    if ( exists $exp{ $headers{type} } and $exp{ $headers{type} }) {
        $exp_conf = $exp{ $headers{type} };
    } else {
        $exp_conf = $exp{'default'};
    }

    ## if expect is set to '0', Expire header should not exist. ##
    if ($exp_conf eq '0') {
        return !$headers{expires};
    } 

    my $expected = '';
    my $exp_type = '';
    if ($exp_conf =~ /^([A|M])(\d+)$/) {
        $exp_type = $1;
        $expected = $2;
        ## With modification date as base expire times can be in the past
        ## Correct behaviour for the server in this case is to set expires
        ## time equal to access time.
        if (($exp_type eq 'M')
            && ($headers{access} > $headers{modified} + $expected)) {
            $expected = $headers{access} - $headers{modified};
        }
    } else {
        print STDERR "\n\ndoom: $exp_conf\n\n";
        return 0;
    }

    my $actual = 0;
    if ($exp_type eq 'M') {
        $actual = $headers{expires} - $headers{modified};
    } elsif ($exp_type eq 'A') {
        $actual = $headers{expires} - $headers{access};
    }

    print "# debug: expected: $expected\n";
    print "# debug: actual  : $actual\n";
    return ($actual == $expected);

}

sub convert_to_time {
    my $timestr = shift;
    return undef unless $timestr;

    my ($sec,$min,$hours,$mday,$mon,$year);
    if ($timestr =~ /^\w{3}, (\d+) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}).*$/) {
        $mday  = $1;
        $mon   = $month{$2};
        $year  = $3;
        $hours = $4;
        $min   = $5;
        $sec   = $6;
    }

    return undef 
        unless 
            defined $sec   && 
            defined $min   && 
            defined $hours && 
            defined $mday  && 
            defined $mon   && 
            defined $year;

    return Time::Local::timegm($sec, $min, $hours, $mday, $mon, $year);
}

sub calculate_seconds {
    ## takes arguments:
    ## years, months, weeks, days, hours, minutes, seconds
    my $exp_years =     shift() * 60 * 60 * 24 * 365;
    my $exp_months =    shift() * 60 * 60 * 24 * 30;
    my $exp_weeks =     shift() * 60 * 60 * 24 * 7;
    my $exp_days =      shift() * 60 * 60 * 24;
    my $exp_hours =     shift() * 60 * 60;
    my $exp_minutes =   shift() * 60;
    return $exp_years + $exp_months + $exp_weeks +
        $exp_days + $exp_hours + $exp_minutes + shift;
}

sub default_exp {
    ## set the exp hash to the defaults as defined in the conf file.
    return
    (	
     'default'    => "M$expires_default",
     'text/plain' => 'M60',
     'image/gif'  => 'A120',
     'image/jpeg' => 'A86400'
    );
}
