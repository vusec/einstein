package EinsteinTests;

$last_str = "NONE";

sub send_string {
        my ($serverctldir, $s) = @_;
        if ( $s eq $last_str ) {
                # No need to send over the same string twice in a row
                #print(STDERR "== cmdsvr setdebugstr: $s ----> (SKIPPED)\n");
                return;
        }
        #print(STDERR "== cmdsvr setdebugstr: $s\n");
        $last_str = $s;
        system("env -C $serverctldir ./serverctl udscmd pids dbt setdebugstr $s");
}

sub send_test_info {
        my ($serverctldir) = @_;
        my $filename = "FILENAME_ERROR";
        my $linenum  = "LINENUM_ERROR";
        my $funcname = "FUNCNAME_ERROR";
        my $i = 0;
        while ( (my @call_details = (caller($i++))) ){
                $filename = $call_details[1];
                $linenum  = $call_details[2];
                $funcname = $call_details[3];
                last if ($filename =~ m/\.t$/);
        }
        my $testinfo = $filename.":".$linenum.":".$funcname;
        send_string($serverctldir, $testinfo);
}

1;
