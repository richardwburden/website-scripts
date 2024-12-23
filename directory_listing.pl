if (@ARGV < 1)
{
    print "Usage: $0 [files]\n";
    exit;
}

foreach $f (glob $ARGV[0])
{
    print '<div class="row"><div class="stream_cell"><a href="'.$f.'">Stream</a></div><div class="download_cell"><a href="';
    open (INPUT, $f) || {warn "can't open $f: $!"; next}
    while (<INPUT>)
    {
	if ($_ =~ m/href="(.*?)"/)
	{
	    print  $1;
	    last;
	}
    }
    close INPUT;
    print '">Download</a></div></div>'."\n";
}
    
    
