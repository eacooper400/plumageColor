#!/usr/bin/perl -w
#
# covMerge.pl
#
# Manually merge the coverage info. from the pileup files
#
# August 3, 2010
# Written by: Liz Cooper

use strict;

# Take as input the starting coverage file, 
# the sample pileup file,
# and the output file name
my ($USAGE) = "\n$0 start_cov_file sample_pileup outfile
\tstart_cov_file = The coverage/pileup file to add information to
\tsample_pileup = The file with new information to merge into cov_file
\toutfile = The name of the new pileup output file with merged info.\n\n";

unless (@ARGV) {
  print $USAGE;
  exit;
}
my ($startfile, $sampfile, $outfile) = @ARGV;

# Open all 3 files
open (START, $startfile) || die "\nUnable to open the file $startfile!\n";
open (SAMP, $sampfile) || die "\nUnable to open the file $sampfile!\n";
open (OUT, ">$outfile") || die "\nUnable to open the file $outfile!\n";

# Get the first line of the sample file
my $line2 = <SAMP>;
chomp $line2;
my ($s2, $p2, $cov) = process_samp($line2);
my $flag = 0;

# Start reading through the start file
SLOOP:while (<START>) {
  my $line1 = $_;
  chomp $line1;
  my ($s1, $p1) = process_start($line1);

  unless ($flag == 0) {
    print OUT $line1, ",", "0", "\n";
    next SLOOP;
  }

  # Compare the positions
  if ($s1 ne $s2) {
    print OUT $line1, ",", "0", "\n";
    next SLOOP;
  } else {
    if ($p1 < $p2) {
      print OUT $line1, ",", "0", "\n";
      next SLOOP;
    } elsif ($p1 == $p2) {
      print OUT $line1, ",", $cov, "\n";
      if (eof SAMP) {
	$flag = 1;
	next SLOOP;
      } else {
	$line2 = <SAMP>;
	chomp $line2;
	($s2, $p2, $cov) = process_samp($line2);
	next SLOOP;
      }
    } elsif ($p1 > $p2) {
      my $check = 0;
      do {
	$line2 = <SAMP>;
	chomp $line2;
	($s2, $p2, $cov) = process_samp($line2);
	$check = compare_lines($s1,$s2,$p1,$p2);
      } until ($check > 0);
      if ($check == 1) {
	print OUT $line1, ",", "0", "\n";
	next SLOOP;
      } elsif ($check == 2) {
	print OUT $line1, ",", $cov, "\n";
	$line2 = <SAMP>;
	chomp $line2;
	($s2, $p2, $cov) = process_samp($line2);
	next SLOOP;
      } elsif ($check == 3) {
	print OUT $line1, ",", "0", "\n";
	$flag = 1;
	next SLOOP;
      } else {
	print OUT $line1, ",", $cov, "\n";
	$flag = 1;
	next SLOOP;
      }
    }
  } 
}
close(START);
close(SAMP);
close(OUT);
exit;
      

#**********************************************************
# Subroutine(s)
#********************************************************** 
sub compare_lines {
  my ($s1, $s2, $p1, $p2) = @_;
  my $check = 0;
  
  if ($p1 < $p2) {
    $check = 1;
  } elsif ($p1 == $p2) {
   $check = 2;
  } else {
    $check = 0;
  }
  if (($check == 0) && (eof SAMP)) {
  $check = 3;
}

if (($check == 2) && (eof SAMP)) {
  $check = 4;
}
return($check);
}   
#********************************************************** 
sub process_samp {
  my ($line) = @_;
  chomp $line;
  my @info = split(/\t/, $line);
  my $scaff = $info[0];
  #$scaff =~ s/^scaffold_//;
  $scaff =~ s/\|\*\|[0-9]{1,}//;
  $scaff =~ s/^>//;
  $scaff =~ s/^JH//;
  my $pos = $info[1];
  my $cov = $info[3];

  return($scaff, $pos, $cov);
}
#**********************************************************
sub process_start {
  my ($line) = @_;
  chomp $line;
  my @info = split(/,/, $line);
  my ($scaffold, $position) = split(/\./, $info[0]);
  $scaffold =~ s/^JH//;
  return ($scaffold, $position);
}
