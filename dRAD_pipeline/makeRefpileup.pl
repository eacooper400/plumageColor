#!/usr/bin/perl -w
#
# makeRefpileup.pl
#
# Use the reference fasta file to make a coverage starter file
#
# July 22, 2010
# By: Liz Cooper

use strict;

# Take the names of the input and output files as arguments
my ($USAGE) = "\n$0 input output
\tinput = A reference sequence file in fasta format
\toutput = The name for a pileup format file with coverage info. for every position in the reference\n\n";

unless (@ARGV) {
  print $USAGE;
  exit;
}
my ($input, $output) = @ARGV;
 
# Open an output file
open (OUT, ">$output") || die "\nUnable to open the file $output!\n";

# Initialize the scaffold and position values
my $scaffold = 0;
my $position = 0;

# Save the number of Ns and the number of Xs separately
my $numN = 0;
my $numX = 0;

# Open the reference file and start reading through it
open (IN, $input) || die "\nUnable to open the file $input!\n";
while (<IN>) {
  chomp $_;
  
  # Ignore blank lines
  if ($_ =~ /^\s*$/) {
    next;
  }

  # Check if the line marks the start of a new scaffold
  elsif ($_ =~ /^>/) {
    my @s = split(/\s/, $_);
    $scaffold = $s[0];
    $scaffold =~ s/\|\*\|[0-9]{1,}//;
    $scaffold =~ s/>//;
    $position = 0;
  }
  
  # Otherwise, print the info. for each base, unless it is an X or an N
  else {
    my $l = length($_);
    for (my $p = 0; $p < $l; $p++) {
      $position++;
      my $base = substr($_, $p, 1);
      if ($base =~ /[Nn]/) {
	$numN++;
      } elsif ($base =~ /[Xx]/) {
	$numX++;
      }
      print OUT $scaffold, ".", $position, "\n";
    }
  }
}
close(IN);
close(OUT);

print $numN, "\t", $numX, "\n";

exit; 

