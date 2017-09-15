#!/usr/bin/perl -w
#
# vcf2snps.pl
#
# Convert the vcf format to the snps format
#
# September 17, 2015
# Liz Cooper

use strict;

# From the command line, get the name of the vcf file, the name of an output file, and a file with
# population info.
my ($USAGE) = "\n$0 <input.vcf> <output.snps> <populations.txt>
\t\tinput.vcf = The name of the input VCF file (must be unzipped!)
\t\toutput.snps = The name of the output file to create
\t\tpopulations.txt = A tab-delimited text file with Population Info for each Sample:\n
\t\tThere should be one line per sample, with a numeric population code in column 1
\t\tand the sample name (must match the VCF column names!) in column 2.\n\n";

unless (@ARGV) {
  print $USAGE;
  exit;
}
my ($input, $output, $popInfo) = @ARGV;

my %hets = (
	    'AC' => 'M',
	    'AG' => 'R',
	    'AT' => 'W',
	    'CA' => 'M',
	    'CG' => 'S',
	    'CT' => 'Y',
	    'GA' => 'R',
	    'GC' => 'S',
	    'GT' => 'K',
	    'TA' => 'W',
	    'TC' => 'Y',
	    'TG' => 'K');

# Read in all of the population info.
my %pops = ();
open (POPS, $popInfo) || die "\nUnable to open the file $popInfo!\n";
while (<POPS>) {
  chomp $_;
  my @info = split(/\t/, $_);
  if (exists $pops{$info[0]}) {
    push(@{$pops{$info[0]}}, $info[1]);
  } else {
    @{$pops{$info[0]}} = ($info[1]);
  }
}
close(POPS);
my @popCodes = sort {$a <=> $b} (keys %pops);

# Open the output file for printing
open (OUT, ">$output") || die "\nUnable to open the file $output!\n";

# Open the input file and start reading through it
# Save sample names from the header
my @samples = ();
my @sample_order = ();
open (IN, $input) || die "\nUnable to open the file $input!\n";

while (<IN>) {
  if ($_ =~ /^\#\#/) {
    next;
  } elsif ($_ =~ /^\#CHROM/) {
    $_ =~ s/^\#//ig;
    my @header_fields = split(/\s{1,}/, $_);
    @samples=@header_fields[9..(scalar @header_fields - 1)];
  } else {
    my @info = split(/\s{1,}/, $_);
    if ((length $info[3] > 1) || (length $info[4] > 1)){
      next;
    }
    my $loc = $info[0] . "." . $info[1];
    print OUT $loc, "\t", $info[3], "\t", $info[4];
    my @individuals = @info[9..(scalar @info - 1)];
    my @codes = ();
    foreach my $i (@individuals) {
      my $gt = (split(/\:/, $i))[0];
      if ($gt =~ /0\/0/) {
	push(@codes, $info[3]);
      } elsif ($gt =~ /1\/1/) {
	push (@codes, $info[4]);
      } elsif (($gt =~ /0\/1/) || ($gt =~ /1\/0/)) {
	my $tmp = $info[3] . $info[4];
	my $code = $hets{$tmp};
	push (@codes, $code);
      } else {
	push (@codes, "N");
      }
    }
    foreach my $p (@popCodes) {
      print OUT "\t";
      my @inds = @{$pops{$p}};
      foreach my $i (@inds) {
	for (my $s=0; $s < scalar @samples; $s++) {
	  if ($i =~ /^$samples[$s]$/) {
	    print OUT $codes[$s];
	    unless ((scalar @sample_order) == (scalar @samples)) {
	      push (@sample_order, $samples[$s]);
	    }
	  }
	}
      }
    }
    print OUT "\n";      
  }
}
close(IN);
close(OUT);
print "The Sample Order in the .snps File is:\n";
foreach my $s (@sample_order) {
  print $s, "\n";
}

exit;
