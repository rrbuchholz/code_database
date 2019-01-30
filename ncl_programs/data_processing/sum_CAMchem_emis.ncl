;=======================================================;
;  sum_CAMchem_emis.ncl
;=======================================================;
;
; Concepts illustrated:
;   - load CAM emission files
;   - global sum each year and print out
;   - write region sum timeseries to netCDF
;   
;   To run type:
;         ncl sum_CAMchem_emis.ncl
;
;   Requires:
;         emission file
;                                  RRB 16 October, 2015
;=======================================================;
; load the libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------
  ystart = 2000
  yend = 2015
  reso = "0.9x1.25"

  machine = "modeling1"        ; modeling1, modeling2, cheyenne
  repository = "CMIP6"    ;FINN, FINN1.5, FINN1.6, FINN_NRT, QFED, QFED_native, QFED/FINN, QFED_NRT, GFAS, GFAS/FINN, CMIP6

  ANTHRO = False

  tracers = (/"CO"/)
  sm_tracers = (/"co"/)
  ;tracers = (/"BC", "OC", "NO", "NH3", "CO", \
  ;            "C2H6", "C3H6", "C3H8", "CH2O", "CH3CHO",\
  ;            "CH3COCH3", "SO2"/)
  ;sm_tracers = (/"BC", "OC", "NO", "NH3", "CO", \
  ;            "C2H6", "C3H6", "C3H8", "CH2O", "CH3CHO",\
  ;            "CH3COCH3", "SO2"/)
  ;tracers = (/"BIGALD", "BIGALK", "BIGENE", "C10H16", "C2H2", "C2H4", "C2H5OH", \
  ;            "C2H6", "C3H6", "C3H8", "CB1", "CB2", "CH2O", "CH3CHO", "CH3CN", \
  ;            "CH3COCH3", "CH3COCHO", "CH3COOH", "CH3OH", "CO", "CO2", "CRESOL", \
  ;            "GLYALD", "HCN", "HCOOH", "HYAC", "ISOP", "MACR", "MEK", "MVK", \
  ;            "NH3", "NO", "OC1", "OC2", "SO2", "TOLUENE"/)
  ; no MW data: XYLENE, BENZ


  ; -------------------------------
  ; toggles
  ; -------------------------------
   NETCDF = True

  ; -------------------------------
  ; begin a tracer loop
  ; -------------------------------
do t = 0, dimsizes(tracers)-1

  tracer = tracers(t)
  sm_tracer = sm_tracers(t)
  s_name = tracer

  ; -------------------------------
  ; emission files and path setup
  ; -------------------------------
  if (machine.eq."modeling1") then 
    top_dir = "/data14b/buchholz/"
    if (repository.eq."FINN") then
     emis_dir = top_dir+ "finn/cam_0.9x1.25/"
     e_file_in = "emissions-finn1.5_"+tracer+"_bb_surface_2002-2017_0.9x1.25.nc"

    else if (repository.eq."QFED/FINN") then
     emis_dir = top_dir+ "qfed/cam_"+reso+"/from_co2/v2.5/"
     e_file_in = "qfed.emis_"+tracer+"_"+reso+"_mol_"+ystart+"_"+yend+".nc"
    else if (repository.eq."QFED_native") then
     emis_dir = top_dir+ "qfed/orig_0.25/"+sm_tracer+"_"+ystart+"/"
    else if (repository.eq."QFED") then
     emis_dir = top_dir+ "qfed/cam_"+reso+"/regridded/"
     e_file_in = "qfed.emis_"+tracer+"_"+reso+"_mol_"+ystart+"_"+yend+".nc"
    else if (repository.eq."CMIP6") then
     emis_dir = top_dir+ "cmip6/"
     e_file_in = "emissions-cmip6_"+tracer+"_bb_surface_1750-2015_0.9x1.25_c20170322.nc"
    end if
    end if
    end if
    end if
    end if

    if (repository.eq."QFED".or.repository.eq."QFED/FINN".or.\
      repository.eq."FINN") then
     indir = emis_dir+"allyears/"
     outpath = emis_dir+"region_sums/"
    else if (repository.eq."QFED_native") then
     outpath = top_dir+ "qfed/cam_"+reso+"/regridded/region_sums/"
     e_file_in = systemfunc ("ls "+emis_dir+"*"+ystart+"*.nc4")
    else if (repository.eq."FINN") then
     indir = emis_dir+"finn1.5/"
     outpath = emis_dir+"region_sums/"
    else if (repository.eq."CMIP6") then
     indir = emis_dir+"cam_0.9x1.25/"
     outpath = emis_dir+"region_sums/"
    end if
    end if
    end if
    end if

    if (repository.eq."GFAS") then
     emis_dir = top_dir+ "gfas/cam_"+reso+"/regridded"
     e_file_in = "gfas.emis_fromgrib_"+tracer+"_"+reso+"_mol_"+ystart+"_"+yend+".nc"
     indir = emis_dir+"/allyears/"
     outpath = emis_dir+"/region_sums/"
    else if (repository.eq."GFAS/FINN") then
     emis_dir = top_dir+ "gfas/cam_"+reso+"/from_co2"
     e_file_in = "gfas.emis_"+tracer+"_"+reso+"_mol_"+ystart+"_"+yend+".nc"
     indir = emis_dir+"/allyears/"
     outpath = emis_dir+"/region_sums/"
    end if
    end if

    if (repository.eq."CMIP6") then
     emis_dir = top_dir+ "gfed/cmip6_cam_"+reso
     e_file_in = "emissions-cmip6_"+tracer+"_bb_surface_1750-2015_"+reso+"_c20170322.nc"
     indir = emis_dir+"/1750_2015/"
     outpath = emis_dir+"/region_sums/"
    end if

  else if (machine.eq."cheyenne") then 
    top_dir = "/glade/work/buchholz/"

    if (repository.eq."FINN_NRT") then
     emis_dir = "/glade/p/acd/fvitt/waccm_forecast_emis/forecast/"
     e_file_in = systemfunc ("ls "+emis_dir+"emissions-fcst_"+tracer+"_bb_surface_2017-2018_0.9x1.25.nc")
    else if (repository.eq."FINN1.5") then
     emis_dir = "/glade/work/emmons/emis/finn1.5/2002_2017_1deg/"
     e_file_in = systemfunc ("ls "+emis_dir+"*"+tracer+"_bb*.nc")
    else if (repository.eq."FINN1.6") then
     emis_dir = "/glade/p_old/work/emmons/emis/finn1.6/cesm_format/"
     e_file_in = systemfunc ("ls "+emis_dir+"*"+tracer+"_bb*_"+ystart+"-"+yend+"_"+reso+".nc")
     ;emis_dir = "/glade/work/emmons/emis/finn1.6_v20180630/"
     ;e_file_in = systemfunc ("ls "+emis_dir+"*"+tracer+"_bb*_"+ystart+"_"+reso+".nc")
    else if (repository.eq."QFED_NRT") then
     emis_dir = top_dir+ "emis/qfed_finn_nrt_1x1/"
     e_file_in = systemfunc ("ls "+emis_dir+"qfed.emis_"+tracer+"_"+reso+"_mol_"+ystart+".nc")
    else if (repository.eq."QFED/FINN") then
     emis_dir = top_dir+ "emis/qfed2.5_finn_2000_2018_1x1/"
     e_file_in = systemfunc ("ls "+emis_dir+"qfed.emis_"+tracer+"_"+reso+"_mol_"+"*.nc")
    else if (repository.eq."CMIP6") then
     cmipdir = "/glade/p/cesmdata/cseg/inputdata/atm/cam/chem/emis/CMIP6_emissions_1750_2015/"
     e_file_in = systemfunc ("ls "+cmipdir+"*"+tracer+"*anthro_surface_1750-2015_0.9x1.25_c20170608.nc")
    end if
    end if
    end if
    end if
    end if
    end if

    outpath = top_dir+ "data_processing/CAM-chem/emissions/"

  else if (machine.eq."modeling2") then 
    top_dir = "/net/mopfl2015.acom.ucar.edu/home/buchholz/"

    if (repository.eq."FINN") then
     emis_dir = "/amadeus-data/emmons/web/finn_emis_nc/"
     e_file_in = systemfunc ("ls "+emis_dir+"*/emissions_"+tracer+"_"+reso+"*.nc")
    end if

    outpath = top_dir+ "/CAM_chem/emissions/"

  end if
  end if
  end if


   ; if (.not.isfilepresent(indir+e_file_in)) then
   ;   print("No file for tracer:" + tracer)
   ;   continue  ; skip all the next bit and go to next file
   ; end if


  ; -------------------------------
  ; MOZART molecular weights
  ; -------------------------------
  ;molwts = "/glade/u/home/buchholz/data/species_molwts.txt"
  molwts = "~/data/species_molwts.txt"

;--------------------------------------------
; end user input
;--------------------------------------------

;********************************************
; set up
  ; -------------------------------
  ; names of data structures
  ; "anthro", "bb", "ocean"
  ; -------------------------------
  if (repository.eq."FINN".or.repository.eq."FINN1.5"\
      .or.repository.eq."FINN1.6") then
    emiss           = "fire"
  else if (repository.eq."QFED_native") then
    emiss           = "biomass"
  else if (repository.eq."CMIP6") then
    emiss           = "emiss_bb"
    if (ANTHRO) then
      emiss           = "emiss_anthro"
    end if
  else
    emiss           = "bb"
  end if
  end if
  end if
  ; -------------------------------
  ; constants
  ; -------------------------------
   NAv = 6.022e23                    ; Avogadro's number, molecules mole^-1
   re   = 6.37122e06                 ; Earth radius (in metres)
   rad  = 4.0 * atan(1.0) / 180.0    ; Convert degrees to radians (pi radians per 180 deg)
   con  = re * rad                   ; constant for determining arc length 

   montharray = (/31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31/)

   ; load molecular weights (g/mol) from a MOZART file,
   ; augmented with additional values for:
   ; CO2, OC and BC copied from OC1 and CB1
   mw_dummy  = asciiread(molwts,-1,"string")
   mw_dummy2 = mw_dummy(2:)
   mol_wts = new((/dimsizes(mw_dummy2),2/), string)
   do s = 0,dimsizes(mw_dummy2)-1
     mol_wts(s,:) = str_split(mw_dummy2(s)," ")
   end do

;********************************************
; load files and extract
  if (repository.eq."QFED_native") then
    fin = addfiles(e_file_in, "r")
    ListSetType (fin, "cat") 
      emiss_in_dummy          = fin[:]->$emiss$
      emiss_in = lonFlip(emiss_in_dummy)
      time := emiss_in&time
      lat = tofloat(emiss_in&lat)
      lon = tofloat(emiss_in&lon)
  else if (machine.eq."modeling2".and.\
           repository.eq."FINN") then
    fin = addfiles(e_file_in, "r")
    ListSetType (fin, "cat") 
      emiss_in          = fin[:]->$emiss$
      time := emiss_in&time
      lat = tofloat(emiss_in&lat)
      lon = tofloat(emiss_in&lon)
  else if (machine.eq."cheyenne") then
    fin = addfiles(e_file_in, "r")
      emiss_in          = fin[:]->$emiss$
      time := emiss_in&time
      lat = tofloat(emiss_in&lat)
      lon = tofloat(emiss_in&lon)
  else
    fin = addfile(indir+e_file_in, "r")
      emiss_in         := fin->$emiss$
      time := emiss_in&time
      lat = emiss_in&lat
      lon = emiss_in&lon

  end if
  end if
  end if

      yyyymmdd := cd_calendar(time,-2)
       yyyymmdd!0 = "time"
       yyyymmdd&time = time
      date = cd_calendar(time,0)
      yyyy = tointeger(date(:,0))
      mm = tointeger(date(:,1))
      ttime = dimsizes(time)
      nlat = dimsizes(lat)
      mlon = dimsizes(lon)


  ;********************************************
  ; Calculate emission totals

    ; -------------------------------
    ; convert to CAM-Chem units
    ; molec. cm-2 s-1 to g per day per gridbox
    ; -------------------------------
     ; not in MW file: XYLENE, HCOOH, HCN, CO2, CH3CN, C2H2, BENZ
     if (tracer.eq."C2H2") then
       mw = 26.036
     else if (tracer.eq."CH3CN") then
       mw = 41.054
     else if (tracer.eq."CO2") then
       mw = 44.008
     else if (tracer.eq."HCN") then
       mw = 27.028
     else if (tracer.eq."HCOOH") then
       mw = 46.024
     else
       mw = tofloat(mol_wts(ind(mol_wts(:,0).eq.tracer),1))
     end if
     end if
     end if
     end if
     end if

     if (repository.eq."QFED_native") then
       emiss_in = emiss_in/(10000)        ; m-2 -> cm-2
       emiss_in = (emiss_in*1000/mw)*NAv  ; kg -> g -> mol -> molec
         emiss_in@units = "molecules/cm2/s"
     end if

     ; g cm-2 s-1
     tracer_emiss = (emiss_in/NAv)*mw          ; molec -> mol -> g
     ; g cm-2 d-1
     tracer_emiss = (tracer_emiss*86400)       ; s-1 -> d-1

     if (repository.eq."CMIP6") then           ; d-1 -> m-1
       month_days = days_in_month(yyyy,mm)
       month_days_array = conform(tracer_emiss, month_days, 0)
       tracer_emiss = tracer_emiss*month_days_array
     end if
     ; g m-2 d-1
     tracer_emiss = (tracer_emiss*100*100)     ; cm-2 -> m-2
      tracer_emiss!0 = "time"
      tracer_emiss&time = yyyymmdd
      tracer_emiss!1 = "lat"
      tracer_emiss&lat = lat
      tracer_emiss!2 = "lon"
      tracer_emiss&lon = lon


     ; weight by gridbox area
       ; prevent negative weights 
       ; (redundant because no emissions over artic and anatarctica)

       newlat = lat
       newlat(0)= 89.99999
       newlat(dimsizes(newlat)-1)= -89.99999   

     clat = cos(lat * rad)           ; cosine of latitude
     dlon = (lon(2) - lon(1))        ; assume dlon is constant
     dlat = (lat(2) - lat(1))        ; assume dlat is constant
     dx   = con * dlon * clat        ; dx (in metres) at each latitude
     dy   = con * dlat               ; dy (in metres) is constant
     dydx = dy * dx                  ; dydx(nlat)

     wgt  = new((/nlat, mlon/), float)
     wgt  = conform(wgt, dydx, 0)
      wgt!0 = "lat"
      wgt&lat = newlat
      wgt!1 = "lon"
      wgt&lon = lon

     globsum  = wgt_areasum2(tracer_emiss,wgt,0)/1e12   ; g -> Tg
       globsum@units = "Tg"
       globsum!0 = "time"
       globsum&time = yyyymmdd

     if (emiss.eq."anthro".or.\
         emiss.eq."ocean") then
       print("monthly emissions")
         if(isleapyear(yyyy(i))) then
           montharray(1)= 29
         else
           montharray(1) = 28
         end if
       do i = 0, dimsizes(yyyymmdd)-1
         globsum(i) = globsum(i) * montharray(mm(i)-1)
       end do
     end if

    ;------------------
    ; Year averages
    ;------------------
    year_array = ispan(ystart,yend,1)
    year_sum_array = new((/dimsizes(year_array)/), float)
    do i = 0, dimsizes(year_array)-1
      year_ind := ind(globsum&time.gt.year_array(i)*10000.and.\
                 globsum&time.lt.(year_array(i)+1)*10000)
      year_sum_array(i) = sum(globsum(year_ind))
    end do

     print("Year, emissions of "+tracer+" (Tg)")
     print(year_array+" "+year_sum_array)

    ;------------------
    ; Month averages
    ;------------------
    month_array = new(dimsizes(year_array)*12, integer)
    month_sum_array = new(dimsizes(month_array), float)
    do i = 0, dimsizes(year_array)-1
      do j = 0, 11
        month_ind := ind(mm.eq.j+1.and.yyyy.eq.year_array(i))
        month_array(i*12+j) = year_array(i)*100 + j+1
        if (.not.(ismissing(month_ind(0)))) then
          month_sum_array(i*12+j) = sum(globsum(month_ind))
        end if
      end do
    end do

     print("Month, emissions of "+tracer+" (Tg)")
     print(month_array+" "+month_sum_array)

    ;------------------
    ; Total average
    ;------------------
     total_avg = avg(year_sum_array(0:dimsizes(year_sum_array)-2))
     print(ystart+" to "+yend+", average yearly emissions of "+tracer+" (Tg): " + total_avg)



  ;********************************************
  ; Extract regional timeseries
  ; region_names = (/"Maritime SEA", "Australasia", \
  ;                  "Southern Africa", "South America",\
  ;                  "Siberia", "North America" /)
  ;                   minlat, maxlat, minlon, maxlon
  ; region_select = (/(/-10.,  10.,      90.,     160./),\ ;Maritime SEA
  ;                   (/-50., -10.,     110.,     180./),\ ;Australasia
  ;                   (/-40.,   5.,       0.,      60./),\ ;SAfrica
  ;                   (/-60.,   4., 360.-80., 360.-40./),\ ;SAmerica
  ;                   (/ 50.,  85.,      91.,     190./),\ ;Siberia
  ;                   (/ 25.,  70.,360.-170.,360.-53./) /) ;NAmerica

   ;region_names = (/"Northwest Canada", "Northwest USA","Southeast USA", \
   ;                 "Siberia", "North America", "India" /)
  ;                   minlat, maxlat, minlon, maxlon
   ;region_select = (/(/ 54.,  67., 360.-120., 360.-93./),\  ;NWCan
   ;                  (/ 40.,  51., 360.-125., 360.-105./),\ ;NWUS
   ;                  (/ 30.,  41., 360.-102., 360.-88./),\  ;SEUS
   ;                  (/ 50.,  85.,      91.,     190./),\   ;Siberia
   ;                  (/ 25.,  70., 360.-160., 360.-53./),\  ;NAmerica
   ;                  (/ 20.,  40.,      65.,     90./) /)   ;India

   region_names = (/"BBCanada", "BBSiberia"/)

   ;                   minlat, maxlat, minlon, maxlon
   region_select = (/(/ 50.,  60., 360.-125.,  360.-90./),\  ;BBCanada
                     (/ 50.,  60.,       90.,      140./)/)  ;BBSiberia


     ; -------------------------------
     ; sums
     ; -------------------------------
     regsum = new((/dimsizes(region_names), dimsizes(yyyymmdd)/), float)
     ; overwrite -89.999 and 89.999 so subset works correctly.
      wgt&lat = lat
     do r = 0, dimsizes(region_names)-1
       emiss_region := tracer_emiss(:,{region_select(r,0):region_select(r,1)},\
                                    {region_select(r,2):region_select(r,3)})
       wgt_region := wgt({region_select(r,0):region_select(r,1)},\
                         {region_select(r,2):region_select(r,3)})
       regsum(r,:)= wgt_areasum2(emiss_region,wgt_region,0)/1e12   ; g -> Tg
     end do

       regsum@units = "Tg"
       regsum!0 = "region"
       regsum&region = region_names
       regsum!1 = "time"
       regsum&time = time

       ;printVarSummary(regsum)

;********************************************
; Write out to new file
;********************************************
if (NETCDF) then
      ;-------------------
      ; create file for each 
      ; CAM-chem species
      ;-------------------
      if (repository.eq."QFED_native") then
        outfilename = "qfed.emis_"+tracer+"_Tg_regional_"+ystart+".nc"
      else if (repository.eq."QFED/FINN") then
        outfilename = "qfed.emis_"+tracer+"_"+reso+"_QFED_cross_FINN_Tg_regional_"+ystart+"_"+yend+".nc"
      else if (repository.eq."GFAS") then
        outfilename = "gfas.emis_"+tracer+"_"+reso+"_"+repository+"_Tg_regional_"+ystart+"_"+yend+".nc"
      else if (repository.eq."GFAS/FINN") then
        outfilename = "gfas.emis_"+tracer+"_"+reso+"_GFAS_cross_FINN_Tg_regional_"+ystart+"_"+yend+".nc"
      else if (repository.eq."FINN".or.repository.eq."FINN1.5".or.repository.eq."FINN1.6") then
        outfilename = "finn.emis_"+tracer+"_"+reso+"_"+repository+"_Tg_regional_"+ystart+"_"+yend+".nc"
      else if (repository.eq."CMIP6") then
        outfilename = "cmip.emis_"+tracer+"_"+reso+"_"+repository+"_Tg_regional_"+ystart+"_"+yend+".nc"
      else
        outfilename = "qfed.emis_"+tracer+"_"+reso+"_"+repository+"_Tg_regional_"+ystart+"_"+yend+".nc"
      end if
      end if
      end if
      end if
      end if
      end if
      fout = addfile(outpath+outfilename, "c")
      print(outpath+outfilename)

      ;------------
      ; File 
      ; Attributes
      ;------------
      setfileoption(fout, "DefineMode",True)
      fAtt                      = True
        fAtt@molecular_weight   = mw
        fAtt@conventions        = "CF"
        fAtt@creation_date      = systemfunc ("date")
        fAtt@author             = "R. R. Buchholz"
        if (repository.eq."QFED/FINN") then
          fAtt@history            = s_name+" is from QFED, Level3b v2.5 "+\
                                  "(qfed-2_4_r6) Gridded Emission Estimates, with "+\
                                  "FINN emission ratios applied"
          fAtt@source             = "QFED: NASA/GSFC/GMAO GEOS-5 Aerosol Group; FINN: C. Wiedinmyer 2015"
          fAtt@title              = "Emissions of "+ tracer+\
                                  " from FINN emission ratios applied to QFED "+s_name+", daily"
        else if (repository.eq."QFED".or.repository.eq."QFED_native") then
          fAtt@history            = tracer+" is from QFED, Level3b v2.4 "+\
                                  "(qfed-2_4_r6) Gridded Emission Estimates"
          fAtt@source             = "QFED: NASA/GSFC/GMAO GEOS-5 Aerosol Group"
          fAtt@title              = "Emissions of "+ tracer+" from QFED, daily"
        else if (repository.eq."FINN".or.repository.eq."FINN1.5"\
                 .or.repository.eq."FINN1.6") then
          fAtt@history            = tracer+" is from "+repository+", v1.5"
          fAtt@title              = "Emissions of "+ tracer+" from FINN, daily"
        else if (repository.eq."GFAS") then
          fAtt@history            = tracer+" is from "+repository+", v1.2"
          fAtt@title              = "Emissions of "+ tracer+" from GFAS, daily"
        else if (repository.eq."GFAS/FINN") then
          fAtt@history            = s_name+" is from "+repository+", v1.2 with "+\
                                  "FINN emission ratios applied"
          fAtt@title              = "Emissions of "+ tracer+" from FINN emission ratios applied to GFAS "+s_name+", daily"
        else if (repository.eq."CMIP6") then
          fAtt@history            = tracer+" is from "+repository
          fAtt@title              = "Emissions of "+ tracer+" from CMIP6, daily"
        end if
        end if
        end if
        end if
        end if
        end if

        fAtt@globalavg          = ystart+" to "+yend+" average global yearly emissions of "+tracer+" (Tg): " + total_avg
        fAtt@average            = region_names

       fileattdef(fout, fAtt)
       setfileoption(fout, "DefineMode",False)

      ;------------
      ; Coordinate Variables
      ;------------
        dimNames = (/"time"/)  
	dim_Sizes = (/ -1  /) 
	dimUnlim = (/ True /)   
	filedimdef(fout,dimNames,dim_Sizes,dimUnlim)

      ;------------
      ; Variables
      ;------------
       ;--- date
         fout->date             = yyyymmdd

      do n = 0, dimsizes(region_names)-1
         bb_name = "bb_"+n
       ;--- emissions
         fout->$bb_name$             = regsum(n, :)
      end do

    end if ;NetCDF

end do ; tracer loop

end

