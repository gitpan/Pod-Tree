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
    print STDERR $name, ' ' x $pad, "\n";
}


sub report2
{
    my($translator, $page) = @_;

    my $verbosity = $translator->{options}{v};

    $verbosity==2 and do
    {
	my $pad = 60 - length $page;
	print STDERR $page, ' ' x $pad, "\r";
    };

    $verbosity==3 and print STDERR "$page\n";
}


sub get_name
{
    my($node, $source) = @_;

    my $tree     = new Pod::Tree;
       $tree->load_file($source);
    my $children = $tree->get_root->get_children;
    my @pod      = grep { is_pod $_ } @$children;
    my $node1    = $pod[1];
       $node1 or return ();

    my $text     = $node1->get_deep_text;
    my($name, $description) = split m(\s+-+\s+), $text, 2;
       $name     =~ s(^\s+)();
       $name or return ();

       $description =~ s(\s+)( )g;
       $description =~ s(\s+$)();

      ($name, $description)
}

sub get_description
{
    my($node, $source) = @_;

    my($name, $description) = $node->get_name($source);
    $description
}


1

__END__

Copyright (c) 2000 by Steven McDougall.  This module is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
