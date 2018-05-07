#!/usr/bin/perl -w
#
# Script for temporally averaging CAMchem output
#

$rundir = "/glade2/scratch2/buchholz/archive/fmerra.208.FCSD.1deg.chey180418.noanth/atm/h0/";
$outdir = "/glade/p/work/buchholz/data_processing/CAM-chem/FCSD2018_noanth/";
#------------------------------------
# create tracer list of tagged tracers to extract
#------------------------------------
$tracerlist = "date,datesec,time,lat,lon,P0,PS,hyam,hybm,hyai,hybi,CO,C2H6,ISOP,NO2,NO,NOX,NOY,O3,OH,PAN";
print "$tracerlist\n";
#print "\n";
#------------------------------------
# concatenate files
#------------------------------------
for  $i (2005..2014) {
  $to_combine = "";
  for  $j (1..12) {
    $m =  sprintf("%02d",$j);
    chomp($fname = `ls $rundir*$i-$m*.nc`);
    $to_combine = $to_combine.$fname." ";
  }
    print "Averaging $i$m\n";
    $outfile = $outdir."CAM_chem_fmerra_FCSD208_1deg_noanth_".$i.$m."_output_dummy.nc";

    print "ncra -O -v $tracerlist $to_combine $outfile\n";
    `ncra -O -v $tracerlist $to_combine $outfile`;
}
     chomp(@final_average = `ls $outdir*dummy.nc`);
         print "Averaging all\n";
         $outfile = $outdir."CAMchem_2001_2007";
         print "ncra -O -v $tracerlist @final_average $outfile.nc\n";
         `ncra -O -v $tracerlist @final_average $outdir"CAMchem_FCSD208_1deg_noanth_2001_2007.nc"`;







