#!/bin/bash

#-------------------
# Extract temporal subset from
# emission files using NCO 
# and change dates
# (netCDF operators).
#-------------------

# set up directories and input files
workdir=/glade/work/emmons/emis/cmip6_2000_2018/   # working directory
outdir=/glade/work/buchholz/emis/test   # out directory

file_list="$(ls ${workdir}*.nc)"
arr=$(echo "$file_list" | sed 's/*2000-2018*.nc//g')        # remove year specific to file

echo $arr

for x in $arr ; do
    newfile_a=$(echo $x | sed 's/\/glade\/work\/emmons\/emis\/cmip6_2000_2018\///')
    newfile=$(echo $newfile_a | sed 's/2000-2018/2018-2019/')
    echo ${newfile}
    # Time variable is the index numbers of time to extract
    echo "ncea -F -d time,204,228 $x ${outdir}/${newfile}"
    ncea -F -d time,204,228 $x ${outdir}/${newfile} # temporal subset
done





