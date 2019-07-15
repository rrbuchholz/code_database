;=======================================================;
;  curtain_plot.ncl
;=======================================================;
;   - curtain procedures generalized (previously hard-wired)
;   - now the curtains can be in any directions
;     (previously t)
;                             Siyuan Wang 22 June 2019 
; ------------------------------------------------------
; Concepts illustrated:
;   - developed for the FIREX 2019 campaign
;     from the KORUS 2016 code base
;   - open model output
;   - read in species
;   - plot 2D field over zoomed region
;   - overplot flight-leg paths
;   - create curtain plots for each flight leg
;
;   Files needed:
;         -model output in netCDF format
;
;   Called in as:
;
;         curtain_plot(file, tracer, station(s) lat, station(s) lon,\
;                          station(s) name(s)) 
;
;                                  RRB June 17, 2019
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
  ; model files
  ; -------------------------------
  filename = fileIN

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
    pltname      = "WACCM_"+tracer+"_forecast_curtain"
    outfolder = "forecast_plots/"
;--------------------------------------------
; interpolate to unusual paths #3 and #4
;--------------------------------------------

  npts     =   40 ;50                    ; number of points in resulting transect
  n_tickmarks_XB = 5

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
  ; model load
  ; -------------------------------
    fin = addfile(filename, "r")           ; read in

     lat_bound_0 = bottomboundary-10
     lat_bound_1 = topboundary+10
     if (leftboundary.lt.0) then
       lon_bound_0 = 360 + leftboundary - 10
     else
       lon_bound_0 = leftboundary - 10
     end if
     if (rightboundary.lt.0) then
       lon_bound_1 = 360 + rightboundary + 10
     else
       lon_bound_1 = rightboundary + 10
     end if

     lev         = fin->lev
     lev_limit_0 = minind(abs(lev - max((/min(lev), 50.0/))))

     tracer_all = read_in_species(filename, tracer, lat_bound_0, lat_bound_1, lon_bound_0, lon_bound_1, lev_limit_0)
     tracername = tracer_all@tracername

      date         = fin->date
      datesec      = fin->datesec
	  P0           = 0.01*fin->P0          ; change Pa to mb
      Psurf        = 0.01*fin->PS(:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})
        Psurf!0         = "time"
        Psurf!1         = "lat"
        Psurf!2         = "lon"
        Psurf&time      = tracer_all&time
        Psurf&lat       = tracer_all&lat
        Psurf&lon       = tracer_all&lon

      hyam         = fin->hyam(lev_limit_0:)
      hybm         = fin->hybm(lev_limit_0:)

      u            = fin->U(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})
      v            = fin->V(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})
      wsbd         = sqrt(u^2 + v^2)

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
      pm&lat       = tracer_all&lat
      pm&lon       = tracer_all&lon
      pm@long_name = "mid-level pressures"
      pm@units     = "hPa"

    ; average the pressure over all 5 days
    pressure_array = dim_avg_n_Wrap(pm,0)

    ; pressure to height
          height = ((-log(tracer_all&lev/1016))*H)/1000
          height@units = "km"


  ; ==============================
  ; Define curtains 
  ;    Boise:  43.6150N, 116.2023W
  ;    Salina: 38.8403N, 97.6114W
  ; ==============================
    curtain_defs_lon = (/(/-116.2023,-116.2023/),\	; C1
                       (/-125.0,-105.0/),\              ; C2
                       (/-97.6114,-97.6114/),\          ; C3
                       (/-110, -90/),\                  ; C4
                       (/-130, -90/)/)                  ; C5
    curtain_defs_lat = (/(/50, 35/),\                   ; C1
                       (/43.6, 43.6/),\                 ; C2
                       (/45, 30/),\                     ; C3
                       (/38.8403,38.8403/),\            ; C4
                       (/44.5904, 36.8855/)/)           ; C5
	curtain_defs_lon = where(curtain_defs_lon.lt.0.0, 360.0+curtain_defs_lon, curtain_defs_lon)
	  
	dim_curtain_defs = dimsizes(curtain_defs_lat)
	
	transect = new((/dim_curtain_defs(0), dim_tracer_all(0), dim_tracer_all(1), npts/), float)
	transect!0 = "curtain_index"
	transect!1 = "time"
	transect!2 = "lev"
	transect!3 = "npts"

	;transect_pm = new((/dim_curtain_defs(0), dim_tracer_all(0), dim_tracer_all(1), npts/), float)
	;transect_pm!0 = "curtain_index"
	;transect_pm!1 = "time"
	;transect_pm!2 = "lev"
	;transect_pm!3 = "npts"

        transect_pm = transect
	  transect_u = transect
	  transect_v = transect
	
   ;----------------------------------------
   ; Add site info:
   ;        Boise:  43.6150N, 116.2023W
   ;        Salina: 38.8403N, 97.6114W
   ;----------------------------------------
   AddSite_Name = (/"Boise ID", "Salina KS"/)
   AddSite_lat = (/43.6150, 38.8403/)
   AddSite_lon = (/-116.2023, -97.6114/)
   ; -----------------------------------------------------------------
   ; Now determine if the sites are on any of the transect (great arc)
   ; -----------------------------------------------------------------
   Site_on_Great_Arc = new((/2, dim_curtain_defs(0)/), float)
   do i = 0, -1+dim_curtain_defs(0)
      do j = 0, -1+dimsizes(AddSite_Name)
         Site_on_Great_Arc(j,i) = gc_pnt2gc(AddSite_lat(j), AddSite_lon(j), curtain_defs_lat(i,:), curtain_defs_lon(i,:))
      end do
   end do
   ; print(""+Site_on_Great_Arc)
	
	
	
	if (dimsizes(date).eq.1)
	   ; ============================================================================
  	   ; Do something here... I assume curtains will not have this time dimension...?
	   ; ============================================================================
	else
	   curtains = transect
	   curtains_pm = transect_pm
	   curtains_u = transect_u
	   curtains_v = transect_v
	   do n = 0, -1+dim_curtain_defs(0)
		  dist_temp = gc_latlon(curtain_defs_lat(n,0),curtain_defs_lon(n,0),curtain_defs_lat(n,1),curtain_defs_lon(n,1),npts,2)
		  transect(n,:,:,:) = linint2_points(tracer_all&lon,tracer_all&lat,tracer_all,True,dist_temp@gclon,dist_temp@gclat,2)
		  transect_pm(n,:,:,:) = linint2_points(pm&lon,pm&lat,pm,True,dist_temp@gclon,dist_temp@gclat,2)
		  transect_u(n,:,:,:) = linint2_points(u&lon,u&lat,u,True,dist_temp@gclon,dist_temp@gclat,2)
		  transect_v(n,:,:,:) = linint2_points(v&lon,v&lat,v,True,dist_temp@gclon,dist_temp@gclat,2)
	      delete(dist_temp)
	      curtains(n,:,:,:) = rm_single_dims(transect(n,:,:,:))
		  curtains_pm(n,:,:,:) = rm_single_dims(transect_pm(n,:,:,:))
		  curtains_u(n,:,:,:) = rm_single_dims(transect_u(n,:,:,:))
		  curtains_v(n,:,:,:) = rm_single_dims(transect_v(n,:,:,:))
	      ; print("--- curtain ind: "+n)
	      ; printMinMax(transect(n,:,:,:), 0)
	   end do
	   copy_VarAtts(tracer_all,transect)
	   transect&lev    = tracer_all&lev
	   curtains&lev    = tracer_all&lev
	   curtains_pm&lev = tracer_all&lev
	   curtains_u&lev  = tracer_all&lev
	   curtains_v&lev  = tracer_all&lev
	end if
	
	; printVarSummary(curtains)
	; printVarSummary(curtains_pm)

	curtains_swap = curtains(curtain_index|:, time|:, npts|:, lev|:)
	curtains_pm_swap = curtains_pm(curtain_index|:, time|:, npts|:, lev|:)
	curtains_u_swap = curtains_u(curtain_index|:, time|:, npts|:, lev|:)
	curtains_v_swap = curtains_v(curtain_index|:, time|:, npts|:, lev|:)
	; printVarSummary(curtains_pm_swap)
	; printVarSummary(curtains_u_swap)
	
	curtains_regrid = linint1_Wrap(curtains_pm_swap, curtains_swap, False, lev, 0)
	curtains_regrid := curtains_regrid(curtain_index|:, time|:,  lev|:, npts|:)

	curtains_u_regrid = linint1_Wrap(curtains_pm_swap, curtains_u_swap, False, lev, 0)
	curtains_u_regrid := curtains_u_regrid(curtain_index|:, time|:,  lev|:, npts|:)
	
	curtains_v_regrid = linint1_Wrap(curtains_pm_swap, curtains_v_swap, False, lev, 0)
	curtains_v_regrid := curtains_v_regrid(curtain_index|:, time|:,  lev|:, npts|:)
	
	curtains_wspd_regrid = curtains_u_regrid
	curtains_wspd_regrid = sqrt(curtains_u_regrid^2 + curtains_v_regrid^2)

        delete(curtains_swap)
        delete(curtains_pm_swap)
        delete(curtains)
        delete(curtains_pm)
        delete(curtains_u)
        delete(curtains_v)
        delete(curtains_u_swap)
        delete(curtains_v_swap)
	
        ; printVarSummary(curtains_u_regrid)

;--------------------------------------------
; plot curtains
;--------------------------------------------
; loop over dates in file
do j= 0,dimsizes(date)-1
  ; plot_name = pltname+"_"+date(j)+"_"+sprintf("%02g",datesec(j)/3600)+"_old"
  plot_name = outfolder + pltname+"_"+date(j)+"_"+sprintf("%02g",datesec(j)/3600)
   plttype@wkWidth = 2500
   plttype@wkHeight = 2500
  wksII = gsn_open_wks(plttype,plot_name)        
  gsn_define_colormap(wksII,"GMT_wysiwygcont_rrb")

  
    plots = new((/6/), graphic)
    plots_windbarb = new((/5/), graphic)
  
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

   cres@vpWidthF             = 0.65
   cres@vpHeightF            = 0.53

   tres = True
     copy_VarAtts(cres, tres)

   cres@tmXTOn               = False
   cres@tiMainOffsetYF       =-0.01
   cres@tmYUseLeft           = False               ; disassociate  YR tick marks with YL tick marks
   cres@tmYRLabelsOn         = True                ; turn on the YR tick mark labels
   cres@tmYRMode             = "Explicit"          ; turn off height labels
     hnice = (/1, 5, 10, 15, 20, 25, 30, 35, 40/)
     pressure = tracer_all&lev
     pnice = ftcurv(height(::-1),pressure(::-1),hnice/3.28084) ; Calculate "nice" pressure values.		<- convert to ft!!!
     cres@tmYRValues    = pnice                    ; At each "nice" pressure value, 
     cres@tmYRLabels    = hnice                    ; put a "height" value label.

   
   cres@trYMaxF              = max(tracer_all&lev)
   cres@trYMinF              = 200
   cres@trYReverse           = True                ; reverse y-axis
   cres@tmYLMode             = "Explicit"          ; Define own tick mark labels.
   cres@tmYLValues           = (/925,850,700,500,300,200/)
   cres@tmYLLabels           = (/925,850,700,500,300,200/)
   cres@gsnYAxisIrregular2Log = True ;False

    ;-------------------
    ; Transect locations
    ;-------------------
    tres@tiMainString = "Transect locations (surface)"
    tres@mpOutlineOn         = False                     ; will draw highres map later
	; tres@mpProjection  ="LambertConformal"
	; tres@gsnMaskLambertConformal = True
    ; tres@mpLimitMode         ="LatLon"
      tres@mpMinLatF         = bottomboundary
      tres@mpMaxLatF         = topboundary
      tres@mpMinLonF         = leftboundary
      tres@mpMaxLonF         = rightboundary
    ; tres@gsnMajorLatSpacing  =2
    ; tres@gsnMajorLonSpacing  =2
    tres@vpHeightF            = 0.1
    tres@tmXBLabelFontHeightF = 0.0036
    tres@tmYLLabelFontHeightF = tres@tmXBLabelFontHeightF

     ; add map outlines
     tres@mpDataSetName         = "Earth..4"   ; This new database contains
     tres@mpDataBaseVersion     = "MediumRes"        ; better map outlines
     tres@mpOutlineOn           = True         ; Turn on map outlines
     tres@mpOutlineBoundarySets = "GeophysicalAndUSStates"
     tres@mpGeophysicalLineThicknessF = 4
     tres@mpUSStateLineThicknessF = 2
     tres@mpNationalLineThicknessF = 2

      tres@gsnAddCyclic        = False
     plots(5) = gsn_csm_contour_map(wksII,tracer_all(j,dimsizes(tracer_all&lev)-1,:,:),tres)  ; plot temp contours 

       ; add surface wind vectors
       surfwind_res = True
         surfwind_res@gsnDraw        = False          ; do not draw
         surfwind_res@gsnFrame       = False          ; do not advance the frame
         surfwind_res@vcGlyphStyle   = "CurlyVector" 
         surfwind_res@vcMapDirection = False	      ; needed to disassociate the map from the vectors
         surfwind_res@gsnAddCyclic   = False          ; data is not cyclic
         surfwind_res@vcMinDistanceF = 0.015   
         surfwind_res@vcMonoLineArrowColor = True
         surfwind_res@vcLineArrowColor = "grey20"
         surfwind_res@vcRefAnnoOn    = True     
         surfwind_res@vcRefAnnoOrthogonalPosF = 0.02 
         surfwind_res@vcRefLengthF   = 0.05 ;0.045    ; define length of vec ref
         surfwind_res@vcRefMagnitudeF = 10
         surfwind_res@vcRefAnnoString1On = True
         surfwind_res@vcRefAnnoOrientation = "horizontal"
         surfwind_res@vcRefAnnoString1   = "$VMG$" +" m/s"
	   
         surfwind_res@lbLabelBarOn    = False
         surfwind_res@vcLevelSelectionMode = "ExplicitLevels" ; will explicitly set the levels
         surfwind_res@vcWindBarbLineThicknessF= 2      ; set the wind barb thickness
         surfwind_res@vcLevels        = ispan(0,20,5)  ; set the levels 

         plot_surfwind = gsn_csm_vector_scalar(wksII, u(j, dimsizes(tracer_all&lev)-1, :, :), v(j, dimsizes(tracer_all&lev)-1, :, :), wsbd(j, dimsizes(tracer_all&lev)-1, :, :), surfwind_res)
	 overlay(plots(5), plot_surfwind)

   ;----------------------
   ; create curtain labels
   ;----------------------
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
    names_array = (/"C1", "C2", "C3",\
                    "C4", "C5"/)
    cur = new((/dimsizes(curtain_defs_lon(:,0))/), graphic)
					
					
 ;----------------------------
 ; Set up other transect plots
 ;----------------------------
	cres@tmXBMode          = "Explicit"
	cres@tiMainFontHeightF = 0.03

   plres                  = True                      ; polyline mods desired
     plres@gsLineColor      = "black" ;"grey"                     ; color of lines
     plres@gsLineThicknessF = 10.0                       ; thickness of lines
	 
	 
	site_lot_on_cutrain = new(dimsizes(Site_on_Great_Arc), graphic)

	 
	do n = 0, -1+dim_curtain_defs(0)
	   ; -------------------------------
	   ; Create individual curtain plots
	   ; -------------------------------
	   curtain_x_max_ind = (npts)
	   cres@tiMainString     = "Curtain "+tostring(n+1)+" (C"+tostring(n+1)+")"
	   dist_temp = gc_latlon(curtain_defs_lat(n,0),curtain_defs_lon(n,0),curtain_defs_lat(n,1),curtain_defs_lon(n,1),npts,2)
       cres@tmXBValues       := toint(fspan(0,curtain_x_max_ind,n_tickmarks_XB))
       cres@tmXBLabels       := new(n_tickmarks_XB, string)
       do k=0,-1+dimsizes(cres@tmXBLabels)
		  ; cres@tmXBLabels(k) = sprintf("%5.1f", dist_temp@gclon(k*tointeger(floor(npts/n_tickmarks_XB))))+"~C~"+sprintf("%5.1f", dist_temp@gclat(k*tointeger(floor(npts/n_tickmarks_XB))))
          if (dist_temp@gclon(k*tointeger(floor(npts/n_tickmarks_XB))).gt.180.0)
	         traj_x_label_lon = sprintf("%5.1fW", 360.0 - dist_temp@gclon(k*tointeger(floor(npts/n_tickmarks_XB))))
		  else
		     traj_x_label_lon = sprintf("%5.1fE", dist_temp@gclon(k*tointeger(floor(npts/n_tickmarks_XB))))
		  end if
		  if (dist_temp@gclat(k*tointeger(floor(npts/n_tickmarks_XB))).gt.0.0)
		     traj_x_label_lat = sprintf("%5.1fN", dist_temp@gclat(k*tointeger(floor(npts/n_tickmarks_XB))))
		  else
		     traj_x_label_lat = sprintf("%5.1fS", -1*dist_temp@gclat(k*tointeger(floor(npts/n_tickmarks_XB))))
		  end if
		  ; cres@tmXBLabels(k) = sprintf("%5.1f", traj_lon(k*tointeger(floor(npts/n_tickmarks_XB))))+"~C~"+sprintf("%5.1f", traj_lat(k*tointeger(floor(npts/n_tickmarks_XB))))
		  cres@tmXBLabels(k) = traj_x_label_lon + "~C~" + traj_x_label_lat 

       end do
       
       ; plots(n) = gsn_csm_contour(wksII,curtains(n, j, :, :),cres)
	   
       if (n.eq.0 .or. n.eq.2 .or. n.eq.4)
          cres@tiYAxisString        = "Altitude (hPa)" 
       else
          cres@tiYAxisString        = " " 
       end if
       plots(n) = gsn_csm_contour(wksII,curtains_regrid(n, j, :, :),cres)
	  
       ; ==============	   
       ; Add wind barbs
       ; ==============
       windbarb_res = True
         windbarb_res@gsnDraw        = False          ; do not draw
         windbarb_res@gsnFrame       = False          ; do not advance the frame
         windbarb_res@vcGlyphStyle   = "WindBarb"     ; select wind barbs 
         windbarb_res@vcMapDirection = False			; needed to disassociate the map from the vectors
         windbarb_res@gsnAddCyclic   = False              ; data is not cyclic
         windbarb_res@vcWindBarbColor = "grey20"
         windbarb_res@vcMinDistanceF = 0.02
         windbarb_res@vcWindBarbTickLengthF = 0.4
         windbarb_res@vcWindBarbTickSpacingF = 0.15
       
         windbarb_res@vcRefAnnoOn    = True       
         ; windbarb_res@vcRefAnnoPerimOn = False
         ; windbarb_res@vcRefAnnoBackgroundColor = -1
         windbarb_res@vcRefAnnoOrthogonalPosF = 0.02 ;-1.0
         windbarb_res@vcRefLengthF   = 0.03 ;0.045          ; define length of vec ref
         windbarb_res@vcRefMagnitudeF = 30
         windbarb_res@vcRefAnnoString1On = True
         windbarb_res@vcRefAnnoOrientation = "horizontal"
         windbarb_res@vcRefAnnoString1   = "$VMG$" +" m/s"
	   
         windbarb_res@lbLabelBarOn         = False
         windbarb_res@vcLevelSelectionMode    = "ExplicitLevels" ; will explicitly set the levels
         windbarb_res@vcWindBarbLineThicknessF= 2              ; set the wind barb thickness
         windbarb_res@vcLevels                = ispan(0,50,10)    ; set the levels 
	   
         plots_windbarb(n) = gsn_csm_vector_scalar(wksII, curtains_u_regrid(n, j, :, :), curtains_v_regrid(n, j, :, :), curtains_wspd_regrid(n, j, :, :), windbarb_res)
         overlay(plots(n),plots_windbarb(n))
	   
	   ; -----------------------------------
	   ; create curtain transects on the map
	   ; -----------------------------------
	   cur(n) = gsn_add_polyline(wksII,plots(5),dist_temp@gclon,dist_temp@gclat,plres)
	   cur_names(0) = gsn_add_text(wksII,plots(5),names_array(0),curtain_defs_lon(0,0)+2,curtain_defs_lat(0,0)+2,txres)   ; C1
	   cur_names(1) = gsn_add_text(wksII,plots(5),names_array(1),curtain_defs_lon(1,0)-1,curtain_defs_lat(1,0)-1,txres)   ; C2
	   cur_names(2) = gsn_add_text(wksII,plots(5),names_array(2),curtain_defs_lon(2,0)+2,curtain_defs_lat(2,0)+2,txres)   ; C3
	   cur_names(3) = gsn_add_text(wksII,plots(5),names_array(3),curtain_defs_lon(3,0),curtain_defs_lat(3,0)-1,txres)     ; C4
	   cur_names(4) = gsn_add_text(wksII,plots(5),names_array(4),curtain_defs_lon(4,0)-1,curtain_defs_lat(4,0)+1,txres)   ; C5
	   delete(dist_temp)

	   ; ----------------------------------------------------------------------------------------------------------------------
	   ; Add site markers on the curtain...
	   ; ... if the disttance bwtween the site and the great arc of the transect is less than a certain threshhold (say, 1 deg)
	   ; ----------------------------------------------------------------------------------------------------------------------
	   DistThreshhold = 1.0
	   site_lot_on_cutrain_res                    = True
	   ; site_lot_on_cutrain_res@gsMarkerColor      = "black"
	   ; site_lot_on_cutrain_res@gsMarkerSizeF      = 10
	   ; site_lot_on_cutrain_res@gsMarkerThicknessF = 15
	   site_lot_on_cutrain_res@gsLineColor = "black"
	   site_lot_on_cutrain_res@gsLineThicknessF = 3.0
	   site_name_on_curtain_res               = True
	   site_name_on_curtain_res@txFontHeightF = 0.03
	   site_name_on_curtain_res@amJust        = "TopLeft"
	   site_name_on_curtain_res@txFontColor   = site_lot_on_cutrain_res@gsLineColor
	   do k = 0, -1+dimsizes(AddSite_Name)
	      ; print(""+AddSite_Name(k)+" on transect "+n+": "+Site_on_Great_Arc(k, n))
	      if (abs(Site_on_Great_Arc(k, n)).lt.DistThreshhold)
	         dist_fract_site = gc_latlon(curtain_defs_lat(n,0),curtain_defs_lon(n,0),AddSite_lat(k),AddSite_lon(k),npts,4) / \
	                           gc_latlon(curtain_defs_lat(n,0),curtain_defs_lon(n,0),curtain_defs_lat(n,1),curtain_defs_lon(n,1),npts,4)
             ; print(""+AddSite_Name(k)+" on transect "+n+": "+Site_on_Great_Arc(k, n)+", "+dist_fract_site)
			 dist_fract_site = dist_fract_site * curtain_x_max_ind
			 ; if (k.eq.0)
			    ; site_lot_on_cutrain_res@gsMarkerIndex = 12
			 ; else
			    ; site_lot_on_cutrain_res@gsMarkerIndex = 8
			 ; end if
			 site_lot_on_cutrain(k, n) = gsn_add_polyline(wksII, plots(n), (/dist_fract_site, dist_fract_site/), (/max(tracer_all&lev), min(tracer_all&lev)/), site_lot_on_cutrain_res)
			 site_name_on_curtain = gsn_add_text(wksII, plots(n), " "+AddSite_Name(k), dist_fract_site, 210, site_name_on_curtain_res)
			 delete(dist_fract_site)
		  end if
	   end do
	end do

    ;----------------------------------------
    ; add in right Y-axis label
    ;----------------------------------------
    txres = True
    txres@txFontHeightF := 0.011   ; Label right Y axis.
    txres@txAngleF      := 90.
    gsn_text_ndc(wksII,"Height (thousand ft)",.84,.83,txres)
    gsn_text_ndc(wksII,"Height (thousand ft)",.84,.55,txres)

   ;----------------------------------------
   ; add in forcast day and tracer name
   ;----------------------------------------
    txres = True
    txres@txFontHeightF = 0.017   ; Label left 
    txres@txAngleF     := 0
      gsn_text_ndc(wksII,"Forecast on: "+forecast_date,.4,0.94,txres)

    txres@txFontHeightF = 0.017   ; Label right
      gsn_text_ndc(wksII,tracername + " ("+tracer_all@units+")",.85,0.94,txres)

   ;----------------------------------------
   ; Add site info:
   ;----------------------------------------
   
   polyres = True                        ; poly marker mods desired     
    polyres@gsMarkerSizeF = 10          ; select size to avoid streaking
    polyres@gsMarkerColor = "black" ;"red"        ; set polymarker color
    polyres@tfPolyDrawOrder = "PostDraw"
    polyres@gsMarkerThicknessF = 8

	transect_plot_sites = new(dimsizes(AddSite_Name), graphic)
	do k = 0, -1+dimsizes(AddSite_Name)
       if (k.eq.0)
          polyres@gsMarkerIndex = 12
       else
          polyres@gsMarkerIndex = 8
       end if
	   transect_plot_sites(k) = gsn_add_polymarker(wksII, plots(5), AddSite_lon(k), AddSite_lat(k), polyres)
	end do
    

  ; -------------------------------
  ; Panel plot the curtains
  ; -------------------------------
  panel_res                       = True
  panel_res@txString              = "FIREX-AQ WACCM forecast " + date(j)+\
                                    " "+sprintf("%02g",datesec(j)/3600) +"UTC";+\
                                    ;sprintf("%02g",mod((datesec(j)/3600),24)) +"UTC"
  panel_res@txPosYF               = 0.98
  panel_res@txPosXF               = 0.54
  panel_res@gsnPanelScalePlotIndex = 5
  panel_res@gsnPanelLabelBar = True
  panel_res@lbLabelFontHeightF =0.01
  panel_res@gsnPanelYF = (/0.89,0.89,0.61,0.61,0.32,0.32/)      ; Adjust bottommost plots.
  panel_res@gsnPanelTop = 0.95
  panel_res@gsnPanelBottom = 0.015
  panel_res@pmLabelBarOrthogonalPosF =-0.005
  
  panel_res@gsnPanelYWhiteSpacePercent  = 2
  
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

  ; Add in NCAR logo to plots
   delete(wksII)
   cmd = "composite -geometry 150x150+1700+2300 ACOM-contemp-logo-blue-square.png "+ plot_name + ".png "+ plot_name + ".png"
   system(cmd)

end do

end

