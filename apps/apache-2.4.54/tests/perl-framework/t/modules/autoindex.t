use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

##
## mod_autoindex test
##
## 9-4-01
## this only tests for a very limited set of functionality
## in the autoindex module.  namely, file sorting and display
## with IndexOrderDefault directive and FancyIndexing.
## more to come...

my $htdocs = Apache::Test::vars('documentroot');
my $ai_dir = "/modules/autoindex";
my $uri_prefix = "$ai_dir/htaccess";
my $dir = "$htdocs$uri_prefix";
my $htaccess = "$dir/.htaccess";
my $readme = 'autoindex test README';
my $s = 'HITHERE';
my $uri = "$uri_prefix/";
my $file_prefix = 'ai-test';
my ($C,$O);
my $cfg = Apache::Test::config();
my $have_apache_2 = have_apache 2;
my $hr = $have_apache_2 ? '<hr>' : '<hr />';

my %file =
(
    README =>
    {
        size => length($readme),
        date => 998932210 
    },
    txt =>
    {
        size => 5,
        date => 998934398
    },
    jpg =>
    {
        size => 15,
        date => 998936491
    },
    gif =>
    {
        size => 1568,
        date => 998932291
    },
    html =>
    {
        size => 9815,
        date => 922934391
    },
    doc =>
    {
        size => 415,
        date => 998134391
    },
    gz =>
    {
        size => 1,
        date => 998935991
    },
    tar =>
    {
        size => 1009845,
        date => 997932391
    },
    php =>
    {
        size => 913515,
        date => 998434391
    }
);

plan tests => 84, ['autoindex'];

## set up environment ##
$cfg->gendir("$htdocs/$ai_dir");
$cfg->gendir("$dir");
test_content('create');

## run tests ##
foreach my $fancy (0,1) {

    ## test default order requests ##
    foreach my $order (qw(Ascending Descending)) {
        $O = substr($order, 0, 1);

        foreach my $component (qw(Name Date Size)) {
            $C = substr($component, 0, 1);
            $C = 'M' if $C eq 'D';
            my $config_string = '';
            $config_string = "IndexOptions FancyIndexing\n" if $fancy;
            $config_string .= "IndexOrderDefault $order $component\n";

            print "---\n$config_string\n";
            sok { ai_test($config_string,$C,$O,$uri) };

            ## test explicit order requests ##
            foreach $C (qw(N M S)) {
                foreach $O (qw(A D)) {
                    my $test_uri;
                    if ($have_apache_2) {
                        $test_uri = "$uri?C=$C\&O=$O";
                    } else {
                        $test_uri = "$uri?$C=$O";
                    }

                    print "---\n$config_string\n(C=$C O=$O)\n";
                    sok { ai_test($config_string,$C,$O,$test_uri) };

                }
            }
        }
    }
}

sub ai_test ($$$$) {
    my ($htconf,$c,$o,$t_uri) = @_;

    my $html_head;

    if (have_min_apache_version('2.5.1')) {
        $html_head = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">';
    }
    else {
        $html_head = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">';
    }

    $html_head .= <<HEAD;

<html>
 <head>
  <title>Index of $uri_prefix</title>
 </head>
 <body>
<h1>Index of $uri_prefix</h1>
HEAD
    my $html_foot = "${hr}</pre>\n</body></html>\n";

    my $i;
    my $fail = 0;
    my $FancyIndexing = ($htconf =~ /FancyIndex/);

    write_htaccess($htconf);
    my $actual = GET_BODY $t_uri;
    print "GET $t_uri\n";

    ################################
    ##    this may not be ok!     ##
    ##----------------------------##
    ## should you be able to sort ##
    ## by components other than   ##
    ## name when FancyIndexing is ##
    ## not on?                    ##
    ################################
    $c = 'N' unless $FancyIndexing;#
    ################################
    ##   end questionable block   ##
    ################################

    my @file_list;
    if ($o =~ /^A$/i) {
        ## sort ascending ##
        if ($c =~ /^N$/i) {
            ## by name ##
            @file_list = sort keys %file;
        } elsif ($c =~ /^S$/i) {
            ## by size ##
            @file_list =
                sort {$file{$a}{size} <=> $file{$b}{size}} keys %file;
        } elsif ($c =~ /^M$/i) {
            ## by date ##
            @file_list =
                sort {$file{$a}{date} <=> $file{$b}{date}} keys %file;
        } else {
            print "big error: C=$c, O=$o\n";
            return 0;
        }
    } elsif ($o =~ /^D$/i) {
        ## sort decending ##
        if ($c =~ /^N$/i) {
            ## by name ##
            @file_list = reverse sort keys %file;
        } elsif ($c =~ /^S$/i) {
            ## by size ##
            @file_list =
                sort {$file{$b}{size} <=> $file{$a}{size}} keys %file;
        } elsif ($c =~ /^M$/i) {
            ## by date ##
            @file_list =
                sort {$file{$b}{date} <=> $file{$a}{date}} keys %file;
        } else {
            print "big error: C=$c, O=$o\n";
            return 0;
        }
    } else {
        print "big error: C=$c, O=$o\n";
        return 0;
    }

    my $sep = '&amp;';

    if ($have_apache_2 && $actual =~ /\?C=.\;/) {
        ## cope with new 2.1-style headers which use a semi-colon
        ## to separate query segment parameters
        $sep = ';';
    }

    if ($actual =~ /<hr \/>/) {
        ## cope with new-fangled <hr /> tags
        $hr = '<hr />';
    }

    ## set up html for fancy indexing ##
    if ($FancyIndexing) {
        my $name_href;
        my $date_href;
        my $size_href;
        if ($have_apache_2) {
            $name_href = 'C=N'.$sep.'O=A';
            $date_href = 'C=M'.$sep.'O=A';
            $size_href = 'C=S'.$sep.'O=A';
        } else {
            $name_href = 'N=A';
            $date_href = 'M=A';
            $size_href = 'S=A';
        }
        foreach ($name_href, $date_href, $size_href) {
            if ($have_apache_2) {
                if ($_ =~ /^C=$c/i) {
                    #print "changed ->$_<- to ";
                    $_ = "C=$c$sep"."O=A" if $o =~ /^D$/i;
                    $_ = "C=$c$sep"."O=D" if $o =~ /^A$/i;
                    last;
                }
            } else {
                if ($_ =~ /^$c=/i) {
                    $_ = "$c=A" if $o =~ /^D$/i;
                    $_ = "$c=D" if $o =~ /^A$/i;
                    last;
                }
            }
        }

        if ($have_apache_2) {

            $html_head .=
        "<pre>      <a href=\"?$name_href\">Name</a>                    <a href=\"?$date_href\">Last modified</a>      <a href=\"?$size_href\">Size</a>  <a href=\"?C=D$sep"."O=A\">Description</a>${hr}      <a href=\"/modules/autoindex/\">Parent Directory</a>                             -   \n";
 
        $html_foot = "${hr}</pre>\n</body></html>\n";

        } else {

            $html_head .= 
        "<pre><a href=\"?$name_href\">name</a>                    <a href=\"?$date_href\">last modified</a>       <a href=\"?$size_href\">size</a>  <a href=\"?d=a\">description</a>\n<hr>\n<parent>\n";

        $html_foot = "</pre><hr>\n</body></html>\n";

        }

    } else {
        ## html for non fancy indexing ##

        if ($have_apache_2) {

        $html_head .= 
    "<ul><li><a href=\"/modules/autoindex/\"> Parent Directory</a></li>\n";

        $html_foot = "</ul>\n</body></html>\n";

        } else {

        $html_head .= 
    "<ul><li><a href=\"/modules/autoindex/\"> Parent Directory</a>\n";

        $html_foot = "</ul></body></html>\n";

        }
    }

    ## verify html heading ##
    my @exp_head = split /\n/, $html_head;
    my @actual = split /\n/, $actual;
    for ($i=0;$i<@exp_head;$i++) {

        $actual[$i] = lc($actual[$i]);
        $exp_head[$i] = lc($exp_head[$i]);

        if ($actual[$i] eq $exp_head[$i]) {
            next;
        } else {
            if (!$have_apache_2 && $actual[$i] =~ /parent directory/ &&
                $exp_head[$i] eq "<parent>") {
                ## cursory check on this one due to timestamp
                ## in parent directory line in 1.3
                next;
            }

            print "expect:\n->$exp_head[$i]<-\n";
            print "actual:\n->$actual[$i]<-\n";
            $fail = 1;
            last;
        }
    }

    if ($fail) {
        print "failed on html head (C=$c\&O=$o";
        print " FancyIndexing" if $FancyIndexing;
        print ")\n";
        return 0;
    }

    ## file list verification ##
    my $e = 0;
    for ($i=$i;$file_list[$e] && $actual;$i++) {
        my $cmp_string = "<li><a href=\"$file_prefix.$file_list[$e]\"> $file_prefix.$file_list[$e]</a></li>";
        $cmp_string = "<li><a href=\"$file_prefix.$file_list[$e]\"> $file_prefix.$file_list[$e]</a>" unless ($have_apache_2);

        $cmp_string =
    "<a href=\"$file_prefix.$file_list[$e]\">$file_prefix.$file_list[$e]</a>"
        if $FancyIndexing;

        if ($file_list[$e] eq 'README' or
            $file_list[$e] eq '.htaccess') {
            $cmp_string =
                "<a href=\"$file_list[$e]\">$file_list[$e]</a>"
                    if $FancyIndexing;
            $cmp_string =
                "<li><a href=\"$file_list[$e]\"> $file_list[$e]</a>"
                    unless $FancyIndexing;
        }

        $actual[$i] = lc($actual[$i]);
        $cmp_string = lc($cmp_string);

        if ($actual[$i] =~ /$cmp_string/i) {
            $e++;
            next;
        } else {
            print "expect:\n->$cmp_string<-\n";
            print "actual:\n->$actual[$i]<-\n";
            $fail = 1;
            last;
        }
    }

    if ($fail) {
        print "failed on file list (C=$c\&O=$o";
        print " FancyIndexing" if $FancyIndexing;
        print ")\n";
        exit;
        return 0;
    }

    ## the only thing left in @actual should be the foot
    my @foot = split /\n/, $html_foot;
    $e = 0;
    for ($i=$i;$foot[$e];$i++) {
        $actual[$i] = lc($actual[$i]);
        $foot[$e] = lc($foot[$e]);
        if ($actual[$i] ne $foot[$e]) {
            $fail = 1;
            print "expect:\n->$foot[$e]<-\nactual:\n->$actual[$i]<-\n";
            last;
        }
        $e++;
    }

    if ($fail) {
        print "failed on html footer (C=$c\&O=$o";
        print " FancyIndexing" if $FancyIndexing;
        print ")\n";
        return 0;
    }

    ## and at this point there should be no more @actual
    if ($i != @actual) {
        print "thats not all!  there is more than we expected!\n";
        print "i = $i\n";
        print "$actual[$i]\n";
        print "$actual[$i+1]\n";
        return 0;
    }

    return 1;
}


## clean up ##
test_content('destroy');
rmdir $dir or print "warning: cant rmdir $dir: $!\n";
rmdir "$htdocs/$ai_dir";

sub write_htaccess {
    open (HT, ">$htaccess") or die "cant open $htaccess: $!";
    print HT shift;
    close(HT);

    ## add/update .htaccess to the file hash ##
    ($file{'.htaccess'}{date}, $file{'.htaccess'}{size}) =
        (stat($htaccess))[9,7];
}

## manage test content ##
sub test_content {
    my $what = shift || 'create';
    return undef if ($what ne 'create' and $what ne 'destroy');

    foreach (sort keys %file) {
        my $file = "$dir/$_";
        $file = "$dir/$file_prefix.$_" unless ($_ eq 'README'
            or $_ eq '.htaccess');

        if ($what eq 'destroy') {
            unlink $file or print "warning: cant  unlink $file: $!\n";
            next;
        }

        open (FILE, ">$file") or die "cant open $file: $!";
        if ($_ eq 'README') {
            ## README file will contain actual text ##
            print FILE $readme;
        } else {
            ## everything else is just x's ##
            print FILE "x"x$file{$_}{size};
        }
        close(FILE);
    
        if ($file{$_}{date} == 0) {
            $file{$_}{date} = (stat($file))[9];
        } else {
            utime($file{$_}{date}, $file{$_}{date}, $file)
                or die "cant utime $file: $!";
        }
    
    }

}

