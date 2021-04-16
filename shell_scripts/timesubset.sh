#!/bin/bash

#-------------------
# Concatenates emission
# files using NCO 
# (netCDF operators)
#-------------------


workdir=/gpfs/fs1/work/buchholz/emis/qfed2.5_finn_2000_2020_1x1   # working directory
outdir=/gpfs/fs1/work/buchholz/emis/test   # working directory
file_list="$(ls $workdir)"

echo $file_list

for x in $file_list ; do
    #echo ${workdir}/${x}
    newfile=$(echo $x | sed 's/1750-2015/2012-2014/')
    echo ${newfile}
    echo "ncea -F -d time,3143,3179,${workdir}/$x ${outdir}/${newfile}"
    # ncea -F -d time,3143,3179,${workdir}/$x ${outdir}/${newfile} # temporal subsed
done
