use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my $htdocs     = Apache::Test::vars('documentroot');
my $url        = '/index.html';
my $cgi_name   = "test-cgi";
my $cgi_string = "test cgi for";
my $root       = "$htdocs/modules/vhost_alias";
my $ext;

my @vh = qw(www.vha-test.com big.server.name.from.heck.org ab.com w-t-f.net);

plan tests => @vh * 2, need need_module('vhost_alias'), need_cgi, need_lwp;

Apache::TestRequest::scheme('http'); #ssl not listening on this vhost
Apache::TestRequest::module('mod_vhost_alias'); #use this module's port

## test environment setup ##
t_mkdir($root);

foreach (@vh) {
    my @part = split /\./, $_;
    my $d = "$root/";

    ## create VirtualDocumentRoot htdocs/modules/vhost_alias/%2/%1.4/%-2/%2+
    ## %2 ##
    if ($part[1]) {
        $d .= $part[1];
    } else {
        $d .= "_";
    }
    t_mkdir($d);

    $d .= "/";
    ## %1.4 ##
    if (length($part[0]) < 4) {
        $d .= "_";
    } else {
        $d .= substr($part[0], 3, 1);
    }
    t_mkdir($d);

    $d .= "/";
    ## %-2 ##
    if ($part[@part-2]) {
        $d .= $part[@part-2];
    } else {
        $d .= "_";
    }
    t_mkdir($d);

    $d .= "/";
    ## %2+ ##
    for (my $i = 1;$i < @part;$i++) {
        $d .= $part[$i];
        $d .= "." if $part[$i+1];
    }
    t_mkdir($d);

    ## write index.html for the VirtualDocumentRoot ##
    t_write_file("$d$url",$_);

    ## create directories for VirtualScriptAlias tests ##
    $d = "$root/$_";
    t_mkdir($d);
    $d .= "/";

    ## write cgi ##
    my $cgi_content = <<SCRIPT;
echo Content-type: text/html
echo
echo $cgi_string $_
SCRIPT

    $ext = Apache::TestUtil::t_write_shell_script("$d$cgi_name", $cgi_content);
    chmod 0755, "$d$cgi_name.$ext";
}

## run tests ##
foreach (@vh) {
    ## test VirtalDocumentRoot ##
    ok t_cmp(GET_BODY($url, Host => $_),
             $_,
             "VirtalDocumentRoot test"
            );

    ## test VirtualScriptAlias ##
    my $cgi_uri = "/cgi-bin/$cgi_name.$ext";
    my $actual  = GET_BODY $cgi_uri, Host => $_;
    $actual =~ s/[\r\n]+$//;
    ok t_cmp($actual,
             "$cgi_string $_",
             "VirtualScriptAlias test"
            );
}


