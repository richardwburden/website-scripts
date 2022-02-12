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


open(ARCHIVEINDEXTEMPLATEDOCTYPE, "archive_issue_index_template_doctype-utf8.txt") || die "can't open archive_issue_index_doctype-utf8.txt for reading: $!";


#include the server side include, which is inside a comment

my $aitdoctype = "";
while(<ARCHIVEINDEXTEMPLATEDOCTYPE>)
{
    $aitdoctype .= $_;
}
close ARCHIVEINDEXTEMPLATEDOCTYPE;

open (INFILE, $ARGV[0]) || die "can't open $ARGV[0] for reading: $!";

my $infile = "";
while (<INFILE>)
{
    my $line = $_;
    $line =~ s%&nbsp;%<span class="nbsp"></span>%g;
    $infile .= $line;
}
close INFILE;

my $tree = HTML::TreeBuilder->new;
$tree->parse($infile);

my @nbsp = $tree->look_down('class','nbsp');
foreach $nbsp (@nbsp)
{$nbsp->replace_with('&nbsp;')->delete}

open (OUTFILE, "+>$ARGV[1]") || die "can't open $ARGV[1] for writing: $!";




my $output = $tree->as_HTML("","\t",\%empty);
my $eolpos = index($output,"\n");
$output = substr($output,$eolpos+1);
my $html = $aitdoctype;
$html .= $output;
binmode(OUTFILE, ":utf8");
print OUTFILE $html;
close OUTFILE;
