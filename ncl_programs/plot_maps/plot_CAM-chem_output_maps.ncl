;=======================================================;
;  plot_CAM-chem_output_maps.ncl.ncl
;=======================================================;
;
; Concepts illustrated:
;   - load CAM output files from automated diagnostic
;   
;   To run type:
;         ncl plot_CAM-chem_output_maps.ncl.ncl
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
  tracer = "jno2"
  region = "NAmerica"
  timeslice = "JJA"

  ; Plot definitions
    units = "/s"
    maxlev = 8.0e-03
    lev_spacing = 0.2e-03

   STATIONS = False

  ; -------------------------------
  ; file location
  ; -------------------------------
  in_folder = "/glade/work/buchholz/CAM_chem_output/anth_v_noanth/"

  camfile_1 = systemfunc ("ls "+in_folder+"/anth/*"+timeslice+"*.nc")

  camfile_2 = systemfunc ("ls "+in_folder+"/noanth/*"+timeslice+"*.nc")


  ;------------
  ; toggles
  ;------------
  PLOT           = True

  if (region.eq."World") then
      latmin                         = -90               ; zoom to World
      latmax                         = 90
      lonmin                         = 0
      lonmax                         = 360
      loncenter                      = 180
      region_name =  "World"
  else if (region.eq."Australia") then
     latmin                          = -50               ; zoom to Australia
      latmax                         = -10
      lonmin                         = 100
      lonmax                         = 180
      loncenter                      = 140
      region_name =  "Australia"
  else if (region.eq."NAmerica") then
      latmin                         = 20               ; zoom to North America
      latmax                         = 60
      lonmin                         = 220
      lonmax                         = 300
      loncenter                      = 260
      region_name =  "NorthAmerica"
  else if (region.eq."Amazon") then
    ;  latmin                         = -40               ; zoom to Amazon
    ;  latmax                         = 10
    ;  lonmin                         = 270
    ;  lonmax                         = 330
  end if
  end if
  end if
  end if


;--------------------------------------------
; end user input
;--------------------------------------------

;********************************************
; set up
   NAv = 6.022e23                    ; Avogadro's number, molecules mole^-1
  ; -------------------------------
  ; plotting parameters
  ; -------------------------------
  if (PLOT) then
    mapType = "x11"
    mapName = "~/"+tracer+"_"+region+"_diff"
    mapType@wkWidth = 1200
    mapType@wkHeight = 1200 
  end if ;PLOT


  cr = "~C~"

;********************************************
;-------------------
; load files and extract
;-------------------

  if (units.eq."ppt") then
    divisor = 1e-12
  else if (units.eq."ppb") then
    divisor = 1e-09
  else if (units.eq."kg/m2/sec") then
    divisor = 1
  else if (units.eq."aod".or.units.eq."K".or.units.eq."W/m2"\
           .or.units.eq."/s".or.units.eq."fraction") then
    divisor = 1
  end if
  end if
  end if
  end if
  fin = addfiles(camfile_1, "r")
   if (tracer.eq."ISOPNITA") then
     tracer_fields_1_a  = fin[:]->$tracer$
     tracer_fields_1_b  = fin[:]->ISOPNITB
     tracer_fields_1 = tracer_fields_1_a + tracer_fields_1_b
     copy_VarMeta(tracer_fields_1_a,tracer_fields_1)
     tracer_fields_1= tracer_fields_1/divisor
   else
     tracer_fields_1  = fin[:]->$tracer$
     tracer_fields_1= tracer_fields_1/divisor
   end if

  fin2 = addfiles(camfile_2, "r")
   if (tracer.eq."ISOPNITA") then
     tracer_fields_2_a  = fin2[:]->$tracer$
     tracer_fields_2_b  = fin2[:]->ISOPNITB
     tracer_fields_2 = tracer_fields_2_a + tracer_fields_2_b
     copy_VarMeta(tracer_fields_2_a,tracer_fields_2)
     tracer_fields_2= tracer_fields_2/divisor
   else
     tracer_fields_2  = fin2[:]->$tracer$
     tracer_fields_2= tracer_fields_2/divisor
   end if

printVarSummary(tracer_fields_1)
;-------------------
; calculations
;-------------------

  if (tracer.eq."MEG_ISOP".or.tracer.eq."AEROD_v"\
     .or.tracer.eq."AODVIS".or.tracer.eq."AODVISdn"\
     .or.tracer.eq."AODDUST".or.tracer.eq."FSNS"\
     .or.tracer.eq."FSDS".or.tracer.eq."FLDS"\
     .or.tracer.eq."CLDTOT") then
    glob_avg = dim_avg_n(tracer_fields_1(:,{20:60},{220:300}), (/1,2/))
    print(glob_avg)
    glob_avg_array = conform_dims(dimsizes(tracer_fields_1),glob_avg,(/0/))
  else
    glob_avg = dim_avg_n(tracer_fields_1(:,:,{20:60},{220:300}), (/2,3/))
    ;glob_avg = dim_avg_n(tracer_fields_1(:,:,{-10:-50},{100:180}), (/2,3/))
    print(glob_avg)
    glob_avg_array = conform_dims(dimsizes(tracer_fields_1),glob_avg,(/0,1/))
  end if


  rel_glob_diff  = (tracer_fields_1-tracer_fields_2)/glob_avg_array
    copy_VarAtts(tracer_fields_1, rel_glob_diff)
    copy_VarCoords(tracer_fields_1, rel_glob_diff)

  rel_glob_avg  = tracer_fields_1/glob_avg_array
    copy_VarAtts(tracer_fields_1, rel_glob_avg)
    copy_VarCoords(tracer_fields_1, rel_glob_avg)
   

;********************************************
  ;-------------------
  ; MAP PLOT
  ;-------------------
  if (PLOT) then
    wks = gsn_open_wks(mapType,mapName)
    gsn_define_colormap(wks,"BlAqGrYeOrRe")        ; change colour map
    ;-------------------
    ; define resources 
    ; to use for plotting
    ;-------------------
    mapres = True
    mapres@tiMainString              = ""                  ; changing main large title
    mapres@gsnFrame                  = False               ; do not advance frame
    mapres@gsnDraw		     = False	           ; don't draw it yet
    mapres@gsnMaximize               = True  

    mapres@gsnLeftStringFontHeightF  = 0.016
    mapres@gsnRightStringFontHeightF = 0.016

    mapres@cnFillOn                  = True
    mapres@cnFillMode                = "CellFill"          ; fill as grid boxes not contours
    mapres@cnLineLabelsOn            = False               ; turn off countour labels
    mapres@cnLinesOn                 = False
    mapres@lbLabelBarOn              = True               ; turn off individual colorbars

    mapres@mpLimitMode               ="LatLon"            ; zoom to Australia
      mapres@mpMinLatF               = latmin
      mapres@mpMaxLatF               = latmax
      mapres@mpMinLonF               = lonmin
      mapres@mpMaxLonF               = lonmax
      mapres@mpCenterLonF            = loncenter

    mapres@cnLevelSelectionMode      = "ManualLevels"      ; manually set the contour levels
      mapres@cnMinLevelValF          = 0.                  ; set the minimum contour level
      mapres@cnMaxLevelValF          = maxlev              ; set the maximum contour level
      mapres@cnLevelSpacingF         = lev_spacing         ; set the interval between contours

    ;-------------------
    ; do the plotting
    ;-------------------
    panel_res                       = True
      panel_res@gsnMaximize               = True  
      panel_res@txString            = ""
      panel_res@gsnPanelLabelBar    = False                ; add common colorbar
      mapres@gsnRightString        = units
      mapres@gsnLeftString     = "CAM-chem surface "+ tracer + " with Anthropogenic emissions " +timeslice
      ;mapres@gsnLeftString     = "CAM-chem surface ISOPNITA+B with Anthropogenic emissions " +timeslice

      mapres@cnFillPalette       = "BlAqGrYeOrRe"
    if (tracer.eq."MEG_ISOP".or.tracer.eq."AEROD_v"\
     .or.tracer.eq."AODVIS".or.tracer.eq."AODVISdn"\
     .or.tracer.eq."AODDUST".or.tracer.eq."FSNS"\
     .or.tracer.eq."FSDS".or.tracer.eq."FLDS"\
     .or.tracer.eq."CLDTOT") then
      map1 = gsn_csm_contour_map_ce(wks,tracer_fields_1(0,:,:),mapres)
    else
      map1 = gsn_csm_contour_map_ce(wks,tracer_fields_1(0,55,:,:),mapres)
    end if

      mapres@gsnLeftString     = "CAM-chem surface "+ tracer + " without Anthropogenic emissions "+timeslice
      ;mapres@gsnLeftString     = "CAM-chem surface ISOPNITA+B without Anthropogenic emissions " +timeslice
    if (tracer.eq."MEG_ISOP".or.tracer.eq."AEROD_v"\
     .or.tracer.eq."AODVIS".or.tracer.eq."AODVISdn"\
     .or.tracer.eq."AODDUST".or.tracer.eq."FSNS"\
     .or.tracer.eq."FSDS".or.tracer.eq."FLDS"\
     .or.tracer.eq."CLDTOT") then
      map2 = gsn_csm_contour_map_ce(wks,tracer_fields_2(0,:,:),mapres)
    else
      map2 = gsn_csm_contour_map_ce(wks,tracer_fields_2(0,55,:,:),mapres)
    end if

     mapres@cnFillPalette       = "WhiteYellowOrangeRed"
     mapres@cnMinLevelValF          = 0              ; set the minimum contour level
     mapres@cnMaxLevelValF          = 1.               ; set the maximum contour level
     mapres@cnLevelSpacingF         = 0.05                ; set the interval between contours
     mapres@gsnLeftString     = "Anth_sim concentrations relative to N. America anth_sim average"   ;
     mapres@gsnRightString     = "" 
    if (tracer.eq."MEG_ISOP".or.tracer.eq."AEROD_v"\
     .or.tracer.eq."AODVIS".or.tracer.eq."AODVISdn"\
     .or.tracer.eq."AODDUST".or.tracer.eq."FSNS"\
     .or.tracer.eq."FSDS".or.tracer.eq."FLDS"\
     .or.tracer.eq."CLDTOT") then
      map3 = gsn_csm_contour_map_ce(wks,rel_glob_avg(0,:,:),mapres)
    else
      map3 = gsn_csm_contour_map_ce(wks,rel_glob_avg(0,55,:,:),mapres)
    end if

     mapres@gsnLeftString     = "Difference between simulations (anth - no_anth), relative to N. America anth_sim average"   ;
     ;mapres@gsnLeftString     = "Difference between simulations (anth - no_anth)"   ;
     ;mapres@gsnRightString     = "W/m2" 
     mapres@cnFillPalette       = "hotcold_18lev"
     mapres@cnMinLevelValF          = -1.             ; set the minimum contour level
     mapres@cnMaxLevelValF          = 1.               ; set the maximum contour level
     mapres@cnLevelSpacingF         = 0.05                ; set the interval between contours
    if (tracer.eq."MEG_ISOP".or.tracer.eq."AEROD_v"\
     .or.tracer.eq."AODVIS".or.tracer.eq."AODVISdn"\
     .or.tracer.eq."AODDUST".or.tracer.eq."FSNS"\
     .or.tracer.eq."FSDS".or.tracer.eq."FLDS"\
     .or.tracer.eq."CLDTOT") then
      map4 = gsn_csm_contour_map_ce(wks,rel_glob_diff(0,:,:),mapres)
    else
      map4 = gsn_csm_contour_map_ce(wks,rel_glob_diff(0,55,:,:),mapres)
    end if


     if (STATIONS) then
    ; ===================
    ; Locations
    ; ===================
    ;
    ; Add the locations as filled circles
    ;
    ;  station_name = (/"Lauder", "Wollongong", "Darwin" /)
    ;  station_lon = (/169.68, 150.88, 130.892/)
    ;  station_lat = (/-45.03, -34.41, -12.425/)

      station_name = (/"Sydney", "Wollongong", "Canberra" /)
      station_lon = (/151.21, 150.88, 149.13/)
      station_lat = (/-33.86, -34.41, -35.28/)
      pmres                    = True
        pmres@gsMarkerIndex    = 16        ; filled markers
        ;pmres@gsMarkerSizeF   = 0.005
        pmres@gsMarkerSizeF    = 0.008
        pmres@gsMarkerColor    = "black"

      tstatn = gsn_add_polymarker(wks,map1,station_lon,station_lat,pmres)

    ; ===================
    ; Add locations names
    ; ===================
    ;
       txres = True
        txres@txFontHeightF  = 0.024
        txres@txFont         = "helvetica-bold"
        txres@txJust         = "BottomLeft"
        txres@txFontColor    = "black"

     text = gsn_add_text(wks,map1,station_name(0),station_lon(0)+0.5,station_lat(0)-0.5,txres)
        txres@txJust         = "TopLeft"
     text = gsn_add_text(wks,map1,station_name(1),station_lon(1)+0.5,station_lat(1)-0.5,txres)
        txres@txJust         = "BottomRight"
     text = gsn_add_text(wks,map1,station_name(2),station_lon(2)-0.5,station_lat(2)-1,txres)
    end if


    gsn_panel(wks,(/map1,map2,map3,map4/),(/2,2/),panel_res)


    ;draw(map1)
    ;frame(wks)

  end if    ; PLOT



end

