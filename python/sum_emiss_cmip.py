# RRB 2020-08-08
# python3 code
# Sum gridded files of emissions - created for GFAS
# To run: python3 sum_emissions_monthly.py
# on cheyenne: module load python
#              ncar_pylib

import numpy as np
import pandas as pd
from netCDF4 import Dataset
import xarray as xr
import datetime as dt
import h5py
import os

#----------------------------------------------------
# User input
#----------------------------------------------------
#directory    = '/glade/p/acom/acom-climate/tilmes/emis/CAMS_Anthro_f09_f09/2000_2020/'
directory    = '/glade/p/acom/MUSICA/emissions/cams/CAMS-GLOB-ANTv4.2_R1.1/f09/2008_2020/'
#directory    = '/glade/work/emmons/emis/cmip6_2000_2018/'
#directory    = '/glade/p/cesm/wawg/inputdata/CMIP6/emis/hist/'
#directory    = '/glade/p/cesmdata/cseg/inputdata/atm/cam/chem/emis/CMIP6_emissions_1750_2015/'
#directory    = '/glade/p/cesmdata/cseg/inputdata/atm/cam/chem/emis/emissions_ssp245/'
start_year = 2010
end_year   = 2019
species_target = 'NH3' 

#fname = directory + 'emissions-cmip6_'+species_target+'_anthro_surface_2000-2018_0.9x1.25.nc'
#fname = directory + 'CAMS-GLOB-ANT_Glb_0.9x1.25_anthro_surface_'+species_target+'_v3.1_c20200120.nc'
fname = directory + 'CAMS-GLOB-ANT_Glb_0.9x1.25_anthro_surface_'+species_target+'_v4.2_c20200817.nc'
#varname = 'emiss_anthro'
varname = 'emiss_ship'

#fname = directory + 'emissions-cmip6_'+species_target+'_other_surface_1750-2015_0.9x1.25_c20170322.nc'
#fname = directory + 'emissions-cmip6_'+species_target+'_other_surface_2000-2018_0.9x1.25.nc'
#fname = directory +species_target+'-em-anthro_input4MIPs_emissions_CMIP_CEDS-2017-05-18_gn_200001-201412.nc'
#NH3-em-AIR-anthro_input4MIPs_emissions_CMIP_CEDS-2017-05-18_gn_200001-201412.nc
#NH3-em-anthro_input4MIPs_emissions_CMIP_CEDS-2017-05-18_gn_200001-201412.nc
#NH3-em-SOLID-BIOFUEL-anthro_input4MIPs_emissions_CMIP_CEDS-2017-05-18-supplemental-data_gn_200001-201412.nc
#varname = 'NH3_em_anthro'
#varname = 'emiss_soils'
#varname = 'emiss_oceans'

#fname = directory + 'emissions-cmip6_'+species_target+'_bb_surface_1750-2015_0.9x1.25_c20170322.nc'
#fname = directory + 'emissions-cmip6-ScenarioMIP_IAMC-MESSAGE-GLOBIOM-ssp245-1-1_'+species_target+'_bb_surface_mol_175001-210101_0.9x1.25_c20190222.nc'
#fname = directory + 'emissions-cmip6-ScenarioMIP_IAMC-MESSAGE-GLOBIOM-ssp245-1-1_'+species_target+'x1.5_bb_surface_mol_175001-210101_0.9x1.25_c20200403.nc'
#varname = 'emiss_bb'
#varname = 'num_so4_a1_bb'



#----------------------------------------------------
# Setup
#----------------------------------------------------
# constants
NAv = 6.022e23                      # Avogadro's number, molecules mole^-1
re=6.37122e06                       # Earth radius (in metres)
rad=4.0 * np.arctan(1.0) / 180.0    # Convert degrees to radians (pi radians per 180 deg)
con  = re * rad                     # constant for determining arc length 

# load molecular weights
if (species_target == 'SOAG' or species_target == 'SOAGx1.5' or species_target == 'SOAGx1.5x2'):
    mw_var = 12.011
elif (species_target == 'bc_a4' or species_target == 'pom_a4'):
    mw_var = 12.011
elif (species_target == 'BENZENE'):
    mw_var = 78.1134
elif (species_target == 'XYLENES'):
    mw_var = 106.167
elif (species_target == 'MTERP'):
    mw_var = 136.228
elif (species_target == 'so4_a1'):
    # CAM-chem reads SO4 as NH4HSO4 in MAM (mw_so4 for BAM is 96)
    mw_var = 115.   
    #mw_var = 96.0636
elif (species_target == 'num_bc_a4'):
    diam = 0.134e-06 
    PI  =  np.pi
    mw = 12.011
    rho_BC = 1700.
    mass_particle = rho_BC *(PI/6.)*(diam)**3       #mass per particle (kg/particle)
    mw_var = mass_particle/mw
elif (species_target == 'num_pom_a4'):
    diam = 0.134e-06 
    PI  =  np.pi
    mw = 12.011
    rho_BC = 1000.
    mass_particle = rho_BC *(PI/6.)*(diam)**3       #mass per particle (kg/particle)
    mw_var = mass_particle/mw
elif (species_target == 'num_so4_a1'):
    diam = 0.134e-06 
    PI  =  np.pi
    mw = 115.
    rho_BC = 1770.
    mass_particle = rho_BC *(PI/6.)*(diam)**3       #mass per particle (kg/particle)
    mw_var = mass_particle/mw
else:
    mw_file = "/glade/u//home/buchholz/data/species_molwts.txt"
    mw_data = pd.read_csv(mw_file,header=None,skiprows=2,delim_whitespace=True,low_memory=False)
    mw_data.columns=['species','MW']
    mw_var = mw_data.MW[mw_data.species==species_target].values
print(species_target+" MW: "+str(mw_var))

# monthdays array
monthdays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

#----------------------------------------------------
# Load file
#----------------------------------------------------

f = xr.open_dataset(fname)
emis = f[varname]

lat = f.lat
lon = f.lon


# create an area weight array
dlon = abs(lon[2].values-lon[1].values)
dlat = abs(lat[2].values-lat[1].values)
clat = np.cos(lat * rad)            # cosine of latitude
dx = con * dlon * clat              #dx (in metres) at each latitude
dy = con * dlat                     #dy (in metres) is constant
dydx = dy * dx                      #dydx(nlat)

#grid_weight = xr.zeros_like(emis[0,0,:,:])
grid_weight = xr.zeros_like(emis[0,:,:])
for x in range(emis.lon.shape[0]):
     grid_weight[:,x] = dydx
print(grid_weight.shape)


#----------------------------------------------------
# Main
#----------------------------------------------------
# make table to store summed DM emissions for each region, year, and source
var_table = np.zeros((1,12*(end_year - start_year + 1))) # region, year
#var_table = np.zeros((8,12*(end_year - start_year + 1))) # region, year
date = np.zeros(12*(end_year - start_year + 1),dtype=int)

# create mask for summing over a region
mask = np.ones((lat.shape[0], lon.shape[0]))

#                   minlat, maxlat, minlon, maxlon
#region_select = (/(/37.,    41.,    251.,    258./),\ ;Colorado CMIP
#region_select = (/(/37.,    41.,   -109.,   -102./),\ ;Colorado CEDS
print(lat)
mask[:,np.argwhere(np.array(lon)<251)] = 0
mask[:,np.argwhere(np.array(lon)>258)] = 0
#mask[:,np.argwhere(np.array(lon)<-109)] = 0
#mask[:,np.argwhere(np.array(lon)>-102)] = 0
mask[np.argwhere(np.array(lat)<37),:] = 0
mask[np.argwhere(np.array(lat)>41),:] = 0  
#print(mask)
#import sys
#sys. exit()    

for year in range(start_year, end_year+1):
    print(year)
    emis_year = emis.loc[str(year)]

    #grid_area = xr.zeros_like(emis)
    dummy,grid_area = xr.broadcast(emis_year,grid_weight)
    
    #replace Feb daycount
    monthdays[1]=pd.Period(str(year)+'-2').days_in_month

    # multiply by area weights and sum
    print(grid_weight.shape)
    print(grid_area.shape)
    print(emis_year.shape)
    

    for month in range(0, 12):
        date[month+12*(year-start_year)] = year*100 + month+1
        #emis_year[month,:,:,:] = emis_year[month,:,:,:]*monthdays[month]
        emis_year[month,:,:] = emis_year[month,:,:]*monthdays[month]
        #emis_year[month,:,:] = (emis_year[month,:,:]/1E31*1.65979e-23)*monthdays[month]

#    for r in range(0, 8):
#        var_table[r,(year-start_year)*12:((year-start_year)*12+12)] = np.sum(grid_area*mask*emis_year, axis=(2,3))[:,r]

    var_table[0,(year-start_year)*12:((year-start_year)*12+12)] = np.sum(grid_area*mask*emis_year, axis=(1,2))

# original units = molecules/cm2/s
# converted to g m**-2 d**-1
# original units = kg m-2 s-1
# converted to g m**-2 d**-1
var_table = (var_table*mw_var)/(NAv)
var_table = (var_table*86400*10000)
#var_table = (var_table*86400*1000)
#var_table = (var_table*mw_var)
#var_table = (var_table*86400*10000)*1E31

var_table = var_table / 1E12
print(var_table.shape[1])
for d in range(0, var_table.shape[1]):
# convert to Tg CO 
    print(f'{date[d]}', var_table[0,d])

#import sys
#sys. exit()


    #----------------------------------------------------
    # Calculations
    #---------------------------------------------------- 
    # fill table with total values for the globe (row 15) or basisregion (1-14)
   # for region in range(15):
   #     if region == 14:
   #         mask = np.ones((720, 1440))
   #     else:
   #         mask = basis_regions == (region + 1)            
   # 
   #     var_table[region, year-start_year] = np.sum(grid_area * mask * var_emissions)
   #     
   # print(year)
        

