use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_write_file t_start_error_log_watch t_finish_error_log_watch t_cmp);

use File::Spec;

use Time::HiRes qw(usleep);

# test ap_expr

Apache::TestRequest::user_agent(keep_alive => 1);

# The left-hand values are written into the config file as-is, i.e.
# necessary quoting for the config file parser needs to be included
# explicitly.
my @test_cases = (
    [ 'foo'                     => 'foo'                ],
    [ '%{req:SomeHeader}'       => 'SomeValue'          ],
    [ '%{'                      => undef                ],
    [ '%'                       => '%'                  ],
    [ '}'                       => '}'                  ],
    [ q{\"}                     => q{"}                 ],
    [ q{\'}                     => q{'}                 ],
    [ q{"\%{req:SomeHeader}"}   => '%{req:SomeHeader}'  ],
    [ '%{tolower:IDENT}'                => 'ident'      ],
    [ '%{tolower:%{REQUEST_METHOD}}'    => 'get'        ],
);

if (have_min_apache_version("2.5")) {
    my $SAN_one         = "email:<redacted1>, email:<redacted2>, " .
                          "IP Address:127.0.0.1, IP Address:0:0:0:0:0:0:0:1, " .
                          "IP Address:192.168.169.170";
    my $SAN_tuple       = "'email:<redacted1>', 'email:<redacted2>', " .
                          "'IP Address:127.0.0.1', 'IP Address:0:0:0:0:0:0:0:1', " .
                          "'IP Address:192.168.169.170'";
    my $SAN_list_one    = "{ '$SAN_one' }";
    my $SAN_list_tuple  = "{ $SAN_tuple }";

    push(@test_cases, (
        [ qq["%{tolower:%{:toupper(%{REQUEST_METHOD}):}}"]  => "get"        ],
        [ qq["%{: join $SAN_list_one :}"]                   => "$SAN_one"   ],
        [ qq["%{: join($SAN_list_tuple, ', ') :}"]          => "$SAN_one"   ],
        [ qq['%{tolower:"IDENT"}']                          => '"ident"'    ],
        [ qq["%{: 'IP Address:%{REMOTE_ADDR}' -in split/, /, join $SAN_list_one :}"]
                                                            => "true"       ],
    ));
}

my $successful_expected = scalar(grep { defined $_->[1] } @test_cases);

plan tests => scalar(@test_cases) * 2 + $successful_expected,
                  need need_lwp,
                  need_module('mod_log_debug');
foreach my $t (@test_cases) {
    my ($expr, $expect) = @{$t};

    write_htaccess($expr);

    t_start_error_log_watch();
    my $response = GET('/apache/expr/index.html',
                       'SomeHeader' => 'SomeValue',
                       'User-Agent' => 'SomeAgent',
                       'Referer'    => 'SomeReferer');
    ### Sleep here, attempt to avoid intermittent failures.
    usleep(250000);
    my @loglines = t_finish_error_log_watch();

    my @evalerrors = grep {/(?:internal evaluation error|flex scanner jammed)/i
        } @loglines;
    my $num_errors = scalar @evalerrors;
    print "Error log should not have 'Internal evaluation error' or " .
          "'flex scanner jammed' entries, found $num_errors:\n@evalerrors\n"
       if $num_errors;
    ok($num_errors == 0);

    my $rc = $response->code;

    if (!defined $expect) {
        print qq{Should get parse error (500) for "$expr", got $rc\n};
        ok($rc == 500);
    }
    else {
        print qq{Expected return code 200, got $rc for '$expr'\n};
        ok($rc == 200);
        my @msg = grep { /log_debug:info/ } @loglines;
        if (scalar @msg != 1) {
            print "expected 1 message, got " . scalar @msg . ":\n@msg\n";
            ok(0);
        }
        elsif ($msg[0] =~ m{^(?:\[                  # opening '['
                                 [^\]]+             # anything but a ']'
                                \]                  # closing ']'
                               [ ]                  # trailing space
                             ){4}                   # repeat 4 times (timestamp, level, pid, client IP)
                             (.*?)                  # The actual message logged by LogMessage
                             (,[ ]referer           # either trailing referer (LogLevel info)
                             |                      # or
                             [ ]\(log_transaction)  # trailing hook info (LogLevel debug and higher)
                           }x ) {
            my $result = $1;
            ok t_cmp($result, $expect, "log message @msg didn't match");
        }
        else {
            print "Can't extract expr result from log message:\n@msg\n";
            ok(0);
        }
    }
}

exit 0;

### sub routines
sub write_htaccess
{
    my $expr = shift;
    my $file = File::Spec->catfile(Apache::Test::vars('serverroot'), 'htdocs', 'apache', 'expr', '.htaccess');
    t_write_file($file, << "EOF" );
LogMessage $expr
EOF
}
