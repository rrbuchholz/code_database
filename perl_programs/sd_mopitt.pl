#!/usr/bin/perl -w
#
# Script for calculating SD of MOPITT month data
# Use after averaging script
#

$rundir = "/net/mopfl/home/buchholz/MOPITT_subset/V8/averages/";
$mopdir = "/net/mopfl/MOPITT/V8T/Archive/L3/";
#$avgfile = $rundir."MOPITT_2002_2017.nc";
$avgfile = $rundir."MOPITT_Feb_2002_2017.nc";

#------------------------------------
# create tracer list of tagged tracers to extract
#------------------------------------
#chomp(@month_files = `ls *dummy.nc`);
    for  $i (2002..2017) {
         for  $j (02..02) {
          $dateval = $i.sprintf("%02d",$j);
          chomp($fname = `ls $mopdir$dateval/month/*.he5`);
          $to_combine = $to_combine.$fname." ";
         }
     }
    @month_files = split(/ /, $to_combine);

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
      my @str_split = split(/-/, $infile);
      $outfile = $rundir.@str_split[1]."_Febdiff.nc";
      print "$outfile\n";
   
      print "ncbo -O -v $tracerlist --op_typ=- $infile $avgfile $outfile \n";
      `ncbo -O -v $tracerlist --op_typ=- $infile $avgfile $outfile`;
     }

      chomp(@final_diffs = `ls $rundir*_Febdiff.nc`);
      $sdfile = $rundir."MOPITT_2002_2017_Feb_sd.nc";
      print "--------------------------------------------------\n";
      print "nces -v $tracerlist -y rmssdn @final_diffs $sdfile \n";
      `nces -O -v $tracerlist -y rmssdn @final_diffs $sdfile`;
