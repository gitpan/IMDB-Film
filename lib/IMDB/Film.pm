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
				_code
				_language
				_country
				_rating
				_genres
				_tagline
				_plot
				_certifications
				_duration
				content
				parser
				matched
				proxy
				error
				cache
				host
				query
				search
				cacheObj
				cache_exp
				debug
	);
	
use vars qw( $VERSION %FIELDS %FILM_CERT );

use constant CLASS_NAME => 'IMDB::Film';
use constant FORCED		=> 1;
use constant USE_CACHE	=> 1;
use constant DEBUG_MOD	=> 1;

BEGIN {
		$VERSION = '0.04';
						
		# Convert age gradation to the digits		
		%FILM_CERT = ( G => 'All', R => 16, 'NC-17' => 16, PG => 13, 'PG-13' => 13 );					
}

{
	my $_objcount = 0;

	sub get_objcount { $_objcount }
	sub _incr_objcount { ++$_objcount }
	sub _decr_objcount { --$_objcount }
	
	my %_defaults = ( 
		proxy		=> $ENV{http_proxy},
		cache		=> 0,
		debug		=> 0,
		error		=> [],
		cache_exp	=> '1 h',
        host		=> 'www.imdb.com',
        query		=> 'title/tt',
        search 		=> 'find?tt=on;mx=20;q=',		
	);

	sub _get_default_attrs { keys %_defaults }		
	sub _get_default_value {
		my($self, $attr) = @_;
		$_defaults{$attr};
	}
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

=cut
sub new {
	my $caller = shift;
	my $class = ref($caller) || $caller;

	$class->_incr_objcount();

	no strict "refs";
	my $self = bless [\%{"${caller}::FIELDS"}], $class;

	$self->_init(@_);
	return $self;
}

=item _init()

Initialize object.

=cut
sub _init {
	my CLASS_NAME $self = shift;
	my %args = @_;
	
	for my $prop ( $self->_get_default_attrs ) {		
		$self->{$prop} = defined $args{$prop} 	? $args{$prop} : 
												$self->_get_default_value($prop);	
	}

	$self->_cacheObj( new Cache::FileCache( { default_expires_in => $self->_cache_exp() } ) );
	
	croak "Film IMDB ID or Title should be defined!" 
											if !defined $args{crit} && $args{crit} eq '';									
	
	$self->_content( $args{crit} );
	$self->_parser(FORCED);
	$self->title(FORCED);

	for my $prop (grep { /^_/ && !/^(_title|_code)$/ } sort keys %FIELDS) {
		($prop) = $prop =~ /^_(.*)/;
		$self->$prop(FORCED);
	}
}

=back

=head2 Object Private Methods

=over 4

=item _proxy()

Store address of proxy server. You can pass a proxy name as parameter into
object constructor:

	my $imdb = new IMDB::Film(code => 111111, proxy => 'my.proxy.host:8080');

or you can define environment variable 'http_host'. For exanple, for Linux
you shoud do a following:

	export http_proxy=my.proxy.host:8080
	
=cut
sub _proxy {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{proxy} = shift }
	return $self->{proxy};
}

=item _cache()

Store cache flag. Indicate use file cache to store content page or not:
	
	my $imdb = new IMDB::Film(code => 111111, cache => 1);

=cut
sub _cache {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{cache} = shift }
	return $self->{cache}
}

=item _cacheObj()

In case of using cache, we create new Cache::File object and store it in object's
propery. For more details about Cache::File please see Cache::Cache documentation.

=cut
sub _cacheObj {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{cacheObj} = shift }
	return $self->{cacheObj}
}

=item _cache_exp()

In case of using cache, we can define value time of cache expire.

	my $imdb = new IMDB::Film(code => 111111, cache_exp => '1 h');

For more details please see Cache::Cache documentation.

=cut
sub _cache_exp {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{cache_exp} = shift }
	return $self->{cache_exp}
}

sub _show_message {
	my CLASS_NAME $self = shift;
	my $msg = shift || 'Unknown error';
	my $type = shift || 'ERROR';

	return if $type =~ /^debug$/i && !$self->_debug();
	
	if($type =~ /(debug|info|warn)/i) {
		carp "[$type] $msg";
	} else {
		croak "[$type] $msg";
	}
}

=item _host()

Store IMDB host name. You can pass this value in object constructor:
		
	my $imdb = new IMDB::Film(code => 111111, host => 'us.imdb.com');

By default, it uses 'www.imdb.com'.

=cut
sub _host {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{host} = shift }
	return $self->{host}
}

=item _query()

Store query string to retrieve film by its ID. You can define
different value for that:

	my $imdb = new IMDB::Film(code => 111111, query => 'some significant string');

Default value is 'title/tt'.

=cut
sub _query {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{query} = shift }
	return $self->{query}
}

=item _search()

Store search string to find film by its title. You can define
different value for that:

	my $imdb = new IMDB::Film(code => 111111, seach => 'some significant string');

Default value is 'Find?select=Titles&for='.

=cut	
sub _search {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{search} = shift }
	return $self->{search}
}

=item _debug()

Indicate to use DEBUG mode to display some debug messages:
	
	my $imdb = new IMDB::Film(code => 111111, debug => 1);

By default debug mode is switched off.	

=cut
sub _debug {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{debug} = shift }
	return $self->{debug}
}

=item _content()

Connect to the IMDB, retrieve page according to crit: by film
IMDB ID or its title and store content of that page in the object
property. 
In case using cache, first check if page was already stored in the
cache then retrieve page from the cache else store content of the 
page in the cache.

=cut
sub _content {
	my CLASS_NAME $self = shift;
	if(@_) {
		my $crit = shift;
		my ($page);
	
		$page = $self->_cacheObj()->get($crit) if $self->_cache();

		$self->code($crit) if $crit =~ /^\d+$/;

		unless (defined $page) {
			
			$self->_show_message("Retrieving page from internet ...", 'DEBUG');
			
			my $ua = new LWP::UserAgent();
			$ua->proxy(['http', 'ftp'], 'http://'.$self->_proxy()) if defined $self->_proxy();

			my $url = 'http://'.$self->_host().'/'.
						( $crit =~ /^\d+$/ ? $self->_query() : $self->_search() ).$crit;

			$self->_show_message("URL is $url ...", 'DEBUG');

			my $req = new HTTP::Request(GET => $url);
			my $res = $ua->request($req);

			unless($res->is_success) {
				$self->error($res->status_line());
				$self->_show_message("Cannot retrieve page: ".$res->status_line(), 'CRITICAL');				
			}
			
			$page = $res->content();
			
			$self->_cacheObj()->set($crit, $page, $self->_cache_exp()) if $self->_cache();
		} else {
			$self->_show_message("Retrieving page from cache ...", 'DEBUG');
		}
		
		$self->{content} = \$page;
	}
	
	return $self->{content};
}

=item _parser()

Setup HTML::TokeParser and store. To have possibility to inherite that class
we should every time initialize parser using stored content of page.
For more information please see HTML::TokeParser documentation.

=cut
sub _parser {	
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;
	my $page = shift || undef;

	if($forced) {
		my $content = defined $page ? $page : $self->_content();

		my $parser = new HTML::TokeParser($content) or croak "[CRITICAL] Cannot create HTML parser: $!!";
		$self->{parser} = $parser;
	}
	
	return $self->{parser};
}

=item _search_film()

Implemets functionality to search film by name.

=cut
sub _search_film {
	my CLASS_NAME $self = shift;
	my (@matched);
	
	my $parser = $self->_parser();

	while(my $tag = $parser->get_tag('a')) {
		my $href = $tag->[1]{href};
		if (my ($id) = $href =~ /\/title\/tt(\d+)/) {
			push @matched, {id => $id, title => $parser->get_text};
		}	
	}

	$self->matched(\@matched);
	$self->_content($matched[0]->{id});
	$self->_parser(FORCED);

	return $matched[0]->{title};
}

=back

=head2 Object Public Methods

=over 4

=item code()

Get IMDB film code.

	my $code = $film->code();

=cut
sub code {
	my CLASS_NAME $self = shift;

	if(@_) { $self->{_code} = shift }

	return $self->{_code};
}

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
		my ($parser) = $self->_parser(FORCED);
	
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
		$val =~ s/\,//;

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



=item matched()

Retrieve list of matched films each element of which is hash reference - 
{ id => <Film ID>, title => <Film Title>:

	my @matched = @{ $film->matched() };

=cut
sub matched {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{matched} = shift }
	return $self->{matched};
}


=item error()

Return string which contains error messages separated by \n:

	my $errors = $film->error();

=cut
sub error {
	my CLASS_NAME $self = shift;
	if(@_) { push @{ $self->{error} }, shift() }
	return join("\n", @{ $self->{error} });
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

HTML::TokeParser, IMDB::Movie, perlobj

=head1 AUTHOR

Michael Stepanov (misha@thunderworx.com)

=head1 COPYRIGHT

Copyright (c) 2004, Michael Stepanov. All Rights Reserved.
This module is free software. It may be used, redistributed and/or 
modified under the same terms as Perl itself.

=cut
