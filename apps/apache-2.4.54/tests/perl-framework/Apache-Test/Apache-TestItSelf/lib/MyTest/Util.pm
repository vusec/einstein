package MyTest::Util;

use strict;
use warnings FATAL => 'all';

use Apache::TestConfig;
use Apache::TestTrace;

use Exporter ();
use IPC::Run3 ();
use Cwd;

use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT    = ();
@EXPORT_OK = qw(myrun3 go_in go_out work_dir dump_stds check_eval
                test_configs);

sub myrun3 {
    my $cmd = shift;
    my $out = '';
    my $err = '';

    my $ok = IPC::Run3::run3($cmd, \undef, \$out, \$err);
    die "IPC::Run3 failed to run $cmd" unless $ok;

    dump_stds($cmd, '', $out, $err) if $?;

    return ($out, $err);
}

sub go_in {
    my $orig_dir = cwd();
    my $dir = $ENV{APACHE_TESTITSELF_BASE_DIR} || '';
    debug "chdir $dir";
    chdir $dir or die "failed to chdir to $dir: $!";
    return $orig_dir;
}

sub go_out {
    my $dir = shift;
    debug "chdir $dir";
    chdir $dir or die "failed to chdir to $dir: $!";
}

# the base dir from which the A-T tests are supposed to be run
# we might not be there
sub work_dir { $ENV{APACHE_TESTITSELF_BASE_DIR} }

sub dump_stds {
    my($cmd, $in, $out, $err) = @_;
    $cmd = 'unknown' unless length $cmd;
    $in  = '' unless length $in;
    $out = '' unless length $out;
    $err = '' unless length $err;

    if ($cmd) {
        $cmd =~ s/\n$//;
        $cmd =~ s/^/# /gm;
        print STDERR "\n\n#== CMD ===\n$cmd\n#=============";
    }
    if ($in) {
        $in =~ s/\n$//;
        $in =~ s/^/# /gm;
        print STDERR "\n### STDIN  ###\n$in\n##############\n\n\n";
    }
    if ($out) {
        $out =~ s/\n$//;
        $out =~ s/^/# /gm;
        print STDERR "\n### STDOUT ###\n$out\n##############\n\n\n";
    }
    if ($err) {
        $err =~ s/\n$//;
        $err =~ s/^/# /gm;
        print STDERR "\n### STDERR ###\n$err\n##############\n\n\n";
    }
}

# if $@ is set dumps the $out and $err streams and dies
# otherwise resets the $out and $err streams if $reset_std is true
sub check_eval {
    my($cmd, $out, $err, $reset_std, $msg) = @_;
    $msg ||= "unknown";
    if ($@) {
        dump_stds($cmd, '', $out, $err);
        die "$@\nError: $msg\n";
    }
    # reset the streams in caller
    ($_[1], $_[2]) = ("", "") if $reset_std;
}

# this function returns an array of configs (hashes) coming from
# -config-file command line option
sub test_configs {
    my $config_file = $ENV{APACHE_TESTITSELF_CONFIG_FILE} || '';

    # reset
    %Apache::TestItSelf::Config = ();
    @Apache::TestItSelf::Configs = ();

    require $config_file;
    unless (@Apache::TestItSelf::Configs) {
        error "can't find test configs in '$config_file'";
        exit 1;
    }

    my %global = %Apache::TestItSelf::Config;

    # merge the global config with instance configs
    my @configs = map { { %global, %$_ } } @Apache::TestItSelf::Configs;

    return @configs;
}


1;

__END__

=head1 NAME

MyTest::Util -- helper functions

=head1 Config files format

the -config-file command line option specifies which file contains the
configurations to run with.

META: expand

  %Apache::TestItSelf::Config = (
      perl_exec     => "/home/$ENV{USER}/perl/5.8.5-ithread/bin/perl5.8.5",
      mp_gen        => '2.0',
      httpd_gen     => '2.0',
      httpd_version => 'Apache/2.0.55',
      timeout       => 200,
      makepl_arg    => 'MOD_PERL=2 -libmodperl mod_perl-5.8.5-ithread.so',
  );

  my $path = "/home/$ENV{USER}/httpd";

  @Apache::TestItSelf::Configs = (
      {
       apxs_exec     => "$path/prefork/bin/apxs",
       httpd_exec    => "$path/prefork/bin/httpd",
       httpd_mpm     => "prefork",
       test_verbose  => 0,
      },
      {
       apxs_exec     => "$path/worker/bin/apxs",
       httpd_exec    => "$path/worker/bin/httpd",
       httpd_mpm     => "worker",
       test_verbose  => 1,
      },
  );
  1;


=cut

