use HTML::TreeBuilder;
use HTML::Element;
use HTML::Entities;


%empty = (); #use as 3rd parameter for HTML::Element->as_HTML() to specify that the HTML generated shall close all open tags

my $tree = HTML::TreeBuilder->new;

open(my $fh, "<:utf8", $ARGV[0]) || die "can't open $ARGV[0]: $!";

$tree->parse_file($fh);

my @scripts = $tree->find_by_tag_name('script');

foreach $s (@scripts) {$s->delete}

print $tree->as_HTML("","\t",%empty);
