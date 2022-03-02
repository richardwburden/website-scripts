#This script reads an HTML file on $ARGV[0] and outputs XML-compatible HTML on $ARGV[1]
#must be run in same directory as archive_issue_index_template_doctype.txt,
#which references w3centities-f.ent in the same directory
use utf8;
use open ':encoding(utf-8)';
binmode(STDOUT, ":utf8");
use HTML::TreeBuilder;
use HTML::Element;
use HTML::Entities;

%empty = (); #use as 3rd parameter for HTML::Element->as_HTML() to specify that the HTML generated shall close all open tags


open (INFILE, $ARGV[0]) || die "can't open $ARGV[0] for reading: $!";

my $infile = "";
while (<INFILE>)
{
    my $line = $_;
#&nbsp; and &amp; will be stripped out when the tree is converted back to HTML in $tree->as_HTML("","\t",\%empty); because the first parameter, "", specifies that "safe" entities will be converted to their characters.  This is necessary to allow correct UTF-8 output.  Unfortunately, the & character is not XML-compliant, and the character substituted for &nbsp; does not display correctly in browsers. We are betting here that the &nbsp; will not appear in any attribute, otherwise, we would have to treat it like the &amp; and substitute some unlikely string for it until after $tree->as_HTML is executed, then restore the original.
    $line =~ s%&nbsp;%<span class="nbsp"></span>%g;
    $line =~ s%&amp;%__#_#__amp;%g;
#    $line =~ s%&gt;%__#_#__gt;%g;
#    $line =~ s%&lt;%__#_#__lt;%g;
#in case we have any & that are not &amp;:
#    $line =~ s%&%__#_#__amp;%g;

    $infile .= $line;
}
close INFILE;

my $tree = HTML::TreeBuilder->new;
$tree->store_comments(1);
$tree->parse($infile);

my @nbsp = $tree->look_down('class','nbsp');
foreach $nbsp (@nbsp)
{$nbsp->replace_with('&nbsp;')->delete}
open (OUTFILE, "+>$ARGV[1]") || die "can't open $ARGV[1] for writing: $!";




my $output = $tree->as_HTML("","",\%empty);
#restore the original &amp;
$output =~ s%__#_#__amp;%&amp;%gs;
$output =~ s%\n\s+%\n%gs;
$output =~ s%\n+% %gs;
binmode(OUTFILE, ":utf8");
print OUTFILE $output;
close OUTFILE;
