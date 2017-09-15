#!/usr/bin/perl -w
#
# run_covMerge.pl
# 
# Run the covMerge script on all files in a directory
#
# September 24, 2013
# By Liz Cooper

use strict;

my ($USAGE) = "\n$0 <ref.cov> <pileup_dir>
\tref.cov = The reference pileup file created by makeRefpileup.pl
\tpileup.dir = The path to the folder where all individual pileup files are located\n
\tIMPORTANT: THIS SCRIPT IS A WRAPPER FOR covMerge.pl - CHECK THE PATH AT LINE 35 TO MAKE SURE IT IS CORRECT!!!\n\n";

unless (@ARGV) {
  print $USAGE;
  exit;
}
my ($reffile, $pileupdir) = @ARGV;
my $origfile = $reffile;

# Check the length of the starting reference file
my $line_count = `wc -l $reffile`;
$line_count =~ s/^\s{1,}//;
my $start_length = ((split(/\s{1,}/, $line_count))[0]);

my @pileup_files = glob("$pileupdir*.pileup");

foreach my $file (@pileup_files) {
  my @names = split(/\//, $file);
  my $newfile = pop @names;
  $newfile =~ s/pileup/cov/;
  
  `perl covMerge.pl $reffile $file $newfile`;
    
    # Unless the previous reference file is the Consensus.pileup file,
    # Check the new file length, and remove the old reference file
    unless($reffile =~ /$origfile/) {
        my $new_count = `wc -l $newfile`;
        chomp $new_count;
        #print $new_count, "\n";
        $new_count =~ s/^\s{1,}//;
        my $new_length = ((split(/\s{1,}/, $new_count))[0]);
        if ($new_length == $start_length) {
                `rm $reffile`;
        }
    }
  
  $reffile = $newfile;
}
exit;
