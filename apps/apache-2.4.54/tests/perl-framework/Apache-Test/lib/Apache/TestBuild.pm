# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
package Apache::TestBuild;

use strict;
use warnings FATAL => 'all';

use subs qw(system chdir
            info warning);

use Config;
use File::Spec::Functions;
use File::Path ();
use Cwd ();

use constant DRYRUN => 0;

my @min_modules = qw(access auth log-config env mime setenvif
                     mime autoindex dir alias);

my %shared_modules = (
    min  => join(' ', @min_modules),
);

my %configs = (
    all => {
        'apache-1.3' => [],
        'httpd-2.0' => enable20(qw(modules=all proxy)),
    },
    most => {
        'apache-1.3' => [],
        'httpd-2.0' => enable20(qw(modules=most)),
    },
    min => {
        'apache-1.3' => [],
        'httpd-2.0' => enable20(@min_modules),
    },
    exp => {
        'apache-1.3' => [],
        'httpd-2.0' => enable20(qw(example case_filter
                                   case_filter_in cache
                                   echo deflate bucketeer)),
    },
);

my %builds = (
     default => {
         cflags => '-Wall',
         config => {
             'apache-1.3' => [],
             'httpd-2.0'  => [],
         },
     },
     debug => {
         cflags => '-g',
         config => {
             'apache-1.3' => [],
             'httpd-2.0'  => [qw(--enable-maintainer-mode)],
         },
     },
     prof => {
         cflags => '-pg -DGPROF',
     },
     shared => {
         config =>  {
             'apache-1.3' => [],
             'httpd-2.0'  => enable20_shared('all'),
         },
     },
     mostshared => {
         config =>  {
             'apache-1.3' => [],
             'httpd-2.0'  => enable20_shared('most'),
         },
     },
     minshared => {
         config =>  {
             'apache-1.3' => [],
             'httpd-2.0'  => enable20_shared('min'),
         },
     },
     static => {
     },
);

my %mpms = (
    default => [qw(prefork worker)],
    MSWin32 => [qw(winnt)],
);

my @cvs = qw(httpd-2.0 apache-1.3);

my @dirs = qw(build tar src install);

sub enable20 {
    [ map { "--enable-$_" } @_ ];
}

sub enable20_shared {
    my $name = shift;
    my $modules = $shared_modules{$name} || $name;
    enable20(qq(mods-shared="$modules"));
}

sub default_mpms {
    $mpms{ $^O } || $mpms{'default'};
}

sub default_dir {
    my($self, $dir) = @_;
    $self->{$dir} ||= catdir $self->{prefix}, $dir,
}

sub new {
    my $class = shift;

    #XXX: not generating a BUILD script yet
    #this way we can run:
    #perl Apache-Test/lib/Apache/TestBuild.pm --cvsroot=anon --foo=...

    require Apache::TestConfig;
    require Apache::TestTrace;
    Apache::TestTrace->import;

    my $self = bless {
        prefix => '/usr/local/apache',
        cwd => Cwd::cwd(),
        cvsroot => 'cvs.apache.org:/home/cvs',
        cvs => \@cvs,
        cvstag => "",
        ssldir => "",
        mpms => default_mpms(),
        make => $Config{make},
        builds => {},
        name => "",
        extra_config => {
            'httpd-2.0' => [],
        },
        @_,
    }, $class;

    #XXX
    if (my $c = $self->{extra_config}->{'2.0'}) {
        $self->{extra_config}->{'httpd-2.0'} = $c;
    }

    for my $dir (@dirs) {
        $self->default_dir($dir);
    }

    if ($self->{ssldir}) {
        push @{ $self->{extra_config}->{'httpd-2.0'} },
          '--enable-ssl', "--with-ssl=$self->{ssldir}";
    }

    $self;
}

sub init {
    my $self = shift;

    for my $dir (@dirs) {
        mkpath($self->{$dir});
    }
}

use subs qw(symlink unlink);
use File::Basename;
use File::Find;

sub symlink_tree {
    my $self = shift;

    my $httpd = 'httpd';
    my $install = "$self->{install}/bin/$httpd";
    my $source  = "$self->{build}/.libs/$httpd";

    unlink $install;
    symlink $source, $install;

    my %dir = (apr => 'apr',
               aprutil => 'apr-util');

    for my $libname (qw(apr aprutil)) {
        my $lib = "lib$libname.so.0.0.0";
        my $install = "$self->{install}/lib/$lib";
        my $source  = "$self->{build}/srclib/$dir{$libname}/.libs/$lib";

        unlink $install;
        symlink $source, $install;
    }

    $install = "$self->{install}/modules";
    $source  = "$self->{build}/modules";

    for (<$install/*.so>) {
        unlink $_;
    }

    finddepth(sub {
        return unless /\.so$/;
        my $file = "$File::Find::dir/$_";
        symlink $file, "$install/$_";
    }, $source);
}

sub unlink {
    my $file = shift;

    if (-e $file) {
        print "unlink $file\n";
    }
    else {
        print "$file does not exist\n";
    }
    CORE::unlink($file);
}

sub symlink {
    my($from, $to) = @_;
    print "symlink $from => $to\n";
    unless (-e $from) {
        print "source $from does not exist\n";
    }
    my $base = dirname $to;
    unless (-e $base) {
        print "target dir $base does not exist\n";
    }
    CORE::symlink($from, $to) or die $!;
}

sub cvs {
    my $self = shift;

    my $cmd = "cvs -d $self->{cvsroot} @_";

    if (DRYRUN) {
        info "$cmd";
    }
    else {
        system $cmd;
    }
}

my %cvs_names = (
    '2.0' => 'httpd-2.0',
    '1.3' => 'apache-1.3',
);

my %cvs_snames = (
    '2.0' => 'httpd',
    '1.3' => 'apache',
);

sub cvs_up {
    my($self, $version) = @_;

    my $name = $cvs_names{$version};

    my $dir = $self->srcdir($version);

    if ($self->{cvsroot} eq 'anon') {
        $self->{cvsroot} = ':pserver:anoncvs@cvs.apache.org:/home/cvspublic';
        unless (-d $dir) {
            #XXX do something better than doesn't require prompt if
            #we already have an entry in ~/.cvspass
            #$self->cvs('login');

            warning "may need to run the following command ",
                    "(password is 'anoncvs')";
            warning "cvs -d $self->{cvsroot} login";
        }
    }

    if (-d $dir) {
        chdir $dir;
        $self->cvs(up => "-dP $self->{cvstag}");
        return;
    }

    my $co = checkout($name);
    $self->$co($name, $dir);

    my $post = post_checkout($name);
    $self->$post($name, $dir);
}

sub checkout_httpd_2_0 {
    my($self, $name, $dir) = @_;

    my $tag = $self->{cvstag};

    $self->cvs(co => "-d $dir $tag $name");
    chdir "$dir/srclib";
    $self->cvs(co => "$tag apr apr-util");
}

sub checkout_apache_1_3 {
    my($self, $name, $dir) = @_;

    $self->cvs(co => "-d $dir $self->{cvstag} $name");
}

sub post_checkout_httpd_2_0 {
    my($self, $name, $dir) = @_;
}

sub post_checkout_apache_1_3 {
}

sub canon {
    my $name = shift;
    return $name unless $name;
    $name =~ s/[.-]/_/g;
    $name;
}

sub checkout {
    my $name = canon(shift);
    \&{"checkout_$name"};
}

sub post_checkout {
    my $name = canon(shift);
    \&{"post_checkout_$name"};
}

sub cvs_update {
    my $self = shift;

    my $cvs = shift || $self->{cvs};

    chdir $self->{src};

    for my $name (@$cvs) {
        $self->cvs_up($name);
    }
}

sub merge_build {
    my($self, $version, $builds, $configs) = @_;

    my $b = {
        cflags => $builds{default}->{cflags},
        config => [ @{ $builds{default}->{config}->{$version} } ],
    };

    for my $name (@$builds) {
        next if $name eq 'default'; #already have this

        if (my $flags = $builds{$name}->{cflags}) {
            $b->{cflags} .= " $flags";
        }
        if (my $cfg = $builds{$name}->{config}) {
            if (my $vcfg = $cfg->{$version}) {
                push @{ $b->{config} }, @$vcfg;
            }
        }
    }

    for my $name (@$configs) {
        my $cfg = $configs{$name}->{$version};
        next unless $cfg;
        push @{ $b->{config} }, @$cfg;
    }

    if (my $ex = $self->{extra_config}->{$version}) {
        push @{ $b->{config} }, @$ex;
    }

    if (my $ex = $self->{extra_cflags}->{$version}) {
        $b->{config} .= " $ex";
    }

    $b;
}

my @srclib_dirs = qw(
    apr apr-util apr-util/xml/expat pcre
);

sub install_name {
    my($self, $builds, $configs, $mpm) = @_;

    return $self->{name} if $self->{name};

    my $name = join '-', $mpm, @$builds, @$configs;

    if (my $tag = $self->cvs_name) {
        $name .= "-$tag";
    }

    $name;
}

#currently the httpd-2.0 build does not properly support static linking
#of ssl libs, force the issue
sub add_ssl_libs {
    my $self = shift;

    my $ssldir = $self->{ssldir};

    return unless $ssldir and -d $ssldir;

    my $name = $self->{current_install_name};

    my $ssl_mod = "$name/modules/ssl";
    info "editing $ssl_mod/modules.mk";

    if (DRYRUN) {
        return;
    }

    my $ssl_mk = "$self->{build}/$ssl_mod/modules.mk";

    open my $fh, $ssl_mk or die "open $ssl_mk: $!";
    my @lines = <$fh>;
    close $fh;

    for (@lines) {
        next unless /SH_LINK/;
        chomp;
        $_ .= " -L$ssldir -lssl -lcrypto\n";
        info 'added ssl libs';
        last;
    }

    open $fh, '>', $ssl_mk or die $!;
    print $fh join "\n", @lines;
    close $fh;
}

sub cvs_name {
    my $self = shift;

    if (my $tag = $self->{cvstag}) {
        $tag =~ s/^-[DAr]//;
        $tag =~ s/\"//g;
        $tag =~ s,[/ :],_,g; #-D"03/29/02 07:00pm"
        return $tag;
    }

    return "";
}

sub srcdir {
    my($self, $src) = @_;

    my $prefix = "";
    if ($src =~ s/^(apache|httpd)-//) {
        $prefix = $1;
    }
    else {
        $prefix = $cvs_snames{$src};
    }

    if ($src =~ /^\d\.\d$/) {
        #release version will be \d\.\d\.\d+
        if (my $tag = $self->cvs_name) {
            $src .= "-$tag";
        }
        $src .= '-cvs';
    }

    join '-', $prefix, $src;
}

sub configure_httpd_2_0 {
    my($self, $src, $builds, $configs, $mpm) = @_;

    $src = $self->srcdir($src);

    chdir $self->{build};

    my $name = $self->install_name($builds, $configs, $mpm);

    $self->{current_install_name} = $name;

    $self->{builds}->{$name} = 1;

    if ($self->{fresh}) {
        rmtree($name);
    }
    else {
        if (-e "$name/.DONE") {
            warning "$name already configured";
            warning "rm $name/.DONE to force";
            return;
        }
    }

    my $build = $self->merge_build('httpd-2.0', $builds, $configs);

    $ENV{CFLAGS} = $build->{cflags};
    info "CFLAGS=$ENV{CFLAGS}";

    my $prefix = "$self->{install}/$name";

    rmtree($prefix) if $self->{fresh};

    my $source = "$self->{src}/$src";

    my @args = ("--prefix=$prefix",
                "--with-mpm=$mpm",
                "--srcdir=$source",
                @{ $build->{config} });

    chdir $source;
    system "./buildconf";

    my $cmd = "$source/configure @args";

    chdir $self->{build};

    mkpath($name);
    chdir $name;

    for my $dir (@srclib_dirs) {
        mkpath("srclib/$dir");
    }

    for my $dir (qw(build docs/conf)) {
        mkpath($dir);
    }

    system $cmd;

    open FH, ">.DONE" or die "open .DONE: $!";
    print FH scalar localtime;
    close FH;

    chdir $self->{prefix};

    $self->add_ssl_libs;
}

sub make {
    my($self, @cmds) = @_;

    push @cmds, 'all' unless @cmds;

    for my $name (keys %{ $self->{builds} }) {
        chdir "$self->{build}/$name";
        for my $cmd (@cmds) {
            system "$self->{make} $cmd";
        }
    }
}

sub system {
    my $cmd = "@_";

    info $cmd;
    return if DRYRUN;

    unless (CORE::system($cmd) == 0) {
        my $status = $? >> 8;
        die "system $cmd failed (exit status=$status)";
    }
}

sub chdir {
    my $dir = shift;
    info "chdir $dir";
    CORE::chdir $dir;
}

sub mkpath {
    my $dir = shift;

    return if -d $dir;
    info "mkpath $dir";

    return if DRYRUN;
    File::Path::mkpath([$dir], 1, 0755);
}

sub rmtree {
    my $dir = shift;

    return unless -d $dir;
    info "rmtree $dir";

    return if DRYRUN;
    File::Path::rmtree([$dir], 1, 1);
}

sub generate_script {
    my($class, $file) = @_;

    $file ||= catfile 't', 'BUILD';

    my $content = join '', <DATA>;

    Apache::Test::basic_config()->write_perlscript($file, $content);
}

unless (caller) {
    $INC{'Apache/TestBuild.pm'} = __FILE__;
    eval join '', <DATA>;
    die $@ if $@;
}

1;
__DATA__
use strict;
use warnings FATAL => 'all';

use lib qw(Apache-Test/lib);
use Apache::TestBuild ();
use Getopt::Long qw(GetOptions);
use Cwd ();

my %options = (
    prefix  => "checkout/build/install prefix",
    ssldir  => "enable ssl with given directory",
    cvstag  => "checkout with given cvs tag",
    cvsroot => "use 'anon' for anonymous cvs",
    version => "apache version (e.g. '2.0')",
    mpms    => "MPMs to build (e.g. 'prefork')",
    flavor  => "build flavor (e.g. 'debug shared')",
    modules => "enable modules (e.g. 'all exp')",
    name    => "change name of the build/install directory",
);

my %opts;

Getopt::Long::Configure(qw(pass_through));
#XXX: could be smarter here, being lazy for the moment
GetOptions(\%opts, map "$_=s", sort keys %options);

if (@ARGV) {
    print "passing extra args to configure: @ARGV\n";
}

my $home = $ENV{HOME};

$opts{prefix}  ||= join '/', Cwd::cwd(), 'farm';
#$opts{ssldir}  ||= '';
#$opts{cvstag}  ||= '';
#$opts{cvsroot} ||= '';
$opts{version} ||= '2.0';
$opts{mpms}    ||= 'prefork';
$opts{flavor}  ||= 'debug-shared';
$opts{modules} ||= 'all-exp';

#my @versions = qw(2.0);

#my @mpms = qw(prefork worker perchild);

#my @flavors  = ([qw(debug shared)], [qw(prof shared)],
#                [qw(debug static)], [qw(prof static)]);

#my @modules = ([qw(all exp)]);

my $split = sub { split '-', delete $opts{ $_[0] } };

my @versions = $opts{version};

my @mpms = $split->('mpms');

my @flavors  = ([ $split->('flavor') ]);

my @modules  = ([ $split->('modules') ]);

my $tb = Apache::TestBuild->new(fresh => 1,
                                %opts,
                                extra_config => {
                                    $opts{version} => \@ARGV,
                                });

$tb->init;

for my $version (@versions) {
    $tb->cvs_update([ $version ]);

    for my $mpm (@mpms) {
        for my $flavor (@flavors) {
            for my $mods (@modules) {
                $tb->configure_httpd_2_0($version, $flavor,
                                         $mods, $mpm);
                $tb->make(qw(all install));
            }
        }
    }
}
