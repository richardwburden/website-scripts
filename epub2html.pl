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
sub findRelPath($$);
sub prepareFiles($$$$$$$;$);
sub filenameFromPath($);
sub updateImageLinks($$$);
sub updateLinksToArticles($$$);

%empty = (); #use as 3rd parameter for HTML::Element->as_HTML() to specify that the HTML generated shall close all open tags

open(INDEXTEMPLATE, "issue_index_template.html") || die "can't open issue_index_template.html for reading: $!";
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

GetOptions ('public|b=s%' => \%publics, 'unlisted|u=s%' => \%unlisteds, 'imageDirs|i=s%' => \%imageDirs, 'unlistedImageDirs|iu=s%' => \%unlistedImageDirs, 'privateImageDirs|ip=s%' => \%privateImageDirs, 'unlistedIssueIndexPath|xu=s' => \$uiip, 'publicIssueIndexPath|xp=s' => \$piip, 'unlistedFilename|uf=s' => \$uf, 'appendBrowserScript|abs' => \$appendBrowserScript, 'publicsOnly|po' => \$publicsOnly, 'unlistedDirname|ud=s' => \$ud, 'filenamesFromTitles|fft' => \$fft,);

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
my $bspl = $options{'browserScriptPathLocal'};
if (not defined $bspl) {$bspl = 'epub2htmlRunJSlocal.bat'}
my $browserPath = $options{'browserPath'};
if (not defined $browserPath) {$browserPath = '%BROWSER_PATH%'}

if ($appendBrowserScript)
{
    open (BROWSERSCRIPT, ">>$bsp") || die "can't open $bsp for appending: $!";
    open (BROWSERSCRIPT_LOCAL, ">>$bspl") || die "can't open $bspl for appending: $!";
}
else
{
    open (BROWSERSCRIPT, "+>$bsp") || die "can't open $bsp for writing: $!";
    open (BROWSERSCRIPT_LOCAL, "+>$bspl") || die "can't open $bspl for writing: $!";
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
	print "$infile[2] --> $newFileName\n";
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

#Fetch the index with links to the PDFs
	my $pdfIndexPath = $options{'pdfIndexPath'};
	$pdfIndexPath =~ s%/%\\%g;
	my $pathFromIndex2PDFIndex = findRelPath($outfilepath,$docRoot.$pdfIndexPath);
	$pdfIndexPath =~ s%\\%/%g;
	my $mech = WWW::Mechanize->new();
	$mech->get($domainName.$pdfIndexPath);
	my $pdfIndexTree = HTML::TreeBuilder->new();
	$pdfIndexTree->parse($mech->content());
#Get the URLs of single article PDFs.  Assumed to be in the correct order in 
#the index at $pdfIndexPath.  URLs assumed to end in /pdf/filename.pdf where 
#filename begins with a page number.
	my @pdfLinks = $pdfIndexTree->look_down('_tag','a','href',qr/\/pdf\/[0-9]+.*pdf$/);
	my @singleArticleURLs = ();
	foreach $pdfLink (@pdfLinks)
	{
	    my $url = $pathFromIndex2PDFIndex.'/'.$pdfLink->attr('href');
	    push @singleArticleURLs, $url
	}

	my $volIssueDateText = $body_text;
	$volIssueDateText =~ s/^.*?Volume\s*(\d+)\s*,\s*Number\s*(\d+),\s*(\S+)\s*(\d+)\s*,\s*(\d+).*/Volume $1, Issue $2_Friday, $3 $4, $5/;
	$vol = $1;
	$zvol = sprintf('%02d', $vol);
	$issue = $2;
	$zissue = sprintf('%02d', $issue);
	$month = $3;
	%zmonths=(qw/January 01 February 02 March 03 April 04 May 05 June 06 July 07 August 08 September 09 October 10 November 11 December 12/);
	$zmonth = $zmonths{$month};
	$mday = $4;
	$zmday = sprintf('%02d', $mday);
	$year = $5;
	my $issueMod10 = $issue % 10;
	my $tenissueGroup = $issue - $issueMod10;
	my $tenissueGroupEnd = $tenissueGroup + 9;
	if ($tenissueGroup == 0){$tenissueGroup = $year.'_01-09'}
	else {$tenissueGroup = $year.'_'.$tenissueGroup.'-'.$tenissueGroupEnd}
	$yearIssue = $year.'-'.$zissue;
	($volIssueText,$DateText) = split /_/,$volIssueDateText;
	
	my $br = HTML::Element->new('br');
	$ttree->parse_file(\*INDEXTEMPLATE);

	my $volIssueDate = $ttree->look_down('id','volIssueDate');
	$volIssueDate->push_content($volIssueText,$br,$DateText);
	
	my $intPDF = $ttree->look_down('id','intPDF');
	$intPDF->attr('href',"$root/eiw/private/$year/$tenissueGroup/$yearIssue/pdf/eirv$zvol"."n$zissue.pdf");
	my $coverLink = $ttree->look_down('id','coverLink');
	$coverLink->attr('href',"$root/eiw/private/$year/$tenissueGroup/$yearIssue/pdf/eirv$zvol"."n$zissue.pdf");
	my $coverImg = $ttree->look_down('id','coverImg');
	$coverImg->attr('src',"$root/eiw/public/$year/$tenissueGroup/$yearIssue/images/eirv$zvol"."n$zissue".'lg.jpg');
	$coverImg->attr('width',undef);
	$coverImg->attr('height',undef);
	my $pqPDF = $ttree->look_down('id','pqPDF');
	$pqPDF->attr('href',"$root/eiw/private/$year/$tenissueGroup/$yearIssue/pdf/eirv$zvol"."n$zissue".'hi-res.pdf');
	my $mobi = $ttree->look_down('id','mobi');
	$mobi->attr('href',"$root/eiw/private/$year/$tenissueGroup/$yearIssue/ebook/eirv$zvol"."n$zissue.mobi");
	my $epub = $ttree->look_down('id','epub');
	$epub->attr('href',"$root/eiw/private/$year/$tenissueGroup/$yearIssue/ebook/eirv$zvol"."n$zissue.epub");
	my $archive = $ttree->look_down('id','archive');
	$archive->attr('href',"$root/eiw/public/$year/index.html");
	
	my $toc = $ttree->look_down('id','toc');
	$toc->unshift_content($content);
	#remove the body tag from $content
	$content->replace_with_content->delete;

	updateImageLinks ($ttree,$infilepath,$outfilepath);

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
	    my $saurl = shift (@singleArticleURLs);
	    $saurlList{$htmlHref} = $saurl;
	    $htmlLink->push_content(' <span class="tocLinkHTML">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>');
	    #insert the PDF link
	    $htmlLink->postinsert(' <a href="'.$saurl.'"><span class="tocLinkAltPDF">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span></a>');
	}

	updateLinksToArticles ($ttree,$infilepath,$outfilepath);

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
	last;
    }
}


#now process the article pages
foreach $infilepath (@infiles)
{
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
	updateLinksToArticles ($ttree,$infilepath,$outfilepath);

	
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
close BROWSERSCRIPT_LOCAL;

sub writeBrowserScript
{
    my $ofp = $_[0];
    my $ofpcopy = $ofp;
    $ofpcopy =~ s%\.([^\.]*)$%.copy.$1%;
    my $docRootRelPath = substr($ofp,length($docRoot));
    my $url = $docRootRelPath;
    $url =~ s%\\%/%g;
    $url = $domainName.$url;
    my $localurl = 'file:///'.$docRoot.$docRootRelPath;
    $localurl =~ s%\\%/%g;
    print BROWSERSCRIPT_LOCAL  $browserPath.' --headless --dump-dom '.$localurl.' > '.$ofpcopy."\n".'move '.$ofpcopy.' '.$ofp."\n";
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
sub updateLinksToArticles ($$$)
{
#We need to update links to articles in the same issue if 1) the destination
#is an article, or an anchor in an article, that is to be moved 2) if the article that contains
#the link is to be moved, and the destination is not an anchor in the same article.
    my ($ttree,$infilepath,$outfilepath) = @_;
    my @infile = File::Spec->splitpath($infilepath);
    my $infilename = $infile[2];
    $infilename =~ s%\#.*$%%;
    #select only links to files in the same directory.  Usually their URLs contain
    #no slashes.
    my @ltas = $ttree->look_down('_tag','a','href',qr%^[^/]+$%);
    #Links to anchors in the same file, and to other files in the same epub,
    # beginning with "../Text/" are generated by the Calibre epub editor,
    #which also places the .xhtml files in the Text directory.
    my @extra_ltas = $ttree->look_down('_tag','a','href',qr%^\.\./Text/%);
    foreach $elta (@extra_ltas)
    {
	my $href = $elta->attr('href');
	$href =~ s%^\.\./Text/%%;
	$elta->attr('href',$href);
    }
    push @ltas,@extra_ltas;
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
    $title = substr($title,0,20);
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
