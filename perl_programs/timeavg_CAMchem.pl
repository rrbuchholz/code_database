#!/usr/bin/perl -w
#
# Script for subsetting a region from CAMchem output
#

$rundir = "/glade/scratch/buchholz/fmerra.e15alpha.FSDSSOA.2deg.longrun/h0/";
$outdir = "/glade/p/work/buchholz/data_processing/CAM-chem/";
#$rundir = "/glade/scratch/buchholz/CAMchem_fmerra_e15_BAM_constE/";
#------------------------------------
# create tracer list of tagged tracers to extract
#------------------------------------
$tracerlist = "date,datesec,time,lat,lon,P0,PS,hyam,hybm,hyai,hybi,CO,C2H6";
print "$tracerlist\n";
#print "\n";
#------------------------------------
# concatenate files
#------------------------------------
for  $i (2001..2007) {
  $to_combine = "";
  for  $j (1..12) {
    $m =  sprintf("%02d",$j);
    chomp($fname = `ls $rundir*$i-$m*.nc`);
    $to_combine = $to_combine.$fname." ";
  }
    print "Averaging $i$m\n";
    $outfile = $outdir."CAM_chem_fmerra_FSDSSOA_2deg_".$i.$m."_ethane_dummy.nc";

    print "ncra -O -v $tracerlist $to_combine $outfile\n";
    `ncra -O -v $tracerlist $to_combine $outfile`;
}
     chomp(@final_average = `ls $outdir*dummy.nc`);
         print "Averaging all\n";
         $outfile = $outdir."CAMchem_2001_2007";
         print "ncra -O -v $tracerlist @final_average $outfile.nc\n";
         `ncra -O -v $tracerlist @final_average $outdir"CAMchem_2001_2007.nc"`;







