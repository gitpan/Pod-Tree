use strict;
use 5.005;

package Pod::Tree::PerlUtil;


sub mkdir
{
    my($translator, $dir) = @_;

    -d $dir or CORE::mkdir $dir, 0755 or 
	die "Pod::Tree::PerlUtil::mkdir: Can't mkdir $dir: $!\n";
}


sub report1
{
    my($translator, $routine) = @_;

    $translator->{options}{v} < 1 and return;

    my $package = ref $translator;
    my $name = "${package}::$routine";
    my $pad = 60 - length $name;
    print $name, ' ' x $pad, "\n";
}


sub report2
{
    my($translator, $page) = @_;

    my $verbosity = $translator->{options}{v};

    $verbosity==2 and do
    {
	my $pad = 60 - length $page;
	print $page, ' ' x $pad, "\r";
    };

    $verbosity==3 and print "$page\n";
}

1
