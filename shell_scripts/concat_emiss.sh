#!/bin/bash

#-------------------
# Concatenates emission
# files using NCO 
# (netCDF operators)
#-------------------

# set up directories
#workdir=/data14b/buchholz/qfed/cam_0.9x1.25/from_co2/nrt/   # working directory
workdir=/data14b/buchholz/qfed/cam_0.9x1.25/from_co2/v2.5/   # working directory
#workdir=/data16b/buchholz/emissions/gfed/daily_cam_0.9x1.25
#workdir=/data16b/buchholz/emissions/gfed/monthly/
#workdir=/data14b/buchholz/qfed/cam_0.9x1.25/from_co2/nrt_template/yearly/
#workdir=/data14b/buchholz/qfed/cam_0.9x1.25/regridded/   # working directory
#workdir=/data14b/buchholz/gfas/cam_0.9x1.25/from_co2/   # working directory
#workdir=/data14b/buchholz/gfas/cam_0.9x1.25/regridded/   # working directory
#workdir=/data14b/buchholz/gfas/cam_0.9x1.25/regridded/   # working directory
#file_list="$(ls $workdir/2014_min/)"
#file_list="$(ls ${workdir}2018/*_XYLENES_2018*)"
file_list="$(ls ${workdir}2018/*.nc | sed s/^.*\\/\//)"
#file_list="$(ls -1 ${workdir}/*BIGENE_0.9x1.25_mol_2018* | sed s/^.*\\/\//)" #list files without path
arr=$(echo "$file_list" | sed 's/2018*.nc//g')        # remove year specific to file
#arr=$(echo "$file_list" | sed 's/2014*.nc//g')        # remove year specific to file
#arr=$(echo "$file_list" | sed 's/2014*.nc//g')        # remove year specific to file
#arr=$(echo "$file_list" | sed 's/2014new*.nc//g')        # remove year specific to file (gfas)

echo $arr

for x in $arr ; do
#    echo ${workdir}2014/${x}2014.nc \
    echo ${x}2018.nc \

#concatenate
  ncrcat -O ${workdir}2000/${x}2000.nc \
         ${workdir}2001/${x}2001.nc \
         ${workdir}2002/${x}2002.nc \
         ${workdir}2003/${x}2003.nc \
         ${workdir}2004/${x}2004.nc \
         ${workdir}2005/${x}2005.nc \
         ${workdir}2006/${x}2006.nc \
         ${workdir}2007/${x}2007.nc \
         ${workdir}2008/${x}2008.nc \
         ${workdir}2009/${x}2009.nc \
         ${workdir}2010/${x}2010.nc \
         ${workdir}2011/${x}2011.nc \
         ${workdir}2012/${x}2012.nc \
         ${workdir}2013/${x}2013.nc \
         ${workdir}2014/${x}2014.nc \
         ${workdir}2015/${x}2015.nc \
         ${workdir}2016/${x}2016.nc \
         ${workdir}2017/${x}2017.nc \
         ${workdir}2018/${x}2018.nc \
         ${workdir}2019/${x}2019.nc \
         ${workdir}2020/${x}2020.nc \
         ${workdir}2021/${x}2021.nc \
         ${workdir}/allyears/${x}2000_2021.nc       # Concatenate along
#         ${workdir}/${x}2000_2021_c20210308.nc       # Concatenate along
# Create a climatology
#    nces ${x}2000.nc \
#         ${x}2001.nc \
#         ${x}2002.nc \
#         ${x}2003.nc \
#         ${x}2004.nc \
#         ${x}2005.nc \
#         ${x}2006.nc \
#         ${x}2007.nc \
#         ${x}2008.nc \
#         ${x}2009.nc \
#         ${x}2010.nc \
#         ${x}2011.nc \
#         ${x}2012.nc \
#         ${x}2013.nc \
#         ${x}2014.nc \
#         ${x}2015.nc \
#         ${x}2016.nc \
#         ${x}2017.nc \
#         ${x}2018.nc \
#         ${x}2000_2018_climatology.nc       # Concatenate along
#         ${workdir}2019/${x}2019.nc \
#         ${workdir}2020/${x}2020.nc \
#         ${workdir}allyears/${x}2000_2020.nc       # Concatenate along
#ncrcat    ${x}2020.nc \
#          ${x}2021.nc \
#          ${x}2022.nc \
#          ${x}2020_2022.nc       # Concatenate along
done
