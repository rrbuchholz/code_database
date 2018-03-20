#!/bin/bash

#-------------------
# Transforms emission files using NCO 
# (netCDF operators).
# Creates empty files to fill.
#-------------------

workdir=/data14b/buchholz/qfed/cam_0.9x1.25/from_co2/v2.5  # working directory
outdir=/data14b/buchholz/qfed/cam_0.9x1.25/from_co2/nrt
year_of_interest=2015
file_list="$(ls $workdir/$year_of_interest/)"
arr=$(echo "$file_list" | sed 's/'$year_of_interest'*.nc//g')        # remove year specific to file

for x in $arr ; do
   infile=$workdir/$year_of_interest/${x}$year_of_interest.nc
   outfile=${outdir}/${x}2018.nc

   echo "ncap2 -O -s 'date=date+30000;time=time+1096;bb=bb*0.0' $infile $outfile"
   ncap2 -O -s 'date=date+30000;time=time+1096;bb=float(bb*0.0)' $infile $outfile

done
