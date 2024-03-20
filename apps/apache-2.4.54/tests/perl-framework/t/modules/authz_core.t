use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_write_file);
use File::Spec;

# test RequireAll/RequireAny containers and AuthzMerging

plan tests => 168 + 14*24,
              need need_lwp,
              need_module('mod_authn_core'),
              need_module('mod_authz_core'),
              need_module('mod_authz_host'),
              need_module('mod_authz_groupfile'),
              need_min_apache_version('2.3.6');


my $text = '';

sub check
{
    my $rc = shift;
    my $path = shift;

    my @args;
    foreach my $e (@_) {
        if ($e =~ /user/) {
            push @args, username => $e, password => $e;
        }
        else {
            push @args, "X-Allowed$e" => 'yes';
        }
    }
    my $res = GET "/authz_core/$path", @args;
    my $got = $res->code;
    print "# got $got, expected $rc [$text: $path @_]\n";
    ok($got == $rc);
}

sub write_htaccess
{
    my $path = shift;
    my $merging = shift || "";
    my $container = shift || "";

    $text = "$path $merging $container @_";

    my $need_auth;
    my $content = "";
    $content .= "AuthMerging $merging\n" if $merging;

    if ($container) {
        $content .= "<Require$container>\n";
    }
    foreach (@_) {
        my $req = $_;
        my $not = "";
        if ($req =~ s/^\!//) {
            $not = 'not';
        }
        if ($req =~ /all/) {
            $content .= "Require $not $req\n";
        }
        elsif ($req =~ /user/) {
            # 'group' is correct, see comment about mod_authany below
            $content .= "Require $not group $req\n";
            $need_auth = 1;
        }
        else {
            $content .= "Require $not env allowed$req\n";
        }
    }
    if ($container) {
        $content .= "</Require$container>\n";
    }

    if ($need_auth) {
        $content .= "AuthType basic\n";
        $content .= "AuthName basic1\n";
        $content .= "AuthUserFile basic1\n";
        $content .= "AuthGroupFile groups1\n";
    }

    my $file = File::Spec->catfile(Apache::Test::vars('documentroot'),
        "/authz_core/$path/.htaccess");
    t_write_file($file, $content);
}

# create some users (username == password)
my $basic_file = File::Spec->catfile(Apache::Test::vars('serverroot'), 'basic1');
t_write_file($basic_file, << 'EOF' );
user1:NYSYdf7MU5KpU
user2:KJ7Yxzr1VVzAI
user3:xnpSvZ2iqti/c
EOF

# mod_authany overrides the 'user' provider, so we can't check users directly :-(
# create some groups instead:
my $group_file = File::Spec->catfile(Apache::Test::vars('serverroot'), 'groups1');
t_write_file($group_file, << 'EOF' );
user1:user1
user2:user2
user3:user3
EOF

write_htaccess("a/", undef, undef);
check(200, "a/");
check(200, "a/", 1);
check(200, "a/", 2);
check(200, "a/", 1, 2);
check(200, "a/", 3);

write_htaccess("a/", undef, undef, "user1");
check(401, "a/");
check(200, "a/", "user1");
check(401, "a/", "user2");

write_htaccess("a/", undef, "Any", 1, 2);
check(403, "a/");
check(200, "a/", 1);
check(200, "a/", 2);
check(200, "a/", 1, 2);
check(403, "a/", 3);
  write_htaccess("a/b/", undef, "Any", 2, 3);
  check(403, "a/b/");
  check(403, "a/b/", 1);
  check(200, "a/b/", 2);
  check(200, "a/b/", 3);
  write_htaccess("a/b/", "Off", "Any", 2, 3);
  check(403, "a/b/");
  check(403, "a/b/", 1);
  check(200, "a/b/", 2);
  check(200, "a/b/", 3);
  write_htaccess("a/b/", "Or", "Any", 2, 3);
  check(403, "a/b/");
  check(200, "a/b/", 1);
  check(200, "a/b/", 2);
  check(200, "a/b/", 3);
  write_htaccess("a/b/", "And", "Any", 2, 3);
  check(403, "a/b/");
  check(403, "a/b/", 1);
  check(200, "a/b/", 2);
  check(403, "a/b/", 3);
  check(200, "a/b/", 1, 2);
  check(200, "a/b/", 1, 3);
  check(200, "a/b/", 2, 3);
  write_htaccess("a/b/", undef, "All", 2, 3);
  check(403, "a/b/");
  check(403, "a/b/", 1);
  check(403, "a/b/", 2);
  check(403, "a/b/", 3);
  check(200, "a/b/", 2, 3);
  check(403, "a/b/", 1, 3);
  write_htaccess("a/b/", "Off", "All", 2, 3);
  check(403, "a/b/");
  check(403, "a/b/", 1);
  check(403, "a/b/", 2);
  check(403, "a/b/", 3);
  check(200, "a/b/", 2, 3);
  check(403, "a/b/", 1, 3);
  write_htaccess("a/b/", "Or", "All", 3, 4);
  check(403, "a/b/");
  check(200, "a/b/", 1);
  check(200, "a/b/", 2);
  check(200, "a/b/", 2, 3);
  check(200, "a/b/", 3, 4);
  check(403, "a/b/", 3);
  check(403, "a/b/", 4);
  write_htaccess("a/b/", "And", "All", 2, 3);
  check(403, "a/b/");
  check(403, "a/b/", 1);
  check(403, "a/b/", 2);
  check(403, "a/b/", 3);
  check(403, "a/b/", 1, 2);
  check(403, "a/b/", 1, 3);
  check(200, "a/b/", 2, 3);


write_htaccess("a/", undef, "All", 1, "!2");
check(403, "a/");
check(200, "a/", 1);
check(403, "a/", 2);
check(403, "a/", 1, 2);
check(403, "a/", 3);
  write_htaccess("a/b/", undef, "Any", 2, 3);
  check(403, "a/b/");
  check(403, "a/b/", 1);
  check(200, "a/b/", 2);
  check(200, "a/b/", 3);
  write_htaccess("a/b/", "Off", "Any", 2, 3);
  check(403, "a/b/");
  check(403, "a/b/", 1);
  check(200, "a/b/", 2);
  check(200, "a/b/", 3);
  write_htaccess("a/b/", "Or", "Any", 3, 4);
  check(403, "a/b/");
  check(200, "a/b/", 1);
  check(403, "a/b/", 1, 2);
  check(200, "a/b/", 1, 2, 3);
  check(200, "a/b/", 1, 2, 4);
  check(200, "a/b/", 4);
  write_htaccess("a/b/", "And", "Any", 2, 3);
  check(403, "a/b/");
  check(403, "a/b/", 1);
  check(403, "a/b/", 2);
  check(403, "a/b/", 3);
  check(403, "a/b/", 1, 2);
  check(200, "a/b/", 1, 3);
  check(403, "a/b/", 2, 3);
    # should not inherit AuthMerging And from a/b/
    write_htaccess("a/b/c/", undef, "Any", 4);
    check(403, "a/b/c/", 1, 3);
    check(200, "a/b/c/", 4);
    check(200, "a/b/c/", 1, 2, 4);
  write_htaccess("a/b/", undef, "All", 2, 3);
  check(403, "a/b/");
  check(403, "a/b/", 1);
  check(403, "a/b/", 2);
  check(403, "a/b/", 3);
  check(200, "a/b/", 2, 3);
  check(403, "a/b/", 1, 3);
  write_htaccess("a/b/", "Off", "All", 2, 3);
  check(403, "a/b/");
  check(403, "a/b/", 1);
  check(403, "a/b/", 2);
  check(403, "a/b/", 3);
  check(200, "a/b/", 2, 3);
  check(403, "a/b/", 1, 3);
  write_htaccess("a/b/", "Or", "All", 3, 4);
  check(403, "a/b/");
  check(200, "a/b/", 1);
  check(403, "a/b/", 2);
  check(403, "a/b/", 2, 3);
  check(200, "a/b/", 3, 4);
  check(403, "a/b/", 3);
  check(403, "a/b/", 4);
  write_htaccess("a/b/", "And", "All", 2, 3);
  check(403, "a/b/");
  check(403, "a/b/", 1);
  check(403, "a/b/", 2);
  check(403, "a/b/", 3);
  check(403, "a/b/", 1, 2);
  check(403, "a/b/", 1, 3);
  check(403, "a/b/", 2, 3);


write_htaccess("a/", undef, "All", 1, 2);
check(403, "a/");
check(403, "a/", 1);
check(403, "a/", 2);
check(200, "a/", 1, 2);
  write_htaccess("a/b/", undef, "Any", 2, 3);
  check(403, "a/b/");
  check(403, "a/b/", 1);
  check(200, "a/b/", 2);
  check(200, "a/b/", 3);
  write_htaccess("a/b/", "Off", "Any", 2, 3);
  check(403, "a/b/");
  check(403, "a/b/", 1);
  check(200, "a/b/", 2);
  check(200, "a/b/", 3);
  write_htaccess("a/b/", "Or", "Any", 3, 4);
  check(403, "a/b/");
  check(403, "a/b/", 1);
  check(403, "a/b/", 2);
  check(200, "a/b/", 1, 2);
  check(200, "a/b/", 3);
  check(200, "a/b/", 4);
  write_htaccess("a/b/", "And", "Any", 3, 4);
  check(403, "a/b/");
  check(403, "a/b/", 1);
  check(403, "a/b/", 2);
  check(403, "a/b/", 3);
  check(403, "a/b/", 4);
  check(403, "a/b/", 1, 2);
  check(200, "a/b/", 1, 2, 3);
  check(200, "a/b/", 1, 2, 4);
  check(403, "a/b/", 1, 3, 4);
  write_htaccess("a/b/", undef, "All", 2, 3);
  check(403, "a/b/");
  check(403, "a/b/", 1);
  check(403, "a/b/", 2);
  check(403, "a/b/", 3);
  check(200, "a/b/", 2, 3);
  check(403, "a/b/", 1, 3);
  write_htaccess("a/b/", "Off", "All", 2, 3);
  check(403, "a/b/");
  check(403, "a/b/", 1);
  check(403, "a/b/", 2);
  check(403, "a/b/", 3);
  check(200, "a/b/", 2, 3);
  check(403, "a/b/", 1, 3);
  write_htaccess("a/b/", "Or", "All", 3, 4);
  check(403, "a/b/");
  check(403, "a/b/", 1);
  check(403, "a/b/", 2);
  check(403, "a/b/", 3);
  check(403, "a/b/", 4);
  check(403, "a/b/", 2, 3);
  check(200, "a/b/", 3, 4);
  check(200, "a/b/", 1, 2);
  write_htaccess("a/b/", "And", "All", 2, 3);
  check(403, "a/b/");
  check(403, "a/b/", 1);
  check(403, "a/b/", 2);
  check(403, "a/b/", 3);
  check(403, "a/b/", 1, 2);
  check(403, "a/b/", 1, 3);
  check(403, "a/b/", 2, 3);
  check(200, "a/b/", 1, 2, 3);

#
# To test merging of a mix of user and non-user authz providers,
# we should test all orders.
#

# helper function to get all permutations of an array
# returns array of references
sub permutations
{
    my @results = [shift];

    foreach my $el (@_) {
        my @new_results;
        foreach my $arr (@results) {
            my $len = scalar(@{$arr});
            foreach my $i (0 .. $len) {
                my @new = @{$arr};
                splice @new, $i, 0, $el;
                push @new_results, \@new;
            }
        }
        @results = @new_results;
    }
    return @results;
}


my @perms = permutations(qw/user1 user2 1 2/);
foreach my $p (@perms) {
	write_htaccess("a/", undef, "All", @{$p});
	check(403, "a/");
	check(403, "a/", 1);
	check(403, "a/", "user1");
	check(401, "a/", 1, 2);
	check(401, "a/", 1, 2, "user1");
	check(401, "a/", 1, 2, "user3");
	check(403, "a/", 1, "user1");

	write_htaccess("a/", undef, "Any", @{$p});
	check(401, "a/");
	check(200, "a/", 1);
	check(200, "a/", "user1");
	check(401, "a/", "user3");
	check(200, "a/", 1, 2);
	check(200, "a/", 1, "user1");
	check(200, "a/", 1, "user3");
}
