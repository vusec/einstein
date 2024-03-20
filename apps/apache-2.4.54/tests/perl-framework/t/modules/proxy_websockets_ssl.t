use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;
use Apache::TestConfig ();

# my @test_cases = ( "ping0", "ping1" x 10, "ping2" x 100, "ping3" x 1024, "ping4" x 4000,  "sendquit");
my @test_cases = ( "ping0", "ping1" x 10, "ping2" x 100, "ping3" x 1024,  "sendquit");
my $total_tests = 2;

plan tests => $total_tests, need 'AnyEvent::WebSocket::Client',
    need_module('ssl', 'proxy_http', 'lua'), need_min_apache_version('2.4.47');

require AnyEvent;
require AnyEvent::WebSocket::Client;

my $config = Apache::Test::config();
#my $hostport = $config->{vhosts}->{proxy_https_https}->{hostport};
my $hostport = $config->{vhosts}->{$config->{vars}->{ssl_module_name}}->{hostport};
my $client = AnyEvent::WebSocket::Client->new(timeout => 5, ssl_ca_file => $config->{vars}->{sslca} . "/" . $config->{vars}->{sslcaorg}  . "/certs/ca.crt");

my $quit_program = AnyEvent->condvar;

my $responses = 0;
my $surprised = 0;

t_debug("wss://$hostport/modules/lua/websockets.lua");

# $client->connect("wss://$hostport/proxy/wsoc")->cb(sub {
$client->connect("wss://$hostport/modules/lua/websockets.lua")->cb(sub {
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
    $quit_program->send();
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
          t_debug("wrong data");
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
# We don't expect the 20k over SSL to work, and we won't read the "sendquit" echoed back either.
ok t_cmp($responses, scalar(@test_cases));
