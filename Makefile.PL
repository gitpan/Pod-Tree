use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(NAME	      => 'Pod::Tree',
	      VERSION_FROM    => 'Tree.pm', # finds $VERSION
	      DISTNAME        => 'Pod-Tree',
	      ($] >= 5.005 ?
	       (ABSTRACT_FROM => 'Tree.pm',
		AUTHOR        => 'Steven McDougall (swmcd@world.std.com)') : 
	       ()),
	      clean           => { FILES => "t/*.?_act lib/Pod/Tree/*~" },
	      dist            => { COMPRESS => 'gzip --best',
			 	   SUFFIX   => '.gz' },
	      EXE_FILES	      => [qw(pod2html pods2html perl2html)],
	      PREREQ_PM       => { HTML::Stream => 1.49,
	                           Pod::Escapes => 1.02  },
);
