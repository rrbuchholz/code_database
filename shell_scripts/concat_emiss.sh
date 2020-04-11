#!/bin/bash

#-------------------
# Concatenates emission
# files using NCO 
# (netCDF operators)
#-------------------

# set up directories
#workdir=/data14b/buchholz/qfed/cam_0.9x1.25/from_co2/nrt/   # working directory
workdir=/data14b/buchholz/qfed/cam_0.9x1.25/from_co2/v2.5/   # working directory
#workdir=/data14b/buchholz/qfed/cam_0.9x1.25/regridded/   # working directory
#workdir=/data14b/buchholz/gfas/cam_0.9x1.25/from_co2/   # working directory
#workdir=/data14b/buchholz/gfas/cam_0.9x1.25/regridded/   # working directory
#workdir=/data14b/buchholz/gfas/cam_0.9x1.25/regridded/   # working directory
file_list="$(ls $workdir/2014_min/)"
#file_list="$(ls ${workdir}*2018*)"
#arr=$(echo "$file_list" | sed 's/2018*.nc//g')        # remove year specific to file
arr=$(echo "$file_list" | sed 's/2014*.nc//g')        # remove year specific to file
#arr=$(echo "$file_list" | sed 's/2014*.nc//g')        # remove year specific to file
#arr=$(echo "$file_list" | sed 's/2014new*.nc//g')        # remove year specific to file (gfas)

echo $arr
for x in $arr ; do
#    echo ${workdir}2014/${x}2014.nc \
    echo ${x}2014.nc \

#concatenate
  #ncrcat ${workdir}2000/${x}2000.nc \
  #       ${workdir}2001/${x}2001.nc \
  #       ${workdir}2002/${x}2002.nc \
  #       ${workdir}2003/${x}2003.nc \
  #       ${workdir}2004/${x}2004.nc \
  #       ${workdir}2005/${x}2005.nc \
  #       ${workdir}2006/${x}2006.nc \
  #       ${workdir}2007/${x}2007.nc \
  #       ${workdir}2008/${x}2008.nc \
  #       ${workdir}2009/${x}2009.nc \
  #       ${workdir}2010/${x}2010.nc \
  #       ${workdir}2011/${x}2011.nc \
  #       ${workdir}2012/${x}2012.nc \
  ncrcat ${workdir}2013_min/${x}2013.nc \
         ${workdir}2014_min/${x}2014.nc \
         ${workdir}2015_min/${x}2015.nc \
         ${workdir}2016_min/${x}2016.nc \
         ${workdir}allyears/${x}2013_2016.nc       # Concatenate along
 #        ${workdir}2017/${x}2017.nc \
 #        ${workdir}2018/${x}2018.nc \
 #        ${workdir}2019/${x}2019.nc \
#ncrcat    ${x}2018.nc \
#          ${x}2019.nc \
#          ${x}2020.nc \
#          ${x}2018_2020.nc       # Concatenate along
done
