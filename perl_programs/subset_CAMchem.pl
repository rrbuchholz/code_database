#!/usr/bin/perl -w
#
# Script for subsetting species or a region from CAMchem output
#
$runtype = "gfasBBCO";
$rundir = "/glade/scratch/buchholz/archive/fmerra.2.0.FCSD.1deg.chey180617.cmip.".$runtype."/atm/hist/";
#$rundir = "/glade/scratch/buchholz/CAMchem_fmerra_e15_BAM_constE/";
$outdir = "/glade2/work/buchholz/CAM_chem_output/fire_uncert/".$runtype."/";
#------------------------------------
# create tracer list of tagged tracers to extract
#------------------------------------
$tracerlist = "CO";
#for  $s (0..29) {
#  print"CO".sprintf("%02d",$s+1).", ";
#  $tracerlist = $tracerlist.",CO".sprintf("%02d",$s+1);
#}
print "\n";

#------------------------------------
# concatenate files
#------------------------------------
for  $i (2014..2014) {
  $y =  sprintf("%04d",$i);
  $outfile = $outdir."CAM_chem_fmerra2_FCSD_1deg_".$runtype."_".$y.".nc";
  print "$outfile\n";
  chomp(@to_combine = `ls $rundir*h1.*$y-*.nc`);
  print "Combining $y\n";

  print "ncrcat -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PS,$tracerlist @to_combine $outfile\n";
  `ncrcat -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PS,$tracerlist @to_combine $outfile`;

  #print "ncrcat -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PDELDRY,$tracerlist -d lat,20,43 -d lon,44,73 @to_combine $outfile\n";
  #`ncrcat -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PDELDRY,$tracerlist -d lat,20,43 -d lon,44,73 @to_combine $outfile`;
}









