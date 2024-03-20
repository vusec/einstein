use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

##
## mod_access test
##

my $vars = Apache::Test::vars();
my $localhost_name = $vars->{servername};
my $remote_addr = $vars->{remote_addr};
my(@addr) = split /\./, $remote_addr;
my $addr1 = $addr[0];
my $addr2 = join '.', $addr[0], $addr[1];

my @localhost = (
    'from all',
    "from $localhost_name",
    "from $remote_addr",
    "from $addr2",
    "from $remote_addr/255.255.0.0",
    "from $remote_addr/16",
    'from somewhere.else.com',
    'from 66.6.6.6'
);
my @order = ('deny,allow', 'allow,deny', 'mutual-failure');
my @allow = @localhost;
my @deny = @localhost;

plan tests => (@order * @allow * @deny * 2) + (@order * @allow), \&need_access;

my $dir = $vars->{t_dir};
$dir .=  "/htdocs/modules/access/htaccess";

sub write_htaccess {
    my $conf_str = shift;
    open (HT, ">$dir/.htaccess") or die "cant open htaccess: $!";
    print HT $conf_str;
    close (HT);
}

my ($config_string, $ok);
foreach my $order (@order) {
    foreach my $allow (@allow) {
        $config_string = "Order $order\nAllow $allow\n";
        write_htaccess($config_string);

        t_debug "---", $config_string;

        if ($order eq 'deny,allow') {

            ## if allowing by default,
            ## there is no 'Deny' directive, so everything
            ## is allowed.
            t_debug "expecting access.";
            ok GET_OK "/modules/access/htaccess/index.html";
            

        } else {

            ## denying by default

            if ($allow =~ /^from $addr1/
                || $allow eq "from $localhost_name"
                || $allow eq 'from all') {

                ## if we are explicitly allowed, its ok
                t_debug "expecting access.";
                ok GET_OK "/modules/access/htaccess/index.html";

            } else {

                ## otherwise, not ok
                t_debug "expecting access denial.";
                ok !GET_OK "/modules/access/htaccess/index.html";
            }
        }
            

        foreach my $deny (@deny) {
            $config_string = "Order $order\nDeny $deny\n";
            write_htaccess($config_string);

            t_debug "---", $config_string;

            if ($order eq 'deny,allow') {

                ## allowing by default

                if ($deny =~ /^from $addr1/
                    || $deny eq "from $localhost_name"
                    || $deny eq 'from all') {

                    ## if we are denied explicitly
                    ## its not ok
                    t_debug "expecting access denial.";
                    ok !GET_OK "/modules/access/htaccess/index.html";

                } else {

                    ## otherwise, ok
                    t_debug "expecting access.";
                    ok GET_OK "/modules/access/htaccess/index.html";

                }
            } else {

                ## if denying by default
                ## there is no 'Allow' directive, so
                ## everything is denied.
                t_debug "expecting access denial.";
                ok !GET_OK "/modules/access/htaccess/index.html";

            }

            $config_string = "Order $order\nAllow $allow\nDeny $deny\n";
            write_htaccess($config_string);

            t_debug "---", $config_string;

            if ($order eq 'deny,allow') {

                ## allowing by default

                if ($allow =~ /^from $addr1/
                    || $allow eq "from $localhost_name"
                    || $allow eq 'from all') {

                    ## we are explicitly allowed
                    ## so it is ok.
                    t_debug "expecting access.";
                    ok GET_OK "/modules/access/htaccess/index.html";

                } elsif ($deny =~ /^from $addr1/
                    || $deny eq "from $localhost_name"
                    || $deny eq 'from all') {

                    ## if we are not explicitly allowed
                    ## and are explicitly denied,
                    ## we are denied access.
                    t_debug "expecting access denial.";
                    ok !GET_OK "/modules/access/htaccess/index.html";

                } else {

                    ## if we are not explicity allowed
                    ## or explicitly denied,
                    ## we get access.
                    t_debug "expecting access.";
                    ok GET_OK "/modules/access/htaccess/index.html";

                }
            } else {

                ## denying by default

                if ($deny =~ /^from $addr1/
                    || $deny eq "from $localhost_name"
                    || $deny eq 'from all') {

                    ## if we are explicitly denied,
                    ## we get no access.
                    t_debug "expecting access denial.";
                    ok !GET_OK "/modules/access/htaccess/index.html";

                } elsif ($allow =~ /^from $addr1/
                    || $allow eq "from $localhost_name"
                    || $allow eq 'from all') {

                    ## if we are not explicitly denied
                    ## and are explicitly allowed,
                    ## we get access.
                    t_debug "expecting access.";
                    ok GET_OK "/modules/access/htaccess/index.html";

                } else {

                    ## if we are not explicitly denied
                    ## and not explicitly allowed,
                    ## we get no access.
                    t_debug "expecting access denial.";
                    ok !GET_OK "/modules/access/htaccess/index.html";

                }
            }
        }
    }
}
