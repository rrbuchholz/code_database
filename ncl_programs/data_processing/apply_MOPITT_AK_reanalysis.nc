;============================================
; apply_MOPITT_AK_reanalysis.ncl
;============================================
;
; Concepts Illustrated
;          - Open reanalysis files
;          - Load MOPITT L3 AK and a priori
;          - Convolve the model with AK and ap
;          - average over regions
;          - write out to netCDF
;
; To use type on the command line:
;          > ncl apply_MOPITT_AK_reanalysis.ncl
;                            RRB Oct 1, 2019
;============================================
load "/IASI/home/buchholz/code_database/ncl_programs/buchholz_global_util/ultrafine_mopitt.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------
  year = 2001
  meas_dir = "/MOPITT/V8T/Archive/L3/"
  meas_files = systemfunc ("ls "+meas_dir+year+"*/month/*.he5")

  model_dir = "/IASI/home/buchholz/CAM_chem/gaubert_reanalysis_2017/climatology/"
  model_files = systemfunc ("ls "+model_dir+"*.nc")

  ;------------
  ; toggles
  ;------------
  PLOT           = True
    plotType      = "x11"
    plotName      = "test"
   ; -------------------------------
   ; Plotting
   ; -------------------------------
    minlev = 0.5
    maxlev = 4.
    lev_spacing = 0.25

  NETCDF           = False

;--------------------------------------------
; end user input
;--------------------------------------------
;
;--------------------------------------------
; set up
;--------------------------------------------

  if (PLOT) then
    pltdir       = "./"
    pltname      = "MOPITT_v_CAM-chem_CO_column"
  end if

  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  ; names of data structures
  ; determined from an ncl_filedump
  sat_surfap    = "APrioriCOSurfaceMixingRatioDay_MOP03"
  sat_ap        = "APrioriCOMixingRatioProfileDay_MOP03"
  sat_colap     = "APrioriCOTotalColumnDay_MOP03"
  sat_colak     = "TotalColumnAveragingKernelDay_MOP03"
  sat_co        = "RetrievedCOTotalColumnDay_MOP03"
  sat_psurf     = "SurfacePressureDay_MOP03"

  ; -------------------------------
  ; MODEL
  ; -------------------------------
  ; names of data structures
  ; determined from an ncl_filedump
  model_tracer  = "CO"

  counter = 0

  ; -------------------------------
  ; CONSTANTS
  ; -------------------------------
   NAv    = 6.0221415e+23                    ;--- Avogadro's number
   g      = 9.81                             ;--- m/s - gravity
   H = (8.314*240)/(0.0289751*9.8)           ;--- scale height
   MWair = 28.94                             ;--- g/mol
   xp_const = (NAv* 10)/(MWair*g)            ;--- scaling factor for turning vmr into pcol
                                             ;--- (note 1*e-09 because in ppb)
  ; -------------------------------
  ; REGIONS
  ; -------------------------------
   region_names = (/"AnthChina", "AnthIndi", "AnthEuro", "AnthUSA",\
                    "BBUSA", "BBCanada", "BBSiberia", "BBWRus",\
                    "BBCAmerica", "BBSAmerica","BBSAmOcean",\
                     "BBCAfrica", "BBSAfrica","BBSAfOcean", \
                    "BBMSEA", "BBNWAu","BBEAu", "NH_monthly", "SH_monthly"/)

   ;                   minlat, maxlat, minlon, maxlon
   region_select = (/(/ 30.,  40.,      110.,      123./),\  ;AnthChina
                     (/ 20.,  30.,       70.,       95./),\  ;AnthIndi
                     (/ 45.,  55.,        0.,       15./),\  ;AnthEuro
                     (/ 35.,  40.,      -95.,      -75./),\  ;AnthUSA
                     (/ 38.,  50.,     -125.,     -105./),\  ;BBUSA
                     (/ 50.,  60.,     -125.,      -90./),\  ;BBCanada
                     (/ 50.,  60.,       90.,      140./),\  ;BBSiberia
                     (/ 35.,  50.,       40.,       85./),\  ;BBWRus
                     (/ 10.,  23.5,    -105.,      -70./),\  ;BBCAmerica
                     (/-25.,  -5.,      -75.,      -50./),\  ;BBSAmerica
                     (/-35., -15.,      -40.,      -25./),\  ;BBSAmericaOcean
                     (/  5.,  15.,      -20.,       38./),\  ;BBCAfrica
                     (/-20.,  -5.,       10.,       40./),\  ;BBSAfrica
                     (/-15.,   0.,      -10.,       10./),\  ;BBSAfOcean
                     (/-10.,   8.,        95.,     125./),\  ;BBMSEA
                     (/-25., -10.,       115.,     140./),\  ;BBNWAu
                     (/-45., -10.,       140.,     155./),\  ;BBEAu
                     (/  0.,  60.,      -180.,     180./),\  ;NH
                     (/-60.,   0.,      -180.,     180./) /) ;SH


;--------------------------------------------
; load mopitt
;--------------------------------------------
meas_file_selected = meas_files(0)
mopitt_in := addfile(meas_file_selected, "r")
    apriori_surf  := mopitt_in->$sat_surfap$
    apriori_prof  := mopitt_in->$sat_ap$
    apriori_col   := mopitt_in->$sat_colap$
    AvKer         := mopitt_in->$sat_colak$
    tcol_gas_orig:= mopitt_in->$sat_co$
      tcol_gas_orig!0    = "lon"
      delete_VarAtts(tcol_gas_orig&lon, (/"Units", "projection"/))
      tcol_gas_orig!1    = "lat"
      delete_VarAtts(tcol_gas_orig&lat, (/"Units", "projection"/))
    tcol_gas = tcol_gas_orig(lat|:, lon|:)
    psurf         := mopitt_in->$sat_psurf$
    pres_array    := mopitt_in->$"Pressure_MOP03"$
    meas_lon      := mopitt_in->$"Longitude_MOP03"$
    meas_lat      := mopitt_in->$"Latitude_MOP03"$

;--------------------------------------------
; Set up MOPITT pressure arrays
;--------------------------------------------
  meas_parray := new((/dimsizes(meas_lon), dimsizes(meas_lat), 10/), float)
  meas_parray(:,:,0) = psurf
  do i=0,dimsizes(pres_array)-1
    meas_parray(:,:,i+1) = pres_array(i)
  end do

  ; Correct for where MOPITT surface pressure <900 hPa
  ; Determine the level where the surface pressure needs to sit
  meas_delta_p := new((/dimsizes(meas_lon), dimsizes(meas_lat), 10/), float)
      do z= 0, 9, 1
        if (z.eq.9) then
          meas_delta_p(:,:,z) = meas_parray(:,:,0)-0
        else
          meas_delta_p(:,:,z) = meas_parray(:,:,0)-meas_parray(:,:,z+1)
        end if
      end do

  ; Repeat surface values at all levels to replace
  ; in equivalent position in parray if needed
  meas_psurfarray = new((/dimsizes(meas_lon), dimsizes(meas_lat), 10/), float) 
   do z= 0, 9, 1
    meas_psurfarray(:,:,z) = psurf
   end do
  ; add fill values below true surface
   meas_parray = where(meas_delta_p.le.0,meas_parray@_FillValue,meas_parray)
   meas_parray = where((meas_delta_p.le.100 .and. meas_delta_p.ge.0),meas_psurfarray,meas_parray)
   meas_parray = where(ismissing(meas_delta_p),meas_parray@_FillValue,meas_parray)

;--------------------------------------------
; MOPITT combine a priori profile info
; (surface values are separate to profiles)
;--------------------------------------------
printVarSummary(apriori_prof)
apriori_prof_all := new((/dimsizes(meas_lon), dimsizes(meas_lat),10/),float,-9999)
      apriori_prof_all(:,:,1:9)  = apriori_prof
      apriori_prof_all(:,:,0)  = apriori_surf

; Repeat surface a priori values at all levels to replace if needed
apsurfarray = new((/dimsizes(meas_lon), dimsizes(meas_lat), 10/), float) 
   do z= 0, 9, 1
    apsurfarray(:,:,z) = apriori_surf
   end do

; Correct for where MOPITT surface pressure <900 hPa
; (add fill values)
   apriori_prof_all = where(meas_delta_p.le.0,apriori_prof_all@_FillValue,apriori_prof_all)
   apriori_prof_all = where((meas_delta_p.le.100 .and. meas_delta_p.ge.0),apsurfarray,apriori_prof_all)
   apriori_prof_all = where(ismissing(meas_delta_p),apriori_prof_all@_FillValue,apriori_prof_all)

   logap = log(apriori_prof_all)

;--------------------------------------------
; load associated climatology file
;--------------------------------------------
model_file_selected = model_files(0)
model_in = addfile(model_file_selected, "r")
    tracer_in     := model_in->$model_tracer$
    ps            = model_in->$"PS"$
    hyam          = model_in->$"hyam"$
    hybm          = model_in->$"hybm"$
    P0            = model_in->$"P0"$

;--------------------------------------------
; model hybrid layers to pressure
;--------------------------------------------
  pi = pres_hybrid_ccm(ps, P0, hyam, hybm) ; pi(ntim,klevi,nlat,mlon)
    pi!0         = "time"
    pi!1         = "lev"
    pi!2         = "lat"
    pi!3         = "lon"
    pi&time      = tracer_in&time
    pi&lev       = tracer_in&lev
    pi&lat       = tracer_in&lat
    pi&lon       = tracer_in&lon
    pi@long_name = "mid-level pressures"
    pi@units     = "Pa"

  ; -------------------------------
  ; Calculate pressure array delta_p
  ; -------------------------------
  delta_p = new(dimsizes(tracer_in),float)
  copy_VarCoords(tracer_in,delta_p)
  do i = 0, dimsizes(delta_p&lev)-2
    delta_p(:,i,:,:) = pi(:,i+1,:,:) - pi(:,i,:,:)
  end do

  ; -------------------------------
  ; Base model tcol
  ; -------------------------------
   model_tcol_all  = dim_sum_n((tracer_in*xp_const*delta_p)/100,1)  ; dp Pa -> hPa
     model_tcol_all!0         = "time"
     model_tcol_all!1         = "lat"
     model_tcol_all!2         = "lon"
     model_tcol_all@long_name = "total column "+ model_tracer
     model_tcol_all@units = "molec/cm^2"
     model_tcol_all&time      = tracer_in&time
     model_tcol_all&lat       = tracer_in&lat
     model_tcol_all&lon       = tracer_in&lon
   model_tcol_all = lonFlip(model_tcol_all)

;--------------------------------------------
; Model downscaled to MOPITT Grid
;--------------------------------------------
tracer_remap = area_conserve_remap_Wrap(tracer_in&lon, tracer_in&lat, tracer_in, tcol_gas&lon, tcol_gas&lat, False)
tracer_remap@_FillValue=-9999
  ;tracer_remap = where(meas_parray@_FillValue,tracer_remap@_FillValue,tracer_remap)
ps_remap = area_conserve_remap_Wrap(tracer_in&lon, tracer_in&lat, ps, tcol_gas&lon, tcol_gas&lat, False)
pi_remap = pres_hybrid_ccm(ps_remap, P0, hyam, hybm) ; pi(ntim,klevi,nlat,mlon)
    pi_remap!0         = "time"
    pi_remap!1         = "lev"
    pi_remap!2         = "lat"
    pi_remap!3         = "lon"
    pi_remap&time      = tracer_in&time
    pi_remap&lev       = tracer_in&lev
    pi_remap&lat       = ps_remap&lat
    pi_remap&lon       = ps_remap&lon
    pi@long_name = "mid-level pressures"
    pi@units     = "Pa"

;--------------------------------------------
; Smoothed tcol - apply AKs
;--------------------------------------------
model_smooth_calc = new(dimsizes(tcol_gas_orig), float)
copy_VarCoords(tcol_gas_orig,model_smooth_calc)
delete_VarAtts(model_smooth_calc, (/"Units", "long_name", "projection"/))
sublevs = 100
AvKer_calcs = where(ismissing(AvKer), 0, AvKer)
logap_calcs = where(ismissing(logap), 0, logap)

;Loop over Latitude
do l = 0, dimsizes(meas_lat)-1
  ;Loop over Longitude
  ;do m = 0, dimsizes(meas_lon)-1
  do m = 0, 2
    if (all(ismissing(meas_parray(m,l,:)))) then
       continue
    else 
      ; Model to MOPITT layers
      model_interp := ultrafine_mopitt(tracer_remap(0,:,l,m), pi_remap(0,:,l,m)/100, meas_parray(m,l,:), sublevs)
      log_modelinterp = log(model_interp/1e-09)
      log_modelinterp_calc = where(ismissing(log_modelinterp), 0, log_modelinterp)

      ; Convolve AK and a priori
      model_smooth_calc(m,l) = apriori_col(m,l) + AvKer_calcs(m,l,:)#(log_modelinterp-logap_calcs(m,l,:))

      print("Ret:"+tcol_gas_orig(m,l)+", A priori:" + apriori_col(m,l)+ ", Smooth: "+model_smooth_calc(m,l))
      ; SOMETHING WEIRD HAPPENING WITH MISSING VALUES IN LOWER LAYERS

    end if
  end do
end do

model_smooth = model_smooth_calc
printVarSummary(model_smooth)



model_smooth = where(ismissing(tcol_gas_orig),model_smooth@_FillValue,model_smooth)
model_smooth_plot = model_smooth(lat|:, lon|:)

;--------------------------------------------
; Relative difference
;--------------------------------------------
diff_tcol = (tcol_gas - model_smooth_plot)/tcol_gas
  copy_VarCoords(model_smooth_plot,diff_tcol)

;--------------------------------------------
; Regional averages
;--------------------------------------------


;--------------------------------------------
; plot
;--------------------------------------------
if (PLOT) then

;************************************************
; Setting up correlation plot
;************************************************
 wks  = gsn_open_wks(plotType,plotName)         ; specifies a plot type
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

    mapres@gsnLeftStringFontHeightF  = 0.016
    mapres@gsnRightStringFontHeightF = 0.016

    mapres@cnFillOn                  = True
    mapres@cnFillMode                = "CellFill"          ; fill as grid boxes not contours
    mapres@cnLineLabelsOn            = False               ; turn off countour labels
    mapres@cnLinesOn                 = False
    mapres@lbLabelBarOn              = True               ; turn off individual colorbars

    mapres@cnLevelSelectionMode      = "ManualLevels"      ; manually set the contour levels
      mapres@cnMinLevelValF          = minlev                  ; set the minimum contour level
      mapres@cnMaxLevelValF          = maxlev              ; set the maximum contour level
      mapres@cnLevelSpacingF         = lev_spacing         ; set the interval between contours

    ;-------------------
    ; do the plotting
    ;-------------------
      mapres@cnFillPalette      = "BlAqGrYeOrRe"
      mapres@gsnRightString     = "x 10~S2~18   molec. cm~S2~-2"
      mapres@gsnLeftString     = "MOPITT"
      map1 = gsn_csm_contour_map_ce(wks,tcol_gas(:,:)/1e18,mapres)

      mapres@gsnLeftString     = "CAM-chem climatology"
      map2 = gsn_csm_contour_map_ce(wks,model_tcol_all(0,:,:)/1e18,mapres)

     mapres@gsnLeftString     = "Smoothed CAM-chem climatology"   ;
      map3 = gsn_csm_contour_map_ce(wks,model_smooth_plot/1e18,mapres)

     mapres@gsnLeftString     = "Relative difference: (MOPITT - smoothed CAM-chem)/MOPITT"   ;
     mapres@gsnRightString     = ""
     mapres@cnFillPalette       = "hotcold_18lev"
     mapres@cnMinLevelValF          = -0.5             ; set the minimum contour level
     mapres@cnMaxLevelValF          = 0.5               ; set the maximum contour level
     mapres@cnLevelSpacingF         = 0.05                ; set the interval between contours
      map4 = gsn_csm_contour_map_ce(wks,diff_tcol(:,:),mapres)


    panel_res                      = True
      panel_res@gsnMaximize        = True  
      panel_res@txString           = ""
      panel_res@gsnPanelLabelBar   = False                ; add common colorbar

    gsn_panel(wks,(/map1,map2,map3,map4/),(/2,2/),panel_res)

end if ; PLOT

;--------------------------------------------
; Write out region averages
;--------------------------------------------
if (NETCDF) then

end if ; NETCDF

end

