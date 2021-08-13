=head1 SYNOPSIS

perl epub2html.pl {-|<config pathname>} [options] <pathname>

=head1 OPTIONS

Each option must be preceded by a double hyphen '--' to indicate that it is an option, except:
options with single character names may be preceded by a single hyphen '-'.

Alternative names for an option are separated by '|'.

Options whose name(s) are followed by '!' are negatable by prepending 'no' or 'no-' to the option on the command line.

Options whose name(s) are followed by '=' require an argument.  The letter following the '=' specifies the argument type (s for string). If the argument type is folllowed by '%', the option  may be used multiple times in the same command line with an argument for each instance. 

 unlistedDirname|ud=s
 filenamesFromTitles|fft
 pathnamesFromTitles|pft=s
 public|b=s%
 unlisted|u=s%
 unlistedIssueIndexPath|xu=s
 publicIssueIndexPath|xp=s
 imageDirs|i=s%
 unlistedImageDirs|iu=s%
 privateImageDirs|ip=s%
 appendBrowserScript|abs
 publicsOnly|po
 archiveIndexOnly|aio
 volume|vol=s
 issue|iss=s
 volumeIssue|vi=s
 coverRegex|cr=s  (enclose regex string arguments in quotes, e.g. --cr="^cover")
 mastheadRegex|mr=s
 coverExists|ce! (no cover by default, omitting this option is equivalent to --noce or --no-ce)
 mastheadExists|me! (masthead exists by default; omitting this option is equivalent to --me)
 makeUnlistedArchiveIndex|muai! (no unlisted archive index by default; omitting this option is equiv to --nomuai or --no-muai)

All paths must contain only forward slashes, and no slash at the beginning or end. 

By default, the issue index (table of contents) page and all article pages will be generated in the same directory, with the same file basename, as its .xhtml source in the unzipped EPUB.  All pages are private by default.

If the unlistedDirname|ud=s option is used, the issue index will be placed in the same directory as a copy of all the article pages: the value of 'unlistedArticlesRootPath' from the config file followed by the value of 'unlistedDirname' from the command line.  All pages placed in the unlisted directory are, of course, unlisted (not private).  In order to make sure that only those who are given links to the pages can view them, the value of 'unlistedDirname' should include a random string that is unlikely to be guessed, but is still a directory that exists on the site.

If the filenamesFromTitles|fft option is used, filenames for article pages will be generated from the article titles and the volume and issue number, and 'index.html' will be the filename of the issue index page.

if pathnamesFromTitles|pft=s is used, filenames are generated in the same manner as when filenamesFromTitles is used, but in the shell output (for convenience in creating a command-line to specify paths to public pages) these are prepended by a relative path calculated from string s.  By default, '/YYYY/' is added to s where YYYY is the four-digit year of this issue.  If s ends with ']]]', the relative path is just s without the ']]]'.

The public|b=s% and  unlisted|u=s% options specify public or unlisted relative pathnames for individual pages (article or issue index).  These pathnames use as prefix the 'publicArticlesRootPath' or 'unlistedArticlesRootPath' from the config file.  Pages given public relative pathnames are intended to be public (not only can the page be viewed by anyone who has the link, but the portal page of the site or some page that is linked from the portal page will have a link to the page).  This script cannot determine whether such a chain of links from the portal page to the page exists; all it does is use 'publicArticlesRootPath' from the config file instead of 'unlistedArticlesRootPath'.

Either unlistedIssueIndexPath|xu=s or  publicIssueIndexPath|xp=s (but not both) can be used to relocate the index page. The final component of 'unlistedIssueIndexPath' or 'publicIssueIndexPath' is assumed to be a filename; it will be appended to the configuration file option 'unlistedIssueIndexRootPath' or 'publicIssueIndexRootPath'. If neither of the these options is used, the configuration file option '[public/unlisted]IssueIndexRootPath' will be ignored and the issue index pathname will be determined by default, ud, fft, b, or u.

imageDirs|i=s%,  unlistedImageDirs|iu=s%,  privateImageDirs|ip=s% specify relative pathnames to image directories.  On the left of each '=' is the relative pathname where the image files are located in the unzipped EPUB, and on the right is the document-root-relative or site-relative pathname where the same image files are to be found on the website (without the initial '/').  Which of these options is used depends on whether the page is public, unlisted or private. Public pages use the first (imageDirs).  All pages are private by default.

appendBrowserScript|abs causes the browser script to be appended instead of overwritten. Regardless of options, this script generates a browser script that can be used to invoke a browser to open all the pages that were previously generated by this script and uploaded to the site, execute the JavaScript in those pages, then download them.  It assumes that the pages were uploaded to the site after this script was run and before the browser script will be run.  The browser script is written to the value of 'browserScriptPath' in the config file.  Each line of the browser script will contain bp bo URL > lpp, where 'bp' is the value of 'browserPath' in the config file, 'bo' the value of 'browserOptions', 'URL' the absolute URL of the page on the site, and 'lpp' is the local page path, the absolute path of the location in the local file system corresponding to the URL of the page on the site. The 'docroot' attribute of the 'domain' tag in the config file is prepended to the path portion of the URL to calculate the lpp.  If the config. file lacks 'browserOptions', '--headless --dump-dom', the options appropriate for Chrome and other Chromium-based browsers such as Yandex, are inserted by default.

publicsOnly|po  causes only public pages and the archive issue index page to be generated

archiveIndexOnly|aio  causes only the archive issue index page to be generated

volume|vol=s, issue|iss=s  specifies the volume and issue numbers (one or two digits each)
volumeIssue|vi=s  four digit combination volume and issue number.  Volume and issue numbers specified on the command-line must match those specified in the issue index page in the unzipped EPUB.  It is necessary to use these options only if filenamesFromTitles|fft is used and the pathname of the Text directory in the unzipped EPUB (where the .xhtml files are located) does not contain the correct year and issue or volume and issue in one of the following formats: /YYYY/NN/, /VV/NN/, or vVVnNN, where YYYY is a four-digit year, VV the volume number, NN the issue number, and VV or NN may be 1 or 2 digits, and the slashes separating directory names may be forward or backward.


=cut

use HTML::TreeBuilder;
use HTML::Element;
use File::Spec;
use Fcntl ':mode';
use File::Copy;
use File::Path qw(make_path remove_tree);
use HTML::Entities;
use URI;
use WWW::Mechanize;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
#use Encode::Encoder;
$HTML::Tagset::isKnown{"domain"} = 1;
$HTML::Tagset::isHeadOrBodyElement{"domain"} = 1;
sub findAbsPath($$);
sub findRelPath($$);
sub prepareFiles($$$$$$;$);
sub filenameFromPath($);
sub updateSiteRelativeLinks($$$);
sub updateImageLinks($$$);
sub updateLinksToArticles($$$$);
sub titleCase($);
sub removePageNumber($);
sub removeBrs($);
sub isEditorial($);
sub publicArticlePDFPathFromPrivate($$$$$);
sub correctNSClassNames($);
#For conversion of kickers in all-caps to part of the title or a section heading in the archive issue index page.
%titleCaseDict = (qw/LAROUCHE LaRouche PAC PAC LAROUCHEPAC LaRouchePAC LPAC LPAC ZEPP-LAROUCHE Zepp-LaRouche UN UN US US USA USA UK UK EU EU/); 
%articlesTitleCaseDict = (qw/A a AN an THE the/); 
%empty = (); #use as 3rd parameter for HTML::Element->as_HTML() to specify that the HTML generated shall close all open tags

#get command-line options other than the config file selector and the input file/directory/glob pattern.  These must appear first on the command line, and all paths must contain only forward slashes, and no slash at the beginning or end. Only one option (-xu or -xp) to relocate the index page can be used. The final component of $piip (the argument for -xp) and $uiip (the argument for -xu) is assumed to be a filename; it will be appended to the configuration file option 'publicIssueIndexRootPath' or 'unlistedIssueIndexRootPath'.  If $piip and $uiip is left empty, the configuration file option '[public/unlisted]IssueIndexRootPath' will be ignored and the issue index page will be generated in the same directory, with the same file basename, as its .xhtml source
my %publics = ();
my %unlisteds = ();
my %imageDirs = ();
my %unlistedImageDirs = ();
my %privateImageDirs = ();
my $fft = "";
my $pft = "";
my $coverExists = 0;
my $mastheadExists = 1;
my $coverRegex = '^cover';
my $mastheadRegex = 'toc';
my %ffts = (); #filenames from titles
my %tffs = (); #titles from filenames
my %bfts = (); #basenames from titles
my $piip = "";
my $uiip = "";
my $uf = "";
my $ud = "";
my $appendBrowserScript = 0;
my $publicsOnly = 0;
my $aio = 0;
my $gha = 0;
#This is used to compute the directory name for the ten issue group beginning with issue 50.  Override in config file with option 'yearEndIssueNumber'.
my $yearEndIssueNumber = 52;
my $vol = undef;
my $issue = undef;
my $vi = undef; #four digit $zvol.$zissue
my $zvol = undef; #two digit with leading 0 for value < 10
my $zissue = undef; #two digit with leading 0 for value < 10
my $help = 0;
my $makeUnlistedArchiveIndex = 0;

GetOptions ('help|?' => \$help, 'public|b=s%' => \%publics, 'unlisted|u=s%' => \%unlisteds, 'imageDirs|i=s%' => \%imageDirs, 'unlistedImageDirs|iu=s%' => \%unlistedImageDirs, 'privateImageDirs|ip=s%' => \%privateImageDirs, 'unlistedIssueIndexPath|xu=s' => \$uiip, 'publicIssueIndexPath|xp=s' => \$piip, 'appendBrowserScript|abs' => \$appendBrowserScript, 'publicsOnly|po' => \$publicsOnly, 'unlistedDirname|ud=s' => \$ud, 'filenamesFromTitles|fft' => \$fft, 'pathnamesFromTitles|pft=s' => \$pft,'archiveIndexOnly|aio' => \$aio,'volume|vol=s' => \$vol, 'issue|iss=s' => \$issue, 'volumeIssue|vi=s' => \$vi, 'coverRegex|cr=s' => \$coverRegex, 'mastheadRegex|mr=s' => \$mastheadRegex, 'coverExists|ce!' => \$coverExists, 'mastheadExists|me!' => \$mastheadExists, 'makeUnlistedArchiveIndex|muai!' => \$makeUnlistedArchiveIndex);
pod2usage(1) if $help;

my $program_basename = $0;
$program_basename =~ s/\.[^\.]*$//;
close STDERR;
open (STDERR, ">$program_basename"."_err.txt") || die "can't open $program_basename"."_err.txt for writing: $!";

print "\nError messages will written to $program_basename"."_err.txt in the current working directory\n\n";

#process the config file selector
if (@ARGV < 2) {usage()}
my $configPath = $ARGV[0];

if ($configPath eq '-') {$configPath = "$program_basename.xml"}
else {$configPath = "$program_basename-$configPath.xml"}

#open (INPUT, $ARGV[0]) || die "can't open $ARGV[0] for reading: $!";
#open (OUTPUT, ">$ARGV[1]") || die "can't open $ARGV[1] for writing: $!";


my $domain;
my %options = ();
get_config ($configPath, \$domain, \%options);


open(INDEXTEMPLATE, "issue_index_template.html") || die "can't open issue_index_template.html for reading: $!";

if ($makeUnlistedArchiveIndex)
{
    open(ARCHIVEINDEXTEMPLATE, "unlisted_archive_issue_index_template.html") || die "can't open unlisted_archive_issue_index_template.html for reading: $!";
}
else
{
    open(ARCHIVEINDEXTEMPLATE, "archive_issue_index_template.html") || die "can't open archive_issue_index_template.html for reading: $!";
}
open(ARCHIVEINDEXTEMPLATEDOCTYPE, "archive_issue_index_template_doctype.txt") || die "can't open archive_issue_index_doctype.txt for reading: $!";
open(ARTICLETEMPLATE, "article_template.html") || die "can't open article_template.html for reading: $!";


if ($makeUnlistedArchiveIndex)
# make an index page in the archive style, but put it in the unlisted directory
{
    $options{'publicIssueIndexArchiveRootPath'} = $options{'unlistedIssueIndexRootPath'};
}

my $docRoot = $domain->attr('docroot');
my $domainName = $domain->attr('name');
#default year end issue number is 52.  This can be overridden in the config file.
my $yein = $options{'yearEndIssueNumber'};
if (defined $yein and $yein > 0) {$yearEndIssueNumber = $yein}

my $bsp = $options{'browserScriptPath'};
if (not defined $bsp) {$bsp = 'epub2htmlRunJS.bat'}
my $browserPath = $options{'browserPath'};
my $browserOptions = $options{'browserOptions'};
if (not defined $browserOptions) {$browserOptions = '--headless --dump-dom'}
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
$inpath = $ARGV[1];
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

if (defined $vol and defined $issue)
{
    $zvol = sprintf('%02d',$vol);
    $zissue = sprintf('%02d',$issue);
}
elsif (defined $vi)
{
    $zvol = substr ($vi,0,2);
    #set $vol to the integer of $zvol to use for calculating the year
    $vol = $zvol + 0;
    $zissue = substr ($vi,2,2);
}
else
#extract volume from inpath directory
{
    if ($inpath =~ m%[\\/](\d\d\d\d)[\\/](\d\d?)[\\/]%)
    {
	my $year = $1;
	$issue = $2;
	$vol = $year - 1973;
	$zvol = sprintf('%02d',$vol);
	$zissue = sprintf('%02d',$issue);
    }
    elsif ($inpath =~ m%[\\/](\d\d?)[\\/](\d\d?)[\\/]%)
    {
	$vol = $1;
	$issue = $2;
	$zvol = sprintf('%02d',$vol);
	$zissue = sprintf('%02d',$issue);
    }
    elsif ($inpath =~ m%v(\d\d?)n(\d\d?)%i)
    {
	$vol = $1;
	$issue = $2;
	$zvol = sprintf('%02d',$vol);
	$zissue = sprintf('%02d',$issue);
    }
    elsif ($fft ne "" or $pft ne "") {die "Command line lacks volume and issue number parameters, and the volume and issue number can't be determined from last argument $inpath, a requirement for determining filenames from titles (-fft or -pft option)"}
}


#Find the table of contents and process it first.
my $ttree = undef;
my $arch_ttree = undef;
my $tree = undef;
my $content = undef;
my $body_text = undef;
#my $root = undef;
my %saurlList = ();
my $count = -1;
my $indexFileName = "";

my @noncmInfiles = ();  #infiles other than the cover and masthead

if ($fft ne "" or $pft ne "")
{
    print "The unlisted HTML files will be written to the filename right of the '=' in the lines below, under the directory\n$options{'unlistedArticlesRootPath'}$ud\n, which is the value of 'unlistedArticlesRootPath' in the configuration file follwed by the value of the 'unlistedDirectory' or 'ud' parameter in the command-line. Using the lines below in the command-line will write the files to the filename or path right of the '=' under the directory '$options{'publicArticlesRootPath'}' ('publicArticlesRootPath' in the config. file).  The '^' is used to indicate continuation of the command line in the Windows shell. Any valid path where this script has permission to write may follow the '='.\n";
    if ($pft ne "")
    {
	if (substr($pft,-3) ne ']]]')
	{ #append year
	    my $year = $vol + 1973;
	    $pft .= '/'.$year.'/'
	}
    }
}

my $coverFound = 0;
my $mastheadFound = 0;
foreach $infilepath (@infiles)
{
    my @infile = File::Spec->splitpath($infilepath);
    #Don't process the cover page
    if ($coverExists and $infile[2] =~ /$coverRegex/i) {$coverFound = 1; next}
    #Don't process the masthead
    if ($mastheadExists and $infile[2] =~ /$mastheadRegex/i){$mastheadFound = 1; next}
    push @noncmInfiles, $infilepath;
}
if ($coverExists and not $coverFound) {print "Cover with filename matching /$coverRegex/i not found\n"; exit}
if ($mastheadExists and not $mastheadFound) {print "Masthead with filename matching /$mastheadRegex/i not found\n"; exit}


foreach $infilepath (@noncmInfiles)
{
    $count++;
    $outfilepath = $infilepath;
    #If only public files are to be processed, we don't need to write this index, but go ahead and read it to get information to be used in the public article pages.
    if ($publicsOnly) {$outfilepath = ''}
    if (prepareFiles($infilepath,\$ttree,\$tree,\$content,\$body_text,\$outfilepath,'tocOnly'))
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
	my $toc_vol = $1;
	my $toc_issue = $2;
	$month = $3;
	$mday = $4;
	$year = $5;
	my $toc_zvol = sprintf('%02d', $toc_vol);
	my $toc_zissue = sprintf('%02d', $toc_issue);
	my %zmonths=(qw/January 01 February 02 March 03 April 04 May 05 June 06 July 07 August 08 September 09 October 10 November 11 December 12/);
	$zmonth = $zmonths{$month};
	$zmday = sprintf('%02d', $mday);
	if (defined $zvol and $zvol != $toc_zvol)
	{
	    die "Volume number $toc_vol in Table of Contents, formatted as $toc_zvol, does not agree with formatted command-line parameter value $zvol"
	}
	else {$zvol = $toc_zvol}
	if (defined $zissue and $zissue != $toc_zissue)
	{
	    die "Issue number $toc_issue in Table of Contents, formatted as $toc_zissue, does not agree with formatted command-line parameter value $zissue"
	}
	else {$zissue = $toc_zissue}

#	my $issueMod10 = $toc_issue % 10;
#        $tenissueGroup = $toc_issue - $issueMod10;
#	my $tenissueGroupEnd = $tenissueGroup + 9;
#	if ($tenissueGroup == 50) {$tenissueGroupEnd = $yearEndIssueNumber}
#	if ($tenissueGroup == 0){$tenissueGroup = $year.'_01-09'}
#	else {$tenissueGroup = $year.'_'.$tenissueGroup.'-'.$tenissueGroupEnd}
	$yearIssue = $year.'-'.$zissue;
	($volIssueText,$DateText) = split /_/,$volIssueDateText;


#Fetch the index with links to the PDFs
	my $pdfIndexPath = $options{'pdfIndexPath'};
	if ($pdfIndexPath =~ m%\]\]\]$%)
	{$pdfIndexPath =~ s%\]\]\]$%%}
	else
	{$pdfIndexPath .= "$year/eirv$zvol"."n$zissue-$year$zmonth$zmday/pdf_links.txt"}
	my $mech = WWW::Mechanize->new();
	$mech->get($domainName.$pdfIndexPath);
	my $pdfIndexTree = HTML::TreeBuilder->new();
	$pdfIndexTree->parse($mech->content());

	my $piiarp = $options{'publicIssueIndexArchiveRootPath'};

	#archive index page filename is index-nc.html because it is not fully HTML5 compliant.
	#a XSL transform will be applied using java net.sf.saxon.Transform to make it compliant.

	my $arch_outfilepath = "";
	if ($makeUnlistedArchiveIndex and defined $ud and $ud ne "")
	{
	    $arch_outfilepath = $piiarp.$ud.'/index-nc.html';
	}
	else
	{
	    $arch_outfilepath = $piiarp."$year/eirv$zvol"."n$zissue-$year$zmonth$zmday/index-nc.html";
	}
	my $full_arch_outfilepath = $docRoot.$arch_outfilepath;
	$full_arch_outfilepath =~ s%/%\\%g;

#	my $arch_root = findRelPath($full_arch_outfilepath,$docRoot.'/');


	open (ARCH_OUTFILE, "+>$full_arch_outfilepath") || die "can't open $full_arch_outfilepath for writing: $!";

#	my $pathFromIndex2ArchivePDFIndex = findRelPath($outfilepath,$full_arch_outfilepath);

#Get the URLs of single article PDFs.  Assumed to be in the correct order in 
#the index at $pdfIndexPath. 
	my @pdfLinks = $pdfIndexTree->find_by_tag_name('a');
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

	my $aitdoctype = "";
	while(<ARCHIVEINDEXTEMPLATEDOCTYPE>)
	{
	    $aitdoctype .= $_;
	}
	close ARCHIVEINDEXTEMPLATEDOCTYPE;

	my $volIssueDate = $ttree->look_down('id','volIssueDate');
	$volIssueDate->push_content($volIssueText,$br,$DateText);

	my $tocIssueTitle = $arch_ttree->look_down('id','tocIssueTitle');
	$tocIssueTitle->push_content($tocIssueTitleText);

	my $fullIssueLinks = $arch_ttree->look_down('id','fullIssueLinks');
	
#	$fullIssueLinks->attr('class','serveIssue');

	my $fullPDFview = $arch_ttree->look_down('id','fullPDFview');

	#In John Sigerson's archive index pages, links to serve the whole issue are private until they are made public 6 weeks after publication.
	$fullPDFview->attr('href',"/eiw/private/$year/eirv$zvol"."n$zissue-$year$zmonth$zmday/eirv$zvol"."n$zissue-$year$zmonth$zmday.pdf");

	my $phpPath = "";
	$phpPath = "/eiw/private/$year/eirv$zvol"."n$zissue-$year$zmonth$zmday/eirv$zvol"."n$zissue-$year$zmonth$zmday.php";

	my $fullPDFdownload = $arch_ttree->look_down('id','fullPDFdownload');
	$fullPDFdownload->attr('href',"$phpPath?ext=pdf");

	my $epubDownload = $arch_ttree->look_down('id','epubDownload');
	if (defined $epubDownload)
	{
	    $epubDownload->attr('href',"$phpPath?ext=epub");
	}

	my $mobiDownload = $arch_ttree->look_down('id','mobiDownload');
	if (defined $mobiDownload)
	{
	    $mobiDownload->attr('href',"$phpPath?ext=mobi");
	}


	my $coverLink = $ttree->look_down('id','coverLink');
	$coverLink->attr('href',"/eiw/private/$year/eirv$zvol"."n$zissue-$year$zmonth$zmday/eirv$zvol"."n$zissue-$year$zmonth$zmday.pdf");

	my $coverImg = $ttree->look_down('id','coverImg');
	$coverImg->attr('src',"/eiw/public/$year/eirv$zvol"."n$zissue-$year$zmonth$zmday/eirv$zvol"."n$zissue".'lg.jpg');

	my $cover = $arch_ttree->look_down('id','cover');
	$cover->attr('src',"/eiw/public/$year/eirv$zvol"."n$zissue-$year$zmonth$zmday/eirv$zvol"."n$zissue-$year$zmonth$zmday-cover.jpg");
	$coverImg->attr('width',undef);
	$coverImg->attr('height',undef);
	$cover->attr('width',undef);
	$cover->attr('height',undef);

	my $pqPDF = $ttree->look_down('id','pqPDF');
	$pqPDF->attr('href',"/eiw/private/$year/eirv$zvol"."n$zissue-$year$zmonth$zmday/eirv$zvol"."n$zissue-$year$zmonth$zmday".'.pdf');
	my $mobi = $ttree->look_down('id','mobi');
	if (defined $mobi)
	{
	    $mobi->attr('href',"/eiw/private/$year/eirv$zvol"."n$zissue-$year$zmonth$zmday/eirv$zvol"."n$zissue-$year$zmonth$zmday.mobi");
	}
	my $epub = $ttree->look_down('id','epub');
	if (defined $epub)
	{
	    $epub->attr('href',"/eiw/private/$year/eirv$zvol"."n$zissue-$year$zmonth$zmday/eirv$zvol"."n$zissue-$year$zmonth$zmday.epub");
	}
	my $archive = $ttree->look_down('id','archive');
	$archive->attr('href',"/eiw/public/$year/index.html");
	
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

        #Links in the TOC to articles may contain "../Text/", which is unnecessary because the TOC in an EPUB generated by Calibre is always in the Text directory.  To simplify processing, we remove the unnecessary part of the URL here.
	    $htmlHref =~ s%^\.\./Text/%%;
	    $htmlLink->attr('href',$htmlHref);

	    if ($htmlHref =~ m%/%) {next}
	    #get the next PDF link
	    # @singleArticleURLs contains two relative URLs for each single Article PDF: first, the relative URLs for the subscriber's issue index page, in their order of appearance in the table of contents, then those for the archive issue index page, in the same order, in that order.
	    my $saurl = shift @singleArticleURLs;
	    #save this $saurl in a hash to use when inserting a link to the PDF
	    #into the subscriber's HTML article page, which will be placed in the same directory as the subscriber's issue index page.  We will not repeat this step when generating the archive issue index page, because that would cause the first hash for each $htmlHref to be overwritten by a value appropriate for a page in the directory of the archive issue index page.
	    $saurlList{$htmlHref} = $saurl;
	    
	    my $filename = $htmlHref;
	    my $htmlLinkClone = $htmlLink->clone();
	    removeBrs($htmlLinkClone);
	    my $titleText = $htmlLinkClone->as_text;
	    $htmlLinkClone->delete;
	    $tffs{$htmlHref} = $titleText;
	    $ffts{$htmlHref} = filenameFromTitle($titleText);
	    if (not $publicsOnly)
	    {
		print "-b $htmlHref"."="."$pft$ffts{$htmlHref} ^\n";
	    }

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
	    #my $htmlLinkText = $htmlLink->as_text;
	    #skip links to targets that are not articles from the epub
	    if ($htmlHref !~ /\.xhtml$/) {next}

        #Links in the TOC to articles may contain "../Text/", which is unnecessary because the TOC in an EPUB generated by Calibre is always in the Text directory.  To simplify processing, we remove the unnecessary part of the URL here.
	    $htmlHref =~ s%^\.\./Text/%%;
	    $htmlLink->attr('href',$htmlHref);

	    if ($htmlHref =~ m%/%) {next}
	    #get the next PDF link
	    # @singleArticleURLs contains two relative URLs for each single Article PDF: first, the relative URLs for the subscriber's issue index page, in their order of appearance in the table of contents, then those for the archive issue index page, in the same order, in that order.
	    my $saurl = shift @singleArticleURLs;
	    my $pinsert = HTML::Element->new('a');
	    if (! $makeUnlistedArchiveIndex && $saurl =~ m%/private/%)
	    {	
		#replace the unlisted HTML link with the subscribers-only PDF link and a hidden placeholder for the future public HTML link
		$htmlLink->attr('href',$saurl);
		$htmlLink->attr('class','tocLinkSubPDF');
		$pinsert->attr('href','#');
		$pinsert->attr('class','tocLinkHiddenHTML');
	    }
	    else
	    {
		#replace the unlisted HTML link with the public HTML link if available (in updateLinksToArticles), otherwise, link it to the archive issue index page, in both cases followed by a public PDF link.
		$htmlLink->attr('href',$saurl);
		$htmlLink->attr('class','tocLinkPDF');
		if (! $makeUnlistedArchiveIndex && not defined $publics{$htmlHref})
		{
		    $pinsert->attr('href','#');
		    $pinsert->attr('class','tocLinkHiddenHTML');
		}
		else
		{
		    $pinsert->attr('href',$htmlHref);
		    $pinsert->attr('class','tocLinkAltHTML');
		}
	    }
	    $pinsert->push_content('&nbsp;');
	    #put a space before the non-breaking public PDF link so it can wrap to the next line if necessary.
	    $htmlLink->postinsert(' ');
	    $htmlLink->postinsert($pinsert);
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
	my @atocblurbs = $atoc->look_down('_tag','p','class',qr/.*blurb/i);
	foreach $atocblurb (@atocblurbs)
	{
	    $atocblurb->attr('class','tocBlurb');
	}
	my @tocblurbs = $toc->look_down('_tag','p','class',qr/.*blurb/i);
	foreach $tocblurb (@tocblurbs)
	{
	    $tocblurb->attr('class','articleblurb');
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
		if (not defined $kickra) 
		{
		    print STDERR "kicker without link in table of contents\n";
		}
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
	my @articleLinks =  $atoc->find_by_tag_name('a');
	foreach $aL (@articleLinks)
	{
	    my $found = 0;
	    my $aLtext  = $aL->as_text;
	    $aLtext =~ s%&nbsp;% %gs;
	    if ($aLtext =~ m%\S%)
	    {
		$aL->attr('title',$aLtext);
		$found = 1;
	    }
	    else
	    {
		my @aLlefts = $aL->left;
		foreach $aLleft (@aLlefts)
		{
		    if (ref($aLleft) eq 'HTML::Element' and $aLleft->tag eq 'a')
		    {
			$aLtext  = $aLleft->as_text;
			$aLtext =~ s%&nbsp;% %gs;
			if ($aLtext =~ m%\S%)
			{
			    $aL->attr('title',$aLtext);
			    $found = 1;
			    last;
			}
		    }
		}
	    }
	    if (not $found)
	    {
		warn ("No text found for article link ".$aL->as_HTML);
	    }
	}
	
	correctNSClassNames ($ttree);

	updateLinksToArticles ($ttree,$infilepath,$outfilepath,1);
	updateSiteRelativeLinks ($ttree,$infilepath,$outfilepath);
	updateLinksToArticles ($arch_ttree,$infilepath,$full_arch_outfilepath,1);
	updateSiteRelativeLinks ($arch_ttree,$infilepath,$full_arch_outfilepath);
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
	
	$output = $aitdoctype;
	$output .= $arch_ttree->as_HTML("","\t",\%empty);
	$arch_ttree->delete;
#FOR HTML5 compliance:
	$output =~ s/&(\s)/&amp;$1/gs;

	print ARCH_OUTFILE $output;
	close ARCH_OUTFILE;

	last;
    }
}


#now process the article pages
foreach $infilepath (@noncmInfiles)
{
    #don't process article pages if we're only generating the archive index.
    if ($aio) {last}
    my $saurl = filenameFromPath ($infilepath);
    if ($saurl eq $indexFileName) {next} #don't re-process the index page
    #skip if only public articles are to be processed and this is not a 
    #public article
    if ($publicsOnly and not defined $publics{$saurl}) {next};

    $outfilepath = $infilepath;
    if (prepareFiles($infilepath,\$ttree,\$tree,\$content,\$body_text,\$outfilepath))
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
	    $issueIndexLink->attr('href',$iirp.$iip);
	}
	else
	    #use the default link to the issue index page in the EIR archive, which is under construction when the issue is new.
	{
	    my $piiarp = $options{'publicIssueIndexArchiveRootPath'};
	    $issueIndexLink->attr('href',$piiarp."$year/eirv$zvol"."n$zissue".'-'."$year$zmonth$zmday/index.html");
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
	updateSiteRelativeLinks ($ttree,$infilepath,$outfilepath);
	
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

	#non-breaking space entities in the template or the epub get converted
	#into illegal characters that display as question marks in the web page,
	#therefore it is necessary to use a div class="nbsp" in the epub and 
	#in the template and convert it here to the entity.
	my @nbsp = $ttree->look_down('class','nbsp');
	foreach $nbsp (@nbsp)
	{$nbsp->replace_with('&nbsp;&nbsp;&nbsp;&nbsp;')->delete}

	correctNSClassNames($ttree);

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
    
    print BROWSERSCRIPT '"'.$browserPath.'" '.$browserOptions.' '.$url.' > '.$ofp."\n";
} 

sub isTargetedDomain
{
    return $_[0] =~ m%(www\.)?$domainName%i;
}

sub updateSiteRelativeLinks ($$$)
{
    my ($ttree, $infilepath, $outfilepath) = @_;
    my @srs = $ttree->find_by_tag_name('script');
    push (@srs, $ttree->find_by_tag_name('link'));
    push (@srs, $ttree->find_by_tag_name('a'));
    foreach $sr (@srs)
    {
	my $src = $sr->attr('src');
	if ($sr->tag ne 'script') {$src = $sr->attr('href')}
	my $srcUri = URI->new($src);
	#skip email links
	if (defined $srcUri->scheme and $srcUri->scheme eq "mailto") {next} 
	#skip absolute links to sites other than the site to which the pages generated by this script will be posted.
	if (defined $srcUri->authority and not isTargetedDomain($srcUri->authority)) {next}
	#skip absolute links that are not HTTP
	if (defined $srcUri->scheme and $srcUri->scheme !~ /^http/) {next}

	if (not defined $srcUri->path or $srcUri->path eq '') {$srcUri->path('/')}
	#site relative links to the document root are acceptable as-is.
	if ($srcUri->path eq '/') {next}

	if (defined $srcUri->scheme) {$srcUri->scheme(undef)}
	if (defined $srcUri->authority) {$srcUri->authority(undef)}

	my @src = File::Spec->splitpath($srcUri->path);
	my $srcdir = $src[1];

	#skip non-site-relative links
	if (substr($srcdir,0,1) ne '/') {next} 
	
	$srcdir = $docRoot.$srcdir;
	$src = $srcdir.$src[2];
	$src =~ s%\\%/%g;
	 
	my $newsrcpath = "";
	my @infilepath = File::Spec->splitpath($infilepath);
	$srcdir =~ s%/$%%; #remove '/' at end
	#calculate absolute path from the original HTML file location
	my $infilepathFS = $infilepath;
	$infilepathFS =~ s%\\%/%g;
	my $pathUri = URI->new($src);
	$newsrcpath = $pathUri->abs($infilepathFS);
	
	#calculate new relative path from the HTML output file location
	$newsrcpath =~ s%\\%/%g;
	my $newsrc = findRelPath($outfilepath,$newsrcpath);
	#preserve the query string while updating the path
	$srcUri->path($newsrc);
	if ($sr->tag ne 'script')
	{
	    $sr->attr('href',$srcUri)
	}
	else
	{
	    $sr->attr('src',$srcUri)
	}
    }
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

	if (substr($srcdir,0,1) eq '/') 
	{
	    $srcdir = $docRoot.$srcdir;
	    $src = $srcdir.$src[2];
	    $src =~ s%\\%/%g;
	} 

	my $id = $img->id;
	#the link to the cover image was updated when created.
	if (defined $id and ($id eq 'coverImg' or $id eq 'cover')) {next}

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

sub prepareFiles($$$$$$;$)
{
    ($infilepath,$ttree,$tree,$content,$body_text,$outfilepath,$flag) = @_;
    print STDERR "Processing $infilepath\n";
    my @infile = File::Spec->splitpath($infilepath);
    my $titleText = $tffs{$infile[2]};

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
    my $toc = 0;

    if ($body_text =~ /Cover\s*This\s*Week/si)
    {
	$toc = 1;
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
	else 
	{
	    print STDERR "assigning filename 'index.html' to $infile[2]\n";
	    $outfilename = "index.html"
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
	$outfilename =~ s/\.xhtml$/\.html/i;
    }
    if (defined $ud and $ud ne "")
    {
	my $uarp = $options{'unlistedArticlesRootPath'};
	$uarp =~ s%/%\\%g;
	$uarp =~ s%\\$%%;
	$outfiledir = $docRoot.$uarp.'/'.$ud . '/';
	$outfiledir =~ s%/%\\%g;
    }
    if (($fft ne "" or $pft ne "") and (not $toc))
    {
	$outfilename = $ffts{$infile[2]};
    }

    #If this subroutine was called with $outfilepath = '', don't write anything.

    if ($outfilepath ne "")
    {
	print STDERR "computing outfilepath for $infile[2]\n";
	$outfilepath = $outfiledir.$outfilename;
	my $debugfilepath = $outfiledir.'zzzz'.$outfilename.'.debug.log'; 
	make_path($outfiledir);
	open(OUTFILE,"+>$outfilepath") || die "can't open $outfilepath for writing: $!"; 
	open(DEBUG,">$debugfilepath") || die "can't open $debugfilepath for writing: $!"; 

	#find document-relative path to $docRoot
#	$root = findRelPath($outfilepath,$docRoot.'/');
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
    my $filenameExt = $_[1];
    if (not defined $filenameExt) {$filenameExt = 'html'}
    $title =~ s/[^a-z0-9]/_/gi;
    $title =~ s/__+/_/g;
    $title =~ s/^_//;
    $title = substr($title,0,30);
    $title =~ s/_$//;
    $title = lc($title);
    #guarantee that the title-derived basename (Basename From Title) is unique
    while (defined $bfts{$title})
    {
	$title = incPath($title);
    }
    $bfts{$title} = "";
    return $zvol.$zissue.'-'.$title.'.'.$filenameExt;
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
	    if (defined $text->parent and defined $text->parent()->attr('class'))
	    {
		if ($text->parent()->attr('class') eq 'lc')
		{
		    $text->attr('text', lc $t); 
		    next
		}
		if ($text->parent()->attr('class') eq 'uc')
		{
		    $text->attr('text', uc $t); 
		    next
		}
	    }

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

sub correctNSClassNames($)
{
	#correct non-standard class names introduced by Calibre's epub compressor.  Calibre will not allow the same class to have different CSS when used with different tags, so it creates new classes by appending '1' to the class name.
    my $tree = $_[0];

	my @head1s = $tree->look_down('class',qr/head1/i);
	foreach $head1 (@head1s)
	{
	    my $class = $head1->attr('class');
	    $class =~ s/1$//;
	    $head1->attr('class',$class);
	}
}

sub usage
{
    my $dcf = $program_basename.'.xml';
    my $options_doc = "";
	
    print <<EOF;
perl $0 {-|<config pathname>} [options] <pathname>
<config pathname> is the pathname of the configuration file, relative to $0
- uses the default configuration file, $dcf
<pathname> is the pathname of the input file, relative to the website
document root as specified in the configuration file, however:
It should begin with a forward slash, use only forward slashes, and
should be quoted if it contains spaces.  The spaces and other non-web-safe
characters should not be converted to web-safe entities like '%20'

For a list of options, use perl $0 - -help

EOF

exit
}
