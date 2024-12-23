$buffer = "";
open (INPUT, $ARGV[0]) || die "can't open $ARGV[0] for reading: $!";
open (OUTPUT, "+>$ARGV[1]") || die "can't open or create $ARGV[1] for writing: $!";
$result = read (INPUT, $buffer, 1024);
if (defined($result) and $result > 0)
{
$buffer =~ s%\s+xmlns="http://www.pbcore.org/PBCore/PBCoreNamespace.html"\s+% %;
print OUTPUT $buffer;

$result = read (INPUT, $buffer, 1024);
while (defined($result) and $result > 0)
{
	print OUTPUT $buffer;
	$result = read (STDIN, $buffer, 1024);
}
close INPUT;
close OUTPUT;
exit(0);
}
else
{close INPUT;
 close OUTPUT;
 exit(1);}
