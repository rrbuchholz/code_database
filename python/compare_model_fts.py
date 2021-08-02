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
#from scipy.interpolate import interp1d
try:
    import scipy
    print("Imported Scipy")
except ModuleNotFoundError:
    print("2. Could not import Scipy")
#import datetime
try:
    import datetime
    print("Imported datetime")
except ModuleNotFoundError:
    print("3. Could not import datetime")
#import numpy as np
try:
    import numpy
    print("Imported numpy")
except ModuleNotFoundError:
    print("4. Could not import numpy")
#import math
try:
    import math
    print("Imported math")
except ModuleNotFoundError:
    print("5. Could not import math")
#import cartopy.crs as ccrs
#from cartopy.util import add_cyclic_point
#from cartopy import config
try:
    import cartopy
    print("Imported cartopy")
except ModuleNotFoundError:
    print("6. Could not import cartopy")
#import matplotlib.pyplot as plt
#from matplotlib import colors, mticker
try:
    import matplotlib
    print("Imported matplotlib")
except ModuleNotFoundError:
    print("7. Could not import matplotlib")
#from netCDF4 import Dataset
try:
    import netCDF4
    print("Imported netCDF4")
except:
    print("8. Could not import netCDF4")
#from pyhdf.SD import SD, SDC
try:
    import pyhdf
    print("Imported pyhdf")
except ModuleNotFoundError:
    print("9. Could not import pyhdf")

try:
    import h5py
    print("Imported h5py")
except ModuleNotFoundError:
    print("10. Could not import h5py")
<<<<<<< HEAD

=======
>>>>>>> 501d5daafbb9770fac51810cf544f70c3cbfc5c4




def main():
    #modelfile = Dataset("/home/buchholz/Documents/CAM-Chem/Output_examples/2020-03-20/atm/h1/fmerra.2.0.FCSD.1deg.chey200317.cmip.qfedBB_spin_32L.cam.h1.2013-12-01-00000.nc") 
    #print(modelfile.variables.keys())




#def find_index(array,x):
    """ 
    Find nearest index 
    """
    #idx = np.argmin(np.abs(array-x))
    #return idx


#def load_var(fileread,var):
    """
    Load HDF variable
    """
    #sds_obj = fileread.select(var)
    #ext_var = sds_obj.get()
    #return ext_var

# Call the main program
if __name__ == "__main__":
    main()
