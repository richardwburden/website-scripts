  use CGI qw/:standard/;
  use File::Find;
use File::Spec;
use HTML::TreeBuilder;
use HTML::Element;
use HTML::Entities;
use URI;


  print header,
        start_html('Directory Listing'),
        p(a({-href=>'http://schillerinstitute.org'},'Schiller Institute home page')),
        start_form,
        "Directory pathname",textarea('path_list'),br,
		"Paths are relative to the site root, one per line",br,
                "use forward slashes",br,
		"but should not begin with a slash. Leave blank to search entire site",p,
        "Modified since how long ago?",
        popup_menu(-name=>'age',
                   -values=>['less than 1 hour','less than 1 day','less than 1 week','anytime']),p,
		"Modified less than how many days ago?",textfield('days'),p,
		"Pathname pattern (Perl regular expression)",textfield('pattern'),br,radio_group('file_type',['picture','webpage','other'],'webpage'),
" &nbsp;&nbsp;&nbsp;&nbsp;include filename extension in pattern only if \"other\" is selected",	br,
		"pattern matching is case-insensitive.",p,textarea('wrappers'),p,
    "tags, attributes and text to wrap each link.  One tag per line, followed by a blank space, followed by its attributes in the format normally used in HTML code, excluding the &lt;,&gt;,&lt;/ and /&gt;. Within an attribute or text, use \$url to reference the url of the link, and \$t to reference the title of the webpage if applicable.",p("To specify a blank space at the beginning or end of an attribute, use \\s.",br,"To specify a text to be wrapped, use \- as the first tag, the text as its attributes.",br,"To prepend text to the previous spec, use &lt; as the tag.",br,"To append, use &gt; as the tag",br,"To specify a line break, use \-,&lt; or &gt; as the tag and &lt;br /&gt; or &lt;br&gt; as the attribute"),p("An img tag will replace the spec that precedes it because img tags do not wrap, but are an item to be wrapped.  If no attributes are supplied, src=\$url is assumed."),p("For \"a\" tags with no attributes supplied, href=\$url is assumed"),checkbox({-id=>'show_code', -name=>'show_code',-selected=>0,-value=>'checked',-label=>'show code'}),

        submit,
        end_form,
        hr;

   if (param()) {

       my $age     = param('age');
       my $days = param('days');
       $pattern = param('pattern');
       $show_code = param('show_code');
my $file_type = param('file_type');

       if (defined $pattern) {$pattern =~ s/^\s+//; $pattern =~ s/\s+$//}
       if (not defined $pattern or $pattern eq '') {$pattern = '.*'}
    if ($file_type eq 'picture') {$pattern .= '\.(jpe?g|gif|png)'}
    elsif ($file_type eq 'webpage') {$pattern .= '\.html?'}
       $mintime = time();
       if (defined $days and $days > 0)
       {$mintime -= $days*3600*24}
       elsif ($age eq 'less than 1 hour') {$mintime -= 3600}
       elsif ($age eq 'less than 1 day') {$mintime -= 3600*24}
       elsif ($age eq 'less than 1 week') {$mintime -= 3600*24*7}
       else {$mintime = 0}
       $wrappers = param('wrappers');
       @wrappers = ();
       if (defined $wrappers) {
	   @wrappers  = split /[\r\n]+/,$wrappers;
	   for (my $i=0;$i<@wrappers;$i++) 
	   {$wrappers[$i]=~s%^\s+%%; $wrappers[$i]=~s%\s+$%%}
       }
    

      my $path_list      = param('path_list');
#my $path_list = "educ/joan_ib.html\
#educ/hist/bailly.html";
       my @paths = ();
       my $path_found = 0;
       
       if (defined $path_list) 
       {
	   @paths = split /[\r\n]+/,$path_list;
	   my $path = "";
	   foreach $path (@paths)
	   {
	       $path =~ s/^\s+//; $path =~ s/\s+$//;
 #print '<pre>'.$path.'</pre>';
               $path =~ s/^http:\/\/(www\.)?schillerinstitute\.org\///i;
 #print '<pre>'.$path.'</pre>';
	       $path =~ s/^\///;
	      #print '<pre>'.$path.'</pre>';
	       if ($path eq ""){next}
	       if (isInjectionAttack($path)){print p('Invalid path'); next}
	       else {$path_found = 1}

	       find(\&wanted, '../'.$path);
	   }
       }
       if (not $path_found) {print p('no path'); 
find(\&wanted, '..')
       }
}
print end_html;
   
sub wanted
{
 #print '<pre>'.$File::Find::name.' wanted</pre>';
  if ($File::Find::dir =~ /aaweb/){return}
  if (not -f $_) {next}
  my $href;
  my $href2;
  my $msg = "";
  my $title;
  my $webpage = 0;
  if ($_ !~ /\.(lck|dwsync)$/i)
  {
  	  #print '<pre>'.$pattern.' pattern wanted</pre>';
    if ($File::Find::name !~ m%$pattern%i) {return}
 #print '<pre>'.$_.' wanted</pre>';
if ($_ =~ /\.(html?)$/i) {$webpage = 1}
    my @stat = stat($_);
	$, = ',';
#	print p (@stat);
	   if (not defined $stat[9]) {$msg = " couln't determine modification time"}
   else {$msg = ""}
	if ($mintime == 0 or not defined $stat[9] or $stat[9] > $mintime)
	{ 
      $href = $File::Find::name;
      $href =~ s%^\.\.%.%;
      $href = URI->new($href);
      $href = $href->abs('http://schillerinstitute.org');
	 }
	 else {return}
  }
  else
  {return}
    
  if (not open (INPUT, $_))
  {
  	print p("Can't open $File::Find::name for reading: $!");
      return
  }
  elsif ($webpage)
  {
  	my $tree = HTML::TreeBuilder->new;
  	$tree->parse_file(\*INPUT);
	my $titletag = $tree->find_by_tag_name('title');
	if (defined $titletag and defined $titletag->as_text())
	{$title = $titletag->as_text()}
  }
  else {$title = $href}

  close(INPUT);
  my $report = "";
  if (@wrappers)
  {
      foreach my $w(@wrappers)
      {
	  my $tag = $w;
	  my $atts = $w;
	  $tag =~ s/\s+.*//;
	  $atts =~ s/\S+\s*//;
	  $atts =~ s%\$url%$href%gi;
	  $atts =~ s%\$t%$title%gi;
	  $atts =~ s%\\s% %gi;
	  if ((lc $tag) eq 'img')
	  {
	      if ($atts eq "") {$atts = "src=\"$href\""}
	      $report = "<$tag $atts />"
	  }
	  elsif ((lc $tag) eq 'a' and $atts eq "")
	  {$atts = "href=\"$href\"";
	   $report = "<$tag $atts>$report</$tag>"}
	  elsif ($tag eq '-')
	  {$report = $atts}
	  elsif ($tag eq '>')
	  {$report .= $atts}
	  elsif ($tag eq '<')
	  {$report = $atts.$report}
	  else
	  {$report = "<$tag $atts>$report</$tag>"}
      }
      if ($msg ne "") {$report .= " $msg"}
  }
  else
  {$report = p(a({-href=>$href,-target=>'_blank'},$title),' '.$href.' '.$msg)}
	  
 if (defined $show_code and $show_code eq 'checked')
{#print '<pre>show code checked</pre>';
print encode_entities($report,'<&>\x{100}-\x{ffff}')}
else
{print encode_entities($report,'\x{100}-\x{ffff}')}
#print $page->br();

}

#guard against injection attack!  If HTML markup brackets or the word 'eval' is present and surrounded by characters that would allow the perl interpreter to execute it, reject it!
sub isInjectionAttack
{
    my $param = $_[0];
#Note: \b matches hyphens but does not match underscores.
    $param =~ s/-eval-/_eval_/g;
    $param =~ s/^eval-/eval_/;
    $param =~ s/-eval$/_eval/;
    if($param =~ /[<>]|\beval\b/){return 1}
    if($param =~ m%\.\.|\||`%){return 1}
    return 0;
}
