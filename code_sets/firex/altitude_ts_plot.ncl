;=======================================================;
;  altitude_ts_plot.ncl
;=======================================================;
;
; Concepts illustrated:
;   - developed for the FIREX 2019 campaign
;   - open model output
;   - read in species
;   - plot concentrations at altitude versus time

;   Files needed:
;         -model output in netCDF format
;
;   Called in as:
;
;         altitude_ts_plot(file, tracer, station(s) lat, station(s) lon,\
;                          station(s) name(s)) 
;                                  RRB February 08, 2016
;=======================================================;
load "read_in_species.ncl"

undef("altitude_ts_plot")
procedure altitude_ts_plot(filesIN:string, tracer:string, lat_array:numeric, lon_array:numeric,\
                           station_names:string, contour_levels:numeric, forecast_date:numeric)

begin

  ; check input
  if (.not.all(fileexists(filesIN))) then
    print("altitude_ts_plot: One or all input files do not exist: " + fileIN)
    return
  end if

  if (dimsizes(lat_array).ne.dimsizes(lon_array).or.\
      dimsizes(lat_array).ne.dimsizes(station_names)) then
    print("altitude_ts_plot: Station array sizes do not match - ")
    print("#Lats: "+dimsizes(lat_array)+", #Lons: "+dimsizes(lon_array)+\
          ", #Names: "+dimsizes(station_names))
    return
  end if

;--------------------------------------------
; user input
;--------------------------------------------

  ; -------------------------------
  ; model files
  ; -------------------------------
  filenames = filesIN

  ;------------
  ; plot definitions
  ;------------
    plttype      = "png"           ; pdf or png if want to save
    pltname      = "WACCM_"+tracer+"_"
    outfolder = "forecast_plots/"

;--------------------------------------------
; end user input
;--------------------------------------------

;--------------------------------------------
; set up
;--------------------------------------------
  H = (8.314*240)/(0.0289751*9.8)           ;--- scale height
   
;*******************************************
;--------------------------------------------
; load file and extract
;--------------------------------------------

  ; -------------------------------
  ; model load
  ; -------------------------------
    fin = addfiles(filenames, "r")         ; read in
    ListSetType (fin, "cat")               ; concatenate

     tracer_all = read_in_species(filenames, tracer)
     tracername = tracer_all@tracername

     date = fin[:]->$"date"$
     datesec = fin[:]->$"datesec"$
     P0         = 0.01*fin[0]->P0           ; change Pa to mb
     Psurf      = 0.01*fin[:]->PS
     hyam       = fin[0]->hyam 
     hybm       = fin[0]->hybm

;printVarSummary(tracer_all)
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
    pm&lat       = tracer_all&lat
    pm&lon       = tracer_all&lon
    pm@long_name = "mid-level pressures"
    pm@units     = "hPa"

  ; average the pressure over all 5 days
  pressure_array = dim_avg_n_Wrap(pm,0)
   

;--------------------------------------------
; plot
;--------------------------------------------
;loop over stations
do i=0, dimsizes(lat_array)-1
  tracer_station = tracer_all(:,:,{lat_array(i)},{lon_array(i)})
  pressure_station = pressure_array(:,{lat_array(i)},{lon_array(i)})
  tracer_station&lev = pressure_station
  tracer_station&lev@units = "hPa"

  plot_name = outfolder+pltname+station_names(i)+"_5dForecast_"+forecast_date
  wks = gsn_open_wks(plttype,plot_name)        
  gsn_define_colormap(wks,"GMT_wysiwygcont_rrb")  

  res                       = True                  ; plot mods desired
    res@gsnDraw             = False	            ; don't draw it yet
    res@gsnFrame            = False                 ; don't advance frame

    res@cnFillOn            = True                  ; turn on color
    res@cnLinesOn           = False                 ; no contour lines  
    res@cnLevelSelectionMode ="ExplicitLevels"
    res@cnLevels             = contour_levels

    res@tiMainString        = "FIREX WACCM 5-day forecast at~C~"+ \
                             station_names(i) +", "+ date(0)+" to "+date(dimsizes(date)-1) +" (UTC)"
    ;res@gsnLeftString      = "Forecast made on: "               ; add the gsn titles
    res@gsnLeftString       = ""
    res@gsnRightString      = tracername + " ("+tracer_all@units+")"
    res@tiYAxisString       = tracer_station&lev@long_name+" ("+\
                               tracer_station&lev@units+")"
    res@tiMainFontHeightF   = 0.024

    res@vpXF                 = 0.13
    res@vpWidthF             = 0.75
    res@vpHeightF            = 0.40
    res@trYReverse           = True                 ; reverse y-axis
    res@trYMinF              = 200

    res@tmXBMode             = "Explicit" ; Define own tick mark labels.
    time_dim = dimsizes(tracer_all&time)-1
    res@tmXBValues           = tracer_all&time(0:time_dim:4)
    res@tmXBLabels           = date(0:time_dim:4)
    res@tmXBMinorValues      = tracer_all&time

    res@tmYLMode             = "Explicit" ; Define own tick mark labels.
    res@gsnYAxisIrregular2Log = False
    res@tmYLValues           = (/925,850,700,600,500,300/)
    res@tmYLLabels           = (/925,850,700,600,500,300/)

    res@tmYUseLeft           = False               ; disassociate  YR tick marks with YL tick marks
    res@tmYRLabelsOn         = True                ; turn on the YR tick mark labels
    res@tmYRMode             = "Explicit"          ; turn off height labels

     ;height_labels = (/0.5,1,2,4,6,10/)
     height_labels_feet = (/1.,3.,5.,10.,18.,32./)             ; thousand feet for pilots
     height_labels = (height_labels_feet*1000)/3280.84   ; convert to km for plotting
     pressures = pressure_station(dimsizes(pressure_station)-1) * exp((-height_labels*1000)/H)
     res@tmYRValues          = pressures
     res@tmYRLabels          = height_labels_feet

  ; the contour plot
  plot = gsn_csm_contour(wks,tracer_station(lev|:,time|:),res)

  ; add in right Y-axis label
    txres = True
    txres@txFontHeightF = 0.022   ; Label right Y axis.
    txres@txAngleF      = 90.
    gsn_text_ndc(wks,"Height (thousand feet)",.95,.6,txres)

  ; add in forcast day
    txres@txFontHeightF = 0.012   ; Label right Y axis.
    txres@txAngleF      = 0.
    gsn_text_ndc(wks,"Forecast on: "+forecast_date,.23,.825,txres)

  draw(plot)
  frame(wks)

  ; Trim png files to remove white space
  if (plttype.eq."png") then
     system("convert -density 96 -trim "+plot_name+"."+plttype+" "+plot_name+"."+plttype) 
  end if

end do ; stations

end

