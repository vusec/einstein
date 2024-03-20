use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
#
# Test the FileETag directive.
#
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

t_debug "Checking for existence of FileETag directive\n";
my $resp = GET('/apache/etags/test.txt');
my $rc = $resp->code;
t_debug "Returned $rc:";
if ($rc == 500) {
    t_debug "Feature not supported, skipping..",
        " Message was:", $resp->as_string;
    if (defined($resp->content)) {
        t_debug $resp->content;
    }
    plan tests => 1..0;
    exit;
}

#
# The tests verify the inclusion of the different fields, and
# inheritance, according to the directories involved.  All are
# subdirectories under /apache/etags/.  The key is the path, the value
# is the pattern the ETag response header field needs to match,
# and the comment is the keywords on the FileETag directive in
# the directory's .htaccess file.  A pattern of "" means the header
# field is expected to be absent.
#
# The things we want to test are:
#
# 1. That the 'All' and 'None' keywords work.
# 2. That the 'MTime', 'INode', and 'Size' keywords work,
#    alone and in combination.
# 3. That '+MTime', '+INode', and '+Size' work, alone and
#    in combination.
# 4. That '-MTime', '-INode', and '-Size' work, alone and
#    in combination.
# 5. That relative keywords work in combination with non-relative
#    ones.
# 6. That inheritance works properly.
#
my $x = '[0-9a-fA-F]+';
my $tokens_1 = "^\"$x\"\$";
my $tokens_2 = "^\"$x-$x\"\$";
my $tokens_3 = "^\"$x-$x-$x\"\$";
my %expect = ($tokens_1 => "one component in ETag field",
              $tokens_2 => "two components in ETag field",
              $tokens_3 => "three components in ETag field",
              ""        => "field to be absent"
              );
my $tokens_default = have_min_apache_version("2.3.15") ? $tokens_2 : $tokens_3;
my %tests = (
             '/default/'                 => $tokens_default,
             #
             # First, the absolute settings in various combinations,
             # disregarding inheritance.
             #
             '/m/'                       => $tokens_1, # MTime
             '/i/'                       => $tokens_1, # INode
             '/s/'                       => $tokens_1, # Size
             '/mi/'                      => $tokens_2, # MTime INode
             '/ms/'                      => $tokens_2, # MTime Size
             '/is/'                      => $tokens_2, # INode Size
             '/mis/'                     => $tokens_3, # MTime INode Size
             '/all/'                     => $tokens_3, # All
             '/none/'                    => "",        # None
             '/all/m/'                   => $tokens_1, # MTime
             '/all/i/'                   => $tokens_1, # INode
             '/all/s/'                   => $tokens_1, # Size
             '/all/mi/'                  => $tokens_2, # MTime INode
             '/all/ms/'                  => $tokens_2, # MTime Size
             '/all/is/'                  => $tokens_2, # INode Size
             '/all/mis/'                 => $tokens_3, # MTime INode Size
             '/all/inherit/'             => $tokens_3, # no directive
             '/none/m/'                  => $tokens_1, # MTime
             '/none/i/'                  => $tokens_1, # INode
             '/none/s/'                  => $tokens_1, # Size
             '/none/mi/'                 => $tokens_2, # MTime INode
             '/none/ms/'                 => $tokens_2, # MTime Size
             '/none/is/'                 => $tokens_2, # INode Size
             '/none/mis/'                => $tokens_3, # MTime INode Size
             '/none/inherit/'            => "",        # no directive
             #
             # Now for the relative keywords.  First, subtract fields
             # in a place where they all should have been inherited.
             #
             '/all/minus-m/'             => $tokens_2, # -MTime
             '/all/minus-i/'             => $tokens_2, # -INode
             '/all/minus-s/'             => $tokens_2, # -Size
             '/all/minus-mi/'            => $tokens_1, # -MTime -INode
             '/all/minus-ms/'            => $tokens_1, # -MTime -Size
             '/all/minus-is/'            => $tokens_1, # -INode -Size
             '/all/minus-mis/'           => "",        # -MTime -INode -Size
             #
             # Now add them in a location where they should all be absent.
             #
             '/none/plus-m/'             => $tokens_1, # +MTime
             '/none/plus-i/'             => $tokens_1, # +INode
             '/none/plus-s/'             => $tokens_1, # +Size
             '/none/plus-mi/'            => $tokens_2, # +MTime +INode
             '/none/plus-ms/'            => $tokens_2, # +MTime +Size
             '/none/plus-is/'            => $tokens_2, # +INode +Size
             '/none/plus-mis/'           => $tokens_3, # +MTime +INode +Size
             #
             # Try subtracting them below where they were added.
             #
             '/none/plus-mis/minus-m/'   => $tokens_2, # -MTime
             '/none/plus-mis/minus-i/'   => $tokens_2, # -INode
             '/none/plus-mis/minus-s/'   => $tokens_2, # -Size
             '/none/plus-mis/minus-mi/'  => $tokens_1, # -MTime -INode
             '/none/plus-mis/minus-ms/'  => $tokens_1, # -MTime -Size
             '/none/plus-mis/minus-is/'  => $tokens_1, # -INode -Size
             '/none/plus-mis/minus-mis/' => "",        # -MTime -INode -Size
             #
             # Now relative settings under a non-All non-None absolute
             # setting location.
             #
             '/m/plus-m/'                => $tokens_1, # +MTime
             '/m/plus-i/'                => $tokens_2, # +INode
             '/m/plus-s/'                => $tokens_2, # +Size
             '/m/plus-mi/'               => $tokens_2, # +MTime +INode
             '/m/plus-ms/'               => $tokens_2, # +MTime +Size
             '/m/plus-is/'               => $tokens_3, # +INode +Size
             '/m/plus-mis/'              => $tokens_3, # +MTime +INode +Size
             '/m/minus-m/'               => "",        # -MTime
             '/m/minus-i/'               => "",        # -INode
             '/m/minus-s/'               => "",        # -Size
             '/m/minus-mi/'              => "",        # -MTime -INode
             '/m/minus-ms/'              => "",        # -MTime -Size
             '/m/minus-is/'              => "",        # -INode -Size
             '/m/minus-mis/'             => ""         # -MTime -INode -Size
             );

my $testcount = scalar(keys(%tests));
plan tests => $testcount;

for my $key (keys(%tests)) {
    my $uri = "/apache/etags" . $key . "test.txt";
    my $pattern = $tests{$key};
    t_debug "---", "HEAD $uri",
        "Expecting " . $expect{$pattern};
    $resp = HEAD($uri);
    my $etag = $resp->header("ETag");
    if (defined($etag)) {
        t_debug "Received $etag";
        ok ($etag =~ /$pattern/);
    }
    else {
        t_debug "ETag field is missing";
        if ($tests{$key} eq "") {
            ok 1;
        }
        else {
            t_debug "ETag field was expected";
            ok 0;
        }
    }
}

#
# Local Variables:
# mode: perl
# indent-tabs-mode: nil
# End:
#
