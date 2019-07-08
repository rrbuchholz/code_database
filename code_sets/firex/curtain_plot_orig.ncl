;=======================================================;
;  curtain_plot.ncl
;=======================================================;
;
; Concepts illustrated:
;   - developed for the KORUS 2016 campaign
;   - open CAM-chem output
;   - read in species
;   - plot 2D field over zoomed region
;   - overplot flight-leg paths
;   - create curtain plots for each flight leg
;
;   Files needed:
;         -CAM-chem output in netCDF format
;
;   Called in as:
;
;         curtain_plot(file, tracer, station(s) lat, station(s) lon,\
;                          station(s) name(s)) 
;
;                                  RRB February 08, 2016
;=======================================================;
load "read_in_species.ncl"

undef("curtain_plot")
procedure curtain_plot(fileIN:string, tracer:string, contour_levels:numeric, forecast_date:numeric)

begin

  ; check input
  if (.not.all(fileexists(fileIN))) then
    print("curtain_plot: Input file does not exist: " + fileIN)
    return
  end if

;--------------------------------------------
; user input
;--------------------------------------------

  ; -------------------------------
  ; CAM-chem files
  ; -------------------------------
  filename = fileIN

  ;------------
  ; define location
  ;------------
  ; KOREA
   topboundary     = 39
   bottomboundary  = 32
   leftboundary    = 123.5
   rightboundary   = 132.5

  ;------------
  ; toggles
  ;------------
    plttype      = "png"           ; pdf or png if want to save
    pltname      = "CAM-chem_"+tracer+"_forecast_curtain"

    outfolder = "forecast_plots/"

;--------------------------------------------
; end user input
;--------------------------------------------

;--------------------------------------------
; set up
;--------------------------------------------
                                             ; CONSTANTS
   H = (8.314*240)/(0.0289751*9.8)           ;--- scale height

   
;*******************************************
;--------------------------------------------
; load file and extract
;--------------------------------------------

  ; -------------------------------
  ; CAM-chem load
  ; -------------------------------
    fin = addfile(filename, "r")           ; read in
     tracer_all = read_in_species(filename, tracer)
     lat = tracer_all&lat
     lon = tracer_all&lon

      date         = fin->date
      datesec      = fin->datesec
      P0           = 0.01*fin->P0          ; change Pa to mb
      Psurf        = 0.01*fin->PS
      hyam         = fin->hyam 
      hybm         = fin->hybm

;printVarSummary(tracer_all)
;print(max(tracer_all))
;exit

  ; -------------------------------
  ; Hybrid levels to pressure levels
  ; -------------------------------
    pm = pres_hybrid_ccm(Psurf, P0, hyam, hybm) ; pi(ntim,klevi,nlat,mlon)

      pm!0         = "time"
      pm!1         = "lev"
      pm!2         = "lat"
      pm!3         = "lon"
      pm&time      = tracer_all&time
      pm&lat       = lat
      pm&lon       = lon
      pm@long_name = "mid-level pressures"
      pm@units     = "hPa"

    ; average the pressure over all 5 days
    pressure_array = dim_avg_n_Wrap(pm,0)

    ; pressure to height
          height = ((-log(tracer_all&lev/1016))*H)/1000
          height@units = "km"


  ; -------------------------------
  ; Define curtain locations
  ; -------------------------------
   ; Curtains
   ;1: 31N-39N at 124.5E 
   ;2: 31N-38N at 127.1E (Seoul—Gwangju-Jeju) 
   ;3: (37.8N, 126.8E) - (34.0N, 130.1E) (Seoul-Daegu-Busan)
   ;4: at 37.5N 124E-132E
   ;5: (32.5N, 126.5E) - (37N, 132E)

    curtain_defs_lon = (/(/124.5,124.5/),\           ;1
                         (/127.1,127.1/),\           ;2 
                         (/126.8,130.1/),\           ;3
                         (/124,132/),\               ;4
                         (/126.5,132/)/)             ;5
    curtain_defs_lat = (/(/32,39/),\                 ;1
                         (/32,38/),\                 ;2
                         (/37.8,34.0/),\             ;3
                         (/37.5,37.5/),\             ;4
                         (/32.5,37/)/)               ;5


;--------------------------------------------
; interpolate to unusual paths #3 and #4
;--------------------------------------------

  npts     =   10                    ; number of points in resulting transect

 ;-------------------
 ; Curtain 3
 ;-------------------
 ; calculate great circle along transects
 ;-------------------
 ; dist     = gc_latlon(leftlat,leftlon,rightlat,rightlon,npts,2)
  dist3     = gc_latlon(curtain_defs_lat(2,0),curtain_defs_lon(2,0),\
                        curtain_defs_lat(2,1),curtain_defs_lon(2,1),npts,2)
  points   = ispan(0,npts-1,1)*1.0 

 ;-------------------
 ; interpolate variable
 ;-------------------
  transect3   = linint2_points(tracer_all&lon,tracer_all&lat,tracer_all,True,dist3@gclon,dist3@gclat,2)
    copy_VarAtts(tracer_all,transect3)          ; copy attributes
    transect3!1      = "lev"                    ; create named dimension and assign
    transect3&lev    = tracer_all&lev           ; coordinate variable for height dimension only

  curtain3 = rm_single_dims(transect3)

 ;-------------------
 ; Curtain 5
 ;-------------------
 ; calculate great circle along transects
 ;-------------------
  dist5     = gc_latlon(curtain_defs_lat(4,0),curtain_defs_lon(4,0),\
                        curtain_defs_lat(4,1),curtain_defs_lon(4,1),npts,2)
  points   = ispan(0,npts-1,1)*1.0 

 ;-------------------
 ; interpolate variable
 ;-------------------
  transect5   = linint2_points(tracer_all&lon,tracer_all&lat,tracer_all,True,dist5@gclon,dist5@gclat,2)
    copy_VarAtts(tracer_all,transect3)          ; copy attributes
    transect5!1      = "lev"                    ; create named dimension and assign
    transect5&lev    = tracer_all&lev           ; coordinate variable for height dimension only

  curtain5 = rm_single_dims(transect5)

;*******************************************
;--------------------------------------------
; plot curtains
;--------------------------------------------
; loop over dates in file
do j= 0,dimsizes(date)-1
  plot_name = outfolder + pltname+"_"+date(j)+"_"+sprintf("%02g",datesec(j)/3600)
   plttype@wkWidth = 2500
   plttype@wkHeight = 2500
  wksII = gsn_open_wks(plttype,plot_name)        
  gsn_define_colormap(wksII,"GMT_wysiwygcont_rrb")

 ;-----------------------
 ; Set resources for plotting
 ;-----------------------
  cres = True
   cres@gsnMaximize         = True  
   cres@gsnDraw		    = False	       ; don't draw it yet
   cres@gsnFrame            = False            ; don't advance frame
  
   cres@cnFillOn             = True            ; turn on color fill
   cres@cnLinesOn            = False           ; turn lines on/off         ; True is default
   cres@cnLineLabelsOn       = False           ; turn line labels on/off   ; True is default
   cres@cnLevelSelectionMode ="ExplicitLevels"
   cres@cnLevels             = contour_levels

   cres@lbLabelBarOn         = False
   cres@cnInfoLabelOn        = False    ; no contour labels

   cres@gsnCenterString = " "	
   cres@gsnLeftString = " "
   cres@gsnRightString = " "

   cres@vpWidthF             = 0.6
   cres@vpHeightF            = 0.5

   res2 = True
   res2 = cres

   tres = True
     copy_VarAtts(cres, tres)

   cres@tmXTOn               = False
   cres@tiMainOffsetYF       =-0.01
   cres@tmYUseLeft           = False               ; disassociate  YR tick marks with YL tick marks
   cres@tmYRLabelsOn         = True                ; turn on the YR tick mark labels
   cres@tmYRMode             = "Explicit"          ; turn off height labels
     hnice = fspan(2.,10.,5)                       ; Set range of "nice" height values.
     pressure = tracer_all&lev
     pnice = ftcurv(height(::-1),pressure(::-1),hnice) ; Calculate "nice" pressure values.
     cres@tmYRValues    = pnice                    ; At each "nice" pressure value, 
     cres@tmYRLabels    = hnice                    ; put a "height" value label.

   res2 = True
     copy_VarAtts(cres, res2)

   cres@tiYAxisString        = "Altitude (hPa)" 
   cres@trYMinF              = 200
   cres@trYReverse           = True                ; reverse y-axis
   cres@tmYLMode             = "Explicit"          ; Define own tick mark labels.
   cres@gsnYAxisIrregular2Log = True
   cres@tmYLValues           = (/925,850,700,500,300,200/)
   cres@tmYLLabels           = (/925,850,700,500,300,200/)



   cres@tmXBMode             = "Manual"

; resources for topography
;res2 = True

  res2@trGridType            = "TriangularMesh"
;  res2@trYLinear          = True
;res2@trYAxisType         ="LogAxis"
;res2@trYCoordPoints   = pnice
;  res2@gsnYAxisIrregular2Log = True


  res2@cnFillOn              = True
  res2@lbLabelBarOn         = False
  res2@cnLinesOn             = False
  res2@cnLineLabelsOn        = False
  res2@cnInfoLabelOn        = False 
  res2@vpWidthF             = 0.6
  res2@vpHeightF            = 0.5

  res2@cnLevelSelectionMode ="ExplicitLevels"
  res2@cnLevels             = contour_levels
  res2@cnMaxLevelCount       = 21
  res2@trYMaxF              = 11
  ;res2@trYReverse            = True
  res2@tiYAxisString        = "" 
  ;res2@tmYLMode             = "Explicit"          ; Define own tick mark labels.
  ;res2@tmYLValues           = (/925,850,700,500,300,200/)
  ;res2@tmYLLabels           = (/925,850,700,500,300,200/)

   res2@gsnCenterString = " "	
   res2@gsnLeftString = " "
   res2@gsnRightString = " "

  res2@lbPerimOn             = False

   res2@tmXBTickSpacingF = 1

 ;-----------------------
 ; Set up each plot
 ;-----------------------
    plots = new((/6/), graphic)
    ;-----------------------
    ; 1. China INFLOW region (N-S)
    ; 31N-39N at 124.5E 
    ;-----------------------
    cres@tiMainString     = "Curtain 1: S-N in West Sea"
    cres@tmXBTickEndF     = 39
    cres@tmXBTickStartF   = 32
    cres@tmXBTickSpacingF = 1
    slice1 = tracer_all(j,:,{31.5:39.5},{124.5})

    ; create pressure array for plotting against
    dims_b   := dimsizes(pm(j,:,{31.5:39.5},{124.5}))
    lat_b    := conform_dims(dims_b,lat({31.5:39.5}),1)
    levels_b := pm(j,:,{31.5:39.5},{124.5})

   levels_b_height:=((-log(levels_b/1016))*H)/1000
          levels_b_height@units = "km"

;printVarSummary(levels_b)
;print(levels_b)
;print(levels_b_height)
;exit


    res2@sfXArray              := lat_b
    res2@sfYArray              := levels_b_height

    ;plots(0) = gsn_csm_contour(wksII,slice1,res2)
    plots(0) = gsn_csm_contour(wksII,slice1,cres)

    ;-----------------------
    ; 2. China INFLOW region + local (N-S)
    ; 31N-38N at 127.1E
    ; (Seoul—Gwangju-Jeju) 
    ;-----------------------
    cres@tiMainString     = "Curtain 2: Jeju to Seoul"
    cres@tiYAxisString    = "" 
    cres@tmXBTickEndF     = 38
    cres@tmXBTickStartF   = 32
    slice2 = tracer_all(j,:,{31.5:38.5},{127.1})

    ; create pressure array for plotting against
    dims_b   := dimsizes(pm(j,:,{31.5:38.5},{127.1}))
    lat_b    := conform_dims(dims_b,lat({31.5:38.5}),1)
    levels_b := pm(j,:,{31.5:38.5},{127.1})
   levels_b_height:=((-log(levels_b/1016))*H)/1000
          levels_b_height@units = "km"

    res2@sfXArray              := lat_b
    res2@sfYArray              := levels_b_height

    ;plots(1) = gsn_csm_contour(wksII,slice2,res2)
    plots(1) = gsn_csm_contour(wksII,slice2,cres)


    ;-----------------------
    ; 3. Local and regional Korean pollution (specified path)
    ; (37.8N, 126.8E) - (34.0N, 130.1E)
    ; (Seoul-Daegu-Busan)
    ;-----------------------
    cres@tiMainString      = "Curtain 3: Seoul to Busan"
    cres@tiYAxisString        = "Altitude (hPa)" 
    cres@tmXBMode          = "Explicit"
    cres@tmXBValues       := toint(fspan(0,8,5))
    cres@tmXBLabels       := new(5, string)
      do i=0,4
        cres@tmXBLabels(i) = sprintf("%5.1f", dist3@gclon(i*2))+"~C~"+sprintf("%5.1f", dist3@gclat(i*2))
      end do
    if (dimsizes(date).eq.1)
      plots(2) = gsn_csm_contour(wksII,curtain3(:,:),cres)
    else
      plots(2) = gsn_csm_contour(wksII,curtain3(j,:,:),cres)
    end if

    ;-----------------------
    ; 4. N/S border region (W-E)
    ; 37.5N 124E-132E
    ;-----------------------
    cres@tiMainString         = "Curtain 4: W-E at Seoul"
    cres@tiYAxisString        = "" 
    cres@tmXBMode             = "Manual"
    cres@tmXBTickEndF         = 132
    cres@tmXBTickStartF       = 124
    cres@tmXBTickSpacingF     = 2
    slice4 = tracer_all(j,:,{37.5},{123.5:132.5})

    ; create pressure array for plotting against
    dims_b   := dimsizes(pm(j,:,{37.5},{123.5:132.5}))
    lat_b    := conform_dims(dims_b,lon({123.5:132.5}),1)
    levels_b := pm(j,:,{37.5},{123.5:132.5})
   levels_b_height:=((-log(levels_b/1016))*H)/1000
          levels_b_height@units = "km"

    res2@sfXArray              := lat_b
    res2@sfYArray              := levels_b_height

    ;plots(3) = gsn_csm_contour(wksII,slice4,res2)
    plots(3) = gsn_csm_contour(wksII,slice4,cres)

    ;-----------------------
    ; 5. Outflow region to Japan (specified path)
    ; (32.5N, 126.5E) - (37N, 132E) 
    ;-----------------------
    cres@tiMainString = "Curtain 5: Korea Strait"
    cres@tiYAxisString        = "Altitude (hPa)" 
    cres@tmXBMode             = "Explicit"
    cres@tmXBValues       := toint(fspan(0,8,5))
    cres@tmXBLabels       := new(5, string)
      do i=0,4
        cres@tmXBLabels(i) = sprintf("%5.1f", dist5@gclon(i*2))+"~C~"+sprintf("%5.1f", dist5@gclat(i*2))
      end do
    cres@trYReverse           = True                 ; reverse y-axis aga
    if (dimsizes(date).eq.1)
      plots(4) = gsn_csm_contour(wksII,curtain5(:,:),cres)
    else
      plots(4) = gsn_csm_contour(wksII,curtain5(j,:,:),cres)
    end if

    ;-----------------------
    ; 6. Transect locations
    ;-----------------------
    tres@tiMainString = "Transect locations (surface)"
    tres@mpOutlineOn         = False                     ; will draw highres map later
    tres@mpLimitMode         ="LatLon"
      tres@mpMinLatF         = bottomboundary
      tres@mpMaxLatF         = topboundary
      tres@mpMinLonF         = leftboundary
      tres@mpMaxLonF         = rightboundary
    tres@gsnMajorLatSpacing  =2
    tres@gsnMajorLonSpacing  =2
    tres@vpHeightF            = 0.1
    tres@tmXBLabelFontHeightF = 0.0036
    tres@tmYLLabelFontHeightF = 0.0036

     plots(5)=gsn_csm_contour_map_ce(wksII,tracer_all(j,dimsizes(tracer_all&lev)-1,:,:),tres)  ; plot temp contours 

     ;----------------------------------------
     ; add countries and counties
     ;----------------------------------------
     country_shp_name    = "shapefiles/US_census_state/tl_2018_us_state.shp"
     lnres                  = True
       lnres@gsLineColor      = "gray24"
       lnres@gsLineThicknessF = .9
      country_id = gsn_add_shapefile_polylines(wksII,plots(5),country_shp_name,lnres)

      world_shp_name    = "shapefiles/GSHHS_NOAA/GSHHS_shp/i/GSHHS_i_L1.shp"
        lnres@gsLineThicknessF = 1.1
      world_id = gsn_add_shapefile_polylines(wksII,plots(5),world_shp_name,lnres)

   ;----------------------------------------
   ; add polylines
   ;----------------------------------------
   ;1: 31N-39N at 124.5E 
   ;2: 31N-38N at 121.8E (Seoul—Gwangju-Jeju) 
   ;3: (37.8N, 126.8E) - (34.0N, 130.1E) (Seoul-Daegu-Busan)
   ;4: at 37.5N 124E-132E
   ;5: (32.5N, 126.5E) - (37N, 132E)
   plres                  = True                      ; polyline mods desired
     plres@gsLineColor      = "grey"                     ; color of lines
     plres@gsLineThicknessF = 7.0                       ; thickness of lines

    cur = new((/dimsizes(curtain_defs_lon(:,0))/), graphic)

    do i= 0,dimsizes(curtain_defs_lon(:,0))-1
      if (i.eq.2) then
        cur(i) = gsn_add_polyline(wksII,plots(5),dist3@gclon,dist3@gclat,plres)
      else if (i.eq.4) then
        cur(i) = gsn_add_polyline(wksII,plots(5),dist5@gclon,dist5@gclat,plres)
      else
        cur(i) = gsn_add_polyline(wksII,plots(5),curtain_defs_lon(i,:),curtain_defs_lat(i,:),plres)
      end if
      end if
    end do

   ;----------------------------------------
   ; add contour labels
   ;----------------------------------------
   ; add station
    txres                   = True
     txres@txFontHeightF    = 0.032                    ; font smaller. default big
     txres@txJust           = "CenterRight"
     txres@txPerimOn        = False
     txres@txFontColor      = "gray23"
     txres@txPerimThicknessF= 2.0
    cur_names = new((/dimsizes(curtain_defs_lon(:,0))/), graphic)
    ;names_array = (/"Curtain 1", "Curtain 2", "Curtain 3",\
    ;                "Curtain 4", "Curtain 5", "Curtain 1"/)
    names_array = (/"C 1", "C 2", "C 3",\
                    "C 4", "C 5", "C 1"/)

    do i= 0,dimsizes(curtain_defs_lon(:,0))-1
      if (i.eq.2) then
        txres@txAngleF              = -45
        cur_names(i) = gsn_add_text(wksII,plots(5),names_array(i),curtain_defs_lon(i,1)+0.5,curtain_defs_lat(i,1)+0.8,txres)
      else if (i.eq.3) then
        txres@txAngleF              = 0
        cur_names(i) = gsn_add_text(wksII,plots(5),names_array(i),curtain_defs_lon(i,1),curtain_defs_lat(i,1)+0.4,txres)
      else if (i.eq.4) then
        txres@txAngleF              = 40
        cur_names(i) = gsn_add_text(wksII,plots(5),names_array(i),curtain_defs_lon(i,1),curtain_defs_lat(i,1)-1.0,txres)
      else
        txres@txAngleF              = 90
        cur_names(i) = gsn_add_text(wksII,plots(5),names_array(i),curtain_defs_lon(i,0)+0.5,curtain_defs_lat(i,0)+0.5,txres)
      end if
      end if
      end if
    end do

  ; add in right Y-axis label
    txres = True
    txres@txFontHeightF := 0.011   ; Label right Y axis.
    txres@txAngleF      := 90.
    gsn_text_ndc(wksII,"Height (km)",.85,.81,txres)
    gsn_text_ndc(wksII,"Height (km)",.85,.55,txres)

   ;----------------------------------------
   ; add in forcast day and tracer name
   ;----------------------------------------
    txres = True
    txres@txFontHeightF = 0.010   ; Label left 
    txres@txAngleF     := 0
      gsn_text_ndc(wksII,"Forecast on: "+forecast_date,.32,0.94,txres)

    txres@txFontHeightF = 0.017   ; Label right
      gsn_text_ndc(wksII,tracername + " ("+tracer_all@units+")",.85,0.94,txres)

   ;----------------------------------------
   ; add in Seoul location
   ; 126.9667, 37.5667
   ;----------------------------------------
   polyres=True                        ; poly marker mods desired     
    polyres@gsMarkerIndex=7            ; choose circle as polymarker
    polyres@gsMarkerSizeF=8.          ; select size to avoid streaking
    polyres@gsMarkerColor="red"        ; set polymarker color
    polyres@tfPolyDrawOrder = "PostDraw"
    polyres@gsMarkerThicknessF =8
    
    ; 2
    gsn_polymarker_ndc(wksII,0.782,0.656,polyres) ; draw polymarkers
    ; 3
    gsn_polymarker_ndc(wksII,0.210,0.380,polyres) ; draw polymarkers
    ; 4
    gsn_polymarker_ndc(wksII,0.635,0.377,polyres) ; draw polymarkers

    gsn_polymarker_ndc(wksII,0.755,0.03,polyres) ; draw polymarkers
    txres@txFontHeightF = 0.010   ; Label right
      gsn_text_ndc(wksII,"Seoul",.80,0.03,txres)

    transect_plot_seoul = gsn_add_polymarker(wksII, plots(5), 126.9667, 37.5667, polyres)

  ; -------------------------------
  ; Panel plot the curtains
  ; -------------------------------
  panel_res                       = True
  panel_res@txString              = "KORUS CAM-chem forecast " + date(j)+\
                                    " "+sprintf("%02g",datesec(j)/3600) +"Z, "+\
                                    sprintf("%02g",mod((datesec(j)/3600)+9,24)) +"KST"
  panel_res@txPosYF               = 0.98
  panel_res@txPosXF               = 0.54
  panel_res@gsnPanelScalePlotIndex = 5
  panel_res@gsnPanelLabelBar = True
  panel_res@lbLabelFontHeightF =0.01
  panel_res@gsnPanelYF = (/0.89,0.89,0.61,0.61,0.32,0.32/)      ; Adjust bottommost plots.
  panel_res@gsnPanelTop = 0.95
  panel_res@gsnPanelBottom = 0.015
  panel_res@pmLabelBarOrthogonalPosF =-0.005
   ;panel_res@gsnPanelDebug =True
  gsn_panel(wksII,plots,(/3,2/),panel_res)    ; will draw the plots

  ;frame(wksII)

  ; -------------------------------
  ; Post-plotting clean-up
  ; -------------------------------
  ; Trim png files to remove white space
  if (plttype.eq."png") then
     system("convert -density 96 -trim "+plot_name+"."+plttype+" "+plot_name+"."+plttype) 
  end if

  delete(cres)

end do

end

