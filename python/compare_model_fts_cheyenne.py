#! /usr/bin/env python
# -*- coding: utf-8 -*-

"""
  Code aims
  1. Load measurement
  2. Get date/s of model values
  3. Load model
  4. Get correct model location or measurement (interpolate)
  5. Transform to correct model pressure using psurf, hyam, hybm, P0
  6. Interpolate to FTS layers
  7. Load and plot measurement a priori and load AK
  8. Smooth by AK and plot
  9. Pressure weighted sum to convert profile to column values
  10. Load measured column and plot against model column (smooth and unsmoothed)

Author:- Rebecca Buchholz © Copyright 2020 ACOM / UCAR
"""

#import shapely
try:
    import shapely
    print("Imported shapely")
except ModuleNotFoundError:
    print("1. Could not import shapely")
#import scipy
try:
    import scipy
    print("Imported Scipy")
    from scipy.interpolate import interp1d
except ModuleNotFoundError:
    print("2. Could not import Scipy")
#import datetime
try:
    import datetime
    print("Imported datetime")
except ModuleNotFoundError:
    print("3. Could not import datetime")
#import numpy
try:
    import numpy as np
    print("Imported numpy")
except ModuleNotFoundError:
    print("4. Could not import numpy")
#import math
try:
    import math
    print("Imported math")
except ModuleNotFoundError:
    print("5. Could not import math")
#import cartopy
try:
    import cartopy
    print("Imported cartopy")
    import cartopy.crs as ccrs
    from cartopy.util import add_cyclic_point
    from cartopy import config
except ModuleNotFoundError:
    print("6. Could not import cartopy")
#import matplotlib
try:
    import matplotlib
    print("Imported matplotlib")
    import matplotlib.pyplot as plt
    import matplotlib.colors as colors
    import matplotlib.ticker as mticker
except ModuleNotFoundError:
    print("7. Could not import matplotlib")
#from netCDF4 import Dataset
try:
    import netCDF4
    print("Imported netCDF4")
    from netCDF4 import Dataset
except ModuleNotFoundError:
    print("8. Could not import netCDF4")
#from pyhdf
try:
    import pyhdf
    print("Imported pyhdf")
    from pyhdf.SD import SD, SDC
except ModuleNotFoundError:
    print("9. Could not import pyhdf")


# main code
def main():
    # Load model file
    modelfile = Dataset("/glade/scratch/shawnh/GEOS5_frcst_data_Beta/20200605/model_files/finn/f.e22.beta02.FWSD.f09_f09_mg17.cesm2_2_beta02.forecast.001.cam.h3.2020-06-05-00000.nc") 
    print(modelfile.variables.keys())

    model_lat = modelfile.variables['lat'][:]
    model_lon = modelfile.variables['lon'][:]
    model_hyam = modelfile.variables['hyam'][:]
    model_hybm = modelfile.variables['hybm'][:]
    model_p0 = modelfile.variables['P0'][:]
    model_psurf = modelfile.variables['PS'][0,:,:]
    model_tracer = modelfile.variables['CO'][0,:,:,:]

    # Load measurement
    loc_psurf = 980


    index_lat = find_index(model_lat,40)
    # need to account for +/- lon versus 0-360 lon
    index_lon = find_index(model_lon,150)
    print(model_lon[index_lon])
    tracer_prof = model_tracer[:,index_lat,index_lon]*1e9 #mol/mol -> ppb
    loc_psurf = model_psurf[index_lat,index_lon] #Pa

    # calculate model pressure levels
    model_press = (model_hyam*model_p0 + model_hybm*loc_psurf)/100 #Pa -> hPa


    # Find index where measured level is equal to model level
    index_top = find_index(model_press,1)

    # Mask the measure data above top model level
    model_press[0:index_top] = np.nan
    tracer_prof[0:index_top]= np.nan

    # Plot the profile
    # Increase default size of working space
    plt.figure(figsize=(6,8))

    plt.plot(tracer_prof, model_press, '-ok', label='CO',
             color='blue',
             markersize=8, linewidth=3,
             markerfacecolor='blue',
             markeredgecolor='grey',
             markeredgewidth=1)
    plt.title('CO from CAM-chem at Boulder')        
    plt.xlabel('CO (ppb)')
    plt.ylabel('Altitude (hPa)')
    plt.legend()
    plt.gca().invert_yaxis()
    plt.show() 


def find_index(array,x):
    """ 
    Find nearest index 
    """
    idx = np.argmin(np.abs(array-x))
    return idx


def load_var(fileread,var):
    """
    Load HDF variable
    """
    sds_obj = fileread.select(var)
    ext_var = sds_obj.get()
    return ext_var

# Call the main program
if __name__ == "__main__":
    main()
