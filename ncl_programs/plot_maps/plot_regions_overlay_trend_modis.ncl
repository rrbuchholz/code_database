;=======================================================;
;  plot_regions_overlay_trend.ncl
;=======================================================;
;
; Concepts illustrated:
;   - plot a map of trends with overlayed boxes showing selected regions
; 
;   To run type:
;         ncl plot_regions_overlay_trend.ncl
;
;   Requires:
;         input emission file
;                                  RRB May 5, 2020
;=======================================================;
; load the libraries

begin

;--------------------------------------------
; user input
;--------------------------------------------
  tracername = "AOD"
  ; -------------------------------
  ; emission files
  ; -------------------------------
  monthname = "August"
  monthval = 8
  years = ispan(2000,2020,1)
  yyyymm = years*100 + monthval
  yfrac = yyyymm_to_yyyyfrac(yyyymm,0)

  ; -------------------------------
  ; MODIS
  ; -------------------------------
  timeseries_files = systemfunc ("ls /IASI/home/buchholz/MODIS/month_files/modis_MOD08_M3L3_3d.nc")

  print(timeseries_files)

  outpath = "/IASI/home/buchholz/"

  ;------------
  ; toggles
  ;------------
  PLOTREGIONS    = True
     WITHCO      = True

;--------------------------------------------
; end user input
;--------------------------------------------

;********************************************
; set up
  ; -------------------------------
  ; plotting parameters
  ; -------------------------------
    ;  latmin                         = -80.               ; World
    ;  latmax                         = 80.
    ;  lonmin                         = -170.
    ;  lonmax                         = 185.
      ;centerlon                      = 0

    ;  latmin                         = -25.               ; NH
    ;  latmax                         = 80.
    ;  lonmin                         = 30.
    ;  lonmax                         = 360.
    ;  centerlon                      = 180

    ;  latmin                         = 20.               ; USA
    ;  latmax                         = 70.
    ;  lonmin                         = -140.
    ;  lonmax                         = -60.

      latmin                         = -35.               ; Gulf Of Guinea
      latmax                         = 30.
      lonmin                         = -30.
      lonmax                         = 60.


  if (PLOTREGIONS) then
    mapType2 = "x11"
    mapName2 = tracername+"_trend_NorthAmerica_"+monthname
  end if ;PLOT

  cr = "~C~"

  ; -------------------------------
  ; Define regions
  ; -------------------------------
   ;region_names = (/"AnthChina", "AnthIndi", "AnthEuro", "AnthUSA",\
   ;                 "BBUSA", "BBCanada", "BBSiberia", "BBWRus",\
   ;                 "BBCAmerica", "BBSAmerica","BBSAmOcean",\
   ;                  "BBCAfrica", "BBSAfrica","BBSAfOcean", \
   ;                 "BBMSEA", "BBNWAu","BBEAu", "NH", "SH"/)

   ;                   minlat, maxlat, minlon, maxlon
   ;region_select = (/(/ 30.,  40.,      110.,      123./),\  ;AnthChina
   ;                  (/ 20.,  30.,       70.,       95./),\  ;AnthIndi
   ;                  (/ 45.,  55.,        0.,       15./),\  ;AnthEuro
   ;                  (/ 35.,  40.,      -95.,      -75./),\  ;AnthUSA
   ;                  (/ 38.,  50.,     -125.,     -105./),\  ;BBUSA
   ;                  (/ 50.,  60.,     -125.,      -90./),\  ;BBCanada
   ;                  (/ 50.,  60.,       90.,      140./),\  ;BBSiberia
   ;                  (/ 35.,  50.,       40.,       85./),\  ;BBWRus
   ;                  (/ 10.,  23.5,    -105.,      -70./),\  ;BBCAmerica
   ;                  (/-25.,  -5.,      -75.,      -50./),\  ;BBSAmerica
   ;                  (/-35., -15.,      -40.,      -25./),\  ;BBSAmericaOcean
   ;                  (/  5.,  15.,      -20.,       38./),\  ;BBCAfrica
   ;                  (/-20.,  -5.,       10.,       40./),\  ;BBSAfrica
   ;                  (/-15.,   0.,      -10.,       10./),\  ;BBSAfOcean
   ;                  (/-10.,   8.,        95.,     125./),\  ;BBMSEA
   ;                  (/-25., -10.,       115.,     140./),\  ;BBNWAu
   ;                  (/-45., -10.,       140.,     155./),\  ;BBEAu
   ;                  (/  0.,  60.,      -180.,     180./),\  ;NH
   ;                  (/-60.,   0.,      -180.,     180./) /) ;SH

   ;region_names = (/"PNW", "Central USA", "East USA", "Great Lakes"/)
   ;                  (/ 32.5,  42.,     -95.,     -75./),\  ;East US

   region_names = (/"PNW", "Central USA", "Northeast"/)

   ;                   minlat, maxlat, minlon, maxlon
   region_select = (/(/ 38.,  57.,     -127.,     -110./),\ ;PNW
                     (/ 35.,  49.,     -110.,     -95./),\  ;Central USA
                     (/ 41.,  53.,     -95.,     -74./) /)  ;Northeast


   n_regions = dimsizes(region_select(:,0))

   ; -----------------------------------------------------
   ; collect region outlines for plotting later
     region_lon := region_select(:,0:1)
     region_lat := region_select(:,2:3)


  ; -------------------------------
  ; Load AOD and calculate trend
  ; -------------------------------

  ; -------------------------------
  ; MODIS
  ; -------------------------------
     print("Collecting MODIS")
     fin = addfile(timeseries_files, "r")            ; read in
     tracer_dummy  = fin->DTDB_CMB_MEAN
        tracer_dummy!0 = "time"
        tracer_dummy!1 = "latitude"
        tracer_dummy!2 = "longitude"
        tracer_dummy@_FillValue = -9999
     tracer = tracer_dummy(time|:,longitude|:,latitude|:)
     tracer&latitude@units = "degrees_north"
     tracer&longitude@units = "degrees_east"

     time = tracer&time
     time@units = "days since -4712-01-01"
     date = cd_calendar(time,0)
     year = date(:,0)
     month = date(:,1)
     ind_select_month = ind(month.eq.monthval)
     ;print(year(ind_select_month)+" "+month(ind_select_month))
     ;print(date)

   tracer_array = new((/dimsizes(years),dimsizes(tracer&longitude),dimsizes(tracer&latitude)/), float)
      ; select years
      tracer_array(2:19,:,:)=tracer(ind_select_month(1:dimsizes(ind_select_month)-1),:,:)

      tracer_array!0 = "time"
      tracer_array&time = yyyymm

   mean_co = dim_avg_n_Wrap(tracer_array,0)
      mean_co!0 = "longitude"
      mean_co!1 = "latitude"

   ; calc trend
   rc           = ((regCoef(yfrac,tracer_array(latitude|:,longitude|:,time|:)))/mean_co(latitude|:,longitude|:))*100       
   
   rc@long_name = "regression coefficient (trend)"
   rc@units     = "percent/year"
      rc!0 = "latitude"
      rc&latitude = tracer&latitude
      rc!1 = "longitude"
      rc&longitude = tracer&longitude
 print(rc@tval)

    tval1 = new(dimsizes(rc) , float)
    nxy1  = new(dimsizes(rc) , integer)
    b1    = new(dimsizes(rc) , float)
    unity    = new(dimsizes(rc) , float)
    rc1   = regcoef (yfrac,tracer_array(latitude|:,longitude|:,time|:), tval1,nxy1)
      rc1!0 = "latitude"
      rc1&latitude = tracer&latitude
      rc1!1 = "longitude"
      rc1&longitude = tracer&longitude
    rc1a = (rc1/mean_co(latitude|:,longitude|:))*100


   df   = nxy1-2       ; degrees of freedom: n-2
   b1    = 0.5          ; b must be same size as tval (and df)
   ;prob  = betainc(df/(df+tval1^2),df/2.0,b1)
   prob = (1 - betainc(df/(df+tval1^2),df/2.0,b1) )
      prob!0 = "latitude"
      prob&latitude = tracer&latitude
      prob!1 = "longitude"
      prob&longitude = tracer&longitude
      prob@_FillValue = -1e+30
    
  ; Select probability limit
   prob_limit = 0.95
 
    rc1b = where(prob.lt.prob_limit, rc1a@_FillValue, rc1a)
      rc1b!0 = "latitude"
      rc1b&latitude = tracer&latitude
      rc1b!1 = "longitude"
      rc1b&longitude = tracer&longitude

   lat_array = conform(rc1b,rc1b&latitude,0)
   lat_array = where(prob.lt.prob_limit, lat_array@_FillValue, lat_array)
   lon_array = conform(rc1b,rc1b&longitude,1)
   lon_array = where(prob.lt.prob_limit, lon_array@_FillValue, lon_array)


printVarSummary(tracer)
printVarSummary(tracer_array)
printVarSummary(rc)
printVarSummary(mean_co)
print(yyyymm)
print(yyyymm+ " "+tracer_array(:,{-150},{40}))
;print(tracer&latitude)

  ;********************************************
  ;-------------------
  ; MAP PLOT
  ;-------------------
  if (PLOTREGIONS) then
    wks2 = gsn_open_wks(mapType2,mapName2)
    ;-------------------
    ; define resources 
    ; to use for plotting
    ;-------------------
    mapres = True
    mapres@tiMainString              = ""                 ; changing main large title
    mapres@gsnLeftString             = ""                 ; change left 
    mapres@gsnRightString             = ""                 ; change left 
    mapres@gsnFrame                  = False              ; do not advance frame
    mapres@gsnDraw		     = False	          ; don't draw it yet
    mapres@mpCenterLonF              =10

    mapres@mpLimitMode               ="LatLon"            ; zoom to Australia
      mapres@mpMinLatF               = latmin
      mapres@mpMaxLatF               = latmax
      mapres@mpMinLonF               = lonmin
      mapres@mpMaxLonF               = lonmax
    ;  mapres@mpCenterLonF            = centerlon

    mapres@vpXF = 0.1
    mapres@vpYF = 0.8
    mapres@vpHeightF            = 0.4          ; set height of plot

    ;-------------------
    ; do the plotting
    ;-------------------

   if (WITHCO) then
     mapres@gsnMaximize           = True             ; make large
     mapres@mpFillOn              = False            ; turn off default background gray
     mapres@mpGeophysicalLineThicknessF = 6
     ;mapres@tmXTMinorOn           = False
     ;mapres@tmYRMinorOn           = False
     ;mapres@tmXTMajorOn           = False
     ;mapres@tmYRMajorOn           = False
     mapres@tmBorderThicknessF   = 4.0
     ;mapres@tmXBMajorThicknessF  = 5.0
     ;mapres@tmXBMinorThicknessF  = 5.0
     ;mapres@tmYLMajorThicknessF  = 5.0
     ;mapres@tmYLMinorThicknessF  = 5.0
     mapres@tmYROn = False            ; Turn off right tickmarks.
     mapres@tmXTOn = False            ; Turn off top tickmarks.    

     ; contour levels
     mapres@cnFillOn              = True             ; turn on color
     ;mapres@cnFillPalette         = "BlWhRe" ; set color map
     mapres@cnFillPalette         = "BlueWhiteOrangeRed" ; set color map
     mapres@cnLinesOn             = False            ; turn off contour lines
     mapres@cnLineLabelsOn        = False            ; turn off contour line labels
     mapres@cnFillMode            = "RasterFill"
     mapres@cnLevelSelectionMode  = "ManualLevels"   ; set manual contour levels
     mapres@cnMinLevelValF        =  -8.6           ; set min contour level
     mapres@cnMaxLevelValF        =   8.6           ; set max contour level
     mapres@cnLevelSpacingF       =   0.2            ; set contour interval
     ;mapres@cnFillPalette         = "hotcolr_19lev" ; set color map
     ;mapres@cnLevelSelectionMode = "ExplicitLevels" ; set explicit contour levels
     ;mapres@cnLevels = log10((/0.1,0.3,0.5,0.75,1,3,5,7.5,10,30,75,100/)) ; set levels 

     ; label bar
     mapres@lbBoxEndCapStyle    = "TriangleBothEnds"
     mapres@lbBoxLinesOn        = True
     mapres@lbTitleOn           = True
     mapres@lbTitleFontHeightF  = 0.014
     mapres@lbTitleString       = " % per year"
     mapres@lbTitlePosition     = "bottom"
   
     mapres@tiMainString          = monthname + " AOD trend"
     ;map1 = gsn_csm_contour_map_ce(wks2,rc1b,mapres)    
     map1 = gsn_csm_contour_map_ce(wks2,rc,mapres)    

    ; Add significance hashes
    pmres = True
      pmres@gsMarkerColor = "gray60"
      pmres@gsMarkerIndex = 16
      pmres@gsMarkerSizeF = 0.004

     ;pmres@gsMarkerColor = "black"
     ;pmres@gsMarkerSizeF = 0.001


    dummy = gsn_add_polymarker(wks2, map1, lon_array, lat_array, pmres)


  ; mapres@cnLevelSelectionMode  = "ManualLevels"   ; set manual contour levels
  ; mapres@cnMinLevelValF        =  0           ; set min contour level
  ; mapres@cnMaxLevelValF        =  1          ; set max contour level
  ; mapres@cnLevelSpacingF       =  0.1            ; set contour interval
  ;   map1 = gsn_csm_contour_map_ce(wks2,prob,mapres)    

   else 
    map1 = gsn_csm_map(wks2,mapres)                          ; draw a blank map
   end if

    ;-------------------
    ; add names
    ;-------------------
    txres = True
      txres@txFontHeightF = 0.018                     ; font smaller. default big
      txres@txFontThicknessF = 12.
      txres@txFontColor = "black"
      txres@txBackgroundFillColor = "white"
      txres@txPerimSpaceF = 0.2

    do i=0,n_regions-1
      if (region_names(i).eq."SH".or.region_names(i).eq."NH") then 
         continue
      else if (region_names(i).eq."BBCAfrica") then 
       ; dum = gsn_add_text(wks2,map1,region_names(i),10,\
       ;                    (region_select(i,0)+region_select(i,1))/2,txres)
      else if (region_names(i).eq."BBMSEA") then 
       ; dum = gsn_add_text(wks2,map1,region_names(i),(region_select(i,2)+region_select(i,3))/2.2,\
        ;                   (region_select(i,0)+region_select(i,1))/2+5,txres)
      else if (region_names(i).eq."Central USA".or.region_names(i).eq."Northeast") then 
        dum = gsn_add_text(wks2,map1,region_names(i),(region_select(i,2)+region_select(i,3))/2,\
                           region_select(i,0)-1.5,txres)
      else
        dum = gsn_add_text(wks2,map1,region_names(i),(region_select(i,2)+region_select(i,3))/2+0.8,\
                           region_select(i,0)-1.5,txres)
      end if
      end if
      end if
      end if
    end do

   draw(map1)


    ;-------------------
    ; draw region boxes
    ;-------------------
    boxres = True
      boxres@gsLineThicknessF = 8

      do j=0,n_regions-1
       if (region_names(j).eq."CWAS1".or.region_names(j).eq."CWAS2") then 
         continue
       else if (region_names(j).eq."SH".or.region_names(j).eq."NH") then 
       boxres@gsLineColor      = "forestgreen"
       boxres@gsLineDashPattern  = 0  
         regions_lon := (/360-179,0/)
         regions_lon2 := (/0,180/)
         regions_lat := (/region_select(j,0),region_select(j,0)/)
         regions_lat2 := (/region_select(j,1),region_select(j,1)/)
         gsn_polyline(wks2,map1,regions_lon,regions_lat,boxres)
         gsn_polyline(wks2,map1,regions_lon2,regions_lat,boxres)
         gsn_polyline(wks2,map1,regions_lon,regions_lat2,boxres)
         gsn_polyline(wks2,map1,regions_lon2,regions_lat2,boxres)
       else if (region_names(j).eq."AnthChina".or.\
                region_names(j).eq."AnthEuro".or.\
                region_names(j).eq."AnthUSA".or.\
                region_names(j).eq."AnthIndi") then 
       boxres@gsLineColor      = "red"
       boxres@gsLineDashPattern  = 0  
         regions_lon := (/region_select(j,2), region_select(j,2), \
                          region_select(j,3) , region_select(j,3), \
                          region_select(j,2)/)
         regions_lat := (/region_select(j,0), region_select(j,1), \
                          region_select(j,1) , region_select(j,0), \
                          region_select(j,0)/)
         gsn_polyline(wks2,map1,regions_lon,regions_lat,boxres)
       else
       boxres@gsLineColor      = "gray20"
       boxres@gsLineDashPattern  = 0 
         regions_lon := (/region_select(j,2), region_select(j,2), \
                          region_select(j,3) , region_select(j,3), \
                          region_select(j,2)/)
         regions_lat := (/region_select(j,0), region_select(j,1), \
                          region_select(j,1) , region_select(j,0), \
                          region_select(j,0)/)
         gsn_polyline(wks2,map1,regions_lon,regions_lat,boxres)
       end if
       end if
       end if
      end do

    frame(wks2)
   end if ; PLOTREGIONS

end

