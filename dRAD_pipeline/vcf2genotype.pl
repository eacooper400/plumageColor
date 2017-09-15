#!/usr/bin/perl -w
#
# vcf2genotype.pl
#
# Process Individual vcf files into Genotype files
# Edit the Chromosome Name to match the coverage file
# Print a Genotype String for each Individual
#
# September 24, 2013
# Liz Cooper

############################################################
# RUN THIS SCRIPT IN THE DIRECTORY WITH THE VCF FILES!!!!
############################################################

use strict;

my @files = glob("*.vcf");

foreach my $file (@files) {
  my $prefix = ((split(/\./, $file))[0]);
  my $new = $prefix . "." . "gens";

  open (OUT, ">$new") || die "\nUnable to open the file $new!\n";

  open (VCF, $file) || die "\nUnable to open the file $file!\n";
  while (<VCF>) {
    chomp $_;
    
    if ($_ =~ /^\#/) {
      next;
    }

    my ($chrom, $pos, $id, $ref, $alt, $qual, $filter, $info, $format, $string) = split(/\s{1,}/, $_);
    
    # First Edit the chromosome name to have only the stacks tag# , followed by .pos
    $chrom =~ s/\|\*\|[0-9]{1,}//;
    $chrom .= "." . $pos;

    # Get the Genotype String based on the DP4 field
    # Change Indel Genotypes to 0 and 1
    my @info_fields = split(/\;/, $info);
    my $dp4;
    my @bases = ();
    my $num_ref = 0;
    my $num_alt = 0;
    my $gen_string = '';
    
    # Figure out which field has the read depths
    foreach my $if (@info_fields) {
        if ($if =~ /^DP4/){
            $dp4 = $if;
        }
    }

    if ($info =~ /^INDEL/) {
        #$dp4 = $info_fields[4];
      $dp4 =~ s/^DP4\=//;
      @bases = split(/,/, $dp4);
      $num_ref = $bases[0] + $bases[1];
      $num_alt = $bases[2] + $bases[3];
      $gen_string = '0' x $num_ref;
      $gen_string .= '1' x $num_alt;
    } else {
        #$dp4 = $info_fields[3];
      $dp4 =~ s/^DP4\=//;
      @bases = split(/,/, $dp4);
      $num_ref = $bases[0] + $bases[1];
      $num_alt = $bases[2] + $bases[3];
    
      $gen_string = $ref x $num_ref;
      $gen_string .= $alt x $num_alt;
    }

    print OUT $chrom, "\t", $ref, "\t", $alt, "\t", $gen_string, "\n";
  }
  close(VCF);
  close(OUT);
}
exit;

    
