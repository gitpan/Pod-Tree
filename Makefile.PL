use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	   => 'Pod::Tree',
    'VERSION_FROM' => 'Tree.pm', # finds $VERSION
    'clean'        => { FILES => "t/*.?_act lib/Pod/Tree/*~" },
    'dist'         => { COMPRESS => 'gzip --best',
	                SUFFIX   => '.gz' },
);
