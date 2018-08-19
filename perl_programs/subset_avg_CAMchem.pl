#!/usr/bin/perl -w
#
# Script for subsetting a region from CAMchem output
#

#$rundir = "/glade/scratch/buchholz/fmerra.e15alpha.FSDSSOA.2deg.longrun/h1/";
#$rundir = "/glade/scratch/buchholz/CAMchem_fmerra_e15_BAM_constE/";
$rundir = "/data16a/buchholz/CAM_chem_output/fmerra.208.FCSD.1deg.chey180418/atm/h0/";
$outdir = "/data16a/buchholz/CAM_chem_output/fmerra.208.FCSD.1deg.chey180418/processed/";
#------------------------------------
# create tracer list of tagged tracers to extract
#------------------------------------
$tracerlist = "CO,C2H6";
#for  $s (12,15,16,26,29,30) {
#  #print"CO".sprintf("%02d",$s).", ";
#  $tracerlist = $tracerlist.",CO".sprintf("%02d",$s);
#}
print "$tracerlist\n";
#print "\n";
#------------------------------------
# concatenate files
#------------------------------------
for  $i (2014..2014) {
  #for  $j (1..12) {
    $y =  sprintf("%04d",$i);
    $m =  sprintf("%02d",$j);
    $outfile = $outdir."CAM_chem_fmerra_FCSD_1deg_".$y.$m."_ethane.nc";
    print "$outfile\n";
    #chomp(@to_combine = `ls $outdir*$y-$m-*.nc`);
    chomp(@to_combine = `ls $outdir*$y-$m-*.nc`);
    print "Averaging $y$m\n";

    print "ncra -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PDELDRY,$tracerlist  @to_combine $outfile\n";
    #`ncra -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PDELDRY,$tracerlist -d lat,23,28 -d lon,113,118 @to_combine $outfile`;
    `ncra -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PDELDRY,$tracerlist @to_combine $outfile`;
  }
}









