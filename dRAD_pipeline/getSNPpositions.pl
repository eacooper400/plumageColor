#!/usr/bin/perl -w
#
# getSNPpositions.pl
#
# Get a list of all possible SNP positions across populations
#
# September 23, 2013
# By: Liz Cooper

use strict;
use Data::Dumper;

# Take as input the list of directories with VCF files
# Take as input the name of an output file
# Take as input the total number of individuals
my ($USAGE) = "\n$0 <output.list> <num_individuals> <VCF_DIR_1...VCF_DIR5>
\toutput.list = The name of a file that will have all SNP positions from the combined set of files
\tnum_individuals = The total number of individual samples in the VCF files
\tVCF_DIR_1...VCF_DIR5 = The list of folders (each separated by a space) with VCF files to be merged\n  
\tTypically, each folder has all individual VCF files for a single population,
\tand different folders are different populations 
\t(Note: in the final .snps file, these population groupings will be maintained)\n\n";

unless (@ARGV) {
  print $USAGE;
  exit;
}
my $output = $ARGV[0];
my $num_indiv = $ARGV[1];
my @vcf_dirs = @ARGV[2..(scalar @ARGV -1)];

# Open a file for output
open (LIST, ">$output") || die "\nUnable to open the file $output\n";

# Create a hash of all the SNP sites as well as a hash of all the reference bases and alt alleles
my %sites = ();
my %refs = ();
my %alts = ();
my $count = 0;
my $string = 'X' x $num_indiv;
my @blank = split('', $string);

# Start going through all of the SNP files
foreach my $dir (@vcf_dirs) {
  my @files = glob("$dir*.gens");
  foreach my $file (@files) {
    open (VCF, $file) || die "\nUnable to open the file $file!\n";
   
  FILELOOP: while (<VCF>) {
      chomp $_;
      my @info = split(/\s{1,}/, $_);
      my $chr = $info[0];
      $chr =~ s/scaffold//ig;
      $chr =~ s/C//ig;

      # Check if the site is already in the hash
      if (exists $sites{$chr}) {
	# Add values to the sites hash
	my @existing = @{$sites{$chr}};
	$existing[$count] = $info[3];
	@{$sites{$chr}} = @existing;
	
	# Check if the alt allele is the same, and throw the site out if it is not
	my $check = $alts{$chr};
	   
	unless ($check =~ /$info[2]/) {
	  next FILELOOP;
	}
	  
      }
      # If not, then initialize the array and add the value
      # Create an entry in the ref base hash as well
      else {
	@{$sites{$chr}} = @blank;
	my @temp = @blank;
	$temp[$count] = $info[3];
	@{$sites{$chr}} = @temp;
	$refs{$chr} = $info[1];
	$alts{$chr} = $info[2];
      }
    }
    close(VCF);
    $count++;
  }
  #print Dumper (\%sites);
}

my @keys = keys %sites;
my @sorted = sort {$a <=> $b} @keys;

foreach my $key (@sorted) {
  my @genotypes = @{$sites{$key}};
  my $gen_string = join(",", @genotypes);
  my $ref = $refs{$key};
  my $alt = $alts{$key};
  print LIST $key, "\t", $ref, "\t", $alt, "\t", $gen_string, "\n";
}
close(LIST);
exit;
