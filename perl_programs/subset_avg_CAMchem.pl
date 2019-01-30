#!/usr/bin/perl -w
#
# Script for subsetting a region from CAMchem output
#

$rundir = "/glade/scratch/buchholz/archive/CAMchem_fmerra_e15/atm/hist/";
#$rundir = "/glade/scratch/buchholz/archive/CAMchem_fmerra_e15_BAM_constE/";
#$rundir = "/data16a/buchholz/CAM_chem_output/fmerra.208.FCSD.1deg.chey180418/atm/h0/";
$outdir = "/glade/work/buchholz/data_processing/CAM-chem/";
#------------------------------------
# create tracer list of tagged tracers to extract
#------------------------------------
#$tracerlist = "CO,C2H6";
$tracerlist = "CO";
for  $s (0..29) {
  print"CO".sprintf("%02d",$s+1).", ";
  $tracerlist = $tracerlist.",CO".sprintf("%02d",$s+1);
}
print "$tracerlist\n";
#print "\n";
#------------------------------------
# concatenate files
#------------------------------------
for  $i (2000..2000) {
  for  $j (1..12) {
    $y =  sprintf("%04d",$i);
    $m =  sprintf("%02d",$j);
    $outfile = $outdir."Siberia_CAM_chem_fmerra_FCSD_2deg_".$y."avg_co.nc";
    print "$outfile\n";
    #chomp(@to_combine = `ls $outdir*$y-$m-*.nc`);
    chomp(@to_combine = `ls $rundir*$y-$m*.nc`);
    print "Averaging $y$m\n";

    print "ncra -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PDELDRY,$tracerlist -d lat,75,81 -d lon,97,111 @to_combine $outfile\n";
    `ncra -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PDELDRY,$tracerlist -d lat,75,81 -d lon,97,111 @to_combine $outfile`;
#BBCanada  50.,  60.,     240.,      275. = -d lat,75,81 -d lon,97,111;
#BBSiberia 50.,  60.,       90.,      140. = -d lat,75,81 -d lon,37,57;
   # `ncra -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PDELDRY,$tracerlist @to_combine $outfile`;
  }
}









