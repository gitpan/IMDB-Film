#
# Test for module IMDB::Film
# TODO: Add cache tests 
#
use strict;
use warnings;
use Test::More tests => 33;
use ExtUtils::MakeMaker qw(prompt);

use Data::Dumper;

my %film_info = (
	code    		=> '0332452',
	title   		=> 'Troy',
	year    		=> '2004',
	genres			=> [qw(Action Drama War Adventure Romance)],
	country 		=> [qw(USA Malta UK)],
	language		=> [qw(English)],
	plot			=> qq{An adaptation of Homer's great epic, the film follows the assault on Troy by the united Greek forces and chronicles the fates of the men involved.},								
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

my $full_plot = qq{In the year 1193 B.C., Paris, a prince of Troy woos Helen, Queen of Sparta, away from her husband, Menelaus, setting the kingdoms of Mycenae Greece at war with Troy. The Greeks sail to Troy and lay siege. Achilles was the greatest hero among the Greeks, while Hector, the eldest son of Priam, King of Troy, embodied the hopes of the people of his city.};

require_ok('IMDB::Film');

my $online_test = prompt("\nDo you want to connect to IMDB?", "Y");

SKIP: {
	skip "online test!", 30 if $online_test =~ /^(n|q)/i;

	my $proxy = $ENV{http_proxy} ? $ENV{http_proxy} : 'no';
	$proxy = prompt("\nUse proxy?", "$proxy");
	print "\n";

	print "\nTesting film '$film_info{title}' [$film_info{code}] ...\n\n";

	my %pars = (crit => $film_info{code});
	$pars{proxy} = $proxy if defined $proxy && $proxy !~ /^no/i;
	$pars{cache} = 0;
	$pars{debug} = 0;
	my $film = new IMDB::Film(%pars);
	isa_ok($film, 'IMDB::Film');	
	compare_props($film);	

	$pars{crit} = $film_info{title};
	$film = new IMDB::Film(%pars);
	compare_props($film);
	
	$pars{crit} = 'Con Air';
	$film = new IMDB::Film(%pars);	
	is($film->code, '0118880', 'search code')
};

sub compare_props {
	my $film = shift;

	for my $key ( sort keys %film_info ) {
		my $val = $film_info{$key};	
		if(ref($val)) {
			is_deeply($film->$key, $val, $key);
		} else {
			is($film->$key(), $val, $key);
		}
	}
	my $f_plot = $film->full_plot();
	$f_plot =~ s/\n/ /m;
	$full_plot =~ s/\n/ /m;
	is($f_plot, $full_plot, 'full plot');

	like($film->rating(), qr/\d+\.?\d+/, 'rating (scalar context)');
	my($rating, $val) = $film->rating();
	like($rating, qr/\d+\.?\d+/, 'rating (array context)');
	like($val, qr/\d+/, 'number of votes');
}
