#!/usr/bin/perl -w
#
# Script for subsetting a region from CAMchem output
#

$rundir = "/glade/scratch/buchholz/fmerra.e15alpha.FSDSSOA.2deg.longrun/h1/";
#$rundir = "/glade/scratch/buchholz/CAMchem_fmerra_e15_BAM_constE/";
#------------------------------------
# create tracer list of tagged tracers to extract
#------------------------------------
$tracerlist = "CO";
for  $s (12,15,16,26,29,30) {
  #print"CO".sprintf("%02d",$s).", ";
  $tracerlist = $tracerlist.",CO".sprintf("%02d",$s);
}
print "$tracerlist\n";
#print "\n";
#------------------------------------
# concatenate files
#------------------------------------
for  $i (2014..2014) {
  for  $j (1..11) {
    $y =  sprintf("%04d",$i);
    $m =  sprintf("%02d",$j);
    $outfile = $rundir."CAM_chem_fmerra_FSDSSOA_2deg_".$y.$m."_MtTronadorRegion_tags.nc";
    print "$outfile\n";
    chomp(@to_combine = `ls $rundir*$y-$m-*.nc`);
    print "Averaging $y$m\n";

    print "ncra -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PDELDRY,$tracerlist -d lat,23,28 -d lon,113,118 @to_combine $outfile\n";
    `ncra -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PDELDRY,$tracerlist -d lat,23,28 -d lon,113,118 @to_combine $outfile`;
  }
}









