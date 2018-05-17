;=======================================================;
;  lat_lon_plot.ncl
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
;         lat_lon_plot(file, tracer, max lat, min lat, min lon, max lon, \
;                      pressure levels to plot, region name based on lat lon boundaries,\
;                      color bar levels)
; 
;                                  RRB February 08, 2016
;=======================================================;

undef("lat_lon_plot")
procedure lat_lon_plot(fileIN:string, tracer:string, topboundary:numeric, bottomboundary:numeric, \
                       leftboundary:numeric, rightboundary:numeric, pnew:numeric, region_name, \
                       contour_levels, forecast_date:numeric)

begin

  ; check input
  if (.not.(fileexists(fileIN))) then
    print("lat_lon_plot: Input file does not exist: " + fileIN)
    return
  end if


;--------------------------------------------
; user input
;--------------------------------------------

  ; -------------------------------
  ; CAM-chem file
  ; -------------------------------
  filename = fileIN

  ;------------
  ; plot definitions
  ;------------
    plttype      = "png"           ; pdf or png if want to save
    pltname      = "CAM-chem_"+tracer+"_latlon_"+region_name

;--------------------------------------------
; end user input
;--------------------------------------------

;--------------------------------------------
; set-up
;--------------------------------------------
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
 else if (tracer.eq."AEROD_v") then
   tracername = "AOD"
 else if (tracer.eq."DUST_ODV") then
   tracername = "Dust optical depth"
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
 end if
 end if

   
;*******************************************
;--------------------------------------------
; load file and extract
;--------------------------------------------

  ; -------------------------------
  ; CAM-chem load
  ; -------------------------------
    fin = addfile(filename, "r")           ; read in
      if (tracer.eq."ISOP_etc") then
        tracer_dummy1 = fin->ISOP          ; mol/mol
        tracer_dummy2 = fin->MACR          ; mol/mol
        tracer_dummy3 = fin->MVK           ; mol/mol
        tracer_dummy = tracer_dummy1 +tracer_dummy2 + tracer_dummy3
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "ISOP + MACR + MVK concentration"
      else if (tracer.eq."NOx") then
        tracer_dummy1 = fin->NO2          ; mol/mol
        tracer_dummy2 = fin->NO          ; mol/mol
        tracer_dummy = tracer_dummy1 +tracer_dummy2
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "NO + NO2 concentration"
      else if (tracer.eq."BC") then
        tracer_dummy1 = fin->CB1          ; kg/kg
        tracer_dummy2 = fin->CB2          ; kg/kg
        tracer_dummy = tracer_dummy1 +tracer_dummy2
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "BC concentration"
      else if (tracer.eq."OC") then
        tracer_dummy1 = fin->OC1          ; kg/kg
        tracer_dummy2 = fin->OC2          ; kg/kg
        tracer_dummy = tracer_dummy1 +tracer_dummy2
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "OC concentration"
      else if (tracer.eq."SOA") then
        tracer_dummy1 = fin->SOAB          ; kg/kg
        tracer_dummy2 = fin->SOAI          ; kg/kg
        tracer_dummy3 = fin->SOAM          ; kg/kg
        tracer_dummy4 = fin->SOAT          ; kg/kg
        tracer_dummy5 = fin->SOAX          ; kg/kg
        tracer_dummy = tracer_dummy1+tracer_dummy2+tracer_dummy3+tracer_dummy4+tracer_dummy5
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "SOA concentration"
      else if (tracer.eq."DUST_ODV") then
        tracer_dummy1 = fin->ODV_DST01          ; kg/kg
        tracer_dummy2 = fin->ODV_DST02          ; kg/kg
        tracer_dummy3 = fin->ODV_DST03          ; kg/kg
        tracer_dummy4 = fin->ODV_DST04          ; kg/kg
        tracer_dummy = tracer_dummy1+tracer_dummy2+tracer_dummy3+tracer_dummy4
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "Dust ODV"
      else if (tracer.eq."CO_var") then
        tracer_dummy1 = fin->CO          ; mol/mol
        match_str   = "cam_0001.h1"
        min_str     = "cam_0002.h1"
        max_str     = "cam_0003.h1"
        filemin = str_sub_str(filename,match_str,min_str)
        filemax = str_sub_str(filename,match_str,max_str)
        fin2 = addfile(filemin, "r")           ; read in
        fin3 = addfile(filemax, "r")           ; read in
        tracer_dummy_min = fin2->CO          ; mol/mol
        tracer_dummy_max = fin3->CO          ; mol/mol
        tracer_dummy = 0.5*((tracer_dummy_max - tracer_dummy_min)/tracer_dummy1)
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "CO variability"
          tracer_dummy@units = "ppb/ppb"
      else 
        tracer_dummy = fin->$tracer$         ; mol/mol or kg/kg
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      date       = fin->$"date"$
      datesec    = fin->$"datesec"$
      P0mb       = 0.01*fin->P0            ; change Pa to mb
      Psurf      = fin->PS
      hyam       = fin->hyam               ; read to memory
      hybm       = fin->hybm
      u          = fin->U
      v          = fin->V

     if (tracer.eq."BC".or.tracer.eq."OC".or.\
         tracer.eq."SO4".or.tracer.eq."SOA") then
       tracer_all = tracer_dummy              ; kg/kg
         copy_VarCoords(tracer_dummy,tracer_all)
         copy_VarAtts(tracer_dummy,tracer_all)
     else if (tracer.eq."AEROD_v".or.\
              tracer.eq."DUST_ODV".or.\
              tracer.eq."CO_var") then
       tracer_all = tracer_dummy
     else
       tracer_all = tracer_dummy/1e-9         ; mol/mol -> ppb
         copy_VarCoords(tracer_dummy,tracer_all)
         copy_VarAtts(tracer_dummy,tracer_all)
         tracer_all@units = "ppb"
     end if
     end if

;print(tracer_all&lat)
;printVarSummary(tracer_all)
;print(tracer_all&lon)
;print(max(tracer_all))
;exit

  ; -------------------------------
  ; regrid to selected levels
  ; -------------------------------
  if (tracer.eq."AEROD_v".or.\
      tracer.eq."DUST_ODV") then
    ; only one level
    level_names := "Surface"
    level_array := "surface"
  else
    level_names = new((/dimsizes(pnew)+1/), string)
    level_array = new((/dimsizes(pnew)+1/), string)

    level_names(0) = "Surface"
    level_array(0) = "surface"

    do i = 1,dimsizes(pnew)
      level_names(i) = sprintf("%3g", (pnew(i-1))) + " hPa"
      level_array(i) = sprintf("%3g", (pnew(i-1)))
    end do

    tracer_new = vinth2p(tracer_all,hyam, hybm, pnew ,Psurf, 1    \
                 ,P0mb, 1, False)

    u_new = vinth2p(u,hyam, hybm, pnew ,Psurf, 1    \
                 ,P0mb, 1, False)

    v_new = vinth2p(v,hyam, hybm, pnew ,Psurf, 1    \
                 ,P0mb, 1, False)
  end if


;*******************************************
;--------------------------------------------
; plot
;--------------------------------------------
; loop over levels
do i= 0,dimsizes(level_array)-1
  ; loop over dates in file
  do j= 0,dimsizes(date)-1

    plot_name = pltname+"_"+level_array(i)+"_"+date(j)+"_"+sprintf("%02g",datesec(j)/3600)
    wks = gsn_open_wks(plttype,plot_name)        
    gsn_define_colormap(wks,"GMT_wysiwygcont_rrb")  

   ;-----------------------
   ; Set resources for plotting
   ;----------------------- 
    res                       = True                      ; plot mods desired
      res@gsnDraw             = False	                  ; don't draw it yet
      res@gsnFrame            = False                     ; don't advance frame
      res@mpOutlineOn         = False                     ; will draw highres map later
      res@gsnMaximize         = True   

      if (tracer.eq."AEROD_v".or.\
        tracer.eq."DUST_ODV") then
        res@tiMainString      = "KORUS CAM-chem forecast, Column, "+ \
                                date(j)+" "+sprintf("%02g",datesec(j)/3600)+"Z, "+\
                                sprintf("%02g",mod((datesec(j)/3600)+9,24)) +"KST"
      else
        res@tiMainString      = "KORUS CAM-chem forecast, "+level_names(i)+", "+ \
                                date(j)+" "+sprintf("%02g",datesec(j)/3600)+"Z, "+\
                                sprintf("%02g",mod((datesec(j)/3600)+9,24)) +"KST"
      end if

      res@tiMainFontHeightF   = 0.022

      ;res@gsnLeftString   = "Forecast made on: "               ; add the gsn titles
      res@gsnLeftString   = ""               ; add the gsn titles
      res@gsnRightString  = tracername + " ("+tracer_all@units+")"
      res@gsnRightStringFontHeightF = 0.020

      res@cnFillOn             = True
      res@cnLinesOn            = False
      res@cnLevelSelectionMode ="ExplicitLevels"
      res@cnLevels             := contour_levels
      res@lbOrientation        = "vertical"

      ; limit plotting region
      res@mpLimitMode         ="LatLon"
        res@mpMinLatF         = bottomboundary
        res@mpMaxLatF         = topboundary
        res@mpMinLonF         = leftboundary
        res@mpMaxLonF         = rightboundary

   ;-----------------------
   ; Set up the contour plot
   ;-----------------------
     if (i.eq.0) then
       if (tracer.eq."AEROD_v".or.\
           tracer.eq."DUST_ODV") then
         plot=gsn_csm_contour_map_ce(wks,tracer_all(j,:,:),res)  ; plot contours
       else
         plot=gsn_csm_contour_map_ce(wks,tracer_all(j,dimsizes(tracer_all&lev)-1,:,:),res)  ; plot contours
       end if
     else if (pnew(i-1).ge.700) then
       plot=gsn_csm_contour_map_ce(wks,tracer_new(j,i-1,:,:),res)  ; plot contours 
     else
       if (tracer.eq."CO") then
         res@cnLevels             := contour_levels(2:17)
       else if (tracer.eq."ISOP_etc".or.\
                tracer.eq."NOx") then
         res@cnLevels             := contour_levels/10
       else if (tracer.eq."PAN".or.\
                tracer.eq."CO_var") then
         res@cnLevels             := contour_levels/2
       else if (tracer.eq."O3") then
         res@cnLevels             := contour_levels
       else
         res@cnLevels             := contour_levels/5
       end if
       end if
       end if
       end if
       plot=gsn_csm_contour_map_ce(wks,tracer_new(j,i-1,:,:),res)  ; plot contours 
     end if
     end if

   ;-----------------------
   ; Add vectors
   ;-----------------------
    resV                  = True                      ; vector only resources
      resV@gsnDraw                 = False            ; don'd draw yet
      resV@gsnFrame                = False            ; don't advance yet
      resV@vcRefMagnitudeF         = 10.0             ; add a reference vector
      resV@vcRefLengthF            = 0.025            ; what the ref length is
      resV@vcLineArrowThicknessF   = 2.0              ; change vector thickness
      resV@vcMinDistanceF          = 0.015            ; thin out the vectors
      resV@vcGlyphStyle            = "CurlyVector"    ; turn on curly vectors
      resV@vcLineArrowColor        = "grey45"           ; change vector color
      resV@vcRefAnnoArrowLineColor  = "black"         ; change ref vector color

      resV@vcRefAnnoOn               = True
      resV@vcRefAnnoString1          = "10 m/s"
      resV@vcRefAnnoSide             = "Bottom"
      resV@vcRefAnnoString2On        = False
      resV@vcRefAnnoPerimOn          = True
      resV@vcRefAnnoOrthogonalPosF   = -0.11
      resV@vcRefAnnoParallelPosF     = 1

      resV@gsnLeftString   = ""
      resV@gsnRightString  = ""
   
    if (i.eq.0) then
      plotV = gsn_csm_vector(wks,u(j,dimsizes(u&lev)-1,:,:),v(j,dimsizes(v&lev)-1,:,:),resV)
    else
      plotV = gsn_csm_vector(wks,u_new(j,i-1,:,:),v_new(j,i-1,:,:),resV)
    end if

    overlay(plot,plotV)

   ;----------------------------------------
   ; add countries and counties
   ;----------------------------------------
     country_shp_name    = "/glade/u/home/pfister/KORUS/KOR_adm1.shp"
     lnres                  = True
       lnres@gsLineColor      = "gray24"
       lnres@gsLineThicknessF = .9
      country_id = gsn_add_shapefile_polylines(wks,plot,country_shp_name,lnres)

      world_shp_name    = "/glade/u/home/pfister/KORUS/countries.shp"
        lnres@gsLineThicknessF = 1.1
      world_id = gsn_add_shapefile_polylines(wks,plot,world_shp_name,lnres)

   ;----------------------------------------
   ; add in forcast day
   ;----------------------------------------
    txres = True
    txres@txFontHeightF = 0.012   ; Label right Y axis.
    if (region_name.eq."east_asia") then
      gsn_text_ndc(wks,"Forecast on: "+forecast_date,.18,.79,txres)
    else
      gsn_text_ndc(wks,"Forecast on: "+forecast_date,.18,.71,txres)
    end if


    draw(plot)
    frame(wks)

   ; Trim png files to remove white space
   if (plttype.eq."png") then
      system("convert -density 96 -trim "+plot_name+"."+plttype+" "+plot_name+"."+plttype) 
   end if

  end do
end do


end

