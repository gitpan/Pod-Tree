# -*- perl -*-

use strict;
use diagnostics;
use Pod::Tree;
use Pod::Tree::Pod;

my $N = 1;
sub Not { print "not " }
sub OK  { print "ok ", $N++, "\n" }

print "1..6\n";


for my $file (qw(cut paragraph list sequence for link))
{
    my $tree1    = new Pod::Tree;
       $tree1->load_file("t/$file.pod");
    my $string   = new IO::String;
    my $pod      = new Pod::Tree::Pod $tree1, $string;
       $pod->translate;

    my $tree2    = new Pod::Tree;
       $tree2->load_string($$string);
    my $actual   = $tree2->dump;
    my $expected = ReadFile("t/$file.p_exp");
    $actual eq $expected or Not; OK;

    WriteFile("t/$file.pod2"   , $$string);
    WriteFile("t/$file.pod_act",  $actual);
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
    
