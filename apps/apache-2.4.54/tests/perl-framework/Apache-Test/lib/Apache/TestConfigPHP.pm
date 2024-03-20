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
package Apache::TestConfigPHP;

#things specific to php

use strict;
use warnings FATAL => 'all';
use File::Spec::Functions qw(catfile splitdir abs2rel);
use File::Find qw(finddepth);
use Apache::TestTrace;
use Apache::TestRequest;
use Apache::TestConfig;
use Apache::TestConfigPerl;
use Config;

@Apache::TestConfigPHP::ISA = qw(Apache::TestConfig);

my ($php_ini, $test_more);

{
  # __DATA__ contains both php.ini and test-more.php

  local $/ = "END_OF_FILE\n";

  $php_ini = <DATA>;
  chomp $php_ini;

  $test_more = <DATA>;
  chomp $test_more;
}

sub new {
    return shift->SUPER::new(@_);
}

my %warn_style = (
    html    => sub { "<!-- @_ -->" },
    c       => sub { "/* @_ */" },
    ini     => sub { join '', grep {s/^/; /gm} @_ },
    php     => sub { join '', "<?php\n", grep {s/^/# /gm} @_ },
    default => sub { join '', grep {s/^/\# /gm} @_ },
);

my %file_ext = (
    map({$_ => 'html'} qw(htm html)),
    map({$_ => 'c'   } qw(c h)),
    map({$_ => 'ini' } qw(ini)),
    map({$_ => 'php' } qw(php)),
);

sub warn_style_sub_ref {
    my ($self, $filename) = @_;
    my $ext = $self->filename_ext($filename);
    return $warn_style{ $file_ext{$ext} || 'default' };
}

sub configure_php_tests_pick {
    my($self, $entries) = @_;

    for my $subdir (qw(Response)) {
        my $dir = catfile $self->{vars}->{t_dir}, lc $subdir;
        next unless -d $dir;

        finddepth(sub {
            return unless /\.php$/;

            my $file = catfile $File::Find::dir, $_;
            my $module = abs2rel $file, $dir;
            my $status = $self->run_apache_test_config_scan($file);
            push @$entries, [$file, $module, $subdir, $status];
        }, $dir);
    }
}

sub write_php_test {
    my($self, $location, $test) = @_;

    (my $path = $location) =~ s/test//i;
    (my $file = $test) =~ s/php$/t/i;

    my $dir = catfile $self->{vars}->{t_dir}, lc $path;
    my $t = catfile $dir, $file;
    my $php_t = catfile $dir, $test;
    return if -e $t;

    # don't write out foo.t if foo.php already exists
    return if -e $php_t;

    $self->gendir($dir);
    my $fh = $self->genfile($t);

    print $fh <<EOF;
use Apache::TestRequest 'GET_BODY_ASSERT';
print GET_BODY_ASSERT "/$location/$test";
EOF

    close $fh or die "close $t: $!";

    # write out an all.t file for the directory
    # that will skip running all PHP test unless have_php

    my $all = catfile $dir, 'all.t';

    unless (-e $all) {
        my $fh = $self->genfile($all);

        print $fh <<EOF;
use strict;
use warnings FATAL => 'all';

use Apache::Test;

# skip all tests in this directory unless a php module is enabled
plan tests => 1, need_php;

ok 1;
EOF
    }
}

sub configure_php_inc {
    my $self = shift;

    my $serverroot = $self->{vars}->{serverroot};

    my $path = catfile $serverroot, 'conf';

    # make sure that require() or include() calls can find
    # the generated test-more.php without using absolute paths
    my $cfg = { php_value => "include_path $path", };
    $self->postamble(IfModule => $self->{vars}->{php_module}, $cfg);

    # give test-more.php access to the ServerRoot directive
    $self->postamble("SetEnv SERVER_ROOT $serverroot\n");
}

sub configure_php_functions {
    my $self = shift;

    my $dir  = catfile $self->{vars}->{serverroot}, 'conf';
    my $file = catfile $dir, 'test-more.php';

    $self->gendir($dir);
    my $fh = $self->genfile($file);

    print $fh $test_more;

    close $fh or die "close $file: $!";

    $self->clean_add_file($file);
}

sub configure_php_ini {
    my $self = shift;

    my $dir  = catfile $self->{vars}->{serverroot}, 'conf';
    my $file = catfile $dir, 'php.ini';

    return if -e $file;

    my $log  = catfile $self->{vars}->{t_logs}, 'error_log';

    $self->gendir($dir);
    my $fh = $self->genfile($file);

    $php_ini =~ s/\@error_log\@/error_log $log/;
    print $fh $php_ini;

    close $fh or die "close $file: $!";

    $self->clean_add_file($file);
}

sub configure_php_tests {
    my $self = shift;

    my @entries = ();
    $self->configure_php_tests_pick(\@entries);
    $self->configure_pm_tests_sort(\@entries);

    my %seen = ();

    for my $entry (@entries) {
        my ($file, $module, $subdir, $status) = @$entry;

        my @args = ();

        my $directives = $self->add_module_config($file, \@args);

        my @parts    = splitdir $file;
        my $test     = pop @parts;
        my $location = $parts[-1];

        debug "configuring PHP test file $file";

        if ($directives->{noautoconfig}) {
            $self->postamble(""); # which adds "\n"
        }
        else {
            unless ($seen{$location}++) {
                $self->postamble(Alias => [ catfile('', $parts[-1]), catfile(@parts) ]);

                my @args = (AddType => 'application/x-httpd-php .php');

                $self->postamble(Location => "/$location", \@args);
            }
        }

        $self->write_php_test($location, $test);
    }
}

1;

__DATA__
; This is php.ini-recommended from php 5.0.2,
; used in place of your locally installed php.ini file
; as part of the pristine environment Apache-Test creates
; for you
; [NOTE]: cat php.ini-recommended | grep -v '^;' | sed -e '/^$/d' 
;
; exceptions to php.ini-recommended are as follows:
display_startup_errors = On
html_errors = Off
@error_log@
output_buffering = Off

; the rest of php.ini-recommended, unaltered, save for
; some tidying like the removal of comments and blank lines

[PHP]
engine = On
zend.ze1_compatibility_mode = Off
short_open_tag = Off
asp_tags = Off
precision    =  14
y2k_compliance = On
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func=
serialize_precision = 100
allow_call_time_pass_reference = Off
safe_mode = Off
safe_mode_gid = Off
safe_mode_include_dir =
safe_mode_exec_dir =
safe_mode_allowed_env_vars = PHP_
safe_mode_protected_env_vars = LD_LIBRARY_PATH
disable_functions =
disable_classes =
expose_php = On
max_execution_time = 30     ; Maximum execution time of each script, in seconds
max_input_time = 60	; Maximum amount of time each script may spend parsing request data
memory_limit = 128M      ; Maximum amount of memory a script may consume (128MB)
error_reporting  =  E_ALL
display_errors = Off
log_errors = On
log_errors_max_len = 1024
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
track_errors = Off
variables_order = "GPCS"
register_globals = Off
register_long_arrays = Off
register_argc_argv = Off
auto_globals_jit = On
post_max_size = 8M
magic_quotes_gpc = Off
magic_quotes_runtime = Off
magic_quotes_sybase = Off
auto_prepend_file =
auto_append_file =
default_mimetype = "text/html"
doc_root =
user_dir =
enable_dl = On
file_uploads = On
upload_max_filesize = 2M
allow_url_fopen = On
allow_url_include = Off
default_socket_timeout = 60
[Date]
[filter]
[iconv]
[sqlite]
[xmlrpc]
[Pcre]
[Syslog]
define_syslog_variables  = Off
[mail function]
SMTP = localhost
smtp_port = 25
[SQL]
sql.safe_mode = Off
[ODBC]
odbc.allow_persistent = On
odbc.check_persistent = On
odbc.max_persistent = -1
odbc.max_links = -1
odbc.defaultlrl = 4096
odbc.defaultbinmode = 1
[MySQL]
mysql.allow_persistent = On
mysql.max_persistent = -1
mysql.max_links = -1
mysql.default_port =
mysql.default_socket =
mysql.default_host =
mysql.default_user =
mysql.default_password =
mysql.connect_timeout = 60
mysql.trace_mode = Off
[MySQLi]
mysqli.max_links = -1
mysqli.default_port = 3306
mysqli.default_socket =
mysqli.default_host =
mysqli.default_user =
mysqli.default_pw =
mysqli.reconnect = Off
[mSQL]
msql.allow_persistent = On
msql.max_persistent = -1
msql.max_links = -1
[OCI8]
[PostgresSQL]
pgsql.allow_persistent = On
pgsql.auto_reset_persistent = Off
pgsql.max_persistent = -1
pgsql.max_links = -1
pgsql.ignore_notice = 0
pgsql.log_notice = 0
[Sybase]
sybase.allow_persistent = On
sybase.max_persistent = -1
sybase.max_links = -1
sybase.min_error_severity = 10
sybase.min_message_severity = 10
sybase.compatability_mode = Off
[Sybase-CT]
sybct.allow_persistent = On
sybct.max_persistent = -1
sybct.max_links = -1
sybct.min_server_severity = 10
sybct.min_client_severity = 10
[bcmath]
bcmath.scale = 0
[browscap]
[Informix]
ifx.default_host =
ifx.default_user =
ifx.default_password =
ifx.allow_persistent = On
ifx.max_persistent = -1
ifx.max_links = -1
ifx.textasvarchar = 0
ifx.byteasvarchar = 0
ifx.charasvarchar = 0
ifx.blobinfile = 0
ifx.nullformat = 0
[Session]
session.save_handler = files
session.use_cookies = 1
session.name = PHPSESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.cookie_domain =
session.cookie_httponly = 
session.serialize_handler = php
session.gc_probability = 1
session.gc_divisor     = 1000
session.gc_maxlifetime = 1440
session.bug_compat_42 = 0
session.bug_compat_warn = 1
session.referer_check =
session.entropy_length = 0
session.entropy_file =
session.cache_limiter = nocache
session.cache_expire = 180
session.use_trans_sid = 0
session.hash_function = 0
session.hash_bits_per_character = 5
url_rewriter.tags = "a=href,area=href,frame=src,input=src,form=fakeentry"
[MSSQL]
mssql.allow_persistent = On
mssql.max_persistent = -1
mssql.max_links = -1
mssql.min_error_severity = 10
mssql.min_message_severity = 10
mssql.compatability_mode = Off
mssql.secure_connection = Off
[Assertion]
[COM]
[mbstring]
[FrontBase]
[gd]
[exif]
[Tidy]
tidy.clean_output = Off
[soap]
soap.wsdl_cache_enabled=1
soap.wsdl_cache_dir="/tmp"
soap.wsdl_cache_ttl=86400
END_OF_FILE
/*******************************************************************\
*                        PROJECT INFORMATION                        *
*                                                                   *
*  Project:  Apache-Test                                            *
*  URL:      http://perl.apache.org/Apache-Test/                    *
*  Notice:   Copyright (c) 2006 The Apache Software Foundation      *
*                                                                   *
*********************************************************************
*                        LICENSE INFORMATION                        *
*                                                                   *
*  Licensed under the Apache License, Version 2.0 (the "License");  *
*  you may not use this file except in compliance with the          *
*  License. You may obtain a copy of the License at:                *
*                                                                   *
*  http://www.apache.org/licenses/LICENSE-2.0                       *
*                                                                   *
*  Unless required by applicable law or agreed to in writing,       *
*  software distributed under the License is distributed on an "AS  *
*  IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either  *
*  express or implied. See the License for the specific language    *
*  governing permissions and limitations under the License.         *
*                                                                   *
*********************************************************************
*                        MODULE INFORMATION                         *
*                                                                   *
*  This is a PHP implementation of Test::More:                      *
*                                                                   *
*  http://search.cpan.org/dist/Test-Simple/lib/Test/More.pm         *
*                                                                   *
*********************************************************************
*                              CREDITS                              *
*                                                                   *
*  Originally inspired by work from Andy Lester. Written and        *
*  maintained by Chris Shiflett. For contact information, see:      *
*                                                                   *
*  http://shiflett.org/                                             *
*                                                                   *
\*******************************************************************/

header('Content-Type: text/plain');
register_shutdown_function('_test_end');

$_no_plan = FALSE;
$_num_failures = 0;
$_num_skips = 0;
$_test_num = 0;

function plan($plan)
{
    /*
    plan('no_plan');
    plan('skip_all');
    plan(array('skip_all' => 'My reason is...'));
    plan(23);
    */

    global $_no_plan;
    global $_skip_all;
    global $_skip_reason;

    switch ($plan)
    {
        case 'no_plan':
            $_no_plan = TRUE;
            break;

        case 'skip_all':
            echo "1..0\n";
            break;

        default:
            if (is_array($plan))
            {
                echo "1..0 # Skip {$plan['skip_all']}\n";
                exit;
            }

            echo "1..$plan\n";
            break;
    }
}

function ok($pass, $test_name = '')
{
    global $_test_num;
    global $_num_failures;
    global $_num_skips;

    $_test_num++;

    if ($_num_skips)
    {
        $_num_skips--;
        return TRUE;
    }

    if (!empty($test_name) && $test_name[0] != '#')
    {
        $test_name = "- $test_name";
    }

    if ($pass)
    {
        echo "ok $_test_num $test_name\n";
    }
    else
    {
        echo "not ok $_test_num $test_name\n";

        $_num_failures++;
        $caller = debug_backtrace();

        if (strstr($caller['0']['file'], $_SERVER['PHP_SELF']))
        {
            $file = $caller['0']['file'];
            $line = $caller['0']['line'];
        }
        else
        {
            $file = $caller['1']['file'];
            $line = $caller['1']['line'];
        }

        $file = str_replace($_SERVER['SERVER_ROOT'], 't', $file);

        diag("    Failed test ($file at line $line)");
    }

    return $pass;
}

function is($this, $that, $test_name = '')
{
    $pass = ($this == $that);

    ok($pass, $test_name);

    if (!$pass)
    {
        diag("         got: '$this'");
        diag("    expected: '$that'");
    }

    return $pass;
}

function isnt($this, $that, $test_name = '')
{
    $pass = ($this != $that);

    ok($pass, $test_name);

    if (!$pass)
    {
        diag("    '$this'");
        diag('        !=');
        diag("    '$that'");
    }

    return $pass;
}

function like($string, $pattern, $test_name = '')
{
    $pass = preg_match($pattern, $string);

    ok($pass, $test_name);

    if (!$pass)
    {
        diag("                  '$string'");
        diag("    doesn't match '$pattern'");
    }

    return $pass;
}

function unlike($string, $pattern, $test_name = '')
{
    $pass = !preg_match($pattern, $string);

    ok($pass, $test_name);

    if (!$pass)
    {
        diag("                  '$string'");
        diag("          matches '$pattern'");
    }

    return $pass;
}

function cmp_ok($this, $operator, $that, $test_name = '')
{
    eval("\$pass = (\$this $operator \$that);");

    ok($pass, $test_name);

    if (!$pass)
    {
        diag("         got: '$this'");
        diag("    expected: '$that'");
    }

    return $pass;
}

function can_ok($object, $methods)
{
    $pass = TRUE;
    $errors = array();

    foreach ($methods as $method)
    {
        if (!method_exists($object, $method))
        {
            $pass = FALSE;
            $errors[] = "    method_exists(\$object, $method) failed";
        }
    }

    if ($pass)
    {
        ok(TRUE, "method_exists(\$object, ...)");
    }
    else
    {
        ok(FALSE, "method_exists(\$object, ...)");
        diag($errors);
    }

    return $pass;
}

function isa_ok($object, $expected_class, $object_name = 'The object')
{
    $got_class = get_class($object);

    if (version_compare(php_version(), '5', '>='))
    {
        $pass = ($got_class == $expected_class);
    }
    else
    {
        $pass = ($got_class == strtolower($expected_class));
    }

    if ($pass)
    {
        ok(TRUE, "$object_name isa $expected_class");
    }
    else
    {
        ok(FALSE, "$object_name isn't a '$expected_class' it's a '$got_class'");
    }

    return $pass;
}

function pass($test_name = '')
{
    return ok(TRUE, $test_name);
}

function fail($test_name = '')
{
    return ok(FALSE, $test_name);
}

function diag($message)
{
    if (is_array($message))
    {
        foreach($message as $current)
        {
            echo "# $current\n";
        }
    }
    else
    {
        echo "# $message\n";
    }
}

function include_ok($module)
{
    $pass = ((include $module) == 'OK');
    return ok($pass);
}

function require_ok($module)
{
    $pass = ((require $module) == 'OK');
    return ok($pass);
}

function skip($message, $num)
{
    global $_num_skips;

    if ($num < 0)
    {
        $num = 0;
    }

    for ($i = 0; $i < $num; $i++)
    {
        pass("# SKIP $message");
    }

    $_num_skips = $num;
}

/*

TODO:

function todo()
{
}

function todo_skip()
{
}

function is_deeply()
{
}

function eq_array()
{
}

function eq_hash()
{
}

function eq_set()
{
}

*/

function _test_end()
{
    global $_no_plan;
    global $_num_failures;
    global $_test_num;

    if ($_no_plan)
    {
        echo "1..$_test_num\n";
    }

    if ($_num_failures)
    {
        diag("Looks like you failed $_num_failures tests of $_test_num.");
    }
}

?>
