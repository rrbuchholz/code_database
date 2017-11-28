;=======================================================;
;  combine_qfed_finn_ers.ncl
;=======================================================;
;
; Concepts illustrated:
;   - Load qfed CO2 (or CO) files
;   - Load Christine's emission values
;         (separated into 4 land types)
;   - Calculate emission factors
;   - Multiply CO2 (or CO) by emission factors for each species
;      and change units to molec/cm^2/s
;   - Load Christine's VOC speciation 
;   - For VOC speciation - multiply NMOC
;         (total VOCs) by speciation factor
;   - Regrid from 0.25 x 0.25 to 1.9 x2.5
;                          or to 0.94 x 1.2
;   - Regrid lon gridding,
;          -180 to 180 qfed : 0 to 360 CAM-chem
;   - Write out to netCDF - one file per tracer per year
;                         - kept at daily time resolution
;   
;   To run type:
;         ncl combine_qfed_finn_ers.ncl
;
;   Requires:
;         path to qfed files separated into years
;         path to FINN emission ratios file
;         path to FINN VOC speciation
;         path to MOZART molecular weight file
;         emission ratio files must have line (or column for VOC) order:
;         1: Savanna Grasslands
;         2: Shrublands/Savanna
;         3: Tropical Forest
;         4: Extratropical Forest
;                                  RRB March 06, 2015
;=======================================================;
; load the libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------
  NRT = True

  if (NRT) then
    if (.not. isvar("YYYYMMDD")) then      ; is YYYYMMDD from command line?
       YYYYMMDD = 20171101
    end if
    splitdate = str_split_by_length(tostring(YYYYMMDD), 4)
    year = toint(splitdate(0))
    outres = "0.94x1.2"
    ratio_species = "co2"
    species = "CO2"
    outpath = "/net/modeling1/data14b/buchholz/qfed/cam_"+outres+"/from_"+ratio_species+"/nrt/"
  else
    year = 2016
    outres = "0.94x1.2"
    ratio_species = "co"
    species = "CO"
    outpath = "/net/modeling1/data14b/buchholz/qfed/cam_"+outres+"/from_"+ratio_species+"/"+year+"/"
  end if

  ; -------------------------------
  ; QFED files
  ; -------------------------------

  if (NRT) then
    qfed_dir = "/net/modeling1/data14b/buchholz/qfed/orig_0.25/"+ratio_species+"_nrt/"
    qfed_files = systemfunc ("ls "+qfed_dir+"*"+YYYYMMDD+"*.nc4")
  else
    qfed_dir = "/net/modeling1/data14b/buchholz/qfed/orig_0.25/"+ratio_species+"_"+year+"/"
    qfed_files = systemfunc ("ls "+qfed_dir+"*"+year+"*.nc4")
  end if

  ; -------------------------------
  ; FINN emission ratios
  ; -------------------------------
  finn_emiss = "/net/modeling1/home/buchholz/data/emissionsfactors_speciation_20150305.csv"
  finn_VOC = "/net/modeling1/home/buchholz/data/VOC_emissionfactors_speciation_20150313.csv"

  ; -------------------------------
  ; MOZART molecular weights
  ; -------------------------------
  molwts = "/net/modeling1/home/buchholz/data/species_molwts.txt"

  ;------------
  ; toggles
  ;------------
  netCDF         = True                       ; for netCDF output
  PLOT           = False
;--------------------------------------------
; end user input
;--------------------------------------------

;********************************************
; set up
  ; -------------------------------
  ; names of QFED data structures
  ; determined from an ncl_filedump
  ; -------------------------------
  qfed_co2           = "biomass"
  qfed_co2_trop      = "biomass_tf"
  qfed_co2_extratrop = "biomass_xf"
  qfed_co2_savanna   = "biomass_sv"
  qfed_co2_grass     = "biomass_gl"
  qfed_time          = "time"

  ; -------------------------------
  ; plotting parameters
  ; -------------------------------
  if (PLOT) then
    mapType = "x11"
    mapName = "test"
  end if ;PLOT

  ; -------------------------------
  ; constants
  ; -------------------------------
   NAv = 6.022e23              ; Avogadro's number, molecules mole^-1

   re   = 6.37122e06              ; Earth radius
   rad  = 4.0 * atan(1.0) / 180.0 ; For area sums/avg
   con  = re * rad                 

   ; load molecular weights (g/mol) from a MOZART file,
   ; augmented with additional values for:
   ; CO2, OC and BC copied from OC1 and CB1
   mw_dummy  = asciiread(molwts,-1,"string")
   mw_dummy2 = mw_dummy(2:)
   mol_wts = new((/dimsizes(mw_dummy2),2/), string)
   do s = 0,dimsizes(mw_dummy2)-1
     mol_wts(s,:) = str_split(mw_dummy2(s)," ")
   end do

  ; -------------------------------
  ; lat/lon for re-gridding
  ; -------------------------------

  if (outres.eq."0.94x1.2") then
   ; higher res - 1 deg
   newlon  = fspan(0,358.8, 288)
     newlon@units      = "degrees_east"
     newlon@long_name  = "longitude"
     newlon!0          = "lon"
     newlon&lon        = newlon
   newlat  = fspan(-90,90, 192)
     newlat@units      = "degrees_north"
     newlat@long_name  = "latitude"
     newlat!0          = "lat"
     newlat&lat        = newlat
  else
    ; lower res - 2 deg
   newlon  = fspan(0,357.5, 144)
     newlon@units      = "degrees_east"
     newlon@long_name  = "longitude"
     newlon!0          = "lon"
     newlon&lon        = newlon
   newlat  = fspan(-90,90, 96)
     newlat@units      = "degrees_north"
     newlat@long_name  = "latitude"
     newlat!0          = "lat"
     newlat&lat        = newlat
   end if

  ; -------------------------------
  ; CAM-chem res for sums/avgs
  ; -------------------------------
     clat = cos(newlat * rad)        ; cosine of latitude
     dlon = (newlon(2) - newlon(1))  ; assume dlon is constant
     dlat = (newlat(2) - newlat(1))  ; assume dlat is constant
     dx   = con * dlon * clat        ; dx at each latitude
     dy   = con * dlat               ; dy is constant
     dydx = dy * dx                  ; dydx(nlat)
   
     wgt_CAM  = new((/dimsizes(newlat), dimsizes(newlon)/), float)
     wgt_CAM  = conform(wgt_CAM, dydx, 0)


;********************************************
; load files and extract
  ; -------------------------------
  ; QFED load
  ; -------------------------------
    fin = addfiles(qfed_files, "r")            ; read in
    ListSetType (fin, "cat") 
      co2_all          = fin[:]->$qfed_co2$
      co2_trop         = fin[:]->$qfed_co2_trop$
      co2_xtrop        = fin[:]->$qfed_co2_extratrop$
      co2_savan        = fin[:]->$qfed_co2_savanna$
      co2_grass        = fin[:]->$qfed_co2_grass$

      ; load and convert time format
      time_dummy       = fin[:]->$qfed_time$
      time = cd_convert(time_dummy, "days since 1850-01-01 00:00:00" )
        time@long_name = "Time"
        time@calendar = "Gregorian"
        time!0 = "time"
        time&time = time

      date = cd_calendar(time_dummy,-2)
        date!0 = "time"
        date&time = time
        date@long_name = "Date"
        date@units = "YYYYMMDD"
        delete(date@calendar)

      delete(co2_all&time )
      co2_all!0 = "time"
      co2_all&time = (time)

  ; -------------------------------
  ; QFED res for sums/avgs
  ; -------------------------------
     clat_q = cos(co2_all&lat * rad) ; cosine of latitude
     dlon_q = (co2_all&lon(2) - co2_all&lon(1))  ; assume dlon is constant
     dlat_q = (co2_all&lat(2) - co2_all&lat(1))  ; assume dlat is constant
     dx_q   = con * dlon_q * clat_q   ; dx at each latitude
     dy_q   = con * dlat_q            ; dy is constant
     dydx_q = dy_q * dx_q             ; dydx(nlat)

     wgt_QFED  = new((/dimsizes(co2_all&lat), dimsizes(co2_all&lon)/), float)
     wgt_QFED  = conform(wgt_QFED, tofloat(dydx_q), 0)

  ; -------------------------------
  ; load FINN emission ratios
  ; -------------------------------
  ;---read the values in as 1D lines
  emiss_g  = asciiread(finn_emiss,-1,"string")

  ;--- collect data
  delim  = ","
  header = emiss_g(0)
  data = emiss_g(1:)
  nlines = dimsizes(data)
  ncols  = dimsizes(str_split(data(0),delim))
  print("columns = " + ncols)
  print(header)

  ;--- separate header for species name
  dummy_var = str_split_csv(header,delim,0)
  dummy_var2 = dummy_var(0,1:)
  var_names = str_upper(dummy_var2)
  ;--- replace names to be consistent with MOZART
  var_names = where(var_names.eq."NO","ignore",var_names)      ; ignore the initial NO column
  var_names = where(var_names.eq."NOX AS NO","NO",var_names)   ; turn the NOx value into NO

  ;---reshape data to 2D array, and convert to float
  strs = str_split_csv (data, delim, 0)  
  ltype = strs(:,0)                 ;--- land type names
  e_fields = tofloat(strs(:,1:))    ;--- emission values
    ;--- define attributes
    e_fields!0 = "vegtype"
    e_fields&vegtype = ltype
    e_fields!1 = "tracer"
    e_fields&tracer = var_names
    e_fields@units = "g/kg"
    e_fields@_FillValue = -9999.99
    e_fields = where(ismissing(e_fields),0,e_fields) ; replace missing with zeros for calculations

  ; -------------------------------
  ; compute factors
  ; -------------------------------
   e_factors = e_fields
   if (ratio_species.eq."co2") then
     do k=0,nlines-1                                      
       e_factors(k,:) = e_fields(k,:)/e_fields(k,0)
     end do
   else if (ratio_species.eq."co") then
     do k=0,nlines-1                                      
       e_factors(k,:) = e_fields(k,:)/e_fields(k,1)
     end do
   end if
   end if
     e_factors@units = "g/kg per g/kg"

  ;********************************************
  ; Non- VOCs
  ;--- FINN                    QFED
  ;                          kg s-1 m-2
  ; Savanna Grasslands       co2_grass
  ; Shrublands/Savanna       co2_savan
  ; Tropical Forest          co2_xtrop
  ; Extratropical Forest     co2_trop

  do tracer = 0,dimsizes(var_names)-1
  ;do tracer = 0,1
    if (var_names(tracer).eq."NMOC".or.\
        var_names(tracer).eq."ignore".or.\
        var_names(tracer).eq."PM2.5".or.\
        var_names(tracer).eq."PM10") then
      ; Apply speciation values to total vocs
      ; outside this loop
      ; and ignore PM2.5 and PM10
      continue
    else
      ; -------------------------------
      ; calculate emissions for non-VOCs
      ; -------------------------------
      tracer_emiss:= co2_grass * e_factors(0,tracer) +\
                     co2_savan * e_factors(1,tracer) +\
                     co2_trop * e_factors(2,tracer) +\
                     co2_xtrop * e_factors(3,tracer)
    end if
    copy_VarAtts(co2_all,tracer_emiss)
    copy_VarCoords(co2_all,tracer_emiss)
    ;printVarSummary(tracer_emiss)

    ; -------------------------------
    ; convert to CAM-Chem units
    ; kg s-1 m-2 to molec. cm-2 s-1
    ; -------------------------------
     print(var_names(tracer))
     mw = tofloat(mol_wts(ind(mol_wts(:,0).eq.var_names(tracer)),1))
     print(var_names(tracer)+" MW: "+mw)
     tracer_emiss = tracer_emiss/(10000)        ; m-2 -> cm-2
     tracer_emiss = (tracer_emiss*1000/mw)*NAv  ; kg -> g -> mol -> molec
       tracer_emiss@units = "molecules/cm2/s"

    ; -------------------------------
    ; regrid to CAM-chem structure
    ; 1.9 x 2.5 or 0.94 x 1.2
    ; -------------------------------
     opt    = False
     emiss_regrid  = area_conserve_remap_Wrap(tracer_emiss&lon,tracer_emiss&lat, \
                                         tracer_emiss , \
                                         newlon, newlat, opt)  ; (ntim,96,144)
     ;printVarSummary(emiss_regrid)

     ;--- sanity check
     AvgOrigGrid = wgt_areaave2 (tracer_emiss , wgt_QFED, 0)
     Avg_Regrid = wgt_areaave2 (emiss_regrid, wgt_CAM, 0)
     AvgDiff = AvgOrigGrid-Avg_Regrid
     PercDiff = (AvgDiff/AvgOrigGrid)*100
     MaxDiff = max(PercDiff)
     max_ind = ind(PercDiff.eq.MaxDiff)
   ;print("Maximum diff: lowres: "+sprintf("%2.2e",AvgOrigGrid(max_ind))+\
   ;      "  highres: "+sprintf("%2.2e",Avg_Regrid(max_ind))+   \
   ;      "    diff: "+sprintf("%2.2e",AvgDiff(max_ind))+  \
   ;      "   percent diff: "+sprintf("%2.2f",PercDiff(max_ind))+"%")

   print("Maximum percent diff in "+var_names(tracer)+\
         " from regridding: "+sprintf("%2.2f",PercDiff(max_ind))+"%"+\
         " on date: " + cd_calendar(co2_all&time(max_ind),2))
   print("-------------------------------------------------")

    ;--------------------------------------------
    ; Write out to an netCDF file
    ;--------------------------------------------
    if (netCDF) then
      ;-------------------
      ; create file for each 
      ; CAM-chem species
      ;-------------------
      if (NRT) then
        outfilename = "qfed.emis_"+var_names(tracer)+"_"+outres+"_mol_"+year+".nc"
        template = addfile(outpath+outfilename, "r")            ; read in
           date_template = template->date
           bb_template = template->bb
        fout = addfile(outpath+outfilename, "w")                ; ready for some overwriting
      else 
        outfilename = "qfed.emis_"+var_names(tracer)+"_"+outres+"_mol_"+year+".nc"
        fout = addfile(outpath+outfilename, "c")
      end if

      if (NRT) then
         ind_overwrite = ind(date_template.eq.date)
         emiss_overwrite = bb_template
         emiss_overwrite(ind_overwrite,:,:) = emiss_regrid

       ;--- emissions
         fout->bb               = emiss_overwrite

      else
      ;------------
      ; File 
      ; Attributes
      ;------------
      setfileoption(fout, "DefineMode",True)
      fAtt                      = True
        fAtt@molecular_weight   = mw
        fAtt@conventions        = "CF"
        fAtt@history            = species+" is from QFED, Level3b v2.4 "+\
                                  "(qfed-2_4_r6) Gridded Emission Estimates, with "+\
                                  "FINN emission ratios applied"
        fAtt@author             = "R. R. Buchholz"
        fAtt@creation_date      = systemfunc ("date")
        fAtt@source             = "QFED: NASA/GSFC/GMAO GEOS-5 Aerosol Group; FINN: C. Wiedinmyer 2015"
        fAtt@title              = "Emissions of "+ var_names(tracer)+\
                                  " from FINN emission ratios applied to QFED" +\
                                   species+", daily"

       fileattdef(fout, fAtt)
       setfileoption(fout, "DefineMode",False)

      ;------------
      ; Coordinate Variables
      ;------------
        dimNames = (/"time", "lat", "lon"/)  
	dim_Sizes = (/ -1   ,  dimsizes(emiss_regrid&lat),  dimsizes(emiss_regrid&lon)/) 
	dimUnlim = (/ True , False, False/)
	filedimdef(fout,dimNames,dim_Sizes,dimUnlim)
      ;------------
      ; Variables
      ;------------
      emiss_regrid@long_name = dummy_var2(tracer)+" QFED/FINN fire emissions"
      emiss_regrid@vmax      = max(emiss_regrid)
      emiss_regrid@vmin      = min(emiss_regrid)
      delete(emiss_regrid@missing_value)
      delete(emiss_regrid@fmissing_value)

       ;--- date
         fout->date             = date
       ;--- emissions
         fout->bb               = emiss_regrid
      end if

    end if ;NetCDF

  tracername := var_names(tracer)

  end do ;non VOC tracers

  ;********************************************
  ; VOCs
  ; -------------------------------
  ; load FINN VOC speciation
  ; -------------------------------
  ;---read the values in as 1D lines
  voc_in  = asciiread(finn_VOC,-1,"string")

  ;--- collect data
  delim  = ","
  header2 = voc_in(0)
  data2 = voc_in(1:)
  nlines2 = dimsizes(data2)
  ncols2  = dimsizes(str_split(data2(0),delim))
  print("columns = " + ncols2)

  ;--- separate header for landtype
  dummy_var3 = str_split_csv(header2,delim,0)
  voc_vtype = dummy_var3(0,1:)

  ;---reshape data as 2D array, and convert to float
  ;---account for missing values
  strs2 = str_split_csv(data2, delim, 0)  
  ;--- read in species types
  dummy_var4 = strs2(:,0) 
  voc_spec = str_upper(dummy_var4) 
  print(voc_spec)

  speciate = tofloat(strs2(:,1:))  
    ;--- define attributes
    speciate!0 = "tracer"
    speciate&tracer = voc_spec
    speciate!1 = "vegtype"
    speciate&vegtype = voc_vtype
    speciate@units = ""
    speciate@_FillValue = -9999.99

  ;print(speciate)

   ; -------------------------------
   ; apply VOC speciation
   ; -------------------------------
   nmoc_ind = ind(var_names.eq."NMOC")    ; get index of nmoc

   do voctype = 0,dimsizes(voc_spec)-1
   ;do voctype = 0,0
    if (voc_spec(voctype).eq."NO".or.\
        voc_spec(voctype).eq."IGNORE".or.\
        voc_spec(voctype).eq."ONIT") then
      ; ignore NO in VOC table,
      ; ONIT is all zeros
      continue
    else
      print("Calculating VOC speciation...")
      voc_tracer_emiss:= co2_grass * e_factors(0,nmoc_ind)*speciate(voctype,0) +\
                        co2_savan * e_factors(1,nmoc_ind)*speciate(voctype,1) +\
                        co2_trop * e_factors(2,nmoc_ind)*speciate(voctype,2) +\
                        co2_xtrop * e_factors(3,nmoc_ind)*speciate(voctype,3)
    end if
     copy_VarAtts(co2_all,voc_tracer_emiss)
     copy_VarCoords(co2_all,voc_tracer_emiss)

   ; -------------------------------
   ; convert to CAM-Chem units
   ; moles s-1 m-2 to molec. cm-2 s-1
   ;
   ; VOC factors convert from kg to moles
   ; so no need to do mw weight step
   ; -------------------------------
     print("No need for MW, emission factor to NMHC converts kg/s -> moles/s")
     print(voc_spec(voctype))
     voc_tracer_emiss = voc_tracer_emiss/(10000)     ; m-2 -> cm-2
     voc_tracer_emiss = voc_tracer_emiss*NAv         ; moles -> molec
       voc_tracer_emiss@units = "molecules/cm2/s"

    ; -------------------------------
    ; regrid to CAM-chem structure
    ; 1.9 x 2.5 or 0.94 x 1.2
    ; -------------------------------
     opt    = False
     voc_emiss_regrid  = area_conserve_remap_Wrap(voc_tracer_emiss&lon,voc_tracer_emiss&lat, \
                                         voc_tracer_emiss , \
                                         newlon, newlat, opt)  ; (ntim,96,144)
    ; printVarSummary(voc_emiss_regrid)

     ;--- sanity check
     AvgOrigGrid_voc = wgt_areaave2 (voc_tracer_emiss , wgt_QFED, 0) 
     Avg_Regrid_voc = wgt_areaave2 (voc_emiss_regrid, wgt_CAM, 0) 
     AvgDiff_voc = AvgOrigGrid_voc-Avg_Regrid_voc

   if (any(AvgOrigGrid_voc.eq.0)) then
     print("No emissions for "+voc_spec(voctype)+" in some entries of " + year)
     nonzero_ind = ind(AvgOrigGrid_voc.ne.0)
     PercDiff_voc = (AvgDiff_voc(nonzero_ind)/AvgOrigGrid_voc(nonzero_ind))*100
     print("-------------------------------------------------")
     print("lowres: "+AvgOrigGrid_voc+", highres: "+Avg_Regrid_voc)
   else
     PercDiff_voc = (AvgDiff_voc/AvgOrigGrid_voc)*100
   end if

     MaxDiff_voc = max(PercDiff_voc)
     max_ind_voc = ind(PercDiff_voc.eq.MaxDiff_voc)
     ;print("Maximum diff: lowres: "+sprintf("%2.2e",AvgOrigGrid(max_ind))+\
     ;      "  highres: "+sprintf("%2.2e",Avg_Regrid(max_ind))+   \
     ;      "    diff: "+sprintf("%2.2e",AvgDiff(max_ind))+\
     ;      "   percent diff: "+sprintf("%2.2f",PercDiff(max_ind))+"%")
     print("Maximum percent diff in "+voc_spec(voctype)+\
        " from regridding: "+sprintf("%2.2f",PercDiff(max_ind_voc))+"%"+\
         " on date: " + cd_calendar(co2_all&time(max_ind_voc),2))
     print("-------------------------------------------------")


    ;--------------------------------------------
    ; Write out to an netCDF file
    ;--------------------------------------------
    if (netCDF) then
      ;-------------------
      ; create file for each 
      ; CAM-chem species
      ;-------------------
      if (NRT) then
        outfilename = "qfed.emis_"+voc_spec(voctype)+"_"+outres+"_mol_"+year+".nc"
        template = addfile(outpath+outfilename, "r")            ; read in
           date_template = template->date
           bb_template = template->bb
        fout = addfile(outpath+outfilename, "w")                ; ready for some overwriting
      else 
        outfilename = "qfed.emis_"+voc_spec(voctype)+"_"+outres+"_mol_"+year+".nc"
        fout = addfile(outpath+outfilename, "c")
      end if

      if (NRT) then
         ind_overwrite = ind(date_template.eq.date)
         emiss_overwrite = bb_template
         emiss_overwrite(ind_overwrite,:,:) = emiss_regrid

       ;--- emissions
         fout->bb               = emiss_overwrite

      else
      ;------------
      ; File 
      ; Attributes
      ;------------
      setfileoption(fout, "DefineMode",True)
      fAtt                      = True
        fAtt@molecular_weight   = mw
        fAtt@conventions        = "CF"
        fAtt@history            = species+" is from QFED, Level3b v2.4 "+\
                                  "(qfed-2_4_r6) Gridded Emission Estimates, with "+\
                                  "FINN emission ratios applied"
        fAtt@author             = "R. R. Buchholz"
        fAtt@creation_date      = systemfunc ("date")
        fAtt@source             = "QFED: NASA/GSFC/GMAO GEOS-5 Aerosol Group; FINN: C. Wiedinmyer 2015"
        fAtt@title              = "Emissions of "+ voc_spec(voctype)+\
                                  " from FINN emission ratios applied to QFED "+\
                                   species+", daily"


       fileattdef(fout, fAtt)
       setfileoption(fout, "DefineMode",False)

      ;------------
      ; Coordinate Variables
      ;------------
        dimNames = (/"time", "lat", "lon"/)  
	dim_Sizes = (/ -1   ,  dimsizes(emiss_regrid&lat),  dimsizes(emiss_regrid&lon)/) 
	dimUnlim = (/ True , False, False/)   
	filedimdef(fout,dimNames,dim_Sizes,dimUnlim)

      ;------------
      ; Variables
      ;------------
      voc_emiss_regrid@long_name = voc_spec(voctype)+" QFED/FINN fire emissions"
      voc_emiss_regrid@vmax      = max(voc_emiss_regrid)
      voc_emiss_regrid@vmin      = min(voc_emiss_regrid)
      delete(voc_emiss_regrid@missing_value)
      delete(voc_emiss_regrid@fmissing_value)

       ;--- date
         fout->date             = date
       ;--- emissions
         fout->bb               = voc_emiss_regrid
      end if ;NRT or Reanalysis

    end if ;NetCDF

   end do ; VOC loop


  ;********************************************
  ; panel plots for consistency check
  ;-------------------
  ; MAP PLOT
  ;-------------------
  if (PLOT) then
    wks = gsn_open_wks(mapType,mapName)
    gsn_define_colormap(wks,"sunshine_9lev")        ; change colour map
    ;-------------------
    ; define resources 
    ; to use for plotting
    ;-------------------
    mapres = True
    mapres@tiMainString              = ""                  ; changing main large title
    mapres@gsnLeftString             = ""                  ; change left 
    mapres@gsnRightString            = tracer_emiss@units  ; change right title
    mapres@gsnFrame                  = False               ; do not advance frame
    mapres@gsnDraw		     = False	           ; don't draw it yet

    mapres@cnFillOn                  = True
    mapres@cnFillMode                = "CellFill"          ; fill as grid boxes not contours
    mapres@cnLineLabelsOn            = False               ; turn off countour labels
    mapres@cnLinesOn                 = False
    mapres@lbLabelBarOn              = False               ; turn off individual colorbars

    ;mapres@mpLimitMode               ="LatLon"            ; zoom to Australia
    ;  mapres@mpMinLatF               = -45
    ;  mapres@mpMaxLatF               = -10
    ;  mapres@mpMinLonF               = 100
     ; mapres@mpMaxLonF               = 160

    mapres@cnLevelSelectionMode      = "ManualLevels"      ; manually set the contour levels
      mapres@cnMinLevelValF          = 1e09                ; set the minimum contour level
      mapres@cnMaxLevelValF          = 5e10                ; set the maximum contour level
      mapres@cnLevelSpacingF         = 1e10                ; set the interval between contours

    ;-------------------
    ; do the plotting
    ;-------------------
    ;map1 = gsn_csm_contour_map_ce(wks,co2_all(0,:,:),mapres)

    mapres@gsnLeftString            = "spatial avg = "+ AvgOrigGrid(0) ; change left title
      map1 = gsn_csm_contour_map_ce(wks,tracer_emiss(0,:,:),mapres)

    mapres@gsnLeftString            = "spatial avg = "+ Avg_Regrid(0) ; change left title
      map2 = gsn_csm_contour_map_ce(wks,emiss_regrid(0,:,:),mapres)

    panel_res                       = True
      panel_res@txString            = "QFED "+ tracername +" emissions"
      panel_res@gsnPanelLabelBar    = True                ; add common colorbar
      panel_res@gsnPanelFigureStrings = (/"qfed high res","qfed low res"/)

    gsn_panel(wks,(/map1,map2/),(/2,1/),panel_res)

  end if    ; PLOT


end

