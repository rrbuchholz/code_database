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
for  $s (0..29) {
  print"CO".sprintf("%02d",$s+1).", ";
  $tracerlist = $tracerlist.",CO".sprintf("%02d",$s+1);
}
print "\n";

#------------------------------------
# concatenate files
#------------------------------------
for  $i (2011..2014) {
  $y =  sprintf("%04d",$i);
  #$outfile = $rundir."CAM_chem_fmerra_FSDSSOA_2deg_".$y."_Australasia.nc";
  $outfile = $rundir."CAM_chem_fmerra_FSDSSOA_2deg_".$y."_Australasia.nc";
  print "$outfile\n";
  chomp(@to_combine = `ls $rundir*$y-*.nc`);
  print "Combining $y\n";

  print "ncrcat -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PDELDRY,$tracerlist -d lat,20,43 -d lon,44,73 @to_combine $outfile\n";
  `ncrcat -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PDELDRY,$tracerlist -d lat,20,43 -d lon,44,73 @to_combine $outfile`;
}









