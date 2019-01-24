=head1 SYNOPSIS

perl makeEIRpagesResponsive.pl {-|<config pathname>} [options] <pathname>

=head1 OPTIONS

Each option must be preceded by a double hyphen '--' to indicate that it is an option, except:
options with single character names may be preceded by a single hyphen '-'.

Alternative names for an option are separated by '|'.

Options whose name(s) are followed by '=' require an argument.  The letter following the '=' specifies the argument type (s for string). If the argument type is folllowed by '%', the option  may be used multiple times in the same command line with an argument for each instance.

 appendBrowserScript|abs

appendBrowserScript|abs causes the browser script to be appended instead of overwritten. Regardless of options, this script generates a browser script that can be used to invoke a browser to download  all the non-responsive EIR pages that are linked from the EIR home page, insert JavaScript in those pages, execute the JavaScript, then write the result.  The browser script is written to the value of 'browserScriptPath' in the config file.  Each line of the browser script will contain bp bo URL > lpp, where 'bp' is the value of 'browserPath' in the config file, 'bo' the value of 'browserOptions', 'URL' the absolute URL of the page on the site, and 'lpp' is the local page path, the absolute path of the location in the local file system corresponding to the URL to which the new responsive page will be uploaded. The 'docroot' attribute of the 'domain' tag in the config file is prepended to the path portion of the URL to calculate the lpp.  If the config. file lacks 'browserOptions', '--headless --dump-dom', the options appropriate for Chrome and other Chromium-based browsers such as Yandex, are inserted by default.

=cut

use HTML::TreeBuilder;
use HTML::Element;
use File::Spec;
use File::Find;
use File::Path qw(make_path remove_tree);
use Fcntl ':mode';
use File::Copy;
use HTML::Entities;
use URI;
use WWW::Mechanize;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use Cwd;
use Encode qw/encode decode /;
use HTML::Entities qw/:DEFAULT encode_entities_numeric/;


$HTML::Tagset::isKnown{"domain"} = 1;
$HTML::Tagset::isHeadOrBodyElement{"domain"} = 1;

%empty = (); #use as 3rd parameter for HTML::Element->as_HTML() to specify that the HTML generated shall close all open tags

sub isTargetedAuthority($);
sub findAbsPath($$);
sub findRelPath($$);
sub filenameFromPath($);
sub updateSiteRelativeLinks($$$);
sub updateImageLinks($$$);
sub updateDocumentRelativeLinks($$$$);


my $help = 0;
my $appendBrowserScript = 0;

GetOptions ('help|?' => \$help,'appendBrowserScript|abs' => \$appendBrowserScript);
pod2usage(1) if $help;

my $program_basename = $0;
$program_basename =~ s/\.[^\.]*$//;
close STDERR;
open (STDERR, ">$program_basename"."_err.txt") || die "can't open $program_basename"."_err.txt for writing: $!";

print "\nError messages will written to $program_basename"."_err.txt in the current working directory\n\n";

if (@ARGV < 2) {usage()}
#debug output is off by default.  It is turned on by using 'debug' as the first command-line argument OR by defining debug with any value in the configuration file.
my $debug = 0;
if (lc($ARGV[0]) eq 'debug')
{
    $debug = 1;
    shift @ARGV
}
if (@ARGV < 2) {usage()}

#process the config file selector
my $configPath = $ARGV[0];

if ($configPath eq '-') {$configPath = "$program_basename.xml"}
else {$configPath = "$program_basename-$configPath.xml"}



my $domain;
my %options = ();
get_config ($configPath, \$domain, \%options);

#debug output is off by default.  It is turned on by using 'debug' as the first command-line argument OR by defining debug with any value in the configuration file.
if (defined $options{'debug'}){$debug = 1}

my $docRoot = $domain->attr('docroot');
my $domainName = $domain->attr('name');
my $targetedAuthority = $domainName;
$targetedAuthority =~ s%^http.*?://%%;

my $outputFileLinksPage = $options{'outputFileLinksPage'};
    if (defined $outputFileLinksPage)
    {
	open(OFLP,">$outputFileLinksPage") || die "can't open $outputFileLinksPage for writing: $!"; 
    }
    else
    {
	open(OFLP, ">$nullDevice") || die "can't open $nullDevice for writing: $!"; 
    }

my $bsp = $options{'browserScriptPath'};
if (not defined $bsp) {$bsp = 'epub2htmlRunJS.bat'}
my $browserPath = $options{'browserPath'};
my $browserOptions = $options{'browserOptions'};
if (not defined $browserOptions) {$browserOptions = '--headless --dump-dom'}
if (not defined $browserPath) {$browserPath = '%BROWSER_PATH%'}
my $delCmd = $options{'delCmd'};
if (not defined $delCmd) {$delCmd = 'del'}
my $responsivePagesPathPrefix = $options{'responsivePagesPathPrefix'};
my $nullDevice = $options{'nullDevice'};
my $localHostURL = $options{'localHostURL'};
my $articleTemplatePath = $options{'articleTemplatePath'};
if (not defined $responsivePagesPathPrefix) {$responsivePagesPathPrefix = '\r'}
if (not defined $nullDevice) {$nullDevice = 'nul'}
if (not defined $localHostURL) {$localHostURL = 'http://localhost:8000'}
if (not defined $articleTemplatePath) {$articleTemplatePath = 'process_nr_article_template.html'}


if ($appendBrowserScript)
{
    open (BROWSERSCRIPT, ">>$bsp") || die "can't open $bsp for appending: $!";
}
else
{
    open (BROWSERSCRIPT, "+>$bsp") || die "can't open $bsp for writing: $!";
}

open(ARTICLETEMPLATE, $articleTemplatePath) || die "can't open $articleTemplatePath for reading: $!";
#my $articletemplate = "";
#while (<ARTICLETEMPLATE>) {$articletemplate .= $_}
#close ARTICLETEMPLATE;

my $attree = HTML::TreeBuilder->new;
$attree->parse_file(\*ARTICLETEMPLATE);
close ARTICLETEMPLATE;

#process the input file/directory/glob pattern.
my $inpath = "";
$inpath = $ARGV[1];
#Extract filenames from $inpath

$inpath =~ s%/%\\%g;

$inpath = File::Spec->join($docRoot,$inpath);

@inpath = File::Spec->splitpath($inpath);
@infiles = ();
%relocations = ();

my $is_directory = 0;
my $mode = undef;
$mode = (stat($inpath))[2];
if (defined $mode)
{$is_directory = S_ISDIR($mode)}

if ($is_directory)
{
    find (\&wanted, $inpath);
}
elsif ($inpath[2] =~ /[\?\*]/)
{
    print "globpath: $inpath\n";
    @infiles = glob ($inpath);
}

else
{@infiles = ($inpath)}

#build hash of new URLs for pages to be made responsive keyed by their current URLs 
foreach $infilepath (@infiles)
{
    if (! open(INFILE, $infilepath)){print STDERR "can't open $infilepath for reading: $!"; next}
    #process only non-responsive webpages
    my $responsive = 0;
    while (<INFILE>)
    {
	if ($_ =~ /meta content="width=device-width/) {$responsive = 1; last}
    }
    close INFILE;
    if ($responsive){next}
    my @infile = File::Spec->splitpath($infilepath);
    my $infileDir = File::Spec->join($infile[0],$infile[1]);
    my $siteRelInfileDir = substr($infileDir,length($docRoot));
    my $outfiledir = $docRoot.$responsivePagesPathPrefix.$siteRelInfileDir;
    my $err = undef;
    make_path($outfiledir, {error => \$err});
    if (@$err) {
	for my $diag (@$err) {
	    my ($dir, $message) = %$diag;
	    if ($dir eq '') {
		print STDERR "general error: $message\n";
	    }
	    else {
		print STDERR "problem creating $dir: $message\n";
	    }
	}
	next;
    }
    
    my $outfile = File::Spec->join($outfiledir,$infile[2]);
    $relocations{$infilepath} = $outfile;
}

foreach $infilepath (keys %relocations)
{
    if (! open(INFILE, "<:encoding(utf-8)", $infilepath)){print STDERR "can't open $infilepath for reading: $!"; next}
    my $outfile = $relocations{$infilepath};
    my @outfile = File::Spec->splitpath($outfile);
    my $outfiledir = File::Spec->join($outfile[0],$outfile[1]);
    if ($debug)
    {
	open(DEBUG,">$outfile.debug.html") || die "can't open $outfile.debug.html for writing: $!"; 
    }
    else
    {
	open(DEBUG, ">$nullDevice") || die "can't open $nullDevice for writing: $!"; 
    }

    my $tree = HTML::TreeBuilder->new();
    $tree->store_comments(1);
    $tree->parse_file(\*INFILE);
    close INFILE;

    
    my $safeChars = "";
    my $typeMeta = $tree->look_down('_tag','meta','http-equiv',qr/content-type/);
    #if not utf-8, encode all unsafe characters as HTML entities
    if ((not defined $typeMeta) or $typeMeta->attr('content') !~ /charset=utf-8/i)
    {$safeChars = undef}
=head
    #if not utf-8, read it again as iso-8859-1, and encode it as utf-8
    {
	if (! open(INFILE, "<:encoding(Latin-1)", $infilepath)){print STDERR "can't open $infilepath for reading: $!"; next}
	$tree->store_comments(1);
	$tree->parse_file(\*INFILE);
	close INFILE;
    }
=cut
    my $dirURL = $outfiledir;
    $dirURL = $localHostURL . substr($dirURL,length($docRoot));
    $dirURL =~ s%\\%/%g;
    my $savedDir = getcwd();
    #open temporary file for writing. Write it out in utf-8.
    open (TEMP,"+>:encoding(utf-8)","$outfiledir\\temp.html") || die "can't open $outfiledir\\temp.html for writing: $!";
    #open (TEMP,"+>$outfiledir\\temp.html") || die "can't open $outfiledir\\temp.html for writing: $!";

    my @acontent = $tree->find_by_tag_name('body')->content_list;
    my @atitle = $tree->find_by_tag_name('title');
    my $acontentdiv = HTML::Element->new('div','id','old_article_content');
    $acontentdiv->push_content(@acontent);
    
    #make a clone of the article template
    my $attreeClone = $attree->clone();

    #insert the content of the old page into the clone of the article template
    my $atbody = $attreeClone->find_by_tag_name('body');
    $atbody->push_content($acontentdiv);
    my $athead = $attreeClone->find_by_tag_name('head');
    $athead->push_content(@atitle);

    #update links in $attreeClone
    updateImageLinks($attreeClone,$infilepath,$outfile);
    my $changedLinksHashRef = updateSiteRelativeLinks ($attreeClone,$infilepath,$outfile);
    updateDocumentRelativeLinks ($attreeClone,$infilepath,$outfile,$changedLinksHashRef);

    #write the stuffed clone of the article template to a temporary HTML file
    my $tempfile = $attreeClone->as_HTML($safeChars,"\t",\%empty);
    #decode_entities ($tempfile);
   # $tempfile =~ s%\xc297%&8212;%gs;
    #encode_entities_numeric ($tempfile);
   # my %safeEntities = ('&lt;','<','&gt;','>');
    #_decode_entities($tempfile,{lt=>'<',gt=>'>'});
    print TEMP $tempfile;
    close TEMP;

    #discard the stuffed clone of the article template
    $attreeClone->delete;

    #use a browser to execute the JavaScript on the temporary HTML file and save to $outfile
    chdir $outfiledir;
    my $cmd = '"'.$browserPath.'" '.$browserOptions.' "'.$dirURL.'/temp.html" > "'.$outfile.'"';
    system($cmd);
    system($delCmd.' temp.html');
    chdir $savedDir;
    my $outfileURL = substr($outfile,length($docRoot));
    $outfileURL =~ s%\\%/%g;
    print OFLP '<a href="'.$outfileURL.'">'.$outfileURL.'</a><br />'."\n";
}
close OFLP;

sub wanted
{
    if (not -f $_) {next}
    if ($_ !~ /\.(html?)$/i) {next}
    my $path = $File::Find::name;
    $path =~ s%/%\\%g;
    push (@infiles,$path);
}
sub isTargetedAuthority($)
{
    return $_[0] =~ m%^(www\.)?$targetedAuthority$%i;
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
sub updateSiteRelativeLinks ($$$)
{
    my ($ttree, $infilepath, $outfilepath) = @_;
    my %changedLinks = ();
    my @srs = $ttree->find_by_tag_name('script');
    push (@srs, $ttree->find_by_tag_name('link'));
    push (@srs, $ttree->find_by_tag_name('a'));
    foreach $sr (@srs)
    {
	my $src = $sr->attr('src');
	if ($sr->tag ne 'script') {$src = $sr->attr('href')}
	#skip tags with no src or href attribute
	if (not defined $src) {next}
	my $origSrc = $src;
	my $srcUri = URI->new($src);
	#skip email links
	if (defined $srcUri->scheme and $srcUri->scheme eq "mailto") {next} 
	#skip absolute links that are not HTTP
	if (defined $srcUri->scheme and $srcUri->scheme !~ /^http/) {next}
	#skip absolute links to sites other than the site to which the pages generated by this script will be posted.
	if (defined $srcUri->authority and not isTargetedAuthority($srcUri->authority)) {next}

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

	if ($infilepathFS eq $src)
	{
	    if (not defined $srcUri->fragment or $srcUri->fragment eq "")
	    {
		$srcUri = URI->new('#');
	    }
	    else  #keep the fragment, delete the path
	    {
		$srcUri->path("");
	    }
	}
	else
	{
	    my $pathUri = URI->new($src);
	    $newsrcpath = $pathUri->abs($infilepathFS);
	    
	    #calculate new relative path from the HTML output file location
	    $newsrcpath =~ s%\\%/%g;
	    my $newsrc = findRelPath($outfilepath,$newsrcpath);
	    #preserve the query string while updating the path
	    $srcUri->path($newsrc);
	}
	if ($sr->tag ne 'script')
	{
	    $sr->attr('href',$srcUri)
	}
	else
	{
	    $sr->attr('src',$srcUri)
	}
	$changedLinks{$srcUri} = $origSrc;
    }
    return \%changedLinks;
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

	my $srcUri = URI->new($src);
	my $newsrcpath = "";
	my @infilepath = File::Spec->splitpath($infilepath);
	$srcdir =~ s%/$%%; #remove '/' at end
	    #calculate absolute path to the image from the original HTML file location
	    my $infilepathFS = $infilepath;
	    $infilepathFS =~ s%\\%/%g;
	    $newsrcpath = $srcUri->abs($infilepathFS);
	#calculate new relative path to the image from the HTML output file location (which may be the same as the input, except for the filename extension)
	$newsrcpath =~ s%\\%/%g;
	my $newsrc = findRelPath($outfilepath,$newsrcpath);
	$img->attr('src',$newsrc)
    }
}
sub updateDocumentRelativeLinks ($$$$)
{
    my ($ttree,$infilepath,$outfilepath,$changedLinksHashRef) = @_;
    my $infileSiteRelativeURL = $infilepath;
    $infileSiteRelativeURL = substr($infilepath,length($docRoot));

    my @infile = File::Spec->splitpath($infilepath);
    my $infilename = $infile[2];

    my @dras = $ttree->look_down('_tag','a','href',qr%^[^/]%);
    foreach $dra (@dras)
    {
	if (not defined $dra->attr('href')) {next}
	my $href = $dra->attr('href');

	#if the link URL has already been adjusted to compensate for the movement of the source file, we obtain its site relative URL relative to the original location of the source file
	my $originalHref = $$changedLinksHashRef{$href};
	if (defined $originalHref)
	{
	    #$href was adjusted in updateSiteRelativeLinks
	    $href = $originalHref;
	}

	my $hrefUri = URI->new($href);

	#no need to update absolute links
	if (defined $hrefUri->scheme) {next}

	#links to anchors in the same file should be reduced to just the fragment, so that the link will still work if the file is downloaded and saved under a different filename.
	if ($hrefUri->path eq "" or $hrefUri->path eq $infilename) 
	{
	    if (defined $hrefUri->fragment)
	    {
		$dra->attr('href','#'.$hrefUri->fragment)
	    }
	    else
	    {
		$dra->attr('href','#');
	    }
	    next
	}
	
	
	my $destSiteRelativeURL = findAbsPath($infileSiteRelativeURL,$hrefUri->path);
	my $destPath = $docRoot.$destSiteRelativeURL;
	$destPath =~ s%/%\\%g;

	my $newhrefpath = "";
	my $newhref = "";

	#case 1: destination to be moved
	#calculate absolute path to the new location of the destination
	if (defined $relocations{$destPath}) 
	{
	    my $newDestPath = $relocations{$destPath};
	    $newhrefpath = findRelPath ($outfilepath,$newDestPath);
	    $newhrefpath  =~ s%\\%/%g;
	    if (defined $hrefUri->fragment and $hrefUri->fragment ne "")
	    {$newhrefpath .= '#'.$hrefUri->fragment}
	    $dra->attr('href',$newhrefpath);
	}
	#case 2: source to be moved, but destination will not be moved, and
	#destination is not an anchor in the source, and destination has not already been adjusted to compensate for the movement of the source ($originaHref not defined).
	elsif ($hrefUri->path ne "" and not defined $originalHref)
	{
	    #calculate absolute path to the destination from the original source location
	    my $infilepathFS = $infilepath;
	    $infilepathFS =~ s%\\%/%g;
	    $newhrefpath = $hrefUri->abs($infilepathFS);

	    #calculate relative URL to the destination from the new source location
	    $newhref = findRelPath ($outfilepath,$newhrefpath);
	    $dra->attr('href',$newhref);
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


sub usage
{
    my $dcf = $program_basename.'.xml';
    my $options_doc = "";
	
    print <<EOF;
perl $0 [debug] {-|<config pathname>} [options] <pathname>
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
