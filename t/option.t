# -*- perl -*-

use strict;
use diagnostics;
use HTML::Stream;
use Pod::Tree;
use Pod::Tree::HTML;

my $N = 1;
sub Not { print "not " }
sub OK  { print "ok ", $N++, "\n" }

print "1..8\n";

Option("toc" ,  0 , 0);
Option("toc" ,  1 , 1);
Option("hr"  ,  0 , 0);
Option("hr"  ,  1 , 1);
Option("hr"  ,  2 , 2);
Option("hr"  ,  3 , 3);
Option("base", "U"   );
Option("base", "D", "http://www.site.com/dir/");


sub Option
{
    my($option, $suffix, $value) = @_;

    my $tree = new Pod::Tree;
    my $pod  = "t/$option.pod";
    $tree->load_file($pod) or die "Can't load $pod: $!\n";

    my $actual = new IO::String;
    my $html = new Pod::Tree::HTML $tree, $actual;
    $html->set_options($option => $value);
    $html->translate;

    my $expected = ReadFile("t/$option$suffix.h_exp");
    $$actual eq $expected or Not; OK;

    WriteFile("t/$option$suffix.h_act"		              , $$actual);
#   WriteFile("$ENV{HOME}/public_html/pod/$option$suffix.html", $$actual);
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
    
