#!/usr/bin/perl -w
#
# Script for temporally averaging MOPITT output
#
#$rundir = "/IASI/home/buchholz/MOPITT_subset/regions_v8/NH_monthly/";
$rundir = "/IASI/home/buchholz/MOPITT_subset/regions_v8/SH_monthly/";
$outdir = "/IASI/home/buchholz/MOPITT_subset/regions_v8/";
#$rundir = "/data16a/buchholz/gaubert_reanalysis_2017/h0/";
#$outdir = "/data16a/buchholz/gaubert_reanalysis_2017/climatology/";
#------------------------------------
# create tracer list of tagged tracers to extract
#------------------------------------
#$tracerlist = "date,datesec,time,lat,lon,P0,PS,PDELDRY,hyam,hybm,hyai,hybi,CO,C2H6,ISOP,NO2,NO,NOX,NOY,O3,OH,PAN";
$tracerlist = "time,RetrievedX_CO,RetrievedX_CORegionStats,RetrievedX_CORegion5th95th,AvgAPrioriX_CO,AvgDegreesofFreedomforSignal,AvgSurfacePressure,AvgDryAirColumn,AvgError,AvgRandomError,AvgSmoothingError,AvgAPrioriCOMixingRatioProfile,AvgRetrievedCOMixingRatioProfile,AvgTotalColumnAveragingKernel,AvgRetrievalAveragingKernelMatrix";
#$tracerlist = "time,time_bnds,lat,lon,lev,P0,PS,hyam,hybm,CO";
print "$tracerlist\n";
#print "\n";
#------------------------------------
# average files across months
#------------------------------------
for  $i (2016..2018) {
  $to_combine = "";
  for  $j (1..12) {
    $m =  sprintf("%02d",$j);
    chomp($fname = `ls $rundir*$i$m*.nc`);
    $to_combine = $to_combine.$fname." ";
  }
    print "Averaging $i\n";
    $outfile = $outdir."SH_V8Tsubset_".$i."monthavg_VMR.nc";

    #print "ncra -O -v $tracerlist $to_combine $outfile\n";
    #`ncra -O -v $tracerlist $to_combine $outfile`;
    print "nces -O -v $tracerlist $to_combine $outfile\n";
    `nces -O -v $tracerlist $to_combine $outfile`;
}
     #chomp(@final_average = `ls $outdir*dummy.nc`);
     #    print "Averaging all\n";
     #    $outfile = $outdir."CAMchem_2008_2015";
     #    print "ncra -O -v $tracerlist @final_average $outfile.nc\n";
     #    `ncra -O -v $tracerlist @final_average $outdir"CAMchem_FCSD208_1deg_2008_2015.nc"`;

#for  $i (2003..2013) {
#  $to_combine = "";
#  for  $j (1..12) {
#    $m =  sprintf("%02d",$j);
#    chomp($fname = `ls $rundir*$i-$m*.nc`);
#    $to_combine = $to_combine.$fname." ";
#  }
#    print "Averaging $i$m\n";
#    $outfile = $outdir."CAM_chem_fmerra_fmerra_FCSD_1deg_".$i."_output_dummy.nc";

#    print "ncra -O -v $tracerlist $to_combine $outfile\n";
#    `ncra -O -v $tracerlist $to_combine $outfile`;
#}
#------------------------------------
# average files across years
#------------------------------------
#     chomp(@final_average = `ls $outdir*dummy.nc`);
#         print "Averaging all\n";
#         $outfile = $outdir."CAMchem_2008_2015";
#         print "ncra -O -v $tracerlist @final_average $outfile.nc\n";
#         `ncra -O -v $tracerlist @final_average $outdir"Gaubert_reanalysis_2003_2013.nc"`;

#------------------------------------
# average months across years
#------------------------------------
#for  $j (1..12) {
#  $to_combine = "";
#  $m =  sprintf("%02d",$j);
#  for  $i (2003..2013) {
#    chomp($fname = `ls $rundir*$i-$m*.nc`);
#    $to_combine = $to_combine.$fname." ";
#  }
#    print "Averaging for month: $m\n";
#    $outfile = $outdir."Gaubert_reanalysis_month".$m."_2003_2013.nc";

#    print "ncra -O -v $tracerlist $to_combine $outfile\n";
#    `ncra -O -v $tracerlist $to_combine $outfile`;
#}






