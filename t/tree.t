# -*- perl -*-

use strict;
use Pod::Tree;

my $N = 1;
sub Not { print "not " }
sub OK  { print "ok ", $N++, "\n" }

print "1..6\n";

for my $file (qw(cut paragraph list sequence link for))
{
    my $tree = new Pod::Tree;
    my $pod  = "t/$file.pod";
    $tree->load_file($pod) or die "Can't load $pod: $!\n";

    my $actual   = $tree->dump;
    my $expected = ReadFile("t/$file.p_exp");
    $actual eq $expected or Not; OK;

    WriteFile("t/$file.p_act", $actual);
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

