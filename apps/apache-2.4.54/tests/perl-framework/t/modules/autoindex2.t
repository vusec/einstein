use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use File::Spec::Functions qw(catfile catdir);

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

##
## mod_autoindex test part II
##
## this tests how mod_autoindex handles sub-dirs:
## normal, with protected access, with broken .htaccess, etc...

#my $cfg = Apache::Test::config();
my $vars = Apache::Test::config()->{vars};
my $documentroot = $vars->{documentroot};
my $base_dir = catdir $documentroot, "modules", "autoindex2";
my $base_uri = "/modules/autoindex2";
my $have_apache_2 = have_apache 2;

# which sub-dir listings should be seen in mod_autoindex's output
# 1 == should appear
# 0 == should not appear
my %dirs = (
   dir_normal    => 1, # obvious
   dir_protected => $have_apache_2?0:1, # 
   dir_broken    => $have_apache_2?0:1, # 
);

plan tests => 3, ['autoindex'];

setup();

my $res = GET_BODY "$base_uri/";

# simply test whether we get the sub-dir listed or not
for my $dir (sort keys %dirs) {
    my $found = $res =~ /$dir/ ? 1 : 0;
    ok t_cmp($found,
             $dirs{$dir}, 
             "$dir should @{[$dirs{$dir}?'':'not ']}be listed");
}

sub setup {
    t_mkdir $base_dir;

    ### normal dir
    t_mkdir catdir $base_dir, "dir_normal";

    ### passwd protected dir
    my $prot_dir = catdir $base_dir, "dir_protected";
    # htpasswd file
    t_write_file catfile($prot_dir, "htpasswd"), "nobody:HIoD8SxAgkCdQ";
    # .htaccess file
    my $content = <<CONTENT;
AuthType Basic
AuthName "Restricted Directory"
AuthUserFile $prot_dir/htpasswd
Require valid user
CONTENT
    t_write_file catfile($prot_dir, ".htaccess"), $content;

    ### dir with a broken .htaccess
    my $broken_dir = catdir $base_dir, "dir_broken";
    t_write_file catfile($broken_dir, ".htaccess"),
                "This_is_a_broken_on_purpose_.htaccess_file";

}
