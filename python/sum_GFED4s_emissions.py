# RRB 2020-07-27
# python3 code
# Create gridded files of emissions - based off the GFED python script for CO
# To run: python create_GFED4s_emissions.py
# Requires: GFED4_Emission_Factors.txt, GFED4.1s hdf files

import numpy as np
import h5py # if this creates an error please make sure you have the h5py library

#----------------------------------------------------
# User input
#----------------------------------------------------
directory    = '/data16b/buchholz/emissions/gfed/'
start_year = 2012
end_year   = 2012
species_target = "CO"

#----------------------------------------------------
# Setup
#----------------------------------------------------

months       = '01','02','03','04','05','06','07','08','09','10','11','12'
sources      = 'SAVA','BORF','TEMF','DEFO','PEAT','AGRI'

#Read in emission factors
# initialize emission factor arrays
species = [] # names of the different gas and aerosol species
EFs     = np.zeros((41, 6)) # 41 species, 6 sources

k = 0
f = open(directory+'/ancill/GFED4_Emission_Factors.txt')
while 1:
    line = f.readline()
    if line == "":
        break
        
    if line[0] != '#':
        contents = line.split()
        species.append(contents[0])
        EFs[k,:] = contents[1:]
        k += 1
                
f.close()

# we are interested in CO for this example (4th row):
EF_CO = EFs[3,:]
print(species)

# create dimension arrays
lat = np.linspace(89.875,-89.875,720)
lon = np.linspace(-179.875,179.875,1440)
time = np.zeros(12)
date = np.zeros(12,dtype=int)

#----------------------------------------------------
# Main
#----------------------------------------------------
# make table to store summed DM emissions for each region, year, and source
var_table = np.zeros((15, end_year - start_year + 1)) # region, year

# process emissions
for year in range(start_year, end_year+1):
    string = directory+'/monthly_carbon/GFED4.1s_'+str(year)+'.hdf5'
    if year >= 2017: # beta product    
        print(str(year) +' is a beta product')
        string = directory+'/monthly_carbon/GFED4.1s_'+str(year)+'_beta.hdf5'
    f = h5py.File(string, 'r')
    
    if year == start_year: # these are time invariable    
        basis_regions = f['/ancill/basis_regions'][:]
        grid_area     = f['/ancill/grid_cell_area'][:]
    
    var_emissions = np.zeros((12, 720, 1440))
    for month in range(12):
        # create time variable
        date[month] = year*100 + month+1
        # read in DM emissions
        string = '/emissions/'+months[month]+'/DM'
        DM_emissions = f[string][:]
        for source in range(6):
            # read in the fractional contribution of each source
            string = '/emissions/'+months[month]+'/partitioning/DM_'+sources[source]
            contribution = f[string][:]
            # calculate CO emissions as the product of DM emissions (kg DM per 
            # m2 per month), the fraction the specific source contributes to 
            # this (unitless), and the emission factor (g CO per kg DM burned)
            var_emissions[month,:,:] += DM_emissions * contribution * EF_CO[source]

    f.close()

    #----------------------------------------------------
    # Calculations
    #---------------------------------------------------- 
    # fill table with total values for the globe (row 15) or basisregion (1-14)
    for region in range(15):
        if region == 14:
            mask = np.ones((720, 1440))
        else:
            mask = basis_regions == (region + 1)
            #mask = (basis_regions == (14))
            print(basis_regions.shape)
            #mask[,] = False
            ix = np.isin(mask, True)
            test = np.where(ix)
            print(test)   
            print(lat[400:558])   
            print(lon[1288:1435])   
            print(lat[440:558])   
            print(lon[1288:1435])
            mask = False
            mask = False
            import sys
            sys. exit()         
    
        var_table[region, year-start_year] = np.sum(grid_area * mask * var_emissions)
        
    print(year)
        
# convert to Tg CO 
var_table = var_table / 1E12
print(var_table)



# please compare this to http://www.falw.vu/~gwerf/GFED/GFED4/tables/GFED4.1s_CO.txt


