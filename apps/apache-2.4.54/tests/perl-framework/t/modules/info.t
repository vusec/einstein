use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

##
## mod_info quick test
##

plan tests => 1, need_module 'info';

my $uri = '/server-info';
my $info = GET_BODY $uri;
my $config = Apache::Test::config();
my $mods = $config->{modules};
my (@actual,@expected) = ((),());

## extract module names from html ##
foreach (split /\n/, $info) {
    if ($_ =~ /<a name=\"(\w+\.c)\">/) {
        if ($1 eq 'util_ldap.c') {
            push(@actual,'mod_ldap.c');
        } elsif ($1 eq 'mod_apreq2.c') {
            push(@actual,'mod_apreq.c');
        } else {
            push(@actual, $1);
        }
    }
}

foreach (sort keys %$mods) {
    ($mods->{$_} && !$config->should_skip_module($_)) or next;
    if ($_ =~ /^mod_mpm_(eventopt|event|motorz|prefork|worker)\.c$/) {
        push(@expected,"$1.c");
    } elsif ($_ eq 'mod_mpm_simple.c') {
        push(@expected,'simple_api.c');
    # statically linked mod_ldap
    } elsif ($_ eq 'util_ldap.c') {
        push(@expected,'mod_ldap.c');
    # statically linked mod_apreq2
    } elsif ($_ eq 'mod_apreq2.c') {
        push(@expected,'mod_apreq.c');
    } else {
        push(@expected,$_);
    }
}
@actual = sort @actual;
@expected = sort @expected;

## verify all mods are there ##
my $ok = 1;
if (@actual == @expected) {
    for (my $i=1 ; $i<@expected ; $i++) {
        if ($expected[$i] ne $actual[$i]) {
            $ok = 0;
            print "comparing expected ->$expected[$i]<-\n";
            print "to actual ->$actual[$i]<-\n";
            print "actual:\n@actual\nexpect:\n@expected\n";
            last;
        }
    }
} else {
    $ok = 0;
    my $a = @actual; my $e = @expected;
    print "actual($a modules):\n@actual\nexpect($e modules):\n@expected\n";
}

ok $ok;
