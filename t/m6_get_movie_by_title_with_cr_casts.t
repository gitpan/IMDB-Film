use strict;

use Test::More tests => 1;
use IMDB::Film;

my $crit = '0072567';
my %pars = (cache => 0, debug => 0, crit => $crit);

my $obj = new IMDB::Film(%pars);

is_deeply($obj->cast->[1], {id => '0815800', name => 'David Soul', role => 'Det. Ken "Hutch" Hutchinson'}, 'casts');

