use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;
use Apache::TestConfig ();

my @echos = ('A'x8, 'A'x64, 'A'x2048, 'A'x4096);

my $skipbodyfailover = !need_min_apache_version("2.4.42");
my $referertest = 0;

if (have_min_apache_version("2.4.41")) {
  $referertest = 2;
}

plan tests => 6+(2*scalar @echos)+$referertest, need 'proxy_balancer', 'proxy_http';

Apache::TestRequest::module("proxy_http_balancer");
Apache::TestRequest::user_agent(requests_redirectable => 0);

# Extract the nonce from response to the URL
sub GetNonce {
  my $url = shift;
  my $balancer = shift;
  my $r;
  $r = GET($url);
  my $NONCE;
  foreach my $query ( split( /\?b=/, $r->content ) ){
    if ($query =~ m/$balancer/) {
      foreach my $var ( split( /&amp;/, $query ) ){
        if ($var =~ m/nonce=/) {
          foreach my $nonce ( split( /nonce=/, $var ) ){
            my $ind = index ($nonce, "\"");
            $nonce = substr($nonce, 0, ${ind});
            if ( $nonce =~ m/^[0-9a-fA-F-]+$/ ) {
              $NONCE = $nonce;
              last;
            }
          }
          last;
        }
      }
    last;
    }
  }
  return $NONCE;
}

my $r;

if (have_module('lbmethod_byrequests')) {
    $r = GET("/baltest1/index.html");
    ok t_cmp($r->code, 200, "Balancer did not die");
} else {
    skip "skipping tests without mod_lbmethod_byrequests" foreach (1..1);
}

if (have_module('lbmethod_bytraffic')) {
    $r = GET("/baltest2/index.html");
    ok t_cmp($r->code, 200, "Balancer did not die");
} else {
    skip "skipping tests without mod_lbmethod_bytraffic" foreach (1..1);
}

if (have_module('lbmethod_bybusyness')) {
    $r = GET("/baltest3/index.html");
    ok t_cmp($r->code, 200, "Balancer did not die");
} else {
    skip "skipping tests without mod_lbmethod_bybusyness" foreach (1..1);
}

if (have_module('lbmethod_heartbeat')) {
    #$r = GET("/baltest4/index.html");
    #ok t_cmp($r->code, 200, "Balancer did not die");
} else {
    #skip "skipping tests without mod_lbmethod_heartbeat" foreach (1..1);
}



# PR63891
foreach my $t (@echos) {
    $r = POST "/baltest_echo_post", content => $t;
    skip $skipbodyfailover, t_cmp($r->code, 200, "failed over");
    skip $skipbodyfailover, t_cmp($r->content, $t, "response body echoed");
}

# test dynamic part
$r = GET("/balancer-manager");
ok t_cmp($r->code, 200, "Can't find balancer-manager");

# get the nonce and add a worker
my $result = GetNonce("/balancer-manager", "dynproxy");

my $query = "b_lbm=byrequests&b_tmo=0&b_max=0&b_sforce=0&b_ss=&b_nwrkr=ajp%3A%2F%2F%5B0%3A0%3A0%3A0%3A0%3A0%3A0%3A1%5D%3A8080&b_wyes=1&b=dynproxy&nonce=" . $result;
my @proxy_balancer_headers;
my $vars   = Apache::Test::vars();
push @proxy_balancer_headers, "Referer" => "http://" . $vars->{servername} . ":" . $vars->{port} . "/balancer-manager";

# First try without the referer it should fail.
if (have_min_apache_version("2.4.41")) {
  $r = POST("/balancer-manager", content => $query);
  ok t_cmp($r->code, 200, "request failed");
  ok !t_cmp($r->content, qr/ajp/, "AJP worker created");
}

# Try with the referer and http (byrequests)
if (have_min_apache_version("2.4.49") && have_module('lbmethod_byrequests')) {
  $r = GET("/dynproxy");
  ok t_cmp($r->code, 503, "request should fail for /dynproxy");
  # create it
  $query = 'b_lbm=byrequests&b_tmo=0&b_max=0&b_sforce=0&b_ss=&b_nwrkr=http%3A%2F%2F' . $vars->{servername} . '%3A' . $vars->{port} . '&b_wyes=1&b=dynproxy&nonce=' . $result;
  $r = POST("/balancer-manager", content => $query, @proxy_balancer_headers);
  # enable it.
  $query = 'w=http%3A%2F%2F' . $vars->{servername} . '%3A' . $vars->{port} . '&b=dynproxy&w_status_D=0&nonce=' . $result;
  $r = POST("/balancer-manager", content => $query, @proxy_balancer_headers);
  # make a query
  $r = GET("/dynproxy");
  ok t_cmp($r->code, 200, "request failed to /dynproxy");
} else {
    skip "skipping tests without lbmethod_byrequests";
    skip "skipping tests without lbmethod_byrequests";
}
