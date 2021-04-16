#!/usr/bin/perl -w
#
# Script for subsetting species and/or a region from CAMchem output
# from multiple files into one file
#

#$region = "Boulder";
$region = "Boulder";
# Reunion, Boulder 
$topdir = "/glade/scratch/buchholz/archive/";
#$casedir = "f.e21_003.FCSD.f09_f09_mg17.20200203_camsqfed_56L_merra2.boulder/atm/hist";
#$casedir = "fmerra.2.1003.FCSD.f09.qfedcmip.56L.001.branch02/atm/hist";
#$casedir = "fmerra.2.1003.FCSD.f09.qfedcmip.56L.001/atm/hist";
#$casedir = "f.e21_003.FCSD.f09_f09_mg17.ch200201_qfed_56L_merra2.boulder/atm/h1";
#$casedir = "f.e21_003.FCSD.f09_f09_mg17.ch200201_qfed_56L_merra2.boulder/atm/hist";
#$casedir = "f.e21_003.FCSD.f09_f09_mg17.ch190918_finn_56L_merra2.boulder/atm/h1";
$casedir = "f.e21_003.FCSD.f09_f09_mg17.ch190918_finn_56L_merra2.boulder/atm/hist";
#$casedir = "f.e21_003.FCSD.f09_f09_mg17.ch190918_qfed_56L_merra2.boulder/atm/h1";
#$casedir = "f.e21_003.FCSD.f09_f09_mg17.ch190918_qfed_56L_merra2.boulder/atm/hist";
#$casedir = "fmerra.2.1003.FCSD.1deg.chey180910.cmip.56L.boulder/atm/h2/";
#$runtype = "anth";
#$casedir = "fmerra.208.FCSD.1deg.chey180418".$runtype."/atm/hist/";
#$casedir = "fmerra.2.0.FCSD.1deg.chey180617.cmip.".$runtype."/atm/hist/";
#$casedir = "CAMchem_fmerra_e15_BAM_constE/";
$rundir = $topdir.$casedir;
#$outdir = "/glade/work/buchholz/CAM_chem_output/FTS_extractions/";
$outdir = "/glade/work/buchholz/CAM_chem_output/boulder/";
#$outdir = "/glade/work/buchholz/CAM_chem_output/for_Janyl/";

#------------------------------------
# create tracer list of tagged tracers to extract
#------------------------------------
#$tracerlist = "CO,O3,CH2O,CLDTOT,CLOUD,ISOP,PAN,OH,NO2,NOX,NOY,jno2,HNO3,ALKNIT,ISOPNO3,MEG_ISOP,AEROD_v,AODVIS,AODVISdn,AQRAIN,H2O,HONITR,HPALD,IEPOX,ISOPNITA,ISOPNITB,ISOPOOH,MPAN,NOA,ONITR,Q,TERPNIT,FSNS,FSDS,FLDS,FLNS";
#Ivan
#$tracerlist ="C2H2,C2H6,CH2O,CH4,CO,HCN,HCOOH,ISOP,NH3,NH4,NO,NO2,O3";
$tracerlist ="NH3,DF_NH3,SFNH3,WD_NH3,H2SO4,CO,DF_CO,CO_CHML,CO_CHMP,SFCO,MEG_CO";
#Janyl
#$tracerlist ="CO";
#$tracerlist ="CO,CH2O,HCN,NH3,NH4,NO,NO2,O3,SO2,PM25,PBLH,AODDUST,AODDUST1,AODDUST2,AODDUST3,AODNIRstdn,AODUVdn,AODUVstdn,AODVIS,AODVISdn,AODVISstdn,AODdnDUST1,AODdnDUST2,AODdnDUST3,AODdnMODE1,AODdnMODE2,AODdnMODE3,bc_a1,bc_a4,pom_a1,pom_a4,ncl_a1,ncl_a2,ncl_a3,so4_a1,so4_a2,so4_a3,soa1_a1,soa2_a1,soa3_a1,soa4_a1,soa5_a1,soa1_a2,soa2_a2,soa3_a2,soa4_a2,soa5_a2,BURDENBCdn,BURDENDUSTdn,BURDENPOMdn,BURDENSEASALTdn,BURDENSO4dn,BURDENSOAdn";

#$tracerlist = "CO";
#for  $s (0..29) {
#  print"CO".sprintf("%02d",$s+1).", ";
#  $tracerlist = $tracerlist.",CO".sprintf("%02d",$s+1);
#}
print "$tracerlist \n";

#------------------------------------
# concatenate files
#------------------------------------
for  $i (2010..2019) {
  $y =  sprintf("%04d",$i);
  $outfile = $outdir."CAM_chem_merra2_FCSD_1deg_FINNCMIP_".$region."_".$y."nh3dep_coProc.nc";
  #$outfile = $outdir."CAM_chem_merra2_FCSD_1deg_QFED_".$region."_".$y.".nc";
  print "$outfile\n";
  chomp(@to_combine = `ls $rundir/*h0.$y-*.nc`);
  #chomp(@to_combine = `ls $rundir/${y}/*$y-*.nc`);
  #chomp(@to_combine = `ls $rundir/*$y-01*.nc`);
  print "Combining $y\n";

  #print "ncrcat -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PS,PDELDRY,$tracerlist @to_combine $outfile\n";
  #`ncrcat -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PS,$tracerlist @to_combine $outfile`;
   # indices for 1x1 simulations
   # Wollongong and surrounds 1 deg: -d lat,56,62  -d lon,117,123
   # Boulder and surrounds 1 deg: -d lat,136,140  -d lon,202,206
   # Xianghe lat [37— 42]; lon [114— 120]: -d lat,135,140  -d lon,91,96
   # Reunion lat [-23 —  -18]; lon [53 —  59]: -d lat,71,76  -d lon,42,47
   # Portovelho lat [-11 — -6 ]; lon [-67 (293) — -61 (299)]: -d lat,84,89  -d lon,234,239
   # CentralAsia lat [35 — 55]; lon [50 — 90]: -d lat,132,154  -d lon,40,72
  print "ncrcat -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PS,PDELDRY,T,Z3,Q,U,V,$tracerlist -d lat,136,140  -d lon,202,206 @to_combine $outfile\n";
  `ncrcat -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PS,PDELDRY,T,Z3,Q,U,V,$tracerlist -d lat,136,140  -d lon,202,206 @to_combine $outfile`;
  #print "ncrcat -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PS,PDELDRY,T,Z3,Q,U,V,$tracerlist -d lat,132,154  -d lon,40,72 @to_combine $outfile\n";
  #`ncrcat -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PS,PDELDRY,T,Z3,Q,U,V,$tracerlist -d lat,132,154  -d lon,40,72 @to_combine $outfile`;
 # `ncrcat -O -v date,datesec,time,lat,lon,P0,hyam,hybm,hyai,hybi,PS,PDELDRY,$tracerlist @to_combine $outfile`;

}






