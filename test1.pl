use HTML::Element;
my $obj = 'hello';

my $robj = \$obj;

print '$robj: '.ref($robj);

my $elem = HTML::Element->new('a');

print '$elem: '.ref($elem);
