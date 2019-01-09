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

$HTML::Tagset::isKnown{"domain"} = 1;
$HTML::Tagset::isHeadOrBodyElement{"domain"} = 1;

%empty = (); #use as 3rd parameter for HTML::Element->as_HTML() to specify that the HTML generated shall close all open tags

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

my $bsp = $options{'browserScriptPath'};
if (not defined $bsp) {$bsp = 'epub2htmlRunJS.bat'}
my $browserPath = $options{'browserPath'};
my $browserOptions = $options{'browserOptions'};
if (not defined $browserOptions) {$browserOptions = '--headless --dump-dom'}
if (not defined $browserPath) {$browserPath = '%BROWSER_PATH%'}
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


foreach $infilepath (@infiles)
{
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
    if (! open(INFILE, $infilepath)){print STDERR "can't open $infilepath for reading: $!"; next}

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
    my $dirURL = $outfiledir;
    $dirURL = $localHostURL . substr($dirURL,length($docRoot));
    $dirURL =~ s%\\%/%g;
    my $savedDir = getcwd();
    #open temporary file for writing
    open (TEMP,"+>$outfiledir\\temp.html") || die "can't open $outfiledir\\temp.html for writing: $!";

    my @acontent = $tree->find_by_tag_name('body')->content_list;
    my @ahead = $tree->find_by_tag_name('head')->content_list;
    my $acontentdiv = HTML::Element->new('div','id','old_article_content');
    $acontentdiv->push_content(@acontent);
    
    #make a clone of the article template
    my $attreeClone = $attree->clone();

    #insert the content of the old page into the clone of the article template
    my $atbody = $attreeClone->find_by_tag_name('body');
    $atbody->push_content($acontentdiv);
    my $athead = $attreeClone->find_by_tag_name('head');
    $athead->push_content(@ahead);

    #write the stuffed clone of the article template to a temporary HTML file
    print TEMP $attreeClone->as_HTML("","\t",\%empty);
    close TEMP;

    #discard the stuffed clone of the article template
    $attreeClone->delete;

    #use a browser to execute the JavaScript on the temporary HTML file and save to $outfile
    chdir $outfiledir;
    my $cmd = '"'.$browserPath.'" '.$browserOptions.' "'.$dirURL.'/temp.html" > "'.$outfile.'"';
    system($cmd);
    chdir $savedDir;
}

sub wanted
{
    if (not -f $_) {next}
    if ($_ !~ /\.(html?)$/i) {next}
    my $path = $File::Find::name;
    $path =~ s%/%\\%g;
    push (@infiles,$path);
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
