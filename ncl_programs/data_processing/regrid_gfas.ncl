;=======================================================;
;  regrid_gfas.ncl
;=======================================================;
;
; Concepts illustrated:
;   - Load qfas BB files
;   - Regrid from 0.1 x 0.1 to 1.9 x2.5
;                          or to 0.94 x 1.2
;   - Regrid lon gridding,
;          -180 to 180 gfas : 0 to 360 CAM-chem
;   - Write out to netCDF - one file per tracer per year
;                         - kept at daily time resolution
;   
;   To run type:
;         ncl regrid_gfas.ncl.ncl
;
;   Requires:
;         path to qfas files separated into years
;         path to MOZART molecular weight file
;                                  RRB September 11, 20157
;=======================================================;
; load the libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------
  year = 2016
  outres = "0.94x1.2"
  input_species = "co"
  species = "CO"
  outpath = "/data14b/buchholz/gfas/cam_"+outres+"/regridded/"+year+"/"

  ; -------------------------------
  ; gfas files
  ; -------------------------------
  gfas_dir = "/data14b/buchholz/gfas/orig_0.1/"
  gfas_files = systemfunc ("ls "+gfas_dir+"*_"+input_species+"_*"+year+"*.nc")

  ; -------------------------------
  ; MOZART molecular weights
  ; -------------------------------
  molwts = "/home/buchholz/data/species_molwts.txt"

  ;------------
  ; toggles
  ;------------
  netCDF         = True                       ; for netCDF output
  PLOT           = True
;--------------------------------------------
; end user input
;--------------------------------------------

;********************************************
; set up
  ; -------------------------------
  ; names of gfas data structures
  ; determined from an ncl_filedump
  ; -------------------------------
  gfas_tracer        = input_species+"fire"
  gfas_time          = "time"

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
  ; gfas load
  ; -------------------------------
    fin = addfiles(gfas_files, "r")            ; read in
    ListSetType (fin, "cat") 
      tracer_dummy       = fin[:]->$gfas_tracer$
      tracer_all:= short2flt(tracer_dummy(:,::-1,:)) ; reorder N->S to S->N
      copy_VarAtts(tracer_dummy,tracer_all)
      tracer_all!1 = "latitude"
      tracer_all&latitude = tracer_dummy&latitude(::-1)
      tracer_all!2 = "longitude"
      tracer_all&longitude = tracer_dummy&longitude
     printVarSummary(tracer_all)

      ; load and convert time format
      time_dummy       = fin[:]->$gfas_time$
      time = cd_convert(time_dummy, "hours since 1900-01-01 00:00:0.0" )
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

      delete(tracer_all&time )
      tracer_all!0 = "time"
      tracer_all&time = (time)

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
  ; Regrid and gfas for CAM-chem input
  ; -------------------------------
    tracer_emiss:= tracer_all
      copy_VarAtts(tracer_all,tracer_emiss)
      copy_VarCoords(tracer_all,tracer_emiss)
     printVarSummary(tracer_emiss)

    ; -------------------------------
    ; convert to CAM-Chem units
    ; kg s-1 m-2 to molec. cm-2 s-1
    ; -------------------------------
     print(species)
     mw = tofloat(mol_wts(ind(mol_wts(:,0).eq.species),1))
     print(species+" MW: "+mw)
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
   print("Maximum diff: lowres: "+sprintf("%2.2e",AvgOrigGrid(max_ind))+\
         "  highres: "+sprintf("%2.2e",Avg_Regrid(max_ind))+   \
         "    diff: "+sprintf("%2.2e",AvgDiff(max_ind))+  \
         "   percent diff: "+sprintf("%2.2f",PercDiff(max_ind))+"%")

   print("Maximum percent diff in "+species+\
         " from regridding: "+sprintf("%2.2f",PercDiff(max_ind))+"%"+\
         " on date: " + cd_calendar(tracer_all&time(max_ind),2))
   print("-------------------------------------------------")

    ;--------------------------------------------
    ; Write out to an netCDF file
    ;--------------------------------------------
    if (netCDF) then
      ;-------------------
      ; create file for each 
      ; CAM-chem species
      ;-------------------
      outfilename = "gfas.emis_"+species+"_"+outres+"_mol_"+year+".nc"
      fout = addfile(outpath+outfilename, "c")

      ;------------
      ; File 
      ; Attributes
      ;------------
      setfileoption(fout, "DefineMode",True)
      fAtt                      = True
        fAtt@molecular_weight   = mw
        fAtt@conventions        = "CF"
        fAtt@history            = species+" is from Global Fire Assimilation System (GFAS),"+\
                                  "regridded from 0.1 x 0.1 deg."
        fAtt@reference          = "Contains modified Copernicus Atmosphere Monitoring Service Information [dwld 2017]"
        fAtt@author             = "R. R. Buchholz"
        fAtt@creation_date      = systemfunc ("date")
        fAtt@source             = "GFASv1.2: ECMWF Copernicus Atmosphere Monitoring Service (CAMS)"

        fAtt@title              = "Emissions of "+ species + " from GFAS, daily"

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
      emiss_regrid@long_name = species +" gfas fire emissions"
      emiss_regrid@vmax      = max(emiss_regrid)
      emiss_regrid@vmin      = min(emiss_regrid)
      delete(emiss_regrid@missing_value)
      delete(emiss_regrid@fmissing_value)

       ;--- date
         fout->date             = date
       ;--- emissions
         fout->bb               = emiss_regrid
    end if ;NetCDF

  tracername := species

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
      mapres@cnMinLevelValF          = 1e11                ; set the minimum contour level
      mapres@cnMaxLevelValF          = 2.5e12                ; set the maximum contour level
      mapres@cnLevelSpacingF         = 1e11                ; set the interval between contours

    ;-------------------
    ; do the plotting
    ;-------------------
    ;map1 = gsn_csm_contour_map_ce(wks,co2_all(0,:,:),mapres)

    mapres@gsnLeftString            = "spatial avg = "+ AvgOrigGrid(0) ; change left title
      map1 = gsn_csm_contour_map_ce(wks,tracer_emiss(0,:,:),mapres)

    mapres@gsnLeftString            = "spatial avg = "+ Avg_Regrid(0) ; change left title
      map2 = gsn_csm_contour_map_ce(wks,emiss_regrid(0,:,:),mapres)

    panel_res                       = True
      panel_res@txString            = "gfas "+ tracername +" emissions"
      panel_res@gsnPanelLabelBar    = True                ; add common colorbar
      panel_res@gsnPanelFigureStrings = (/"gfas high res","gfas low res"/)

    gsn_panel(wks,(/map1,map2/),(/2,1/),panel_res)

  end if    ; PLOT


end

