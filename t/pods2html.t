# -*- perl -*-

use strict;
use diagnostics;

my $N = 1;
sub Not { print "not " }
sub OK  { print "ok ", $N++, "\n" }

print "1..4\n";

my $d = "t/pods2html.d";

system "rm -rf $d/html_act";
system "blib/script/pods2html $d/pod $d/html_act";
system "diff -r $d/html_exp $d/html_act" and Not; OK;

system "rm -rf $d/A";
system "blib/script/pods2html $d/pod $d/A/B/C";
system "diff -r $d/html_exp $d/A/B/C" and Not; OK;

system "rm -rf $d/podR/HTML";
system "blib/script/pods2html $d/podR $d/podR/HTML";
system "diff -r $d/podR_exp $d/podR" and Not; OK;
system "blib/script/pods2html $d/podR $d/podR/HTML";
system "diff -r $d/podR_exp $d/podR" and Not; OK;

