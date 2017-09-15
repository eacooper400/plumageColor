#!/usr/bin/perl -w
#
# filter_by_depth.pl
#
# Filter out reads below or above a specified depth
#
# September 11, 2013
# By: Liz Cooper

use strict;

# Take as input the fasta file name, the min. depth and the max depth
my ($USAGE) = "\n$0 <input.fasta> <min.depth> <max.depth> <output.fasta>
\tinput.fasta = The input fasta file (created by get_stacks_depth.pl)
\tmin.depth = The minimum depth to retain a tag sequence
\tmax.depth = The maximum depth to retain a tag sequence
\toutput.fasta = The name of an output file for the filtered tags\n\n";
unless (@ARGV) {
  print $USAGE;
  exit;
}
my ($input, $min, $max, $output) = @ARGV;

# Open the input and output files
open (IN, $input) || die "\nUnable to open the file $input!\n";
open (OUT, ">$output") || die "\nUnable to open the file $output!\n";

# Create a flag to mark sequences to save outside of the file loop
my $flag = 0;

# Start reading through the input file
while (<IN>) {
  chomp $_;
  if ($_ =~ /^>/) {
    my @info = split(":", $_);
    my $depth = pop @info;
    if (($depth >= $min) && ($depth <= $max)) {
      print OUT $_, "\n";
      $flag = 1;
    }
  } elsif ($flag == 1) {
    print OUT $_, "\n";
    $flag = 0;
  } else {
    $flag = 0;
  }
}
close(IN);
close(OUT);
exit;

    
