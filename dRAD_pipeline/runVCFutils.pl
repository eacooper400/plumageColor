#!/usr/bin/perl -w
#
# runVCFutils.pl
#
# Run the BCFtools and VCFutils to call SNPs in each individual in a directory
#
# September 23, 2013
# By: Liz Cooper

use strict;

# Get the name of the BAM file directory from the input line
# Get the name of the reference fasta file from the input
my ($USAGE) = "\n$0 <BAM_Directory> <reference.fasta>
\tBAM_Directory = The folder with all individual BAM files
\treference.fasta = The reference sequence fasta file\n
NOTE: Check the path to SamTools on Lines 37-38!\n\n";

unless (@ARGV) {
  print $USAGE;
  exit;
}

my ($dir, $reffasta) = @ARGV;

# Get all of the BAM files from that directory
my @files = glob("$dir*.bam");

# Run bcftools view and vcfutils varFilter on every file
foreach my $file (@files) {
  my @info1 = split(/\//, $file);
  my $bamfile = pop @info1;
  my $bcffile = $bamfile;
  $bcffile =~ s/sort*\.bam/raw\.bcf/;
  my $vcffile = $bamfile;
  $vcffile =~ s/\.sort*\.bam/\.vcf/;

   `samtools mpileup -uD -f $reffasta $file | ~/samtools-0.1.19/bcftools/bcftools view -bvcg - >$bcffile`;
  `~/samtools-0.1.19/bcftools/bcftools view $bcffile | ~/samtools-0.1.19/bcftools/vcfutils.pl varFilter -Q 20 -D50 -a 1 >$vcffile`;
}
exit;
  
