# -*- perl -*-

use strict;
use diagnostics;
use HTML::Stream;
use Pod::Tree;
use Pod::Tree::HTML;

my $N = 1;
sub Not { print "not " }
sub OK  { print "ok ", $N++, "\n" }

print "1..6\n";


for my $file (qw(cut paragraph list sequence for link))
{
    my $actual = new IO::String;
    my $html   = new Pod::Tree::HTML "t/$file.pod", $actual;
    $html->set_options(toc => 0);
    $html->translate;

    my $expected = ReadFile("t/$file.h_exp");
    $$actual eq $expected or Not; OK;

    WriteFile("t/$file.h_act"			     , $$actual);
#   WriteFile("$ENV{HOME}/public_html/pod/$file.html", $$actual);
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
    
