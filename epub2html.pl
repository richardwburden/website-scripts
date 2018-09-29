use HTML::TreeBuilder;
use HTML::Element;
use File::Spec;
use Fcntl ':mode';
use File::Copy;
use HTML::Entities;
use URI;
use WWW::Mechanize;
use Getopt::Long qw(:config no_ignore_case);
#use Encode::Encoder;
$HTML::Tagset::isKnown{"domain"} = 1;
$HTML::Tagset::isHeadOrBodyElement{"domain"} = 1;
sub findAbsPath($$);
sub findRelPath($$);
sub prepareFiles($$$$$$$;$);
sub filenameFromPath($);
sub updateImageLinks($$$);
sub updateLinksToArticles($$$$);
sub titleCase($);
sub removePageNumber($);
sub removeBrs($);
sub isEditorial($);
sub publicArticlePDFPathFromPrivate($$$$$);
#For conversion of kickers in all-caps to part of the title or a section heading in the archive issue index page.
%titleCaseDict = (qw/LAROUCHE LaRouche PAC PAC LAROUCHEPAC LaRouchePAC LPAC LPAC ZEPP-LAROUCHE Zepp-LaRouche UN UN US US USA USA UK UK EU EU/); 
%articlesTitleCaseDict = (qw/A a AN an THE the/); 
%empty = (); #use as 3rd parameter for HTML::Element->as_HTML() to specify that the HTML generated shall close all open tags

open(INDEXTEMPLATE, "issue_index_template.html") || die "can't open issue_index_template.html for reading: $!";
open(ARCHIVEINDEXTEMPLATE, "archive_issue_index_template.html") || die "can't open archive_issue_index_template.html for reading: $!";
open(ARTICLETEMPLATE, "article_template.html") || die "can't open article_template.html for reading: $!";

#get command-line options other than the config file selector and the input file/directory/glob pattern.  These must appear first on the command line, and all paths must contain only forward slashes, and no slash at the beginning or end. Only one option (-xu or -xp) to relocate the index page can be used. The final component of $piip (the argument for -xp) and $uiip (the argument for -xu) is assumed to be a filename; it will be appended to the configuration file option 'publicIssueIndexRootPath' or 'unlistedIssueIndexRootPath'.  If $piip and $uiip is left empty, the configuration file option '[public/unlisted]IssueIndexRootPath' will be ignored and the issue index page will be generated in the same directory, with the same file basename, as its .xhtml source
my %publics = ();
my %unlisteds = ();
my %imageDirs = ();
my %unlistedImageDirs = ();
my %privateImageDirs = ();
my %ffts = (); #filenames from titles
my %bfts = (); #basenames from titles
my $piip = "";
my $uiip = "";
my $uf = "";
my $appendBrowserScript = 0;
my $publicsOnly = 0;

GetOptions ('public|b=s%' => \%publics, 'unlisted|u=s%' => \%unlisteds, 'imageDirs|i=s%' => \%imageDirs, 'unlistedImageDirs|iu=s%' => \%unlistedImageDirs, 'privateImageDirs|ip=s%' => \%privateImageDirs, 'unlistedIssueIndexPath|xu=s' => \$uiip, 'publicIssueIndexPath|xp=s' => \$piip, 'unlistedFilename|uf=s' => \$uf, 'appendBrowserScript|abs' => \$appendBrowserScript, 'publicsOnly|po' => \$publicsOnly, 'unlistedDirname|ud=s' => \$ud, 'filenamesFromTitles|fft' => \$fft, 'archiveIndexOnly|aio' => \$aio);

my $program_basename = $0;
$program_basename =~ s/\.[^\.]*$//;
close STDERR;
open (STDERR, ">$program_basename"."_err.txt") || die "can't open $program_basename"."_err.txt for writing: $!";

#process the config file selector
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
my $bsp = $options{'browserScriptPath'};
if (not defined $bsp) {$bsp = 'epub2htmlRunJS.bat'}
my $browserPath = $options{'browserPath'};
if (not defined $browserPath) {$browserPath = '%BROWSER_PATH%'}

if ($appendBrowserScript)
{
    open (BROWSERSCRIPT, ">>$bsp") || die "can't open $bsp for appending: $!";
}
else
{
    open (BROWSERSCRIPT, "+>$bsp") || die "can't open $bsp for writing: $!";
}

#process the input file/directory/glob pattern.
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
    print "globpath: $globpath\n";
    @infiles = glob ($globpath);
}
elsif ($inpath[2] =~ /[\?\*]/)
{
    print "globpath: $inpath\n";
    @infiles = glob ($inpath);
}

else
{@infiles = ($inpath)}


#Find the table of contents and process it first.
my $ttree = undef;
my $arch_ttree = undef;
my $tree = undef;
my $content = undef;
my $body_text = undef;
my $root = undef;
my %saurlList = ();
my $count = -1;
my $indexFileName = "";

if ($uf ne "")
{
    #generate and store the unlisted pathnames
    print "Generated unlisted pathnames:\n";
    foreach $infilepath (@infiles)
    {
	my @infile = File::Spec->splitpath($infilepath);
	$unlisteds{$infile[2]} = $uf;
	print "$infile[2] --> $uf\n";
	incPath(\$uf);
    }
}
if ($fft)
{
    print "The unlisted HTML files will be written to the filename right of the '=' in the lines below, under the directory $options{'unlistedArticlesRootPath'}, which is the value of 'unlistedArticlesRootPath' in the configuration file. Using the lines below in the command-line will write the files to the filename or path right of the '=' under the directory $options{'publicArticlesRootPath'} ('publicArticlesRootPath' in the config. file).  The '^' is used to indicate continuation of the command line in the Windows shell. Any valid path where this script has permission to write may follow the '='.\n";
    foreach $infilepath (@infiles)
    {
	my @infile = File::Spec->splitpath($infilepath);
	#Don't process the cover page
	if ($infile[2] =~ /^cover/i) {next}
	#Don't process the masthead
	if ($infile[2] =~ /toc/i){next}

	my $title = getTitle($infilepath);
	my $newFileName = filenameFromTitle($title);
	$ffts{$infile[2]} = $newFileName;
	print "-b $infile[2]"."="."$newFileName ^\n";
    }
}

foreach $infilepath (@infiles)
{
    $count++;
    $outfilepath = $infilepath;
    #If only public files are to be processed, we don't need to write this index, but go ahead and read it to get information to be used in the public article pages.
    if ($publicsOnly) {$outfilepath = ''}
    if (prepareFiles($infilepath,\$ttree,\$tree,\$content,\$body_text,\$root,\$outfilepath,'tocOnly'))
    {
	#record the original filename of the table of contents file
	$indexFileName = filenameFromPath($infilepath);
	
	#remove the table of contents from the list of files
	splice @infiles,$count,1;

	#extract the volume and issue numbers and date from the text of the epub's "PDF edition" table of contents and convert them to the formats that will be used in URLs on the site.
	my $tocIssueTitleText = $body_text;
	$tocIssueTitleText =~ s/^.*?Volume\s*(\d+)\s*,\s*Number\s*(\d+),\s*(\S+)\s*(\d+)\s*,\s*(\d+).*/Volume $1, Number $2, $3 $4, $5/;
	my $volIssueDateText = $body_text;
	$volIssueDateText =~ s/^.*?Volume\s*(\d+)\s*,\s*Number\s*(\d+),\s*(\S+)\s*(\d+)\s*,\s*(\d+).*/Volume $1, Issue $2_Friday, $3 $4, $5/;
	$vol = $1;
	$zvol = sprintf('%02d', $vol);
	$issue = $2;
	$zissue = sprintf('%02d', $issue);
	$month = $3;
	my %zmonths=(qw/January 01 February 02 March 03 April 04 May 05 June 06 July 07 August 08 September 09 October 10 November 11 December 12/);
	$zmonth = $zmonths{$month};
	$mday = $4;
	$zmday = sprintf('%02d', $mday);
	$year = $5;
	my $issueMod10 = $issue % 10;
        $tenissueGroup = $issue - $issueMod10;
	my $tenissueGroupEnd = $tenissueGroup + 9;
	if ($tenissueGroup == 0){$tenissueGroup = $year.'_01-09'}
	else {$tenissueGroup = $year.'_'.$tenissueGroup.'-'.$tenissueGroupEnd}
	$yearIssue = $year.'-'.$zissue;
	($volIssueText,$DateText) = split /_/,$volIssueDateText;


#Fetch the index with links to the PDFs
	my $pdfIndexPath = $options{'pdfIndexPath'};
	if ($pdfIndexPath =~ m%\]\]\]$%)
	{$pdfIndexPath =~ s%\]\]\]$%%}
	else
	{$pdfIndexPath .= "public/$year/$tenissueGroup/$yearIssue/"}
	my $mech = WWW::Mechanize->new();
	$mech->get($domainName.$pdfIndexPath);
	my $pdfIndexTree = HTML::TreeBuilder->new();
	$pdfIndexTree->parse($mech->content());

	my $piiarp = $options{'publicIssueIndexArchiveRootPath'};

	my $arch_outfilepath = $piiarp."$year/eirv$zvol"."n$zissue-$year$zmonth$zmday/index.html";
	my $full_arch_outfilepath = $docRoot.$arch_outfilepath;
	$full_arch_outfilepath =~ s%/%\\%g;

	my $arch_root = findRelPath($full_arch_outfilepath,$docRoot.'/');


	open (ARCH_OUTFILE, "+>$full_arch_outfilepath") || die "can't open $full_arch_outfilepath for writing: $!";

#	my $pathFromIndex2ArchivePDFIndex = findRelPath($outfilepath,$full_arch_outfilepath);

#Get the URLs of single article PDFs.  Assumed to be in the correct order in 
#the index at $pdfIndexPath.  URLs assumed to end in /pdf/filename.pdf where 
#filename begins with a page number.
	my @pdfLinks = $pdfIndexTree->look_down('_tag','a','href',qr/pdf\/[0-9][^\/]*\.pdf$/);
	my @singleArticleURLs = ();

	my $phpRootPath = $options{'phpRootPath'};

	my $isPublicArchiveIndex = $phpRootPath !~ m%/private%;


	foreach $pdfLink (@pdfLinks)
	{
	    my $pdfLinkHref = $pdfLink->attr('href');
	    my $absPdfLinkHref = findAbsPath($pdfIndexPath,$pdfLinkHref);
	    my $url = findRelPath($outfilepath,$docRoot.$absPdfLinkHref);
	    push @singleArticleURLs, $url
	}


	#append to @singleArticleURLs another copy of the single article PDFs in the same order
	#as before, but this time, make them relative the location of the 
	#archive issue index.
	foreach $pdfLink (@pdfLinks)
	{
	    $pdfLinkHref = $pdfLink->attr('href');
	    $absPdfLinkHref = findAbsPath($pdfIndexPath,$pdfLinkHref);
	    $url = findRelPath($full_arch_outfilepath,$docRoot.$absPdfLinkHref);
	    if ($isPublicArchiveIndex)
	    {$url = publicArticlePDFPathFromPrivate($url,$year,$zvol,$zissue,$zmonth.$zmday)}
	    push @singleArticleURLs, $url
	}

	my $br = HTML::Element->new('br');
	$ttree->parse_file(\*INDEXTEMPLATE);
	
	$arch_ttree =  HTML::TreeBuilder->new();
	#include the server side include, which is inside a comment
	$arch_ttree->store_comments(1);
	$arch_ttree->parse_file(\*ARCHIVEINDEXTEMPLATE);

	my $volIssueDate = $ttree->look_down('id','volIssueDate');
	$volIssueDate->push_content($volIssueText,$br,$DateText);

	my $tocIssueTitle = $arch_ttree->look_down('id','tocIssueTitle');
	$tocIssueTitle->push_content($tocIssueTitleText);

	
	my $intPDF = $ttree->look_down('id','intPDF');
	$intPDF->attr('href',"$root/eiw/private/$year/$tenissueGroup/$yearIssue/pdf/eirv$zvol"."n$zissue.pdf");

	my $fullIssueLinks = $arch_ttree->look_down('id','fullIssueLinks');
	
	#if this archive index is still private, the class will remain as it is in the template, serveIssueSub
	if ($isPublicArchiveIndex)
	{$fullIssueLinks->attr('class','serveIssue')}

	my $fullPDFview = $arch_ttree->look_down('id','fullPDFview');

	if ($isPublicArchiveIndex)
	{$fullPDFview->attr('href',"$arch_root/eiw/public/$year/eirv$zvol"."n$zissue-$year$zmonth$zmday/eirv$zvol"."n$zissue-$year$zmonth$zmday.pdf")}
	else
	{$fullPDFview->attr('href',"$arch_root/eiw/private/$year/$tenissueGroup/$yearIssue/pdf/eirv$zvol"."n$zissue.pdf")}

	my $phpPath = "";
	if ($isPublicArchiveIndex)
	{$phpPath = "$phpRootPath$year/eirv$zvol"."n$zissue-$year$zmonth$zmday/eirv$zvol"."n$zissue-$year$zmonth$zmday.php"}
	else
	{$phpPath = "$phpRootPath$year/$tenissueGroup/$yearIssue/eirv$zvol"."n$zissue-$year$zmonth$zmday.php"}

	my $fullPDFdownload = $arch_ttree->look_down('id','fullPDFdownload');
	$fullPDFdownload->attr('href',"$phpPath?ext=pdf");

	my $epubDownload = $arch_ttree->look_down('id','epubDownload');
	$epubDownload->attr('href',"$phpPath?ext=epub");

	my $mobiDownload = $arch_ttree->look_down('id','mobiDownload');
	$mobiDownload->attr('href',"$phpPath?ext=mobi");


	my $coverLink = $ttree->look_down('id','coverLink');
	$coverLink->attr('href',"$root/eiw/private/$year/$tenissueGroup/$yearIssue/pdf/eirv$zvol"."n$zissue.pdf");

	my $archCoverLink = $arch_ttree->look_down('id','archCoverLink');
	$archCoverLink->attr('href',"$arch_root/eiw/public/$year/$tenissueGroup/$yearIssue/index.html");

	my $coverImg = $ttree->look_down('id','coverImg');
	$coverImg->attr('src',"$root/eiw/public/$year/$tenissueGroup/$yearIssue/images/eirv$zvol"."n$zissue".'lg.jpg');

	my $cover = $arch_ttree->look_down('id','cover');
	$cover->attr('src',"/graphics/eircovers/$year/eirv$zvol"."n$zissue.jpg");

	$coverImg->attr('width',undef);
	$coverImg->attr('height',undef);
	$cover->attr('width',undef);
	$cover->attr('height',undef);

	my $pqPDF = $ttree->look_down('id','pqPDF');
	$pqPDF->attr('href',"$root/eiw/private/$year/$tenissueGroup/$yearIssue/pdf/eirv$zvol"."n$zissue".'hi-res.pdf');
	my $mobi = $ttree->look_down('id','mobi');
	$mobi->attr('href',"$root/eiw/private/$year/$tenissueGroup/$yearIssue/ebook/eirv$zvol"."n$zissue.mobi");
	my $epub = $ttree->look_down('id','epub');
	$epub->attr('href',"$root/eiw/private/$year/$tenissueGroup/$yearIssue/ebook/eirv$zvol"."n$zissue.epub");
	my $archive = $ttree->look_down('id','archive');
	$archive->attr('href',"$root/eiw/public/$year/index.html");
	
	my $acontent = $content->clone();

	#for the archive issue index, delete everything before and including the title of the issue: "EIR Contents", website URL, Vol., No., date, "Cover This Week", large cover image, caption, title of the issue (class cmt)
	my $cmt = $acontent->look_down('class','cmt');
	my $arch_content = $cmt->parent();
	my @accs = $arch_content->content_list();
	foreach $acc (@accs)
	{
	    if ($acc->attr('class') ne 'cmt') {$acc->delete()}
	    else {$acc->delete(); last}
	}

	my $toc = $ttree->look_down('id','toc');
	$toc->unshift_content($content);

	my $atoc = $arch_ttree->look_down('id','toc');
	$atoc->unshift_content($arch_content);

	#remove the body tag from $content
	$content->replace_with_content->delete;
	#remove the outer div tag from $arch_content
	$arch_content->replace_with_content->delete;

	updateImageLinks ($ttree,$infilepath,$outfilepath);
	updateImageLinks ($arch_ttree,$infilepath,$full_arch_outfilepath);

	#add links to PDFs.  Save the path to this index in $indexOutfilePath
	#with forward slashes, so it can be used as a base URL
	#$indexOutfilePath = $outfilepath;
	#$indexOutfilePath =~ s%\\%/%g;

	my @htmlLinks = $toc->find_by_tag_name('a');
	foreach $htmlLink (@htmlLinks)
	{
	    if (! defined $htmlLink->attr('href')) {next}
	    my $htmlHref = $htmlLink->attr('href');
	    #skip links to targets that are not articles from the epub
	    if ($htmlHref !~ /\.xhtml$/) {next}
	    if ($htmlHref =~ m%/%) {next}
	    #get the next PDF link
	    # @singleArticleURLs contains two relative URLs for each single Article PDF: first, the relative URLs for the subscriber's issue index page, in their order of appearance in the table of contents, then those for the archive issue index page, in the same order, in that order.
	    my $saurl = shift @singleArticleURLs;
	    #save this $saurl in a hash to use when inserting a link to the PDF
	    #into the subscriber's HTML article page, which will be placed in the same directory as the subscriber's issue index page.  We will not repeat this step when generating the archive issue index page, because that would cause the first hash for each $htmlHref to be overwritten by a value appropriate for a page in the directory of the archive issue index page.
	    $saurlList{$htmlHref} = $saurl;
	    
	    #insert the HTML icon into the end of the HTML link
	    my $span = HTML::Element->new('span');
	    $span->attr('class','tocLinkHTML');
	    $span->push_content('&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;');
	    $htmlLink->push_content($span);

	    #insert the PDF link
	    $span = HTML::Element->new('span');
	    $span->attr('class','tocLinkAltPDF');
	    $span->push_content('&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;');
    	    my $pinsert = HTML::Element->new('a');
	    $pinsert->attr('href',$saurl);
	    $pinsert->push_content($span);
	    $htmlLink->postinsert($pinsert);
	}

	@htmlLinks = $atoc->find_by_tag_name('a');
	foreach $htmlLink (@htmlLinks)
	{
	    if (! defined $htmlLink->attr('href')) {next}
	    my $htmlHref = $htmlLink->attr('href');
	    #skip links to targets that are not articles from the epub
	    if ($htmlHref !~ /\.xhtml$/) {next}
	    if ($htmlHref =~ m%/%) {next}
	    #get the next PDF link
	    # @singleArticleURLs contains two relative URLs for each single Article PDF: first, the relative URLs for the subscriber's issue index page, in their order of appearance in the table of contents, then those for the archive issue index page, in the same order, in that order.
	    my $saurl = shift @singleArticleURLs;
	    my $pinsert = HTML::Element->new('a');
	    if ($saurl =~ m%/private/%)
	    {	
		#replace the unlisted HTML link with the subscribers-only PDF link and a hidden placeholder for the future public PDF link
		$htmlLink->attr('href',$saurl);
		$htmlLink->attr('class','tocLinkSubPDF');
		$pinsert->attr('href','#');
		my $span = HTML::Element->new('span');
		$span->attr('class','tocLinkHiddenPDF');
		$span->push_content('&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;');
		$pinsert->push_content($span);
	    }
	    else
	    {
		#replace the unlisted HTML link with the public HTML link if available (in updateLinksToArticles), otherwise, link it to the archive issue index page, in both cases followed by a public PDF link.
		$htmlLink->attr('class','tocLinkHTML');
		if (not defined $publics{$htmlHref})
		{
		    $htmlLink->attr('href','#');
		}
		my $span = HTML::Element->new('span');
		$span->attr('class','tocLinkAltPDF');
		$span->push_content('&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;');

		$pinsert->attr('href',$saurl);
		$pinsert->push_content($span);
	    }
	    $htmlLink->postinsert($pinsert);
	    #put a space before the non-breaking public PDF link so it can wrap to the next line if necessary.
	    $htmlLink->postinsert(' ');
	}
	my @tocSections = $atoc->look_down('_tag',qr/h[234]/,'class',qr/department|.*section/i);
	foreach $tocsec (@tocSections)
	{
	    $tocsec->tag('h2');
	    $tocsec->attr('class','tocSection');
	    removeBrs($tocsec);
	}
	my @tocArticles = $atoc->look_down('_tag','p','class',qr/.*title\b/i);
	foreach $tocart (@tocArticles)
	{
	    $tocart->tag('h3');
	    $tocart->attr('class','tocArticle');
	    removeBrs($tocart);
	}
	my @tocbylines = $atoc->look_down('_tag','p','class',qr/.*byline/i);
	foreach $tocbyline (@tocbylines)
	{
	    $tocbyline->attr('class','tocAuthor');
	}
	my @tocblurbs = $atoc->look_down('_tag','p','class',qr/.*blurb/i);
	foreach $tocblurb (@tocblurbs)
	{
	    $tocblurb->attr('class','tocBlurb');
	}

	my @atnks = $atoc->look_down('_tag','p','class',qr/articletitlenokicker/i);
	foreach $atnk (@atnks)
	{
	    $atnk->attr('class','tocArticle');
	    $atnk->tag('h3');
	    $atnk->objectify_text;
	    my @atnkcontent = $atnk->content_list;
	    removePageNumber (\@atnkcontent);
	    $atnk->deobjectify_text;
	    removeBrs($atnk);
	}
	my @kicks =  $atoc->look_down('_tag','p','class',qr/(content|toc).*kicker/i);
	foreach $kick (@kicks)
	{
	    $kick->objectify_text;
	    my @kickcontent = $kick->content_list;
	    titleCase (\@kickcontent);
	    if (removePageNumber (\@kickcontent) and not isEditorial($kick))
	    {
#		$kick->objectify_text;
		my $kickr = $kick->right;
		my $kickra = $kickr->find_by_tag_name('a');
#		$kick->deobjectify_text;
		$kickra->unshift_content(': ');
		$kickra->unshift_content(@kickcontent);
		$kick->delete; #remove empty tag; contents have been moved to $kickra
		$kickra->deobjectify_text;
	    }
	    else #this kicker applies to multiple titles
	    {
		$kick->tag('h2');
		$kick->attr('class','tocSection');
		$kick->deobjectify_text;
	    }
	}
	
	updateLinksToArticles ($ttree,$infilepath,$outfilepath,1);
	updateLinksToArticles ($arch_ttree,$infilepath,$full_arch_outfilepath,1);

	my $output = $ttree->as_HTML("","\t",\%empty);
	$ttree->delete;
	$tree->delete;
	#If only public files are to be processed, we do not need to generate this index page, but we did need to read volume, issue and date from it and process that to make a link to the public index page under construction
	if (not $publicsOnly) 
	{
	    print OUTFILE $output;
	    close OUTFILE;
	}
	close INFILE;
	if (not $publicsOnly) {writeBrowserScript($outfilepath)}
	
	$output = $arch_ttree->as_HTML("","\t",\%empty);
	$arch_ttree->delete;
	print ARCH_OUTFILE $output;
	close ARCH_OUTFILE;

	last;
    }
}


#now process the article pages
foreach $infilepath (@infiles)
{
    #don't process article pages if we're only generating the archive index.
    if ($aio) {last}
    my $saurl = filenameFromPath ($infilepath);
    #skip if only public articles are to be processed and this is not a 
    #public article
    if ($publicsOnly and not defined $publics{$saurl}) {next};

    $outfilepath = $infilepath;
    if (prepareFiles($infilepath,\$ttree,\$tree,\$content,\$body_text,\$root,\$outfilepath))
    {
	my $saPDFurl = $saurlList{$saurl};
	#calculate relative path from $outfilepath to PDF using relative path
	#from this issue's index to the PDF

	my $saPDFURI = URI->new($saPDFurl);
	my $outfilepathURL = $outfilepath;
	$outfilepathURL =~ s%\\%/%g;
	my $newsaPDFurl = $saPDFURI->abs($outfilepathURL);
	$saPDFurl = findRelPath($outfilepath,$newsaPDFurl);

	seek ARTICLETEMPLATE,0,SEEK_SET;
	$ttree->parse_file(\*ARTICLETEMPLATE);
	my $issueIndexLink = $ttree->look_down('id','issueIndexLink');

	#insert a link to the issue index page
	my $iirp = "";
	my $iip = "";
	if (defined $unlisteds{$indexFileName})
	{
	    $iirp = $options{'unlistedIssueIndexRootPath'};
	    $iip = $unlisteds{$indexFileName}
	}
	elsif (defined $publics{$indexFileName})
	{
	    $iirp = $options{'publicIssueIndexRootPath'};
	    $iip = $publics{$indexFileName}
	}
	elsif (defined $ud and $ud ne "")
	{
    	    $iirp = $options{'unlistedIssueIndexRootPath'}.$ud.'/';
	    $iip = "index.html";
	}
	if ($iirp ne "")
	{
	    $issueIndexLink->attr('href',$root.$iirp.$iip);
	}
	else
	    #use the default link to the issue index page in the EIR archive, which is under construction when the issue is new.
	{
	    my $piiarp = $options{'publicIssueIndexArchiveRootPath'};
	    $issueIndexLink->attr('href',$root.$piiarp."$year/eirv$zvol"."n$zissue".'-'."$year$zmonth$zmday/index.html");
	}
	$issueIndexLink->unshift_content("$month $mday, $year");
	my $ab = $ttree->look_down('id','article_body');
	$ab->replace_with($content);
	
	my $title = $tree->find_by_tag_name('title')->clone();
	my $ttitle = $ttree->find_by_tag_name('title');
	$ttitle->replace_with($title);

	my $first500chars = substr($content->as_text,0,500);
	print DEBUG "First 500 chars:\n".$first500chars."\n";
	my $isTranscript = ($first500chars =~ /transcript/i);
	my $isEditorial = ($first500chars =~ /editorial/i);
	my $articleType = "article";
	if ($isTranscript) {$articleType = "transcript"}
	if ($isEditorial) {$articleType = "editorial"}
	my $atspan = $ttree->look_down('id','articleType');
	$atspan->push_content($articleType);
	#strip the body tag from $content
	$content->replace_with_content->delete;

	updateImageLinks ($ttree,$infilepath,$outfilepath);
	updateLinksToArticles ($ttree,$infilepath,$outfilepath,0);

	
	#remove the department from single article pages. It only makes sense
	#to have it in a document that contains more than 1 department.
	my $department = $ttree->look_down('_tag','h2','class',qr/^department/);
	if (defined $department) {$department->delete}
	my $byline = $ttree->look_down('class',qr/^byline/i);
	my $iiLinkPara  = $ttree->look_down('id','iiLinkPara');
	my $pdfLink = '<p><em><a href="'.$saPDFurl.'">[Print version of this '.$articleType. ']</a></em></p>';
	if (defined $byline) {$byline->postinsert($pdfLink)}
	elsif (defined $head) {$head->postinsert($pdfLink)}
	else {$iiLinkPara->postinsert($pdfLink)}
	my $output = $ttree->as_HTML("","\t",\%empty);
	$ttree->delete;
	$tree->delete;
 	print OUTFILE $output;
	close OUTFILE;
	close INFILE;
	writeBrowserScript($outfilepath);
    }
}
close BROWSERSCRIPT;

sub writeBrowserScript
{
    my $ofp = $_[0];
    my $docRootRelPath = substr($ofp,length($docRoot));
    my $url = $docRootRelPath;
    $url =~ s%\\%/%g;
    $url = $domainName.$url;
    print BROWSERSCRIPT $browserPath.' --headless --dump-dom '.$url.' > '.$ofp."\n";
}
sub updateImageLinks ($$$)
{
    my ($ttree, $infilepath, $outfilepath) = @_;
    my @imgs = $ttree->find_by_tag_name('img');
    foreach $img (@imgs)
    {
	my $src = $img->attr('src');
	my @src = File::Spec->splitpath($src);
	my $srcdir = $src[1];

	#no need to change site-root-relative image links
	if (substr($srcdir,0,1) eq '/') {next} 

	my $id = $img->id;
	#the link to the cover image was updated when created.
	if (defined $id and $id eq 'coverImg') {next}

	my $srcUri = URI->new($src);
	my $newsrcpath = "";
	my @infilepath = File::Spec->splitpath($infilepath);
	$srcdir =~ s%/$%%; #remove '/' at end
	#public image files have been relocated, and this is a public HTML file
	if (defined $imageDirs{$srcdir} and defined $publics{$infilepath[2]})
	{
	    $newsrcpath = $docRoot.'/'.$imageDirs{$srcdir}.'/'.$src[2];
	}
	#private image files have been relocated, and this is a private HTML file
	elsif (defined $unlistedImageDirs{$srcdir} and defined $unlisteds{$infilepath[2]})
	{
	    $newsrcpath = $docRoot.'/'.$unlistedImageDirs{$srcdir}.'/'.$src[2];
	}
	elsif (defined $privateImageDirs{$srcdir} and not defined $publics{$infilepath[2]} and not defined $unlisteds{$infilepath[2]})
	{
	    $newsrcpath = $docRoot.'/'.$privateImageDirs{$srcdir}.'/'.$src[2];
	}
	#unspecified image files have been relocated, and this is an unspecified HTML file
	elsif (defined $imageDirs{$srcdir})
	{
	    $newsrcpath = $docRoot.'/'.$imageDirs{$srcdir}.'/'.$src[2];
	}
	#the image files have not been relocated, but the HTML file may have.
	else
	{
	    #calculate absolute path to the image from the original HTML file location
	    my $infilepathFS = $infilepath;
	    $infilepathFS =~ s%\\%/%g;
	    $newsrcpath = $srcUri->abs($infilepathFS);
	}
	#calculate new relative path to the image from the HTML output file location (which may be the same as the input, except for the filename extension)
	$newsrcpath =~ s%\\%/%g;
	my $newsrc = findRelPath($outfilepath,$newsrcpath);
	$img->attr('src',$newsrc)
    }
}
sub updateLinksToArticles ($$$$)
{
#We need to update links to articles in the same issue if 1) the destination
#is an article, or an anchor in an article, that is to be moved 2) if the article that contains
#the link is to be moved, and the destination is not an anchor in the same article.
    my ($ttree,$infilepath,$outfilepath,$toc) = @_;
    my @infile = File::Spec->splitpath($infilepath);
    my $infilename = $infile[2];
    $infilename =~ s%\#.*$%%;
    my @ltas = ();
    my @extra_ltas = ();
    if ($toc)  #this is the table of contents.
    {
	my $tocid = $ttree->look_down('id','toc');
	@ltas = $tocid->look_down('_tag','a','href',qr%\.xhtml$%);
    }
    else
    {
	#select only links to files in the same directory.  Usually their URLs contain
	#no slashes.
	@ltas = $ttree->look_down('_tag','a','href',qr%^[^/]+$%);
	#Links to anchors in the same file, and to other files in the same epub,
	# beginning with "../Text/" are generated by the Calibre epub editor,
	#which also places the .xhtml files in the Text directory.
	@extra_ltas = $ttree->look_down('_tag','a','href',qr%^\.\./Text/%);
	foreach $elta (@extra_ltas)
	{
	    my $href = $elta->attr('href');
	    $href =~ s%^\.\./Text/%%;
	    $elta->attr('href',$href);
	}
	push @ltas,@extra_ltas;
    }
    my $parp = $options{'publicArticlesRootPath'};
    my $uarp = $options{'unlistedArticlesRootPath'};
    foreach $lta (@ltas)
    {
	if (not defined $lta->attr('href')) {next}
	my $href = $lta->attr('href');
	my $hrefUri = URI->new($href);
	#no need to update email links, or any other kind of link that is not
	#document-relative 
	if (defined $hrefUri->scheme) {next}
	if (defined $hrefUri->path and substr($hrefUri->path,0,1) eq '/') {next} 
	#links to anchors in the same file should be reduced to just the fragment, so that the link will still work if the file is downloaded and saved under a different filename.
	if ($hrefUri->path eq $infilename) 
	{
	    $lta->attr('href','#'.$hrefUri->fragment); 
	    next
	}
	my $newhrefpath = "";
	my $newhref = "";
	
	#case 1: destination to be moved
	my $n = "";
	#calculate absolute path to the new location of the destination
	if (defined $publics{$hrefUri->path}) 
	{
	    $n = $publics{$hrefUri->path};
	    $newhrefpath = $docRoot.$parp.$n;
	}
	elsif (defined $unlisteds{$hrefUri->path}) 
	{
	    $n = $unlisteds{$hrefUri->path};
	    $newhrefpath = $docRoot.$uarp.$n;
	}
	elsif (defined $ffts{$hrefUri->path}) 
	{
	    $n = $ffts{$hrefUri->path};
	    $newhrefpath = $docRoot.$uarp;
	    if (defined $ud and $ud ne '')
	    {$newhrefpath .= $ud.'/'}
	    $newhrefpath .= $n;
	}
	if ($newhrefpath ne "")
	{
	    $newhrefpath  =~ s%\\%/%g;
	    #calculate relative URL to the destination from the new source
	    #location, which may or may not be the same as the original
	    $newhref = findRelPath ($outfilepath,$newhrefpath);
	    if (defined $hrefUri->fragment and $hrefUri->fragment ne "")
	    {$newhref .= '#'.$hrefUri->fragment}
	    $lta->attr('href',$newhref);
	}
	#case 2: source to be moved, but destination will not be moved, and
	#destination is not an anchor in the source.
	elsif ($hrefUri->path ne "")
	{
	    #calculate absolute path to the destination from the original source location
	    my $infilepathFS = $infilepath;
	    $infilepathFS =~ s%\\%/%g;
	    $newhrefpath = $hrefUri->abs($infilepathFS);

	    #calculate relative URL to the destination from the new source location
	    $newhref = findRelPath ($outfilepath,$newhrefpath);
	    $lta->attr('href',$newhref);
	} 
    }
}

sub filenameFromPath ($)
{
    my @infile = File::Spec->splitpath($_[0]);
    return $infile[2];
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

sub findAbsPath($$)
{
    my ($a,$b) = @_;
    #find absolute path of relative path $b given absolute path $a as base
    #find document-relative path to from document $a to $b
    my $aFS = $a;
    $aFS =~ s%\\%/%g;
    my $bFS = $b;
    $bFS =~ s%\\%/%g;
    my $base_uri = URI->new($aFS);
    my $abs_uri = URI->new_abs($bFS,$aFS);
    return $abs_uri;
}

sub findRelPath($$)
{
    my ($a,$b) = @_;
    #find document-relative path to from document $a to $b
    my $aFS = $a;
    $aFS =~ s%\\%/%g;
    my $bFS = $b;
    $bFS =~ s%\\%/%g;
    my $base_uri = URI->new($aFS);
    my $dest_uri = URI->new($bFS);
    $dest = $dest_uri->rel($base_uri);
    $dest =~ s%/$%%;  #remove '/' at end
    return $dest;
}

sub prepareFiles($$$$$$$;$)
{
    ($infilepath,$ttree,$tree,$content,$body_text,$root,$outfilepath,$flag) = @_;
    print STDERR "Processing $infilepath\n";
    my @infile = File::Spec->splitpath($infilepath);
    #Don't process the cover page
    if ($infile[2] =~ /^cover/i) {return 0}
    #Don't process the masthead
    if ($infile[2] =~ /toc/i){return 0}

    my $titleText = getTitle($infilepath);

    open(INFILE, $infilepath) || die "can't open $infilepath for reading: $!";

	
    my $first_line = <INFILE>; #skip the first line
	
    $tree = HTML::TreeBuilder->new();
    $tree->store_comments(1);
    $ttree =  HTML::TreeBuilder->new();
    $ttree->store_comments(1);
    
    $tree->parse_file(\*INFILE);
    $content = $tree->find_by_tag_name('body');
    $body_text = $content->as_text();

    my $outfilename = $infile[2];
    my $outfiledir =  File::Spec->join($infile[0],$infile[1]);
    $outfiledir.='\\';

    if ($body_text =~ /Cover\s*This\s*Week/si)
    {
	#relocate this issue's index page to public directory and filename
	#specified in --thisIssueIndexPath or -t command line argument
	my $piirp = $options{'publicIssueIndexRootPath'};
	my $uiirp = $options{'unlistedIssueIndexRootPath'};

	if (defined $piirp and $piirp ne "" and $piip ne "")
	{
	    #add this issue's index page to the list of "articles" made public,
	    #so that links to anchors in the index page are not made to point to
	    #the anchor in the original location of this issue's index page.
	    $publics{$infile[2]} = $piip;

	    my $piip = $docRoot.$piirp.$piip;
	    $piip =~ s%/%\\%g;
	    my @piip = File::Spec->splitpath($piip);
	    $outfilename = $piip[2];
	    $outfiledir = $piip[0].$piip[1];
	}
	elsif (defined $uiirp and $uiirp ne "" and $uiip ne "")
	{
	    #add this issue's index page to the list of "articles" made unlisted,
	    #so that links to anchors in the index page are not made to point to
	    #the anchor in the original location of this issue's index page.
	    $unlisteds{$infile[2]} = $uiip;

	    my $uiip = $docRoot.$uiirp.$uiip;
	    $uiip =~ s%/%\\%g;
	    my @uiip = File::Spec->splitpath($uiip);
	    $outfilename = $uiip[2];
	    $outfiledir = $uiip[0].$uiip[1];
	}
	elsif (defined $unlisteds{$infile[2]}) 
	{
	    my @uinfile = File::Spec->splitpath($unlisteds{$infile[2]});
	    $outfilename = $uinfile[2];
	    $uinfile[1] =~ s%/%\\%g;
	    my $uarp = $options{'unlistedArticlesRootPath'};
	    $uarp =~ s%/%\\%g;
	    $uarp =~ s%\\$%%;
	    if (substr($uinfile[1],0,1) ne '\\') {$uinfile[1] = '\\'.$uinfile[1]} 
	    $outfiledir = $docRoot.$uarp.$uinfile[1];
	}
    }
    else #not the Table of Contents.  If 'tocOnly' flag is set, do not process.
    {
	if (defined $flag and $flag eq 'tocOnly') {return 0}

	my $title = $tree->find_by_tag_name('title');
	$title->delete_content();
	$title->push_content($titleText);

	#relocate public articles to public directory and filename specified in
	#--publics or -b command line argument
	if (defined $publics{$infile[2]}) 
	{
	    my @pubinfile = File::Spec->splitpath($publics{$infile[2]});
	    $outfilename = $pubinfile[2];
	    $pubinfile[1] =~ s%/%\\%g;
	    my $parp = $options{'publicArticlesRootPath'};
	    $parp =~ s%/%\\%g;
	    $parp =~ s%\\$%%;
	    if (substr($pubinfile[1],0,1) ne '\\') {$pubinfile[1] = '\\'.$pubinfile[1]} 
	    $outfiledir = $docRoot.$parp.$pubinfile[1];
	}
	#relocate unlisted articles to public directory and filename specified in
	#--unlisteds or -u command line argument
	if (defined $unlisteds{$infile[2]}) 
	{
	    my @uinfile = File::Spec->splitpath($unlisteds{$infile[2]});
	    $outfilename = $uinfile[2];
	    $uinfile[1] =~ s%/%\\%g;
	    my $uarp = $options{'unlistedArticlesRootPath'};
	    $uarp =~ s%/%\\%g;
	    $uarp =~ s%\\$%%;
	    if (substr($uinfile[1],0,1) ne '\\') {$uinfile[1] = '\\'.$uinfile[1]} 
	    $outfiledir = $docRoot.$uarp.$uinfile[1];
	}
    }
    $outfilename =~ s/\.xhtml$/\.html/i;

    if (defined $ud and $ud ne "")
    {
	my $uarp = $options{'unlistedArticlesRootPath'};
	$uarp =~ s%/%\\%g;
	$uarp =~ s%\\$%%;
	$outfiledir = $docRoot.$uarp.'/'.$ud . '/';
	$outfiledir =~ s%/%\\%g;
    }
    if ($fft)
    {
	$outfilename = $ffts{$infile[2]};
    }

    #If this subroutine was called with $outfilepath = '', don't write anything.

    if ($outfilepath ne "")
    {
	$outfilepath = $outfiledir.$outfilename;
	open(OUTFILE,"+>$outfilepath") || die "can't open $outfilepath for writing: $!"; 
	open(DEBUG,">$outfilepath.debug.log") || die "can't open $outfilepath.debug.log for writing: $!"; 

	#find document-relative path to $docRoot
	$root = findRelPath($outfilepath,$docRoot.'/');
    }

    return 1;
}

sub incPath
{
    my $dir = "";
    my $fn = "";
    my $ext = "";
    $p = $_[0];
    if ($$p =~ m%^(.*)([/\\])(.*)\.(.*)$%)
    { $fn = $3;
      $ext = $4;
      $dir = $1.$2;
    }
    elsif ($$p =~ m%^(.*)([/\\])(.*)$%)
    {
	$dir = $1.$2;
	$fn = $3
    }
    elsif ($$p =~ m%^(.*)\.(.*)$%)
    {
	$fn = $1;
	$ext = $2;
    }
    else {$fn = $$p}
    if ($fn =~ m%(.*?)([0-9]+)$%i)
    {
	$fnRoot = $1;
	my $number = $2;
	$number++;
	$fn = $fnRoot.$number;
    }
    else {$fn .= '0'}
    
    if ($ext ne "")
    {
	$$p = $dir.$fn.'.'.$ext
    }
    else
    {$$p = $dir.$fn}
}

sub filenameFromTitle
{
    my $title = $_[0];
    if ($title eq "!!!Table of Contents!!!") {return "index.html"}
    my $filenameExt = $_[1];
    if (not defined $filenameExt) {$filenameExt = 'html'}
    $title =~ s/[^a-z0-9]/_/gi;
    $title =~ s/__+/_/g;
    $title = substr($title,0,30);
    $title = lc($title);
    #guarantee that the title-derived basename (Basename From Title) is unique
    while (defined $bfts{$title})
    {
	$title = incPath($title);
    }
    $bfts{$title} = "";
    return $title.'.'.$filenameExt;
}    

sub getTitle
{
    open(INFILE, $_[0]) || die "can't open $_[0] for reading: $!";
	
    my $first_line = <INFILE>; #skip the first line
	
    my $tree = HTML::TreeBuilder->new();
    $tree->parse_file(\*INFILE);

    my $content = $tree->find_by_tag_name('body');
    my $body_text = $content->as_text();
    if ($body_text =~ /Cover\s*This\s*Week/si)
    {
	close INFILE;
	return "!!!Table of Contents!!!";
    }

#A span tag to replace <br> tags to insure that ->as_text() will render them as spaces
    my $brspace = HTML::Element->new('span','class' => 'brspace');
    $brspace->push_content(' ');
    
    my @brs = ();
    my $kicker = $tree->look_down('class','kicker');
    if (defined $kicker)
    {
	@brs = $kicker->find_by_tag_name('br');
	foreach $br (@brs)
	{$br->replace_with($brspace->clone())}
    }
    my $head = $tree->look_down('_tag','h2','class','head');
    if (not defined $head)
    {$head = $tree->look_down('_tag','h3','class','head')}
     if (not defined $head)
     {$head = $tree->look_down('_tag','h4','class','head')}
    if (defined $head)
    {
	@brs = $head->find_by_tag_name('br');
	foreach $br (@brs)
	{$br->replace_with($brspace->clone())}
    }
    
    $titleText = "";
    if (defined $kicker) {$titleText .= $kicker->as_text().': '}
    if (defined $head) {$titleText .= $head->as_text()}

    close INFILE;
    return $titleText;
}

#expects an HTML::Element object.  Replaces br tags with spaces.
sub removeBrs ($)
{
    my @brs = $_[0]->find_by_tag_name('br');
    foreach $br (@brs)
    {
	$br->postinsert(' ');
	$br->delete;
    }
}
#expects an HTML::Element object, deobjectifies text.
sub isEditorial ($)
{
   # $_[0]->deobjectify_text;
    my $text = $_[0]->as_text;
    if ($text =~ /^\s*Editorials?\b/i) {return 1}
    else {return 0}
}
    

#Must pass a reference to an array of HTML::Element objects, i.e.
#must call objectify_text on the parent of the array before calling.
#return 1 if page number found, 0 otherwise.  Page number found if first non-whitespace exists and is a digit.
sub removePageNumber ($)
{
    my $tref = $_[0];
    foreach $item (@$tref)
    {
	my @texts = $item->find_by_tag_name('~text');
	foreach $text (@texts)
	{
	    my $t = $text->attr('text');
	    if ($t =~ /\S/)
	    {
		if ($t =~ /^\s*(\d+)/)
		{
		    $t =~ s/(\d+)//;
		    $text->attr('text',$t);
		    return 1;
		}
		else
		{
		    return 0;
		}
	    }
	}
    }
    return 0;
}
#Must pass a reference to an array of HTML::Element objects, i.e.
#must call objectify_text on the parent of the array before calling.
sub titleCase ($)
{
    my $tref = $_[0];
    foreach $item (@$tref)
    {
	my @texts = $item->find_by_tag_name('~text');
	foreach $text (@texts)
	{
	    my $t = $text->attr('text');
	    my @words = split /\W+/,$t;
	    my @wordSeparators = split /\w+/,$t; 
	    my $firstword = 1;
	    my $newtext = "";
	    my $ws = undef;
	    foreach $word (@words)
	    {
		if (length($word) < 1) 
		{
		    $ws = shift @wordSeparators;
		    if (defined $ws) {$newtext .= $ws}
		    next;
		}
		elsif (defined $titleCaseDict{$word})
		{
		    $word = $titleCaseDict{$word};
		}
		elsif (defined $articlesTitleCaseDict{$word} and not $firstword)
		{
		    $word = $articlesTitleCaseDict{$word}
		}
		else
		{
		    my $firstlet = substr($word,0,1);
		    my $rest = substr($word,1);
		    $rest = lc($rest);
		    $firstlet = uc($firstlet);
		    $word = $firstlet.$rest;
		}
		$firstword = 0;
		$ws = shift @wordSeparators;
		#if the text begins with a word, the first word separator will be an empty string.  Get the next word separator, so that we have the word separator that follows the word, if it exists.
		if (defined $ws and length($ws) == 0) {$ws = shift @wordSeparators}
		if (defined $ws)
		{
		    if ($ws =~ /^\./ and (length($word) == 1))
		    {$word = uc($word)}
		    $newtext .= $word.$ws;
		}
		else #if no word separator follows the word, just get the word.
		{$newtext .= $word}
	    }
	    if (@wordSeparators > 0)
	    {
		$ws = shift @wordSeparators;
		$newtext .= $ws;
	    }
	    $text->attr('text',$newtext);
	}
    }
}
sub publicArticlePDFPathFromPrivate($$$$$)
{
    #change relative path to a URL of form   https://larouchepub.com/eiw/private/2018/2018_30-39/2018-37/pdf/29-32_4537.pdf or https://larouchepub.com/eiw/public/2018/2018_30-39/2018-37/2018-37/pdf/29-32_4537.pdf
    #to a relative path to a URL of form https://larouchepub.com/eiw/public/2018/eirv45n37-20180914/29-32_4537.pdf
    my ($url,$year,$zvol,$znum,$mmdd) = @_;
    my $volNumDate = "eirv$zvol"."n$znum"."-"."$year$mmdd";
    $url =~ s%/private/%/public/%;
    $url =~ s%\d\d\d\d_\d\d\-\d\d/\d\d\d\d\-\d\d/\d\d\d\d\-\d\d/%$volNumDate/%;
    $url =~ s%\d\d\d\d_\d\d\-\d\d/\d\d\d\d\-\d\d/%$volNumDate/%;
    $url =~ s%/pdf%%;
    return $url;
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

EOF

exit
}
