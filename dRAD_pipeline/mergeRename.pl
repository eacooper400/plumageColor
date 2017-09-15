#!/usr/bin/perl -w
#
# mergeRename.pl
#
# Merge Stacks fastq files from the 5bp and 4bp iterations of the de-multiplexing process
# Rename files to the sample name instead of the barcode
#
# February 22, 2013
# Written by: Liz Cooper

use strict;

# Take as input the 5bp pools file and run the program in the directory with all of the fastq files
# Also create an option for paired or single end reads
my ($USAGE) = "$0 <input.pools> <PE or SE>\n \tinput.pools = A text file with lines in the format 'Barcode   Sample', with one line per barcode.\n\tPE or SE specifies whether reads are Single End or Paired End runs\n\tRun in the Directory with the fastq files!!\n\n";
unless (@ARGV) {
  print $USAGE;
  exit;
}
my ($poolsfile, $runtype) = @ARGV;

# First, read the pools file into a hash keyed by barcode
my %pools = ();
open (POOLS, $poolsfile) || die "\nUnable to open the file $poolsfile!\n";
while (<POOLS>) {
  chomp $_;
  my ($name, $barcode) = split(/\s{1,}/, $_);
  $pools{$barcode} = $name;
}
close(POOLS);

# Get the sample files for each barcode and rename them accordingly
my @barcodes = keys %pools;

foreach my $barcode (@barcodes) {
  my $alt = substr($barcode, 1, 4);
  my $name = $pools{$barcode};
  if ($runtype =~ /S/i) {
     my $out = $name . '.fq';
     my $in = 'sample_' . $barcode . '.fq';
     my $alt = 'sample_' . $alt . '.fq';
     `cat $in $alt >$out`;
   } elsif ($runtype =~ /P/i) {
     my $out1 = $name . '.fq_1';
     my $out2 = $name . '.fq_2';
       #my $in1 = 'sample_'. $barcode . '.fq_1';
       my $in1 = 'sample_'. $barcode . '.1' . '.fq';
       #my $in2 = 'sample_'. $barcode . '.fq_2';
       my $in2 = 'sample_'. $barcode . '.2' . '.fq';
       #my $alt1 = 'sample_'. $alt . '.fq_1';
       my $alt1 = 'sample_'. $alt . '.1' . '.fq';
       #my $alt2 = 'sample_'. $alt . '.fq_2';
       my $alt2 = 'sample_'. $alt . '.2' . '.fq';
     `cat $in1 $alt1 >$out1`;
     `cat $in2 $alt2 >$out2`;
   } else {
     print "ERROR: INVALID RUN TYPE! MUST BE PE OR SE!\n";
   } 
}
exit;
