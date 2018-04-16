#!/bin/bash

#-------------------
# Concatenates emission
# files using NCO 
# (netCDF operators)
#-------------------

#workdir=/data14b/buchholz/qfed/cam_0.9x1.25/from_co2/v2.5/   # working directory
workdir=/data14b/buchholz/qfed/cam_0.9x1.25/regridded/   # working directory
file_list="$(ls $workdir/2014/)"
arr=$(echo "$file_list" | sed 's/2014*.nc//g')        # remove year specific to file

#echo $arr

for x in $arr ; do
    echo ${workdir}2014/${x}2014.nc \

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
  #       ${workdir}2013/${x}2013.nc \
  ncrcat ${workdir}2014/${x}2014.nc \
         ${workdir}2015/${x}2015.nc \
         ${workdir}2016/${x}2016.nc \
         ${workdir}2017/${x}2017.nc \
         ${workdir}/allyears/${x}2014_2017.nc       # Concatenate along
done

