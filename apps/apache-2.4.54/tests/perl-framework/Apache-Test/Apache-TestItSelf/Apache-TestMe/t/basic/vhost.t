use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY_ASSERT';

my $module = 'TestBasic::Vhost';
my $url    = Apache::TestRequest::module2url($module);
t_debug("connecting to $url");
print GET_BODY_ASSERT $url;
