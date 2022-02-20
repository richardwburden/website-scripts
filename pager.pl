open (INPUT, $ARGV[0]) || die "can't open $ARGV[0] for reading: $!";

while (read (INPUT, $file, 10000))
{
    print $file;
    print "\nHit any key to continue";
    readline (STDIN);
}

