#!/usr/bin/perl -w
#
# Script for subsetting species or a region from CAMchem output
#
$rundir = "/gpfs/fs1/work/buchholz/emis/CMIP6";

#------------------------------------
# create tracer list of tagged tracers to extract
#------------------------------------
$tracerlist = "CO,O3,CH2O,CLDTOT,CLOUD,ISOP,PAN,OH,NO2,NOX,NOY,jno2,HNO3,ALKNIT,ISOPNO3,MEG_ISOP,AEROD_v,AODVIS,AODVISdn,AQRAIN,H2O,HONITR,HPALD,IEPOX,ISOPNITA,ISOPNITB,ISOPOOH,MPAN,NOA,ONITR,Q,T,TERPNIT,FSNS,FSDS,FLDS,FLNS";
#$tracerlist = "CO";
#for  $s (0..29) {
#  print"CO".sprintf("%02d",$s+1).", ";
#  $tracerlist = $tracerlist.",CO".sprintf("%02d",$s+1);
#}
print "$tracerlist \n";

#------------------------------------
# concatenate files
#------------------------------------
for  $i (2004..2015) {
  $y =  sprintf("%04d",$i);
  $outfile = $outdir."CAM_chem_fmerra2_FCSD_1deg_".$region.$runtype."_".$y."_new.nc";
  print "$outfile\n";
  chomp(@to_combine = `ls $rundir*h0.*$y-*.nc`);
  print "Combining $y\n";

  #print "ncrcat -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PS,$tracerlist @to_combine $outfile\n";
  #`ncrcat -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PS,$tracerlist @to_combine $outfile`;
   # Wollongong and surrounds 1 deg: -d lat,56,62  -d lon,117,123
  print "ncrcat -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PS,PDELDRY,$tracerlist -d lat,56,62 -d lon,117,123 @to_combine $outfile\n";
  `ncrcat -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PS,PDELDRY,$tracerlist -d lat,56,62 -d lon,117,123 @to_combine $outfile`;

}






