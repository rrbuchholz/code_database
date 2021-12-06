#!/bin/bash

#-------------------
# Concatenates emission
# files using NCO 
# (netCDF operators)
#-------------------

# set up code directory
codedir=/home/buchholz/code_database/ncl_programs/data_processing

#arr=(OC BC SO4 VBS SOAG SOAG1.5)       # options
#arr=(SOAG SOAG1.5)       # options for SOAG 1.5
year_arr=(2016 2017 2018 2019 2020)     # options
arr=(SOAG SOAG1.5 VBS)       # options
#year_arr=(2016)     # options
echo ${arr[@]}
echo ${year_arr[@]}

for y in ${year_arr[@]} ; do
    echo "-----------------------------------------"
    echo "processing" ${y}
    for x in ${arr[@]} ; do
        echo "processing" ${x}
#process
        echo "ncl 'tracer="${x}"' 'timeres = "daily"' 'outres = "0.9x1.25"' 'year="${y}"' ${codedir}/redistribute_emiss_gfed.ncl"
        ncl 'tracer="'${x}'"' 'timeres = "daily"' 'outres = "0.9x1.25"' 'year="'${y}'"' ${codedir}/redistribute_emiss_gfed.ncl
    done
done
