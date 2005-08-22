=head1 NAME

IMDB::BaseClass - a base class for IMDB::Film and IMDB::Persons.

=head1 SYNOPSIS

  use base qw(IMDB::BaseClass);
  
=head1 DESCRIPTION

IMDB::BaseClass implements a base functionality for IMDB::Film
and IMDB::Persons.

=cut
package IMDB::BaseClass;

use strict;
use warnings;

use HTML::TokeParser;
use LWP::UserAgent;
use Cache::FileCache;
use Carp;

use Data::Dumper;

use vars qw($VERSION %FIELDS $AUTOLOAD);

BEGIN {
	$VERSION = '0.14';
}

use constant FORCED 	=> 1;
use constant CLASS_NAME => 'IMDB::BaseClass';

use fields qw(	content
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
				status
				_code
				
	);

{
	my $_objcount = 0;

	sub get_objcount { $_objcount }
	sub _incr_objcount { ++$_objcount }
	sub _decr_objcount { --$_objcount }
	
	#my($proxy);
	#if(defined $ENV{http_proxy}) {
	#	$proxy = $ENV{http_proxy} =~ m!^http:\/\/(.*?):! ? $1 : $ENV{http_proxy};		
	#}	

	my %_defaults = ( 
		proxy		=> $ENV{http_proxy},
		cache		=> 0,
		debug		=> 0,
		error		=> [],
		cache_exp	=> '1 h',
        host		=> 'www.imdb.com',
        query		=> 'title/tt',
        search 		=> 'find?tt=on;mx=20;q=',		
		status		=> 0,		
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
	my $self = fields::new($class);
	$self->_init(@_);
	return $self;
}

=item _init()

Initialize object.

=cut
sub _init {
	my CLASS_NAME $self = shift;
	my %args = @_;

	no warnings 'deprecated';

	for my $prop ( $self->_get_default_attrs ) {		
		$self->{$prop} = defined $args{$prop} ? 
								$args{$prop} : $self->_get_default_value($prop);	
	}
	
	#$self->_show_message(Dumper($self));
	
	$self->_cacheObj( new Cache::FileCache( { default_expires_in => $self->_cache_exp() } ) );
	
	$self->_content( $args{crit} );
	$self->_parser();
}

=item code()

Get IMDB film code.

	my $code = $film->code();

=cut
sub code {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{_code} = shift }
	return $self->{_code};
}

=item id()

Get IMDB film id (actually, it's the same as code).

	my $id = $film->id();

=cut
sub id {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{_code} = shift }
	return $self->{_code};
}

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

#sub get_proxy {
#	my CLASS_NAME $self = shift;
	#if(defined $ENV{http_proxy}) {
	#	my $proxy = $ENV{http_proxy} =~ m!^http:\/\/(.*?):! ? $1 : $ENV{http_proxy};		
	#	$self->{proxy} = $proxy;
	#}
#}

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
	
	if($type =~ /(debug|info|warn)/i) { carp "[$type] $msg" } 
	else { croak "[$type] $msg" }
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
		my $crit = shift || '';
		my $page;
	
		$page = $self->_cacheObj()->get($crit) if $self->_cache();
		$self->code($crit) if $crit =~ /^\d+$/;

		unless($page) {			
			$self->_show_message("Retrieving page from internet ...", 'DEBUG');
		
			my $ua = new LWP::UserAgent();
			#$ua->proxy(['http', 'ftp'], 'http://'.$self->_proxy()) if $self->_proxy();
			$ua->proxy(['http', 'ftp'], $self->_proxy()) if $self->_proxy();

			my $url = 'http://'.$self->_host().'/'.
						( $crit =~ /^\d+$/ ? $self->_query() : $self->_search() ).$crit;

			$self->_show_message("URL is [$url]...", 'DEBUG');

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

=back

=cut

sub _search_results {
	my CLASS_NAME $self = shift;
	my $pattern = shift || croak 'Please, specify search pattern!';
	my $end_tag = shift || '/li';
	
	my @matched;
	my $parser = $self->_parser();

	while( my $tag = $parser->get_tag('a') ) {
		my $href = $tag->[1]{href};
		if( my($id) = $href =~ /$pattern/ ) {
			push @matched, {id => $id, title => $parser->get_trimmed_text('a', $end_tag)};
		}	
	}

	$self->matched(\@matched);
	$self->_content($matched[0]->{id});
	$self->_parser(FORCED);

	return $matched[0]->{title};
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

sub status {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{status} = shift }
	return $self->{status}
}

sub retrieve_code {
	my CLASS_NAME $self = shift;
	my $parser = shift;
	my $pattern = shift;
	my($id, $tag);			
	
	while($tag = $parser->get_tag('a')) {
		if($tag->[1]{href} && $tag->[1]{href} =~ m!$pattern!) {
			$self->code($1);
			last;
		}	
	}	
}

=item error()

Return string which contains error messages separated by \n:

	my $errors = $film->error();

=cut
sub error {
	my CLASS_NAME $self = shift;
	if(@_) { push @{ $self->{error} }, shift() }
	return join("\n", @{ $self->{error} }) if $self->{error};
}

sub AUTOLOAD {
 	my $self = shift;
	my($class, $method) = $AUTOLOAD =~ /(.*)::(.*)/;
	my($pack, $file, $line) = caller;

	carp "Method [$method] not found in the class [$class]!\n Called from $pack	at line $line";
}

sub DESTROY {
	my $self = shift;
}

1;

__END__

=head1 EXPORTS

Nothing

=head1 BUGS

Please, send me any found bugs by email: misha@thunderworx.com. 

=head1 SEE ALSO

HTML::TokeParser, IMDB::Persons; IMDB::Film;

=head1 AUTHOR

Mikhail Stepanov (stepanov.michael@gmail.com)

=head1 COPYRIGHT

Copyright (c) 2004, Mikhail Stepanov. All Rights Reserved.
This module is free software. It may be used, redistributed and/or 
modified under the same terms as Perl itself.

=cut
