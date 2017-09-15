#!/usr/bin/perl -w
#
# trimFastq.pl
#
# Trim fastq files to an set # of base pairs before alignment
#
# July 22, 2011
# Written by: Liz Cooper

use strict;
use Data::Dumper;

# Get the names of the input file, output file, and trim length
my ($USAGE) = "$0 infile.fastq outfile.fastq length\n\tinfile.fastq = The input fastq file\n\toutfile.fastq = The name of a fastq file for the trimmed output\n\tlength = The length to trim all reads to\n";
unless (@ARGV) {
  print $USAGE;
  exit;
}
my ($infile, $outfile, $len) = @ARGV;

# Open the output file for printing
open (OUT, ">$outfile") || die "\nUnable to open the file $outfile!\n";

# Open and process the input file
open (IN, $infile) || die "\nUnable to open the file $infile!\n";

# Find and save the machine name to look for in the other header lines
my $machine = '';

while (<IN>) {
  chomp $_;
  my $check = $.;
  if ($check == 1) {
    my @temp = split(/\:/, $_);
    $machine = $temp[0];
    $machine =~ s/\@//;
  }
  
  # Skip lines with the sequence name
  if (($_ =~ /^\@$machine/) || ($_ =~ /^\+$machine/) || ($_ =~ /^\+$/)) {
    print OUT $_, "\n";
  } else {
    # Trim the read to the desired length
    #my @info = split('', $_);
    #my @new = @info[0..$len-1];
    #my $string = join('', @new);
    my $string = substr($_, 0, $len);
    print OUT $string, "\n";
  }
}
close(IN);
close(OUT);
exit;

  
