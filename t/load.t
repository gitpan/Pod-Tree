# -*- perl -*-

use strict;
use Pod::Tree;
use IO::File;

my $N = 1;
sub Not { print "not " }
sub OK  { print "ok ", $N++, "\n" }

print "1..3\n";

LoadFH        ("t/list");
LoadString    ("t/list");
LoadParagraphs("t/list");


sub LoadFH
{
    my $file   = shift;
    my $fh     = new IO::File;
    my $tree   = new Pod::Tree;
    $fh  ->open("$file.pod") or die "Can't open $file.pod: $!\n";
    $tree->load_fh($fh);

    my $actual   = $tree->dump;
    my $expected = ReadFile("$file.p_exp");
    $actual eq $expected or Not; OK;
}


sub LoadString
{
    my $file   = shift;
    my $string = ReadFile("$file.pod");
    my $tree   = new Pod::Tree;
    $tree->load_string($string);

    my $actual = $tree->dump;
    my $expected = ReadFile("$file.p_exp");
    $actual eq $expected or Not; OK;
}


sub LoadParagraphs
{
    my $file       = shift;
    my $string     = ReadFile("$file.pod");
    my @paragraphs = split m(\n{2,}), $string;
    my $tree       = new Pod::Tree;

    $tree->load_paragraphs(\@paragraphs);

    my $actual     = $tree->dump;
    my $expected   = ReadFile("$file.p_exp");

    $actual eq $expected or Not; OK;
}


sub ReadFile
{
    my $file = shift;
    open(FILE, $file) or return '';
    local $/;
    undef $/;
    my $contents = <FILE>;
    close FILE;
    $contents
}


sub WriteFile
{
    my($file, $contents) = @_;
    open(FILE, ">$file") or die "Can't open $file: $!\n";
    print FILE $contents;
    close FILE;
}


sub Split
{
    my $string = shift;
    my @pieces = split /(\n{2,})/, $string;

    my @paragraphs;
    while (@pieces)
    {
	my($text, $ending) = splice @pieces, 0, 2;
	$ending or $ending = '';                    # to quiet -w
	push @paragraphs, $text . $ending;
    }

    @paragraphs
}




