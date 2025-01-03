#read a URL
#calculate path to local file
#copy local file to STDOUT	

use File::Spec;
use URI;
use URI::file;
use Cwd;

sub usage;

my $program_basename = $0;
$program_basename =~ s/\.[^\.]*$//;
close STDERR;
open (STDERR, ">$program_basename"."_err.txt") || die "can't open $program_basename"."_err.txt for writing: $!";

if (@ARGV < 2) {usage()}

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


#debug output is off by default.  It is turned on by using 'debug' as the first command-line argument OR by defining debug with any value in the configuration file.
if (defined $options{'debug'}){$debug = 1}


my $url = "";
if (defined $ARGV[1]) {$url = $ARGV[1]}


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
    my $cmd = '"'.$browserPath.'" '.$browserOptions.' '.$dirURL.'/temp.html > temp2.html';

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
	push (@$arRef, $content->look_down('_tag','span','class',$class))
    }
}

sub getFullClassName
{
    if ($_[0] =~ m/^\d+$/) {return 'CharOverride-'.$_[0]}
    else {return $_[0]}
}
