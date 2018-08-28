#!/usr/bin/perl -w
#
# Script for averaging summed years of burned area month data
#

$rundir = "/IASI/home/buchholz/burned_area/GFED_4/";
$outdir = "/IASI/home/buchholz/burned_area/averages/";
#------------------------------------
# create tracer list of tagged tracers to extract
#------------------------------------
$tracerlist = "BurnedArea";

    print "Selected extracted tracers: $tracerlist\n";
    print "\n";
    #------------------------------------
    # concatenate files
    #------------------------------------
    for  $i (2010..2015) {
         $to_combine = "";
         $dummy_sum = $i."_sum_01to12_dummy.nc";
         $outfile_sum = $i."_sum_01to12"."_2011to2016.nc";
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
         # collect year sum files to average
         #------------------------------------
           if ($j == 1){
             `cp $fname $outdir$dummy_sum`;

           } else {
             #ncbo can only handle three filenames
             print "ncbo -O -v $tracerlist --op_typ=+ $fname $outdir$dummy_sum $outdir$outfile_sum \n";
             `ncbo -O -v $tracerlist --op_typ=+ $fname $outdir$dummy_sum $outdir$outfile_sum`;
             print "cp $outdir$outfile_sum $outdir$dummy_sum \n";
             `cp $outdir$outfile_sum $outdir$dummy_sum`;

           }
         }
         print "\n";

         #$outfile = $i."_dummy.nc";
         #$outfile = $i."_01to12"."_BA_dummy.nc";
         #$outfile = $i."_sum_01to12"."_2014.nc";
         #$outfile = $i."_sum_01to12"."_2011to2016.nc";
         #print "$outfile\n";
         #chomp(`ls $rundir$i*/month/*.he5`);

         #------------------------------------
         #print "Averaging $i\n";
        # note ncra requires a time dimension in files, nces requires no time dimension
         #print "nces -O -v $tracerlist $to_combine$outfile\n";
        #`nces -O -v $tracerlist $to_combine$outfile`;

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


     chomp(@final_average = `ls $outdir*dummy.nc`);
         $finalout = "burnarea_2001to2016.nc";
         print "Averaging all\n";
         print "nces -O -v $tracerlist @final_average $outdir$finalout\n";
         `nces -O -v $tracerlist @final_average $outdir$finalout`;



