$buffer = "";
$result = read (STDIN, $buffer, 1024);
if (defined($result) and $result > 0)
{
$buffer =~ s%\s+xmlns="http://www.pbcore.org/PBCore/PBCoreNamespace.html"\s+% %;
print $buffer;

$result = read (STDIN, $buffer, 1024);
while (defined($result) and $result > 0)
{
	print $buffer;
	$result = read (STDIN, $buffer, 1024);
}
exit(0);
}
else
{exit(1);}
