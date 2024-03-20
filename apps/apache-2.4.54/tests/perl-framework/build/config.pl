#!/usr/bin/perl -w

use strict;
use FindBin qw($Bin);
use lib "$Bin/../Apache-Test/lib";

use Apache::TestConfig ();

print Apache::TestConfig::as_string();
