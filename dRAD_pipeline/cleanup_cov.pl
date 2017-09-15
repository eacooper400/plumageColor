#!/usr/bin/perl -w
#
# cleanup_cov.pl
#
# Clean up the merged coverage file for all populations
#
# September 25, 2013
# By: Liz Cooper

use strict;

# Get the input and output file from the command line
my ($USAGE) = "\n$0 <input.pileup> <output.clean>
\tinput.pileup = The merged coverage file from run_covMerge.pl
\toutput.clean = The name of the final coverage file to create\n\n";

unless (@ARGV) {
  print $USAGE;
  exit;
}
my ($input, $output) = @ARGV;

open (IN, $input) || die "\nUnable to open the file $input!\n";
open (OUT, ">$output") || die "\nUnable to open the file $output!\n";

while (<IN>) {
  chomp $_;
  my @pops = split(/\t/, $_);
  my @temp = split(/,/, $pops[0]);
  my $posID = $temp[0];

  print OUT $posID, "\t";
  my $new_string = '';
  
  foreach my $pop (@pops) {
    $pop =~ s/^$posID,//;
    $new_string .= $pop . "\t";
  }

  chop $new_string;
  print OUT $new_string, "\n";
}
close(IN);
close(OUT);
exit;
