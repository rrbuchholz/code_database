;=======================================================;
;  diff_emiss.ncl
;=======================================================;
;
; Concepts illustrated:
;   - load CAM emission files
;   - perform difference on arrays
;   - determine max, min and avg difference globally
;   - plot map of the max average difference
;   - plot timeseries of percent average difference
;   
;   To run type:
;         ncl diff_emiss.ncl
;
;   Requires:
;         two emission files
;                                  RRB March 17, 2015
;=======================================================;
; load the libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------
  tracer = "CO2"
  year = 2014
  repository = "QFED_native"

  ; -------------------------------
  ; emission files
  ; -------------------------------
  ;e_file_1 = "/data14b/buchholz/qfed/cam_1.9x2.5/2012/qfed.emis_"+tracer+"_1.9x2.5_mol_2012.nc"
  ;e_file_1 = "/data14b/buchholz/qfed/cam_0.9x1.25/from_co2/v2.5/2014/qfed.emis_"+tracer+"_0.9x1.25_mol_2014.nc"
  ;e_file_1 = "/data14b/buchholz/qfed/cam_0.9x1.25/regridded/allyears/qfed.emis_"+tracer+"_0.9x1.25_mol_2014_2016.nc"
  ;e_file_1 = "/data14b/buchholz/gfas/cam_0.9x1.25/from_co2/2014/gfas.emis_fromgrib_"+tracer+"_0.9x1.25_mol_2014new.nc"

   emis_dir = "/data14b/buchholz/qfed/orig_0.25/co2_"+year+"/"
   e_file_1 = systemfunc ("ls "+emis_dir+"*"+year+"*.nc4")

  ;e_file_1 = "/data14b/buchholz/finn/cam_0.9x1.25/allyears/emissions-finn1.5_CO_bb_surface_2002-2017_0.9x1.25.nc"
  ;e_file_1 = "/data14b/buchholz/gfed/cmip6_cam_0.9x1.25/1750_2015/emissions-cmip6_"+tracer+"_bb_surface_1750-2015_0.9x1.25_c20170322.nc"


  ;------------
  ; toggles
  ;------------
  PLOT           = True
  TIMEPLOT       = False
  MONTHAVG       = True

  region_name =  "Australasia"
      latmin                         = -45               ; zoom to Australia
      latmax                         = -10
      lonmin                         = 100
      lonmax                         = 160

   ;   latmin                         = 20               ; zoom to North America
   ;   latmax                         = 60
   ;   lonmin                         = 220
   ;   lonmax                         = 300

    ;  latmin                         = -40               ; zoom to Amazon
    ;  latmax                         = 10
    ;  lonmin                         = 270
    ;  lonmax                         = 330


;--------------------------------------------
; end user input
;--------------------------------------------

;********************************************
; set up
  ; -------------------------------
  ; names of fire emission structure
  ; -------------------------------
  if (repository.eq."FINN") then
    fire_emiss           = "fire"
  else if (repository.eq."QFED_native") then
    fire_emiss           = "biomass"
  else if (repository.eq."CMIP6") then
    fire_emiss           = "emiss_bb"
  else
    fire_emiss           = "bb"
  end if
  end if
  end if
  time                 = "time"

  ; -------------------------------
  ; constants
  ; -------------------------------
   NAv = 6.022e23                    ; Avogadro's number, molecules mole^-1
   re   = 6.37122e06                 ; Earth radius (in metres)
   rad  = 4.0 * atan(1.0) / 180.0    ; Convert degrees to radians (pi radians per 180 deg)
   con  = re * rad                   ; constant for determining arc length 

  ; -------------------------------
  ; plotting parameters
  ; -------------------------------
  if (PLOT) then
    mapType = "png"
      mapType@wkWidth  = 1200
      mapType@wkHeight = 1200
    mapName = tracer+"_"+repository
  end if ;PLOT

  if (TIMEPLOT) then
    plotType = "x11"
    plotName = tracer+"_diff_ts"
  end if ;TIMEPLOT

  cr = "~C~"

;********************************************
; load files and extract
  if (repository.eq."QFED_native") then
    fin = addfiles(e_file_1, "r")
    ListSetType (fin, "cat") 
      emiss_in_dummy          = fin[:]->$fire_emiss$
      emiss_file1 = lonFlip(emiss_in_dummy)
       emiss_file1 = emiss_file1/(10000)        ; m-2 -> cm-2
       emiss_file1 = (emiss_file1*1000/28)*NAv  ; kg -> g -> mol -> molec
         emiss_file1@units = "molecules/cm2/s"
      file1_time := emiss_file1&time
  else
    fin1 = addfile(e_file_1, "r")
      time_dummy := fin1->time
      yfrac_dummy:= tofloat(cd_calendar(time_dummy,4))
      range_ind  := ind(yfrac_dummy.ge.2013.and.yfrac_dummy.lt.2017)
      file1_time = time_dummy(range_ind)
      emiss_dummy          = fin1->$fire_emiss$
      emiss_file1 = emiss_dummy(range_ind,:,:)
  end if

      yfrac = tofloat(cd_calendar(file1_time,4))
      time_split = tofloat(cd_calendar(file1_time,0))
      ;selected_ind = ind(time_split(:,1).eq.5)
      selected_ind = ind(time_split(:,0).eq.year)
      ndims = dimsizes(emiss_file1)
      test = dim_sum_n_Wrap(emiss_file1(selected_ind,:,:),0)

      mw = 28.
     if (repository.eq."CMIP6") then
       emiss_tg_dummy = emiss_file1(selected_ind,:,:)*86400; s - > d
       date = cd_calendar(file1_time(selected_ind),0)
       yyyy = tointeger(date(:,0))
       mm = tointeger(date(:,1))
       month_days = days_in_month(yyyy,mm)
       month_days_array = conform(emiss_tg_dummy, month_days, 0)
       emiss_tg_dummy = emiss_tg_dummy*month_days_array     ; d - > m
     else
       emiss_tg_dummy = emiss_file1(selected_ind,:,:)*86400          ; s - > d
     end if
      emiss_tg_dummy  = emiss_tg_dummy *100*100        ; cm^2 -> m^2
      emiss_tg_dummy  = (emiss_tg_dummy /NAv)*mw       ; molec -> mol -> g
      emiss_tg_dummy  = (emiss_tg_dummy /1e12)         ; g -> Tg

      emiss_tg = dim_sum_n_Wrap(emiss_tg_dummy ,0)

      lat = tofloat(test&lat)
       newlat = lat
       newlat(0)= -89.99999
       newlat(dimsizes(newlat)-1)= 89.99999   

      lon = tofloat(test&lon)
      nlat = dimsizes(lat)
      mlon = dimsizes(lon)
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
      emiss_tg = emiss_tg*wgt

test2 = dim_sum_n(dim_sum_n(emiss_tg,0),0)
print(test2)

      copy_VarMeta(test,emiss_tg)

printVarSummary(emiss_tg)

emiss_tg@_FillValue = -999
emiss_tg = where(ismissing(emiss_tg),0,emiss_tg)

  ;********************************************
  ;-------------------
  ; MAP PLOT
  ;-------------------
  if (PLOT) then
    wks = gsn_open_wks(mapType,mapName)
    ;gsn_define_colormap(wks,"WhiteYellowOrangeRed")        ; change colour map
    gsn_define_colormap(wks,"MPL_Greys")        ; change colour map
    ;-------------------
    ; define resources 
    ; to use for plotting
    ;-------------------
    mapres = True
    mapres@tiMainString              = ""                  ; changing main large title
    mapres@gsnLeftString             = ""                  ; change left 
  ;  mapres@gsnRightString            = emiss_diff@units    ; change right title
    mapres@gsnRightString            = ""                   ; change right title
    mapres@gsnFrame                  = False               ; do not advance frame
    mapres@gsnDraw		     = False	           ; don't draw it yet

    mapres@gsnLeftStringFontHeightF  = 0.018
    mapres@gsnRightStringFontHeightF  = 0.018
    mapres@tmXBLabelFontHeightF        =0.018
    mapres@tmYLLabelFontHeightF        =0.018

    mapres@cnFillOn                  = True
    mapres@cnFillMode                = "CellFill"          ; fill as grid boxes not contours
    mapres@cnLineLabelsOn            = False               ; turn off countour labels
    mapres@cnLinesOn                 = False
    mapres@lbLabelBarOn              = True               ; turn off individual colorbars
    mapres@lbTitleString             = "Tg"             ; Label Bar title
    mapres@lbOrientation             = "Vertical"     ; Label bar location

    mapres@mpLimitMode               ="LatLon"            ; zoom to Australia
      mapres@mpMinLatF               = latmin
      mapres@mpMaxLatF               = latmax
      mapres@mpMinLonF               = lonmin
      mapres@mpMaxLonF               = lonmax

    mapres@cnLevelSelectionMode      = "ManualLevels"      ; manually set the contour levels
      ;mapres@cnMinLevelValF          = -5e11                ; set the minimum contour level
      ;mapres@cnMaxLevelValF          = 5e11                ; set the maximum contour level
      ;mapres@cnLevelSpacingF         = 5e10                ; set the interval between contours

      mapres@cnMinLevelValF          = 0.                 ; set the minimum contour level
      mapres@cnMaxLevelValF          = 1.2               ; set the maximum contour level
      mapres@cnLevelSpacingF         = 0.06               ; set the interval between contours


    ;-------------------
    ; do the plotting
    ;-------------------
    panel_res                       = True
      panel_res@txString            = "CAM-chem "+ tracer +" emissions"
      panel_res@gsnPanelLabelBar    = True                ; add common colorbar

      ;mapres@gsnLeftString            = repository+" "+year+" "+tracer; change left title
    map1 = gsn_csm_contour_map_ce(wks,emiss_tg,mapres)


    ;-------------------
    ; add text for regions
    ;-------------------
    ;drawNDCGrid(wks)
       txres = True
        txres@txFontHeightF  = 0.024
        ;txres@txFont         = "helvetica-bold"
        txres@txJust         = "BottomLeft"
        txres@txFontColor    = "black"
        txres@txPerimOn      = True
        txres@txBackgroundFillColor="white"

     text = gsn_add_text(wks,map1,repository+" "+year+" "+tracer, 101, -44,txres)

    ;gsn_panel(wks,(/map1,map2,map3/),(/3,1/),panel_res)
    draw(map1)
    frame(wks)

  end if    ; PLOT

  ;********************************************
  ;-------------------
  ; TIME PLOT
  ;-------------------
  if (TIMEPLOT) then
    if (MONTHAVG) then
      time_frac = yyyymm_to_yyyyfrac(yyyymm,0)
    else
      time_frac = cd_calendar(emiss_file1&time,4)
    end if

    wks2   = gsn_open_wks (plotType,plotName)                ; open workstation

    res                  = True                     ; plot mods desired
    res@tiMainString     = "Timeseries of % difference in global mean for "+ tracer          ; add title

    plot  = gsn_csm_xy (wks2,time_frac,PercDiff,res) ; create plot

    res@tiMainString     = "Timeseries of % difference in "+region_name+" mean for "+ tracer          ; add title
    ;plot  = gsn_csm_xy (wks2,time_frac,region_perc_diff,res) ; create plot

  end if ;TIMEPLOT


end

