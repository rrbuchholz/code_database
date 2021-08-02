#!/bin/bash

#-------------------
# Transforms emission files using NCO 
# (netCDF operators).
# Creates empty files to fill.
#-------------------

# set up directories and input files
#workdir=/data14b/buchholz/qfed/cam_0.9x1.25/from_co2/v2.5  # working directory
workdir=/data14b/buchholz/qfed/cam_0.9x1.25/from_co2/nrt_template/yearly
outdir=/data14b/buchholz/qfed/cam_0.9x1.25/from_co2/nrt_template/yearly
year_of_interest=2019
#file_list="$(ls $workdir/$year_of_interest/)"
file_list="$(ls $workdir/*$year_of_interest.nc)"
arr=$(echo "$file_list" | sed 's/'$year_of_interest'*.nc//g')        # remove year specific to file
#echo $arr
#exit

# how to change the dates
years_forward=3
time_add=$(expr $years_forward \* 365 \+ 1) # need +1 when calculating leap years
date_add=$(expr $years_forward \* 10000)
echo $time_add

# create the empty files
for x in $arr ; do
   #infile=$workdir/${year_of_interest}/${x}$year_of_interest.nc
   infile=${x}$year_of_interest.nc
   outfile=${x}2022.nc

   echo "ncap2 -O -s 'date=date+$date_add;time=time+$time_add;bb=bb*0.0' $infile $outfile"
   ncap2 -O -s 'date=date+'$date_add';time=time+'$time_add';bb=float(bb*0.0)' $infile $outfile

done
