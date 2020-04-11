; =================================================================
; trajectory_plot.ncl
; -----------------------------------------------------------------
; 22 June 2019, Siyuan Wang (siyuan@ucar.edu)
;   - User provide a series of lat/lon endpoints of a trajectory
;     then this procedure extracts the curtain along the trajecotyr
;   - Files needed: CAM-chem output in netCDF format
;   - Called in as:
;     trajectory_plot(file, tracer, station(s) lat, station(s) lon,\
;                          station(s) name(s)) 
; -----------------------------------------------------------------
; Created based on Rebecca Buchholz's original transect scripts
; =================================================================
load "read_in_species.ncl"


undef("trajectory_plot")
procedure trajectory_plot(fileIN:string, tracer:string, contour_levels:numeric, forecast_date:numeric)

begin

  ; check input
  if (.not.all(fileexists(fileIN))) then
    print("trajectory_plot: Input file does not exist: " + fileIN)
    return
  end if

;--------------------------------------------
; user input
;--------------------------------------------

  ; -------------------------------
  ; CAM-chem files
  ; -------------------------------
  filename = fileIN
  print(""+filename)

  ;------------
  ; define location
  ;------------
  ; NAM
   topboundary     = 65.0
   bottomboundary  = 15.0
   leftboundary    = -140.0
   rightboundary   = -70.0

   
  ;------------
  ; toggles
  ;------------
    plttype      = "png"           ; pdf or png if want to save
    pltname      = "CAM-chem_"+tracer+"_forecast_trajectory"
;--------------------------------------------
; interpolate to unusual paths #3 and #4
;--------------------------------------------

  npts     =   200                    ; number of points in resulting transect
  n_tickmarks_XB = 8

;--------------------------------------------
; end user input
;--------------------------------------------

;--------------------------------------------
; set up
;--------------------------------------------
                                             ; CONSTANTS
   H = (8.314*240)/(0.0289751*9.8)           ;--- scale height

 ; if (tracer.eq."CO01") then
   ; tracername = "CO: S.Korea - anthro"
 ; else if (tracer.eq."CO02") then
   ; tracername = "CO: Japan - anthro"
 ; else if (tracer.eq."CO03") then
   ; tracername = "CO: NE China  - anthro"
 ; else if (tracer.eq."CO04") then
   ; tracername = "CO: N. China  - anthro"
 ; else if (tracer.eq."CO05") then
   ; tracername = "CO: S. China - anthro"
 ; else if (tracer.eq."CO06") then
   ; tracername = "CO: S. Asia  - anthro"
 ; else if (tracer.eq."CO07") then
   ; tracername = "CO: N. Asia -fires"
 ; else if (tracer.eq."CO08") then
   ; tracername = "CO: Central Asia - fires"
 ; else if (tracer.eq."CO09") then
   ; tracername = "CO: S. Asia - fires" 
 ; else if (tracer.eq."ISOP_etc") then
   ; tracername = "ISOP + MACR + MVK"
 ; else if (tracer.eq."CO_var") then
   ; tracername = "CO variability [0.5*(max-min)/avg]"

 ; else if (tracer.eq."O3") then
   ; tracername = "O~B~3~N~"
 ; else if (tracer.eq."NOx") then
   ; tracername = "NO~B~x~N~"   
   
 ; else
   ; tracername = tracer
 ; end if
 ; end if
 ; end if
 ; end if
 ; end if
 ; end if
 ; end if
 ; end if
 ; end if
 ; end if
 ; end if
 
 ; end if
 ; end if


   
; ;*******************************************
; ;--------------------------------------------
; ; load file and extract
; ;--------------------------------------------

  ; ; -------------------------------
  ; ; CAM-chem load
  ; ; -------------------------------
    fin = addfile(filename, "r")           ; read in
     ; if (tracer.eq."ISOP_etc") then
        ; tracer_dummy1 = fin->ISOP          ; mol/mol
        ; tracer_dummy2 = fin->MACR          ; mol/mol
        ; tracer_dummy3 = fin->MVK           ; mol/mol
        ; tracer_dummy = tracer_dummy1 +tracer_dummy2 + tracer_dummy3
          ; copy_VarCoords(tracer_dummy1,tracer_dummy)
          ; copy_VarAtts(tracer_dummy1,tracer_dummy)
          ; tracer_dummy@long_name = "ISOP + MACR + MVK concentration"
      ; else if (tracer.eq."NOx") then
        ; tracer_dummy1 = fin->NO2          ; mol/mol
        ; tracer_dummy2 = fin->NO          ; mol/mol
        ; tracer_dummy = tracer_dummy1 +tracer_dummy2
          ; copy_VarCoords(tracer_dummy1,tracer_dummy)
          ; copy_VarAtts(tracer_dummy1,tracer_dummy)
          ; tracer_dummy@long_name = "NO + NO2 concentration"
      ; else if (tracer.eq."BC") then
        ; tracer_dummy1 = fin->CB1          ; kg/kg
        ; tracer_dummy2 = fin->CB2          ; kg/kg
        ; tracer_dummy = tracer_dummy1 +tracer_dummy2
          ; copy_VarCoords(tracer_dummy1,tracer_dummy)
          ; copy_VarAtts(tracer_dummy1,tracer_dummy)
          ; tracer_dummy@long_name = "BC concentration"
      ; else if (tracer.eq."OC") then
        ; tracer_dummy1 = fin->OC1          ; kg/kg
        ; tracer_dummy2 = fin->OC2          ; kg/kg
        ; tracer_dummy = tracer_dummy1 +tracer_dummy2
          ; copy_VarCoords(tracer_dummy1,tracer_dummy)
          ; copy_VarAtts(tracer_dummy1,tracer_dummy)
          ; tracer_dummy@long_name = "OC concentration"
      ; else if (tracer.eq."SOA") then
        ; tracer_dummy1 = fin->SOAB          ; kg/kg
        ; tracer_dummy2 = fin->SOAI          ; kg/kg
        ; tracer_dummy3 = fin->SOAM          ; kg/kg
        ; tracer_dummy4 = fin->SOAT          ; kg/kg
        ; tracer_dummy5 = fin->SOAX          ; kg/kg
        ; tracer_dummy = tracer_dummy1+tracer_dummy2+tracer_dummy3+tracer_dummy4+tracer_dummy5
          ; copy_VarCoords(tracer_dummy1,tracer_dummy)
          ; copy_VarAtts(tracer_dummy1,tracer_dummy)
          ; tracer_dummy@long_name = "SOA concentration"
      ; else if (tracer.eq."CO_var") then
        ; tracer_dummy1 = fin->CO          ; mol/mol
        ; match_str   = "cam_0001.h1"
        ; min_str     = "cam_0002.h1"
        ; max_str     = "cam_0003.h1"
        ; filemin = str_sub_str(filename,match_str,min_str)
        ; filemax = str_sub_str(filename,match_str,max_str)
        ; fin2 = addfile(filemin, "r")           ; read in
        ; fin3 = addfile(filemax, "r")           ; read in
        ; tracer_dummy_min = fin2->CO          ; mol/mol
        ; tracer_dummy_max = fin3->CO          ; mol/mol
        ; tracer_dummy = 0.5*((tracer_dummy_max - tracer_dummy_min)/tracer_dummy1)
          ; copy_VarCoords(tracer_dummy1,tracer_dummy)
          ; copy_VarAtts(tracer_dummy1,tracer_dummy)
          ; tracer_dummy@long_name = "CO variability"
          ; tracer_dummy@units = "ppb/ppb"
      ; else 
        ; tracer_dummy = fin->$tracer$         ; mol/mol or kg/kg
      ; end if
      ; end if
      ; end if
      ; end if
      ; end if
      ; end if
      date         = fin->date
      datesec      = fin->datesec
      P0           = 0.01*fin->P0          ; change Pa to mb
      Psurf        = 0.01*fin->PS
      hyam         = fin->hyam 
      hybm         = fin->hybm
      lat          = fin->lat 
      lon          = fin->lon
      ; u          = fin->U    ; winds are not in the 6-hour outputs
      ; v          = fin->V
	  
	  ; print(""+filename)
	  ; print(""+hyam)

     ; if (tracer.eq."BC".or.tracer.eq."OC".or.\
         ; tracer.eq."SO4".or.tracer.eq."SOA") then
       ; tracer_all = tracer_dummy              ; kg/kg
         ; copy_VarCoords(tracer_dummy,tracer_all)
         ; copy_VarAtts(tracer_dummy,tracer_all)
     ; else if (tracer.eq."CO_var") then
       ; tracer_all = tracer_dummy
     ; else
       ; tracer_all = tracer_dummy/1e-9         ; mol/mol -> ppb
         ; copy_VarCoords(tracer_dummy,tracer_all)
         ; copy_VarAtts(tracer_dummy,tracer_all)
         ; tracer_all@units = "ppb"
     ; end if
     ; end if
       ; tracer_all&lev@units = "hybrid_sigma_pressure"


tracer_all = read_in_species(filename,tracer)
; printVarSummary(tracer_all)
tracername = tracer_all@tracername
	   
	   dim_tracer_all = dimsizes(tracer_all)

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

		  
		; printVarSummary(pm)  
		; printVarSummary(tracer_all)
		  
		  
		  
  ;                         0          1     2     3     4     5     6     7    8      9
  traj_endpoints_lat = (/43.6150,     45,   42,   41,   40,   38,   38,   36,   33,   38.8403/)
  traj_endpoints_lon = (/-116.2023, -130, -128, -115, -128, -115, -125, -115, -122, -97.6114/)		  

  
  traj_endpoints_lon = where(traj_endpoints_lon.lt.0.0, 360.0+traj_endpoints_lon, traj_endpoints_lon)
  traj_endpoints_ind = ispan(0, -1+dimsizes(traj_endpoints_lat), 1)

  
  ; ==============================
  ; Define curtains 
  ;    Boise:  43.6150N, 116.2023W
  ;    Salina: 38.8403N, 97.6114W
  ; ==============================
  curtain_defs_lat = new((/-1+dimsizes(traj_endpoints_lat), 2/), float)
  curtain_defs_lon = new((/-1+dimsizes(traj_endpoints_lat), 2/), float)
  dist_segments = new(-1+dimsizes(traj_endpoints_lat), float)            ; distance of each segment
  flying_dist = new(-1+dimsizes(traj_endpoints_lat), float)              ; distance that the aircraft flies
  npts_segments = new(-1+dimsizes(traj_endpoints_lat), integer)
  do n = 0, -2+dimsizes(traj_endpoints_lat)
     curtain_defs_lat(n, 0) = traj_endpoints_lat(n)
	 curtain_defs_lat(n, 1) = traj_endpoints_lat(n+1)
     curtain_defs_lon(n, 0) = traj_endpoints_lon(n)
	 curtain_defs_lon(n, 1) = traj_endpoints_lon(n+1)	
	 dist_segments(n) = gc_latlon(curtain_defs_lat(n, 0), curtain_defs_lon(n, 0), curtain_defs_lat(n, 1), curtain_defs_lon(n, 1), 2, 4)
	 if (n.eq.0)
	    flying_dist(n) = dist_segments(n)
	 else
	    flying_dist(n) = flying_dist(n-1) + dist_segments(n)
	 end if
  end do
  
  npts_segments = tointeger(npts * (dist_segments / (sum(dist_segments))))
  npts_segments = where(npts_segments.le.2, 3, npts_segments)
  print(""+dist_segments+", "+flying_dist+", "+npts_segments)
  ; print(""+sum(dist_segments))
  ; print("actual total number of points: "+sum(npts_segments))
  
	
	dim_curtain_defs = dimsizes(curtain_defs_lat)
	
	curtains = new((/npts_segments(0), dim_tracer_all(0), dim_tracer_all(1)/), float)
	curtains!0 = "nseg"
	curtains!1 = "time"
	curtains!2 = "lev"	

	curtains_pm = new((/npts_segments(0), dim_tracer_all(0), dim_tracer_all(1)/), float)
	curtains_pm!0 = "nseg"
	curtains_pm!1 = "time"
	curtains_pm!2 = "lev"	
	
	traj_lat = new(npts_segments(0), float)
	traj_lon = new(npts_segments(0), float)
	
	if (dimsizes(date).eq.1)
	   ; ============================================================================
  	   ; Do something here... I assume curtains will not have this time dimension...?
	   ; ============================================================================
	else
	   ; curtains = transect
	   do n = 0, -1+dim_curtain_defs(0)
		  dist = gc_latlon(curtain_defs_lat(n,0),curtain_defs_lon(n,0),curtain_defs_lat(n,1),curtain_defs_lon(n,1),npts_segments(n),2)
		  transect = linint2_points(tracer_all&lon,tracer_all&lat,tracer_all,True,dist@gclon,dist@gclat,2)
		  transect!0 = "time"
	      transect!1 = "lev"
	      transect!2 = "nseg"
		  transect_SwapDim = transect(nseg|:, time|:, lev|:)
          transect_pm = linint2_points(pm&lon,pm&lat,pm,True,dist@gclon,dist@gclat,2)
		  transect_pm!0 = "time"
	      transect_pm!1 = "lev"
	      transect_pm!2 = "nseg"
		  transect_pm_SwapDim = transect_pm(nseg|:, time|:, lev|:)
		  ; print("-----------")
		  ; print(""+dist@gclon+", "+dist@gclat)
		  if (n.eq.0)
		     traj_lat = dist@gclat
			 traj_lon = dist@gclon
		  else
		     traj_lat := array_append_record(traj_lat, dist@gclat, 0)
			 traj_lon := array_append_record(traj_lon, dist@gclon, 0)
		  end if
		  delete(transect)
		  delete(transect_pm)
	      delete(dist)
	      curtains_NewSeg = rm_single_dims(transect_SwapDim)
		  curtains_pm_NewSeg = rm_single_dims(transect_pm_SwapDim)
		  delete(transect_SwapDim)
		  delete(transect_pm_SwapDim)
		  if (n.eq.0)
		     curtains = curtains_NewSeg
			 curtains_pm = curtains_pm_NewSeg
		  else
		     curtains := array_append_record(curtains, curtains_NewSeg, 0)
			 curtains_pm := array_append_record(curtains_pm, curtains_pm_NewSeg, 0)
		  end if
		  delete(curtains_NewSeg)
		  delete(curtains_pm_NewSeg)
	      ; print("--- curtain ind: "+n)
	      ; printMinMax(transect(n,:,:,:), 0)
	   end do
	   ; copy_VarAtts(tracer_all,transect)
	   ; transect&lev    = tracer_all&lev
	   curtains&lev    = tracer_all&lev
	   curtains&nseg   = fspan(0, -1+sum(npts_segments), sum(npts_segments))
	   curtains_pm&lev    = tracer_all&lev
	   curtains_pm&nseg    = fspan(0, -1+sum(npts_segments), sum(npts_segments))
	end if
	
	
	
	; printVarSummary(curtains)
	; printVarSummary(curtains_pm)
	


;--------------
; plot curtains
;--------------
; loop over dates in file
do j= 0,dimsizes(date)-1
  plot_name = pltname+"_"+date(j)+"_"+sprintf("%02g",datesec(j)/3600)
   plttype@wkWidth = 2500
   plttype@wkHeight = 2500
  wksII = gsn_open_wks(plttype,plot_name)        
  gsn_define_colormap(wksII,"GMT_wysiwygcont_rrb")

  
    plots = new(2, graphic)
	TickMarkLabelFontHeight = 0.011

  
 ;-----------------------
 ; Set resources for plotting
 ;-----------------------
  cres = True
   ; cres@gsnMaximize         = True  
   cres@gsnDraw		        = False	       ; don't draw it yet
   cres@gsnFrame            = False            ; don't advance frame
  
   cres@cnFillOn             = True            ; turn on color fill
   cres@cnLinesOn            = False           ; turn lines on/off         ; True is default
   cres@cnLineLabelsOn       = False           ; turn line labels on/off   ; True is default
   cres@cnLevelSelectionMode ="ExplicitLevels"
   cres@cnLevels             = contour_levels

   cres@lbLabelBarOn         = False
   cres@cnInfoLabelOn        = False    ; no contour labels

   cres@gsnCenterString = " "	
   cres@gsnLeftString = tracername + " curtain"
   cres@gsnRightString = " "

   cres@vpWidthF  = 0.4
   cres@vpHeightF = 0.2
   cres@vpYF      = 0.2

   tres = True
     copy_VarAtts(cres, tres)

   cres@tmXTOn               = False
   cres@tiMainOffsetYF       =-0.01
   cres@tmYUseLeft           = False               ; disassociate  YR tick marks with YL tick marks
   cres@tmYRLabelsOn         = True                ; turn on the YR tick mark labels
   cres@tmYRMode             = "Explicit"          ; turn off height labels
   cres@tmYRLabelFontHeightF = TickMarkLabelFontHeight
     hnice = (/1, 2, 3, 4, 5, 6, 8, 10/) ; fspan(2.,10.,5)                       ; Set range of "nice" height values.
     hnice_FreedomUnitOhBoy = hnice *1000.0*3.28084
	 pressure = tracer_all&lev
     pnice = ftcurv(height(::-1),pressure(::-1),hnice) ; Calculate "nice" pressure values.
     cres@tmYRValues    = pnice                    ; At each "nice" pressure value, 
     cres@tmYRLabels    = hnice + " km (" + sprintf("%5.0f", floor(hnice_FreedomUnitOhBoy)) +" ft)"
	; ------------------------- 
    ; add in right Y-axis label
    ; -------------------------
	txres = True
    txres@txFontHeightF := 0.018   ; Label right Y axis.
    txres@txAngleF      := 90.
    ; gsn_text_ndc(wksII,"Height (km)",0.82, 0.44,txres)

   ; cres@tiYAxisString        = "Altitude (hPa)" 
   cres@trYMinF              = 200
   cres@trYMaxF              = max(tracer_all&lev)
   cres@gsnYAxisIrregular2Log = True ;False
   cres@trYReverse           = True                ; reverse y-axis
   cres@tmYLMode             = "Explicit"          ; Define own tick mark labels.
   cres@tmYLValues           = (/925,850,700,500,300,200/)
   cres@tmYLLabels           = cres@tmYLValues + " hPa";(/925,850,700,500,300,200/)
   cres@tmXBLabelFontHeightF = TickMarkLabelFontHeight
   cres@tmYLLabelFontHeightF = cres@tmXBLabelFontHeightF 
   ; cres@tmYLMinorValues      = (/990, 980, 970, 960, 950, 900, 800, 600, 400/)
   cres@tmYLMinorValues      = (/990, 900, 800, 600, 400, 250/)

    ;-------------------
    ; Transect locations
    ;-------------------
    ; tres@tiMainString = "Transect locations (surface)"
	tres@gsnLeftString = "Surface " + tracername + " & transect locations"
    tres@mpOutlineOn         = False                     ; will draw highres map later
	; tres@mpProjection  ="LambertConformal"
	; tres@gsnMaskLambertConformal = True
    ; tres@mpLimitMode         ="LatLon"
      tres@mpMinLatF         = bottomboundary
      tres@mpMaxLatF         = topboundary
      tres@mpMinLonF         = leftboundary
      tres@mpMaxLonF         = rightboundary
	  
    tres@gsnMajorLatSpacing  = 10
    tres@gsnMajorLonSpacing  = 10
    tres@tmXBLabelFontHeightF = TickMarkLabelFontHeight
    tres@tmYLLabelFontHeightF = tres@tmXBLabelFontHeightF
	
	
	; tres@vpYF      = 0.9
	tres@vpHeightF = 0.4
	tres@vpWidthF  = 0.4

     plots(1) = gsn_csm_contour_map(wksII,tracer_all(j,dimsizes(tracer_all&lev)-1,:,:),tres)  ; plot temp contours 
	 
	 
	 
	 ; ---------------	 
	 ; Add a small map
	 ; ---------------
	 smallmapres = True
     smallmapres@gsnDraw          =  False
     smallmapres@gsnFrame         =  False
	 smallmapres@mpProjection     = "Satellite" ; choose map projection
     smallmapres@mpCenterLonF     = (rightboundary+leftboundary)/2.0
     smallmapres@mpCenterLatF     = (bottomboundary+topboundary)/2.0
     smallmapres@mpSatelliteDistF = 3.0         ; choose satellite view
	 smallmapres@mpPerimOn        = False
     smallmapres@gsnLeftString         =  ""
     smallmapres@gsnRightString        =  ""
     smallmapres@vpWidthF              =  0.08
     smallmapres@vpHeightF             =  0.08
     smallmapres@mpLandFillColor        = "Gray75"                ;-- land fill color
     smallmapres@mpOceanFillColor       = "Navy"                 ;-- ocean fill color
     smallmapres@mpInlandWaterFillColor = "Navy"                ;-- inland water color 
     smallmapres@tmXBOn                 =  False
     smallmapres@tmXTOn                 =  False
     smallmapres@tmYLOn                 =  False
     smallmapres@tmYROn                 =  False
     smallmapres@mpMinLatF              = bottomboundary
     smallmapres@mpMaxLatF              = topboundary
     smallmapres@mpMinLonF              = leftboundary
     smallmapres@mpMaxLonF              = rightboundary
	 plot_smallmap = gsn_csm_map(wksII, smallmapres)
	 ; -------------------------------------
	 ; Add the domain box onto the small box
	 ; -------------------------------------
	 domainboxres = True
	 domainboxres@gsLineColor = "red3" ;"gold"
	 domainboxres@gsLineThicknessF = 8.0
	 ; domainboxres@gsFillColor      = "white"
	 ; domainboxres@gsFillOpacityF   = 0.0
	 ; domain_box = gsn_add_polygon(wksII, plot_smallmap, \
	                             ; (/tres@mpMinLonF, tres@mpMaxLonF, tres@mpMaxLonF, tres@mpMinLonF, tres@mpMinLonF/), \
	                             ; (/tres@mpMinLatF, tres@mpMinLatF, tres@mpMaxLatF, tres@mpMaxLatF, tres@mpMinLatF/), \
								 ; domainboxres)
	 domain_box = gsn_add_polyline(wksII, plot_smallmap, \
	                             (/tres@mpMinLonF, tres@mpMaxLonF, tres@mpMaxLonF, tres@mpMinLonF, tres@mpMinLonF/), \
	                             (/tres@mpMinLatF, tres@mpMinLatF, tres@mpMaxLatF, tres@mpMaxLatF, tres@mpMinLatF/), \
								 domainboxres)
	 ; -------------------------------------	  
	 ; Append the small map onto the big map
	 ; -------------------------------------
	 amres                     =  True
     amres@amJust              = "BottomLeft"                ;-- labelbar justification
     amres@amParallelPosF      = -0.5                     ;-- move labelbar to the right of plot
     amres@amOrthogonalPosF    = 0.5                     ;-- move labelbar to the top of plot
	 annoid = gsn_add_annotation(plots(1),plot_smallmap,amres)
					
 ;----------------------------
 ; Set up other transect plots
 ;----------------------------
	cres@tmXBMode          = "Explicit"
	cres@tiMainFontHeightF = 0.03

   plres                  = True                      ; polyline mods desired
     plres@gsLineColor      = "black" ;"grey"                     ; color of lines
     plres@gsLineThicknessF = 10.0                       ; thickness of lines
	 

	 
	   ; -------------------------------
	   ; Create individual curtain plots
	   ; -------------------------------
	   curtain_x_max_ind = (npts)
	   ; cres@tiMainString     = "Curtain "
	   ; dist_temp = gc_latlon(curtain_defs_lat(n,0),curtain_defs_lon(n,0),curtain_defs_lat(n,1),curtain_defs_lon(n,1),npts,2)
	   cres@tmXBValues       := toint(fspan(0,curtain_x_max_ind,n_tickmarks_XB))
       cres@tmXBLabels       := new(n_tickmarks_XB, string)
	   do k=0,-1+dimsizes(cres@tmXBLabels)
		  ; --------------
	      ; Add tick marks
		  ; --------------
	      if (traj_lon(k*tointeger(floor(npts/n_tickmarks_XB))).gt.180.0)
	         traj_x_label_lon = sprintf("%5.1fW", 360.0 - traj_lon(k*tointeger(floor(npts/n_tickmarks_XB))))
		  else
		     traj_x_label_lon = sprintf("%5.1fE", traj_lon(k*tointeger(floor(npts/n_tickmarks_XB))))
		  end if
		  if (traj_lat(k*tointeger(floor(npts/n_tickmarks_XB))).gt.0.0)
		     traj_x_label_lat = sprintf("%5.1fN", traj_lat(k*tointeger(floor(npts/n_tickmarks_XB))))
		  else
		     traj_x_label_lat = sprintf("%5.1fS", -1*traj_lat(k*tointeger(floor(npts/n_tickmarks_XB))))
		  end if
		  ; cres@tmXBLabels(k) = sprintf("%5.1f", traj_lon(k*tointeger(floor(npts/n_tickmarks_XB))))+"~C~"+sprintf("%5.1f", traj_lat(k*tointeger(floor(npts/n_tickmarks_XB))))
		  cres@tmXBLabels(k) = traj_x_label_lon + "~C~" + traj_x_label_lat 
       end do
	   curtains_swap = curtains(:, j, :)
	   curtains_pm_swap = curtains_pm(:, j, :)	
       ; ------------------------------------------------------------------
       ; Now map from the original lev (hybrid) to actual pressure altitude
       ; ------------------------------------------------------------------	   
	   curtains_swap_regrid = linint1_Wrap(curtains_pm_swap, curtains_swap, False, curtains_swap&lev, 0)
	   curtains_swap_regrid := curtains_swap_regrid(lev|:, nseg|:)	   
	   curtains_swap := curtains_swap(lev|:, nseg|:)
	   curtains_pm_swap := curtains_pm_swap(lev|:, nseg|:)
	   ; printVarSummary(curtains_swap)

	   ; curtains_swap_regrid = curtains_swap
	   ; do k = 0, -1+sum(npts_segments)
	      ; ; curtains_swap_regrid(:, k) = linint1(curtains_swap&lev, curtains_swap(:, k), False, curtains_pm_swap(:, k), 0)
	      ; curtains_swap_regrid(:, k) = linint1(curtains_pm_swap(:, k), curtains_swap(:, k), False, curtains_swap&lev, 0)
	   ; end do
	   
	   ; plots(0) = gsn_csm_contour(wksII,curtains_swap,cres)
	   plots(0) = gsn_csm_contour(wksII,curtains_swap_regrid,cres)
	   delete(curtains_swap)
	   delete(curtains_pm_swap)
	   delete(curtains_swap_regrid)
	   
	   


     traj_endpoints_txres               = True
	 traj_endpoints_txres@txFontHeightF = 0.007
     traj_endpoints_txres@amJust        = "TopRight"
	 traj_endpoints_txres@txFontColor   = "black"
	 traj_endpoints_txres@txAngleF      = -90.0
	 SegLineRes                  = True
	 SegLineRes@gsLineThicknessF = 4
	 
	 if(dim_curtain_defs(0).ne.1)
   	 plot_seg_seplines = new(-1+dim_curtain_defs(0), graphic)
	 plot_seg_endpoints = new(-1+dim_curtain_defs(0), graphic)
	 ; -------------------------------------------------
	 ; Add vertical lines to separate different segments
	 ; -------------------------------------------------
	 do n = 0, -1-1+dim_curtain_defs(0)
	    sep_line_x = curtain_x_max_ind * (flying_dist(n) / sum(dist_segments))
		plot_seg_seplines(n) = gsn_add_polyline(wksII, plots(0), (/sep_line_x, sep_line_x/), (/min(cres@tmYLValues), 1000/), SegLineRes)
	 end do
	 end if
	 do n = 0, dim_curtain_defs(0)
		if (traj_endpoints_lon(n).ge.180.0)
		   endpoints_lon_label = sprintf("%5.1fW", 360.0 - traj_endpoints_lon(n))
		else
		   endpoints_lon_label = sprintf("%5.1fE", traj_endpoints_lon(n))
		end if
		if (traj_endpoints_lat(n).ge.0.0)
		   endpoints_lat_label = sprintf("%5.1fN", traj_endpoints_lat(n))
		else
		   endpoints_lat_label = sprintf("%5.1fS", -1.0*traj_endpoints_lat(n))
		end if	 
		if (n.eq.0)
		   traj_endpoints_txres@amJust        = "TopLeft"
		   sep_line_x = 0.0
		else
		   traj_endpoints_txres@amJust        = "TopRight"
		   sep_line_x = min((/curtain_x_max_ind * (flying_dist(n-1) / sum(dist_segments)), sum(npts_segments)*0.99/))
		end if
		add_traj_endpoints = gsn_add_text(wksII, plots(0), tostring(n)+": "+endpoints_lon_label+", "+endpoints_lat_label, sep_line_x, min(cres@tmYLValues)*1.05, traj_endpoints_txres)
	 end do
	   
	   
	   ; -----------------------------------
	   ; create curtain transects on the map
	   ; -----------------------------------
	   trajectory = gsn_add_polyline(wksII,plots(1),traj_lon,traj_lat,plres)
	   SegLineEndpointsRes = True
	   SegLineEndpointsRes@gsMarkerIndex = 16
	   SegLineEndpointsRes@gsMarkerSizeF = 13
	   SegLineEndpointsRes@gsMarkerColor = "black"
	   trajectory_endpoints = gsn_add_polymarker(wksII,plots(1),traj_endpoints_lon,traj_endpoints_lat,SegLineEndpointsRes)

	    traj_endpoints_txres@txAngleF      = 0.0
        traj_endpoints_txres@txFontHeightF = 0.007
        traj_endpoints_txres@txFont        = "helvetica-bold"
		traj_endpoints_txres@txFontColor   = "white"
		traj_endpoints_txres@amJust        = "CenterCenter"
        add_traj_endpoints_map = gsn_add_text(wksII, plots(1), tostring(traj_endpoints_ind),traj_endpoints_lon, traj_endpoints_lat, traj_endpoints_txres)
	   
	   



     ;----------------------------------------
     ; add countries and counties
     ;----------------------------------------
      ; country_shp_name    = "/glade/u/home/pfister/KORUS/KOR_adm1.shp"
	  country_shp_name = "/home/siyuan/Forecast_FIREX/shape_files/US_census_state/tl_2018_us_state.shp"
      lnres                  = True
      lnres@gsLineColor      = "gray24"
      lnres@gsLineThicknessF = .9
      country_id = gsn_add_shapefile_polylines(wksII,plots(1),country_shp_name,lnres)

      ; world_shp_name    = "/glade/u/home/pfister/KORUS/countries.shp"
	  ; world_shp_name    = "/home/siyuan/Forecast_FIREX/shape_files/GSHHS_NOAA/GSHHS_shp/i/GSHHS_i_L2.shp"
	  world_shp_name    = "/home/siyuan/Forecast_FIREX/shape_files/GSHHS_NOAA/GSHHS_shp/i/GSHHS_i_L1.shp"
      lnres@gsLineThicknessF = 1.1
      world_id = gsn_add_shapefile_polylines(wksII,plots(1),world_shp_name,lnres)


   ;----------------------------------------
   ; Add site info:
   ;        Boise:  43.6150N, 116.2023W
   ;        Salina: 38.8403N, 97.6114W
   ;----------------------------------------
   AddSite_Name = (/"Boise ID", "Salina KS"/)
   AddSite_lat = (/43.6150, 38.8403/)
   AddSite_lon = (/-116.2023, -97.6114/)
   
   polyres = True                        ; poly marker mods desired     
    polyres@gsMarkerIndex = 7            ; choose circle as polymarker
    polyres@gsMarkerSizeF = 8.          ; select size to avoid streaking
    polyres@gsMarkerColor = "black" ;"red"        ; set polymarker color
    polyres@tfPolyDrawOrder = "PostDraw"
    polyres@gsMarkerThicknessF = 8
    
	SiteNamesRes = True
	SiteNamesRes@amJust = "TopRight"
	SiteNamesRes@txFontHeightF = 0.007

    transect_plot_sites = gsn_add_polymarker(wksII, plots(1), AddSite_lon, AddSite_lat, polyres)
	; AddSiteNames = gsn_add_text(wksII, plots(1), AddSite_Name, AddSite_lon, AddSite_lat, SiteNamesRes)

	
	 stampres = True
	 stampres@txFontHeightF = 0.012
	 stampres@amJust = "TopRight"
     add_stamp = gsn_add_text(wksII, plots(1), "NCAR", tres@mpMaxLonF, tres@mpMaxLatF, stampres)
	
	
  ; ------------------
  ; Now make the panel
  ; ------------------
  panel_res                       = True
  panel_res@txString              = "FIREX-AQ CAM-chem forecast " + date(j)+\
                                    " "+sprintf("%02g",datesec(j)/3600) +"Z, "+\
                                    sprintf("%02g",mod((datesec(j)/3600),24)) +"UTC"
  panel_res@gsnPanelYWhiteSpacePercent  = 0 
;  panel_res@txPosYF               = 0.98
;  panel_res@txPosXF               = 0.54
;   panel_res@gsnPanelScalePlotIndex = 1
  
;  panel_res@lbLabelFontHeightF =0.01
  ; panel_res@gsnPanelYF = (/0.89,0.89,0.61,0.61,0.32,0.32/)      ; Adjust bottommost plots.
  panel_res@gsnPanelTop = 0.95
  panel_res@gsnPanelBottom = 0.015
  
  panel_res@gsnPanelLabelBar   = True
  panel_res@pmLabelBarOrthogonalPosF = 0 ;0.008 
  panel_res@lbLabelFontHeightF = TickMarkLabelFontHeight * 1.2
  panel_res@lbTitleOn          = True
  panel_res@lbTitleString      = tracername + " ("+tracer_all@units+")"
  panel_res@lbTitleFontHeightF = TickMarkLabelFontHeight * 1.5
  panel_res@lbTitlePosition    = "Bottom"
  panel_res@pmLabelBarWidthF   = 0.5
  panel_res@pmLabelBarHeightF  = 0.06
  panel_res@lbBoxEndCapStyle   = "TriangleBothEnds"
   ;panel_res@gsnPanelDebug =True
  gsn_panel(wksII,plots(::-1),(/2,1/),panel_res)
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

