=head1 NAME

IMDB::Film - OO Perl interface to the movies database IMDB.

=head1 VERSION

IMDB::Film 0.01

=head1 SYNOPSIS

	use IMDB;

	my $imdbObj = new IMDB::Film(crit => 227445);

	or

	my $imdbObj = new IMDB::Film(crit => 'Troy');

	print "Title: ".$imdbObj->title()."\n";
	print "Year: ".$imdbObj->year()."\n";
	print "Plot Symmary: ".$imdbObj->plot()."\n";

=head1 DESCRIPTION

=head2 Overview

IMDB::Film is an object-oriented interface to the IMDB.
You can use that module to retrieve information about film:
title, year, plot etc. 

=cut
package IMDB::Film;

use strict;
use warnings;

use base qw(IMDB::BaseClass);

use HTML::TokeParser;
use LWP::UserAgent;
use Cache::FileCache;
use Carp;

use Data::Dumper;

use fields qw(	_title
				_year
				_summary
				_cast
				_directors
				_writers
				_cover
				_language
				_country
				_rating
				_genres
				_tagline
				_plot
				_certifications
				_duration
				_full_plot
		);
	
use vars qw( $VERSION %FIELDS %FILM_CERT );

use constant CLASS_NAME => 'IMDB::Film';
use constant FORCED		=> 1;
use constant USE_CACHE	=> 1;
use constant DEBUG_MOD	=> 1;

BEGIN {
		$VERSION = '0.10';
						
		# Convert age gradation to the digits		
		# TODO: Store this info into constant file
		%FILM_CERT = ( 	G 		=> 'All', 
						R 		=> 16, 
						'NC-17' => 16, 
						PG 		=> 13, 
						'PG-13' => 13 );					
}

{
	my $_objcount = 0;

	sub get_objcount { $_objcount }
	sub _incr_objcount { ++$_objcount }
	sub _decr_objcount { --$_objcount }	
}

=head2 Constructor and initialization

=over 4

=item new()

Object's constructor. You should pass as parameter movie title or IMDB code.

	my $imdb = new IMDB::Film(crit => <some code>);

or	

	my $imdb = new IMDB::Film(crit => <some title>);

Also, you can specify following optional parameters:
	
	- proxy - define proxy server name and port;
	- debug	- switch on debug mode (on by default);
	- cache - cache or not of content retrieved pages.

=item _init()

Initialize object.

=cut
sub _init {
	my CLASS_NAME $self = shift;
	my %args = @_;

	croak "Film IMDB ID or Title should be defined!" 
								if !defined $args{crit} or $args{crit} eq '';									

	
	$self->SUPER::_init(%args);
	
	$self->title(FORCED);

	for my $prop (grep { /^_/ && !/^(_title|_code)$/ } sort keys %FIELDS) {
		($prop) = $prop =~ /^_(.*)/;
		$self->$prop(FORCED);
	}
}

=back

=head2 Object Private Methods

=over 4

=item _search_film()

Implemets functionality to search film by name.

=cut
sub _search_film {
	my CLASS_NAME $self = shift;

	return $self->SUPER::_search_results('\/title\/tt(\d+)');

}

=back

=head2 Object Public Methods

=over 4

=item title()

Retrieve film title from film page. If was got search page instead
of film page this method calls method _search_film to get list
matched films and continue to process first one:

	my $title = $film->title();

=cut
sub title {	
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;
	if($forced) {
		my $parser = $self->_parser(FORCED);
	
		$parser->get_tag('title');
		my $title = $parser->get_text();
		if($title =~ /IMDb title search/i) {
			$self->_show_message("Go to search page ...", 'DEBUG');
			$title = $self->_search_film();				
		} 
	
		if( !defined $self->code or $self->code eq '' ) {
			my($id, $tag);			
			
			while($tag = $parser->get_tag('img')) {
				last if defined $tag->[1]{alt} && $tag->[1]{alt} =~ /vote/i;
			}
			
			$tag = $parser->get_tag('select');

			$id = $tag->[1]{name};

			$self->code($id);
		} 
	
		(my ($ftitle, $year)) = $title =~ /(.*?)\s+\((\d{4}).*?\)/;
		$self->{_title} = $ftitle;
		$self->{_year} = $year;
	}	
	
	return $self->{_title};
}

=item year()

Get film year:
	
	my $year = $film->year();

=cut
sub year {
	my CLASS_NAME $self = shift;
	return $self->{_year};
}

=item cover()

Retrieve url of film cover:

	my $cover = $film->cover();

=cut
sub cover {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;

	if($forced) {
		my ($parser) = $self->_parser(FORCED);
		my ($cover);

		while(my $img_tag = $parser->get_tag('img')) {
			$img_tag->[1]{alt} ||= '';	
			if($img_tag->[1]{alt} =~ /cover/i) {
				$cover = $img_tag->[1]{src};
				last;
			}

			last if $img_tag->[1]{alt} =~ /^no poster/i;
		}

		$self->{_cover} = $cover;
	}	

	return $self->{_cover};
}	

=item directors()

Retrieve film directors list each element of which is hash reference -
{ id => <ID>, name => <Name> }:

	my @directors = @{ $film->directors() };
	
=cut
sub directors {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;

	if($forced) {
		my ($parser) = $self->_parser(FORCED);
		my (@directors, $tag);
	
		while($tag = $parser->get_tag('b')) {
			last if $parser->get_text =~ /^directed/i;
		}

		while ($tag = $parser->get_tag() ) {
			my $text = $parser->get_text();
			last if $text =~ /writing/i or $tag->[0] eq '/td';
			
			if($tag->[0] eq 'a') {
				my ($id) = $tag->[1]{href} =~ /(\d+)/;	
				push @directors, {id => $id, name => $text};
			}			
		}
		
		$self->{_directors} = \@directors;		
	}	

	return $self->{_directors};
}

=item writers()

Retrieve film writers list each element of which is hash reference -
{ id => <ID>, name => <Name> }:

	my @writers = @{ $film->writers() };

=cut
sub writers {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;

	if($forced) {
		my ($parser) = $self->_parser(FORCED);
		my (@writers, $tag);
		
		while($tag = $parser->get_tag('b')) {
			last if $parser->get_text =~ /^writing/i;
		}
			
		while($tag = $parser->get_tag()) {
			my $text = $parser->get_text();
			last if $tag->[0] eq '/table';
			
			if($tag->[0] eq 'a') {
				if(my ($id) = $tag->[1]{href} =~ /nm(\d+)/) {
					push @writers, {id => $id, name => $text};
				}	
			}		
		}
		
		$self->{_writers} = \@writers;
	}	

	return $self->{_writers};
}

=item genres()

Retrieve film genres list:

	my @genres = @{ $film->genres() };

=cut
sub genres {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;

	if($forced) {
		my ($parser) = $self->_parser(FORCED);
		my (@genres);
		
		while(my $tag = $parser->get_tag('b')) {
			last if $parser->get_text =~ /^genre/i;
		}

		while(my $tag = $parser->get_tag('a')) {
			my $genre = $parser->get_text;	
			last unless $tag->[1]{href} =~ /genres/i;
			last if $genre =~ /more/i;
			push @genres, $genre;
		}	

		$self->{_genres} = \@genres;
	}	

	return $self->{_genres};
}

=item tagline()

Retrieve film tagline:
	
	my $tagline = $film->tagline();

=cut
sub tagline {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;

	if($forced) {
		my ($parser) = $self->_parser(FORCED);		

		while(my $tag = $parser->get_tag('b')) {
			last if($parser->get_text =~ /tagline/i);
		}	
				
		$self->{_tagline} = $parser->get_trimmed_text('b', 'a');
	}	

	return $self->{_tagline};
}

=item plot()

Retrieve film plot summary:

	my $plot = $film->plot();

=cut
sub plot {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;

	my ($text);

	if($forced) {
		my $parser = $self->_parser(FORCED);

		while(my $tag = $parser->get_tag('b')) {
			last if $parser->get_text =~ /^plot/i;
		}

		$self->{_plot} = $parser->get_trimmed_text('b', 'a');

		my $tag = $parser->get_tag('a');
	}	

	return $self->{_plot};
}

=item rating()

In scalar context returns film user rating, in array context returns 
film rating and number of votes:
	
	my $rating = $film->rating();

	or

	my($rating, $vnum) = $film->rating();
	print "RATING: $rating ($vnum votes )";

=cut
sub rating {
	my CLASS_NAME $self = shift;
	my ($forced) = shift || 0;

	if($forced) {
		my $parser = $self->_parser(FORCED);
	
		while(my $tag = $parser->get_tag('b')) {
			last if $parser->get_text =~ /rating/i;
		}

		my $tag = $parser->get_tag('b');	
		my $text = $parser->get_trimmed_text('b', 'a');

		my ($rating, $val) = $text =~ m!(\d+\.?\d+)\/.*?\((\d+\,?\d+)\s.*?\)!;
		$val =~ s/\,// if $val;

		$self->{_rating} = [$rating, $val];
	}

	return wantarray ? @{ $self->{_rating} } : $self->{_rating}[0];
}

=item cast()

Retrieve film cast list each element of which is hash reference -
{ id => <ID>, name => <Full Name>, role => <Role> }:

	my @cast = @{ $film->cast() };

=cut
sub cast {
	my CLASS_NAME $self = shift;
	my ($forced) = shift || 0;

	if($forced) {
		my (@cast, $tag, $person, $id, $role);
		my $parser = $self->_parser(FORCED);
	
		while($tag = $parser->get_tag('b')) {
			last if $parser->get_text() =~ /^cast overview/i;
		}
		
		while($tag = $parser->get_tag('a')) {
			last if $tag->[1]{href} =~ /fullcredits/i;
			if(defined $tag->[1]{href} && $tag->[1]{href} =~ m!/name/nm(\d+?)/!) {
				$person = $parser->get_text;
				$id = $1;	
				my $text = $parser->get_trimmed_text('a', '/tr');
				($role) = $text =~ /.*?\s+(.*)$/;			
				push @cast, {id => $id, name => $person, role => $role};
			}	
		}	
		
		$self->{_cast} = \@cast;
	}

	return $self->{_cast};
}

=item duration()

Retrieve film duration in minutes:

	my $duration = $film->duration();

=cut
sub duration {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;
	
	if($forced) {

		my $parser = $self->_parser(FORCED);
		while(my $tag = $parser->get_tag('b')) {
			my $text = $parser->get_text();
			last if $text =~ /runtime:/i;
		}	
		
		$self->{_duration} = $parser->get_trimmed_text('b', 'br');
	}

	return $self->{_duration};
}

=item country()

Retrieve film produced countries list:

	my @countries = $film->country();

=cut
sub country {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;
	
	if($forced) {
		my $parser = $self->_parser(FORCED);
		while (my $tag = $parser->get_tag('b')) {
			last if $parser->get_text =~ /country/i;
		}	

		my (@countries);
		while(my $tag = $parser->get_tag()) {
			
			if( $tag->[0] eq 'a' && $tag->[1]{href} =~ /countries/i ) {
				push @countries, $parser->get_text();
			} 
			
			last if $tag->[0] eq 'br';
		}

		$self->{_country} = \@countries; 
	}
	
	return $self->{_country}
}

=item language()

Retrieve film languages list:

	my @languages = $film->language();

=cut
sub language {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;
	
	if($forced) {
		my (@languages, $tag);
		my $parser = $self->_parser(FORCED);
		while ($tag = $parser->get_tag('b')) {
			last if $parser->get_text =~ /language/i;
		}	

		while($tag = $parser->get_tag()) {
			
			if( $tag->[0] eq 'a' && $tag->[1]{href} =~ /languages/i ) {
				push @languages, $parser->get_text();
			} 
			
			last if $tag->[0] eq 'br';
		}

		$self->{_language} = \@languages; 
	}
	
	return $self->{_language};

}

=item summary()

Retrieve film user summary:

	my $descr = $film->summary();
	
=cut
sub summary {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;
		
	if($forced) {
		my ($tag, $text);
		my ($parser) = $self->_parser(FORCED);

		while($tag = $parser->get_tag('b')) {
			$text = $parser->get_text();
			last if $text =~ /^summary/i;
		}	

		$text = $parser->get_text('b', 'a');
		$self->{_summary} = $text;
	}	
	
	return $self->{_summary};
}

=item certifications()

Retrieve list of film certifications each element of which is hash reference -
{ country => certificate }:

	my @cert = $film->certifications();

=cut
sub certifications {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;
	my (%cert_list, $tag);

	if($forced) {
		my $parser = $self->_parser(FORCED);
		while($tag = $parser->get_tag('b')) {
			last if $parser->get_text =~ /certification/i;
		}

		while($tag = $parser->get_tag()) {
			
			if($tag->[0] eq 'a' && $tag->[1]{href} =~ /certificates/i) {
				my ($country, $range) = split /\:/, $parser->get_text;
				$cert_list{$country} = $range;
			}

			last if $tag->[0] eq '/td';
		}

		$self->{_certifications} = \%cert_list;
	}

	return $self->{_certifications};
}

=item full_plot

Return full movie plot. 

=cut
sub full_plot {
	my CLASS_NAME $self = shift;

	if (!defined $self->{_full_plot} or $self->{_full_plot} eq '') {
		
		my $url = 'http://www.imdb.com/rg/title-tease/plotsummary/title/tt'.$self->code().'/plotsummary';

		my $ua = new LWP::UserAgent();
		$ua->proxy(['http', 'ftp'], 'http://'.$self->_proxy()) if defined $self->_proxy();

		$self->_show_message("URL is $url ...", 'DEBUG');

		my $req = new HTTP::Request(GET => $url);
		my $res = $ua->request($req);

		unless($res->is_success) {
			$self->error($res->status_line());
			$self->_show_message("Cannot retrieve page: ".$res->status_line(), 'CRITICAL');
			return;
		}
				
		my $page = $res->content();
		
		my $parser = $self->_parser(FORCED, \$page);
		
		my($text);
		while(my $tag = $parser->get_tag('p')) {
			if(defined $tag->[1]{class} && $tag->[1]{class} =~ /plotpar/i) {
				$text = $parser->get_trimmed_text();
				last;
			}
		}

		$self->{_full_plot} = $text;
	
	}

	return $self->{_full_plot};
}

=back

=cut

sub DESTROY {
	my CLASS_NAME $self = shift;
	$self->_decr_objcount();
}

1;

__END__

=head2 Class Variables

=over 4

=item %FIELDS

Contains list all object's properties. See description of pragma C<fields>.

=item @FILM_CERT

Matches USA film certification notation and age.

=back

=head1 EXPORTS

Nothing

=head1 BUGS

Please, send me any found bugs by email: misha@thunderworx.com. 

=head1 SEE ALSO

HTML::TokeParser, IMDB::BaseClass, IMDB::Persons, IMDB::Movie

=head1 AUTHOR

Michael Stepanov (misha@thunderworx.com)

=head1 COPYRIGHT

Copyright (c) 2004, Michael Stepanov. All Rights Reserved.
This module is free software. It may be used, redistributed and/or 
modified under the same terms as Perl itself.

=cut
