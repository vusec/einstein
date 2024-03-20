#!perl

use strict;
use warnings FATAL=>'all';
use Test ();

Test::plan tests=>47;

sub t {
    my $p=$_[0];
    no strict 'refs';
    Test::ok defined &{$p."::ok"} && \&{$p."::ok"}==\&Test::ok,
	    1, "$p - ok";
    Test::ok defined &{$p."::need"} && \&{$p."::need"}==\&Apache::Test::need,
	    1, "$p - need";
    Test::ok defined &{$p."::plan"} && \&{$p."::plan"}==\&Apache::Test::plan,
	    1, "$p - plan";
}

sub tm {
    my $p=$_[0];
    no strict 'refs';
    Test::ok defined &{$p."::ok"} && \&{$p."::ok"}==\&Test::More::ok,
	    1, "$p - ok";
    Test::ok defined &{$p."::need"} && \&{$p."::need"}==\&Apache::Test::need,
	    1, "$p - need";
    Test::ok defined &{$p."::plan"} && \&{$p."::plan"}==\&Apache::Test::plan,
	    1, "$p - plan";
}

{package X0; use Apache::Test;}
{package Y0; use Apache::Test qw/-withtestmore/;}

t  'X0';
tm 'Y0';

{package X1; use Apache::Test qw/:DEFAULT/;}
{package Y1; use Apache::Test qw/-withtestmore :DEFAULT/;}

t  'X1';
tm 'Y1';

{package X2; use Apache::Test qw/!:DEFAULT/;}
{package Y2; use Apache::Test qw/-withtestmore !:DEFAULT/;}

Test::ok !defined &X2::ok, 1,   '!defined &X2::ok';
Test::ok !defined &X2::need, 1, '!defined &X2::need';
Test::ok !defined &X2::plan, 1, '!defined &X2::plan';
Test::ok !defined &Y2::ok, 1,   '!defined &Y2::ok';
Test::ok !defined &Y2::need, 1, '!defined &Y2::need';
Test::ok !defined &Y2::plan, 1, '!defined &Y2::plan';

{package X3; use Apache::Test qw/plan/;}
{package Y3; use Apache::Test qw/-withtestmore plan/;}

Test::ok !defined &X3::ok, 1,   '!defined &X3::ok';
Test::ok !defined &X3::need, 1, '!defined &X3::need';
Test::ok defined &X3::plan && \&X3::plan==\&Apache::Test::plan, 1, "X3 - plan";
Test::ok !defined &Y3::ok, 1,   '!defined &Y3::ok';
Test::ok !defined &Y3::need, 1, '!defined &Y3::need';
Test::ok defined &Y3::plan && \&Y3::plan==\&Apache::Test::plan, 1, "Y3 - plan";

{package X4; use Apache::Test qw/need/;}
{package Y4; use Apache::Test qw/-withtestmore need/;}

Test::ok !defined &X4::ok, 1,   '!defined &X4::ok';
Test::ok defined &X4::need && \&X4::need==\&Apache::Test::need, 1, "X4 - need";
Test::ok !defined &X4::plan, 1, '!defined &X4::plan';
Test::ok !defined &Y4::ok, 1,   '!defined &Y4::ok';
Test::ok defined &Y4::need && \&Y4::need==\&Apache::Test::need, 1, "Y4 - need";
Test::ok !defined &Y4::plan, 1, '!defined &Y4::plan';

{package X5; use Apache::Test qw/ok/;}
{package Y5; use Apache::Test qw/-withtestmore ok/;}

Test::ok defined &X5::ok && \&X5::ok==\&Test::ok, 1, "X5 - ok";
Test::ok !defined &X5::need, 1, '!defined &X5::need';
Test::ok !defined &X5::plan, 1, '!defined &X5::plan';
Test::ok defined &Y5::ok && \&Y5::ok==\&Test::More::ok, 1, "Y5 - ok";
Test::ok !defined &Y5::need, 1, '!defined &Y5::need';
Test::ok !defined &Y5::plan, 1, '!defined &Y5::plan';

{package X6; use Apache::Test qw/ok need/;}
{package Y6; use Apache::Test qw/-withtestmore ok need/;}

Test::ok defined &X6::ok && \&X6::ok==\&Test::ok, 1, "X6 - ok";
Test::ok defined &X6::need && \&X6::need==\&Apache::Test::need, 1, "X6 - need";
Test::ok !defined &X6::plan, 1, '!defined &X6::plan';
Test::ok defined &Y6::ok && \&Y6::ok==\&Test::More::ok, 1, "Y6 - ok";
Test::ok defined &Y6::need && \&Y6::need==\&Apache::Test::need, 1, "Y6 - need";
Test::ok !defined &Y6::plan, 1, '!defined &Y6::plan';

my $warning;
{
    local $SIG{__WARN__}=sub {$warning=join '', @_};
    eval <<'EVAL';
package Z0;
use Apache::Test qw/:withtestmore/;
EVAL
}
Test::ok $warning, qr/^Ignoring import spec :withtestmore at/,
    "Ignore import warning";

undef $warning;
{
    local $SIG{__WARN__}=sub {$warning=join '', @_};
    eval <<'EVAL';
package X0;
use Apache::Test qw/-withtestmore/;
EVAL
}
Test::ok $warning, qr/^Ignoring -withtestmore due to a previous call /,
    "Ignore -withtestmore warning";

use Config ();
my $pio=$Config::Config{useperlio} ? '' : 'need perlio';
my $output;
Test::skip $pio, sub {
    my @res;
    {
	local $Test::ntest=-19;
	local $Test::planned=-42;
	package Y2;	       # uses Apache::Test qw/-withtestmore !:DEFAULT/
			       # so nothing is exported

	local *STDOUT;
	open STDOUT, '>', \$output;
	{
	    # suppress an 'uninitialized' warning in older perl versions
	    local $SIG{__WARN__}=sub {
		warn $_[0]
		    unless $_[0]=~m!uninitialized\svalue\sin\sopen\b.+
				    Test/Builder\.pm!x;
	    };
	    Apache::Test::plan tests=>17;
	}
	Test::More::isnt "hugo", "erwin", "hugo is not erwin";
	@res=($Test::ntest, $Test::planned);
	Test::Builder->new->reset;
    }
    return "@res";
}, '-19 -42', '$Test::ntest, $Test::planned did not change';

Test::skip $pio, $output=~/^1\.\.17$/m;
Test::skip $pio, $output=~/^ok 1 - hugo is not erwin$/m;
