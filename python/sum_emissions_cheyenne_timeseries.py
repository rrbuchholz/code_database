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
start_year = 2000
end_year   = 2020
species_target = 'OC'

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
# FINN1.5
directory    = '/glade/work/emmons/emis/finn1.5/2002_2018'
if (species_target == 'SVOC'):
    varname = 'bb'
else:
    varname = 'fire'

print("Collecting FINN1.5")
if (species_target == 'NOx'):
    mw_no2 = 46.0055
    fname = directory+'/emissions-finn1.5_NO_bb_surface_2002-2018_0.9x1.25.nc'
    f = xr.open_mfdataset(fname,combine='by_coords',concat_dim='time')
    emis1_dummy = f[varname].load()
    fname2 = directory+'/emissions-finn1.5_NO2_bb_surface_2002-2018_0.9x1.25.nc'
    f2 = xr.open_mfdataset(fname2,combine='by_coords',concat_dim='time')
    emis1_dummy2 = f2[varname].load()
    # units are molecules per cm^2 per second so can just add
    emis1 = emis1_dummy + emis1_dummy2
else:
    fname = directory+'/emissions-finn1.5_'+species_target+'_bb_surface_2002-2018_0.9x1.25.nc'
    f = xr.open_mfdataset(fname,combine='by_coords',concat_dim='time')
    emis1 = f[varname].load()

finn15 = np.zeros((16,(2018 - 2003 + 1))) # region, year
for year in range(2003, 2018+1):
    finn15_select = emis1.loc[str(year)]
    finn15_year = finn15_select.sum(dim='time')
    finn15[:,year-2003] = region_sum(finn15_year, basis_regions)

finn_year_vals = np.arange(2003,2018+1,1)

#----------------------------------------------------
# QFED daily files
directory    = '/glade/work/buchholz/emis/qfed2.5_finn_2000_2020_1x1'
varname = 'bb'
print("Collecting QFED")
qfed = np.zeros((16,(end_year - start_year + 1))) # region, year

if (species_target == 'NOx'):
    species_target_qfed = 'NO'
else:
    species_target_qfed = species_target

fname = directory+'/qfed.emis_'+species_target_qfed+'_0.9x1.25_mol_2000_2020.nc'
f = xr.open_mfdataset(fname,combine='by_coords',concat_dim='time')
emis2 = f[varname].load()

for year in range(start_year, end_year+1):
    qfed_select = emis2.loc[str(year)]
    qfed_year = qfed_select.sum(dim='time')
    qfed[:,year-start_year] = region_sum(qfed_year, basis_regions)

qfed_year_vals = np.arange(start_year,end_year+1,1)

#-------------------------------------------
# CMIP
directory    = '/glade/p/cesm/chwg_dev/emmons/CMIP6_emissions_1750_2015_v20170322/'
#directory    = '/glade/p/cesm/chwg_dev/emmons/CMIP6_emissions_1750_2015_FINAL/'
varname = 'emiss_bb'
print("Collecting CMIP")

file_end = '_c20170322.nc'

if (species_target == 'NOx'):
    species_target_cmip = 'NO'
    file_end = '_c20180611.nc'
elif (species_target == 'BIGENE' or species_target == 'BIGALK'):
    species_target_cmip = species_target
    file_end = '_c20170322.nc'
    #file_end = '_c20180611.nc'
elif (species_target == 'SVOC'):
    species_target_cmip = species_target
    #file_end = '_c170213.nc'
elif (species_target == 'SOAG1.5'):
    species_target_cmip = 'SOAGx1.5'
else:
    species_target_cmip = species_target

fname = directory+'emissions-cmip6_'+species_target_cmip+'_bb_surface_1750-2015_0.9x1.25'+ file_end
print(fname)
f = xr.open_mfdataset(fname,combine='by_coords',concat_dim='time')
emis3 = f[varname].load()
print(emis3.shape)

cmip = sum_emiss(emis3, 2000, 2014, basis_regions)
cmip_year_vals = np.arange(2000,2014+1,1)


#-------------------------------------------
# GFED 
directory    = '/glade/p/acom/MUSICA/emissions/gfed/f09_monthly'
varname = 'bb'
#gfed = np.zeros((16,(end_year - start_year + 1))) # region, year
print("Collecting GFED")

if (species_target == 'NOx'):
    species_target_gfed = 'NO'
elif (species_target == 'CH3CN'):
    species_target_gfed = 'CH3CN_scaledCO'
    #species_target_gfed = 'CH3CN'
else:
    species_target_gfed = species_target

fname = directory+'/gfed.emis_'+species_target_gfed+'_0.9x1.25_mol_2010_2020_c20210121.nc'
#fname = '/glade/work/buchholz/emis/test/gfed.emis_SVOC_b_0.9x1.25_mol_2010_2020_c20210121.nc'
f = xr.open_mfdataset(fname,combine='by_coords',concat_dim='time')
emis4 = f[varname].load()

gfed = sum_emiss(emis4, 2010, 2019, basis_regions)
gfed_year_vals = np.arange(2010,2019+1,1)

#-------------------------------------------
# GFED2 
varname = 'bb'
print("Collecting GFED -2 ")

if (species_target == 'NOx'):
    species_target_gfed = 'NO'
elif (species_target == 'CH3CN'):
    species_target_gfed = 'CH3CN'
else:
    species_target_gfed = species_target

#fname = '/glade/work/buchholz/emis/test/gfed.emis_SVOC_0.9x1.25_mol_2010_2020_c20210121.nc'
#fname = '/glade/work/buchholz/emis/test/gfed.emis_SVOCb_0.9x1.25_mol_2010_2020_c20210121.nc'
fname = '/glade/work/buchholz/emis/test/gfed.emis_'+species_target_gfed+'_0.9x1.25_mol_2010_2020_c20210308.nc'
#f = xr.open_mfdataset(fname,combine='by_coords',concat_dim='time')
#emis4a = f[varname].load()
print('***********')
#print(emis4a)

#gfeda = sum_emiss(emis4a, 2010, 2019, basis_regions)


#-------------------------------------------
# GFED daily
directory    = '/glade/p/acom/MUSICA/emissions/gfed/f09_daily'
varname = 'bb'
gfed_daily = np.zeros((16,(2020 - 2016 + 1))) # region, year
print("Collecting GFED daily")


if (species_target == 'NOx'):
    species_target_gfed_d = 'NO'
elif (species_target == 'CH3CN'):
    species_target_gfed_d = 'CH3CN_scaledCO'
    #species_target_gfed_d = 'CH3CN'
else:
    species_target_gfed_d = species_target

fname = directory+'/gfed.emis_'+species_target_gfed_d+'_0.9x1.25_mol_2016_2020_c20210129.nc'
#fname = '/glade/work/buchholz/emis/test/gfed.emis_CH3CN_scaledCO_0.9x1.25_mol_2016_2020_c20210129.nc'
f = xr.open_mfdataset(fname,combine='by_coords',concat_dim='time')
emis5 = f[varname].load()

for year in range(2016, 2020+1):
    gfed_select = emis5.loc[str(year)]
    gfed_year = gfed_select.sum(dim='time')
    gfed_daily[:,year-2016] = region_sum(gfed_year, basis_regions)

gfed_d_year_vals = np.arange(2016,2020+1,1)

#-------------------------------------------
# GFED daily - 2
directory    = '/glade/p/acom/MUSICA/emissions/gfed/f09_daily'
varname = 'bb'
gfed_dailya = np.zeros((16,(2020 - 2016 + 1))) # region, year
print("Collecting GFED daily")


if (species_target == 'NOx'):
    species_target_gfed_d = 'NO'
elif (species_target == 'CH3CN'):
    species_target_gfed_d = 'CH3CN_scaledCO'
    #species_target_gfed_d = 'CH3CN'
else:
    species_target_gfed_d = species_target

fname = '/glade/work/buchholz/emis/test/gfed.emis_'+species_target_gfed+'_0.9x1.25_mol_2016_2020_c20210308.nc'
#f = xr.open_mfdataset(fname,combine='by_coords',concat_dim='time')
#emis6 = f[varname].load()

#for year in range(2016, 2020+1):
#    gfed_select = emis6.loc[str(year)]
#    gfed_year = gfed_select.sum(dim='time')
#    gfed_dailya[:,year-2016] = region_sum(gfed_year, basis_regions)

gfed_e_year_vals = np.arange(2016,2020+1,1)

#----------------------------------------------------
# Convert units
#---------------------------------------------------- 
# FINN1.5
# in molec cm**-2 s**-1
finn15 = (finn15*mw_var)/(NAv)
finn15 = (finn15*86400*10000)
# convert to Tg CO 
finn15 = finn15 / 1E12
print('FINN1.5')
print(finn15[0,:])

#CMIP
# in molec cm**-2 s**-1
cmip = (cmip*mw_var)/(NAv)
cmip = (cmip*86400*10000)
# convert to Tg CO \
print('CMIP')
cmip = cmip / 1E12
print(cmip[0,:])

#GFED
# in molec cm**-2 s**-1
gfed = (gfed*mw_var)/(NAv)
gfed = (gfed*86400*10000)
# convert to Tg CO \
gfed = gfed / 1E12
print('GFED')
print(gfed[0,:])

#GFED2
# in molec cm**-2 s**-1
#gfeda = (gfeda*mw_var)/(NAv)
#gfeda = (gfeda*86400*10000)
# convert to Tg CO \
#gfeda = gfeda / 1E12
#print('GFEDa')
#print(gfeda[0,:])

#GFED - daily
# in molec cm**-2 s**-1
gfed_daily = (gfed_daily*mw_var)/(NAv)
gfed_daily = (gfed_daily*86400*10000)
# convert to Tg CO \
gfed_daily = gfed_daily / 1E12
print('GFED daily')
print(gfed_daily[0,:])

#GFED - daily
# in molec cm**-2 s**-1
gfed_dailya = (gfed_dailya*mw_var)/(NAv)
gfed_dailya = (gfed_dailya*86400*10000)
# convert to Tg CO \
gfed_dailya = gfed_dailya / 1E12
print('GFED daily')
print(gfed_dailya[0,:])

#QFED - daily
# in molec cm**-2 s**-1
qfed = (qfed*mw_var)/(NAv)
qfed = (qfed*86400*10000)
# convert to Tg CO 
qfed = qfed / 1E12
print('QFED')
print(qfed[0,:])


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

ts_plot(finn_year_vals,finn15[0,:],'seagreen','FINNv1.5',8,'-')
#ts_plot(year_vals,finn2_modvrs[0,:],'black','FINNv2.2')
#ts_plot(year_vals,finn2_mod[0,:],'grey','FINNv2.2m')
#ts_plot(year_vals,feer[0,:],'cornflowerblue','FEER')
#ts_plot(year_vals,gfas[0,:],'green','GFAS')
#ts_plot(year_vals,gfed[0,:],'orange','GFED4s')
ts_plot(qfed_year_vals,qfed[0,:],'darkorchid','QFED',8,'-')
ts_plot(cmip_year_vals,cmip[0,:],'cornflowerblue','CMIP6', 18, '-')
#ts_plot(gfed_year_vals,gfeda[0,:],'red','GFED - Louisa process ',15,'-')
#ts_plot(gfed_year_vals,gfeda[0,:],'red','GFED - NEW ',12,'-')
ts_plot(gfed_year_vals,gfed[0,:],'gray','GFED',8,'--')
ts_plot(gfed_d_year_vals,gfed_daily[0,:],'black','GFED daily',3,'-')
#ts_plot(gfed_e_year_vals,gfed_dailya[0,:],'darkred','GFED daily - NEW',3,'-')

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
plt.legend(bbox_to_anchor=(0.25, 0.36),loc='lower right',fontsize=18)

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

        #ts_subplot(year_vals,finn2_modvrs[region_index,:],'black',x,y)
        #ts_subplot(year_vals,finn2_mod[region_index,:],'grey',x,y)
        ts_subplot(cmip_year_vals,cmip[region_index,:],'silver',5,x,y)
        ts_subplot(gfed_year_vals,gfed[region_index,:],'gray',3,x,y)
        ts_subplot(gfed_d_year_vals,gfed_daily[region_index,:],'black',2,x,y)
        ts_subplot(qfed_year_vals,qfed[region_index,:],'crimson',2,x,y)
        ts_subplot(finn_year_vals,finn15[region_index,:],'royalblue',2,x,y)
        axs[x,y].set_title(region_names[region_index])

# Legend block
axs[3,3].legend(('CMIP6', 'GFED4s','GFED4s daily', 'QFED', 'FINN1.5'),loc="center")
axs[3,3].set_ylim([1,5])
axs[3,3].axis('off')

for ax in axs.flat:
    ax.set(xlabel='', ylabel='Tg '+ species_target)
    #ax.label_outer()

plt.show()  
#plt.savefig('emissions_comparison_'+species_target+'.png', bbox_inches='tight')
#plt.close()


