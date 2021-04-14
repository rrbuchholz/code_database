# By line: RRB 2020-07-29
# Script aims to:
# - Load multiple netCDF files
# - Extract one variable: CO
# - Choose a specific location from model grid
# - Plot timeseries
# - Customize visualization

import pandas as pd
from pandas.tseries.offsets import DateOffset
import xarray as xr
import matplotlib.pyplot as plt
import cartopy.crs as ccrs                 # For plotting maps
import cartopy.feature as cfeature         # For plotting maps
import numpy as np
from scipy.interpolate import griddata
import datetime
import csv
import h5py                                # For loading he5 files
from pathlib import Path                   # System agnostic paths


#-------------------------------------
# Local functions
from utilities.readdata import h5filedump

#-------------------------------------
# Define functions


#-------------------------------
#CONSTANTS and conversion factor
#-------------------------------
NAv = 6.0221415e+23                       #--- Avogadro's number
g = 9.81                                  #--- m/s - gravity
MWair = 28.94                             #--- g/mol
xp_const = (NAv* 10)/(MWair*g)*1e-09      #--- scaling factor for turning vmr into pcol
                                          #--- (note 1*e-09 because in ppb)

#-------------------------------------
# Load model climatology
model_dir = "/net/modeling1/data16a/buchholz/gaubert_reanalysis_2017/climatology/"
model_files = "/net/modeling1/data16a/buchholz/gaubert_reanalysis_2017/climatology/Gaubert_reanalysis_month01_2003_2013.nc"
nc_load = xr.open_dataset(model_files)

model_var = nc_load['CO']

# Load values to create true model pressure array
psurf = nc_load['PS'].isel(time=0)
hyam = nc_load['hyam']
hybm = nc_load['hybm']
p0 = nc_load['P0']
lev = var_sel.coords['lev']
num_lev = lev.shape[0]

# Initialize pressure edge arrays
mod_press_low = xr.zeros_like(model_var)
mod_press_top = xr.zeros_like(model_var)

# Calculate pressure edge arrays
# CAM-chem layer indices start at the top and end at the bottom
for i in range(num_lev):
    mod_press_top[i,:,:] = hyai[i]*p0 + hybi[i]*psurf
    mod_press_low[i,:,:] = hyai[i+1]*p0 + hybi[i+1]*psurf

# Delta P in hPa
mod_deltap = (mod_press_low - mod_press_top)/100
#print(mod_press_low[:,0,0])
#print(mod_press_top[:,0,0])
#print(mod_deltap[:,0,0])

#-------------------------------------
# Create model total column
print(model_var.lev)

import sys
sys.exit()

#-------------------------------------
# Create model column average VMR

column_dry_air = psurf * 

#-------------------------------------
# Load measurements

result_dir = Path("/MOPITT/V8J/Archive/L3/202001/month/")
file = "MOP03JM-202001-L3V95.6.3.he5"
file_to_open = result_dir / file

test = h5filedump(str(file_to_open))

print(test)
he5_load = h5py.File(file_to_open, mode='r')
dataset = he5_load["/HDFEOS/GRIDS/MOP03/Data Fields/RetrievedCOTotalColumnDay"][:]
print(dataset)

#-------------------------------------
# Regrid model to MOPITT horizontal res



#-------------------------------------
# Mask MOPITT missing values



#-------------------------------------
# Collect region



#-------------------------------------
# Remove seasonal cycle




#-------------------------------------
# Write timeseries out to csv



