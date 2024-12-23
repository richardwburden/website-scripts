if (@ARGV < 2)
{
    print "Usage: $0 [title] [files] [stream_prefix]\n";
    exit;
}
$title = $ARGV[0];
$sp = "";
if (@ARGV > 2)
{
    $sp = $ARGV[2];
}
print <<EOF;
<!DOCTYPE html>
<html lang="en"><head>
		<meta content="width=device-width" name="viewport">
		<meta content="text/html; charset=utf-8" http-equiv="Content-Type">
		<link href="../../css/r-page-no-sidebar1.css" rel="stylesheet" type="text/css">
		<link href="../../css/r-page-extra-20240104.css" rel="stylesheet" type="text/css">
		<link href="../../css/r-page-extra-r1.css" rel="stylesheet" type="text/css">
		<link href="../../css/r-page-extra-r2.css" rel="stylesheet" type="text/css">
		<link href="../../css/r-page-extra-r3.css" rel="stylesheet" type="text/css">
		<link href="../../css/r-l_r_image_boxes.css" rel="stylesheet" type="text/css">
                <style>
					.table {font-size:80%; margin:0 auto}
                .row { }
					.title_cell {text-align:left; border:1px solid black;padding:5px 2px}
                .stream_cell, .download_cell {text-align:center; border:1px solid black;padding:5px 2px}
                </style>
                <title>$title</title>
	</head>
	<body><div id="convertedPage">
		<div id="container">
			<div id="header"><a href="/" title="Go to home page"></a></div>
			<div id="home_icon"><a href="/"><img alt="Go to home page" src="../../graphics/display/home.gif" title="Go to home page"></a></div>
			<div id="adbar"><a href="https://store.larouchepub.com/EIR-Subscribe-p/eiwos-0-0-0.htm">SUBSCRIBE TO EIR</a></div>
			<div id="print_header"><img alt="EIR banner" src="../../eir3.gif"></div>
			<div id="content">

				<div id="article_column">
<h2 style="text-align:center">$title</h2>
					<table class="table">
EOF

foreach $f (glob $ARGV[1])
{
    my $b = substr($f, 0, -4);
    $b =~ s/_/ /g;
    print '<tr class="row"><td class="title_cell">'.$b.'</td><td class="stream_cell"><a href="'.$sp.$f.'">Stream</a></td><td class="download_cell"><a href="';
    if (! open (INPUT, $f))
	{warn "can't open $f: $!"; next}
    while (<INPUT>)
    {
	if ($_ =~ m/href *= *"(.*?)"/i)
	{
	    print  $1;
	    last;
	}
    }
    close INPUT;
    print '">Download</a></td></tr>'."\n";
}
print <<EOG;
			</table>
				 
					<p><a href="#container"><img alt="Back to top" class="noprint" src="../../graphics/display/back_to_top.gif" title="Back to top"></a>&nbsp;&nbsp;&nbsp;&nbsp;<a href="/"><img alt="Go to home page" class="noprint" src="../../graphics/display/home.gif" title="Go to home page"></a></p><img alt="clear" class="clear" src="../../graphics/display/r-1x16000-clear.gif"></div><img alt="clear" class="clear" src="../../graphics/display/r-1x16000-clear.gif"></div><img alt="clear" class="clear" src="../../graphics/display/r-1x16000-clear.gif"></div></div>
	

</body></html>
EOG
