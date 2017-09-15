#!/usr/bin/perl -w
#
# get_stacks_depth.pl
#
# Create a fasta file based on the consensus sequences in a Stacks.tags.tsv file
# Save the read depth for each Stack
# Count the number of stacks per individual
#
# September 11, 2013
#
# RUN IN THE DIRECTORY WITH THE TAGS FILES!!!!!

use strict;

# Get all of the names of the tags.tsv files in the directory
my @files = glob("*.tags.tsv");

# Save the distribution of read depths and tag number outside of the file loop
my %depths = ();
my $tags = 0;

# Process each file individually
foreach my $file (@files) {
  
  # Get the prefix from the file name and create an output file
  my @filename = split(/\./, $file);
  my $prefix = $filename[0];
  my $output = $prefix . "_stacks.fasta";
  
  # Open the input and output file
  open (IN, $file) || die "\nUnable to open the file $file!\n";
  open (OUT, ">$output") || die "\nUnable to open the file $output!\n";

  # Set the read depth to zero, initialize the sequence, then start processing the input file
  my $reads = 0;
  my $sequence = '';
  my $name = '';
  
  while (<IN>) {
    chomp $_;
    my @info = split(/\t/, $_);
        
    # Check if the sequence type is consensus
    if ($info[6] =~ /consensus/) {
      $sequence = $info[9];
      #print $sequence, "\n";
      unless ($reads == 0) {
	
	# Update the hash with the distribution of depths
	if (exists $depths{$reads}) {
	  $depths{$reads} += 1;
	} else {
	  $depths{$reads} = 1;
	}

	# Print the previous consensus sequence and reset the variables
	print OUT $name, $reads, "\n";
	print OUT $sequence, "\n";
	$tags++;
	$reads = 0;
	#$sequence = '';
	#$sequence = $info[8];
	$name = '';
	$name = ">" . "Sample:" . $info[1] . "_Stack:" . $info[2] . "_Depth:";
      } else {
	#$sequence = $info[8];
	$name = ">" . "Sample:" . $info[1] . "_Stack:" . $info[2] . "_Depth:";
      }
    } elsif ($info[6] =~ /model/) {
      next;
    } else {
      $reads++;
    }
  }
  if (exists $depths{$reads}) {
    $depths{$reads} += 1;
  } else {
    $depths{$reads} = 1;
  }
  print OUT $name, $reads, "\n";
  print OUT $sequence, "\n";
  close(IN);
  close(OUT);
  print $prefix, " ", $tags, "\n";
  $tags = 0;
}

# Print out the read depth distribution for the entire population
open (TMP, ">read.depths") || die "\nUnable to open the file read.depths!\n";
foreach my $key (keys %depths) {
  print TMP $key, " ", $depths{$key}, "\n";
}
close(TMP);
exit;
  
