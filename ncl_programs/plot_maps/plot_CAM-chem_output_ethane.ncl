;=======================================================;
;  plot_CAM-chem_output_ethane.ncl.ncl
;=======================================================;
;
; Concepts illustrated:
;   - load CAM output files from automated diagnostic
;   - Overlay FTS ethane
;   
;   To run type:
;         ncl plot_CAM-chem_output_ethane.ncl
;
;   Requires:
;         one average output file
;                                  RRB March 17, 2015
;=======================================================;
; load the libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------
  tracer = "C2H6"
  region = "World"
  timeslice = "2008-2015"

  ; Plot definitions
    units = "ppb"
    maxlev = 2.4
    minlev = 0.2
    lev_spacing = 0.1

   STATIONS = True

  ; -------------------------------
  ; file location
  ; -------------------------------
  in_folder = "/data16a/buchholz/CAM_chem_output/fmerra.208.FCSD.1deg.chey180418/processed"

  camfile_1 = systemfunc ("ls "+in_folder+"/CAMchem_FCSD208_1deg_2008_2015.nc")


  ;------------
  ; toggles
  ;------------
  PLOT           = True
  ; -------------------------------
  ; plotting parameters
  ; -------------------------------
  if (PLOT) then
    mapType = "png"
    mapName = "~/"+tracer+"_"+region+"_diff"
      mapType@wkWidth = 1250
      mapType@wkHeight = 2500 
  end if ;PLOT

  if (region.eq."World") then
      latmin                         = -90               ; zoom to World
      latmax                         = 90
      lonmin                         = -180
      lonmax                         = 180
      loncenter                      = 0
      region_name =  "World"
  else if (region.eq."Australia") then
     latmin                          = -50               ; zoom to Australia
      latmax                         = -10
      lonmin                         = 100
      lonmax                         = 180
      loncenter                      = 140
      region_name =  "Australia"
  else if (region.eq."NAmerica") then
      latmin                         = 20               ; zoom to North America
      latmax                         = 60
      lonmin                         = 220
      lonmax                         = 300
      loncenter                      = 260
      region_name =  "NorthAmerica"
  else if (region.eq."Amazon") then
    ;  latmin                         = -40               ; zoom to Amazon
    ;  latmax                         = 10
    ;  lonmin                         = 270
    ;  lonmax                         = 330
  end if
  end if
  end if
  end if

;--------------------------------------------
; end user input
;--------------------------------------------

;********************************************
; set up
   NAv = 6.022e23                    ; Avogadro's number, molecules mole^-1


  cr = "~C~"

;********************************************
;-------------------
; load files and extract
;-------------------

  if (units.eq."ppt") then
    divisor = 1e-12
  else if (units.eq."ppb") then
    divisor = 1e-09
  else if (units.eq."kg/m2/sec") then
    divisor = 1
  else if (units.eq."aod".or.units.eq."K".or.units.eq."W/m2"\
           .or.units.eq."/s".or.units.eq."fraction") then
    divisor = 1
  end if
  end if
  end if
  end if
  fin = addfiles(camfile_1, "r")
     tracer_fields_1  = fin[:]->$tracer$
     tracer_fields_1= tracer_fields_1/divisor
     delta_p  = fin[:]->PDELDRY

printVarSummary(tracer_fields_1)
printVarSummary(delta_p)

; Column average VMR
     sum_deltap = dim_sum_n(delta_p,1)
     sum_deltap_array = conform_dims(dimsizes(delta_p), sum_deltap,(/0,2,3/))
     pressure_weight  = delta_p/sum_deltap_array

     column_prof = tracer_fields_1* pressure_weight
     column_vmr_dum = dim_sum_n(column_prof,1)
     column_vmr = rm_single_dims(column_vmr_dum)
     column_vmr!0 = "lat"
     column_vmr&lat = tracer_fields_1&lat
     column_vmr!1 = "lon"
     column_vmr&lon = tracer_fields_1&lon


;********************************************
  ;-------------------
  ; MAP PLOT
  ;-------------------
  if (PLOT) then
    wks = gsn_open_wks(mapType,mapName)
    gsn_define_colormap(wks,"BlAqGrYeOrRe")        ; change colour map
    ;-------------------
    ; define resources 
    ; to use for plotting
    ;-------------------
    mapres = True
    mapres@tiMainString              = ""                  ; changing main large title
    mapres@gsnFrame                  = False               ; do not advance frame
    mapres@gsnDraw		     = False	           ; don't draw it yet
    mapres@gsnMaximize               = True  

    mapres@cnFillOn                  = True
    mapres@cnFillMode                = "CellFill"          ; fill as grid boxes not contours
    mapres@cnLineLabelsOn            = False               ; turn off countour labels
    mapres@cnLinesOn                 = False
    mapres@lbLabelBarOn              = True               ; turn off individual colorbars

    mapres@lbTitleFontHeightF       = .020
    mapres@lbTitlePosition          = "bottom"      ; Label Bar title
    mapres@lbOrientation             = "Vertical"     ; Label bar location
    mapres@mpGeophysicalLineThicknessF = 2.5


    mapres@mpLimitMode               ="LatLon"            ; zoom to Australia
      mapres@mpMinLatF               = latmin
      mapres@mpMaxLatF               = latmax
      mapres@mpMinLonF               = lonmin
      mapres@mpMaxLonF               = lonmax
      mapres@mpCenterLonF            = loncenter

    mapres@gsnRightStringFontHeightF   =0.024
    mapres@tmXBLabelFontHeightF        =0.020
    mapres@tmYLLabelFontHeightF        =0.020
    mapres@tmXBTickSpacingF            = 60.
    mapres@tmYLTickSpacingF            = 45.

    mapres@cnLevelSelectionMode      = "ManualLevels"      ; manually set the contour levels
      mapres@cnMinLevelValF          = minlev                  ; set the minimum contour level
      mapres@cnMaxLevelValF          = maxlev              ; set the maximum contour level
      mapres@cnLevelSpacingF         = lev_spacing         ; set the interval between contours

    ;-------------------
    ; do the plotting
    ;-------------------
      mapres@gsnRightString     = "CAM-chem column average C~B1~2 H~B1~6  VMR"
      map1 = gsn_csm_contour_map_ce(wks,tracer_fields_1(0,55,:,:),mapres)


     if (STATIONS) then
    ; ===================
    ; Locations
    ; ===================
    ;
    ; Add the locations as filled squares
    ;


     ; replace ethane with avg FTS value 2008-2015
     ethane_avg = (/ (/80.05,78.92,76.53,67.84,59.88,53.1,48.85,47.42,46.55,43.66,43.46,\
                    40.04,28.3,19.54,-20.9,-34.41,-45.04,-77.82/),\
                   (/-86.42,11.93,-68.74,20.41,29.83,8.85,2.35,10.98,7.98,-79.4,143.8,\
                    -105.26,-16.48,-155.58,55.5,150.88,169.68,166.65 /),\
                   (/1.3999,0.828,0.9005,0.9959,1.0072,0.9075,1.023,0.7231,0.7014,1.0606,1.1615,\
                     0.9381,0.5926,0.4595,0.3048,0.2499,0.1931,0.1321/)\
                /)

     new_tracer_field_dummy = column_vmr
     new_tracer_field = lonFlip(new_tracer_field_dummy)

       do k = 0, dimsizes(ethane_avg(0,:))-1
         newval = ethane_avg(2,k)
         new_tracer_field({ethane_avg(0,k)-5:ethane_avg(0,k)+5},{ethane_avg(1,k)-5:ethane_avg(1,k)+5}) = newval
       end do

      map1 = gsn_csm_contour_map_ce(wks,new_tracer_field,mapres)

     ; add polygons
     plres               = True
     plres@gsLineColor      = "grey25"
     plres@gsLineThicknessF = 4.0

     dum_polygon  = new(dimsizes(ethane_avg(0,:)),graphic)
     ;---Loop through each "bin" and attach the markers to the map.
     do i = 0, dimsizes(ethane_avg(0,:))-1
        ;---Add outlines
        lat_points = (/ethane_avg(0,i)-5,  ethane_avg(0,i)-5, ethane_avg(0,i)+5, ethane_avg(0,i)+5, ethane_avg(0,i)-5/)
        lon_points = (/ethane_avg(1,i)-5, ethane_avg(1,i)+5,  ethane_avg(1,i)+5, ethane_avg(1,i)-5, ethane_avg(1,i)-5/)
        dum_polygon(i) = gsn_add_polyline(wks,map1,lon_points,lat_points,plres)
     end do

    end if


    draw(map1)
    frame(wks)

  end if    ; PLOT



end

