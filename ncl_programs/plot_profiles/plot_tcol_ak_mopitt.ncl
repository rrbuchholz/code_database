;============================================
; plot_tcol_ak_mopitt.ncl
;============================================
;
; Concepts Illustrated
;          - Open v7, level 2, he5 files
;          - Plot reported column AK
;          - Calculate own column AK and compare
;
; To use type on the command line:
;          > ncl plot_tcol_ak_mopitt.ncl
;                            RRB Mar 25, 2018
;============================================
; load the libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------
  ; MOPITT version
  version = "V7J"
  ret = "J"
  YYYY = 2016
  MM = 01
  DD = 11
  mopitt_general = systemfunc ("ls /MOPITT/"+version+"/Archive/L2/"+YYYY+sprintf("%02.4g", MM)+\
                                "/"+sprintf("%02.4g", MM)+sprintf("%02.4g", DD)+"/MOP02"+ret+"-*.he5")

  ;------------
  ; toggles
  ;------------
  PLOT            = False
    plotType      = "x11"

  PLOTPROFILE       = True
    plot2Type       = "x11"

;--------------------------------------------
; end user input
;--------------------------------------------
;
;--------------------------------------------
; set up
;--------------------------------------------
   ; -------------------------------
   ; Plotting set up
   ; -------------------------------
     ; PLOT
     plotName      = version+"diffAKs"
     titlestring          = "FTS with matrix and vector AK at Lauder, 2000-2012"
     ymax                 = 1e17
     ymin                 = -1e17
     xmin                 = 1999
     xmax                 = 2014

     ; PLOTPROFILE
     plot2Name      = version+"averaging_kernels"
     titlestring2          = "MOPITT and FTS Averaging kernels,  for Lauder, 2000-2012"
     y2max                 = 1000
     y2min                 = 100
     x2min                 = -1.2
     x2max                 = 0.4

  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  ; names of data structures
  ; determined from an ncl_filedump
  suff           = "_MOP02"
  date          = "Time"+suff
  longitude     = "Longitude"+suff
  latitude      = "Latitude"+suff
  solarza       = "SolarZenithAngle"+suff

  sat_profile   = "RetrievedCOMixingRatioProfile_MOP02"
  sat_surf      = "RetrievedCOSurfaceMixingRatio_MOP02"
  sat_psurf     = "SurfacePressure_MOP02"
  sat_ak        = "RetrievalAveragingKernelMatrix_MOP02"

  diag_1       = "RetrievalAnomalyDiagnostic"+suff
  diag_2       = "RetrievedCOTotalColumnDiagnostics"+suff
  col_avker    = "TotalColumnAveragingKernel"+suff

  pvect = (/900.,800.,700.,600.,500.,400.,300.,200.,100./)

                                             ; CONSTANTS
   NAv    = 6.0221415e+23                    ;--- Avogadro's number
   g      = 9.81                             ;--- m/s - gravity
   H = (8.314*240)/(0.0289751*9.8)           ;--- scale height
   MWair = 28.94                             ;--- g/mol
   xp_const = (NAv* 10)/(MWair*g)*1.0e-09    ;--- scaling factor for turning vmr into pcol
                                             ;--- (note 1*e-09 because in ppb)
  ;------------
  ; select daytime 
  ; retrievals
  ;------------
  ; For SZA < 80
  dayflag = 80

  ;------------
  ; distance around 
  ; station
  ;------------
  delta_deg   = 20
  location_lat = 40.
  location_lon =-105
   topboundary     = location_lat+delta_deg
   bottomboundary  = location_lat-delta_deg
   rightboundary   = location_lon+delta_deg
   leftboundary    = location_lon-delta_deg

;--------------------------------------------
; load file and extract
;--------------------------------------------
print("***Plotting MOPITT AKs for file "+mopitt_general+", date: "+YYYY+\
          sprintf("%02.4g", MM)+sprintf("%02.4g", DD))

fin = addfile(mopitt_general, "r")            ;--- read in
      sza          := fin->$solarza$
      lon          := fin->$longitude$
      lat          := fin->$latitude$
      anom_diag    := fin->$diag_1$

  ;--------------------------------------------
  ; select daytime retrievals
  ; within a boundary
  ; and quality controlled
  ;--------------------------------------------
  day_retrievals := ind(sza.le.dayflag.and.\
                 lat.le.topboundary.and.\
                 lat.ge.bottomboundary.and.\
                 lon.ge.leftboundary.and.\
                 lon.le.rightboundary.and.\
                 anom_diag(:,0).eq.0.and.\
                 anom_diag(:,1).eq.0.and.\
                 anom_diag(:,2).eq.0.and.\
                 anom_diag(:,3).eq.0.and.\
                 anom_diag(:,4).eq.0)

  time           := fin->$date$(day_retrievals)  ;--- time in seconds since 1993-1-1 00:00:00 (TAI93)
  lat            := lat(day_retrievals)
  lon            := lon(day_retrievals)

  ak_col         := fin->$col_avker$(day_retrievals,:)
  psurf          := fin->$sat_psurf$(day_retrievals)
  prof           := fin->$sat_profile$(day_retrievals,:,0)
  surf_vmr       := fin->$sat_surf$(day_retrievals,0)
  sat_ak_matrix  := fin->$sat_ak$(day_retrievals,:,:)


  ;--------------------------------------------
  ; select surface pressure less than 900 hPa
  ;--------------------------------------------
  ind_low_press = ind(psurf.le.900)

    low_psurf = (psurf(ind_low_press))
    low_psurf_ak = ak_col(ind_low_press,:)

  ;--------------------------------------------
  ; select surface pressure less than 900 hPa
  ;--------------------------------------------
  ind_high_press = ind(psurf.gt.900)

    high_psurf = (psurf(ind_high_press))
    high_psurf_ak = ak_col(ind_high_press,:)

  ;--------------------------------------------
  ; Set up MOPITT pressure arrays
  ;--------------------------------------------
    parray = new((/dimsizes(psurf), 10/), float)
    parray(:,0) = psurf
    do i=0,dimsizes(psurf)-1
      parray(i,1:9) = pvect
    end do

  ;--------------------------------------------------------------
  ; Correct for where surface pressure <900 hPa
  ;--------------------------------------------------------------
    dp = new((/dimsizes(psurf), 10/), float) ; Pressure difference array
      do z= 0, 8, 1
        dp(:,z) = parray(:,0) - parray(:,z+1)
      end do
     dp(:,9) = 1000

  ; Repeat surface values at all levels to replace if needed
  psurfarray = new((/dimsizes(psurf), 10/), float) 
   do z= 0, 9, 1
    psurfarray(:,z) = psurf
   end do

   parray = where(dp.le.0,parray@_FillValue,parray)
   parray = where((dp.le.100 .and. dp.ge.0),psurfarray,parray)

  ; Repeat surface values for retrieved profiles
    ret_prof =  new((/dimsizes(psurf), 10/), float)
    ret_prof(:,0) = surf_vmr
    do i=0,dimsizes(psurf)-1
      ret_prof(i,1:9) = prof(i,:)
    end do

  ; Repeat surface values for retrieved profiles
  vmrsurfarray = new((/dimsizes(psurf), 10/), float) 
   do z= 0, 9, 1
    vmrsurfarray(:,z) = surf_vmr
   end do

   ret_prof = where(dp.le.0,ret_prof@_FillValue,ret_prof)
   ret_prof = where((dp.le.100 .and. dp.ge.0),vmrsurfarray,ret_prof)

   ;--------------------------------------------
   ; Pressure difference array
   ;--------------------------------------------
   ; MOPITT pressures are level edges.
   ; see V5 User Guide for more info
    delta_p = new((/dimsizes(psurf),10/), float)
    do z= 0, 8, 1
       delta_p(:,z) = parray(:,z)-parray(:,z+1)
    end do
      delta_p(:,9) = 74   ; 26 top level

  ;--------------------------------------------
  ; calculate tcol AK from ak matrix
  ;--------------------------------------------
    log10e = log10(exp(1.))
      prof_dummy = ret_prof
      prof_dummy  = where(ismissing(prof_dummy),0,prof_dummy)
      ak = sat_ak_matrix
      ak  = where(ismissing(ak),0,ak)
      delta_p_dummy = delta_p
      delta_p_dummy  = where(ismissing(delta_p_dummy),0,delta_p_dummy)
    ak_colm = new((/dimsizes(psurf),10/),float)
    ak_colm2 = new((/dimsizes(psurf),10/),float)
    do i = 0, dimsizes(psurf)-1
      do z = 0, 9 
       ak_colm(i,z) = (xp_const/log10e)*(delta_p(i,:)*prof_dummy(i,:)) # (ak(i,z,:))
       multiply_ak := (xp_const/log10e)*(delta_p(i,:)*prof_dummy(i,:)) * (ak(i,z,:))
       ak_colm2(i,z) = sum(multiply_ak)
;if (i.eq.ind_low_press(0))
;print(multiply_ak)
;print(ak_colm2(i,z))
;print(prof_dummy(i,:))
;print(delta_p(i,:))
;print(ak(i,z,:))
;exit
;end if
      end do
    end do

  ak_colm2  = where(ak_colm2.eq.0,ak_colm2@_FillValue,ak_colm2)

  lowak_col = ak_colm(ind_low_press, :)
  lowak_col2 = ak_colm2(ind_low_press, :)
  highak_col2 = ak_colm2(ind_high_press, :)


printVarSummary(psurf)
printVarSummary(high_psurf_ak)
printVarSummary(low_psurf_ak)
print(low_psurf_ak(0:2,:))
print(lowak_col2(0:2,:))

print(high_psurf_ak(0:2,:))
print(highak_col2(0:2,:))
;exit

  ;--------------------------------------------
  ; difference retrieved versus calculated column AKs
  ;--------------------------------------------
  diff_ak = ak_col-ak_colm2
    lowdiff_ak = diff_ak(ind_low_press, :)
    highdiff_ak = diff_ak(ind_high_press, :)


;************************************************
; Setting up profile plot
;************************************************
 if (PLOTPROFILE) then
  wks  = gsn_open_wks(plot2Type,plot2Name)            ; open a workstation
  pvect2 = (/1000.,900.,800.,700.,600.,500.,400.,300.,200.,100./)

  ;-----------------------------------
  ; define resources to use for plotting
  ;-----------------------------------
  res2 = True
     res2@gsnDraw                 = False
    res2@gsnFrame                 = False          ; don't advance frame
    ; Set axes limits
    res2@trYMaxF                  = 1016
    res2@trYMinF                  = 0
    res2@trXMinF                  = x2min
    res2@trXMaxF                  = x2max
    res2@tmXBTickStartF           = x2min
    res2@tmXBTickEndF             = x2max
    res2@xyMarkLineMode           = "MarkLines"       ; Markers *and* lines
    res2@xyMarkers                = 9             ; marker style
    res2@xyMarkerSizeF            = 0.015
    res2@xyLineThicknessF         = 3
    res2@vpWidthF                 = 0.5
    ;res2@vpHeightF                = 0.4 

    ;res2@trYLog                   = True           ; convert axes to logaritmic\
    res2@trYReverse               = True 
    res2@tmXTOn                   = False          ; turn off tickmarks
    res2@tmYROn                   = False

    res2@tiMainString             =""
    res2@tiYAxisString            =""
    res2@tiXAxisString            =""

  ;-----------------------------------
  ; end define resources
  ;-----------------------------------

  ;-----------------------------------
  ; Draw different AKs
  ;-----------------------------------
  ; 1 Psurf < 900 hPa
    res2@tiMainString            = "Values"
    res2@tiYAxisString           = "Altitude (hPa)"
    res2@tiXAxisString            ="AK value (~F34~4~F21~10~S2~19   ) "
    low_cols                    := new(dimsizes(low_psurf_ak(:,0)), "string")
    low_cols                    = "red"
    res2@xyLineColors           := low_cols
    res2@xyMarkerColors         := low_cols
  plot1 = gsn_csm_xy(wks,  low_psurf_ak(0:9,:)/1e19, pvect2, res2)

  ; 1a Psurf < 900 hPa, but calculated here
    low_cols                    := new(dimsizes(lowak_col2(:,0)), "string")
    low_cols                    = "orange"
    res2@xyLineColors           := low_cols
    res2@xyMarkerColors         := low_cols
  plot1a = gsn_csm_xy(wks,  lowak_col2(0:9,:)/1e19, pvect2, res2)
  overlay(plot1, plot1a)

  ; 1b Psurf > 900 hPa
    high_cols                   := new(dimsizes(high_psurf_ak(:,0)), "string")
    high_cols                    = "blue"
    res2@xyLineColors           := high_cols
    res2@xyMarkerColors         := high_cols
  plot1b = gsn_csm_xy(wks,  high_psurf_ak(0:9,:)/1e19, pvect2, res2)
  overlay(plot1, plot1b)

  ; 1a Psurf > 900 hPa, but calculated here

    high_cols                   := new(dimsizes(highak_col2(:,0)), "string")
    high_cols                    = "darkgreen"
    res2@xyLineColors           := high_cols
    res2@xyMarkerColors         := high_cols
  plot1c = gsn_csm_xy(wks,  highak_col2(0:9,:)/1e19, pvect2, res2)
  overlay(plot1, plot1c)

  ; 2 Difference
    res2@tiMainString            ="Difference: retrieved -- calculated"
    res2@tiYAxisString           =""
    res2@tiXAxisString           ="Difference (~F34~4~F21~10~S2~19   ) "
    diff_cols                   := new(dimsizes(ak_colm2(:,0)), "string")
    diff_cols                    = "black"
    res2@xyLineColors           := diff_cols
    res2@xyMarkerColors         := diff_cols
  plot2 = gsn_csm_xy(wks,  lowdiff_ak(0:9,:)/1e19, pvect2, res2)
  plot2a = gsn_csm_xy(wks,  highdiff_ak(0:9,:)/1e19, pvect2, res2)
  overlay(plot2, plot2a)

  ;-----------------------------------
  ; Draw background vertical grid
  ;-----------------------------------
  mopittres = True
    mopittres@gsLineThicknessF        = 0.8
    mopittres@gsLineDashPattern       = 1
    mopittres@gsLineColor             = "grey"

  dummy_alt = new(10, graphic)
  do i = 0, 9
    dummy_alt(i) = gsn_add_polyline(wks, plot1, (/x2min,x2max/), (/pvect2(i), \
                   pvect2(i)/), mopittres)
  end do

  ;-----------------------------------
  ; Add in title and labels
  ;-----------------------------------
   ;drawNDCGrid(wks)
   ; add station
    txres                   = True                      ; polyline mods desired
     txres@txFontHeightF    = 0.014                     ; font smaller. default big
     txres@txJust           = "CenterLeft"              ; font smaller. default big
     txres@txPerimOn        = False
     txres@txFontColor      = "orange"
   gsn_text_ndc(wks,"Psurf < 900 hPa, recalculated",0.11,0.71,txres)
     txres@txFontColor      = "darkgreen"
    gsn_text_ndc(wks,"Psurf > 900 hPa, recalculated",0.11,0.69,txres)
     txres@txFontColor      = "red"
    gsn_text_ndc(wks,"Psurf < 900 hPa",0.11,0.67,txres)
     txres@txFontColor      = "blue"
    gsn_text_ndc(wks,"Psurf > 900 hPa",0.11,0.65,txres)

     txres@txFontColor      = "orange"
    ;gsn_text_ndc(wks,"Psurf < 900 hPa, recalculated",0.45,0.77,txres)
    ; txres@txFontColor      = "darkgreen"
    ;gsn_text_ndc(wks,"Psurf > 900 hPa, recalculated",0.45,0.73,txres)
     txres@txFontColor      = "red"
    ;gsn_text_ndc(wks,"Psurf < 900 hPa",0.22,0.75,txres)
     txres@txFontColor      = "blue"
    ;gsn_text_ndc(wks,"Psurf > 900 hPa",0.22,0.71,txres)

  ;-----------------------------------
  ; Now draw plot
  ;-----------------------------------
  ;draw(plot1)
  ;frame(wks)

  ;-------------------
  ; do the plotting
  ;-------------------
  panel_res                       = True
      panel_res@txString              = "MOPITT "+version+" Averaging Kernels, for the 10 first retrievals ~C~"+ \
                                         "within"+ delta_deg+" deg around "+ "Lat: "+location_lat+", Lon: "+ location_lon +\
                                         ", Date: "+YYYY +sprintf("%02.4g", MM)+sprintf("%02.4g", DD)

    gsn_panel(wks,(/plot1,plot2/),(/1,2/),panel_res)

  end if    ; PLOTPROFILE
exit

;=================================================================
mopitt_in = addfile(mopitt_general, "r")
    mopitt_tcol  = mopitt_in->$sat_tcol$
    mopitt_profile = mopitt_in->$sat_profile$
    time         = mopitt_in->$timearray$
   ; Date is in seconds since 1993-1-1 00:00:00
    mopitt_date  = cd_calendar(time, 0)
    psurf        = mopitt_in->$sat_psurf$
    apriori      = mopitt_in->$sat_ap$
    AvKer        = mopitt_in->$sat_ak$
    error        = mopitt_in->$sat_err$

  ; Repeat surface apriori values at all levels to replace if needed
  apsurfarray = new((/dimsizes(psurf), 10/), float) 
   do z= 0, 9, 1
    apsurfarray(:,z) = (apriori(:,0))
   end do
   apriori = where(dp.le.0,apriori@_FillValue,apriori) ; re-order apriori array
   apriori = where((dp.le.100 .and. dp.ge.0),apsurfarray,apriori)


;--------------------------------------------
; plot
;--------------------------------------------
if (PLOT) then

;************************************************
; Setting up correlation plot
;************************************************
 wks  = gsn_open_wks(plotType,plotName) ; specifies a ps plot
 
 res                     = True                         ; plot mods desired
  res@gsnFrame                 = False                  ; don't advance frame yet
  res@gsnDraw                  = False                  ; don't draw plot
  res@xyMarkLineModes          = (/"Markers","Lines"/)  ; choose which have markers
  res@xyMarkers                = 9                     ; choose type of marker 
  res@xyMarkerColor            = "dodgerblue"                  ; Marker color
  res@xyMarkerSizeF            = 0.008                  ; Marker size (default 0.01)
  res@xyDashPatterns           = 2                      ; dashed line 
  res@xyLineThicknesses        = 5                ; thickness

  ; Set axes limits
  res@trYMaxF                  = ymax
  res@trYMinF                  = ymin
  res@trXMaxF                  = xmax
  res@trXMinF                  = xmin

  res@tmEqualizeXYSizes        = True
  res@tmLabelAutoStride        = True

  res@tiMainString        = titlestring  ; title
  res@tiYAxisString            ="MOPITT total column"
  res@tiXAxisString            ="FTS total column"

 plot1  = gsn_csm_xy (wks, time_frac, diff,res)      ; create plot


 draw(plot1)
; draw(plot2)
 frame(wks)

end if ; PLOT




end

