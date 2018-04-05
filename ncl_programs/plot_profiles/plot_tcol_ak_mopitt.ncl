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
  version = "V7T"
  ret = "T"
  YYYY = 2014
  MM = 09
  DD = 25
  mopitt_general = systemfunc ("ls /MOPITT/"+version+"/Archive/L2/"+YYYY+sprintf("%02.4g", MM)+\
                                "/"+sprintf("%02.4g", MM)+sprintf("%02.4g", DD)+"/MOP02"+ret+"-*.he5")

  ;mopitt_general =  systemfunc ("ls /MOPITT/VALIDATION/ArchiveTW/L2-HIPPO10_MT_CKD_3.2/"+\
  ;                              YYYY+sprintf("%02.4g", MM)+"/"+sprintf("%02.4g", MM)+\
  ;                              sprintf("%02.4g", DD)+"/MOP02"+ret+"-*.he5")


  ;------------
  ; toggles
  ;------------
  PLOTPROFILE       = True
    plot2Type       = "x11"

  REPROCESSED       = True
   if (REPROCESSED) then
     mopitt_new = systemfunc ("ls /MOPITT/VALIDATION/ArchiveTW/L2-HIPPO10_MT_CKD_3.2/"+\
                                YYYY+sprintf("%02.4g", MM)+"/"+sprintf("%02.4g", MM)+\
                                sprintf("%02.4g", DD)+"/MOP02"+ret+"-*.he5")
   end if 

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
  clouds        = "CloudDescription"+suff

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
      cloud_diag   := fin->$clouds$


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
                 anom_diag(:,4).eq.0);.and.\
                 ;cloud_diag.eq.2)


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

   if (REPROCESSED) then
     fin_2 = addfile(mopitt_new, "r")            ;--- read in
      sza_2         := fin_2->$solarza$
      lon_2         := fin_2->$longitude$
      lat_2         := fin_2->$latitude$
      anom_diag_2   := fin_2->$diag_1$
      cloud_diag_2   := fin_2->$clouds$


    ;--------------------------------------------
    ; select daytime retrievals
    ; within a boundary
    ; and quality controlled
    ;--------------------------------------------
    day_retrievals_2 := ind(sza_2.le.dayflag.and.\
                 lat_2.le.topboundary.and.\
                 lat_2.ge.bottomboundary.and.\
                 lon_2.ge.leftboundary.and.\
                 lon_2.le.rightboundary.and.\
                 anom_diag_2(:,0).eq.0.and.\
                 anom_diag_2(:,1).eq.0.and.\
                 anom_diag_2(:,2).eq.0.and.\
                 anom_diag_2(:,3).eq.0.and.\
                 anom_diag_2(:,4).eq.0);.and.\
                 ;cloud_diag_2.eq.2)

    time_2         := fin_2->$date$(day_retrievals_2)  ;--- time in seconds since 1993-1-1 00:00:00 (TAI93)
    lat_2          := lat_2(day_retrievals_2)
    lon_2          := lon_2(day_retrievals_2)
    ak_colm := fin_2->$col_avker$(day_retrievals_2,:)
    psurf_2 := fin_2->$sat_psurf$(day_retrievals_2)

   else
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
    do i = 0, dimsizes(psurf)-1
      do z = 0, 9 
       multiply_ak := (xp_const/log10e)*(delta_p(i,:)*prof_dummy(i,:)) * (ak(i,z,:))
       ak_colm(i,z) = sum(multiply_ak)
      end do
    end do

  ak_colm  = where(ak_colm.eq.0,ak_colm@_FillValue,ak_colm)

  lowak_col = ak_colm(ind_low_press, :)
  highak_col = ak_colm(ind_high_press, :)

  end if

    ak_colm  = where(ak_colm.eq.0,ak_colm@_FillValue,ak_colm)

    lowak_col = ak_colm(ind_low_press, :)
    highak_col = ak_colm(ind_high_press, :)


  ;--------------------------------------------
  ; print for analysis
  ;--------------------------------------------
printVarSummary(ak_col)
printVarSummary(low_psurf_ak)
printVarSummary(high_psurf_ak)
  low_psurf_ak  = where(ismissing(low_psurf_ak),0,low_psurf_ak)
  high_psurf_ak  = where(ismissing(high_psurf_ak),0,high_psurf_ak)
  lowak_col  = where(ismissing(lowak_col),0,lowak_col)
  highak_col  = where(ismissing(highak_col),0,highak_col)

  ind_low_reported = ind(low_psurf_ak(:,0).lt.0.or.low_psurf_ak(:,1).lt.0.or.\
                         low_psurf_ak(:,2).lt.0.or.low_psurf_ak(:,3).lt.0.or.\
                         low_psurf_ak(:,4).lt.0.or.low_psurf_ak(:,5).lt.0.or.\
                         low_psurf_ak(:,6).lt.0.or.low_psurf_ak(:,7).lt.0.or.\
                         low_psurf_ak(:,8).lt.0.or.low_psurf_ak(:,9).lt.0)

  ind_low_reported_b = ind(low_psurf_ak(:,0).ge.0.and.low_psurf_ak(:,1).ge.0.and.\
                         low_psurf_ak(:,2).ge.0.and.low_psurf_ak(:,3).ge.0.and.\
                         low_psurf_ak(:,4).ge.0.and.low_psurf_ak(:,5).ge.0.and.\
                         low_psurf_ak(:,6).ge.0.and.low_psurf_ak(:,7).ge.0.and.\
                         low_psurf_ak(:,8).ge.0.and.low_psurf_ak(:,9).ge.0)

  ind_high_reported = ind(high_psurf_ak(:,0).lt.0.or.high_psurf_ak(:,1).lt.0.or.\
                         high_psurf_ak(:,2).lt.0.or.high_psurf_ak(:,3).lt.0.or.\
                         high_psurf_ak(:,4).lt.0.or.high_psurf_ak(:,5).lt.0.or.\
                         high_psurf_ak(:,6).lt.0.or.high_psurf_ak(:,7).lt.0.or.\
                         high_psurf_ak(:,8).lt.0.or.high_psurf_ak(:,9).lt.0)

  ind_high_reported_b = ind(high_psurf_ak(:,0).ge.0.and.high_psurf_ak(:,1).ge.0.and.\
                         high_psurf_ak(:,2).ge.0.and.high_psurf_ak(:,3).ge.0.and.\
                         high_psurf_ak(:,4).ge.0.and.high_psurf_ak(:,5).ge.0.and.\
                         high_psurf_ak(:,6).ge.0.and.high_psurf_ak(:,7).ge.0.and.\
                         high_psurf_ak(:,8).ge.0.and.high_psurf_ak(:,9).ge.0)

  ind_low_retrieved= ind(lowak_col(:,0).lt.0.or.lowak_col(:,1).lt.0.or.\
                         lowak_col(:,2).lt.0.or.lowak_col(:,3).lt.0.or.\
                         lowak_col(:,4).lt.0.or.lowak_col(:,5).lt.0.or.\
                         lowak_col(:,6).lt.0.or.lowak_col(:,7).lt.0.or.\
                         lowak_col(:,8).lt.0.or.lowak_col(:,9).lt.0)

  ind_high_retrieved = ind(highak_col(:,0).lt.0.or.highak_col(:,1).lt.0.or.\
                         highak_col(:,2).lt.0.or.highak_col(:,3).lt.0.or.\
                         highak_col(:,4).lt.0.or.highak_col(:,5).lt.0.or.\
                         highak_col(:,6).lt.0.or.highak_col(:,7).lt.0.or.\
                         highak_col(:,8).lt.0.or.highak_col(:,9).lt.0)

printVarSummary(ind_low_reported)
printVarSummary(ind_high_reported)
printVarSummary(ind_low_reported_b)
printVarSummary(ind_high_reported_b)
;print(low_psurf_ak(ind_low_reported_b,:))
printVarSummary(ind_low_retrieved)
print(ind_low_retrieved)
;print(lowak_col(ind_low_reported_b,:))
printVarSummary(ind_high_retrieved)

  low_psurf_ak  = where(low_psurf_ak.eq.0,low_psurf_ak@_FillValue,low_psurf_ak)
  high_psurf_ak  = where(high_psurf_ak.eq.0,high_psurf_ak@_FillValue,high_psurf_ak)
  lowak_col  = where(lowak_col.eq.0,lowak_col@_FillValue,lowak_col)
  highak_col  = where(highak_col.eq.0,highak_col@_FillValue,highak_col)

;exit

  ;--------------------------------------------
  ; difference retrieved versus calculated column AKs
  ;--------------------------------------------
printVarSummary(ak_colm)
printVarSummary(ak_col)

  if (REPROCESSED) then
      lowdiff_collect = new((/3, 20, dimsizes(ak_col(0, :))/), float)
      time_compare_low = time(ind_low_press)
      lat_compare_low = lat(ind_low_press)
      lon_compare_low = lon(ind_low_press)

      highdiff_collect  = new((/3, 20, dimsizes(ak_col(0, :))/), float)
      time_compare_high = time(ind_high_press)
      lat_compare_high = lat(ind_high_press)
      lon_compare_high = lon(ind_high_press)


      do j = 0,19
          ind_compare_low = ind(time_2.eq.time_compare_low(j).and.\
                                lat_2.eq.lat_compare_low(j).and.\
                                lon_2.eq.lon_compare_low(j))
print(ind_compare_low)
          lowdiff_collect(0,j,:) = low_psurf_ak(j,:)
          lowdiff_collect(1,j,:) = ak_colm(ind_compare_low,:)
          lowdiff_collect(2,j,:) = low_psurf_ak(j,:)-ak_colm(ind_compare_low,:)

          ind_compare_high = ind(time_2.eq.time_compare_high(j).and.\
                                lat_2.eq.lat_compare_high(j).and.\
                                lon_2.eq.lon_compare_high(j))
          highdiff_collect(0,j,:) = high_psurf_ak(j,:)
          highdiff_collect(1,j,:) = ak_colm(ind_compare_high,:)
          highdiff_collect(2,j,:) = high_psurf_ak(j,:)-ak_colm(ind_compare_high,:)
      end do

  print(lowdiff_collect(:,0,:))
  print(highdiff_collect(:,0,:))

      low_psurf_ak := lowdiff_collect(0,:,:)
      lowak_col := lowdiff_collect(1,:,:)
      lowdiff_ak = lowdiff_collect(2,:,:)

      high_psurf_ak := highdiff_collect(0,:,:)
      highak_col := highdiff_collect(1,:,:)
      highdiff_ak = highdiff_collect(2,:,:)

printVarSummary(lowdiff_ak)


  else
    diff_ak = ak_col-ak_colm
      lowdiff_ak = diff_ak(ind_low_press, :)
      highdiff_ak = diff_ak(ind_high_press, :)
   end if



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
    res2@tiXAxisString            ="AK value (~F34~4~F21~10~S2~19   mol/(cm~S2~2   log(VMR))) "
    low_cols                    := new(dimsizes(low_psurf_ak(:,0)), "string")
    low_cols                    = "red"
    res2@xyLineColors           := low_cols
    res2@xyMarkerColors         := low_cols
  plot1 = gsn_csm_xy(wks,  low_psurf_ak(0:9,:)/1e19, pvect2, res2)

  ; 1a Psurf < 900 hPa, but calculated here
    low_cols                    := new(dimsizes(lowak_col(:,0)), "string")
    low_cols                    = "orange"
    res2@xyLineColors           := low_cols
    res2@xyMarkerColors         := low_cols
  plot1a = gsn_csm_xy(wks,  lowak_col(0:9,:)/1e19, pvect2, res2)
  overlay(plot1, plot1a)

  ; 1b Psurf > 900 hPa
    high_cols                   := new(dimsizes(high_psurf_ak(:,0)), "string")
    high_cols                    = "blue"
    res2@xyLineColors           := high_cols
    res2@xyMarkerColors         := high_cols
  plot1b = gsn_csm_xy(wks,  high_psurf_ak(0:9,:)/1e19, pvect2, res2)
  overlay(plot1, plot1b)

  ; 1a Psurf > 900 hPa, but calculated here

    high_cols                   := new(dimsizes(highak_col(:,0)), "string")
    high_cols                    = "darkgreen"
    res2@xyLineColors           := high_cols
    res2@xyMarkerColors         := high_cols
  plot1c = gsn_csm_xy(wks,  highak_col(0:9,:)/1e19, pvect2, res2)
  overlay(plot1, plot1c)

  ; 2 Difference
    res2@tiMainString            ="Difference: retrieved -- calculated"
    res2@tiYAxisString           =""
    res2@tiXAxisString           ="Difference (~F34~4~F21~10~S2~19   mol/(cm~S2~2   log(VMR))) "
    diff_cols                   := new(dimsizes(ak_colm(:,0)), "string")
    diff_cols                    = "black"
    res2@xyLineColors           := diff_cols
    res2@xyMarkerColors         := diff_cols
  plot2 = gsn_csm_xy(wks,  lowdiff_ak(0:9,:)/1e19, pvect2, res2)
    diff_cols                    = "purple"
    res2@xyLineColors           := diff_cols
    res2@xyMarkerColors         := diff_cols
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
  dummy_alt2 = new(10, graphic)
  do i = 0, 9
    dummy_alt(i) = gsn_add_polyline(wks, plot1, (/x2min,x2max/), (/pvect2(i), \
                   pvect2(i)/), mopittres)
    dummy_alt2(i) = gsn_add_polyline(wks, plot2, (/x2min,x2max/), (/pvect2(i), \
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
     ;Recalculated
    ;gsn_text_ndc(wks,"V7 Psurf < 900 hPa, recalculated",0.12,0.71,txres)
     txres@txFontColor      = "darkgreen"
    ;gsn_text_ndc(wks,"V7 Psurf > 900 hPa, recalculated",0.12,0.69,txres)
     txres@txFontColor      = "red"
    gsn_text_ndc(wks,"V7 Psurf < 900 hPa",0.12,0.67,txres)
     txres@txFontColor      = "blue"
    gsn_text_ndc(wks,"V7 Psurf > 900 hPa",0.12,0.65,txres)

    ;Orig
     txres@txFontColor      = "red"
    ;gsn_text_ndc(wks,"V7 Psurf < 900 hPa",0.22,0.75,txres)
     txres@txFontColor      = "blue"
    ;gsn_text_ndc(wks,"V7 Psurf > 900 hPa",0.22,0.73,txres)

    ; Test V8
     txres@txFontColor      = "orange"
    gsn_text_ndc(wks,"V8 Psurf < 900 hPa, recalculated",0.12,0.71,txres)
     txres@txFontColor      = "darkgreen"
    gsn_text_ndc(wks,"V8 Psurf > 900 hPa, recalculated",0.12,0.69,txres)

   ; difference plot labels
     txres@txFontColor      = "black"
     gsn_text_ndc(wks,"Psurf < 900 hPa",0.62,0.71,txres)
     txres@txFontColor      = "purple"
     gsn_text_ndc(wks,"Psurf > 900 hPa",0.62,0.69,txres)

  ;-----------------------------------
  ; Now draw plot
  ;-----------------------------------
  ;draw(plot1)
  ;frame(wks)

  ;-------------------
  ; do the plotting
  ;-------------------
  panel_res                       = True
      panel_res@txString              = "MOPITT "+version+" Averaging Kernels, for the first 10 retrievals in each set ~C~"+ \
                                         "within "+ delta_deg+" deg around "+ "Lat: "+location_lat+", Lon: "+ location_lon +\
                                         ", Date: "+YYYY +sprintf("%02.4g", MM)+sprintf("%02.4g", DD)

   gsn_panel(wks,(/plot1,plot2/),(/1,2/),panel_res)

  ;draw(plot1)
  ;frame(wks)

  end if    ; PLOTPROFILE



end

