#!/usr/bin/perl -w
#
# fixFasta.pl
#
# Fix fasta files so that each sequence is on one line
#
# September 12, 2013
#
# RUN THIS SCRIPT IN THE DIRECTORY WITH THE FILES!!!!!
# By Liz Cooper

use strict;

# Get the input files from the current directory
my @files = glob("*filtered.cap.singlets");

# For each file, fix the reads and output to a new file
foreach my $file (@files) {
  my @name = split(/\./, $file);
  my $prefix = $name[0];
  $prefix =~ s/filtered/fixed/;
  my $output = $prefix . "." . "fasta";
  open (OUT, ">$output") || die "\nUnable to open the file $output!\n";
  open (IN, $file) || die "\nUnable to open the file $file!\n";
  
  my $sequence = '';

  # Start reading through the input file
  while (<IN>) {
    chomp $_;
    if ($_ =~ /^>/) {
      unless ((length($sequence)) == 0) {
	print OUT $sequence, "\n";
      }
      print OUT $_, "\n";
      $sequence = '';      
    } else {
      $sequence .= $_;
    }
  }
  print OUT $sequence, "\n";
  close(IN);
  close(OUT);
}
exit;
