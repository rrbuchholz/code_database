#!/usr/bin/perl -w
#
# Script for averaging MOPITT month data
#

$rundir = "/net/mopfl/MOPITT/V8J/Archive/L3/";
$outdir = "/net/mopfl/home/buchholz/MOPITT_subset/V8/averages/";
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
     $to_combine = "";
     chomp($fname1 = `ls ${rundir}201912/month/*.he5`);
     chomp($fname2 = `ls ${rundir}202001/month/*.he5`);
     #chomp($fname1 = `ls ${rundir}202008/month/*.he5`);
     #chomp($fname2 = `ls ${rundir}202009/month/*.he5`);
     #chomp($fname3 = `ls ${rundir}202010/month/*.he5`);
     $to_combine = $to_combine.$fname1." ".$fname2;
         print "Combining $to_combine\n";
         print "\n";

     $outfile = $outdir."DecJan_V8J_Ausfire.nc";

     # note ncra requires a time dimension in files, nces requires no time dimension
     print "nces -O -v $tracerlist $to_combine $outfile\n";
     `nces -O -v $tracerlist $to_combine $outfile`;

     $diffile = $outdir."DJV8J_diff.nc";
     $avgfile = $outdir."MOPITTV8J_DJ2002_2019.nc";
         print "Differencing specific average\n";
         print "ncbo -O -v $tracerlist --op_typ=- $outfile $avgfile $diffile \n";
         `ncbo -O -v $tracerlist --op_typ=- $outfile $avgfile $diffile`;




