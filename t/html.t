# -*- perl -*-

use strict;
use diagnostics;
use HTML::Stream;
use Pod::Tree;
use Pod::Tree::HTML;

my $N = 1;
sub Not { print "not " }
sub OK  { print "ok ", $N++, "\n" }

my $Dir = 't/html.d';

my $nTests = 5 + 3 + 6 + 1 + 1;
print "1..$nTests\n";

Source1  ();
Source2  ();
Source3  ();
Source4  ();
Source5  ();
Dest1    ();
Dest2    ();
Dest3    ();
Translate();
Base     ();
Depth    ();

sub Source1
{
    my $tree   = new Pod::Tree;
    $tree->load_file("$Dir/paragraph.pod");
    my $actual = new IO::String;
    my $html   = new Pod::Tree::HTML $tree, $actual;

    Source($html, $actual);
}

sub Source2
{
    my $actual = new IO::String;
    my $html   = new Pod::Tree::HTML "$Dir/paragraph.pod", $actual;

    Source($html, $actual);
}

sub Source3
{
    my $io     = new IO::File "$Dir/paragraph.pod";
    my $actual = new IO::String;
    my $html   = new Pod::Tree::HTML $io, $actual;

    Source($html, $actual);
}

sub Source4
{
    my $pod    = ReadFile("$Dir/paragraph.pod");
    my $actual = new IO::String;
    my $html   = new Pod::Tree::HTML \$pod, $actual;

    Source($html, $actual);
}

sub Source5
{
    my @paragraphs = ReadParagraphs("$Dir/paragraph.pod");
    my $actual     = new IO::String;
    my $html       = new Pod::Tree::HTML \@paragraphs, $actual;

    Source($html, $actual);
}

sub Source
{
    my($html, $actual) = @_;

       $html->set_options(toc => 0);
       $html->translate;

    my $expected = ReadFile("$Dir/paragraph.exp");
       $$actual eq $expected or Not; OK;
}

sub Dest1
{
    my $actual = new IO::String;
    my $stream = new HTML::Stream $actual;
    my $html   = new Pod::Tree::HTML "$Dir/paragraph.pod", $stream;

       $html->set_options(toc => 0);
       $html->translate;

    my $expected = ReadFile("$Dir/paragraph.exp");
       $$actual eq $expected or Not; OK;
}

sub Dest2
{
    my $actual = new IO::String;
    my $html   = new Pod::Tree::HTML "$Dir/paragraph.pod", $actual;

       $html->set_options(toc => 0);
       $html->translate;

    my $expected = ReadFile("$Dir/paragraph.exp");
       $$actual eq $expected or Not; OK;
}

sub Dest3
{
    {
    my $html = new Pod::Tree::HTML "$Dir/paragraph.pod", "$Dir/paragraph.act";

       $html->set_options(toc => 0);
       $html->translate;
    }

    my $expected = ReadFile("$Dir/paragraph.exp");
    my $actual   = ReadFile("$Dir/paragraph.act");
    $actual eq $expected or Not; OK;
}


sub Translate
{
    for my $file (qw(cut paragraph list sequence for link))
    {
	my $actual = new IO::String;
	my $html   = new Pod::Tree::HTML "$Dir/$file.pod", $actual;
	$html->set_options(toc => 0);
	$html->translate;

	my $expected = ReadFile("$Dir/$file.exp");
	$$actual eq $expected or Not; OK;

	WriteFile("$Dir/$file.act"			 , $$actual);
    #   WriteFile("$ENV{HOME}/public_html/pod/$file.html", $$actual);
    }
}

sub Base
{
    my $actual = new IO::String;
    my $html   = new Pod::Tree::HTML "$Dir/link.pod", $actual;
    $html->set_options(toc => 0, base => 'http://world.std.com/~swmcd/pod');
    $html->translate;

    my $expected = ReadFile("$Dir/base.exp");
    $$actual eq $expected or Not; OK;

    WriteFile("$Dir/base.act"			    , $$actual);
#   WriteFile("$ENV{HOME}/public_html/pod/base.html", $$actual);
}

sub Depth
{
    my $actual = new IO::String;
    my $html   = new Pod::Tree::HTML "$Dir/link.pod", $actual;
    $html->set_options(toc => 0, depth => 2);
    $html->translate;

    my $expected = ReadFile("$Dir/depth.exp");
    $$actual eq $expected or Not; OK;

    WriteFile("$Dir/depth.act"			     , $$actual);
#   WriteFile("$ENV{HOME}/public_html/pod/depth.html", $$actual);
}

sub ReadParagraphs
{
    my $file   = shift;
    my $pod    = ReadFile($file);
    my @chunks = split /(\n{2,})/, $pod;

    my @paragraphs;
    while (@chunks)
    {
	push @paragraphs, join '', splice @chunks, 0, 2;
    }

    @paragraphs
}

sub ReadFile
{
    my $file = shift;
    open(FILE, $file) or die "Can't open $file: $!\n";
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
    chmod 0644, $file or die "Can't chmod $file: $!\n";
}


package IO::String;

sub new 
{
    my $self = '';
    bless \$self, shift;
}

sub print 
{
    my $self = shift;
    $$self .= join('', @_);
}
    
