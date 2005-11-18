use strict;

use Test::More tests => 1;
use IMDB::Film;


my $crit = 'Con Air';
my %pars = (cache => 0, debug => 0, crit => $crit);

my $obj = new IMDB::Film(%pars);

$obj = new IMDB::Film(%pars);	
is($obj->code, '0118880', 'search code');

