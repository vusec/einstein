use strict;

print "Content-Type: text/plain\n\n";
print $ENV{NextAvailablePort} || '';
