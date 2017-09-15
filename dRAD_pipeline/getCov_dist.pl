#!/usr/bin/perl -w
#
# getCov_dist.pl
#
# Get coverage distribution from a pileup/cov file
#
# July 22, 2016
# By: Liz Cooper

use strict;

my ($USAGE) = "\n$0 <input.cov> <output.txt>
\tinput.cov = A merged coverage/pileup file for all individuals
\toutput.txt = A counts file (histogram) for all coverage values, to assist in choosing the right cut-offs\n\n";

unless (@ARGV) {
  print $USAGE;
  exit;
}
my ($input, $output) = @ARGV;

open (IN, $input) || die "\nUnable to open the file $input!\n";
open (OUT, ">$output") || die "\nUnable to open the file $output!\n";

my %covs = ();

while (<IN>) {
  chomp $_;
  my @info = split(/\s{1,}/, $_);
  for (my $i = 1; $i < scalar @info; $i++) {
    my @vals = split(/,/, $info[$i]);
    foreach my $v (@vals) {
      if (exists $covs{$v}) {
	$covs{$v} += 1;
      } else {
	$covs{$v} = 1;
      }
    }
  }
}

close(IN);

my @cov_sort = sort {$a <=> $b} (keys %covs);
foreach my $c (@cov_sort) {
  print OUT $c, "\t", $covs{$c}, "\n";
}
close(OUT);
exit;
