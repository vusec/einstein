package LightyTest;

use strict;
use IO::Socket ();
use Test::More; # diag()
use Socket;
use Cwd 'abs_path';

use lib "$ENV{'ROOT'}/apps/scripts/perl-tests";
require EinsteinTests;

sub find_program {
	my @DEFAULT_PATHS = ('/usr/bin/', '/usr/local/bin/');
	my ($envname, $program) = @_;
	my $location;

	if (defined $ENV{$envname}) {
		$location = $ENV{$envname};
	} else {
		$location = `which "$program" 2>/dev/null`;
		chomp $location;
		if (! -x $location) {
			for my $path (@DEFAULT_PATHS) {
				$location = $path . $program;
				last if -x $location;
			}
		}
	}

	if (-x $location) {
		$ENV{$envname} = $location;
		return 1;
	} else {
		delete $ENV{$envname};
		return 0;
	}
}

BEGIN {
	our $HAVE_PERL = find_program('PERL', 'perl');
	if (!$HAVE_PERL) {
		die "Couldn't find path to perl, but it obviously seems to be running";
	}
}

sub mtime {
	my $file = shift;
	my @stat = stat $file;
	return @stat ? $stat[9] : 0;
}

sub new {
	my $class = shift;
	my $self = {};
	my $lpath;

	$self->{CONFIGFILE} = 'lighttpd.conf';

	$lpath = (defined $ENV{'top_builddir'} ? $ENV{'top_builddir'} : '..');
	$self->{BASEDIR} = abs_path($lpath);

	$lpath = (defined $ENV{'top_builddir'} ? $ENV{'top_builddir'}."/tests/" : '.');
	$self->{TESTDIR} = abs_path($lpath);

	$lpath = (defined $ENV{'srcdir'} ? $ENV{'srcdir'} : '.');
	$self->{SRCDIR} = abs_path($lpath);


	if (mtime($self->{BASEDIR}.'/src/lighttpd') > mtime($self->{BASEDIR}.'/build/lighttpd')) {
		$self->{BINDIR} = $self->{BASEDIR}.'/src';
		if (mtime($self->{BASEDIR}.'/src/.libs')) {
			$self->{MODULES_PATH} = $self->{BASEDIR}.'/src/.libs';
		} else {
			$self->{MODULES_PATH} = $self->{BASEDIR}.'/src';
		}
	} else {
		$self->{BINDIR} = $self->{BASEDIR}.'/build';
		$self->{MODULES_PATH} = $self->{BASEDIR}.'/build';
	}
	$self->{LIGHTTPD_PATH} = $self->{BINDIR}.'/lighttpd';
	if (exists $ENV{LIGHTTPD_EXE_PATH}) {
		$self->{LIGHTTPD_PATH} = $ENV{LIGHTTPD_EXE_PATH};
	}

	my ($name, $aliases, $addrtype, $net) = gethostbyaddr(inet_aton("127.0.0.1"), AF_INET);

	$self->{HOSTNAME} = $name;

	bless($self, $class);

	return $self;
}

sub listening_on {
	my $self = shift;
	my $port = shift;

	local $@;
	local $SIG{ALRM} = sub { };
    eval {
	local $SIG{ALRM} = sub { die 'alarm()'; };
	alarm(1);
	my $remote = IO::Socket::INET->new(
		Timeout  => 1,
		Proto    => "tcp",
		PeerAddr => "127.0.0.1",
		PeerPort => $port) || do { alarm(0); die 'socket()'; };

	close $remote;
	alarm(0);
    };
	alarm(0);
	return (defined($@) && $@ eq "");
}

sub stop_proc {
	my $self = shift;

	my $pid = $self->{LIGHTTPD_PID};
	if (defined $pid && $pid != -1) {
		kill('USR1', $pid) if (($ENV{"TRACEME"}||'') eq 'strace');
		kill('TERM', $pid) or return -1;
		return -1 if ($pid != waitpid($pid, 0));
		system('env', '-C', '..', 'V=1', './serverctl', 'stop');
		sleep(5);
	} else {
		diag("\nProcess not started, nothing to stop");
		return -1;
	}

	return 0;
}

sub wait_for_port_with_proc {
	my $self = shift;
	my $port = shift;
	my $child = shift;
	my $timeout = 10*100; # 10 secs (valgrind might take a while), select waits 0.01 s

	while (0 == $self->listening_on($port)) {
		select(undef, undef, undef, 0.01);
		$timeout--;

		# the process is gone, we failed
		require POSIX;
		if (0 != waitpid($child, POSIX::WNOHANG())) {
			return -1;
		}
		if (0 >= $timeout) {
			diag("\nTimeout while trying to connect; killing child");
			kill('TERM', $child);
			return -1;
		}
	}

	return 0;
}

sub bind_ephemeral_tcp_socket {
	my $SOCK;
	socket($SOCK, PF_INET, SOCK_STREAM, 0) || die "socket: $!";
	setsockopt($SOCK, SOL_SOCKET, SO_REUSEADDR, pack("l", 1)) || die "setsockopt: $!";
	bind($SOCK, sockaddr_in(0, INADDR_LOOPBACK)) || die "bind: $!";
	my($port) = sockaddr_in(getsockname($SOCK));
	return ($SOCK, $port);
}

sub get_ephemeral_tcp_port {
	# bind to an ephemeral port, close() it, and return port that was used
	# (While there is a race condition before caller may reuse the port,
	#  the port is likely to remain available for the serialized tests)
	my $port;
	(undef, $port) = bind_ephemeral_tcp_socket();
	return $port;
}

sub taint_all {
	my $lighttypdpath = $ENV{'ROOT'}.'/apps/lighttpd-1.4.65';
	EinsteinTests::send_test_info($lighttypdpath);
	diag("Now tainting all memory...\n");
	sleep(2);
	system('env', '-C', $lighttypdpath, './serverctl', 'udscmd', 'pids', 'dbt', 'taintall');
	diag("Done! Now continuing test...\n");
	sleep(2);
}

sub start_proc {
	my $self = shift;
	# kill old proc if necessary
	#$self->stop_proc;

	# listen on localhost and kernel-assigned ephemeral port
	my $SOCK;
	($SOCK, $self->{PORT}) = bind_ephemeral_tcp_socket();

	# pre-process configfile if necessary
	#

	$ENV{'SRCDIR'} = $self->{BASEDIR}.'/tests';
	$ENV{'PORT'} = $self->{PORT};

	my $testfilename = (split(/\//, $0))[-1];
	my $testname = (split(/\./, $testfilename))[0];

	my @cmdline = ('env', '-C', '..', 'RUN_EINSTEIN=1', 'V=1', 'PIN_FOLLOW_EXECV=0', 'USE_LOG_DIR=1', "LOG_SUB_DIR=$testname", './serverctl', 'start', "-D", "-f", $self->{SRCDIR}."/".$self->{CONFIGFILE}, "-m", $self->{MODULES_PATH});

	splice(@cmdline, -2) if exists $ENV{LIGHTTPD_EXE_PATH};
	if (defined $ENV{"TRACEME"} && $ENV{"TRACEME"} eq 'strace') {
		@cmdline = (qw(strace -tt -s 4096 -o strace -f -v), @cmdline);
	} elsif (defined $ENV{"TRACEME"} && $ENV{"TRACEME"} eq 'truss') {
		@cmdline = (qw(truss -a -l -w all -v all -o strace), @cmdline);
	} elsif (defined $ENV{"TRACEME"} && $ENV{"TRACEME"} eq 'gdb') {
		@cmdline = ('gdb', '--batch', '--ex', 'run', '--ex', 'bt full', '--args', @cmdline);
	} elsif (defined $ENV{"TRACEME"} && $ENV{"TRACEME"} eq 'valgrind') {
		@cmdline = (qw(valgrind --tool=memcheck --track-origins=yes --show-reachable=yes --leak-check=yes --log-file=valgrind.%p), @cmdline);
	}
	diag("\nstarting lighttpd at :".$self->{PORT}.", cmdline: @cmdline\n");
	my $child = fork();
	if (not defined $child) {
		diag("\nFork failed");
		close($SOCK);
		return -1;
	}
	if ($child == 0) {
		#if ($^O eq "MSWin32") {
		if (1) {
			# On platforms where systemd socket activation is not supported
			# or inconvenient for testing (i.e. cygwin <-> native Windows exe),
			# there is a race condition with close() before server start,
			# but port specific port is unlikely to be reused so quickly,
			# and the point is to avoid a port which is already in use.
			close($SOCK);
			my $CONF;
			open($CONF,'>',"$ENV{'SRCDIR'}/tmp/bind.conf") || die "open: $!";
			print $CONF <<BIND_OVERRIDE;
server.systemd-socket-activation := "disable"
server.bind = "127.0.0.1"
server.port = $ENV{'PORT'}
BIND_OVERRIDE
		}
		else {
			# set up systemd socket activation env vars
			$ENV{LISTEN_FDS} = "1";
			$ENV{LISTEN_PID} = $$;
			if (defined($ENV{"TRACEME"}) && $ENV{"TRACEME"} ne "valgrind") {
				$ENV{LISTEN_PID} = "parent:$$"; # lighttpd extension
			}
			listen($SOCK, 1024) || die "listen: $!";
			if (fileno($SOCK) != 3) { # SD_LISTEN_FDS_START 3
				require POSIX;
				POSIX::dup2(fileno($SOCK), 3) || die "dup2: $!";
				close($SOCK);
			}
			else {
				require Fcntl;
				fcntl($SOCK, Fcntl::F_SETFD(), 0); # clr FD_CLOEXEC
			}
		}
		exec @cmdline or die($?);
	}
	close($SOCK);

	if (0 != $self->wait_for_port_with_proc($self->{PORT}, $child)) {
		diag(sprintf('\nThe process %i is not up', $child));
		return -1;
	}
	taint_all();

	$self->{LIGHTTPD_PID} = $child;

	0;
}

sub handle_http {
	EinsteinTests::send_test_info('..');
	my $self = shift;
	my $t = shift;
	my $EOL = "\015\012";
	my $BLANK = $EOL x 2;
	my $host = "127.0.0.1";

	my @request = $t->{REQUEST};
	my @response = $t->{RESPONSE};
	my $slow = defined $t->{SLOWREQUEST};
	my $is_debug = $ENV{"TRACE_HTTP"};

	my $remote =
		IO::Socket::INET->new(
			Proto    => "tcp",
			PeerAddr => $host,
			PeerPort => $self->{PORT});

	if (not defined $remote) {
		diag("\nconnect failed: $!");
		return -1;
	}

	$remote->autoflush(1);

	if (!$slow) {
		diag("\nsending request header to ".$host.":".$self->{PORT}) if $is_debug;
		foreach(@request) {
			# pipeline requests
			s/\r//g;
			s/\n/$EOL/g;

			print $remote $_.$BLANK;
			diag("\n<< ".$_) if $is_debug;
		}
		shutdown($remote, 1) if ($^O ne "openbsd" && $^O ne "dragonfly"); # I've stopped writing data
	} else {
		diag("\nsending request header to ".$host.":".$self->{PORT}) if $is_debug;
		foreach(@request) {
			# pipeline requests
			chomp;
			s/\r//g;
			s/\n/$EOL/g;

			print $remote $_;
			diag("<< ".$_."\n") if $is_debug;
			select(undef, undef, undef, 0.0001);
			print $remote "\015";
			select(undef, undef, undef, 0.0001);
			print $remote "\012";
			select(undef, undef, undef, 0.0001);
			print $remote "\015";
			select(undef, undef, undef, 0.0001);
			print $remote "\012";
			select(undef, undef, undef, 0.0001);
		}

	}
	diag("\n... done") if $is_debug;

	my $lines = "";

	#sleep(1);
	diag("\nreceiving response") if $is_debug;
	# read everything
	while(<$remote>) {
		$lines .= $_;
		diag(">> ".$_) if $is_debug;
	}
	diag("\n... done") if $is_debug;

	close $remote;

	my $full_response = $lines;

	my $href;
	foreach $href ( @{ $t->{RESPONSE} }) {
		# first line is always response header
		my %resp_hdr;
		my $resp_body;
		my $resp_line;
		my $conditions = $_;

		for (my $ln = 0; defined $lines; $ln++) {
			(my $line, $lines) = split($EOL, $lines, 2);

			# header finished
			last if(!defined $line or length($line) == 0);

			if ($ln == 0) {
				# response header
				$resp_line = $line;
			} else {
				# response vars

				if ($line =~ /^([^:]+):\s*(.+)$/) {
					(my $h = $1) =~ tr/[A-Z]/[a-z]/;

					if (defined $resp_hdr{$h}) {
#						diag(sprintf("\nheader '%s' is duplicated: '%s' and '%s'\n",
#						             $h, $resp_hdr{$h}, $2));
						$resp_hdr{$h} .= ', '.$2;
					} else {
						$resp_hdr{$h} = $2;
					}
				} else {
					diag(sprintf("\nunexpected line '%s'", $line));
					return -1;
				}
			}
		}

		if (not defined($resp_line)) {
			diag(sprintf("\nempty response"));
			return -1;
		}

		$t->{etag} = $resp_hdr{'etag'};
		$t->{date} = $resp_hdr{'date'};

		# check length
		if (defined $resp_hdr{"content-length"}) {
			$resp_body = substr($lines, 0, $resp_hdr{"content-length"});
			if (length($lines) < $resp_hdr{"content-length"}) {
				$lines = "";
			} else {
				$lines = substr($lines, $resp_hdr{"content-length"});
			}
			undef $lines if (length($lines) == 0);
		} else {
			$resp_body = $lines;
			undef $lines;
		}

		# check conditions
		if ($resp_line =~ /^(HTTP\/1\.[01]) ([0-9]{3}) .+$/) {
			if ($href->{'HTTP-Protocol'} ne $1) {
				diag(sprintf("\nproto failed: expected '%s', got '%s'", $href->{'HTTP-Protocol'}, $1));
				return -1;
			}
			if ($href->{'HTTP-Status'} ne $2) {
				diag(sprintf("\nstatus failed: expected '%s', got '%s'", $href->{'HTTP-Status'}, $2));
				return -1;
			}
		} else {
			diag(sprintf("\nunexpected resp_line '%s'", $resp_line));
			return -1;
		}

		if (defined $href->{'HTTP-Content'}) {
			$resp_body = "" unless defined $resp_body;
			if ($href->{'HTTP-Content'} ne $resp_body) {
				diag(sprintf("\nbody failed: expected '%s', got '%s'", $href->{'HTTP-Content'}, $resp_body));
				return -1;
			}
		}

		if (defined $href->{'-HTTP-Content'}) {
			if (defined $resp_body && $resp_body ne '') {
				diag(sprintf("\nbody failed: expected empty body, got '%s'", $resp_body));
				return -1;
			}
		}

		foreach (keys %{ $href }) {
			next if $_ eq 'HTTP-Protocol';
			next if $_ eq 'HTTP-Status';
			next if $_ eq 'HTTP-Content';
			next if $_ eq '-HTTP-Content';

			(my $k = $_) =~ tr/[A-Z]/[a-z]/;

			my $verify_value = 1;
			my $key_inverted = 0;

			if (substr($k, 0, 1) eq '+') {
				$k = substr($k, 1);
				$verify_value = 0;
			} elsif (substr($k, 0, 1) eq '-') {
				## the key should NOT exist
				$k = substr($k, 1);
				$key_inverted = 1;
				$verify_value = 0; ## skip the value check
			}

			if ($key_inverted) {
				if (defined $resp_hdr{$k}) {
					diag(sprintf("\nheader '%s' MUST not be set", $k));
					return -1;
				}
			} else {
				if (not defined $resp_hdr{$k}) {
					diag(sprintf("\nrequired header '%s' is missing", $k));
					return -1;
				}
			}

			if ($verify_value) {
				if ($href->{$_} =~ /^\/(.+)\/$/) {
					if ($resp_hdr{$k} !~ /$1/) {
						diag(sprintf(
							"\nresponse-header failed: expected '%s', got '%s', regex: %s",
							$href->{$_}, $resp_hdr{$k}, $1));
						return -1;
					}
				} elsif ($href->{$_} ne $resp_hdr{$k}) {
					diag(sprintf(
						"\nresponse-header failed: expected '%s', got '%s'",
						$href->{$_}, $resp_hdr{$k}));
					return -1;
				}
			}
		}
	}

	# we should have sucked up everything
	if (defined $lines) {
		diag(sprintf("\nunexpected lines '%s'", $lines));
		return -1;
	}

	return 0;
}

sub spawnfcgi {
	EinsteinTests::send_test_info('..');
	my ($self, $binary, $port) = @_;
	my $child = fork();
	if (not defined $child) {
		diag("\nCouldn't fork");
		return -1;
	}
	if ($child == 0) {
		my $iaddr   = inet_aton('localhost') || die "no host: localhost";
		my $proto   = getprotobyname('tcp');
		socket(SOCK, PF_INET, SOCK_STREAM, $proto) || die "socket: $!";
		setsockopt(SOCK, SOL_SOCKET, SO_REUSEADDR, pack("l", 1)) || die "setsockopt: $!";
		bind(SOCK, sockaddr_in($port, $iaddr)) || die "bind: $!";
		listen(SOCK, 1024) || die "listen: $!";
		require POSIX;
		POSIX::dup2(fileno(SOCK), 0) || die "dup2: $!";
		exec { $binary } ($binary) or die($?);
	} else {
		if (0 != $self->wait_for_port_with_proc($port, $child)) {
			diag(sprintf("\nThe process %i is not up (port %i, %s)", $child, $port, $binary));
			return -1;
		}
		return $child;
	}
}

sub endspawnfcgi {
	my ($self, $pid) = @_;
	return -1 if (-1 == $pid);
	kill(2, $pid);
	waitpid($pid, 0);
	return 0;
}

sub has_feature {
	# quick-n-dirty crude parse of "lighttpd -V"
	# (XXX: should be run on demand and only once per instance, then cached)
	my ($self, $feature) = @_;
	my $FH;
	open($FH, "-|",$self->{LIGHTTPD_PATH}, "-V") || return 0;
	while (<$FH>) {
		return ($1 eq '+') if (/([-+]) \Q$feature\E/);
	}
	close $FH;
	return 0;
}

sub has_crypto {
	# quick-n-dirty crude parse of "lighttpd -V"
	# (XXX: should be run on demand and only once per instance, then cached)
	my ($self) = @_;
	my $FH;
	open($FH, "-|",$self->{LIGHTTPD_PATH}, "-V") || return 0;
	while (<$FH>) {
		#return 1 if (/[+] (?i:OpenSSL|mbedTLS|GnuTLS|WolfSSL|Nettle|NSS crypto) support/);
		return 1 if (/[+] (?i:OpenSSL|mbedTLS|GnuTLS|WolfSSL|Nettle) support/);
	}
	close $FH;
	return 0;
}

1;
