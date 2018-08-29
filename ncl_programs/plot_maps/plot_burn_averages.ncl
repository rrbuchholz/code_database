;================================================;
;  plot_burn_averages.ncl
;================================================;
;
; Concepts illustrated:
;   - For use with GFED 4 burned area
;   - Plotting region on a map
;
;   Files needed:
;         -GFED 4 burned area
;
;   To run type:
;         plot_burn_averages.ncl
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
    ;burn_file = "/IASI/home/buchholz/burned_area/GFED_4/GFED4.0_MQ_201609_BA.hdf"
    ;burn_file = "/IASI/home/buchholz/burned_area/averages/burnarea_ASON_2001_2016.nc"
    ;burn_file = "/IASI/home/buchholz/burned_area/averages/burnarea_01to12_2014.nc"
    ;burn_file = "/IASI/home/buchholz/burned_area/averages/burnarea_sum_01to12_2014.nc"
    burn_file = "/IASI/home/buchholz/burned_area/averages/burnarea_2001to2016.nc"
    sd_file = "/IASI/home/buchholz/burned_area/averages/burnarea_2001_2016_ASONsd.nc"

   yyyy = 2014

   ; -------------------------------
   ; SELECT OUTPUT
   ; -------------------------------
   PLOT   = True                             ; generate map plot

   if (PLOT) then                            ; Map plot
       mapDir  = "./"                        ; directory for plot output
       mapName = "BurnedArea_percent" ; plot name output
       mapType = "x11"                       ; workstation type
        mapType@wkWidth = 1800
        mapType@wkHeight = 1800 
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

   burn_area = "BurnedArea"

;--------------------------------------------
; Extract MOPITT trace gas information
;--------------------------------------------
  fin = addfile(burn_file, "r")             ; load

  data = fin->$burn_area$      ; extract total column data (:,:)
  
  ; create grid
  lon = fspan(-179.875,179.875,1440)
   lon@units = "degrees_east"
   lon@long_name = "longitude"
 lat = fspan(89.875,-89.875,720)
   lat@units = "degrees_north"
   lat@long_name = "latitude"

  ; -------------------------------
  ; rename coordinate variables
  ; -------------------------------
  data!0 = "lat"
  data&lat = lat
  data!1 = "lon"
  data&lon = lon
   printVarSummary(data) 
;--------------------------------------------
; Mask Ocean
;--------------------------------------------
   a    = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
   lsdata = a->LSMASK
   lsm  = landsea_mask(lsdata,data&lat,data&lon)
   tracer = mask(data,lsm.eq.0,False)
   printVarSummary(tracer) 
   ;tracer    = where(tracer.ne.0,tracer,tracer@_FillValue)
    tracer!0 = "lat"
    tracer&lat = lat
    tracer!1 = "lon"
    tracer&lon = lon

;--------------------------------------------
; Percent burned
;--------------------------------------------
   re = 6.37122e03 ; [km] average radius of earth
   pi = 4.0*atan(1.0)
   rad = pi/180.0
   rr = re*rad 
   
   dy = (lat(2)-lat(1))*rr ; dx=dlon at equator [km]
   dx = dy*cos(lat*rad) ; dx[*] at each latitude, note degrees need to be in radians

   area = conform_dims(dimsizes(data),dx*dy,0)

   percent_burned = ((tracer*0.01)/area)*100    ; hectare -> km^2
     percent_burned!0 = "lat"
     percent_burned&lat = lat
     percent_burned!1 = "lon"
     percent_burned&lon = lon

    print("area: min="+min(area)+" max="+max(area)) 
    print("burned area hectares: min="+min(tracer)+" max="+max(tracer)) 
    print("percent: min="+min(percent_burned)+" max="+max(percent_burned)) 


;--------------------------------------------
; Extract MOPITT sd
;--------------------------------------------
  sd_fin = addfile(sd_file, "r")             ; load
  sd_data = sd_fin->$burn_area$      ; extract total column data (:,:)

  sd_data!0 = "lat"
  sd_data&lat = lat
  sd_data!1 = "lon"
  sd_data&lon = lon
   sd_tracer = mask(sd_data,lsm.eq.0,False)
   printVarSummary(sd_tracer) 
  sd_tracer!0 = "lat"
  sd_tracer&lat = lat
  sd_tracer!1 = "lon"
  sd_tracer&lon = lon

 ; sd_tracer    = where(sd_tracer.ne.0,sd_tracer,sd_tracer@_FillValue)

   sd_percent_burned = ((sd_tracer*0.01)/area)*100
     sd_percent_burned!0 = "lat"
     sd_percent_burned&lat = lat
     sd_percent_burned!1 = "lon"
     sd_percent_burned&lon = lon

;--------------------------------------------
; Plot data
;--------------------------------------------
  ;************
  ; MAP PLOT
  ;************

  if (PLOT) then
    wks = gsn_open_wks(mapType,mapName)
    gsn_define_colormap(wks,"sunshine_9lev")        ; change colour map
;WhiteYellowOrangeRed, MPL_afmhot
;    gsn_reverse_colormap(wks)
;gsn_draw_colormap(wks)
;exit

    ;-----------------------------------
    ; define resources to use for plotting
    ;-----------------------------------
    mapres = True
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
    ;mapres@lbOrientation             = "Vertical"     ; Label bar location
    mapres@lbLabelAutoStride         = True
    mapres@lbBoxLinesOn              = False
    mapres@lbBoxEndCapStyle           = "TriangleBothEnds"
    mapres@pmLabelBarOrthogonalPosF  = .35            ; move whole thing down

    mapres@gsnStringFontHeightF        =0.014
    mapres@tmXBLabelFontHeightF        =0.014
    mapres@tmYLLabelFontHeightF        =0.014
    mapres@tmXBTickSpacingF            = 30.
    mapres@tmYLTickSpacingF            = 20.

    mapres@cnMissingValFillPattern = 0             ; choose fill pattern 0 (solid fill) 
    mapres@cnMissingValFillColor   = "grey"        ; color fill missing areas grey
    mapres@cnMissingValPerimThicknessF  = 2.0      ; increase missing value perimeter thickness

    mapres@mpLimitMode               ="LatLon"
      ;mapres@mpMinLatF               = 10       ; zoom to USA
      ;mapres@mpMaxLatF               = 70
      ;mapres@mpMinLonF               = 220
      ;mapres@mpMaxLonF               = 300
      ;-------------------------------------
      ;mapres@mpMinLatF               = 0      ; zoom to India
      ;mapres@mpMaxLatF               = 45
      ;mapres@mpMinLonF               = 55
      ;mapres@mpMaxLonF               = 130
      ;mapres@mpCenterLonF           = 65
      ;-------------------------------------
      mapres@mpMinLatF               = 20       ; zoom to NH
      mapres@mpMaxLatF               = 87
      mapres@mpMinLonF               = -170
      mapres@mpMaxLonF               = 200
      ;mapres@mpCenterLonF           = 65
      ;-------------------------------------
      ;mapres@mpMinLatF               = -70       ; zoom to SH
      ;mapres@mpMaxLatF               = 15
      ;mapres@mpMinLonF               = -110
      ;mapres@mpMaxLonF               = 240
      ;mapres@mpCenterLonF            = 65
      ;-------------------------------------
      ;mapres@mpMinLatF               = -85       ; zoom to +/- 80
      ;mapres@mpMaxLatF               = 85
      ;mapres@mpMinLonF               = -170
      ;mapres@mpMaxLonF               = 185
      ;mapres@mpCenterLonF            = 65

    ;-----------------------------------
    ; end define resources
    ;-----------------------------------

    ; ===================
    ; CO plot
    ; ===================
    mapres@lbTitleString             = "% Burned Area"  ; Label Bar title
    mapres@gsnRightString             = "MODIS average yearly % Burned Area 2014-2016"  ; Label Bar title
    ;mapres@lbTitleString             = "km~S2~2"             ; Label Bar title
    ;mapres@gsnRightString            = ""               ; change right title
    mapres@cnLevelSelectionMode      = "ExplicitLevels"
    ;pows = fspan(1,4.5,15)
    ;labels = 10^pows
    ;mapres@cnLevels                  = labels
    ;mapres@lbLabelStrings            = labels
    pows = fspan(-2,2,9)
    labels = 10^pows
    print(labels)
    ;labels :=(/0.1,1,1.5,3,3.7,4.8,6.3,8.2,10,14,19,24,30/)
    ;labels :=(/0.3,1,3,6,32/)
    mapres@cnLevels                  = labels/2
    mapres@lbLabelStrings            = sprintf("%5.2f", labels/2)
    ;mapres@cnLevelSelectionMode      = "ManualLevels"
    ;  ;%
    ;  mapres@cnMinLevelValF          = 0.          ; set the minimum contour level
    ;  mapres@cnMaxLevelValF          = 30.         ; set the maximum contour level
    ;  mapres@cnLevelSpacingF         = 2.          ; set the interval between contours

   ; map = gsn_csm_contour_map_ce(wks,tracer(::-1,:),mapres)
    map = gsn_csm_contour_map_ce(wks,percent_burned(::-1,:),mapres)

    ; ===================
    ; SD plot
    ; ===================
   ; mapres@cnLevelSelectionMode      = "ExplicitLevels"
    ;mapres@lbTitleString             := "x 10~S2~17   molec cm~S2~-2"             ; Label Bar title
    ;pows := fspan(0,4,10)
    ;labels := 8^pows
    ;mapres@cnLevels                  := labels
    ;mapres@lbLabelStrings            := labels
     ;tcol
    ;mapres@cnLevelSelectionMode      = "ManualLevels"
     ; mapres@cnMinLevelValF          = 0.2e17   ; set the minimum contour level
     ; mapres@cnMaxLevelValF          = 3.2e17    ; set the maximum contour level
     ; mapres@cnLevelSpacingF         = 0.25e17    ; set the interval between contours
      ;vmr
    ;  mapres@cnMinLevelValF          = 5.          ; set the minimum contour level
    ;  mapres@cnMaxLevelValF          = 30.         ; set the maximum contour level
    ;  mapres@cnLevelSpacingF         = 0.5          ; set the interval between contours

   ; map2 = gsn_csm_contour_map_ce(wks,sd_tracer(::-1,:),mapres)
    map2 = gsn_csm_contour_map_ce(wks,sd_percent_burned(::-1,:),mapres)

    ;-------------------
    ; draw region boxes
    ;-------------------
    boxres = True
      boxres@gsLineColor      = "black"
      boxres@gsLineThicknessF = 5

      ;region_name = (/"NorthAustralasia","SouthAustralasia","Indonesia","CSAfrica","SSAfrica",\
      ;                 "EastSAmerica","WestSAmerica"/)
      ;latmin = (/-25.,-50.,-10.,-25.,-40.,-60.,-60./)
      ;latmax = (/-10.,-25.,10.,-10.,-25.,4.,4./)
      ;lonmin = (/110.,110.,90.,0.,0.,-60 + 360.,-80 + 360./)
      ;lonmax = (/180.,180.,160.,59.,59.,-40 + 360.,-60 + 360./)

      ;region_name = (/"Australasia","Indonesia","SAfrica",\
      ;                "SouthAmerica", "Siberia", "NAmerica"/)
      ;region_acr = (/"NAus","MSEA","SAf",\
      ;                 "SAm", "Sib", "NAm"/)
      ;latmin = (/-50.,-10.,-40.,-60.,50., 25./)
      ;latmax = (/-10.,10.,5.,4.,85.,70./)
      ;lonmin = (/110.,90.,0.,-80 + 360.,91.,-170.+360./)
      ;lonmax = (/180.,160.,60.,-40 + 360.,190.,-53.+360./)


     region_name = (/"Northwest Canada", "Northwest USA",\
                    "Southeast USA" , "Siberia"/);,\
                    ;"India"/)
  ;                   minlat, maxlat, minlon, maxlon
     region_select = (/(/ 54.,  67., 360.-120., 360.-93./),\ ;NWCan
                     (/ 40.,  51., 360.-125., 360.-105./),\ ;NWUS
                     (/ 30.,  41., 360.-102., 360.-88./),\;SEUS
                     (/ 50.,  85.,      91.,     190./)/); ,\; Siberia
                     ;(/ 20.,  40.,      65.,     90./) /) ;India


      ;region_acr = (/"NAus","MSEA","SAf",\
      ;                 "SAm", "Sib", "NAm"/)
      latmin = region_select(:,0)
      latmax = region_select(:,1)
      lonmin = region_select(:,2)
      lonmax = region_select(:,3)

     region_names = (/"Australasia", "Maritime SEA", \
                    "Southern Africa", "South ~C~America",\
                    "Siberia", "North ~C~America" /)

   ; -----------------------------------------------------
    dum = new(dimsizes(region_name),graphic)
    dum2 = new(dimsizes(region_name),graphic)
    do j=0,dimsizes(region_name)-1
     region_lon := (/lonmin(j), lonmin(j), lonmax(j), lonmax(j), lonmin(j)/)
     region_lat := (/latmin(j), latmax(j), latmax(j), latmin(j), latmin(j)/)
     dum(j) = gsn_add_polyline(wks,map,region_lon,region_lat,boxres)
     dum2(j) = gsn_add_polyline(wks,map2,region_lon,region_lat,boxres)
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

      region_acr = (/"NAus","SAus","MSEA","CSAf","SSAf",\
                       "ESAm","WSAm"/)
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
  panel_res@gsnPanelFigureStrings = (/"(c) Average Burned Area","(d) SD of  Burned Area"/)
  panel_res@gsnPanelFigureStringsJust = "Bottomright"
  panel_res@gsnPanelFigureStringsFontHeightF = 0.014
  panel_res@gsnPanelFigureStringsPerimOn = True
  panel_res@gsnPanelMainString    = "Burned Area, ASON, 2001-2016"
  panel_res@gsnPanelMainFontHeightF = 0.028 
  ;gsn_panel(wks,(/map,map2/),(/2,1/),panel_res) ; All plots will be drawn.
  ;frame(wks)

  draw(map)    ; All plots will be drawn.
  frame(wks)

  end if    ; PLOT




end
