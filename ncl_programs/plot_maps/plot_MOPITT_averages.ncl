;================================================;
;  plot_mopitt_averages.ncl
;================================================;
;
; Concepts illustrated:
;   - For use with MOPITT CO version 7, level 3 product month average files
;   - Load data from MOPITT .he5 file
;   - Plotting region on a map
;
;   Files needed:
;         -MOPITT level 3, monthly netCDF
;
;   To run type:
;         apply_tracer_ratios.ncl 
;                                          rrb 20170510
; ================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

; add in bash for own colormaps
;export NCARG_COLORMAPS=/IASI/home/buchholz/NCL_programs/colormaps:$NCARG_ROOT/lib/ncarg/colormaps

begin
;***************************************************************
; User Input
;***************************************************************
   date    = "2008-2015"                        ; date for file
    version = "V7T"
    mopitt_file = "/IASI/home/buchholz/scripts/MOPITT_ASON_2001_2016.nc"
    sd_file = "/IASI/home/buchholz/scripts/MOPITT_2001_2016_ASONsd.nc"
   ; -------------------------------
   ; SELECT OUTPUT
   ; -------------------------------
   PLOT   = True                             ; generate map plot

   if (PLOT) then                            ; Map plot
       mapDir  = "./"                        ; directory for plot output
       mapName = "MOPITT_"+version+"_tcol" ; plot name output
       mapType = "x11"                       ; workstation type
        mapType@wkWidth = 1200
        mapType@wkHeight = 1200 
   end if

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
  sat_psurf = fin->$"SurfacePressureDay"$        ; extract surface pressure (:,:)
  latitude = fin->$"Latitude"$
  longitude = fin->$"Longitude"$

  ; -------------------------------
  ; rename coordinate variables
  ; -------------------------------
  data!0 = "lon"
  data!1 = "lat"
  tracer = data(lat|:, lon|:)             ; reorder - NCL needs lon as rightmost coordinate

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

  rel_sd = sd_tracer/tracer
  rel_sd!0 = "lat"
  rel_sd&lat = latitude
  rel_sd!1 = "lon"
  rel_sd&lon = longitude


;--------------------------------------------
; Plot data
;--------------------------------------------
  ;************
  ; MAP PLOT
  ;************

  if (PLOT) then
    wks = gsn_open_wks(mapType,mapName)
    gsn_define_colormap(wks,"haxby_rrb")        ; change colour map

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

    mapres@mpGeophysicalLineThicknessF = 2.5
    mapres@cnFillOn                  = True
    mapres@cnFillMode                = "CellFill"     ; fill as grid boxes not contours
    mapres@cnLinesOn                 = False


    mapres@lbTitleFontHeightF       = 0.014
    mapres@lbLabelFontHeightF       = 0.014
    mapres@lbTitlePosition          = "bottom"      ; Label Bar title
    mapres@lbOrientation             = "Vertical"     ; Label bar location
    mapres@lbLabelAutoStride         = True
    mapres@lbBoxLinesOn              = False
    mapres@lbBoxEndCapStyle           = "TriangleBothEnds"
    ;mapres@pmLabelBarOrthogonalPosF  = .10            ; move whole thing down

    mapres@gsnStringFontHeightF        =0.014
    mapres@tmXBLabelFontHeightF        =0.014
    mapres@tmYLLabelFontHeightF        =0.014
    mapres@tmXBTickSpacingF            = 60.
    mapres@tmYLTickSpacingF            = 40.

    mapres@cnMissingValFillPattern = 0             ; choose fill pattern 0 (solid fill) 
    mapres@cnMissingValFillColor   = "grey"        ; color fill missing areas blue
    mapres@cnMissingValPerimThicknessF  = 2.0      ; increase missing value perimeter thickness

    mapres@mpLimitMode               ="LatLon"
    ;  mapres@mpMinLatF               = 15       ; zoom to USA
    ;  mapres@mpMaxLatF               = 80
    ;  mapres@mpMinLonF               = -180
    ;  mapres@mpMaxLonF               = -50
      ;-------------------------------------
      mapres@mpMinLatF               = -70       ; zoom to SH
      mapres@mpMaxLatF               = 15
      mapres@mpMinLonF               = -105
      mapres@mpMaxLonF               = 245
      mapres@mpCenterLonF            = 70

    ;-----------------------------------
    ; end define resources
    ;-----------------------------------

    ; ===================
    ; CO plot
    ; ===================
    mapres@lbTitleString             = "x 10~S2~18   molec cm~S2~-2"             ; Label Bar title
    mapres@gsnRightString            = ""               ; change right title
    mapres@cnLevelSelectionMode      = "ExplicitLevels"
    labels = fspan(1e18,3.0e18, 21)
    labels_strings = (/"1.0","1.1","1.2","1.3","1.4","1.5","1.6","1.7","1.8","1.9",\
                       "2.0","2.1","2.2","2.3","2.4","2.5","2.6","2.7","2.8","2.9",\
                       "3.0"/)
    mapres@cnLevels                  = labels
    mapres@lbLabelStrings            = labels_strings
    ;mapres@cnLevelSelectionMode      = "ManualLevels"
     ;tcol
    ;  mapres@cnMinLevelValF          = 1e18          ; set the minimum contour level
    ;  mapres@cnMaxLevelValF          = 2.8e18           ; set the maximum contour level
    ;  mapres@cnLevelSpacingF         = 0.1e18          ; set the interval between contours
      ;vmr
    ;  mapres@cnMinLevelValF          = 50.          ; set the minimum contour level
    ;  mapres@cnMaxLevelValF          = 220.         ; set the maximum contour level
    ;  mapres@cnLevelSpacingF         = 5.          ; set the interval between contours

    map = gsn_csm_contour_map_ce(wks,tracer(::-1,:),mapres)


    ; ===================
    ; SD plot
    ; ===================
    mapres@cnLevelSelectionMode      = "ExplicitLevels"
    ;mapres@lbTitleString             = "relative SD"             ; Label Bar title
    ;labels := fspan(0.025, 0.4, 16)
    ;labels_strings := (/"0.025","0.050","0.075","0.100","0.125",\
    ;                   "0.150","0.175","0.200","0.225","0.250",\
    ;                   "0.275","0.300","0.325","0.350","0.375","0.400"/)
    mapres@lbTitleString             := "x 10~S2~17   molec cm~S2~-2"             ; Label Bar title
    labels := fspan(0.5e17,7.5e17, 15)
    labels_strings := (/"0.5","1.0","1.5","2.0","2.5",\
                       "3.0","3.5","4.0","4.5","5.0",\
                       "5.5","6.0","6.5","7.0","7.5"/)
    ;print(labels)
    mapres@cnLevels                  := labels
    mapres@lbLabelStrings            := labels_strings
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

    ;-------------------
    ; draw region boxes
    ;-------------------
    boxres = True
      boxres@gsLineColor      = "black"
      boxres@gsLineThicknessF = 5

      region_name = (/"NorthAustralasia","SouthAustralasia","Indonesia","CSAfrica","SSAfrica",\
                       "EastSAmerica","WestSAmerica"/)
      latmin = (/-25.,-50.,-10.,-25.,-40.,-60.,-60./)
      latmax = (/-10.,-25.,10.,-10.,-25.,4.,4./)
      lonmin = (/110.,110.,90.,0.,0.,-60 + 360.,-80 + 360./)
      lonmax = (/180.,180.,160.,59.,59.,-40 + 360.,-60 + 360./)

   ; -----------------------------------------------------
    dum = new(dimsizes(region_name),graphic)
    dum2 = new(dimsizes(region_name),graphic)
    do j=0,dimsizes(region_name)-1
     region_lon := (/lonmin(j), lonmin(j), lonmax(j), lonmax(j), lonmin(j)/)
     region_lat := (/latmin(j), latmax(j), latmax(j), latmin(j), latmin(j)/)
     dum(j) = gsn_add_polyline(wks,map,region_lon,region_lat,boxres)
     ;dum2(j) = gsn_add_polyline(wks,map2,region_lon,region_lat,boxres)
    end do

    ;-------------------
    ; draw climate index boxes
    ;-------------------
    boxresII = True
      boxresII@gsLineColor      = "red"
      boxresII@gsLineThicknessF = 5

      index_name = (/"NINO 3.4","DMI","DMI2","TSA"/)
      index_latmin = (/-5.,-10.,-10.,-20./)
      index_latmax = (/5.,10.,0.,0./)
      index_lonmin = (/-170.+360.,50.,90.,-30.+360./)
      index_lonmax = (/-120.+360.,70.,110.,10./)

   ; -----------------------------------------------------
    dum3 = new(dimsizes(index_name),graphic)
    do j=0,dimsizes(index_name)-1
     region_lon := (/index_lonmin(j), index_lonmin(j), index_lonmax(j), index_lonmax(j), index_lonmin(j)/)
     region_lat := (/index_latmin(j), index_latmax(j), index_latmax(j), index_latmin(j), index_latmin(j)/)
     dum2(j) = gsn_add_polyline(wks,map2,region_lon,region_lat,boxresII)
    end do

    ;-------------------
    ; add text for regions
    ;-------------------
    ;drawNDCGrid(wks)
       txres = True
        txres@txFontHeightF  = 0.012
        ;txres@txFont         = "helvetica-bold"
        txres@txJust         = "BottomLeft"
        txres@txFontColor    = "black"
        ;txres@txPerimOn      = True

      region_acr = (/"NAus","SAus","MSEA","CSAf","SSAf",\
                       "ESAm","WSAm"/)
    ;gsn_text_ndc(wks,"test",0.1,0.1,txres)
    text = new(dimsizes(region_name),graphic)
    do k=0,dimsizes(region_name)-1
      if (k.eq.5) then
        text(k) = gsn_add_text(wks,map,region_acr(k),lonmax(k)+2, latmax(k)-35,txres)
      else if (k.eq.6)
        txres@txJust         = "BottomRight"
        text(k) = gsn_add_text(wks,map,region_acr(k),lonmin(k)-2, latmax(k)-35,txres)
      else
        text(k) = gsn_add_text(wks,map,region_acr(k),lonmax(k)+2, latmax(k)-11,txres)
      end if
      end if
    end do

        txres@txFontColor    = "red"
        txres@txJust         = "BottomRight"
    textII = new(dimsizes(index_name),graphic)
    do k=0,dimsizes(index_name)-1
      if (k.eq.2) then
        continue;
      else if (k.eq.0)
        textII(k) = gsn_add_text(wks,map2,index_name(k),index_lonmin(k)+40, index_latmin(k)-8,txres)
      else if (k.eq.1)
        textII(k) = gsn_add_text(wks,map2,index_name(k),index_lonmin(k)+35, index_latmin(k)-20,txres)
      else 
        textII(k) = gsn_add_text(wks,map2,index_name(k),index_lonmin(k)+25, index_latmin(k)-8,txres)
       end if
       end if
       end if
    end do

    ; ===================
    ; panel the plots
    ; ===================
  res1                     = True
    res1@gsnAttachBorderOn   = False
    res1@tiYAxisFontHeightF  = 0.020
  res2                     = True
    res2@gsnMaximize         = True
    res2@gsnAttachPlotsXAxis = True
    res2@tiXAxisFontHeightF  = 0.020
    res2@tiYAxisFontHeightF  = 0.020

  ; map will be the base plot.

  ;amid = gsn_attach_plots(map,map2,res1,res2)
  ;draw(map)    ; All plots will be drawn.
  ;frame(wks)

  panel_res                       = True
  panel_res@gsnPanelFigureStrings = (/"(a) Average CO","(b) SD"/)
  panel_res@gsnPanelFigureStringsJust = "Bottomright"
  panel_res@gsnPanelFigureStringsFontHeightF = 0.014
  panel_res@gsnPanelFigureStringsPerimOn = True
  panel_res@gsnPanelMainString    = "MOPITT Total column, ASON, 2001-2016"
  panel_res@gsnPanelMainFontHeightF = 0.028 
  gsn_panel(wks,(/map,map2/),(/2,1/),panel_res) ; All plots will be drawn.
  ;frame(wks)

  end if    ; PLOT




end
