#!/usr/bin/perl -w
#
# Script for averaging MOPITT month data
#

$rundir = "/net/mopfl/MOPITT/V8J/Archive/L3/";
#$rundir = "/MOPITT/V7J/Archive/L3/";
#------------------------------------
# create tracer list of tagged tracers to extract
#------------------------------------
$tracerlist = "RetrievedCOTotalColumnDay,RetrievedCOTotalColumnNight,RetrievedCOMixingRatioProfileDay,RetrievedCOSurfaceMixingRatioDay,SurfacePressureDay,Latitude,Longitude,DryAirColumnDay,DryAirColumnNight";
    print "Selected extracted tracers: $tracerlist\n";
    print "\n";
    #------------------------------------
    # concatenate files
    #------------------------------------
    for  $i (2002..2019) {
         $to_combine = "";
         print"$to_combine\n";
         #for  $j (1..12) {
         #for  $j (8..10) {
         for  $j (1,12) {
          $dateval = $i.sprintf("%02d",$j);
          chomp($fname = `ls $rundir$dateval/month/*.he5`);
          $to_combine = $to_combine.$fname." ";
         }
         print "Combining $to_combine\n";
         print "\n";

         $outfile = "/net/mopfl/home/buchholz/MOPITT_subset/V8/averages/".$i."_DJ_V8J.nc";
         #$outfile = "/net/mopfl/home/buchholz/MOPITT_subset/V7/averages/".$dateval."_dummy.nc";
         #$outfile = "/net/mopfl/home/buchholz/MOPITT_subset/V8/averages/".$dateval."_Feb.nc";
         #print "$outfile\n";
         #chomp(`ls $rundir$i*/month/*.he5`);
         print "Averaging $i\n";

        # note ncra requires a time dimension in files, nces requires no time dimension
         print "nces -O -v $tracerlist $to_combine$outfile\n";
        `nces -O -v $tracerlist $to_combine$outfile`;
     }

     chomp(@final_average = `ls /net/mopfl/home/buchholz/MOPITT_subset/V8/averages/*_DJ_V8J.nc`);
         print "Averaging all\n";
         print "nces -O -v $tracerlist @final_average /net/mopfl/home/buchholz/MOPITT_subset/V8/averages/MOPITTV8J_DJ2002_2019.nc\n";
         `nces -O -v $tracerlist @final_average /net/mopfl/home/buchholz/MOPITT_subset/V8/averages/MOPITTV8J_DJ2002_2019.nc`;





