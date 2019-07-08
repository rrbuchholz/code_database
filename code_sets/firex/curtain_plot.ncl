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

  npts     =   50                    ; number of points in resulting transect
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
      hyam         = fin->hyam(lev_limit_0:)
      hybm         = fin->hybm(lev_limit_0:)


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
    curtain_defs_lon = (/(/-116.2023,-116.2023/),\	;0
                         (/-130.0,-100.0/),\		;1
                         (/-110, -90/),\		;2
                         (/-97.6114,-97.6114/),\	;3
                         (/-90, -120/)/)		;4
    curtain_defs_lat = (/(/35, 50/),\			;0
                         (/43.6150,43.6150/),\		;1
                         (/38.8403,38.8403/),\		;2
                         (/35, 45/),\			;3
                         (/36.8855, 44.5904/)/)		;4
	curtain_defs_lon = where(curtain_defs_lon.lt.0.0, 360.0+curtain_defs_lon, curtain_defs_lon)
	
	dim_curtain_defs = dimsizes(curtain_defs_lat)
	
	transect = new((/dim_curtain_defs(0), dim_tracer_all(0), dim_tracer_all(1), npts/), float)
	transect!0 = "curtain_index"
	transect!1 = "time"
	transect!2 = "lev"
	transect!3 = "npts"

	transect_pm = new((/dim_curtain_defs(0), dim_tracer_all(0), dim_tracer_all(1), npts/), float)
	transect_pm!0 = "curtain_index"
	transect_pm!1 = "time"
	transect_pm!2 = "lev"
	transect_pm!3 = "npts"
	
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
	   do n = 0, -1+dim_curtain_defs(0)
		  dist_temp = gc_latlon(curtain_defs_lat(n,0),curtain_defs_lon(n,0),curtain_defs_lat(n,1),curtain_defs_lon(n,1),npts,2)
		  transect(n,:,:,:) = linint2_points(tracer_all&lon,tracer_all&lat,tracer_all,True,dist_temp@gclon,dist_temp@gclat,2)
		  transect_pm(n,:,:,:) = linint2_points(pm&lon,pm&lat,pm,True,dist_temp@gclon,dist_temp@gclat,2)
	      delete(dist_temp)
	      curtains(n,:,:,:) = rm_single_dims(transect(n,:,:,:))
		  curtains_pm(n,:,:,:) = rm_single_dims(transect_pm(n,:,:,:))
	      ; print("--- curtain ind: "+n)
	      ; printMinMax(transect(n,:,:,:), 0)
	   end do
	   copy_VarAtts(tracer_all,transect)
	   transect&lev    = tracer_all&lev
	   curtains&lev    = tracer_all&lev
	   ; curtains_pm&lev    = tracer_all_pm&lev
	end if
	
	; printVarSummary(curtains)
	; printVarSummary(curtains_pm)

	 

	curtains_swap = curtains(curtain_index|:, time|:, npts|:, lev|:)
	curtains_pm_swap = curtains_pm(curtain_index|:, time|:, npts|:, lev|:)
	
	curtains_regrid = linint1_Wrap(curtains_pm_swap, curtains_swap, False, lev, 0)
	curtains_regrid := curtains_regrid(curtain_index|:, time|:,  lev|:, npts|:)
    delete(curtains_swap)
	delete(curtains_pm_swap)
	delete(curtains)
	delete(curtains_pm)
	

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
   cres@vpHeightF            = 0.5

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
	  
	   
	   ; -----------------------------------
	   ; create curtain transects on the map
	   ; -----------------------------------
	   cur(n) = gsn_add_polyline(wksII,plots(5),dist_temp@gclon,dist_temp@gclat,plres)
	   cur_names(n) = gsn_add_text(wksII,plots(5),names_array(n),curtain_defs_lon(n,1)+0.5,curtain_defs_lat(n,1)+0.8,txres)
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
    gsn_text_ndc(wksII,"Height (thousand ft)",.87,.81,txres)
    gsn_text_ndc(wksII,"Height (thousand ft)",.87,.55,txres)

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

end do

end

