#!/usr/bin/perl
my $total = $#ARGV + 1;
my $counter = 1;
my $scriptname = $0;

print "Total args passed to $scriptname : $total\n";

foreach my $a(@ARGV) {
	print "Arg # $counter : $a\n";
	$counter++;
}