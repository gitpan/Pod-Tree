# -*- perl -*-

use strict;
use Pod::Tree;
use IO::File;

my $N = 1;
sub Not { print "not " }
sub OK  { print "ok ", $N++, "\n" }

print "1..6\n";

LoadFile      ("t/cut");
LoadFile      ("t/cut", 0);
LoadFile      ("t/cut", 1);
LoadString    ("t/cut");
LoadString    ("t/cut", 0);
LoadString    ("t/cut", 1);


sub LoadFile
{
    my($file, $in_pod) = @_;

    my %options;
    defined $in_pod and $options{in_pod} = $in_pod;

    my $tree = new Pod::Tree;
    $tree->load_file("$file.pod", %options);

    my $actual   = $tree->dump;
    my $suffix   = defined $in_pod ? "F$in_pod" : "FU";
    my $expected = ReadFile("$file$suffix.p_exp");
    $actual eq $expected or Not; OK;

    WriteFile("$file$suffix.p_act", $actual);
}


sub LoadString
{
    my($file, $in_pod) = @_;
    my $string = ReadFile("$file.pod");

    my %options;
    defined $in_pod and $options{in_pod} = $in_pod;

    my $tree   = new Pod::Tree;
    $tree->load_string($string, %options);

    my $actual   = $tree->dump;
    my $suffix   = defined $in_pod ? "S$in_pod" : "SU";
    my $expected = ReadFile("$file$suffix.p_exp");
    $actual eq $expected or Not; OK;

    WriteFile("$file$suffix.p_act", $actual);
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




