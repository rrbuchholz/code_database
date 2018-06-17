#!/usr/bin/perl -w
#
# Script for averaging burned area month data
#

$rundir = "/IASI/home/buchholz/burned_area/GFED_4/";
#------------------------------------
# create tracer list of tagged tracers to extract
#------------------------------------
$tracerlist = "BurnedArea";

    print "Selected extracted tracers: $tracerlist\n";
    print "\n";
    #------------------------------------
    # concatenate files
    #------------------------------------
    for  $i (2014..2014) {
         $to_combine = "";
         $dummy_sum = $i."_sum_01to12"."_2014_dummy.nc";
         $outfile_sum = $i."_sum_01to12"."_2014.nc";
         print"$to_combine\n";
         for  $j (1..12) {
          $dateval = $i.sprintf("%02d",$j);
         #------------------------------------
         # convert to netcdf
         #------------------------------------
          chomp($inname = `ls $rundir*$dateval*.hdf`);
          $outname = $rundir."/GFED4.0_MQ_".$dateval."_BA.nc";
          print"ncl_convert2nc $inname -o $rundir\n";
          #`ncl_convert2nc $inname -o $rundir`;

         #------------------------------------
         # collect files to avergae
         #------------------------------------
          chomp($fname = `ls $rundir*$dateval*.nc`);
          $to_combine = $to_combine.$fname." ";

         #------------------------------------
         # collect files to avergae
         #------------------------------------
           if ($j == 1){
             `cp $fname $dummy_sum`;
           } else {
             #ncbo can only handle three filenames
             print "ncbo -O -v $tracerlist --op_typ=+ $fname $dummy_sum $outfile_sum \n";
             `ncbo -O -v $tracerlist --op_typ=+ $fname $dummy_sum $outfile_sum`;
             print "cp $outfile_sum $dummy_sum \n";
             `cp $outfile_sum $dummy_sum`;
           }
         }
         print "\n";

         #$outfile = $i."_dummy.nc";
         #$outfile = $i."_08to09"."_dummy.nc";
         $outfile = $i."_sum_01to12"."_2014.nc";
         #print "$outfile\n";
         #chomp(`ls $rundir$i*/month/*.he5`);

         #------------------------------------
         #print "Averaging $i\n";
        # note ncra requires a time dimension in files, nces requires no time dimension
         print "nces -O -v $tracerlist $to_combine$outfile\n";
        #`nces -O -v $tracerlist $to_combine$outfile`;
exit
         #------------------------------------
         # adding for a year before averaging
         # (need to do a couple of hack steps)
         #------------------------------------
         #print "Summing $i\n";
         #print "ncbo -O -v $tracerlist --op_typ=+ $to_combine$outfile\n";
        #`ncbo -O -v $tracerlist --op_typ=+ $to_combine$outfile`;

        # chomp(@fnameII = `ls $i*_dummy.nc`);
        # $outfileII = $i."_08to11"."_dummy.nc";
        # print "ncbo -O -v $tracerlist --op_typ=+ @fnameII $outfileII\n";
        #`ncbo -O -v $tracerlist --op_typ=+ @fnameII $outfileII`;
     }


     chomp(@final_average = `ls *dummy.nc`);
         print "Averaging all\n";
         print "nces -O -v $tracerlist @final_average burnarea_2014.nc\n";
         `nces -O -v $tracerlist @final_average burnarea_2014.nc`;



