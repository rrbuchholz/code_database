#!/bin/bash

#-------------------
# Extract temporal subset from
# emission files using NCO 
# and change dates
# (netCDF operators).
#-------------------

# set up directories and input files
workdir=/glade/work/emmons/emis/cmip6_2000_2018/   # working directory
outdir=/glade/work/buchholz/emis/cmip_extended2   # out directory

file_list="$(ls ${workdir}*.nc)"
arr=$(echo "$file_list" | sed 's/*2000-2018*.nc//g')        # remove year specific to file

echo $arr

for x in $arr ; do
    newfile_a=$(echo $x | sed 's/\/glade\/work\/emmons\/emis\/cmip6_2000_2018\///')
    newfile=$(echo $newfile_a | sed 's/2000-2018/2018-2019/')
    echo ${newfile}
    echo "ncea -F -d time,204,228 $x ${outdir}/${newfile}"
    ncea -F -d time,204,228 $x ${outdir}/${newfile} # temporal subset
done

# how to change the dates
#years_forward=4
#time_add=$(expr $years_forward \* 365 \+ 1) # need +1 when calculating leap years
#date_add=$(expr $years_forward \* 10000)
#echo $time_add

years_forward=1
time_add=$(expr $years_forward \* 365 )
date_add=$(expr $years_forward \* 10000)
echo $time_add

file_list2="$(ls ${outdir}/*.nc)"
echo $file_list2

for y in $file_list2 ; do
   outfile=$y

   # overwrite with new date
   echo "ncap2 -O -s 'date=date+$date_add;time=time+$time_add' $y $y"
   #ncap2 -O -s 'date=date+'$date_add';time=time+'$time_add'' $y $y

   # create empty files
   #echo "ncap2 -O -s 'date=date+$date_add;time=time+$time_add;bb=bb*0.0' $y $y"
   #ncap2 -O -s 'date=date+'$date_add';time=time+'$time_add';bb=float(bb*0.0)' $y $y

done




