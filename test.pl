#
# Test for module IMDB::Film
# TODO: Add cache tests 
#
use strict;
use warnings;
use Test::More tests => 84;
use ExtUtils::MakeMaker qw(prompt);

use Data::Dumper;

my %films = (
	'0332452' => {
		code    		=> '0332452',
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
	},

	'0118694' => {
		code			=> '0118694',
        lookup_title	=> 'In the Mood for Love',
        title           => 'Fa yeung nin wa',
       	year            => '2000',
        genres         	=> [qw(Romance Drama)],
        country         => ['Hong Kong', 'France', 'Thailand'],
        language        => [qw(Cantonese Shanghainese French)],
        plot            => qq{A man and a woman move in to neighboring Hong Kong apartments and form a bond when they both suspect their spouses of extra-marital activities.},
        full_plot       => qq{Set in Hong Kong, 1962, Chow Mo-Wan is a newspaper editor who moves into a new building with his wife. At approximately the same time, Su Li-zhen, a beautiful secretary and her executive husband also move in to the crowded building. With their spouses often away, Chow and Li-zhen spend most of their time together as friends. They have everything in common from noodle shops to martial arts. Soon, they are shocked to discover that their spouses are having an affair. Hurt and angry, they find comfort in their growing friendship even as they resolve not to be like their unfaithful mates.},
        cover           => qq{http://ia.imdb.com/media/imdb/01/I/16/79/02m.jpg},
        cast            => [{   	id => '0504897', name => 'Tony Leung Chiu Wai', role => 'Chow Mo-wan'},
							{       id => '0001041', name => 'Maggie Cheung', role => 'Su Li-zhen Chan'},
							{       id => '0803310', name => 'Ping Lam Siu', role => 'Ah Ping'},
							{       id => '0156432', name => 'Tung Cho \'Joe\' Cheung', role => 'Special Appearance (as Cheun Tung Joe)'},
							{       id => '0659029', name => 'Rebecca Pan', role => 'Mrs. Suen'},
							{       id => '0155296', name => 'Lai Chen',   role => 'Mr. Ho'},
							{       id => '0151014', name => 'Man-Lei Chan', role => undef},
							{       id => '0465499', name => 'Kam-wah Koo', role => undef},
							{       id => '0156559', name => 'Roy Cheung', role => 'Mr. Chan (voice)'},
							{       id => '0156879', name => 'Chi-ang Chi', role => 'The Amah'},
							{       id => '0950499', name => 'Hsien Yu', role => undef},
							{       id => '0159493', name => 'Po-chun Chow', role => undef},
							{       id => '0837282', name => 'Paulyn Sun',  role => 'Mrs. Chow (voice)'},
							{       id => '0939233', name => 'Man-lei Wong', role => 'Kam-wah, Koo'},
                          ],

      	directors       => [{id => '0939182', name => 'Kar Wai Wong'}],
        writers         => [{id => '0939182', name => 'Kar Wai Wong'}],
	}
);

my %person_info = (
	code                    => '0000129',
	name                    => qq{Tom Cruise},
	mini_bio                => qq{In 1976, if you had told 14 year old Franciscan seminary student Thomas...},
	date_of_birth   => qq{3 July 1962},
	place_of_birth  => qq{Syracuse, New York, USA}, 
	photo                   => 'http://ia.imdb.com/media/imdb/01/I/51/45/38m.jpg',
);

use_ok('IMDB::Film');
use_ok('IMDB::Persons');

my $online_test = prompt("\nDo you want to connect to IMDB?", "Y");

SKIP: {
	skip "online test!", 81 if $online_test =~ /^(n|q)/i;

    my %pars = ();
	foreach my $id (keys %films) {
		my %film_info = %{ $films{$id} };

		print "\nTesting search a movie by its code [$film_info{code}] ...\n\n";
		%pars = (crit => $film_info{code});
		# $pars{proxy} = $proxy if defined $proxy && $proxy !~ /^no/i;
		$pars{cache} = 0;
		$pars{debug} = 0;
		my $film = new IMDB::Film(%pars);
		isa_ok($film, 'IMDB::Film');	
		compare_props($film, $id);

		print "\nTesting search a movie by its title [$film_info{title}] (many matched results) ...\n\n";
		$pars{crit} = $film_info{lookup_title} || $film_info{title};
		$film = new IMDB::Film(%pars);
		compare_props($film, $id);
	}	

	print "\nTesting search a movie by its title [Con Air] (one matched result) ...\n\n";
	$pars{crit} = 'Con Air';
	my $film = new IMDB::Film(%pars);	
	is($film->code, '0118880', 'search code');

	print "\nTesttin search a movie without rating ...\n";
	$pars{crit} = 'jonny zer';
	$film = new IMDB::Film(%pars);
	is($film->code, '0412158', 'search code');

	print "\nTesting search a movie with complete credited casts ...\n";
	$pars{crit} = '0072567';
	$film = new IMDB::Film(%pars);
	is_deeply($film->cast->[0], {id => '0815800', name => 'David Soul', role => 'Det. Ken "Hutch" Hutchinson'}, 'casts');

	print "\nTesting search IMDB person by its code [$person_info{code}] ...\n\n";
	$pars{crit} = $person_info{code};
	my $person = new IMDB::Persons(%pars);
	isa_ok($person, 'IMDB::Persons');       
	test_person($person);

	print "\nTesting search IMDB person by its name [$person_info{name}] ...\n\n";
	$pars{crit} = $person_info{name};
	$person = new IMDB::Persons(%pars);
	test_person($person);

	print "\nFinished!\n";
};

sub compare_props {
	my $film = shift;
	my $id   = shift;

        my %film_info = %{ $films{$id} };
	for my $key ( sort keys %film_info ) {
		next if $key eq 'lookup_title';
		my $val = $film_info{$key};	
		if(ref($val)) {
			is_deeply($film->$key, $val, $key);
		} else {
			is($film->$key(), $val, $key);
		}
	}
	my $f_plot = $film->full_plot();
	$f_plot =~ s/\n/ /m;
	$film_info{full_plot} =~ s/\n/ /m;
	is($f_plot, $film_info{full_plot}, 'full plot');

	like($film->rating(), qr/\d+\.?\d+/, 'rating (scalar context)');
	my($rating, $val) = $film->rating();
	like($rating, qr/\d+\.?\d+/, 'rating (array context)');
	like($val, qr/\d+/, 'number of votes');
}

sub test_person {
	my $p = shift;

	is($p->code, $person_info{code}, 'code');
	is($p->name, $person_info{name}, 'name');
	is($p->date_of_birth, $person_info{date_of_birth}, 'date_of_birth');
	is($p->place_of_birth, $person_info{place_of_birth}, 'place_of_birth');
	is($p->mini_bio, $person_info{mini_bio}, 'mini_bio');
	is($p->photo, $person_info{photo}, 'photo');
}

