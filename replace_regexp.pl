if (@ARGV < 3)
{
    print "Usage: $0 [files] [searchexp] [replaceexp]\n
forward slashes do not need to be escaped in searchexp or replaceexp\n
but both need to be quoted if they contain colons";
    exit;
}
$s = $ARGV[1];
$r = $ARGV[2];
# $m = $ARGV[3];
foreach $f (glob $ARGV[0])
{
    if (! open (INPUT, $f))
	{warn "can't open $f: $!"; next}
    open (TEMP, "+>temp.txt");
    while (<INPUT>)
    {
	my $line = $_;
	$line =~ s/$s/$r/;
	print TEMP $line;
    }
    close INPUT;
    close TEMP;
    system ("move temp.txt $f");
}
    
    
