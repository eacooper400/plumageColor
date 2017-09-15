#!/usr/bin/perl -w
#
# filterSNPs.pl
#
# Filter the merged SNP list from all individuals
# Remove sites with more than 2 alleles
# Remove sites with less than 5% MAF
# Create a Single Genotype code for each individual
# Heterozygotes must have at least 5 sequences present, and 20% must have the second allele to be called
#
# September 24, 2013
# Liz Cooper

use strict;

# Get the name of the snplist file and the output file from the command line
my ($USAGE) = "\n$0 <input.snplist> <output.genotypes>
\tinput.snplist = The list of SNP sites created by getSNPpositions.pl
\toutput.genotypes = The genotypes for each individual at all positions in the snplist.\n
\t This script does the following filtering steps:
\t\tRemoves sites with more than 2 alleles (Line 54)
\t\tRemoves sites with less than 5% MAF (Line 68)
\t\tRequires heterozygotes to have at least 5 sequences present, 
\t\tand 20% of sequences must have the second allele (Lines 106-115)\n\n";

unless (@ARGV) {
  print $USAGE;
  exit;
}
my ($input, $output) = @ARGV;

open (IN, $input) || die "\nUnable to open the file $input!\n";
open (OUT, ">$output") || die "\nUnable to open the file $output!\n";

# Read through the infile one line at a time
while (<IN>) {
  chomp $_;
  my ($chr, $ref, $alt, $list) = split(/\s{1,}/, $_);

  # Count the number of alleles at each site
  # Skip sites with more than 2
  my %alleles = ();
  for (my $p = 0; $p < (length($list)); $p++) {
    my $b = substr($list, $p, 1);
    unless (($b =~ /,/) || ($b =~ /X/)) {
      if (exists $alleles{$b}) {
	$alleles{$b}++;
      } else {
	$alleles{$b} += 1;
      }
    }
  }
  my @alleles = keys %alleles;
  if (((scalar @alleles) > 2) || ((scalar @alleles) < 2)) {
    next;
  } else { 

    # Skip sites with MAF < 5%
    my @a_counts = values %alleles;
    my $total = $a_counts[0] + $a_counts[1];
    my %afs = ();
    foreach my $a (@alleles) {
      my $ct = $alleles{$a};
      my $freq = $ct/$total;
      $afs{$a} = $freq;
    }
    my @freqs = values %afs;
    if (($freqs[0] < 0.05) || ($freqs[1] < 0.05)) {
      next;
    } else {
  
      # Find the major allele and the minor allele based on the frequency
      my $minAllele = '';
      my $majAllele = '';
      if ($afs{$alleles[0]} < $afs{$alleles[1]}) {
	$minAllele = $alleles[0];
	$majAllele = $alleles[1];
      } else {
	$minAllele = $alleles[1];
	$majAllele = $alleles[0];
      }
      
      # Create a single letter genotype for each individual
      # For a het call, make sure that at least 5 sequences are present, and at least 20% have the second allele
      # Otherwise, the site is homozygous for the majority alleles (or N)
      my $new_string = '';
      my @indivs = split(/,/, $list);
  
      foreach my $ind (@indivs) {
	if ($ind =~ /X/) {
	  $new_string .= 'X' . ",";
	} else {
	  my $c1 = 0;
	  my $c2 = 0;
	  while ($ind =~ /$majAllele/ig) {
	    $c1++;
	  }
	  while ($ind =~ /$minAllele/ig) {
	    $c2++;
	  }
	  if ($c2 == 0) {
	    $new_string .= $majAllele . ",";
	  } elsif ($c1 == 0) {
	    $new_string .= $minAllele . ",";
	  } else {
	    
	    ## CHANGE THIS LOOP TO RAISE MINIMUM COVERAGE FOR CALLING A SNP (CURRENT SETTING 5X)
	    if (($c1 + $c2) < 5) {
	      ### CHANGE SCRIPT HERE TO REPLACE LOW COVERAGE WITH EITHER MAJOR ALLELE OR N
	      #$new_string .= $majAllele . ",";
	      $new_string .= 'N' . ",";
	    ## CHANGE THIS LOOP TO RAISE/LOWER MINIMUM % OBSERVATIONS FOR CALLING A HET (CURRENTLY SET AT 20%)  
	    } elsif (($c2/($c1+$c2)) < 0.2) {
	      # CHANGE SCRIPT HERE TO REPLACE LOW FRACTION ALT SITES WITH N OR WITH MAJOR ALLELE
	      #$new_string .= $majAllele . ",";
	      $new_string .= 'N' . ",";

	    } else {
	      if (($minAllele =~ /A/) && ($majAllele =~ /C/)) {
		$new_string .= 'M' . ",";
	      } elsif (($minAllele =~ /A/) && ($majAllele =~ /G/)) {
		$new_string .= 'R' . ",";
	      } elsif (($minAllele =~ /A/) && ($majAllele =~ /T/)) {
		$new_string .= 'W' . ",";
	      } elsif (($minAllele =~ /C/) && ($majAllele =~ /A/)) {
		$new_string .= 'M' . ",";
	      } elsif (($minAllele =~ /C/) && ($majAllele =~ /G/)) {
		$new_string .= 'S' . ",";
	      } elsif (($minAllele =~ /C/) && ($majAllele =~ /T/)) {
		$new_string .= 'Y' . ",";
	      } elsif (($minAllele =~ /G/) && ($majAllele =~ /A/)) {
		$new_string .= 'R' . ",";
	      } elsif (($minAllele =~ /G/) && ($majAllele =~ /C/)) {
		$new_string .= 'S' . ",";
	      } elsif (($minAllele =~ /G/) && ($majAllele =~ /T/)) {
		$new_string .= 'K' . ",";
	      } elsif (($minAllele =~ /T/) && ($majAllele =~ /A/)) {
		$new_string .= 'W' . ",";
	      } elsif (($minAllele =~ /T/) && ($majAllele =~ /C/)) {
		$new_string .= 'Y' . ",";
	      } elsif (($minAllele =~ /T/) && ($majAllele =~ /G/)) {
		$new_string .= 'K' . ",";
	      }
	    }
	  }
	}
      }
      chop $new_string;
      # Check that the site is still a SNP
      my %new_alleles = ();
      for (my $p1 = 0; $p1 < (length($new_string)); $p1++) {
	my $b1 = substr($new_string, $p1, 1);
	unless (($b1 =~ /,/) || ($b1 =~ /X/) || ($b1 =~ /N/)) {
	  if (exists $new_alleles{$b1}) {
	    $new_alleles{$b1}++;
	  } else {
	    $new_alleles{$b1} += 1;
	  }
	}
      }
      unless (scalar (keys %new_alleles) < 2) {
	print OUT $chr, "\t", $ref, "\t", $alt, "\t", $new_string, "\n";
      }
    }
  }
}
close(IN);
close(OUT);
    
exit;
