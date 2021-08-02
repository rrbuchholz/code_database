#!/bin/bash

#-------------------
# Concatenates emission
# files using NCO 
# (netCDF operators)
#-------------------

# set up directories
workdir=/data16b/buchholz/emissions/gfed/monthly/   # working directory
#workdir=/data16b/buchholz/emissions/gfed/daily/   # working directory
codedir=/home/buchholz/code_database/ncl_programs/data_processing

#file_list="$(ls -1 ${workdir}*BIG*2018* | sed s/^.*\\/\//)" #list files without path
file_list="$(ls -1 ${workdir}*BIG*2018*c20210606.nc | sed s/^.*\\/\//)" #list files without path
#file_list="$(ls -1 ${workdir}*_2018* | sed s/^.*\\/\//)" #list files without path
#arr=$(echo "$file_list" | sed 's/_2018_native_c20210119.nc//g')        # remove year specific to file
arr=$(echo "$file_list" | sed 's/GFED4s_monthly_//g') # prefix
#arr=$(echo "$arr" | sed 's/_2018_native_c20210119.nc//g') # remove year
#arr=$(echo "$arr" | sed 's/_2018_native_c20210308.nc//g')    # remove year
arr=$(echo "$arr" | sed 's/_2018_native_c20210606.nc//g')     # remove year
#arr=$(echo "$arr" | sed 's/GFED4s_daily_//g')        # remove file beginning
echo $arr


for x in $arr ; do
    echo "-----------------------------------------"
    echo "processing" ${x}


    echo "ncl 'input_species="${x}"' 'outres="0.9x1.25"' 'timeres="monthly"' ${codedir}/regrid_gfed.ncl"
    ncl 'input_species="'${x}'"' 'outres="0.9x1.25"' 'timeres="monthly"' ${codedir}/regrid_gfed.ncl


#process daily
#    echo "ncl 'input_species="${x}"' 'outres="0.9x1.25"' 'timeres="daily"' 'year=2016' ${codedir}/regrid_gfed.ncl"
#    ncl 'input_species="'${x}'"' 'outres="0.9x1.25"' 'timeres="daily"' 'year=2016' ${codedir}/regrid_gfed.ncl

done
