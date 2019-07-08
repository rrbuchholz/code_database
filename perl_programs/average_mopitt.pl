#!/usr/bin/perl -w
#
# Script for averaging MOPITT month data
#

$rundir = "/net/mopfl/MOPITT/V8T/Archive/L3/";
#$rundir = "/MOPITT/V7J/Archive/L3/";
#------------------------------------
# create tracer list of tagged tracers to extract
#------------------------------------
$tracerlist = "RetrievedCOTotalColumnDay,RetrievedCOTotalColumnNight,RetrievedCOMixingRatioProfileDay,RetrievedCOSurfaceMixingRatioDay,SurfacePressureDay,Latitude,Longitude";
    print "Selected extracted tracers: $tracerlist\n";
    print "\n";
    #------------------------------------
    # concatenate files
    #------------------------------------
    for  $i (2002..2017) {
         $to_combine = "";
         print"$to_combine\n";
         for  $j (1..12) {
          $dateval = $i.sprintf("%02d",$j);
          chomp($fname = `ls $rundir$dateval/month/*.he5`);
          $to_combine = $to_combine.$fname." ";
         }
         print "\n";

         $outfile = "/net/mopfl/home/buchholz/MOPITT_subset/V8/averages/".$i."_dummy.nc";
         #$outfile = "/net/mopfl/home/buchholz/MOPITT_subset/V7/averages/".$dateval."_dummy.nc";
         #$outfile = "/net/mopfl/home/buchholz/MOPITT_subset/V8/averages/".$dateval."_Feb.nc";
         #print "$outfile\n";
         #chomp(`ls $rundir$i*/month/*.he5`);
         print "Averaging $i\n";

        # note ncra requires a time dimension in files, nces requires no time dimension
         print "nces -O -v $tracerlist $to_combine$outfile\n";
        `nces -O -v $tracerlist $to_combine$outfile`;
     }

     chomp(@final_average = `ls /net/mopfl/home/buchholz/MOPITT_subset/V8/averages/*_dummy.nc`);
         print "Averaging all\n";
         print "nces -O -v $tracerlist @final_average /net/mopfl/home/buchholz/MOPITT_subset/V8/averages/MOPITT_2002_2017.nc\n";
         `nces -O -v $tracerlist @final_average /net/mopfl/home/buchholz/MOPITT_subset/V8/averages/MOPITT_2002_2017.nc`;
