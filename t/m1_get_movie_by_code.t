use strict;
use warnings;

use Test::More tests => 12;

use IMDB::Film;

my $crit = '0332452';
my %films = (
		code    		=> '0332452',
		id 		   		=> '0332452',
		title   		=> 'Troy',
		year    		=> '2004',
		genres			=> [qw(Action Drama War Adventure Romance)],
		country 		=> [qw(USA Malta UK)],
		language		=> [qw(English)],
		plot			=> qq{An adaptation of Homer's great epic, the film follows the assault on Troy by the united Greek forces and chronicles the fates of the men involved.},
		full_plot		=> qq{In the year 1193 B.C., Paris, a prince of Troy woos Helen, Queen of Sparta, away from her husband, Menelaus, setting the kingdoms of Mycenae Greece at war with Troy. The Greeks sail to Troy and lay siege. Achilles was the greatest hero among the Greeks, while Hector, the eldest son of Priam, King of Troy, embodied the hopes of the people of his city.},
		cover			=> qq{http://ia.imdb.com/media/imdb/01/I/21/65/48m.jpg},
		cast			=> [{ 	id => '0002103', name => 'Julian Glover', role => 'Triopas'},	
							{	id => '0004051', name => 'Brian Cox', role => 'Agamemnon'},	
							{	id => '0428923', name => 'Nathan Jones', role => 'Boagrius'},	
							{	id => '0549539', name => 'Adoni Maropis', role => 'Agamemnon\'s Officer'},	  						
							{	id => '0808559', name => 'Jacob Smith',	role => 'Messenger Boy'},	
							{	id => '0000093', name => 'Brad Pitt',	role => 'Achilles'},	
							{	id => '0795344', name => 'John Shrapnel', role => 'Nestor'},	
							{	id => '0322407', name => 'Brendan Gleeson',	 role => 'Menelaus'},	
							{	id => '1208167', name => 'Diane Kruger', role => 'Helen'},	
							{	id => '0051509', name => 'Eric Bana', role => 'Hector'},	
							{	id => '0089217', name => 'Orlando Bloom', role => 'Paris'},	
							{	id => '1595495', name => 'Siri Svegler', role => 'Polydora'},	
							{	id => '1595480', name => 'Lucie Barat',	 role => 'Helen\'s Handmaiden'},	
							{	id => '0094297', name => 'Ken Bones', role => 'Hippasus'},	
							{	id => '0146439', name => 'Manuel Cauchi', role => 'Old Spartan Fisherman'},
					],

		directors		=> [{id => '0000583', name => 'Wolfgang Petersen'}],
		writers			=> [{id => '0392955', name => 'Homer'}, 
							{id => '1125275', name => 'David Benioff'}],
);

my %pars = (cache => 0, debug => 0, crit => $crit);

my $obj = new IMDB::Film(%pars);
isa_ok($obj, 'IMDB::Film');	

is($obj->code, $films{code}, 'Movie IMDB Code');
is($obj->id, $films{id}, 'Movie IMDB ID');
is($obj->title, $films{title}, 'Movie Title');
is($obj->year, $films{year}, 'Movie Production Year');
like($obj->plot, qr/$films{plot}/, 'Movie Plot');
like($obj->cover, qr/$films{cover}/, 'Movie Cover');
is_deeply($obj->cast, $films{cast}, 'Movie Cast');
is($obj->language->[0], $films{language}[0], 'Movie Language');
is($obj->country->[0], $films{country}[0], 'Movie Country');
is($obj->genres->[0], $films{genres}[0], 'Movie Genre');
like($obj->full_plot, qr/$films{full_plot}/, 'Movie full plot');
