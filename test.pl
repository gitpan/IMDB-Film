#
# Test for module IMDB::Film
# TODO: Add test for film persons and for case find film by its title 
#
use strict;
use warnings;
use Test::More tests => 15;
use ExtUtils::MakeMaker qw(prompt);

my %film_info = (
	Aa => { code    		=> '332452', },
	Ba => { title   		=> 'Troy', },
	Ca => { year    		=> '2004',},
	Da => { genres			=> [qw(Action Drama War Adventure Romance)], },
	Fa => { country 		=> [qw(USA)], },
	Ga => { language		=> [qw(English)], },
	Ia => { certifications	=> { 	Argentina => 13 , 
									Australia=>'MA', 
									Australia=>'M',
									Brazil=>14, 
									Canada=>'14A', 
									Chile=>14, 
									'Czech Republic'=>12,
									Finland=>'K-15',
									France=>'U',
									Germany=>12, 
									Germany=>16,
									'Hong Kong'=>'IIB', 
									Ireland=>15,
									Netherlands=>16,
									Norway=>15,
									Peru=>14,
									Portugal=>'M/12',
									Singapore=>'NC-16',
									Singapore=>'PG',
									Switzerland=>12,
									UK=>15,
									USA=>'R' }, },
	Db => { plot			=> qq{An adaptation of Homer's great epic, the film follows the assault on Troy by the united Greek forces and chronicles the fates of the men involved.} },								
	Cb => { cover			=> qq{http://ia.imdb.com/media/imdb/01/I/54/16/28m.jpg}, },
	Dd => { casts			=> [{ 	id => '0002103', name => 'Julian Glover'},	
								{	id => '0004051', name => 'Brian Cox'},		
								{	id => '0428923', name => 'Nathan Jones'},	
								{	id => '0549539', name => 'Adoni Maropis'},									
								{	id => '0808559', name => 'Jacob Smith'},		
								{	id => '0000093', name => 'Brad Pitt'},		
								{	id => '0795344', name => 'John Shrapnel'},	
								{	id => '0322407', name => 'Brendan Gleeson'},	
								{	id => '1208167', name => 'Diane Kruger'},	
								{	id => '0051509', name => 'Eric Bana'},		
								{	id => '0089217', name => 'Orlando Bloom'},	
								{	id => '1595495', name => 'Siri Svegler'},	
								{	id => '1595480', name => 'Lucie Barat'},		
								{	id => '0094297', name => 'Ken Bones'},		
								{	id => '0146439', name => 'Manuel Cauchi'} ] },

	Cd => { directors		=> [{id => '0000583', name => 'Wolfgang Petersen'}] },
	Ce => { writers			=> [{id => '0392955', name => 'Homer'}, 
								{id => '1125275', name => 'David Benioff'}] },

	);							

require_ok('IMDB::Film');

my $online_test = prompt("\nDo you want to connect to IMDB?", "Y");

SKIP: {
	skip "online test!", 14 if $online_test =~ /^(n|q)/i;

	print "\nTesting film '$film_info{Ba}{title}' [$film_info{Aa}{code}] ...\n";

	my $proxy = $ENV{http_proxy} ? $ENV{http_proxy} : 'no';
	$proxy = prompt("\nUse proxy?", "$proxy");
	print "\n";

	my %pars = (crit => $film_info{Aa}{code});
	$pars{proxy} = $proxy if defined $proxy && $proxy !~ /^no/i;
	$pars{cache} = 0;
	$pars{debug} = 1;
	my $film = new IMDB::Film(%pars);

	isa_ok($film, 'IMDB::Film');

	for my $item ( sort keys %film_info ) {
		my ($key, $val) = each %{ $film_info{$item} };
		
		if(ref($val)) {
			is_deeply($film->$key, $val, $key);
		} else {
			is($film->$key(), $val, $key);
		}
	}

	like($film->rating(), qr/\d+\.\d+/, 'rating');
};
