use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              	=> 'IMDB::Film',
    VERSION_FROM      	=> 'lib/IMDB/Film.pm', 
	PREREQ_PM         	=> {
							HTML::TokeParser 	=> 2.28,
							LWP::UserAgent		=> 2.024,
							Cache::FileCache	=> 0, 
							Carp				=> 0,
							Error				=> 0,
					}, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  	=> 'lib/IMDB/Film.pm', 
       AUTHOR         	=> 'Michael Stepanov <misha@thunderworx.com>') : ()),
);
