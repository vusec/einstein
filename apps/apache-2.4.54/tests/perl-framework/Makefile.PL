use ExtUtils::MakeMaker;

use 5.005;

use lib qw(Apache-Test/lib);

use Apache::Test5005compat;

use Apache::TestMM qw(test clean);
use Apache::TestReport ();
use Apache::TestSmoke ();
use Apache::TestRun ();

use File::Find qw(finddepth);

my @scripts = ();

finddepth(sub {
    return unless /^(?!.#)(.*?\.pl)\.PL$/;
    push @scripts, "$File::Find::dir/$1";
}, '.');

Apache::TestMM::filter_args();

# Temporary workaround to allow passing
# arguments to "perl Makefile.PL"
# that should go to t/TEST but are not yet
# supported in an Apache::Test release.
# Code borrowed from Apache::TestMM::filter_args().
my %local_args = (
    limitrequestline => 'Value for LimitRequestLine',
    limitrequestlinex2 => 'Twice the value for LimitRequestLine',
);
my($argv, $args_vars) = Apache::TestConfig::filter_args(\@ARGV, \%local_args);
@ARGV = @$argv;
# Merge given vars with default values
my %local_vars = (
    limitrequestline => '128',
    limitrequestlinex2 => '256',
);
map {$local_vars{$_} = $args_vars->{$_}} keys %$args_vars;

push(@Apache::TestMM::Argv, %local_vars);

for my $script (@scripts) {
    Apache::TestMM::generate_script($script);
}

for my $util (qw(Report Smoke Run)) {
    my $class = "Apache::Test${util}";
    $class->generate_script;
}

WriteMakefile(
    NAME => 'httpd-test',
    VERSION => '0.01',
    clean => { FILES => "@scripts" },
);
