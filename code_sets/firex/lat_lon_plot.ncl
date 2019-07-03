;=======================================================;
;  lat_lon_plot.ncl
;=======================================================;
;   - updated to FIREX domains and species
;                               R Schwantes 17 June 2019 
; ------------------------------------------------------;
; Concepts illustrated:
;   - developed for the FIREX 2019 campaign
;   - open model output
;   - read in species
;   - plot 2D field over zoomed region
;   - overplot flight-leg paths
;   - create curtain plots for each flight leg
;
;   Files needed:
;         -modeloutput in netCDF format
;
;   Called in as:
;         lat_lon_plot(file, tracer, max lat, min lat, min lon, max lon, \
;                      pressure layers to plot, region name for plot,\
;                      color bar levels)
; 
;                                  RRB February 08, 2016
;=======================================================;
load "read_in_species.ncl"

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


outfolder = "forecast_plots/"
;--------------------------------------------
; user input
;--------------------------------------------

  ; -------------------------------
  ; model file
  ; -------------------------------
  filename = fileIN

  ;------------
  ; plot definitions
  ;------------
    plttype      = "png"           ; pdf or png if want to save
    pltname      = "WACCM_"+tracer+"_latlon_"+region_name

;--------------------------------------------
; end user input
;--------------------------------------------

   
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
     lev_limit_1 = dimsizes(lev)-1


     tracer_all = read_in_species(filename, tracer, lat_bound_0, lat_bound_1, lon_bound_0, lon_bound_1, lev_limit_0)
     tracername = tracer_all@tracername

      date       = fin->$"date"$
      datesec    = fin->$"datesec"$
      P0mb       = 0.01*fin->P0            ; change Pa to mb
      Psurf      = fin->PS(:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})
      hyam       = fin->hyam(lev_limit_0:)               ; read to memory
      hybm       = fin->hybm(lev_limit_0:)
      ;u          = fin->U(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})
      ;v          = fin->V(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})

;printVarSummary(tracer_all)
;printVarSummary(Psurf)
;print(tracer_all&lev)
;print(max(tracer_all))
;exit

  ; -------------------------------
  ; regrid to selected levels
  ; -------------------------------
  if (tracer.eq."AODVISdn".or.\
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

    ;u_new = vinth2p(u,hyam, hybm, pnew ,Psurf, 1    \
    ;             ,P0mb, 1, False)

    ;v_new = vinth2p(v,hyam, hybm, pnew ,Psurf, 1    \
    ;             ,P0mb, 1, False)
  end if


;*******************************************
;--------------------------------------------
; plot
;--------------------------------------------
; loop over levels
do i= 0,dimsizes(level_array)-1
  ; loop over dates in file
  do j= 0,dimsizes(date)-1

    plot_name = outfolder + pltname+"_"+level_array(i)+"_"+date(j)+"_"+sprintf("%02g",datesec(j)/3600)
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
      res@gsnAddCyclic        = False

      if (tracer.eq."AODVISdn".or.\
        tracer.eq."DUST_ODV") then
        res@tiMainString      = "FIREX WACCM forecast, Column, "+ \
                                date(j)+" "+sprintf("%02g",datesec(j)/3600)+"UTC"; +\
                                ; sprintf("%02g",mod((datesec(j)/3600)+9,24)) +"KST"
      else
        res@tiMainString      = "FIREX WACCM forecast, "+level_names(i)+", "+ \
                                date(j)+" "+sprintf("%02g",datesec(j)/3600)+"UTC";+\
                                ;sprintf("%02g",mod((datesec(j)/3600)+9,24)) +"KST"
      end if

      res@tiMainFontHeightF   = 0.022

      res@gsnLeftString   = "Forecast run on: "+forecast_date   ; add the gsn titles
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

      ; add map outlines
      res@mpDataSetName         = "Earth..4"   ; This new database contains
      res@mpDataBaseVersion     = "MediumRes"        ; better map outlines
      res@mpOutlineOn           = True         ; Turn on map outlines
      res@mpOutlineBoundarySets = "GeophysicalAndUSStates"
      res@mpGeophysicalLineThicknessF = 4
      res@mpUSStateLineThicknessF = 2
      res@mpNationalLineThicknessF = 2
 

   ;-----------------------
   ; Set up the contour plot
   ;-----------------------
     if (i.eq.0) then
       if (tracer.eq."AODVISdn".or.\
           tracer.eq."DUST_ODV") then
         plot=gsn_csm_contour_map_ce(wks,tracer_all(j,:,:),res)  ; plot contours
       else
         plot=gsn_csm_contour_map_ce(wks,tracer_all(j,dimsizes(tracer_all&lev)-1,:,:),res)  ; plot contours
       end if
     else if (pnew(i-1).gt.700) then
       plot=gsn_csm_contour_map_ce(wks,tracer_new(j,i-1,:,:),res)  ; plot contours
     else
       if (tracer.eq."CO") then
         res@cnLevels             := contour_levels(1:16)
       else if (tracer.eq."CO01") then
         res@cnLevels             := contour_levels(0:14)
       else if (tracer.eq."CO02".or.\
                tracer.eq."COnotNA") then
         res@cnLevels             := contour_levels(0:23)
       else if (tracer.eq."ISOP".or.\
                tracer.eq."NOx") then
         res@cnLevels             := contour_levels/10
       else if (tracer.eq."O3".or.\
                tracer.eq."O3S") then
         res@cnLevels             := contour_levels
       else
         res@cnLevels             := contour_levels/5
       end if
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
   
    ;if (i.eq.0) then
    ;  plotV = gsn_csm_vector(wks,u(j,dimsizes(u&lev)-1,:,:),v(j,dimsizes(v&lev)-1,:,:),resV)
    ;else
    ;  plotV = gsn_csm_vector(wks,u_new(j,i-1,:,:),v_new(j,i-1,:,:),resV)
    ;end if

    ;overlay(plot,plotV)

   ;----------------------------------------
   ; Add site info:
   ;        Boise:  43.6150N, 116.2023W
   ;        Salina: 38.8403N, 97.6114W
   ;----------------------------------------
   polyres = True                        ; poly marker mods desired     
    polyres@gsMarkerSizeF = 10          ; select size to avoid streaking
    polyres@gsMarkerColor = "black" ;"red"        ; set polymarker color
    polyres@tfPolyDrawOrder = "PostDraw"
    polyres@gsMarkerThicknessF = 7
    polyres@gsMarkerIndex    = 4

   AddSite_Name = (/"Boise ID", "Salina KS"/)
   AddSite_lat = (/43.6150, 38.8403/)
   AddSite_lon = (/360-116.2023, 360-97.6114/)
    stations_poly = gsn_add_polymarker(wks, plot, AddSite_lon, AddSite_lat, polyres)

   ;----------------------------------------
   ; add countries and counties
   ;----------------------------------------
    ;This is now plotted above.
    ; country_shp_name    = "shapefiles/US_census_state/tl_2018_us_state.shp"
    ; lnres                  = True
    ;   lnres@gsLineColor      = "gray24"
    ;   lnres@gsLineThicknessF = 1.4
    ;  country_id = gsn_add_shapefile_polylines(wks,plot,country_shp_name,lnres)

    ;  world_shp_name    = "shapefiles/GSHHS_NOAA/GSHHS_shp/i/GSHHS_i_L1.shp"
    ;    lnres@gsLineThicknessF = 1.4
    ;  world_id = gsn_add_shapefile_polylines(wks,plot,world_shp_name,lnres)



    draw(plot)
    frame(wks)

   ; Trim png files to remove white space
   if (plttype.eq."png") then
      system("convert -density 96 -trim "+plot_name+"."+plttype+" "+plot_name+"."+plttype) 
   end if

  end do
end do


end

