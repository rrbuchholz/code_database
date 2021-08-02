#!/bin/bash

#-------------------
# Concatenates emission
# files using NCO 
# (netCDF operators)
#-------------------


#workdir=/gpfs/fs1/work/buchholz/emis/CMIP6   # working directory
#outdir=/gpfs/fs1/work/buchholz/emis/CMIP62012_2014   # working directory
#file_list="$(ls $workdir)"
workdir=/data14b/buchholz/qfed/cam_0.9x1.25/from_co2/nrt_new
outdir=/data14b/buchholz/qfed/cam_0.9x1.25/from_co2/nrt_new
file_list="$(ls $workdir/*2018_2020.nc)"
arr=$(echo "$file_list" | sed 's/2018_2020*.nc//g')        # remove year specific to file
#arr=$(echo "$file_list" | sed 's/'$year_of_interest'*.nc//g')        # remove year specific to file

for x in $arr ; do
   infile=${x}2018_2020.nc
   outfile=${x}2020.nc
    #echo ${workdir}/${x}
    #newfile=$(echo $x | sed 's/1750-2015/2012-2014/')
    echo ${infile}
    #echo "ncea -F -d time,3143,3179,${workdir}/$x ${outdir}/${newfile}"
    echo "ncrcat -d time,730,1095 $infile $outfile"
    ncrcat -d time,730,1095 $infile $outfile
    # ncea -F -d time,3143,3179,${workdir}/$x ${outdir}/${newfile} # temporal subsed
done
