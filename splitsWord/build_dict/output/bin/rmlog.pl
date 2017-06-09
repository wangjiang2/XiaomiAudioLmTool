#!/usr/bin/perl

use strict;

my $input = $ARGV[0];
open(fp,$input);
while(my $line = <fp>)
{
    chomp($line);
    if($line =~ /^#change/)
    {
        next;
    }
    print $line."\n";
}
close($input);
