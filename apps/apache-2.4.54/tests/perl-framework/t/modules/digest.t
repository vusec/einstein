use lib "$ENV{'ROOT'}/apps/scripts/perl-tests"; require EinsteinTests; EinsteinTests::send_string("../..", __FILE__.":".__LINE__); sleep(1);
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp t_write_file);
use File::Spec;

plan tests => 13, need need_lwp,
                       need_module('mod_auth_digest'),
                       need_min_apache_version('2.0.51');

my ($no_query_auth, $query_auth, $bad_query);

# write out the authentication file
my $file = File::Spec->catfile(Apache::Test::vars('serverroot'), 'realm1');
t_write_file($file, <DATA>);

my $url   = '/digest/index.html';
my $query = 'try=til%7Ede';

{
  my $response = GET $url;

  ok t_cmp($response->code,
           401,
           'no user to authenticate');
}

{
  # bad pass
  my $response = GET $url,
                   username => 'user1', password => 'foo';

  ok t_cmp($response->code,
           401,
           'user1:foo not found');
}

{
  # authenticated
  my $response = GET $url,
                   username => 'user1', password => 'password1';

  ok t_cmp($response->code,
           200,
           'user1:password1 found');

  # set up for later
  $no_query_auth = $response->request->headers->authorization;
}

# now that we know normal digest auth works, play with the query string

{
  # add a query string
  my $response = GET "$url?$query",
                   username => 'user1', password => 'password1';

  ok t_cmp($response->code,
           200,
           'user1:password1 with query string found');

  # set up for later
  $query_auth = $response->request->headers->authorization;
}

{
  # do the auth header ourselves
  my $response = GET "$url?$query", Authorization => $query_auth;

  ok t_cmp($response->code,
           200,
           'manual Authorization header query string');
}

{
  # remove the query string from the uri - bang!
  (my $noquery = $query_auth) =~ s!$query!!;

  my $response = GET "$url?$query",
                   Authorization => $noquery;

  ok t_cmp($response->code,
           400,
           'manual Authorization with no query string in header');
}

{
  # same with changing the query string in the header
  ($bad_query = $query_auth) =~ s!$query!something=else!;

  my $response = GET "$url?$query",
                   Authorization => $bad_query;

  ok t_cmp($response->code,
           400,
           'manual Authorization header with mismatched query string');
}

{
  # another mismatch
  my $response = GET $url,
                   Authorization => $query_auth;

  ok t_cmp($response->code,
           400,
           'manual Authorization header with mismatched query string');
}

# finally, the MSIE tests

{
  if (have_min_apache_version("2.5.0")) {
    skip "'AuthDigestEnableQueryStringHack' has been removed in r1703305";
  } 
  else  
  {
    # fake current MSIE behavior - this should work as of 2.0.51
    my $response = GET "$url?$query",
                     Authorization => $no_query_auth, 
                     'X-Browser'   => 'MSIE';
  
    ok t_cmp($response->code,
             200,
             'manual Authorization with no query string in header + MSIE');
  }
}

{
  # pretend MSIE fixed itself
  my $response = GET "$url?$query",
                   username    => 'user1', password => 'password1', 
                   'X-Browser' => 'MSIE';

  ok t_cmp($response->code,
           200,
           'a compliant response coming from MSIE');
}

{
  # this still bombs
  my $response = GET "$url?$query",
                   Authorization => $bad_query, 
                   'X-Browser'   => 'MSIE';

  ok t_cmp($response->code,
           400,
           'manual Authorization header with mismatched query string + MSIE');
}

{
  # as does this
  my $response = GET $url,
                   Authorization => $query_auth,
                   'X-Browser'   => 'MSIE';

  ok t_cmp($response->code,
           400,
           'manual Authorization header with mismatched query string + MSIE');
}

{
  # no hack required
  my $response = GET $url,
                   username => 'user1', password => 'password1', 
                   'X-Browser' => 'MSIE';

  ok t_cmp($response->code,
           200,
           'no query string + MSIE');
}

__DATA__
# user1/password1
user1:realm1:4b5df5ee44449d6b5fbf026a7756e6ee
