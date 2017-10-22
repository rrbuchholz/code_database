#!/usr/bin/perl -w
#
# Script for calculating SD of MOPITT month data
# Use after averaging script
#

$rundir = "/IASI/home/buchholz/scripts/";
$avgfile = "MOPITT_SOND_2001_2016.nc";

#------------------------------------
# create tracer list of tagged tracers to extract
#------------------------------------
chomp(@month_files = `ls *dummy.nc`);
$dims = scalar(@month_files);
print "Number of files = $dims\n";

$tracerlist = "RetrievedCOTotalColumnDay,RetrievedCOTotalColumnNight,RetrievedCOMixingRatioProfileDay,RetrievedCOSurfaceMixingRatioDay";
    print "Selected extracted tracers: $tracerlist\n";
    print "\n";
    #------------------------------------
    # Difference for each month
    #------------------------------------
    for  $i (0..$dims-1) {
      chomp($infile = @month_files[$i]); 
      my @str_split = split(/_/, $infile);
      $outfile = @str_split[0]."_diff.nc";
      print "$outfile\n";
   
      print "ncbo -O -v $tracerlist --op_typ=- $infile $avgfile $outfile \n";
      `ncbo -O -v $tracerlist --op_typ=- $infile $avgfile $outfile`;
     }

      chomp(@final_diffs = `ls *_diff.nc`);
      $sdfile = "MOPITT_2001_2016_SONDsd.nc";
      print "--------------------------------------------------\n";
      print "nces -v $tracerlist -y rmssdn @final_diffs $sdfile \n";
      `nces -O -v $tracerlist -y rmssdn @final_diffs $sdfile`;
