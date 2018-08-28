;=======================================================;
;  combine_gfas_finn_ers.ncl
;=======================================================;
;
; Concepts illustrated:
;   - Load qfas CO2 files
;   - Load Christine's emission values
;         (separated into 4 land types)
;   - Calculate emission factors
;   - Multiply CO2 by emission factors for each species
;      and change units to molec/cm^2/s
;   - Load Christine's VOC speciation 
;   - For VOC speciation - multiply NMOC
;         (total VOCs) by speciation factor
;   - Regrid from 0.1 x 0.1 to 1.9 x2.5
;                          or to 0.94 x 1.2
;   - Regrid lon gridding,
;          -180 to 180 gfas : 0 to 360 CAM-chem
;   - Write out to netCDF - one file per tracer per year
;                         - kept at daily time resolution
;   
;   To run type:
;         ncl combine_gfas_finn_ers.ncl
;
;   Requires:
;         path to gfas files separated into years
;         path to gfas land type file
;           gfas land cover classes and fuel type:
;           01: savannah                       SA
;           02: savannah with organic soil     SA
;           03: agriculture                    AG
;           04: agriculture with organic soil  AG
;           05: tropical forest                TF
;           06: peat                         PEAT
;           07: extratropical forest           EF
;           08: extratropical forest with      EF
;               organic soil
;         path to MOZART molecular weight file
;         path to FINN emission ratios file
;         path to FINN VOC speciatio
;         
;                                  RRB September 11, 20157
;=======================================================;
; load the libraries
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------
  if (.not. isvar("year")) then      ; is YYYYMMDD=<value> from command line?
       year = 2014
  end if
  outres = "0.9x1.25"
  input_species = "co2"
  lg_input_species = "CO2"
  output_species = "CO"
  outpath = "/data14b/buchholz/gfas/cam_"+outres+"/from_co2/"+year+"/"

  ; -------------------------------
  ; gfas files
  ; -------------------------------
  gfas_dir = "/data14b/buchholz/gfas/"
  gfas_files = systemfunc ("ls "+gfas_dir+"orig_0.1/*_"+input_species+"_*"+year+".grib")
  gfas_landcover_file = systemfunc ("ls "+gfas_dir+"GFAS_landcover_dlc.nc")

  ; -------------------------------
  ; MOZART molecular weights
  ; -------------------------------
  molwts = "/home/buchholz/data/species_molwts.txt"

  ; -------------------------------
  ; FINN emission ratios
  ; -------------------------------
  finn_emiss = "/net/modeling1/home/buchholz/data/GFAS_base_EFs_20180523.csv"
  finn_VOC = "/net/modeling1/home/buchholz/data/GFAS_VOC_EFs_20180523.csv"


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
  ; names of gfas data structures
  ; determined from an ncl_filedump
  ; -------------------------------
  ;gfas_tracer        = input_species+"fire"
  ;gfas_time          = "time"
  gfas_tracer        = lg_input_species+"FIRE_GDS0_SFC_ave24h"
  gfas_time          = "initial_time0_hours"
  gfas_vegtype       = "var94"

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

  if (outres.eq."0.9x1.25") then
   ; higher res - 1 deg
   newlon  = fspan(0,358.75, 288)
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
  var_names = where(var_names.eq."NOX AS NO","ignore",var_names)   ; ignore NOx - use NO and NO2
  var_names = where(var_names.eq."SO2","SO2_orig",var_names)   ;

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

  ;printVarSummary(speciate)

  ; -------------------------------
  ; compute factors
  ; -------------------------------
   e_factors = e_fields
   if (input_species.eq."co2") then
     do k=0,nlines-1                                      
       e_factors(k,:) = e_fields(k,:)/e_fields(k,0)
     end do
   else if (input_species.eq."co") then
     do k=0,nlines-1                                      
       e_factors(k,:) = e_fields(k,:)/e_fields(k,1)
     end do
   end if
   end if
     e_factors@units = "g/kg per g/kg"

   ;printVarSummary(e_factors)

  ; -------------------------------
  ; gfas load land cover
  ; -------------------------------
    lcin = addfile(gfas_landcover_file, "r")            ; read in
      landcover_dummy       = lcin->$gfas_vegtype$
      landcover_dummy       = landcover_dummy(:,::-1,:) ; Flip the latitude dimension 

  ; -------------------------------
  ; create emission ratio and emission factor maps
  ; -------------------------------
;          Land cover type                    Fuel Type
;           01: savannah                       SA
;           02: savannah with organic soil     SA
;           03: agriculture                    AG
;           04: agriculture with organic soil  AG
;           05: tropical forest                TF
;           06: peat                         PEAT
;           07: extratropical forest           EF
;           08: extratropical forest with      EF
;   Fuel type order in EF file:
;   SA, TF, PEAT, EF, AG

  landcover = rm_single_dims(landcover_dummy)
  lc_lat = landcover&lat
  lc_lon = landcover&lon
  ind_sa = ind(ltype.eq."SA")
  ind_tf = ind(ltype.eq."TF")
  ind_peat = ind(ltype.eq."PEAT")
  ind_ef = ind(ltype.eq."EF")
  ind_ag = ind(ltype.eq."AG")

  num_tracers = dimsizes(e_factors(0,:))
  num_voc = dimsizes(speciate(:,0))

  EF_map = new((/num_voc,dimsizes(lc_lat), dimsizes(lc_lon)/), float)
  ER_map = new((/num_tracers,dimsizes(lc_lat), dimsizes(lc_lon)/), float)

  do i=0,num_tracers-1
    ER_map(i,:,:) = where(landcover.eq.0, ER_map@_FillValue,ER_map(i,:,:)) ; Ocean - missing values
    ER_map(i,:,:)  = where(landcover.eq.1.or.landcover.eq.2, e_factors(ind_sa,i), ER_map(i,:,:)) ; SA
    ER_map(i,:,:)  = where(landcover.eq.5, e_factors(ind_tf,i), ER_map(i,:,:)) ; TF
    ER_map(i,:,:)  = where(landcover.eq.6, e_factors(ind_peat,i), ER_map(i,:,:)) ; PEAT
    ER_map(i,:,:)  = where(landcover.eq.7.or.landcover.eq.8, e_factors(ind_ef,i), ER_map(i,:,:)) ; EF
    ER_map(i,:,:) = where(landcover.eq.3.or.landcover.eq.4, e_factors(ind_ag,i), ER_map(i,:,:)) ; AG
  end do

  ER_map!0 = "tracer"
  ER_map!1 = landcover!0
  ER_map&lat = landcover&lat
  ER_map!2 = landcover!1
  ER_map&lon = landcover&lon
  ;printVarSummary(ER_map)
  print("Loaded emission ratios")

  do i=0,num_voc-1
    EF_map(i,:,:) = where(landcover.eq.0, EF_map@_FillValue,EF_map(i,:,:)) ; Ocean - missing values
    EF_map(i,:,:)  = where(landcover.eq.1.or.landcover.eq.2, speciate(i,ind_sa), EF_map(i,:,:)) ; SA
    EF_map(i,:,:)  = where(landcover.eq.5, speciate(i,ind_tf), EF_map(i,:,:)) ; TF
    EF_map(i,:,:)  = where(landcover.eq.6, speciate(i,ind_peat), EF_map(i,:,:)) ; PEAT
    EF_map(i,:,:)  = where(landcover.eq.7.or.landcover.eq.8, speciate(i,ind_ef), EF_map(i,:,:)) ; EF
    EF_map(i,:,:) = where(landcover.eq.3.or.landcover.eq.4, speciate(i,ind_ag), EF_map(i,:,:)) ; AG
  end do

  EF_map!0 = "voc"
  EF_map!1 = landcover!0
  EF_map&lat = landcover&lat
  EF_map!2 = landcover!1
  EF_map&lon = landcover&lon
  ;printVarSummary(EF_map)
  print("Loaded VOC emission factors")


  ; -------------------------------
  ; gfas load
  ; -------------------------------
    fin = addfile(gfas_files, "r")            ; read in
    ;ListSetType (fin, "cat") 
      tracer_all       = fin->$gfas_tracer$
        tracer_all = tracer_all(:,::-1,:) ; Flip the latitude dimension 

      ; load and convert time format
      time_dummy       = fin->$gfas_time$
      time = cd_convert(time_dummy, "hours since 1800-01-01 00:00" )
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

      delete(tracer_all&initial_time0_hours )
      tracer_all!0 = "time"
      tracer_all&time = (time)
      tracer_all!1 = "latitude"
      tracer_all!2 = "longitude"


  ; -------------------------------
  ; gfas res for sums/avgs
  ; -------------------------------
     clat_q = cos(tracer_all&latitude * rad) ; cosine of latitude
     dlon_q = (tracer_all&longitude(3) - tracer_all&longitude(2))  ; assume dlon is constant
     dlat_q = (tracer_all&latitude(3) - tracer_all&latitude(2))  ; assume dlat is constant
     dx_q   = con * dlon_q * clat_q   ; dx at each latitude
     dy_q   = con * dlat_q            ; dy is constant
     dydx_q = dy_q * dx_q             ; dydx(nlat)

     wgt_gfas  = new((/dimsizes(tracer_all&latitude), dimsizes(tracer_all&longitude)/), float)
     wgt_gfas  = conform(wgt_gfas, tofloat(dydx_q), 0)


  ;********************************************
  ; Non- VOCs
  ;--- FINN                    GFAS
  ;                          kg s-1 m-2

  ;do tracer = 0,dimsizes(var_names)-1
  ;do tracer = 2,4
    ;if (var_names(tracer).eq."NMOC".or.\
     ;   var_names(tracer).eq."ignore".or.\
     ;   var_names(tracer).eq."PM2.5".or.\
     ;   var_names(tracer).eq."PM10") then
      ; Apply speciation values to total vocs
      ; (NMOC) outside this loop
      ; and ignore PM2.5 and PM10
      ;continue
    ;else
      ; -------------------------------
      ; calculate emissions for non-VOCs
      ; -------------------------------
    printVarSummary(tracer_all)
    printVarSummary(ER_map(1,:,:))
      factor_multiplier = conform_dims(dimsizes(tracer_all), ER_map(1,:,:), (/1,2/))
    printVarSummary(factor_multiplier)
      tracer_emiss:= tracer_all * factor_multiplier   ; test for CO
    ;end if
      tracer_emiss = where(ismissing(tracer_emiss), 0, tracer_emiss)
    copy_VarAtts(tracer_all,tracer_emiss)
    copy_VarCoords(tracer_all,tracer_emiss)
    printVarSummary(tracer_emiss)

  ;********************************************
  ; Regrid and gfas for CAM-chem input
    ; -------------------------------
    ; convert to CAM-Chem units
    ; kg s-1 m-2 to molec. cm-2 s-1
    ; -------------------------------
     print(output_species)
     if (output_species.eq."SO2_orig")
        mw = tofloat(mol_wts(ind(mol_wts(:,0).eq."SO2"),1))
     else
        mw = tofloat(mol_wts(ind(mol_wts(:,0).eq.output_species),1))
     end if
     print(output_species+" MW: "+mw)
     tracer_emiss = tracer_emiss/(10000)        ; m-2 -> cm-2
     tracer_emiss = (tracer_emiss*1000/mw)*NAv  ; kg -> g -> mol -> molec
       tracer_emiss@units = "molecules/cm2/s"

    ; -------------------------------
    ; regrid to CAM-chem structure
    ; 1.9 x 2.5 or 0.94 x 1.2
    ; -------------------------------
     opt    = False
     emiss_regrid  = area_conserve_remap_Wrap(tracer_emiss&longitude,tracer_emiss&latitude, \
                                         tracer_emiss , \
                                         newlon, newlat, opt)  ; (ntim,nlat,nlon)
     printVarSummary(emiss_regrid)

     ;--- sanity check
     AvgOrigGrid = wgt_areaave2 (tracer_emiss , wgt_gfas, 0)
     Avg_Regrid = wgt_areaave2 (emiss_regrid, wgt_CAM, 0)
     AvgDiff = AvgOrigGrid-Avg_Regrid
     PercDiff = (AvgDiff/AvgOrigGrid)*100
     MaxDiff = max(PercDiff)
     max_ind = ind(PercDiff.eq.MaxDiff)
;max_ind = 0
print(MaxDiff)

   print("Maximum diff: highres: "+sprintf("%2.2e",AvgOrigGrid(max_ind))+\
         "  lowres: "+sprintf("%2.2e",Avg_Regrid(max_ind))+   \
         "    diff: "+sprintf("%2.2e",AvgDiff(max_ind))+  \
         "   percent diff: "+sprintf("%2.2f",PercDiff(max_ind))+"%")

   print("Maximum percent diff in "+output_species+\
         " from regridding: "+sprintf("%2.2f",PercDiff(max_ind))+"%"+\
         " on date: " + cd_calendar(tracer_all&time(max_ind),2))
   print("-------------------------------------------------")


  tracername := output_species

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
    mapres@gsnAddCyclic              = True
 
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
      mapres@cnMaxLevelValF          = 2.5e10                ; set the maximum contour level
      mapres@cnLevelSpacingF         = 1e09                ; set the interval between contours

    ;-------------------
    ; do the plotting
    ;-------------------
    ;map1 = gsn_csm_contour_map_ce(wks,co2_all(0,:,:),mapres)

    mapres@gsnLeftString            = "spatial avg = "+ AvgOrigGrid(0) ; change left title
      map1 = gsn_csm_contour_map_ce(wks,tracer_emiss(0,:,:),mapres)

    mapres@gsnLeftString            = "spatial avg = "+ Avg_Regrid(0) ; change left title
      map2 = gsn_csm_contour_map_ce(wks,emiss_regrid(0,:,:),mapres)

     info    = (/ " 1  savannah                    ", \  ; n=0
                " 2  savannah + organic            ", \
                " 3  agriculture                   ", \
                " 4  agriculture + organic         ", \
                " 5  tropical forest               ", \
                " 6  peat                          ", \
                " 7  extratropical forest          ", \
                " 8  extratropical forest + organic" /) ; n=8
    ;mapres@cnLevelSelectionMode = "ExplicitLevels" ; set explict contour levels
    ;mapres@cnLevels         = (/1,2,3,4,5,6,7,8/)
    mapres@cnFillPalette       = "default"
    mapres@pmLegendDisplayMode      = "Always"        ; turn on legend

    ;mapres@gsnLeftString            = "spatial avg = "+ AvgOrigGrid(0) ; change left title
      ;map3 = gsn_csm_contour_map_ce(wks,landcover,mapres)
      ;map3 = gsn_csm_contour_map_ce(wks,EF_map(1,:,:),mapres)


    panel_res                       = True
      panel_res@txString            = "gfas "+ tracername +" emissions"
      panel_res@gsnPanelLabelBar    = True                ; add common colorbar
      panel_res@gsnPanelFigureStrings = (/"gfas high res","gfas low res"/)

    gsn_panel(wks,(/map1,map2/),(/2,1/),panel_res)
    ;draw(map3)
    frame(wks)

  end if    ; PLOT

    ;--------------------------------------------
    ; Write out to an netCDF file
    ;--------------------------------------------
    if (netCDF) then
      ;-------------------
      ; create file for each 
      ; CAM-chem species
      ;-------------------
      outfilename = "gfas.emis_fromgrib_"+output_species+"_"+outres+"_mol_"+year+"new.nc"
      fout = addfile(outpath+outfilename, "c")

      ;------------
      ; File 
      ; Attributes
      ;------------
      setfileoption(fout, "DefineMode",True)
      fAtt                      = True
        fAtt@molecular_weight   = mw
        fAtt@conventions        = "CF"
        fAtt@history            = output_species+" is from Global Fire Assimilation System (GFAS),"+\
                                  "regridded from 0.1 x 0.1 deg,  with  FINN emission ratios applied"
        fAtt@reference          = "Contains modified Copernicus Atmosphere Monitoring Service Information [dwld 2018]"
        fAtt@author             = "R. R. Buchholz (buchholz@ucar.edu)"
        fAtt@creation_date      = systemfunc ("date")
        fAtt@source             = "GFASv1.2: ECMWF Copernicus Atmosphere Monitoring Service (CAMS)"+\
                                  "FINN v1.6: C. Wiedinmyer 2015"
        fAtt@title              = "Emissions of "+ output_species + " from FINN v1.6 x GFAS, daily"

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
      emiss_regrid@long_name = output_species +" gfas/FINN fire emissions"
      emiss_regrid@vmax      = max(emiss_regrid)
      emiss_regrid@vmin      = min(emiss_regrid)
      ;delete(emiss_regrid@missing_value)
      ;delete(emiss_regrid@fmissing_value)

       ;--- date
         fout->date             = date
       ;--- emissions
         fout->bb               = emiss_regrid
    end if ;NetCDF

end

