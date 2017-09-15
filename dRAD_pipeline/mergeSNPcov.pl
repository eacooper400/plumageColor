#!/usr/bin/perl -w
#
# mergeSNPcov.pl
#
# merge SNP file and coverage file information
# Replace Xs in SNP file with Ref base in appropriate positions
# Remove SNPs with fewer than 3 individuals present
#
# September 25, 2013
# Liz Cooper

use strict;

# Get the SNP file, the coverage file, and the output file as command line arguments
# Get the number of individuals as an input argument
my ($USAGE) = "\n$0 <input.genotypes> <input.cov> <output.snps> <num_individuals>
\tinput.genotypes = The sorted genotypes file from filterSNPs.pl
\tinput.cov = The merged and sorted coverage file from cleanup_cov.pl
\toutput.snps = The name of the final output file with SNPs for all individuals
\tnum_individuals = The total number of individuals that will be in the output\n\n";

unless (@ARGV) {
  print $USAGE;
  exit;
}
my ($snpfile, $covfile, $outfile, $num_indivs) = @ARGV;

open (SNP, $snpfile) || die "\nUnable to open the file $snpfile!\n";
open (COV, $covfile) || die "\nUnable to open the file $covfile!\n";
open (OUT, ">$outfile") || die "\nUnable to open the file $outfile!\n";

while (<SNP>) {
  chomp $_;
  my ($posID, $ref, $alt, $genstring) = split(/\s{1,}/, $_);
  #print $posID, "\n";
  my @gens = split(/,/, $genstring);
  if ((scalar @gens) != $num_indivs) {
    next;
  } else {
    my $flag = 1;
    my $line = '';
  LOOP: while ($flag) {
      unless (eof(COV)) {
	$line = <COV>;
	chomp $line;
	my @temp = split (/\s{1,}/, $line);
	if ($temp[0] eq $posID) {
	  $flag = 0;
	  last LOOP;
	} else {
	  $flag++;
	}
      }
    } 
    
    my @cov_line = split(/\s{1,}/, $line);
    my @pops = @cov_line[1..(scalar @cov_line - 1)];
    my @lengths = ();
    foreach my $p (@pops) {
     my @temp_p = split(/,/,$p);
     push (@lengths, (scalar @temp_p));
   }  
    my $long_string = join(",", @pops);
    my @covs = split(/,/, $long_string);
        
    for (my $i = 0; $i < scalar @gens; $i++) {
      my $g = $gens[$i];
      if ($g =~ /X/) {
	my $cov = $covs[$i];
	if ($cov > 0) {
	  if (length $ref > 1) {
	    $gens[$i] = '0';
	  } else {
	    $gens[$i] = $ref;
	  }
	} else {
	  $gens[$i] = 'N';
	}
      }
    }

    my $new_string = join('', @gens);
    #print $posID, "\t", $new_string, "\n";
    my $temp_string = $new_string;
    $temp_string =~ s/N//g;
    
    if (length $temp_string < 5) {
      next;
    } else {
      my @new_pops = ();
      my $prev = 0;
      foreach my $len (@lengths) {
	my $new_pop = substr($new_string, $prev, $len);
	push (@new_pops, $new_pop);
	$prev += $len;
      }
      my $new_out_line = join("\t", @new_pops);
      print OUT $posID, "\t", $ref, "\t", $alt, "\t", $new_out_line, "\n";
    }
  }
}
close(SNP);
close(COV);
close(OUT);
exit;
    
