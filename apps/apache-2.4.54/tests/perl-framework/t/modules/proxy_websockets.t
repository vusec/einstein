use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;
use Apache::TestConfig ();

# not reliable, hangs for some people:
# my @test_cases = ( "ping0", "ping1" x 10, "ping2" x 100, "ping3" x 1024, "ping4" x 4096,  "sendquit");
my @test_cases = ( "ping0", "ping1" x 10, "ping2" x 100, "ping3" x 1024, "sendquit");
my $total_tests = 2;

plan tests => $total_tests, need 'AnyEvent::WebSocket::Client',
    need_module('proxy_http', 'lua'), need_min_apache_version('2.4.47');

require AnyEvent;
require AnyEvent::WebSocket::Client;

my $config = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport();

my $client = AnyEvent::WebSocket::Client->new(timeout => 5);

my $quit_program = AnyEvent->condvar;

my $responses = 0;
my $surprised = 0;

$client->connect("ws://$hostport/proxy/wsoc")->cb(sub {
  our $connection = eval { shift->recv };
  t_debug("wsoc connected");
  if($@) {
    # handle error...
    warn $@;
    $quit_program->send();
    return;
  }


  # AnyEvent::WebSocket::Connection does not pass the PONG message down to the callback
  # my $actualpingmsg = AnyEvent::WebSocket::Message->new(opcode => 0x09, body => "xxx");
  # $connection->send($actualpingmsg);

  foreach (@test_cases){ 
    $connection->send($_);
  }

  $connection->on(finish => sub {
    t_debug("finish");
  });
  
  # recieve message from the websocket...
  $connection->on(each_message => sub {
    # $connection is the same connection object
    # $message isa AnyEvent::WebSocket::Message
    my($connection, $message) = @_;
    $responses++;
    t_debug("wsoc msg received: " . substr($message->body, 0, 5). " opcode " . $message->opcode);
    if ("sendquit" eq $message->body) { 
      $connection->send('quit');
      t_debug("closing");
      $connection->close; # doesn't seem to close TCP.
      $quit_program->send();
    }
    elsif ($message->body =~ /^ping(\d)/) { 
      my $offset = $1;
      if ($message->body ne $test_cases[$offset]) { 
          $surprised++;
      }
    }
    else { 
        $surprised++;
    }
  });

});

$quit_program->recv;
ok t_cmp($surprised, 0);
ok t_cmp($responses, scalar(@test_cases) );
