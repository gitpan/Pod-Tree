# Copyright 1999-2000 by Steven McDougall.  This module is free
# software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Pod::Tree::HTML;

require 5.004;

use strict;
use vars qw(&isa);
use HTML::Stream;
use IO::File;
use Pod::Tree;

$Pod::Tree::HTML::VERSION = '1.04';


my $LinkFormat = [ sub { my($b,$p,$f)=@_; ""              },
		   sub { my($b,$p,$f)=@_;           "#$f" },
                   sub { my($b,$p,$f)=@_;    "$p.html"    },
                   sub { my($b,$p,$f)=@_;    "$p.html#$f" },
                   sub { my($b,$p,$f)=@_; "$b/"           },
                   sub { my($b,$p,$f)=@_;           "#$f" },
                   sub { my($b,$p,$f)=@_; "$b/$p.html"    },
                   sub { my($b,$p,$f)=@_; "$b/$p.html#$f" } ];

sub new
{
    my($class, $source, $dest, %options) = @_;
    defined $dest or die "Pod::Tree::HTML::new: not enough arguments\n";

    my $tree   = _resolve_source($source);
    my $stream = _resolve_dest  ($dest  ); 

    my $HTML = { tree        => $tree,
		 root        => $tree->get_root,
		 stream      => $stream,
		 text_method => 'text',
		 bgcolor     => '#fffff8',
		 text        => '#000000',
	         hr          => 1,
	         toc         => 1,
	         base        => '',
	         link_format => $LinkFormat,
		 link_map    => Pod::Tree::HTML::LinkMap->new() };

    bless $HTML, $class;

    $HTML->set_options(%options);
    $HTML
}


sub _resolve_source
{
    my $source = shift;
    my $ref    = ref $source;
    local *isa = \&UNIVERSAL::isa;

    isa $source, 'Pod::Tree' and return $source;

    my $tree = new Pod::Tree;
    not $ref		    and $tree->load_file     ( $source);
    isa $source, 'IO::File' and $tree->load_fh	     ( $source);
    $ref eq 'SCALAR'        and $tree->load_string   ($$source);
    $ref eq 'ARRAY'         and $tree->load_paragaphs( $source);

    $tree->loaded or 
	die "Pod::Tree::HTML::_resolve_source: Can't load POD from $source\n";

    $tree    
}


sub _resolve_dest
{
    my $dest   = shift;
    local *isa = \&UNIVERSAL::isa;

    isa $dest, 'HTML::Stream' and return 		  $dest;
    ref $dest 		      and return new HTML::Stream $dest;

    my $fh = new IO::File;
    $fh->open(">$dest") or die "Pod::Tree::HTML::new: Can't open $dest: $!\n";
    new HTML::Stream $fh
}


sub set_options
{
    my($html, %options) = @_;

    my($key, $value);
    while (($key, $value) = each %options)
    {
	defined $value or $value = '';  # -w
	$html->{$key} = $value;
    }
}


sub get_options
{
    my($html, @options) = @_;

    map { $html->{$_} } @options
}


sub get_stream { shift->{stream} } 


sub translate
{
    my $html    = shift;
    my $stream 	= $html->{stream};
    my $bgcolor = $html->{bgcolor};
    my $text 	= $html->{text};
    my $title   = $html->_make_title;
    my $base    = $html->{base};

    $stream->HTML->HEAD;
    
    defined $title and $stream->TITLE->text($title)->_TITLE;

    $stream->_HEAD
	   ->BODY(BGCOLOR => $bgcolor, TEXT => $text);

    $html->_emit_toc;
    $html->_emit_body;

    $stream->nl
	   ->_BODY
	   ->_HTML
}


sub _make_title
{
    my $html   = shift;

    my $title = $html->{title};
    defined $title and return $title;

    my $node1  = $html->{root}->get_children->[1];
    $node1 or return undef;

    my $text = $node1->get_deep_text;
    ($title) = split m(-), $text;

    $title  or return undef;      # to quiet -w
    $title =~ s(\s+$)();

    $title
}


sub _emit_toc
{
    my $html = shift;
    $html->{toc} or return;

    my $root  = $html->{root};
    my $nodes = $root->get_children;
    my @nodes = @$nodes;

    $html->_emit_toc_1(\@nodes);

    $html->{hr} > 0 and $html->{stream}->HR;
}


sub _emit_toc_1
{
    my($html, $nodes) = @_;
    my $stream = $html->{stream};

    $stream->UL;

    while (@$nodes)
    {
	my $node = $nodes->[0];
	is_c_head2 $node and $html->_emit_toc_2   ($nodes), next;
	is_c_head1 $node and $html->_emit_toc_item($node );
	shift @$nodes;
    }

    $stream->_UL;
}


sub _emit_toc_2
{
    my($html, $nodes) = @_;
    my $stream = $html->{stream};

    $stream->UL;

    while (@$nodes)
    {
	my $node = $nodes->[0];
	is_c_head1 $node and last;
	is_c_head2 $node and $html->_emit_toc_item($node);
	shift @$nodes;
    }

    $stream->_UL;
}


sub _emit_toc_item
{
    my($html, $node) = @_;
    my $stream = $html->{stream};
    my $target = $html->_make_anchor($node);

    $stream->LI->A(HREF => "#$target");
    $html->_emit_children($node);
    $stream->_A->_LI;
}


sub _emit_body
{
    my $html = shift;
    my $root = $html->{root};
    $html->_emit_children($root);
}


sub _emit_children
{
    my($html, $node) = @_;

    my $children = $node->get_children;

    for my $child (@$children)
    {
	$html->_emit_node($child);
    }
}


sub _emit_siblings
{
    my($html, $node) = @_;

    my $siblings = $node->get_siblings;

    if (@$siblings==1 and $siblings->[0]{type} eq 'ordinary')
    {
	# don't put <p></p> around a single ordinary paragraph
	$html->_emit_children($siblings->[0]);
    }
    else
    {
	for my $sibling (@$siblings)
	{
	    $html->_emit_node($sibling);
	}
    }
    
}


sub _emit_node
{
    my($html, $node) = @_;
    my $type = $node->{type};

    for ($type)
    {
	/command/  and $html->_emit_command ($node);
	/for/      and $html->_emit_for     ($node);
	/item/     and $html->_emit_item    ($node);
	/list/     and $html->_emit_list    ($node);
	/ordinary/ and $html->_emit_ordinary($node);
	/sequence/ and $html->_emit_sequence($node);
	/text/     and $html->_emit_text    ($node);
	/verbatim/ and $html->_emit_verbatim($node);
    }
}


my %HeadTag = ( head1 => { 'open' => 'H1', 'close' => '_H1', level => 1 },
	        head2 => { 'open' => 'H2', 'close' => '_H2', level => 2 } );

sub _emit_command
{
    my($html, $node) = @_;
    my $stream   = $html->{stream};
    my $command  = $node->get_command;
    my $anchor   = $html->_make_anchor($node);
    my $head_tag = $HeadTag{$command};

    $html->_emit_hr($head_tag->{level});

    my $tag;
    $tag = $head_tag->{'open'};
    $stream->$tag()->A(NAME => $anchor);

    $html->_emit_children($node);

    $tag = $head_tag->{'close'};
    $stream->_A->$tag();
}


sub _emit_hr
{
    my($html, $level) = @_;
    $html->{hr} > $level or return;
    $html->{skip_first}++ or return;
    $html->{stream}->HR;
}    


sub _emit_for
{
    my($html, $node) = @_;
    
    my $interpreter = $node->get_arg;
    lc $interpreter eq 'html' or return;

    my $stream = $html->{stream};
    $stream->P;
    $stream->io->print($node->get_text);
    $stream->_P;
}


sub _emit_item
{
    my($html, $node) = @_;

    my $stream = $html->{stream};
    my $item_type = $node->get_item_type;
    for ($item_type)
    {
	/bullet/ and do
	{
	    $stream->LI();
	    $html->_emit_siblings($node);
	    $stream->_LI();
	};

	/number/ and do
	{
	    $stream->LI();
	    $html->_emit_siblings($node);
	    $stream->_LI();
	};

	/text/   and do
	{
	    my $anchor = $html->_make_anchor($node);
	    $stream->DT->A(NAME => "$anchor");
	    $html->_emit_children($node);
	    $stream->_A->_DT->DD;
	    $html->_emit_siblings($node);
	    $stream->_DD;
	};
    }

}


my %ListTag  = (bullet => { 'open' => 'UL', 'close' => '_UL' },
		number => { 'open' => 'OL', 'close' => '_OL' },
		text   => { 'open' => 'DL', 'close' => '_DL' } );

sub _emit_list
{
    my($html, $node) = @_;
    my($list_tag, $tag);    # to quiet -w, see beloew

    my $stream    = $html->{stream};
    my $list_type = $node->get_list_type;

    $list_type and $list_tag = $ListTag{$list_type};
    $list_tag  and $tag      = $list_tag->{'open'};
    $tag and $stream->$tag();

    $html->_emit_children($node);
    
    $list_tag and $tag = $list_tag->{'close'};
    $tag and $stream->$tag();
}


sub _emit_ordinary
{
    my($html, $node) = @_;
    my $stream = $html->{stream};

    $stream->P;
    $html->_emit_children($node);
    $stream->_P;
}


sub _emit_sequence
{
    my($html, $node) = @_;

    for ($node->get_letter)
    {
	/I|B|C|F/ and $html->_emit_element($node), last;
	/S/       and $html->_emit_nbsp   ($node), last;
	/L/       and $html->_emit_link   ($node), last;
	/X/       and $html->_emit_index  ($node), last;
	/E/       and $html->_emit_entity ($node), last;
    }
}


my %ElementTag = (I => { 'open' => 'I'   , 'close' => '_I'    },
		  B => { 'open' => 'B'   , 'close' => '_B'    },
		  C => { 'open' => 'CODE', 'close' => '_CODE' },
		  F => { 'open' => 'I'   , 'close' => '_I'    } );

sub _emit_element
{
    my($html, $node) = @_;

    my $letter = $node->get_letter;
    my $stream = $html->{stream};

    my $tag;
    $tag = $ElementTag{$letter}{'open'};
    $stream->$tag();
    $html->_emit_children($node);
    $tag = $ElementTag{$letter}{'close'};
    $stream->$tag();
}


sub _emit_nbsp
{
    my($html, $node) = @_;

    my $old_method = $html->{text_method};
    $html->{text_method} = 'text_nbsp';
    $html->_emit_children($node);
    $html->{text_method} = 'text';
}


sub _emit_link
{
    my($html, $node) = @_;

    my $stream   = $html->{stream};
    my $base     = $html->{base};
    my $target   = $node->get_target;
    my $page     = $target->get_page;
    my $section  = $target->get_section;

    my $link_map = $html->{link_map};
    ($base, $page, $section) = $link_map->map($base, $page, $section);

    $base =~ s(/$)();
    my $fragment = $html->_escape_text($section);

    my $i      = $html->_make_index($base, $page, $fragment);
    my $format = $html->{link_format}[$i];
    my $url    = &$format($base, $page, $fragment);

    $stream->A(HREF=>$url);
    $html->_emit_children($node);
    $stream->_A;
}


sub _make_index
{
    my $html = shift;
    my $i = 0;

    for (@_)
    {
	$i <<= 1;
	length and $i |= 1;
    }

    $i
}


sub _emit_index
{
    my($html, $node) = @_;

    my $stream = $html->{stream};
    my $anchor = $html->_make_anchor($node);
    $stream->A(NAME=>$anchor);
    $html->_emit_children($node);
    $stream->_A;
}


sub _emit_entity
{
    my($html, $node) = @_;

    my $stream = $html->{stream};
    my $entity = $node->get_deep_text;
    $stream->ent($entity);
}


sub _emit_text
{
    my($html, $node) = @_;
    my $stream 	     = $html->{stream};
    my $text         = $node->get_text;
    my $text_method  = $html->{text_method};

    $stream->$text_method($text);
}


sub _emit_verbatim
{
    my($html, $node) = @_;
    my $stream = $html->{stream};
    my $text   = $node->get_text;
    $text =~ s(\n\n$)();

    $stream->PRE->text($text)->_PRE;
}


sub _make_anchor
{
    my($html, $node) = @_;
    my $text = $node->get_deep_text;
       $text =~ s(   \s*\n\s*/  )( )xg;  # close line breaks
       $text =~ s( ^\s+ | \s+$  )()xg;   # clip leading and trailing WS
       $html->_escape_text($text)
}

 
sub _escape_text
{
    my($html, $text) = @_;
    $text =~ s(([^\w\-.!~*'()]))(sprintf("%%%02x", ord($1)))eg;
    $text
}


package Pod::Tree::HTML::LinkMap;

sub new
{
    my $class = shift;
    bless {}, $class
}

sub map
{
    my($link_map, $base, $page, $section) = @_;

    $page =~ s(::)(/)g;

    ($base, $page, $section)
}

__END__

=head1 NAME

Pod::Tree::HTML - Generate HTML from a Pod::Tree

=head1 SYNOPSIS

  use Pod::Tree::HTML;

  $source =   new Pod::Tree;
  $source =  "file.pod";
  $source =   new IO::File;
  $source = \$pod;
  $source = \@pod;
    
  $dest   =   new HTML::Stream;
  $dest   =   new IO::File;
  $dest   =  "file.html";

  $html   =   new Pod:::Tree::HTML $source, $dest, %options;

  $html->set_options(%options);
  @values = $html->get_options(@keys);

  $html->translate;

=head1 DESCRIPTION

C<Pod::Tree::HTML> reads a POD and translates it to HTML.
The source and destination are fixed when the object is created.
Options are provided for controlling details of the translation.

The C<translate> method does the actual translation.

For convenience, 
C<Pod::Tree::HTML> can read PODs from a variety of sources,
and write HTML to a variety of destinations.
The C<new> method resolves the I<$source> and I<$dest> arguments.

=head2 Source resolution

C<Pod::Tree::HTML> can obtain a POD from any of 5 sources.
C<new> resolves I<$source> by checking these things,
in order:

=over 4

=item 1

If I<$source> C<isa> C<POD::Tree>, 
then the POD is taken from that tree.

=item 2

If I<$source> is not a reference, 
then it is taken to be the name of a file containing a POD.

=item 3

If I<$source> C<isa> C<IO::File>, 
then it is taken to be an C<IO::File> object that is already
open on a file containing a POD.

=item 4

If I<$source> is a SCALAR reference,
then the text of the POD is taken from that scalar.

=item 5

if I<$source> is an ARRAY reference,
then the paragraphs of the POD are taken from that array.

=back

If I<$source> isn't any of these things,
C<new> C<die>s.

=head2 Destination resolution

C<Pod::Tree::HTML> can write HTML to any of 3 destinations.
C<new> resolves I<$dest> by checking these things,
in order:

=over 4

=item 1

If I<$dest> C<isa> C<HTML::Stream>,
then it writes to that stream.

=item 2

If I<$dest> is a reference,
then it is taken to be an C<IO::File> object
that is already open on the file where the HTML will be written.

=item 3

If I<$dest> is not a reference,
then it is taken to be the name of the file where the HTML will be written.

=back

=head1 METHODS

=over 4

=item I<$html> = C<new> C<Pod::Tree::HTML> I<$source>, I<$dest>, I<%options>

Creates a new C<Pod::Tree::HTML> object.

I<$html> reads a POD from I<$source>,
and writes HTML to I<$dest>.
See L</Source resolution> and L</Destination resolution> for details.

Options controlling the translation may be passed in the I<%options> hash.
See L</OPTIONS> for details.

=item I<$html>->C<set_options>(I<%options>)

Sets options controlling the translation.
See L</OPTIONS> for details.

=item I<@values> = I<$html>->C<get_options>(I<@keys>)

Returns the current values of the options specified in I<@keys>.
See L</OPTIONS> for details.

=item I<$html>->C<translate>

Translates the POD to HTML.
This method should only be called once.

=back

=head1 OPTIONS

=over 4

=item C<base> => I<$url>

Translate C<LE<lt>E<gt>> sequences into HTML
links relative to I<$url>.

=item C<link_map> => I<$link_map>

Sets the link mapping object.
Before emitting an LE<lt>E<gt> markup in HTML, 
C<translate> calls

(I<$base>, I<$page>, I<$section>) = I<$link_map>-E<gt>C<map>(I<$base>, I<$page>, I<$section>);

Where

=over 4

=item I<$base>

is the URL given in the C<base> option.

=item I<$page>

is the man page named in the LE<lt>E<gt> markup.

=item I<$section>

is the man page section given in the LE<lt>E<gt> markup.

=back

The C<map> method may perform arbitrary mappings on its arguments.

The default link_map translates C<::> sequences in I<$page> to C</>.

=item C<toc> => [C<0>|C<1>]

Includes or omits the table of contents.
Default is to include the TOC.

=item C<hr> => I<$level>

Controls the profusion of horizontal lines in the output, as follows:

    $level   horizontal lines
    0 	     none
    1 	     between TOC and body
    2 	     after each =head1
    3 	     after each =head1 and =head2

Default is level 1.

=item C<bgcolor> => I<#rrggbb>

Set the background color to I<#rrggbb>.
Default is C<#fffff8>, which is an off-white.

=item C<text> => I<#rrggbb>

Set the text color to I<#rrggbb>.
Default is C<#fffff>, which is black.

=item C<title> => I<title>

Set the page title to I<title>.
If no C<title> option is given, 
C<Pod::Tree::HTML> will attempt construct a title from the 
second paragrah of the POD.
This supports the following style:

    =head1 NAME
    
    ls - list contents of directory

=back

=head1 LINKS and TARGETS

C<Pod::Tree::HTML> automatically generates HTML name anchors for
all =head1 and =head2 command paragraphs,
and for text items in =over lists.
The text of the paragraph becomes the C<name> entity in the anchor.
Markups are ignored and the text is escaped according to RFC 2396.

For example, the paragraph

	=head1 C<Foo> Bar

is translated to 

	<h1><a name="Foo%20Bar"><code>Foo</code> Bar</a></h1>

To link to a heading, 
simply give the text of the heading in a C<LE<lt>E<gt>> markup.
The text must match exactly; 
markups may vary.
Either of these would link to the heading shown above

	L</C<Foo> Bar>
	L</Foo Bar>

To generate HTML anchors in other places, 
use the index (C<XE<lt>E<gt>>) markup

	We can link to X<this text>.

and link to it as usual

	L</this text> uses the index markup.

=head1 DIAGNOSTICS

=over 4

=item C<Pod::Tree::HTML::new: not enough arguments>

(F) C<new> called with fewer than 2 arguments.

=item C<Pod::Tree::HTML::new: Can't load POD from $source>

(F) C<new> couldn't resolve the I<$source> argument.
See L</Source resolution> for details.

=item C<Pod::Tree::HTML::new: Can't open $dest: $!>

(F) The destination file couldn't be opened.

=back

=head1 SEE ALSO

perl(1), L<C<Pod::Tree>>, L<C<Pod::Tree::Node>>

=head1 AUTHOR

Steven McDougall, swmcd@world.std.com

=head1 COPYRIGHT

Copyright 1999-2000 by Steven McDougall. This module is free
software; you can redistribute it and/or modify it under the same
terms as Perl itself.

