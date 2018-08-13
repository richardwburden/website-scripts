# This script crashes when the input file contains span tags with no attributes.
# Misbehaves if the input file contains a tag that normally contains text or other tags (not <br /> or <meta ... />) that is closed without a closing tag that repeats the tag name, e.g. contains <div ... /> instead of <div ...>...</div>

use HTML::TreeBuilder;
use HTML::Element;
use File::Spec;
use Fcntl ':mode';
use File::Copy;
use HTML::Entities;
#use Encode::Encoder;
$HTML::Tagset::isKnown{"domain"} = 1;
$HTML::Tagset::isHeadOrBodyElement{"domain"} = 1;

%empty = (); #use as 3rd parameter for HTML::Element->as_HTML() to specify that the HTML generated shall close all open tags

sub wrap ($$);

my $program_basename = $0;
$program_basename =~ s/\.[^\.]*$//;
close STDERR;
open (STDERR, ">$program_basename"."_err.txt") || die "can't open $program_basename"."_err.txt for writing: $!";

if (@ARGV < 1) {usage()}
my $configPath = $ARGV[0];

if ($configPath eq '-') {$configPath = "$program_basename.xml"}
else {$configPath = "$program_basename-$configPath.xml"}

#open (INPUT, $ARGV[0]) || die "can't open $ARGV[0] for reading: $!";
#open (OUTPUT, ">$ARGV[1]") || die "can't open $ARGV[1] for writing: $!";


my $domain;
my %options = ();
get_config ($configPath, \$domain, \%options);

my $docRoot = $domain->attr('docroot');
my $domainName = $domain->attr('name');

if (not defined $options{'backup_prefix'})
{die "prefix for backup file must be defined in config file\n"}

my $inpath = "";
if (defined $ARGV[1]) {$inpath = $ARGV[1]}
#Extract filenames from $inpath

$inpath =~ s%/%\\%g;

$inpath = File::Spec->join($docRoot,$inpath);

@inpath = File::Spec->splitpath($inpath);
@infiles = ();

my $is_directory = 0;
my $mode = undef;
$mode = (stat($inpath))[2];
if (defined $mode)
{$is_directory = S_ISDIR($mode)}

if ($is_directory)
{
    my $globpath = File::Spec->join($inpath,'*.?htm?');
    #print "globpath: $globpath\n";
    @infiles = glob ($globpath);
}
elsif ($inpath[2] =~ /[\?\*]/)
{
    #print "globpath: $inpath\n";
    @infiles = glob ($inpath);
}
else
{@infiles = ($inpath)}

foreach $infilepath (@infiles)
{
    my @infile = File::Spec->splitpath($infilepath);
    #Don't process the cover page
    if ($infile[2] =~ /^cover/i) {next}
    my $backup = File::Spec->join($infile[1],$options{'backup_prefix'}.$infile[2]);

    my $outfile = File::Spec->join($infile[1],$infile[2]);
    my $infile = $backup;
    copy ($outfile,$infile) || die "can't copy $outfile to $infile: $!";
    open(INFILE, $infile) || die "can't open $infile for reading: $!";
    open(OUTFILE,"+>$outfile") || die "can't open $outfile for writing: $!"; 
    open(DEBUG,">$outfile.debug.html") || die "can't open $outfile.debug.html for writing: $!"; 

#The first line of .xhtml files in .epub format typically looks like this:
#<?xml version="1.0" encoding="UTF-8" standalone="no"?>
#Save it here to be restored after the rest of the file is processed.

# This script expects to find the class names for bold, italic, etc. in 
# the second line (which may be blank).
# Class names that begin with CharOverride- can be represented without 
# that prefix (typically just the number that follows).
# Multiple class names may be used for each of the styles;
# styles are separated by ';' while multiple classes
# used for a style are separated by ','
# see sub getFullClassname and sub getMatchingContent
# example: it;2,4;boit;5;bo;6
# classes 2 and 4 call for italics, 5 for bold italics, and 6 for bold
# (each class name begins with CharOverride-)

    my $first_line = <INFILE>;
    my $second_line = <INFILE>;
    $styles_text = $second_line;
    chomp $styles_text;
    if ($styles_text =~ /<\!\-\-/)
    {
	$styles_text =~ s/^.*?<\!\-\-//;
	$styles_text =~ s/\-\->.*$//;
    }
    $styles_text =~ s/^\s+//;
    $styles_text =~ s/\s+$//;

    $second_line = '<!--'.$styles_text.'-->'."\n";

    my $tree = HTML::TreeBuilder->new();
    $tree->store_comments(1);
    $tree->parse_file(\*INFILE);
    $content = $tree->look_down('id','content');
    if (!defined $content){$content = $tree->find_by_tag_name('body')}
    if (!defined $content){$content = $tree}

    my $it_class = undef;
    my $bold_class = undef;
    my $bold_it_class = undef;
    my $sub_class = undef;
    my $sub_it_class = undef;
    my $super_class = undef;
    my $super_it_class = undef;
    my $small_caps_class = undef;
    my $uppercase_class = undef;
    my $h1_class = undef;
    if ($styles_text =~ /;/ )
    {
	my %styles = split m/;/,$styles_text;
	$it_class = $styles{'it'};
	$bold_class = $styles{'bo'};
	$sub_class = $styles{'sub'};
	$sub_it_class = $styles{'subit'};
	$super_class = $styles{'sup'};
	$super_it_class = $styles{'supit'};
	$bold_it_class = $styles{'boit'};
	$h1_class = $styles{'h1'};
	$small_caps_class= $styles{'sc'};
	$uppercase_class = $styles{'uc'};

    }

    my @MajorSubheads = $content->look_down('_tag','p','class',qr/MajorSubhead/i);
    push(@MajorSubheads,'','majorsubhead','class','h3');
    my @Subheads = $content->look_down('_tag','p','class',qr/section-title/i);
    push(@Subheads,'','subhead','class','h4');
    my @kickers = $content->look_down('_tag','p','class',qr/chapter-type/i);
    push(@kickers,'','kicker','class','h4');
    my @bylines = $content->look_down('_tag','p','class',qr/^Byline$/i);
    push(@bylines,'','byline','class','p');
    my @Heads = ();
    push (@Heads,  $content->look_down('_tag','p','class',qr/chapter-title/i));
    push(@Heads,'','head','class','h2');
#    my @BigHeads =  $content->look_down('_tag','p','class',qr/Heading-3/i);
#    push(@BigHeads,'','bighead','class','h1');

    my @extracts = $content->look_down('_tag','p','class',qr/quotes_one-para/i);
    push(@extracts,'','extract','class','p');

    my @extractbs = $content->look_down('_tag','p','class',qr/extractbegin/i);
    push(@extractbs,'','extractbegin','class','p');

    my @extractms = $content->look_down('_tag','p','class',qr/extractmiddle/i);
    push(@extractms,'','extractmiddle','class','p');

    my @extractes = $content->look_down('_tag','p','class',qr/extractend/i);
    push(@extractes,'','extractend','class','p');
   
    my @spaceAbove = $content->look_down('_tag','p','class',qr/spaceabove/i);
    push (@spaceAbove,'','spaceabove','class','p');

    my @departments = $content->look_down('_tag','p','class',qr/contents--chapter/i);
    push (@departments,'','department','class','h4');

    my @ArticleTitles = $content->look_down('_tag','p','class',qr/contents--title/i);
    push (@ArticleTitles,'','|','<','articletitle','class','p','+','strong');

    my @ArticleBlurbs = $content->look_down('_tag','p','class',qr/contents--(Text|byline)/i);
    push (@ArticleBlurbs,'','articleblurb','class','p');
my @footnote_links = ();
push (@footnote_links,  $content->look_down('_tag','a','class',qr/FootnoteLink/));
    push (@footnote_links,'','a','|||',']','text','~text','^^^','[fn_','text','~text');
my @footnote_anchors = ();
push (@footnote_anchors,  $content->look_down('_tag','a','class',qr/FootnoteAnchor/));
    push (@footnote_anchors,'','a','|||',']','text','~text','^^^','[fn_','text','~text');
    my @h1s = ();
    if (defined $h1_class)
    {
	getMatchingContent(\@h1s, $h1_class);
	push(@h1s,'','h1','class','span');
    }

    my @italics = ();
    if (defined $it_class)
    {
	getMatchingContent(\@italics, $it_class);
	push(@italics,'','em');
    }

    my @bolds = ();
    if (defined $bold_class)
    {
	getMatchingContent(\@bolds, $bold_class);
	push(@bolds,'','strong');
    }

    my @bold_italics = ();
    if (defined $bold_it_class)
    {
	getMatchingContent(\@bold_italics, $bold_it_class);
	push(@bold_italics,'','|','<','em','+','strong');
    }

    my @superscripts = ();
    if (defined $super_class)
    {
	my @matches = ();
	getMatchingContent(\@matches, $super_class);
	foreach my $elem (@matches)
	{
	    if (not defined $elem->look_down('_tag','a','class',qr/Footnote/))
	    {#remove footnote links and anchors (do not superscript them)
		push (@superscripts,$elem);
	    }
	}
	push(@superscripts,'','sup');
    }

    my @itsuperscripts = ();
    if (defined $super_it_class)
    {
	my @matches = ();
	getMatchingContent(\@matches, $super_it_class);
	foreach my $elem (@matches)
	{
	    if (not defined $elem->look_down('_tag','a','class',qr/Footnote/))
	    {#remove footnote links and anchors (do not superscript them)
		push (@itsuperscripts,$elem);
	    }
	}
	push(@itsuperscripts,'','|','<','em','+','sup');
    }
    
    my @subscripts = ();
    if (defined $sub_class)
    {
	getMatchingContent(\@subscripts, $sub_class);
	push(@subscripts,'','sub');
    }
my @itsubscripts = ();
if (defined $sub_it_class)
{
    getMatchingContent(\@itsubscripts, $sub_it_class);
    push(@itsubscripts,'','|','<','em','+','sub');
}

    my @smallcaps = ();
    if (defined $small_caps_class)
    {
	getMatchingContent(\@smallcaps, $small_caps_class);
	push(@smallcaps,'','smallcaps','class','span');
    }
    my @uppercase = ();
    if (defined $uppercase_class)
    {
	getMatchingContent(\@uppercase, $uppercase_class);
	push(@uppercase,'','uppercase','class','span');
    }



    my $prev_newelem = undef;
    my $newelem = undef;
    my $tag = undef;
    my %attribs = ();
    my $arritem = undef;
    foreach $arr (\@footnote_links,\@footnote_anchors,\@MajorSubheads,\@Subheads,\@kickers, \@bylines,
		  \@Heads,\@italics,\@bolds,\@bold_italics,\@superscripts,\@itsuperscripts,\@subscripts,\@itsubscripts,\@smallcaps,\@uppercase,\@h1s,\@extracts,\@extractbs,\@extractms,\@extractes,\@spaceAbove,\@departments,
		  \@ArticleTitles,\@ArticleBlurbs)
    {
	my @wrappers = ();
	$arritem = pop(@$arr);
	if (not defined ($arritem)) {next}
	
	while ($arritem ne '')
	{
	    push (@wrappers,$arritem);
	    $arritem = pop(@$arr);
	}
	
	while (defined ($arritem = pop(@$arr)))
	{
	    if (not defined $arritem->tag or $arritem->tag eq '')
	    {
		print DEBUG "Warning: blank tag\n";
		next
	    }
	    print DEBUG '$arritem: '.$arritem->as_HTML("","\t",\%empty);
	    my @newelems = wrap ($arritem, \@wrappers);
	    foreach $newelem (@newelems)
	    {print DEBUG '$newelem: '.$newelem->as_HTML("","\t",\%empty)}
	    my $ex_arritem = $arritem->replace_with(@newelems);
	    print DEBUG '$ex_arritem: '.$ex_arritem->as_HTML("","\t",\%empty);
	    $ex_arritem->delete;
	}
    }
    print OUTFILE $first_line;
    print OUTFILE $second_line;
    $tree->deobjectify_text();
    my $output = $tree->as_HTML("","\t",\%empty);
    print OUTFILE $output;
    close OUTFILE;
    close INFILE;
    close DEBUG;
}

sub wrap ($$)
{
    my ($elem,$wrappers_ref) = @_;
    my @newelems = ();
    my %attributes = ();
    my $prev_newelem = undef;
    my $i = 0;
=head1
 $wrapper symbols: +,<+,|,<,^  all terminate the attribute list for the previous element.  All other values for $wrapper are assumed to be alternating attributes and values, except the first, or the first following a symbol, which is assumed to be the tag name of an element.

If the next element is not going to wrap the previous one, or there is no next element, then the next wrapper list item should be '|' or '^', otherwise the previous element will be lost.

<  the previous element will wrap the element before it. If this is the first value for $wrapper, it is ignored.  

+ the contents of the original element, not the entire original element, are to be placed at the end of the content list of the previous element.  Since all elements generated in this routine are created with empty content lists, this is the same as saying that the contents of the original element will become the contents of the previous element.  This symbol must appear only once in the array of wrappers, and need not appear at all if there is only one element in the wrapper list (the default is that the contents of the original element will be placed at the end of the contents of the last element in the wrapper list).

+- Like + except the attributes of the original element will not be added to the previous element, but will
be passed on to the next eligible wrapper.

<+ the previous element will wrap the original element.  Must appear only once, exclusive of all other symbols containing '+'.  If this is the first value for $wrapper, it is ignored.

| indicates that the previous element will be appended to the replacement list.  If there is an element following '|', it will not wrap the previous element, but will be appended to the replacement list after the previous element.

|| append previous element to content list of element before it (or the original element, if none before it)

||| unconditionally append previous element to content list of the original element.

^ indicates that the previous element will be prepended to the replacement list.  If there is an element following '|', it will not wrap the previous element, but will be appended to the replacement list after the previous element.

^^ prepend previous element to content list of element before it (or the original element, if none before it)

^^^ unconditionally prepend previous element to content list of the original element.

=cut
   #
    # Otherwise, $wrapper is assumed to be an attribute of the previous tag.
    my $original_content_captured = 0;
    my $original_atts_captured = 0;
    my $keep_atts = 1; #default.  The element that receives the original content will also receive the attributes of the original element (initially; attributes specified in the wrapper list will overwrite attributes of the same name)
    if (@$wrappers_ref[0] eq 'drop_atts') {$keep_atts = 0; $i++}
    while (defined (my $wrapper = @$wrappers_ref[$i++]))
    {
	my $tag = '';
	if ($wrapper !~ /^[\^<+\|]/)
	{
	    $tag = $wrapper;
	    $wrapper = @$wrappers_ref[$i++];
	    while (defined $wrapper and $wrapper !~ /^[\^<+\|]/)
	    {
		my $att_name = $wrapper;
		$wrapper = @$wrappers_ref[$i++];
		my $value = $wrapper;
		$attributes{$att_name} = $value;
		$wrapper = @$wrappers_ref[$i++];
	    }
	    $newelem = HTML::Element->new($tag,%attributes);
	    %attributes = ();
	}
# default action when last wrapper item is part of an element (either a tag name or the value of the preceding attribute): place the content of the original element in this last element.
	if (not defined ($wrapper))
	{
	    if (not $original_content_captured)
	    { 
		$newelem->push_content($elem->detach_content());
		if ($keep_atts and not $original_atts_captured)
		{set_atts($newelem,$elem->all_external_attr())}
	    }
	    #set_atts($newelem,%attributes);
	    #%attributes = ();
	    push @newelems,$newelem;
	    last;
	}
	elsif ($wrapper eq '<')
	{
            if (not (defined $newelem)) {print STDERR "Attempt to wrap non-existent element; ignored\n";next}
	    if (defined $prev_newelem)
	    {$newelem->push_content($prev_newelem);}
	    else 
	    {$newelem->push_content($elem); 
	     if ($keep_atts and not $original_atts_captured)
	     {set_atts($newelem,$elem->all_external_attr())}
	     $original_content_captured = 1;
	     $original_atts_captured = 1;
}
	}
	elsif ($wrapper eq '+')
	{
	    if ($original_content_captured) {print STDERR "Original content already captured. '+'  Ignored\n"; next}
	    $newelem->push_content($elem->detach_content());
	    if ($keep_atts and not $original_atts_captured)
	    {set_atts($newelem,$elem->all_external_attr())}
	    $original_content_captured = 1;
	    $original_atts_captured = 1;

	}
	elsif ($wrapper eq '+-')
	{
	    if ($original_content_captured) {print STDERR "Original content already captured. '+'  Ignored\n"; next}
	    $newelem->push_content($elem->detach_content());
	    $original_content_captured = 1;
	}

	elsif ($wrapper eq '<+')
	{
	    if (not (defined $newelem)) {print STDERR "Attempt to wrap original element with non-existent element; ignored\n";next}
	    if ($original_content_captured) {print STDERR "Original content already captured. Ignored\n";}
	    else
	    {
		$newelem->push_content($elem);
		if ($keep_atts and not $original_atts_captured)
		{set_atts($newelem,$elem->all_external_attr())}
		$original_content_captured = 1;
		$original_atts_captured = 1;

	    }
	}
	elsif ($wrapper eq '|')
	{
	    #set_atts($newelem,%attributes);
	    #%attributes = ();
	    push @newelems,$newelem;
	}
	elsif ($wrapper eq '^')
	{
	    #set_atts($newelem,%attributes);
	    #%attributes = ();
	    unshift @newelems,$newelem;
	}
	elsif ($wrapper eq '||')
	{
	    if (defined $prev_newelem)
	    {$prev_newelem->push_content($newelem)}
	    else
	    {$elem->push_content($newelem)}
	}
	elsif ($wrapper eq '^^')
	{
	    if (defined $prev_newelem)
	    {$prev_newelem->unshift_content($newelem)}
	    else
	    {$elem->unshift_content($newelem)}
	}
	elsif ($wrapper eq '|||')
	{
	    $elem->push_content($newelem)
	}
	elsif ($wrapper eq '^^^')
	{
	    $elem->unshift_content($newelem)
	}

	$prev_newelem = $newelem;
    }
    return @newelems;
}

#sets attributes for the new element that are not already set by the script.
#Attributes specified for the new, replacement element in the script take priority 
#over those found in the original element in the webpage.
sub set_atts
{
    my ($elem,%atts) = @_;
    foreach $att (keys %atts)
    {
	if (not defined $elem->attr($att))
	{$elem->attr($att,$atts{$att})}
    }
    return
}

sub get_config
{
	my ($configPath, $domainRef, $optionsRef) = @_;

	open (CONFIG, "$configPath") || die "can't open $configPath for reading: $!";

	my $tree = HTML::TreeBuilder->new();
	$tree->store_comments(1); #to exclude commented-out configuration code from interpretation
	$tree->parse_file(\*CONFIG);
	$$domainRef = $tree->find_by_tag_name ("domain");
	my @options = $tree->find_by_tag_name ("option");
	foreach $option (@options)
	{
		my $key = $option->attr('id');
		my $value = $option->attr('value');
		if (defined $value)
		{
			$$optionsRef{$key} = $value;
		}
		else
		{
			$$optionsRef{$key} = '';
		}
	}
}

sub usage
{
    my $dcf = $program_basename.'.xml';
    print <<EOF;
perl $0 {-|<config pathname>} <pathname>
<config pathname> is the pathname of the configuration file, relative to $0
- uses the default configuration file, $dcf
<pathname> is the pathname of the input file, relative to the website
document root as specified in the configuration file, however:
It should begin with a forward slash, use only forward slashes, and
should be quoted if it contains spaces.  The spaces and other non-web-safe
characters should not be converted to web-safe entities like '%20'

In the input file: insert a style tag with attributes bo,it,boit,sup,sub,supit to indicate which of the InDesign-generated CSS classes are to be replaced with <strong>,<em>,<strong><em>,<sup>,<sub>,<sup><em> tags respectively. If the CSS class name is of the form "char-style-override-N" where N is an integer, then the value of the attribute can be just that integer N, otherwise, the full name of the class must be used.  Within each of the style tag attributes, mulitple values may be used to cause the substitutions to be applied to multiple CSS classes, with each value separated by a comma.
EOF

exit
}


sub getMatchingContent
{

    my @it_classes = split m%,%, $_[1];
    my $arRef = $_[0];

    foreach my $part (@it_classes)
    {
	my $class = getFullClassName($part);
	push (@$arRef, $content->look_down('_tag','span','class',$class))
    }
}

sub getFullClassName
{
    if ($_[0] =~ m/^\d+$/) {return 'CharOverride-'.$_[0]}
    else {return $_[0]}
}
