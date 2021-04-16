;================================================;
;  plot_MOPITT_averages.ncl
;================================================;
;
; Concepts illustrated:
;   - For use with MOPITT CO version 7, level 3 product month average files
;   - Load data from MOPITT .he5 file
;   - Plotting region on a map
;   - Overlay region of interest boxes
;   - Plot vectors
;
;   Files needed:
;         -MOPITT level 3, monthly netCDF
;
;   To run type:
;         ncl plot_MOPITT_averages.ncl 
;                                          rrb 20170612
; ================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/net/mopfl/home/buchholz/code_database/ncl_programs/buchholz_global_util/arrow.ncl"

; add in bash for own colormaps
;export NCARG_COLORMAPS=/IASI/home/buchholz/ncl_programs/colormaps:$NCARG_ROOT/lib/ncarg/colormaps

begin
;***************************************************************
; User Input
;***************************************************************
    version = "V8J"
    ;mopitt_file = "/IASI/home/buchholz/MOPITT_subset/averages/MOPITT_ASON_2001_2016.nc"
    ;mopitt_file = "/net/mopfl/home/buchholz/MOPITT_subset/V8/averages/MOPITT_2002_2017.nc"
    ;mopitt_file = "/net/mopfl/home/buchholz/MOPITT_subset/V8/averages/MOPITTV8J_AS2002_2019.nc"
    mopitt_file = "/net/mopfl/home/buchholz/MOPITT_subset/V8/averages/MOPITTV8J_DJ2002_2019.nc"
    ;mopitt_file = "/net/mopfl/home/buchholz/MOPITT_subset/V8/averages/MOPITT_Nov_2002_2017.nc"
    ;mopitt_file = "/net/mopfl/home/buchholz/MOPITT_subset/V7/averages/MOPITT_2014_01to12.nc"
    ;mopitt_file = "/net/mopfl/home/buchholz/burned_area/averages/burnarea_01to12_2014.nc"
    ;sd_file = "/net/mopfl/home/buchholz/MOPITT_subset/averages/MOPITT_2001_2016_SONDsd.nc"
    sd_file = "/net/mopfl/home/buchholz/MOPITT_subset/V8/averages/MOPITT_2002_2017_sd.nc"

   ; -------------------------------
   ; SELECT OUTPUT
   ; -------------------------------
   PLOT   = True                             ; generate map plot

   if (PLOT) then                            ; Map plot
       mapDir  = "./"                        ; directory for plot output
       mapName = "/net/mopfl/home/buchholz/MOPITT_"+version+"_tcol" ; plot name output
       mapType = "x11"                       ; workstation type
        ;mapType@wkWidth = 1800
        ;mapType@wkHeight = 1800 
   end if

   DIFF = True
     ;diff_file1 = "/net/mopfl/home/buchholz/MOPITT_subset/V8/averages/200802_Febdiff.nc"
     ;diff_file2 = "/net/mopfl/home/buchholz/MOPITT_subset/V8/averages/201402_Febdiff.nc"
     ;diff_file1 = "/net/mopfl/home/buchholz/MOPITT_subset/V8/averages/DJV8J_diff.nc.nc"
     diff_file1 = "/net/mopfl/home/buchholz/MOPITT_subset/V8/averages/ASV8J_diff.nc.nc"
     ;diff_file2 = "/net/mopfl/home/buchholz/MOPITT_subset/V8/averages/AugSep_V8J_PNWfire.nc"
     diff_file2 = "/net/mopfl/home/buchholz/MOPITT_subset/V8/averages/DecJan_V8J_Ausfire.nc"

;***************************************************************
; End User Input
;***************************************************************

;--------------------------------------------
; SETUP
;--------------------------------------------
                                             ; CONSTANTS
   NAv    = 6.0221415e+23                    ;--- Avogadro's number
   g      = 9.81                             ;--- m/s - gravity
   H = (8.314*240)/(0.0289751*9.8)           ;--- scale height
   MWair = 28.94                             ;--- g/mol
   xp_const = (NAv* 10)/(MWair*g)            ;--- scaling factor for turning vmr into pcol

  ; mopitt_tracer = "RetrievedCOSurfaceMixingRatioDay"
   mopitt_tracer = "RetrievedCOTotalColumnDay"

;--------------------------------------------
; Extract MOPITT trace gas information
;--------------------------------------------
  fin = addfile(mopitt_file, "r")             ; load

  data = fin->$mopitt_tracer$      ; extract total column data (:,:)
    data!0 = "lon"
    data!1 = "lat"
  sat_psurf = fin->$"SurfacePressureDay"$        ; extract surface pressure (:,:)
  dry_air = fin->$"DryAirColumnDay"$        ; extract surface pressure (:,:)
    dry_air!0 = "lon"
    dry_air!1 = "lat"
  latitude = fin->$"Latitude"$
  longitude = fin->$"Longitude"$


  ; -------------------------------
  ; rename coordinate variables
  ; -------------------------------

  tracer = data(lat|:, lon|:)/dry_air(lat|:, lon|:)         ; reorder - NCL needs lon as rightmost coordinate

  sat_psurf!0 = "lon"
  sat_psurf!1 = "lat"
  psurf = sat_psurf(lat|:, lon|:)         ; reorder - NCL needs lon as rightmost coordinate

;--------------------------------------------
; Extract MOPITT sd
;--------------------------------------------
  sd_fin = addfile(sd_file, "r")             ; load
  sd_data = sd_fin->$mopitt_tracer$      ; extract total column data (:,:)

  sd_data!0 = "lon"
  sd_data!1 = "lat"
  sd_tracer = sd_data(lat|:, lon|:)             ; reorder - NCL needs lon as rightmost coordinate

  rel_sd = (sd_tracer/tracer)*100
  rel_sd!0 = "lat"
  rel_sd&lat = latitude
  rel_sd!1 = "lon"
  rel_sd&lon = longitude

;--------------------------------------------
; Extract MOPITT diffs
;--------------------------------------------
 if (DIFF) then
  diff_fin = addfile(diff_file1, "r")             ; load
  diff_data = diff_fin->$mopitt_tracer$      ; extract total column data (:,:)

  diff_data!0 = "lon"
  diff_data!1 = "lat"
  diff_tracer = diff_data(lat|:, lon|:)             ; reorder - NCL needs lon as rightmost coordinate

  diff2_fin = addfile(diff_file2, "r")             ; load
  diff2_data = diff2_fin->$mopitt_tracer$      ; extract total column data (:,:)
  dry_air2 = diff2_fin->$"DryAirColumnDay"$        ; extract dry air column

  diff2_data!0 = "lon"
  diff2_data!1 = "lat"
  dry_air2!0 = "lon"
  dry_air2!1 = "lat"
  diff2_tracer = diff2_data(lat|:, lon|:)/dry_air2(lat|:, lon|:)          ; reorder - NCL needs lon as rightmost coordinate


end if

relative_diff = ((diff2_tracer - tracer)/tracer)*100
copy_VarCoords(tracer,relative_diff)


;--------------------------------------------
; Plot data
;--------------------------------------------
  ;************
  ; MAP PLOT
  ;************

  if (PLOT) then
    wks = gsn_open_wks(mapType,mapName)
    ;gsn_define_colormap(wks,"haxby_rrb")        ; change colour map
    gsn_define_colormap(wks,"GMT_haxby")        ; change colour map

;gsn_draw_colormap(wks)
;exit

    ;-----------------------------------
    ; define resources to use for plotting
    ;-----------------------------------
    mapres = True

    mapres@tiMainString              = ""
    mapres@gsnLeftString             = ""                                 ; change left title
    mapres@gsnRightString            = "total column (molec. cm~S2~-2  )" ; change right title
    mapres@gsnAddCyclic              = True
    mapres@gsnFrame                  = False             ; do not advance frame
    mapres@gsnDraw                   = False             ; do not advance frame
    mapres@vpXF                      = 0.06
    mapres@gsnMaximize               = True  
    mapres@gsnPaperOrientation       = "portrait"


    mapres@mpGeophysicalLineThicknessF = 2.5
    mapres@cnFillOn                  = True
    mapres@cnFillMode                = "CellFill"     ; fill as grid boxes not contours
    mapres@cnLinesOn                 = False

    mapres@lbTitleFontHeightF       = 0.022
    mapres@lbLabelFontHeightF       = 0.022
    mapres@lbTitleFontHeightF       = 0.018
    mapres@lbLabelFontHeightF       = 0.018
    mapres@lbTitlePosition          = "bottom"      ; Label Bar title
    mapres@lbOrientation             = "Vertical"     ; Label bar location
    mapres@lbLabelAutoStride         = True
    mapres@lbBoxLinesOn              = False
    mapres@lbBoxEndCapStyle          = "TriangleBothEnds"
    mapres@pmLabelBarOrthogonalPosF  = .04            ; move whole thing down
    ;mapres@pmLabelBarParallelPosF    = .8

    mapres@gsnStringFontHeightF        =0.022
    mapres@tmXBLabelFontHeightF        =0.022
    mapres@tmYLLabelFontHeightF        =0.022
    mapres@tmXBTickSpacingF            = 60.
    mapres@tmYLTickSpacingF            = 40.

    mapres@cnMissingValFillPattern = 0             ; choose fill pattern 0 (solid fill) 
    mapres@cnMissingValFillColor   = "grey"        ; color fill missing areas blue
    mapres@cnMissingValPerimThicknessF  = 2.0      ; increase missing value perimeter thickness

    mapres@mpLimitMode               ="LatLon"
     ; mapres@mpMinLatF               = 5      ; zoom to USA
     ; mapres@mpMaxLatF               = 60
     ; mapres@mpMinLonF               = -140
     ; mapres@mpMaxLonF               = -50
      ;-------------------------------------
     ; mapres@mpMinLatF               = -70       ; zoom to SH
     ; mapres@mpMaxLatF               = 15
     ; mapres@mpMinLonF               = -180
     ; mapres@mpMaxLonF               = 180
     ; mapres@mpCenterLonF            = 70
      ;-------------------------------------
     ; mapres@mpMinLatF               = -60       ; zoom to Aus
     ; mapres@mpMaxLatF               = 0
     ; mapres@mpMinLonF               = 100
     ; mapres@mpMaxLonF               = 200
     ; mapres@mpCenterLonF            = 70
      ;-------------------------------------
     ; mapres@mpMinLatF               = -85       ; zoom to +/- 80
     ; mapres@mpMaxLatF               = 85
     ; mapres@mpMinLonF               = -120
     ; mapres@mpMaxLonF               = 185
     ; mapres@mpCenterLonF            = 0
      ;-------------------------------------
      mapres@mpMinLatF               = -85       ; zoom to +/- 80
      mapres@mpMaxLatF               = 65
      mapres@mpCenterLonF            = -120
      ;-------------------------------------
      ;mapres@mpMinLatF               = -60       ; zoom to MSEA
      ;mapres@mpMaxLatF               = 40
      ;mapres@mpMinLonF               = 60
      ;mapres@mpMaxLonF               = 230
      ;mapres@mpCenterLonF            = 70

    ;-----------------------------------
    ; end define resources
    ;-----------------------------------

    ; ===================
    ; CO plot
    ; ===================
    mapres@gsnRightString            = ""               ; change right title
    ;mapres@cnLevelSelectionMode      = "ExplicitLevels"
    ;labels = fspan(0.9e18,2.5e18, 33)
    ;labels = fspan(0.9,2.5, 33)
    ;print(labels)
    ;labels_strings = (/"0.9","0.95","1.0","1.05","1.1","1.15","1.2","1.25","1.3","1.35",\
    ;                   "1.4","1.45","1.5","1.55","1.6","1.65","1.7","1.75","1.8","1.85",\
    ;                   "1.9","1.95","2.0","2.05","2.1","2.15","2.2","2.25","2.3","2.35",\
    ;                   "2.4","2.45","2.5" /); "2.6","2.7","2.8","2.9",\
    ;                   "3.0"/)
    ;mapres@cnLevels                  = labels
    ;mapres@lbLabelStrings            = labels_strings
    mapres@cnLevelSelectionMode      = "ManualLevels"
     ;tcol
    ;  mapres@cnMinLevelValF          = 1e18          ; set the minimum contour level
    ;  mapres@cnMaxLevelValF          = 2.8e18           ; set the maximum contour level
    ;  mapres@cnLevelSpacingF         = 0.1e18          ; set the interval between contours
    ;mapres@lbTitleString             = "x 10~S2~18   molec cm~S2~-2"             ; Label Bar title
      ;vmr
      mapres@cnMinLevelValF          = 20.          ; set the minimum contour level
      mapres@cnMaxLevelValF          = 140.         ; set the maximum contour level
      mapres@cnLevelSpacingF         = 4.          ; set the interval between contours
    mapres@lbTitleString             = "X~B2~CO     ppb"             ; Label Bar title

    ;map = gsn_csm_contour_map_ce(wks,tracer(::-1,:),mapres)
    map = gsn_csm_contour_map_ce(wks,tracer/1e-09,mapres)


    ; ===================
    ; SD plot
    ; ===================
    mapres@cnLevelSelectionMode      = "ExplicitLevels"
    mapres@lbTitleString             = "SD"             ; Label Bar title
    ;labels := fspan(2.5, 40, 16)
    ;labels_strings := (/"2.5","5.0","7.5","10","12.5",\
    ;                   "15","17.5","20","22.5","25",\
    ;                   "27.5","30","32.5","35","37.5","40"/)
    mapres@lbTitleString             := "x 10~S2~17   molec cm~S2~-2"             ; Label Bar title
    ;labels := fspan(0.0e17,8.0e17, 17)
;print(labels) 
    ;labels_strings := (/"0", "0.5", "1.0","1.5","2.0","2.5",\
    ;                   "3.0","3.5","4.0","4.5","5.0",\
    ;                   "5.5","6.0","6.5","7.0","7.5","8.0"/)
    ;print(labels)
    ;mapres@cnLevels                  := labels
    ;mapres@lbLabelStrings            := labels_strings
     ;tcol
    ;mapres@cnLevelSelectionMode      = "ManualLevels"
     ; mapres@cnMinLevelValF          = 0.2e17   ; set the minimum contour level
     ; mapres@cnMaxLevelValF          = 3.2e17    ; set the maximum contour level
     ; mapres@cnLevelSpacingF         = 0.25e17    ; set the interval between contours
      ;vmr
    ;  mapres@cnMinLevelValF          = 5.          ; set the minimum contour level
    ;  mapres@cnMaxLevelValF          = 30.         ; set the maximum contour level
    ;  mapres@cnLevelSpacingF         = 0.5          ; set the interval between contours

  ;  map2 = gsn_csm_contour_map_ce(wks,rel_sd(::-1,:),mapres)
    map2 = gsn_csm_contour_map_ce(wks,sd_tracer(::-1,:),mapres)

    if (DIFF) then
    ; ===================
    ; Difference plot
    ; ===================
    ;cmap = read_colormap_file("BlWhRe")
    cmap = read_colormap_file("BlueWhiteOrangeRed")

    mapres@cnFillPalette       = cmap

printVarSummary(cmap)
    ;colour_arr := (/cmap(40,:),cmap(48,:),cmap(50,:),cmap(50,:),cmap(51,:),cmap(52,:),\
    ;            cmap(54,:), cmap(56,:),cmap(60,:),cmap(65,:),cmap(70,:),cmap(75,:),cmap(80,:),\
    ;             cmap(85,:),cmap(90,:),cmap(95,:),cmap(100,:)/)
    colour_arr := (/cmap(32,:),cmap(40,:),cmap(48,:),cmap(49,:),cmap(51,:),cmap(52,:),\
                 cmap(54,:), cmap(60,:),cmap(65,:),cmap(70,:),cmap(75,:),cmap(80,:),\
                 cmap(95,:),cmap(100,:)/)

    ;mapres@cnFillPalette       = colour_arr
    ;mapres@cnLevelSelectionMode      = "ExplicitLevels"
    ;mapres@lbTitleString             = "SD"             ; Label Bar title
    ;mapres@lbTitleString             := "x 10~S2~17   molec cm~S2~-2"             ; Label Bar title
    ;labels := fspan(-2.0e17,8.0e17, 11)
;print(labels)
    ;labels_strings := (/"-2.0","-1.0","0", "1.0","2.0",\
    ;                   "3.0","4.0","5.0","6.0","7.0","8.0"/)
    ;mapres@cnLevelSelectionMode      = "ExplicitLevels"
    ;labels := fspan(-30.,70., 11)
;print(labels)
    ;labels_strings := (/"-30","-20","-100","0", "10.","20.",\
    ;                   "30.","40.","50.","60.","70."/)
    mapres@lbTitleString             := "% difference"             ; Label Bar title

    ;labels_strings := (/"-2.0","-1.0","0", "1.0","2.0",\
    ;                   "3.0","4.0","5.0","6.0","7.0","8.0",\
    ;                   "9.0","10.0","11.0","12.0","13.0"/)
    ;print(labels)
    ;mapres@cnLevels                  := labels
    ;mapres@lbLabelStrings            := labels_strings
     ;tcol
    mapres@cnLevelSelectionMode      = "ManualLevels"
     ; mapres@cnMinLevelValF          = 0.2e17   ; set the minimum contour level
     ; mapres@cnMaxLevelValF          = 3.2e17    ; set the maximum contour level
     ; mapres@cnLevelSpacingF         = 0.25e17    ; set the interval between contours
      ;vmr
      mapres@cnMinLevelValF          = -40.          ; set the minimum contour level
      mapres@cnMaxLevelValF          = 40.         ; set the maximum contour level
      mapres@cnLevelSpacingF         = 2.          ; set the interval between contours

    map2 = gsn_csm_contour_map_ce(wks,diff_tracer(::-1,:),mapres)
    map3 = gsn_csm_contour_map_ce(wks,relative_diff,mapres)

    end if

    ;-------------------
    ; draw region boxes
    ;-------------------
    boxres = True
      boxres@gsLineColor      = "black"
      boxres@gsLineThicknessF = 10

      ;region_name = (/"NorthAustralasia","SouthAustralasia","Indonesia","CSAfrica","SSAfrica",\
      ;                 "CentralSAmerica", "SouthAmerica"/)
      ;region_acr = (/"NAus","SAus","MSEA","CSAf","SSAf",\
      ;                 "CSAm","SSAm"/)
      ;latmin = (/-25.,-50.,-10.,-25.,-40.,-25.,-60./)
      ;latmax = (/-10.,-25.,10.,-10.,-25.,-5.,-25./)
      ;lonmin = (/110.,110.,90.,0.,0.,-80 + 360.,-80 + 360./)
      ;lonmax = (/180.,180.,160.,59.,59.,-32 + 360.,-32 + 360./)

      region_name = (/"Australasia","Indonesia","SAfrica",\
                      "SouthAmerica", "Siberia", "NAmerica"/)
      region_acr = (/"NAus","MSEA","SAf",\
                       "SAm", "Sib", "NAm"/)
      latmin = (/-50.,-10.,-40.,-60.,50., 25./)
      latmax = (/-10.,10.,5.,4.,85.,70./)
      lonmin = (/110.,90.,0.,-80 + 360.,91.,-170.+360./)
      lonmax = (/180.,160.,60.,-40 + 360.,190.,-53.+360./)

     region_names = (/"Australasia", "Maritime SEA", \
                    "Southern Africa", "South ~C~America",\
                    "Siberia", "North ~C~America" /)



   ; -----------------------------------------------------
    dum = new(dimsizes(region_name),graphic)
    dum2 = new(dimsizes(region_name),graphic)
    do j=0,dimsizes(region_name)-1
     region_lon := (/lonmin(j), lonmin(j), lonmax(j), lonmax(j), lonmin(j)/)
     region_lat := (/latmin(j), latmax(j), latmax(j), latmin(j), latmin(j)/)
     ;dum(j) = gsn_add_polyline(wks,map,region_lon,region_lat,boxres)
     ;dum2(j) = gsn_add_polyline(wks,map,region_lon,region_lat,boxres)
    end do

    ;-------------------
    ; draw climate index boxes
    ;-------------------
    boxresII = True
      boxresII@gsLineColor      = "red2"
      boxresII@gsLineThicknessF = 15

      index_name = (/"NINO 3.4","~F33~D","DMI","TSA"/)
      index_latmin = (/-5.,-10.,-10.,-20./)
      index_latmax = (/5.,10.,0.,0./)
      index_lonmin = (/-170.+360.,50.,90.,-30.+360./)
      index_lonmax = (/-120.+360.,70.,110.,10./)

   ; -----------------------------------------------------
    dum3 = new(dimsizes(index_name),graphic)
    do j=0,dimsizes(index_name)-1
     region_lon := (/index_lonmin(j), index_lonmin(j), index_lonmax(j), index_lonmax(j), index_lonmin(j)/)
     region_lat := (/index_latmin(j), index_latmax(j), index_latmax(j), index_latmin(j), index_latmin(j)/)
     ;dum2(j) = gsn_add_polyline(wks,map2,region_lon,region_lat,boxresII)
    end do

    ;-------------------
    ; draw AAO arrows
    ;-------------------
    aao_lines_up = new(9, graphic)
    aao_lines_down = new(9, graphic)
    arrow_res = True
     ; arrow_res@gsLineColor      = "white"
     ; arrow_res@gsLineThicknessF = 15.0
    do j = 0,dimsizes(aao_lines_up)-1
      ;aao_lines_up(j)=add_arrow(wks, map2,(/-8+40*j,-8+40*j/),(/-62,-45/),arrow_res)
     ; aao_lines_down(j)=add_arrow(wks, map2,(/-8+40*j,-8+40*j/),(/-45,-62/),arrow_res)
    end do

    ;-------------------
    ; add text for regions
    ;-------------------
    ;drawNDCGrid(wks)
       txres = True
        txres@txFontHeightF  = 0.014
        ;txres@txFont         = "helvetica-bold"
        txres@txJust         = "BottomLeft"
        txres@txFontColor    = "black"
        ;txres@txPerimOn      = True
        txres@txBackgroundFillColor="white"

     
    ;gsn_text_ndc(wks,"test",0.1,0.1,txres)
    text = new(dimsizes(region_name),graphic)
    do k=0,dimsizes(region_name)-1
      if (k.eq.1) then
        txres@txJust         = "TopLeft"
        ;text(k) = gsn_add_text(wks,map,region_names(k),lonmin(k)+2, latmax(k)+15,txres)
      else if (k.eq.3)
        txres@txJust         = "BottomRight"
        ;text(k) = gsn_add_text(wks,map,region_names(k),lonmin(k)-2, latmin(k)+2,txres)
      else if (k.eq.5)
        txres@txJust         = "BottomLeft"
        ;text(k) = gsn_add_text(wks,map,region_names(k),lonmin(k)+2, latmin(k)+2,txres)
      else
        txres@txJust         = "BottomLeft"
        ;text(k) = gsn_add_text(wks,map,region_names(k),lonmin(k)+2, latmin(k)-15,txres)
      end if
      end if
      end if
    end do

        txres@txFontColor    = "red2"
        txres@txJust         = "BottomRight"
    textII = new(dimsizes(index_name),graphic)
    do k=0,dimsizes(index_name)-1
      if (k.eq.2) then
       ; textII(k) = gsn_add_text(wks,map2,index_name(k),index_lonmin(k)-2, index_latmin(k)-20,txres)
        continue;
      else if (k.eq.0)
       ; textII(k) = gsn_add_text(wks,map2,index_name(k),index_lonmin(k)+50, index_latmin(k)-12,txres)
      else if (k.eq.1)
       ; textII(k) = gsn_add_text(wks,map2,index_name(k),index_lonmin(k)+35, index_latmin(k)-10,txres)
      else 
       ; textII(k) = gsn_add_text(wks,map2,index_name(k),index_lonmin(k)+35, index_latmin(k)-12,txres)
       end if
       end if
       end if
    end do

        txres@txFontColor    = "white"
        txres@txJust         = "CenterCenter"
        ;textIII = gsn_add_text(wks,map2,"SAM",51, -55,txres)

    ; ===================
    ; Location Data
    ; ===================

      ;station_name = (/"Darwin", "Wollongong", "Lauder"/)
      ;station_lon = (/130.89, 150.88, 169.68/)
      ;station_lat = (/-12.42, -34.41, -45.04/)


      ;station_name = (/"Darwin"/)
      ;station_lon = (/130.89/)
      ;station_lat = (/-12.42/)

    ; ===================
    ; Locations
    ; ===================
    ;
     pmres                    = True
       pmres@gsMarkerIndex    = 16        ; filled markers
       pmres@gsMarkerSizeF    = 0.010
       pmres@gsMarkerColor    = "black"

       ;gsn_polymarker(wks,map,station_lon,station_lat,pmres)
       ;points = gsn_add_polymarker(wks,map,station_lon,station_lat,pmres)

    ; ===================
    ; Add locations names
    ; ===================
    ;
     txres = True
      txres@txFontHeightF  = 0.022
      txres@txFont         = "helvetica-bold"
      txres@txJust         = "TopRight"
      txres@txFontColor    = "black"

      ;text = gsn_add_text(wks,map,station_name(0),station_lon(0)-2.5,station_lat(0)+1.0,txres)

      txres@txJust         = "BottomLeft"

     do i = 1, dimsizes(station_name)-1 
        ;text2 = gsn_add_text(wks,map,station_name(1),station_lon(1),station_lat(1),txres)
        ;text3 = gsn_add_text(wks,map,station_name(2),station_lon(2),station_lat(2),txres) 
      end do


    ; ===================
    ; panel the plots
    ; ===================
  res1                     = True
    res1@gsnAttachBorderOn   = False
    res1@tiYAxisFontHeightF  = 0.024
  res2                     = True
    res2@gsnMaximize         = True
    res2@gsnAttachPlotsXAxis = True
    res2@tiXAxisFontHeightF  = 0.024
    res2@tiYAxisFontHeightF  = 0.024

  ; map will be the base plot.

  ;amid = gsn_attach_plots(map,map2,res1,res2)
  ;draw(map)    ; All plots will be drawn.
  ;frame(wks)

  panel_res                       = True
  panel_res@gsnPanelFigureStringsJust = "Bottomleft"
  panel_res@gsnPanelFigureStringsFontHeightF = 0.014
  panel_res@gsnPanelFigureStringsPerimOn = True
  ;panel_res@gsnPanelMainString    = "MOPITT total column CO, 2002-2017"
  panel_res@gsnPanelMainString    = ""
  ;panel_res@gsnPanelMainFontHeightF = 0.024 

  if (DIFF) then
    ;panel_res@gsnPanelFigureStrings = (/"Average August-September CO 2002-2019","Aug. to Sep. 2020 difference from average","Feb 2014 difference to average"/)
    panel_res@gsnPanelFigureStrings = (/"Average December-January CO 2002-2019","Dec. 2019 to Jan. 2020 difference from average","Feb 2014 difference to average"/)
    ;gsn_panel(wks,(/map,map2,map3/),(/3,1/),panel_res) ; All plots will be drawn.
    ;gsn_panel(wks,(/map,map2/),(/2,1/),panel_res) ; All plots will be drawn.
    gsn_panel(wks,(/map,map3/),(/2,1/),panel_res) ; All plots will be drawn.
  else 
    panel_res@gsnPanelFigureStrings = (/"Average CO","(b) CO Std. Dev."/)
    gsn_panel(wks,(/map,map2/),(/2,1/),panel_res) ; All plots will be drawn.
  end if 
 ; frame(wks)

  ;draw(map)    ; All plots will be drawn.
  ;frame(wks)

  end if    ; PLOT




end