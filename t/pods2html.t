# -*- perl -*-

use strict;
use diagnostics;
use Config;

my $Skip = "# Skipped: test skipped on this platform\n";
my $N    = 1;

sub Not  { print "not " }
sub OK   { print "ok ", $N++, "\n" }
sub Skip { print "ok ", $N++, " $Skip\n" for 1..$_[0] }


print "1..4\n";

my $dir = "t/pods2html.d";
Simple($dir);
Subdir($dir);

if ($Config{osname} =~ /Win32/)
{
    Skip(2);
}
else
{  
    Recurse($dir);
}


sub Simple
{
    my $d = shift;

    system "rm -rf $d/html_act";
    system "perl blib/script/pods2html $d/pod $d/html_act";
    RDiff("$d/html_exp", "$d/html_act") and Not; OK;
}

sub Subdir
{
    my $d = shift;

    system "rm -rf $d/A";
    system "perl blib/script/pods2html $d/pod $d/A/B/C";
    RDiff("$d/html_exp", "$d/A/B/C") and Not; OK;
}

sub Recurse
{
    my $d = shift;
    
    system "rm -rf $d/podR/HTML";
    system "blib/script/pods2html $d/podR $d/podR/HTML";
    RDiff("$d/podR_exp", "$d/podR") and Not; OK;
    system "blib/script/pods2html $d/podR $d/podR/HTML";
    RDiff("$d/podR_exp", "$d/podR") and Not; OK;
}


sub RDiff  # Recursive subdirectory comparison
{
    my($a, $b) = @_;

    eval { DirCmp($a, $b) };

    print STDERR $@;
    $@
}


sub DirCmp
{
    my($a, $b) = @_;

    my @a = Names($a);
    my @b = Names($b);

    ListCmp(\@a, \@b) and die "Different names: $a $b\n";

       @a = map { "$a/$_" } @a;
       @b = map { "$b/$_" } @b;

    for (@a, @b) { -f or -d or die "bad type: $_\n" }

    while (@a and @b)
    {
	$a = shift @a;
	$b = shift @b;

	-f $a and -f $b and FileCmp($a, $b) and return "$a ne $b";
	-d $a and -d $b and DirCmp ($a, $b);
	-f $a and -d $b or -d $a and -f $b  and return "type mismatch: $a $b";
    }

    ''
}

sub Names
{
    my $dir = shift;

    opendir DIR, $dir or die "Can't opendir $dir: $!\n";
    my @names = grep { not m(^\.) and $_ ne 'CVS' } readdir(DIR);
    closedir DIR;

    sort @names
}

sub ListCmp
{
    my($a, $b) = @_;
    
    @$a == @$b or return 1;

    for (my $i=0; $i<@$a; $i++)
    {
	$a->[$i] eq $b->[$i]
	    or return 1;
    }

    0
}

sub FileCmp
{
    my($a, $b) = @_;

    local $/ = undef;

    open A, $a or die "Can't open $a: $!\n";
    open B, $b or die "Can't open $b: $!\n";

    <A> ne <B>
}
