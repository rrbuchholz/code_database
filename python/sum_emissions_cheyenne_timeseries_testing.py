# RRB 2020-08-08
# python3 code
# Sum gridded files of emissions
# To run: python3 sum_emissions_cheyenne_timeseries.py
# on cheyenne do this first:
#              execdav
#              module load python
#              ncar_pylib

import numpy as np
import pandas as pd
from netCDF4 import Dataset
import xarray as xr
import datetime as dt
import h5py
import os
import matplotlib
#matplotlib.use('GTK3Agg')
import matplotlib.pyplot as plt
import cartopy.crs as ccrs                 # For plotting maps
import cartopy.feature as cfeature         # For plotting maps
from cartopy.util import add_cyclic_point  # For plotting maps

#----------------------------------------------------
# User input
#----------------------------------------------------
start_year = 2014
end_year   = 2025
species_target = 'bc_a4'
emistype = 'bb'

# Acetone: 'CH3COCH3' FINN, small is 'acet' QFED, exceptions: 'Acet' FEER, 'c3h6o' GFAS, 'C3H6O' GFED
# others are the same with letters as small case

#----------------------------------------------------
# Setup
#----------------------------------------------------
# constants
NAv = 6.022e23                      # Avogadro's number, molecules mole^-1
re=6.37122e06                       # Earth radius (in metres)
rad=4.0 * np.arctan(1.0) / 180.0    # Convert degrees to radians (pi radians per 180 deg)
con  = re * rad                     # constant for determining arc length 

# load molecular weights
if (species_target == 'SOAG'or species_target == 'IVOC'
    or species_target == 'SOAG1.5'):
    mw_var = 12.011
elif (species_target == 'SVOC'):
    mw_var = 310.
elif (species_target == 'bc_a4' or species_target == 'pom_a4' or species_target == 'PM2.5'):
    mw_var = 12.011
elif (species_target == 'SO2_orig'):
    mw_var = 64.0648
elif (species_target == 'so4_a1'):
    # CAM-chem reads SO4 as NH4HSO4 in MAM (mw_so4 for BAM is 96)
    mw_var = 115
    #mw_var = 96.0636
elif (species_target == 'NOx'):
    # Most inventories describe NOx as NO
    mw_var = 30.0061 
elif (species_target == 'CH3CN'):
    mw_var = 41.0527
elif (species_target == 'C2H2'):
    mw_var = 26.04
elif (species_target == 'BENZENE'):
    mw_var = 78.1134
elif (species_target == 'XYLENES'):
    mw_var = 106.167
elif (species_target == 'HCN'):
    mw_var = 27.0253
elif (species_target == 'HCOOH'):
    mw_var = 46.0248
elif (species_target == 'MTERP'):
    mw_var = 136.228
else:
    mw_file = "/glade/u/home/buchholz/data/species_molwts.txt"
    mw_data = pd.read_csv(mw_file,header=None,skiprows=2,delim_whitespace=True,low_memory=False)
    mw_data.columns=['species','MW']
    mw_var = mw_data.MW[mw_data.species==species_target].values
print(species_target+" MW: "+str(mw_var))

# monthdays array
monthdays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

# load basis regions
f_basis = xr.open_dataset('/glade/u/home/buchholz/data/GFEDbasis_regions.nc')
basis_regions = f_basis['GFED basis regions']

# reorder so the regridding will work
basis_regions['lon'] = ((basis_regions.coords['lon']+ 360) % 360)
basis_regions = basis_regions.sortby(basis_regions.lon)
basis_regions = basis_regions.sortby(basis_regions.lat)

# Region names array
region_names = ('World', 'BONA', 'TENA', 'CEAM', 'NHSA ', 'SHSA', 'EURO', 'MIDE', 'NHAF', 'SHAF', 'BOAS', 'CEAS', 'SEAS', 'EQAS', 'AUST', '')

#----------------------------------------------------
# Setup summing function
#----------------------------------------------------
def sum_emiss(emis, start_year, end_year, basis_regions):
    lat = emis.lat
    lon = emis.lon
    #print(lat)
    #print(lon)
    # regrid the GFED basis regions
    basis_regions_regrid = basis_regions.reindex(lat=lat, lon=lon, method='nearest')
    #return emiss_table
    # create an area weight array
    dlon = abs(lon[2].values-lon[1].values)
    dlat = abs(lat[2].values-lat[1].values)
    clat = np.cos(lat * rad)            # cosine of latitude
    dx = con * dlon * clat              #dx (in metres) at each latitude
    dy = con * dlat                     #dy (in metres) is constant
    dydx = dy * dx                      #dydx(nlat)

    grid_weight = xr.zeros_like(emis[0,:,:])
    for x in range(emis.lon.shape[0]):
        grid_weight[:,x] = dydx
    #print(grid_weight.shape)

    # make table to store summed DM emissions for each region, year, and source
    var_table = np.zeros((16,(end_year - start_year + 1))) # region, year

    for year in range(start_year, end_year+1):
        #print(year)
        emis_year = emis.loc[str(year)]

        #grid_area = xr.zeros_like(emis)
        dummy,grid_area = xr.broadcast(emis_year.time,grid_weight)

        #replace Feb daycount
        monthdays[1]=pd.Period(str(year)+'-2').days_in_month

        # multiply by area weights and sum
        #print(grid_weight.shape)
        #print(grid_area.shape)
        #print(emis_year.shape)
    
        for month in range(0, 12):
            emis_year[month,:,:] = emis_year[month,:,:]*monthdays[month]

        # World mask
        mask = np.ones((lat.shape[0], lon.shape[0]))
        var_table[0,year-start_year] = np.sum(grid_area*mask*emis_year)
        # Region sums
        for region in range(14):
            # class_0 :	Ocean \n
            # class_1 :	BONA (Boreal North America) \n
            # class_2 :	TENA (Temperate North America \n
            # class_3 :	CEAM (Central America) \n
            # class_4 :	NHSA (Northern Hemisphere South America) \n
            # class_5 :	SHSA (Southern Hemisphere South America) \n
            # class_6 :	EURO (Europe) \n
            # class_7 :	MIDE (Middle East) \n
            # class_8 :	NHAF (Northern Hemisphere Africa) \n
            # class_9 :	SHAF (Southern Hemisphere Africa) \n
            # class_10 : BOAS (Boreal Asia) \n
            # class_11 : CEAS (Central Asia) \n
            # class_12 : SEAS (Southeast Asia) \n
            # class_13 : EQAS (Equatorial Asia) \n
            # class_14 : AUST (Australia and New Zealand) \n
            mask = basis_regions_regrid == (region + 1)
            var_table[region+1,year-start_year] = np.sum(grid_area*mask*emis_year)

    return var_table

def region_sum(emis, basis_regions):
    lat = emis.lat
    lon = emis.lon
    #print(lat)
    #print(lon)
    # regrid the GFED basis regions
    basis_regions_regrid = basis_regions.reindex(lat=lat, lon=lon, method='nearest')
    #return emiss_table
    # create an area weight array
    dlon = abs(lon[2].values-lon[1].values)
    dlat = abs(lat[2].values-lat[1].values)
    clat = np.cos(lat * rad)            # cosine of latitude
    dx = con * dlon * clat              #dx (in metres) at each latitude
    dy = con * dlat                     #dy (in metres) is constant
    dydx = dy * dx                      #dydx(nlat)

    grid_area = xr.zeros_like(emis[:,:])
    for x in range(emis.lon.shape[0]):
        grid_area[:,x] = dydx
    #print(grid_weight.shape)

    region_sum = np.zeros((16)) # region
    # World mask
    mask = np.ones((lat.shape[0], lon.shape[0]))
    region_sum[0] = np.sum(grid_area*mask*emis)
    # Region sums
    for region in range(14):
        mask = basis_regions_regrid == (region + 1)
        region_sum[region+1] = np.sum(grid_area*mask*emis)

    return region_sum

#----------------------------------------------------
# Main
#----------------------------------------------------

#----------------------------------------------------
# SSP245
directory    = '/glade/p/cesmdata/cseg/inputdata/atm/cam/chem/emis/emissions_ssp245'
if (emistype == 'anth'):
    varname = 'emiss_anthro'
    fend = '_anthro_surface_mol_175001-210101_0.9x1.25_c20190222.nc'
else:
    varname = 'emiss_bb'
    fend = '_bb_surface_mol_175001-210101_0.9x1.25_c20190222.nc'

print("Collecting SSP245")
fname = directory+'/emissions-cmip6-ScenarioMIP_IAMC-MESSAGE-GLOBIOM-ssp245-1-1_'+species_target+fend
f = xr.open_mfdataset(fname,combine='by_coords',concat_dim='time')
emis1_dummy = f[varname].load()
emis1 = emis1_dummy.loc['2013':'2030']

ssp245 = np.zeros((16,(emis1.time.shape[0]))) # region, year
for time in range(emis1.time.shape[0]):
    print(time)
    ssp245_select = emis1[time,:,:]
    ssp245[:,time] = region_sum(ssp245_select, basis_regions)

ssp_time_vals = emis1.indexes['time'].to_datetimeindex()

#import sys
#sys. exit()

#----------------------------------------------------
# COVID
directory    = '/glade/p/cesm/chwg_dev/emmons/emissions_covid/cesm_cutSSP245_V4'
print("Collecting COVID")

varname_array = ('emiss_agriculture', 'emiss_energy', 'emiss_industry', 'emiss_transport', 'emiss_resident', 'emiss_solvents', 'emiss_waste', 'emiss_shipping')

fname = directory+'/emissions-cmip6-cutSSP245-TwoYearBlip_'+species_target+'_anthro_surface_mol_201501-210012_0.9x1.25_c20200731.nc'
f = xr.open_mfdataset(fname,combine='by_coords',concat_dim='time')

print(varname_array[0])
emis2_dummy = f[varname_array[0]].load()
for var in varname_array[1:]:
    print(var)
    emis2_load = f[var].load()
    emis2_dummy = emis2_dummy + emis2_load

emis2 = emis2_dummy.loc['2015':'2023']
#print(emis2)

covid = np.zeros((16,(emis2.time.shape[0]))) # region, year
for time in range(emis2.time.shape[0]):
    covid_select = emis2[time,:,:]
    #covid[:,time] = region_sum(covid_select, basis_regions)

covid_time_vals = emis2.indexes['time'].to_datetimeindex()

print(covid_time_vals)

#import sys
#sys. exit()

#-------------------------------------------
# GFED 
directory    = '/glade/work/buchholz/emis/tagged_emis'
print("Collecting GFED")

#gfed over Aus
varname = 'bb'
fname = directory+'/gfed/gfed.emis_'+species_target+'*_0.9x1.25_mol_2018_2020_AUST_c20200912.nc'
f1 = xr.open_mfdataset(fname,combine='by_coords',concat_dim='time')
emis_gfed_load = f1[varname].load()

#SSP245 minus Aus
varname = 'emiss_bb'
fname2 = directory+'/cmip6/ssp245.emis_'+species_target+'_bb_0.9x1.25_mol_175001-210101_NOAUST_c20200912.nc'
f2 = xr.open_mfdataset(fname2,combine='by_coords',concat_dim='time')
emis4_load2 = f2[varname].load()


emis3 = emis_gfed_load
gfed = np.zeros((16,(emis3.time.shape[0]))) # region, year
for time in range(emis3.time.shape[0]):
    gfed_select = emis3[time,:,:]
    gfed[:,time] = region_sum(gfed_select, basis_regions)
gfed_time_vals = emis3.indexes['time'].to_datetimeindex()
print(gfed_time_vals)


emis4 = emis4_load2.loc['2013':'2030']
ssp2 = np.zeros((16,(emis4.time.shape[0]))) # region, year
for time in range(emis4.time.shape[0]):
    ssp2_select = emis4[time,:,:]
    ssp2[:,time] = region_sum(ssp2_select, basis_regions)
ssp2_time_vals = emis4.indexes['time'].to_datetimeindex()

print(ssp2_time_vals)


#import sys
#sys. exit()

#----------------------------------------------------
# Convert units
#---------------------------------------------------- 
# SSP245
# in molec cm**-2 s**-1
ssp245 = (ssp245*mw_var)/(NAv)
ssp245 = (ssp245*86400*10000)
# convert to Tg CO 
ssp245 = ssp245 / 1E12
print('SSP245')
print(ssp245[0,:])

#COVID
# in molec cm**-2 s**-1
covid = (covid*mw_var)/(NAv)
covid = (covid*86400*10000)
# convert to Tg CO \
print('COVID')
covid = covid / 1E12
print(covid[0,:])

#GFED
# in molec cm**-2 s**-1
gfed = (gfed*mw_var)/(NAv)
gfed = (gfed*86400*10000)
# convert to Tg CO \
gfed = gfed / 1E12
print('GFED')
print(gfed[0,:])

#SSP fire
# in molec cm**-2 s**-1
ssp2 = (ssp2*mw_var)/(NAv)
ssp2 = (ssp2*86400*10000)
# convert to Tg CO \
ssp2 = ssp2 / 1E12
print('SSP fire')
print(ssp2[0,:])

#import sys
#sys. exit()

#----------------------------------------------------
# Plot
#---------------------------------------------------- 

#----------------
# One plot
def ts_plot(time_arr,val_arr,color_choice,label_string,linewidth,linestyle):
    plt.plot(time_arr, val_arr, '-ok', label=label_string,
         color=color_choice, markersize=10,
         linestyle=linestyle, linewidth=linewidth,
         markerfacecolor=color_choice,
         markeredgecolor='grey',
         markeredgewidth=1)

plt.figure(figsize=(20,10))
ax = plt.axes()

ts_plot(ssp_time_vals,ssp245[0,:],'blue','SSP245 fire',8,'-')
#ts_plot(covid_time_vals,covid[0,:],'blue','COVID',8,'--')
ts_plot(gfed_time_vals,gfed[0,:],'green','GFED',8,'--')
ts_plot(ssp2_time_vals,ssp2[0,:],'lightgreen','SSP245 fire - Aus fire',8,':')

#DIFFERENCE
#ts_plot(gfed_year_vals,((gfeda[0,:]-gfed[0,:])/gfed[0,:])*100,'red','GFED monthly diff',12,'-')
#ts_plot(gfed_d_year_vals,((gfed_dailya[0,:]- gfed_daily[0,:])/gfed_daily[0,:])*100,'darkred','GFED daily diff',3,'-')
#plt.title('Yearly Global emissions differnece ((new - old)/old %) of '+species_target,fontsize=24) 
#plt.ylabel(species_target+' difference (%)',fontsize=24)

# axes format
plt.xticks(fontsize=24)
#ax.set_ylim(0, 12)
#plt.yticks(np.arange(0, 0.45, step=0.05), fontsize=24)
plt.yticks(fontsize=24)

# adjust border
ax.spines["left"].set_linewidth(2.5)
ax.spines["bottom"].set_linewidth(2.5)
ax.spines["right"].set_visible(False)
ax.spines["top"].set_visible(False)

#titles
plt.title('Yearly Global emissions of '+species_target,fontsize=24)             
plt.xlabel('Year',fontsize=24)
plt.ylabel(species_target+' (Tg)',fontsize=24)

# legend
plt.legend(bbox_to_anchor=(0.75, 0.76),loc='lower right',fontsize=18)

plt.show()  

#----------------
#Sub-plots
def ts_subplot(time_arr,val_arr,color_choice,linewidth,position1,position2):
    axs[position1,position2].plot(time_arr, val_arr, '-ok',
         color=color_choice,
         markersize=6, linewidth=linewidth,
         markerfacecolor=color_choice,
         markeredgecolor='grey',
         markeredgewidth=1)
    

fig, axs = plt.subplots(4,4,sharex=True,sharey=False,figsize=(50,10))
fig.suptitle('Regional emissions of ' + species_target)

for x in range(4):
    for y in range(4):
        print(str(x)+','+str(y))
        region_index = x*4 + y

        ts_subplot(ssp_time_vals,ssp245[region_index,:],'red',5,x,y)
        #ts_subplot(covid_time_vals,covid[region_index,:],'blue',3,x,y)
        #ts_subplot(gfed_d_year_vals,gfed[region_index,:],'cornflowerblue',2,x,y)

        axs[x,y].set_title(region_names[region_index])


# Legend block
axs[3,3].legend(('SSP245', 'COVID','GFED'),loc="center")
axs[3,3].set_ylim([1,5])
axs[3,3].axis('off')

for ax in axs.flat:
    ax.set(xlabel='', ylabel='Tg '+ species_target)
    #ax.label_outer()

#plt.show()  
#plt.savefig('emissions_comparison_'+species_target+'.png', bbox_inches='tight')
#plt.close()


