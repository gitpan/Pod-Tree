use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(NAME	   => 'Pod::Tree',
	      VERSION_FROM => 'Tree.pm', # finds $VERSION
	      DISTNAME     => 'Pod-Tree',
	      ($] >= 5.005 ?
	       (ABSTRACT   => 'tree-based POD parser',
		AUTHOR     => 'Steven McDougall (swmcd@world.std.com)') : ()),
	      clean        => { FILES => "t/*.?_act lib/Pod/Tree/*~" },
	      dist         => { COMPRESS => 'gzip --best',
				SUFFIX   => '.gz' },
);
