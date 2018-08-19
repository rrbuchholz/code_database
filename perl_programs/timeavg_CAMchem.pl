#!/usr/bin/perl -w
#
# Script for temporally averaging CAMchem output
#

#$rundir = "/glade2/scratch2/buchholz/archive/fmerra.208.FCSD.1deg.chey180418.noanth/atm/h0/";
#$outdir = "/glade/p/work/buchholz/data_processing/CAM-chem/FCSD2018_noanth/";
$rundir = "/data16a/buchholz/CAM_chem_output/fmerra.208.FCSD.1deg.chey180418/atm/h0/";
$outdir = "/data16a/buchholz/CAM_chem_output/fmerra.208.FCSD.1deg.chey180418/processed/";
#------------------------------------
# create tracer list of tagged tracers to extract
#------------------------------------
$tracerlist = "date,datesec,time,lat,lon,P0,PS,PDELDRY,hyam,hybm,hyai,hybi,CO,C2H6,ISOP,NO2,NO,NOX,NOY,O3,OH,PAN";
print "$tracerlist\n";
#print "\n";
#------------------------------------
# concatenate files
#------------------------------------
for  $i (2008..2015) {
  $to_combine = "";
  for  $j (1..12) {
    $m =  sprintf("%02d",$j);
    chomp($fname = `ls $rundir*$i-$m*.nc`);
    $to_combine = $to_combine.$fname." ";
  }
    print "Averaging $i$m\n";
    $outfile = $outdir."CAM_chem_fmerra_fmerra_FCSD_1deg_".$i."_output_dummy.nc";

    print "ncra -O -v $tracerlist $to_combine $outfile\n";
    `ncra -O -v $tracerlist $to_combine $outfile`;
}
     chomp(@final_average = `ls $outdir*dummy.nc`);
         print "Averaging all\n";
         $outfile = $outdir."CAMchem_2008_2015";
         print "ncra -O -v $tracerlist @final_average $outfile.nc\n";
         `ncra -O -v $tracerlist @final_average $outdir"CAMchem_FCSD208_1deg_2008_2015.nc"`;







