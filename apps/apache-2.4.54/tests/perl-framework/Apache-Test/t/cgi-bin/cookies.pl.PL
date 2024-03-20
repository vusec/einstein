#!perl -wT

use strict;

use CGI;
use CGI::Cookie;

my %cookies = CGI::Cookie->fetch;
my $name = 'ApacheTest';
my $c = ! exists $cookies{$name}
    ? CGI::Cookie->new(-name=>$name, -value=>time)
    : '';

print "Set-Cookie: $c\n" if $c;
print "Content-Type: text/plain\n\n";
print ($c ? 'new' : 'exists'), "\n";
