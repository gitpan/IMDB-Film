use strict;
use warnings;

use Test::More tests => 14;

use IMDB::Film;

my $crit = 'Troy';
my %films = (
		code    		=> '0332452',
		id 		   		=> '0332452',
		title   		=> 'Troy',
		year    		=> '2004',
		genres			=> [qw(Action Drama War Adventure Romance)],
		country 		=> [qw(USA Malta UK)],
		language		=> [qw(English)],
		plot			=> qq{An adaptation of Homer's great epic, the film follows the assault on Troy by the united Greek forces and chronicles the fates of the men involved.},
		full_plot		=> qq{It is the year 1250 B.C. during the late Bronze age. Two emerging nations begin to clash after Paris, the Trojan prince, convinces Helen, Queen of Sparta, to leave her husband Menelaus, and sail with him back to Troy. After Menelaus finds out that his wife was taken by the Trojans, he asks his brother Agamemnom to help him get her back. Agamemnon sees this as an opportunity for power. So they set off with 1,000 ships holding 50,000 Greeks to Troy. With the help of Achilles, the Greeks are able to fight the never before defeated Trojans. But they come to a stop by Hector, Prince of Troy. The whole movie shows their battle struggles, and the foreshadowing of fate in this remake by Wolfgang Petersen of Homer's "The Iliad."},
		cover			=> qq{/images/M/MV5BMTU1MjM4NTA5Nl5BMl5BanBnXkFtZTcwOTE3NzA1MQ@@._V1._SX100_SY114_.jpg},
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
		duration		=> '163 min',
		aspect_ratio	=> '2.35 : 1',
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
is($obj->duration, $films{duration}, 'Movie Duration');
is($obj->aspect_ratio, $films{aspect_ratio}, 'Movie Aspect Ratio');
