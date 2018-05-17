;=======================================================;
;  altitude_ts_plot.ncl
;=======================================================;
;
; Concepts illustrated:
;   - developed for the KORUS 2016 campaign
;   - open CAM-chem output
;   - read in species
;   - plot concentrations at altitude versus time

;   Files needed:
;         -CAM-chem output in netCDF format
;
;   Called in as:
;
;         altitude_ts_plot(file, tracer, station(s) lat, station(s) lon,\
;                          station(s) name(s)) 
;                                  RRB February 08, 2016
;=======================================================;
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
  ; CAM-chem files
  ; -------------------------------
  filenames = filesIN

  ;------------
  ; plot definitions
  ;------------
    plttype      = "png"           ; pdf or png if want to save
    pltname      = "CAM-chem_"+tracer+"_"

;--------------------------------------------
; end user input
;--------------------------------------------

;--------------------------------------------
; set up
;--------------------------------------------
  H = (8.314*240)/(0.0289751*9.8)           ;--- scale height


 if (tracer.eq."CO01") then
   tracername = "CO: S.Korea - anthro"
 else if (tracer.eq."CO02") then
   tracername = "CO: Japan - anthro"
 else if (tracer.eq."CO03") then
   tracername = "CO: NE China  - anthro"
 else if (tracer.eq."CO04") then
   tracername = "CO: N. China  - anthro"
 else if (tracer.eq."CO05") then
   tracername = "CO: S. China - anthro"
 else if (tracer.eq."CO06") then
   tracername = "CO: S. Asia  - anthro"
 else if (tracer.eq."CO07") then
   tracername = "CO: N. Asia -fires"
 else if (tracer.eq."CO08") then
   tracername = "CO: Central Asia - fires"
 else if (tracer.eq."CO09") then
   tracername = "CO: S. Asia - fires" 
 else if (tracer.eq."ISOP_etc") then
   tracername = "ISOP + MACR + MVK"
 else if (tracer.eq."CO_var") then
   tracername = "CO variability [0.5*(max-min)/avg]"
 else
   tracername = tracer
 end if
 end if
 end if
 end if
 end if
 end if
 end if
 end if
 end if
 end if
 end if
   
;*******************************************
;--------------------------------------------
; load file and extract
;--------------------------------------------

  ; -------------------------------
  ; CAM-chem load
  ; -------------------------------
    fin = addfiles(filenames, "r")         ; read in
    ListSetType (fin, "cat")               ; concatenate

      if (tracer.eq."ISOP_etc") then
        tracer_dummy1 = fin[:]->ISOP          ; mol/mol
        tracer_dummy2 = fin[:]->MACR          ; mol/mol
        tracer_dummy3 = fin[:]->MVK           ; mol/mol
        tracer_dummy = tracer_dummy1 +tracer_dummy2 + tracer_dummy3
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "ISOP + MACR + MVK concentration"
      else if (tracer.eq."NOx") then
        tracer_dummy1 = fin[:]->NO2          ; mol/mol
        tracer_dummy2 = fin[:]->NO           ; mol/mol
        tracer_dummy = tracer_dummy1 +tracer_dummy2
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "NO + NO2 concentration"
      else if (tracer.eq."BC") then
        tracer_dummy1 = fin[:]->CB1          ; mol/mol
        tracer_dummy2 = fin[:]->CB2          ; mol/mol
        tracer_dummy = tracer_dummy1 +tracer_dummy2
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "BC concentration"
      else if (tracer.eq."OC") then
        tracer_dummy1 = fin[:]->OC1          ; mol/mol
        tracer_dummy2 = fin[:]->OC2          ; mol/mol
        tracer_dummy = tracer_dummy1 +tracer_dummy2
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "OC concentration"
      else if (tracer.eq."SOA") then
        tracer_dummy1 = fin[:]->SOAB          ; kg/kg
        tracer_dummy2 = fin[:]->SOAI          ; kg/kg
        tracer_dummy3 = fin[:]->SOAM          ; kg/kg
        tracer_dummy4 = fin[:]->SOAT          ; kg/kg
        tracer_dummy5 = fin[:]->SOAX          ; kg/kg
        tracer_dummy = tracer_dummy1+tracer_dummy2+tracer_dummy3+tracer_dummy4+tracer_dummy5
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "SOA concentration"
      else if (tracer.eq."CO_var") then
        tracer_dummy1 = fin[:]->CO          ; mol/mol
        match_str   = "cam_0001.h1"
        min_str     = "cam_0002.h1"
        max_str     = "cam_0003.h1"
        filemin = str_sub_str(filenames,match_str,min_str)
        filemax = str_sub_str(filenames,match_str,max_str)
        fin2 = addfiles(filemin, "r")         ; read in
        ListSetType (fin2, "cat")             ; concatenate
        fin3 = addfiles(filemax, "r")         ; read in
        ListSetType (fin3, "cat")             ; concatenate
        tracer_dummy_min = fin2[:]->CO          ; mol/mol
        tracer_dummy_max = fin3[:]->CO          ; mol/mol
        tracer_dummy = 0.5*((tracer_dummy_max - tracer_dummy_min)/tracer_dummy1)
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "CO variability"
          tracer_dummy@units = "ppb/ppb"
      else 
        tracer_dummy = fin[:]->$tracer$         ; mol/mol or kg/kg
      end if
      end if
      end if
      end if
      end if
      end if
     date = fin[:]->$"date"$
     datesec = fin[:]->$"datesec"$
     P0         = 0.01*fin[0]->P0           ; change Pa to mb
     Psurf      = 0.01*fin[:]->PS
     hyam       = fin[0]->hyam 
     hybm       = fin[0]->hybm

     if (tracer.eq."BC".or.tracer.eq."OC".or.\
         tracer.eq."SO4".or.tracer.eq."SOA") then
       tracer_all = tracer_dummy              ; kg/kg
         copy_VarCoords(tracer_dummy,tracer_all)
         copy_VarAtts(tracer_dummy,tracer_all)
     else if (tracer.eq."CO_var") then
       tracer_all = tracer_dummy
     else
       tracer_all = tracer_dummy/1e-9         ; mol/mol -> ppb
         copy_VarCoords(tracer_dummy,tracer_all)
         copy_VarAtts(tracer_dummy,tracer_all)
         tracer_all@units = "ppb"
     end if
     end if
       tracer_all&lev@units = "hybrid_sigma_pressure"

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

  plot_name = pltname+station_names(i)+"_5dForecast_"+forecast_date
  wks = gsn_open_wks(plttype,plot_name)        
  gsn_define_colormap(wks,"GMT_wysiwygcont_rrb")  

  res                       = True                  ; plot mods desired
    res@gsnDraw             = False	            ; don't draw it yet
    res@gsnFrame            = False                 ; don't advance frame

    res@cnFillOn            = True                  ; turn on color
    res@cnLinesOn           = False                 ; no contour lines  
    res@cnLevelSelectionMode ="ExplicitLevels"
    res@cnLevels             = contour_levels

    res@tiMainString        = "KORUS CAM-chem 5-day forecast at~C~"+ \
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
    time_dim = dimsizes(tracer_dummy&time)-1
    res@tmXBValues           = tracer_dummy&time(0:time_dim:4)
    res@tmXBLabels           = date(0:time_dim:4)
    res@tmXBMinorValues      = tracer_all&time

    res@tmYLMode             = "Explicit" ; Define own tick mark labels.
    res@gsnYAxisIrregular2Log = True
    res@tmYLValues           = (/925,850,700,500,300,200/)
    res@tmYLLabels           = (/925,850,700,500,300,200/)

    res@tmYUseLeft           = False               ; disassociate  YR tick marks with YL tick marks
    res@tmYRLabelsOn         = True                ; turn on the YR tick mark labels
    res@tmYRMode             = "Explicit"          ; turn off height labels
     height_labels = (/2,4,6,8,10/)
     pressures = pressure_station(dimsizes(pressure_station)-1) * exp((-height_labels*1000)/H)
     res@tmYRValues          = pressures
     res@tmYRLabels          = height_labels

  ; the contour plot
  plot = gsn_csm_contour(wks,tracer_station(lev|:, time|:),res)

  ; add in right Y-axis label
    txres = True
    txres@txFontHeightF = 0.022   ; Label right Y axis.
    txres@txAngleF      = 90.
    gsn_text_ndc(wks,"Height (km)",.95,.6,txres)


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

