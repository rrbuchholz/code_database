;================================================;
;  plot_region_grid.ncl
;================================================;
;
; Concepts illustrated:
;   - Plot World Map
;   - Overlay region of interest boxes
;
;   To run type:
;         ncl plot_region_grid.ncl 
;                                          rrb 20180501
; ================================================;

begin
;***************************************************************
; User Input
;***************************************************************
   cr = tochar(10)
   region_name = (/"North~C~Australasia","South~C~Australasia","Maritime SEA",\
                   "Central~C~Southern Africa","South~C~Southern Africa",\
                   "Central~C~South America", "Southern~C~South America"/)
   region_acr = (/"NAus","SAus","MSEA","CSAf","SSAf",\
                    "CSAm","SSAm"/)
   latmin = (/-25.,-50.,-10.,-25.,-40.,-25.,-60./)
   latmax = (/-10.,-25.,10.,-10.,-25.,-5.,-25./)
   lonmin = (/110.,110.,90.,0.,0.,-80 + 360.,-80 + 360./)
   lonmax = (/180.,180.,160.,59.,59.,-32 + 360.,-32 + 360./)
   lonadjust = (/4.,4.,5.,0.,0.,-5.,-5./)
   latadjust = (/-15.,-25.,4.,4.,-20.,4.,-20./)

   ; -------------------------------
   ; SELECT OUTPUT
   ; -------------------------------
   PLOT   = True                             ; generate map plot

   if (PLOT) then                            ; Map plot
       mapDir  = "./"                        ; directory for plot output
       mapName = "/net/mopfl/home/buchholz/map_regions" ; plot name output
       mapType = "png"                       ; workstation type
        mapType@wkWidth = 1800
        mapType@wkHeight = 1800 
   end if

;***************************************************************
; End User Input
;***************************************************************


;--------------------------------------------
; MAP PLOT
;--------------------------------------------
  if (PLOT) then
    wks = gsn_open_wks(mapType,mapName)
    gsn_define_colormap(wks,"haxby_rrb")        ; change colour map

    ;-----------------------------------
    ; define resources to use for plotting
    ;-----------------------------------
    mapres = True

    mapres@tiMainString              = "Defined Regions"
    mapres@gsnLeftString             = ""                                 ; change left title
    mapres@gsnRightString            = "" ; change right title
    mapres@gsnFrame                  = False             ; do not advance frame
    mapres@gsnDraw                   = False             ; do not advance frame
    mapres@vpXF                      = 0.06
    mapres@gsnMaximize               = True  

    mapres@mpGeophysicalLineThicknessF = 25.5

    mapres@gsnStringFontHeightF        =0.014
    mapres@tmXBLabelFontHeightF        =0.014
    mapres@tmYLLabelFontHeightF        =0.014
    mapres@tmXBTickSpacingF            = 60.
    mapres@tmYLTickSpacingF            = 40.

    mapres@mpLandFillColor        = "darkolivegreen3"
    mapres@mpOceanFillColor       = "lightblue2"
    mapres@mpInlandWaterFillColor = "lightblue2"

    ;mapres@mpLimitMode               ="LatLon"
      ;-------------------------------------
      ;mapres@mpMinLatF               = -70       ; zoom to SH
      ;mapres@mpMaxLatF               = 15
      ;mapres@mpMinLonF               = -120
      ;mapres@mpMaxLonF               = 245
      mapres@mpCenterLonF            = 60

    ;-----------------------------------
    ; end define resources
    ;-----------------------------------

    ;-------------------
    ; base plot
    ;-------------------
    map = gsn_csm_map(wks,mapres)

    ;-------------------
    ; draw region boxes
    ;-------------------
    boxres = True
      boxres@gsLineColor      = "black"
      boxres@gsLineThicknessF = 8

   ; -----------------------------------------------------
    dum = new(dimsizes(region_name),graphic)
    dum2 = new(dimsizes(region_name),graphic)
    do j=0,dimsizes(region_name)-1
     region_lon := (/lonmin(j), lonmin(j), lonmax(j), lonmax(j), lonmin(j)/)
     region_lat := (/latmin(j), latmax(j), latmax(j), latmin(j), latmin(j)/)
     dum(j) = gsn_add_polyline(wks,map,region_lon,region_lat,boxres)
     ;dum2(j) = gsn_add_polyline(wks,map,region_lon,region_lat,boxres)
    end do

    ;-------------------
    ; add text for regions
    ;-------------------
    ;drawNDCGrid(wks)
       txres = True
        txres@txFontHeightF  = 0.016
        txres@txJust         = "BottomCenter"
        txres@txFontColor    = "black"
        ;txres@txPerimOn      = True
 
    text = new(dimsizes(region_name),graphic)
    do k=0,dimsizes(region_name)-1
      if (k.eq.2.or.k.eq.3.or.k.eq.5) then
        text(k) = gsn_add_text(wks,map,region_name(k),lonmin(k)+lonadjust(k), latmax(k)+latadjust(k),txres)
      else if (k.eq.0.or.k.eq.1)
        txres@txJust         = "BottomLeft"
        text(k) = gsn_add_text(wks,map,region_name(k),lonmax(k)+lonadjust(k), latmax(k)+latadjust(k),txres)
      else
        text(k) = gsn_add_text(wks,map,region_name(k),lonmin(k)+lonadjust(k), latmin(k)+latadjust(k),txres)
      end if
      end if
    end do


  draw(map)
  frame(wks)

  end if    ; PLOT




end
