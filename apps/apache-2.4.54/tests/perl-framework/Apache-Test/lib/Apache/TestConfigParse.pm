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
package Apache::TestConfig; #not TestConfigParse on purpose

#dont really want/need a full-blown parser
#but do want something somewhat generic

use strict;
use warnings FATAL => 'all';

use Apache::TestTrace;

use File::Spec::Functions qw(rel2abs splitdir file_name_is_absolute);
use File::Basename qw(dirname basename);

sub strip_quotes {
    local $_ = shift || $_;
    s/^\"//; s/\"$//; $_;
}

my %wanted_config = (
    TAKE1 => {map { $_, 1 } qw(ServerRoot ServerAdmin TypesConfig DocumentRoot)},
    TAKE2 => {map { $_, 1 } qw(LoadModule LoadFile)},
);

my %spec_init = (
    TAKE1 => sub { shift->{+shift} = "" },
    TAKE2 => sub { shift->{+shift} = [] },
);

my %spec_apply = (
    TypesConfig => \&inherit_server_file,
    ServerRoot  => sub {}, #dont override $self->{vars}->{serverroot}
    DocumentRoot => \&inherit_directive_var,
    LoadModule  => \&inherit_load_module,
    LoadFile    => \&inherit_load_file,
);

#where to add config, default is preamble
my %spec_postamble = map { $_, 'postamble' } qw(TypesConfig);

# need to enclose the following directives into <IfModule
# mod_foo.c>..</IfModule>, since mod_foo might be unavailable
my %ifmodule = (
    TypesConfig => 'mod_mime.c',
);

sub spec_add_config {
    my($self, $directive, $val) = @_;

    my $where = $spec_postamble{$directive} || 'preamble';

    if (my $ifmodule = $ifmodule{TypesConfig}) {
        $self->postamble(<<EOI);
<IfModule $ifmodule>
    $directive $val
</IfModule>
EOI
    }
    else {
        $self->$where($directive => $val);
    }
}

# resolve relative files like Apache->server_root_relative
# this function doesn't test whether the resolved file exists
sub server_file_rel2abs {
    my($self, $file, $base) = @_;

    my ($serverroot, $result) = ();

    # order search sequence
    my @tries = ([ $base,
                       'user-supplied $base' ],
                 [ $self->{inherit_config}->{ServerRoot},
                       'httpd.conf inherited ServerRoot' ],
                 [ $self->apxs('PREFIX', 1),
                       'apxs-derived ServerRoot' ]);

    # remove surrounding quotes if any
    # e.g. Include "/tmp/foo.html"
    $file =~ s/^\s*["']?//;
    $file =~ s/["']?\s*$//;

    if (file_name_is_absolute($file)) {
        debug "$file is already absolute";
        $result = $file;
    }
    else {
        foreach my $try (@tries) {
            next unless defined $try->[0];

            if (-d $try->[0]) {
                $serverroot = $try->[0];
                debug "using $try->[1] to resolve $file";
                last;
            }
        }

        if ($serverroot) {
            $result = rel2abs $file, $serverroot;
        }
        else {
            warning "unable to resolve $file - cannot find a suitable ServerRoot";
            warning "please specify a ServerRoot in your httpd.conf or use apxs";

            # return early, skipping file test below
            return $file;
        }
    }

    my $dir = dirname $result;
    # $file might not exist (e.g. if it's a glob pattern like
    # "conf/*.conf" but what we care about here is to check whether
    # the base dir was successfully resolved. we don't check whether
    # the file exists at all. it's the responsibility of the caller to
    # do this check
    if (defined $dir && -e $dir && -d _) {
        if (-e $result) {
            debug "$file successfully resolved to existing file $result";
        }
        else {
            debug "base dir of '$file' successfully resolved to $dir";
        }

    }
    else {
        $dir ||= '';
        warning "dir '$dir' does not exist (while resolving '$file')";

        # old behavior was to return the resolved but non-existent
        # file.  preserve that behavior and return $result anyway.
    }

    return $result;
}

sub server_file {
    my $f = shift->server_file_rel2abs(@_);
    return qq("$f");
}

sub inherit_directive_var {
    my($self, $c, $directive) = @_;

    $self->{vars}->{"inherit_\L$directive"} = $c->{$directive};
}

sub inherit_server_file {
    my($self, $c, $directive) = @_;

    $self->spec_add_config($directive,
                           $self->server_file($c->{$directive}));
}

#so we have the same names if these modules are linked static or shared
my %modname_alias = (
    'mod_pop.c'            => 'pop_core.c',
    'mod_proxy_ajp.c'      => 'proxy_ajp.c',
    'mod_proxy_http.c'     => 'proxy_http.c',
    'mod_proxy_ftp.c'      => 'proxy_ftp.c',
    'mod_proxy_balancer.c' => 'proxy_balancer.c',
    'mod_proxy_connect.c'  => 'proxy_connect.c',
    'mod_modperl.c'        => 'mod_perl.c',
);

# Block modules which inhibit testing:
# - mod_jk requires JkWorkerFile or JkWorker to be configured
#   skip it for now, tomcat has its own test suite anyhow.
# - mod_casp2 requires other settings in addition to LoadModule
# - mod_bwshare and mod_evasive20 block fast requests that tests are doing
# - mod_fcgid causes https://rt.cpan.org/Public/Bug/Display.html?id=54476
# - mod_modnss.c and mod_rev.c require further configuration
my @autoconfig_skip_module = qw(mod_jk.c mod_casp2.c mod_bwshare.c
    mod_fcgid.c mod_evasive20.c mod_modnss.c mod_rev.c);

# add modules to be not inherited from the existing config.
# e.g. prevent from LoadModule perl_module to be included twice, when
# mod_perl already configures LoadModule and it's certainly found in
# the existing httpd.conf installed system-wide.
sub autoconfig_skip_module_add {
    push @autoconfig_skip_module, @_;
}

sub should_skip_module {
    my($self, $name) = @_;

    for (@autoconfig_skip_module) {
        if (UNIVERSAL::isa($_, 'Regexp')) {
            return 1 if $name =~ /$_/;
        }
        else {
            return 1 if $name eq $_;
        }
    }
    return 0;
}

#inherit LoadModule
sub inherit_load_module {
    my($self, $c, $directive) = @_;

    for my $args (@{ $c->{$directive} }) {
        my $modname = $args->[0];
        my $file = $self->server_file_rel2abs($args->[1]);

        unless (-e $file) {
            debug "$file does not exist, skipping LoadModule";
            next;
        }

        my $name = basename $args->[1];
        $name =~ s/\.(s[ol]|dll)$/.c/;  #mod_info.so => mod_info.c
        $name =~ s/^lib/mod_/; #libphp4.so => mod_php4.c

        $name = $modname_alias{$name} if $modname_alias{$name};

        # remember all found modules
        $self->{modules}->{$name} = $file;
        debug "Found: $modname => $name";

        if ($self->should_skip_module($name)) {
            debug "Skipping LoadModule of $name";
            next;
        }

        debug "LoadModule $modname $name";

        # sometimes people have broken system-wide httpd.conf files,
        # which include LoadModule of modules, which are built-in, but
        # won't be skipped above if they are found in the modules/
        # directory. this usually happens when httpd is built once
        # with its modules built as shared objects and then again with
        # static ones: the old httpd.conf still has the LoadModule
        # directives, even though the modules are now built-in
        # so we try to workaround this problem using <IfModule>
        $self->preamble(IfModule => "!$name",
                        qq{LoadModule $modname "$file"\n});
    }
}

#inherit LoadFile
sub inherit_load_file {
    my($self, $c, $directive) = @_;

    for my $args (@{ $c->{$directive} }) {
        my $file = $self->server_file_rel2abs($args->[0]);

        unless (-e $file) {
            debug "$file does not exist, skipping LoadFile";
            next;
        }

        if ($self->should_skip_module($args->[0])) {
            debug "Skipping LoadFile of $args->[0]";
            next;
        }

        # remember all found modules
        push @{$self->{load_file}}, $file;

        debug "LoadFile $file";

        $self->preamble_first(qq{LoadFile "$file"\n});
    }
}

sub parse_take1 {
    my($self, $c, $directive) = @_;
    $c->{$directive} = strip_quotes;
}

sub parse_take2 {
    my($self, $c, $directive) = @_;
    push @{ $c->{$directive} }, [map { strip_quotes } split];
}

sub apply_take1 {
    my($self, $c, $directive) = @_;

    if (exists $self->{vars}->{lc $directive}) {
        #override replacement @Variables@
        $self->{vars}->{lc $directive} = $c->{$directive};
    }
    else {
        $self->spec_add_config($directive, qq("$c->{$directive}"));
    }
}

sub apply_take2 {
    my($self, $c, $directive) = @_;

    for my $args (@{ $c->{$directive} }) {
        $self->spec_add_config($directive => [map { qq("$_") } @$args]);
    }
}

sub inherit_config_file_or_directory {
    my ($self, $item) = @_;

    if (-d $item) {
        my $dir = $item;
        debug "descending config directory: $dir";

        for my $entry (glob "$dir/*") {
            $self->inherit_config_file_or_directory($entry);
        }
        return;
    }

    my $file = $item;
    debug "inheriting config file: $file";

    my $fh = Symbol::gensym();
    open($fh, $file) or return;

    my $c = $self->{inherit_config};
    while (<$fh>) {
        s/^\s*//; s/\s*$//; s/^\#.*//;
        next if /^$/;

        # support continuous config lines (which use \ to break the line)
        while (s/\\$//) {
            my $cont = <$fh>;
            $cont =~ s/^\s*//;
            $cont =~ s/\s*$//;
            $_ .= $cont;
        }

        (my $directive, $_) = split /\s+/, $_, 2;

        if ($directive eq "Include" or $directive eq "IncludeOptional") {
            foreach my $include (glob($self->server_file_rel2abs($_))) {
                $self->inherit_config_file_or_directory($include);
            }
        }

        #parse what we want
        while (my($spec, $wanted) = each %wanted_config) {
            next unless $wanted->{$directive};
            my $method = "parse_\L$spec";
            $self->$method($c, $directive);
        }
    }

    close $fh;
}

sub inherit_config {
    my $self = shift;

    $self->get_httpd_static_modules;
    $self->get_httpd_defines;

    #may change after parsing httpd.conf
    $self->{vars}->{inherit_documentroot} =
      catfile $self->{httpd_basedir}, 'htdocs';

    my $file = $self->{vars}->{httpd_conf};
    my $extra_file = $self->{vars}->{httpd_conf_extra};

    unless ($file and -e $file) {
        if (my $base = $self->{httpd_basedir}) {
            my $default_conf = $self->{httpd_defines}->{SERVER_CONFIG_FILE};
            $default_conf ||= catfile qw(conf httpd.conf);
            $file = catfile $base, $default_conf;

            # SERVER_CONFIG_FILE might be an absolute path
            unless (-e $file) {
                if (-e $default_conf) {
                    $file = $default_conf;
                }
                else {
                    # try a little harder
                    if (my $root = $self->{httpd_defines}->{HTTPD_ROOT}) {
                        debug "using HTTPD_ROOT to resolve $default_conf";
                        $file = catfile $root, $default_conf;
                    }
                }
            }
        }
    }

    unless ($extra_file and -e $extra_file) {
        if ($extra_file and my $base = $self->{httpd_basedir}) {
            my $default_conf = catfile qw(conf $extra_file);
            $extra_file = catfile $base, $default_conf;
            # SERVER_CONFIG_FILE might be an absolute path
            $extra_file = $default_conf if !-e $extra_file and -e $default_conf;
        }
    }

    return unless $file or $extra_file;

    my $c = $self->{inherit_config};

    #initialize array refs and such
    while (my($spec, $wanted) = each %wanted_config) {
        for my $directive (keys %$wanted) {
            $spec_init{$spec}->($c, $directive);
        }
    }

    $self->inherit_config_file_or_directory($file) if $file;
    $self->inherit_config_file_or_directory($extra_file) if $extra_file;

    #apply what we parsed
    while (my($spec, $wanted) = each %wanted_config) {
        for my $directive (keys %$wanted) {
            next unless $c->{$directive};
            my $cv = $spec_apply{$directive} ||
                     $self->can("apply_\L$directive") ||
                     $self->can("apply_\L$spec");
            $cv->($self, $c, $directive);
        }
    }
}

sub get_httpd_static_modules {
    my $self = shift;

    my $httpd = $self->{vars}->{httpd};
    return unless $httpd;

    $httpd = shell_ready($httpd);
    my $cmd = "$httpd -l";
    my $list = $self->open_cmd($cmd);

    while (<$list>) {
        s/\s+$//;
        next unless /\.c$/;
        chomp;
        s/^\s+//;
        $self->{modules}->{$_} = 1;
    }

    close $list;
}

sub get_httpd_defines {
    my $self = shift;

    my $httpd = $self->{vars}->{httpd};
    return unless $httpd;

    $httpd = shell_ready($httpd);
    my $cmd = "$httpd -V";

    my $httpdconf = $self->{vars}->{httpd_conf};
    $cmd .= " -f $httpdconf" if $httpdconf;

    my $serverroot = $self->{vars}->{serverroot};
    $cmd .= " -d $serverroot" if $serverroot;

    my $proc = $self->open_cmd($cmd);

    while (<$proc>) {
        chomp;
        if( s/^\s*-D\s*//) {
            s/\s+$//;
            my($key, $val) = split '=', $_, 2;
            $self->{httpd_defines}->{$key} = $val ? strip_quotes($val) : 1;
            debug "isolated httpd_defines $key = " . $self->{httpd_defines}->{$key};
        }
        elsif (/(version|built|module magic number|server mpm):\s+(.*)/i) {
            my $val = $2;
            (my $key = uc $1) =~ s/\s/_/g;
            $self->{httpd_info}->{$key} = $val;
            debug "isolated httpd_info $key = " . $val;
        }
    }

    close $proc;

    if (my $mmn = $self->{httpd_info}->{MODULE_MAGIC_NUMBER}) {
        @{ $self->{httpd_info} }
          {qw(MODULE_MAGIC_NUMBER_MAJOR
              MODULE_MAGIC_NUMBER_MINOR)} = split ':', $mmn;
    }

    # get the mpm information where available
    # lowercase for consistency across the two extraction methods
    # XXX or maybe consider making have_apache_mpm() case-insensitive?
    if (my $mpm = $self->{httpd_info}->{SERVER_MPM}) {
        # 2.1
        $self->{mpm} = lc $mpm;
    }
    elsif (my $mpm_dir = $self->{httpd_defines}->{APACHE_MPM_DIR}) {
        # 2.0
        $self->{mpm} = lc basename $mpm_dir;
    }
    else {
        # Apache 1.3 - no mpm to speak of
        $self->{mpm} = '';
    }

    my $version = $self->{httpd_info}->{VERSION} || '';

    if ($version =~ qr,Apache/2,) {
        # PHP 4.x on httpd-2.x needs a special modname alias:
        $modname_alias{'mod_php4.c'} = 'sapi_apache2.c';
    }

    unless ($version =~ qr,Apache/(2.0|1.3),) {
        # for 2.1 and later, mod_proxy_* are really called mod_proxy_*
        delete @modname_alias{grep {/^mod_proxy_/} keys %modname_alias};
    }
}

sub httpd_version {
    my $self = shift;

    my $httpd = $self->{vars}->{httpd};
    return unless $httpd;

    my $version;
    $httpd = shell_ready($httpd);
    my $cmd = "$httpd -v";

    my $v = $self->open_cmd($cmd);

    local $_;
    while (<$v>) {
        next unless s/^Server\s+version:\s*//i;
        chomp;
        my @parts = split;
        foreach (@parts) {
            next unless /^Apache\//;
            $version = $_;
            last;
        }
        $version ||= $parts[0];
        last;
    }

    close $v;

    return $version;
}

sub httpd_mpm {
    return shift->{mpm};
}

1;
