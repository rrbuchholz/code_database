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


#-------------------------------------
# Load model climatology
model_dir = "/net/modeling1/data16a/buchholz/gaubert_reanalysis_2017/climatology/"
model_files = "/net/modeling1/data16a/buchholz/gaubert_reanalysis_2017/climatology/Gaubert_reanalysis_month01_2003_2013.nc"

nc_load = xr.open_dataset(model_files)
model_var = nc_load['CO']

#-------------------------------------
# Load measurements

result_dir = Path("/MOPITT/V8J/Archive/L3/202001/month/")
file = "MOP03JM-202001-L3V95.6.3.he5"
file_to_open = result_dir / file

test = h5filedump(str(file_to_open))

print(test)
he5_load = h5py.File(file_to_open, mode='r')
dataset_apriori = he5_load["/HDFEOS/GRIDS/MOP03/Data Fields/APrioriCOMixingRatioProfileNight"][:]
dataset = he5_load["/HDFEOS/GRIDS/MOP03/Data Fields/RetrievedCOTotalColumnDay"][:]
print(dataset_apriori)

#-------------------------------------
# Regrid to MOPITT horizontal location



#-------------------------------------
# Vertical regrid



#-------------------------------------
# Apply AK


#-------------------------------------
# Average region


#-------------------------------------
# Write timeseries out to csv
