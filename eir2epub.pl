# This script crashes when the input file contains span tags with no attributes.
# Misbehaves if the input file contains a tag that normally contains text or other tags (not <br /> or <meta ... />) that is closed without a closing tag that repeats the tag name, e.g. contains <div ... /> instead of <div ...>...</div>

#This script requires a web server to be running on the local host with the document root same as in the config file for this script.

#/* The user may specify how a particular character style override is to be handled by editing the CSS file, adding '_XX_' to the beginning of the font-family for that style (adding a font-family if there is none), where XX is any character style override type recognized by eir2epub.pl, e.g. 'h1' for the 'h1_class', 'sf' for the 'sf_class'   */	

use HTML::TreeBuilder;
use HTML::Element;
use File::Spec;
use Fcntl ':mode';
use File::Copy;
use HTML::Entities;
use URI;
use URI::file;
use Cwd;
#use Encode::Encoder;
$HTML::Tagset::isKnown{"domain"} = 1;
$HTML::Tagset::isHeadOrBodyElement{"domain"} = 1;

%empty = (); #use as 3rd parameter for HTML::Element->as_HTML() to specify that the HTML generated shall close all open tags

sub wrap ($$);
sub processCss ($$);
sub usage;

my $program_basename = $0;
$program_basename =~ s/\.[^\.]*$//;
close STDERR;
open (STDERR, ">$program_basename"."_err.txt") || die "can't open $program_basename"."_err.txt for writing: $!";

if (@ARGV < 1) {usage()}

#debug output is off by default.  It is turned on by using 'debug' as the first command-line argument OR by defining debug with any value in the configuration file.
my $debug = 0;
if (lc($ARGV[0]) eq 'debug')
{
    $debug = 1;
    shift @ARGV
}

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
my $localHostURL = $options{'localHostURL'};
if (not defined $localHostURL) {$localHostURL = 'http://localhost:8000'}
if (not defined $options{'backup_prefix'})
{die "prefix for backup file must be defined in config file\n"}

my $browserPath = $options{'browserPath'};
my $browserOptions = $options{'browserOptions'};
if (not defined $browserOptions) {$browserOptions = '--headless --dump-dom'}
if (not defined $browserPath) {$browserPath = '%BROWSER_PATH%'}
my $processCssScriptURL = $options{'processCssScriptURL'};
my $jqueryURL = $options{'jqueryURL'};
if (not defined $processCssScriptURL) {$processCssScriptURL = 'processCss.js'}
if (not defined $jqueryURL) {$jqueryURL = 'jquery-1.11.3.min.js'}
my $sourceFilesRoot = $options{'sourceFilesRoot'};
if (not defined $sourceFilesRoot) {$sourceFilesRoot = ""}
#debug output is off by default.  It is turned on by using 'debug' as the first command-line argument OR by defining debug with any value in the configuration file.
if (defined $options{'debug'}){$debug = 1}

#$processCssScriptURL = URI::file->new($processCssScriptPath);
#$jqueryURL = URI::file->new($jqueryPath);


my $inpath = "";
if (defined $ARGV[1]) {$inpath = $ARGV[1]}
#Extract filenames from $inpath

$inpath =~ s%/%\\%g;

$inpath = File::Spec->join($docRoot,$sourceFilesRoot,$inpath);

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
    print "glob path: $globpath\n";
    @infiles = glob ($globpath);
}
else {usage}

foreach $infilepath (@infiles)
{
    my @infile = File::Spec->splitpath($infilepath);
    #Don't process the cover page
    if ($infile[2] =~ /^cover/i) {next}
    my $backup = File::Spec->join($infile[0],$infile[1],$options{'backup_prefix'}.$infile[2]);

    my $outfile = File::Spec->join($infile[0],$infile[1],$infile[2]);
    my $outfiledir = File::Spec->join($infile[0],$infile[1]);
    my $infile = $backup;
    copy ($outfile,$infile) || die "can't copy $outfile to $infile: $!";
    open(INFILE, $infile) || die "can't open $infile for reading: $!";
    open(OUTFILE,"+>$outfile") || die "can't open $outfile for writing: $!";
    if ($debug)
    {
	open(DEBUG,">$outfile.debug.html") || die "can't open $outfile.debug.html for writing: $!"; 
    }
    else # /dev/null for Windows
    {
	open(DEBUG,">nul") || die "can't open nul for writing: $!"; 
    }

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

    my $tree = HTML::TreeBuilder->new();
    $tree->store_comments(1);
    $tree->parse_file(\*INFILE);
    my $head = $tree->find_by_tag_name('head');
    my $charset = HTML::Element->new('meta','charset' => 'utf-8');
    $head->preinsert($charset); #allows broswer to correctly interpret locally saved temp.html file.  Necessary when browserPath set to empty string, to allow user to manually load temp.html into a browser, let it run JavaScript, then dump the DOM to temp2.html, instead of letting this script invoke a headless broswer.

    my $styles_text = processCss($tree,$outfiledir);

    my $styles_comment = HTML::Element->new('~comment','text' => $styles_text);
    $head = $tree->find_by_tag_name('head');
    $head->preinsert($styles_comment); #for debugging processCss
    
    $content = $tree->look_down('id','content');
    if (!defined $content){$content = $tree->find_by_tag_name('body')}
    if (!defined $content){$content = $tree}

    my $it_class = undef;
    my $bold_class = undef;
    my $sub_class = undef;
    my $super_class = undef;
    my $h1_class = undef;
    my $sc_class = undef;
    my $uc_class = undef;
    my $sharp_flat_class = undef;
    my $ns_class = undef;
    my $nw_class = undef;

    if ($styles_text =~ /;/ )
    {
	my %styles = split m/;/,$styles_text;
	$it_class = $styles{'it'};
	$bold_class = $styles{'bo'};
	$sub_class = $styles{'sub'};
	$super_class = $styles{'sup'};
	$h1_class = $styles{'h1'};
	$sm_caps_class = $styles{'sc'};
	$uc_class = $styles{'uc'};
	$sharp_flat_class = $styles{'sf'};
	$ns_class = $styles{'ns'}; #font-style: normal
	$nw_class = $styles{'nw'}; #font-weight: normal
    }

    my @LightSubheads = $content->look_down('_tag','p','class',qr/light_subhead/);
    push(@LightSubheads,'','light_subhead','class','h4','no more wrappers');

    my @MajorLightSubheads = $content->look_down('_tag','p','class',qr/MajorLightSubhead/i);
    push(@MajorLightSubheads,'','light_subhead','class','h3','no more wrappers');
 my @CenteredHeads = $content->look_down('_tag','p','class',qr/CenteredHead/i);
    push(@CenteredHeads,'','light_subhead','class','h2','no more wrappers');
    my @MajorSubheads = $content->look_down('_tag','p','class',qr/Major[\-\s]*Subhead/i);

    push(@MajorSubheads,'','majorsubhead','class','h3','no more wrappers');

    my @LynSubheads = $content->look_down('_tag','p','class',qr/^Subhead\-Lyn/i);
    push(@LynSubheads,'','|','<','subhead','class','h4','+','em','no more wrappers');

    my @Subheads = $content->look_down('_tag','p','class',qr/^Subhead|Minor[\-\s]*section/i);
    push(@Subheads,'','subhead','class','h4');

    my @dkickers = $content->look_down('_tag','p','class',qr/department/i);
    push(@dkickers,'','department','class','h2','no more wrappers');
    my @editorials = $content->look_down('_tag','p','class',qr/Feature[\-\s]*Kicker/i);
    push(@editorials,'','department','class','h3','no more wrappers');
    my @kickers = $content->look_down('_tag','p','class',qr/pt[\-\s]*Kicker/i);
    push(@kickers,'','kicker','class','h4');
    my @bylines = $content->look_down('_tag','p','class',qr/^Byline\b/i);
    push(@bylines,'','byline','class','p');
    my @Heads = ();
    push (@Heads,  $content->look_down('_tag','p','class',qr/pt[\-\s]*Head/i));
    push(@Heads,'','head','class','h2');
#    my @BigHeads =  $content->look_down('_tag','p','class',qr/Heading-3/i);
#    push(@BigHeads,'','bighead','class','h1');

    my @extracts = $content->look_down('_tag','p','class',qr/^extract[\-\s]*$/i);
    push(@extracts,'','extract','class','p');

    my @extractbs = $content->look_down('_tag','p','class',qr/extract[\-\s]*begin/i);
    push(@extractbs,'','extractbegin','class','p');

    my @extractms = $content->look_down('_tag','p','class',qr/extract[\-\s]*middle/i);
    push(@extractms,'','extractmiddle','class','p');

    my @extractes = $content->look_down('_tag','p','class',qr/extract[\-\s]*end/i);
    push(@extractes,'','extractend','class','p');

    my @display_quotes = $content->look_down('_tag','p','class',qr/display.*quote.*/i);
    push(@display_quotes,'','^','hr','|','hr','|','<','Display-Quote','class','p','+','strong');

   
    my @spaceAbove = $content->look_down('_tag','p','class',qr/space[\-\s]*above\b/i);
    push (@spaceAbove,'','spaceabove','class','p');

    my @cmt = $content->look_down('_tag','p','class',qr/^Contents[\-\s]*Main.*/i);
    push (@cmt,'','cmt','class','h4');

    my @departments = $content->look_down('_tag','p','class',qr/^Contents?[\-\s]*Section/i);
    push (@departments,'','department','class','h4');

    my @ArticleTitleNoKickers = $content->look_down('_tag','p','class',qr/^Contents?[\-\s]*Head[\-\s]*no[\-\s]*kicker/i);
    push (@ArticleTitleNoKickers,'','|','<','articletitlenokicker','class','p','+','strong');

    my @ArticleTitles = $content->look_down('_tag','p','class',qr/^Contents?[\-\s]*Head$/i);
    push (@ArticleTitles,'','|','<','articletitle','class','p','+','strong');

    my @ArticleBlurbs = $content->look_down('_tag','p','class',qr/^Contents?[\-\s]*Text/i);
    push (@ArticleBlurbs,'','articleblurb','class','p');
    my @ArticleBylines = $content->look_down('_tag','p','class',qr/^Contents?[\-\s]*byline/i);
    push (@ArticleBylines,'','tocbyline','class','p');

    my @footnote_links = ();
    push (@footnote_links,  $content->look_down('_tag','a','class',qr/Footnote[\-\s]*Link/i));
    push (@footnote_links,'','a','|||',']','text','~text','^^^','[fn_','text','~text');
    my @footnote_anchors = ();
    push (@footnote_anchors,  $content->look_down('_tag','a','class',qr/Footnote[\-\s]*Anchor/i));
    push (@footnote_anchors,'','a','|||',']','text','~text','^^^','[fn_','text','~text');
    my @layouts = ();
    push (@layouts, $content->look_down ('_tag','div','class',qr/_idGenObjectLayout/));
    push (@layouts,'','|','+','div','|||','---------------------------------------------','text','~text');


    my @ShortsHeads = $content->look_down('_tag','p','class',qr/Short.*Hea?d.*/i);
    push (@ShortsHeads,'','shorts_head','class','h4');
    
    my @ShortsTexts = $content->look_down('_tag','p','class',qr/Short.*Text.*/i);
    push (@ShortsTexts,'','Text','class','p');

    my @FootnoteTexts = $content->look_down('_tag','p','class',qr/Footnote.*Text.*/i);
    push (@FootnoteTexts,'','FootnoteText','class','p');

    my @emphases = $content->look_down('_tag','span','class',qr/emphasis.*/i);
    push (@emphases,'','em');

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

    my @subscripts = ();
    if (defined $sub_class)
    {
	getMatchingContent(\@subscripts, $sub_class);
	push(@subscripts,'','sub');
    }

    my @sharpflats = ();
    if (defined $sharp_flat_class)
    {
	getMatchingContent(\@sharpflats, $sharp_flat_class);
	push(@sharpflats,'','sharpflats','class','span');
    }
    my @smallcaps = ();
    if (defined $sm_caps_class)
    {
	getMatchingContent(\@smallcaps, $sm_caps_class);
	push(@smallcaps,'','smallcaps','class','span');
    }
    my @ucase = ();
    if (defined $uc_class)
    {
	getMatchingContent(\@ucase, $uc_class);
	push(@ucase,'','ucase','class','span');
    }
    my @normals = ();
    if (defined $ns_class)
    {
	getMatchingContent(\@normals, $ns_class);
	push(@normals,'','fsn','class','span');
    }
    my @normal_weights = ();
    if (defined $nw_class)
    {
	getMatchingContent(\@normal_weights, $nw_class);
	push(@normal_weights,'','fwn','class','span');
    }

    my $prev_newelem = undef;
    my $newelem = undef;
    my $tag = undef;
    my %attribs = ();
    my $arritem = undef;
    my @arr_of_arrs = (\@footnote_links,\@footnote_anchors,\@FootnoteTexts,\@MajorSubheads,\@MajorLightSubheads,\@CenteredHeads,\@LightSubheads,\@LynSubheads,\@Subheads,\@kickers,\@dkickers,\@editorials,\@bylines,\@Heads,\@ShortsHeads,\@ShortsTexts,\@italics,\@bolds,\@superscripts,\@subscripts,\@ucase,\@normals,\@normal_weights,\@layouts,\@h1s,\@extracts,\@extractbs,\@extractms,\@extractes,\@display_quotes,\@spaceAbove,\@departments,\@ArticleTitles,\@ArticleTitleNoKickers,\@ArticleBlurbs,\@ArticleBylines,\@cmt,\@sharpflats,\@emphases);
    while ($arr = shift(@arr_of_arrs))
    {
	my @wrappers = ();
	$arritem = pop(@$arr);
	if (not defined ($arritem)) {next}
	
	# '' marks the beginning of the wrappers in the array @$arr. All items before it are tags to be wrapped, and all items after it are wrappers.  Here we are moving items popped from the end of @$arr and pushing them onto the end of @wrappers.
	while ($arritem ne '')
	{
	    push (@wrappers,$arritem);
	    $arritem = pop(@$arr);
	}
#If the first wrapper is 'no more wrappers', then after the tag is wrapped with this set of wrappers, no further wrappers are allowed, and 'no more wrappers' is removed from the array of wrappers.  Otherwise, the first wrapper must be restored to the array of wrappers using unshift.
	my $wrappable = 1;
	my $first_wrapper = shift(@wrappers);
	if ($first_wrapper eq 'no more wrappers')
	{$wrappable = 0}
	else
	{unshift(@wrappers,$first_wrapper)}	    
	my $saved_array_item_separator = $,;
	$, = "','";
	print DEBUG '@wrappers: \''.@wrappers."'\n";
	$, = $saved_array_item_separator;
	while (defined ($arritem = pop(@$arr)))
	{
	    if (not defined $arritem->tag or $arritem->tag eq '')
	    {
		print DEBUG "Warning: blank tag\n";
		next
	    }
	    print DEBUG '$arritem: '.$arritem.': '.$arritem->as_HTML("","\t",\%empty)."\n";
	    my @newelems = wrap ($arritem, \@wrappers);

	    my $listcontainer = HTML::Element->new('div','class','list_container');
	    $listcontainer->push_content(@newelems);	    print DEBUG '$arritem replaced with '.$listcontainer->as_HTML("","\t",\%empty)."\n";

	    #foreach $newelem (@newelems)
	    #{print DEBUG '$newelem: '.$newelem->as_HTML("","\t",\%empty)}
	    $arritem->replace_with($listcontainer);
	    print DEBUG '$arritem '.$arritem.' replaced with '.$listcontainer.': '.$listcontainer->as_HTML("","\t",\%empty)."\n";

	    #replace $arritem with $listcontainer in each of the not yet processed lists.  This is done by assigning the value of $listcontainer to pointer in the not yet processed arrays whose value is the same as $arritem.  The HTML::Element method replace_with, in $arritem->replace_with($listcontainer), does not change the value of $arritem; instead, the content list of the parent of $arritem is changed, and $arritem loses its parent, which is why this method invocation would fail if $listcontainer were the parent of $arritem.
	    foreach $future_arr (@arr_of_arrs)
	    {
		my $i = 0;
		print DEBUG '$wrappable = '.$wrappable."\n";
		while ($i < @$future_arr)
		{
		    #ignore wrappers at end of each array.  '' marks the beginning of the wrappers.
		    if (@$future_arr[$i] eq '') {last}
		    print DEBUG '@$future_arr['.$i.']: '.@$future_arr[$i].': '.@$future_arr[$i]->as_HTML("","\t",\%empty)."\n";

		    if ($arritem == @$future_arr[$i])
		    {
			print DEBUG '$arritem matched'."\n";
			if ($wrappable)
			{
			    @$future_arr[$i] = $listcontainer;
			    $i++
			}
			else
			{
			    splice @$future_arr,$i,1  #remove item from @$future_arr
			}
		    }
		    else {$i++}
		}
	    }
	    $arritem->delete;
	}
    }
    my @listcontainers = $tree->look_down('_tag','div','class','list_container');
    foreach my $lc (@listcontainers) {my $lcb = $lc->replace_with_content; $lcb->delete}
    my @lcclasstags = $tree->look_down('class','list_container');
    #remove copied 'list_container' class attribute from parent div.list_container
    foreach my $lcct (@lcclasstags) {$lcct->attr('class',undef)}


	#correct non-standard class names
	my @credits = $tree->look_down('class',qr/credit/i);
	foreach $credit (@credits)
	{
	    $credit->attr('class','PixCredit');
	}
	my @captions = $tree->look_down('class',qr/caption\b/i);
	foreach $caption (@captions)
	{
	    my $ctext = $caption->attr('class');
	    $ctext =~ s/caption/Captions/i;
	    $caption->attr('class',$ctext);
	}

    print OUTFILE $first_line;
    $tree->deobjectify_text();
    my $output = $tree->as_HTML("","\t",\%empty);
    print OUTFILE $output;
    close OUTFILE;
    close INFILE;
    close DEBUG;
}

sub processCss ($$)
{
    my $tree = $_[0];
    my $dir = $_[1];
    my $dirURL = $dir;
    $dirURL = $localHostURL . substr($dirURL,length($docRoot));
    $dirURL =~ s%\\%/%g;
    my $savedDir = getcwd();
    #open temporary file for writing
    open (TEMP,"+>$dir\\temp.html") || die "can't open $dir\\temp.html for writing: $!";
    #insert script tags
    my $jquery = HTML::Element->new('script','type'=>'text/javascript','src'=>$jqueryURL);
    my $script = HTML::Element->new('script','type'=>'text/javascript','src'=>$processCssScriptURL);   my $initscript = HTML::Element->new('script','type'=>'text/javascript');
    $initscript->push_content('$(window).load(processCss);');
    my $head = $tree->find_by_tag_name('head');
    $head->push_content($jquery,$script,$initscript);
    #write $tree to a temporary HTML file
    print TEMP $tree->as_HTML("","\t",\%empty);
    close TEMP;
    #restore $tree to its original contents
    $jquery->delete;
    $script->delete;
    $initscript->delete;
    #use a browser to execute the JavaScript on the temporary HTML file and save to another temporary HTML file
    chdir $dir;
    
    my $cmd = "";
    if ($browserPath eq '')
    {
	print "Open $dirURL/temp.html in a browser and save it to $dir\\temp2.html, then hit Enter.\n";
	$cmd = 'pause';
    }
    else
    {
	$cmd = '"'.$browserPath.'" '.$browserOptions.' '.$dirURL.'/temp.html > temp2.html';
    }
    print STDERR $cmd;
    system($cmd);
    
    #read and parse the 2nd temporary HTML file
    open (TEMP, "temp2.html") || die "can't open $dir\\temp2.html for reading: $!";
    my $stree = HTML::TreeBuilder->new;
    $stree->parse_file(\*TEMP);
    #extract and return the processed css character style overrides
    my $text = $stree->look_down('id','CharOverrides')->as_text;
    close TEMP;
    chdir $savedDir;
    return $text;
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

^ indicates that the previous element will be prepended to the replacement list.  If there is an element following '^', it will not wrap the previous element, but will be prepended to the replacement list after the previous element.

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
perl $0 {-|<config pathname>} <dir>
<config pathname> is the pathname of the configuration file, relative to $0
- uses the default configuration file, $dcf
<dir> is the pathname of the input directory (must be a directory), relative to the website
document root as specified in the configuration file, however:
It should begin with a forward slash, use only forward slashes, and
should be quoted if it contains spaces.  The spaces and other non-web-safe
characters should not be converted to web-safe entities like '%20'.  The input directory must contain a subdirectory 'css' which contains the css files referenced in the XHTML files in the input directory.

This script crashes when the input file contains span tags with no attributes.
Misbehaves if the input file contains a tag that normally contains text or other tags (not <br /> or <meta ... />) that is closed without a closing tag that repeats the tag name, e.g. contains <div ... /> instead of <div ...>...</div>

This script requires a web server to be running on the local host with the document root same as in the config file for this script.

The user may specify how a particular character style override is to be handled by editing the CSS file, adding '_XX_' to the beginning of the font-family for that style (adding a font-family if there is none), where XX is any character style override type recognized by eir2epub.pl, e.g. 'h1' for the 'h1_class', 'sf' for the 'sf_class' 

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
	#we look for qr/\b$class\b/ to find tags with multiple classes including $class, e.g. <span class="Hyperlink CharOverride-4">...</span>  The word boundary assertions (\b) prevent matching, e.g. <span class="CharOverride-11">...</span> with $class eq 'CharOverride-1'
	push (@$arRef, $content->look_down('_tag','span','class',qr/\b$class\b/))
    }
}

sub getFullClassName
{
    if ($_[0] =~ m/^\d+$/) {return 'CharOverride-'.$_[0]}
    else {return $_[0]}
}
