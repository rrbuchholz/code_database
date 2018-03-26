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
     x2min                 = -0.05
     x2max                 = 2e19

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
  sat_ap        = "APrioriCOMixingRatioProfile_MOP02"
  sat_ap_surf   = "APrioriCOSurfaceMixingRatio_MOP02"
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

  anom_diag      := fin->$diag_1$(day_retrievals,:)
  ak_col         := fin->$col_avker$(day_retrievals,:)
  psurf          := fin->$sat_psurf$(day_retrievals)

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

printVarSummary(psurf)
printVarSummary(high_psurf_ak)
printVarSummary(low_psurf_ak)


  ;--------------------------------------------
  ; calculate tcol AK from ak matrix
  ;--------------------------------------------


;************************************************
; Setting up profile plot
;************************************************
 if (PLOTPROFILE) then
  wks  = gsn_open_wks(plot2Type,plot2Name)            ; open a workstation

  ;-----------------------------------
  ; define resources to use for plotting
  ;-----------------------------------
  res2 = True
    res2@gsnFrame                 = False          ; don't advance frame
    ; Set axes limits
    ;res2@trYMaxF                  = y2max
    ;res2@trYMinF                  = y2min
    ;res2@trXMaxF                  = x2max
    ;res2@trXMinF                  = x2min
    res2@xyMarkLineMode           = "Lines"       ; Markers *and* lines
    res2@xyMarkers                = 9             ; marker style
    res2@xyMarkerSizeF            = 0.015
    res2@xyLineThicknessF         = 3
    ;res2@vpWidthF                 = 0.5
    ;res2@vpHeightF                = 0.4 

    ;res2@trYLog                   = True           ; convert axes to logaritmic\
    ;res2@trXLog                   = False           ; convert axes to logaritmic
    res2@trYReverse               = True 
    res2@tmXTOn                   = False          ; turn off tickmarks
    res2@tmYROn                   = False
    ;res2@tmXTBorderOn             = False          ; turn off outline
    ;res2@tmYRBorderOn             = False
    res2@tmXBMode                 = "Manual"	
    res2@tmXBTickStartF           = 0
    res2@tmXBTickEndF             = x2max
    ;res2@tmXBTickSpacingF         = 0.5

    ;res2@tmYLMode                 = "Explicit"
    ;res2@tmYLValues               = (/100,300,500,700,1000/)
    ;res2@tmYLLabels               = "" + res2@tmYLValues

    ;res2@pmLegendDisplayMode      = "Always"        ; turn on legend
    ;res2@lgAutoManage             = False           ; turn off auto-manage
    ;res2@pmLegendSide             = "top"           ; Change location of 
    ;res2@lgPerimOn                = False           ; turn off box around
    ;res2@pmLegendParallelPosF     = 0.9             ; move units right
    ;res2@pmLegendOrthogonalPosF   = -0.4            ; move units down
    ;res2@pmLegendWidthF           = 0.2             ; Change width and
    ;res2@pmLegendHeightF          = 0.3             ; height of legend
    ;res2@lgLabelFontHeightF       = 0.01
    ;res2@lgLabelJust              = "Right"


    res2@tiMainString             ="MOPITT "+version+" Averaging Kernels"
    res2@tiYAxisString            ="Altitude (hPa)"
    res2@tiXAxisString            ="AK value"

    res2@tfPolyDrawOrder          = "Predraw"       ; line on top
  ;-----------------------------------
  ; end define resources
  ;-----------------------------------

  ;-----------------------------------
  ; Draw different AKs
  ;-----------------------------------
  ; 1
  pvect2 = (/1000.,900.,800.,700.,600.,500.,400.,300.,200.,100./)
    res2@xyExplicitLegendLabels = "MOPITT AK "+version+ " (norm)"   ; create explicit labels
    res2@xyLineColors            = "red"
    res2@xyMarkerColors          = "red"
    res2@pmLegendOrthogonalPosF  = -0.5            ; move units down
  plot = gsn_csm_xy(wks,  low_psurf_ak(0:10,:), pvect2, res2)

  ; 2
    res2@xyLineColors            = "blue"
    res2@xyMarkerColors          = "blue" 
    res2@xyExplicitLegendLabels  = "FTS AK"      ; create explicit labels
    res2@pmLegendOrthogonalPosF  = -0.95            ; move units down
    res2@xyMarkers               = 7             ; marker style

  plot = gsn_csm_xy(wks,  high_psurf_ak(0:10,:), pvect2, res2)


  ; Draw background vertical grid
  ;mopittres = True
  ;  mopittres@gsLineThicknessF        = 1
  ;  mopittres@gsLineDashPattern       = 1
  ;  mopittres@gsLineColor             = "grey"

  ;dummy_alt = new(10, graphic)
  ;do i = 0, 9
  ;  dummy_alt(i) = gsn_add_polyline(wks, plot, (/x2min,x2max/), (/mean_levs(i), \
  ;                 mean_levs(i)/), mopittres)
  ;end do


  ;-----------------------------------
  ; Now draw plot
  ;-----------------------------------
  draw(plot)
  frame(wks)
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

   test = ind(dp(:,0).le.0)

   parray = where(dp.le.0,parray@_FillValue,parray)
   parray = where((dp.le.100 .and. dp.ge.0),psurfarray,parray)

  ; Repeat surface apriori values at all levels to replace if needed
  apsurfarray = new((/dimsizes(psurf), 10/), float) 
   do z= 0, 9, 1
    apsurfarray(:,z) = (apriori(:,0))
   end do
   apriori = where(dp.le.0,apriori@_FillValue,apriori) ; re-order apriori array
   apriori = where((dp.le.100 .and. dp.ge.0),apsurfarray,apriori)

  ; FTS values are averages for the whole box, 
  ; centred at an altitude while MOPITT values are averages described for box above level.
  pinterp = new((/dimsizes(psurf), 10/), double)
  do z=0,8,1
    pinterp(:,z) = parray(:,z) - (parray(:,z)-parray(:,z+1))/2
  end do
  pinterp(:,9) = 87.


      ;--------------------------------------------
      ; Apply AK to FTS
      ; note AK applies to log(vmr) values
      ;--------------------------------------------
      logfts = log10(fts_interp)
        ;logfts = where(ismissing(logfts),0,logfts)
      logap = log10(apriori(mopitt_comp,:))
        ;logap = where(ismissing(logap),0,logap)

      logfts_ak = new((/10/), float)
      print("Convolving with averaging kernel. . .") ; AK calculations
         ak = (/AvKer(mopitt_comp,:,:)/)
         ; missing values -> zero for array calculations
         ak  = where(ismissing(ak),0,ak)  
         logap  = where(ismissing(logap),0,logap)       
         logfts  = where(ismissing(logfts),0,logfts)
         ; calculate         
         logfts_ak = logap + transpose(ak) # (logfts - logap)
         ;logfts_ak_1 = transpose(ak) # (logfts - logap)
       print(". . . Done!")
       ; change zero back to missing values for plotting etc
       logfts_ak = where(logfts_ak.eq.0,logfts_ak@_FillValue, logfts_ak)
       ;logfts_ak = where(logfts_ak_1.eq.0,logfts_ak_1@_FillValue, logfts_ak_1)
       ; change back to vmr
       fts_ak = 10^logfts_ak
       ;fts_ak = 10^logfts_ak

      ;--------------------------------------------
      ; Pressure difference array
      ;--------------------------------------------
      ; MOPITT pressures are level edges.
      ; see V5 User Guide for more info
      delta_p = new((/10/), float)
      do z= 0, 8, 1
         delta_p(z) = parray(mopitt_comp,z)-parray(mopitt_comp,z+1)
      end do
      delta_p(9) = 74   ; 26 top level
      ;delta_p(9) = 67  ; 33 top level
      ;delta_p(9) = 100  ; 0 top level


      ;--------------------------------------------
      ; Calculate tcol AK
      ;--------------------------------------------
      log10e = log10(exp(1.))
      ap = apriori(mopitt_comp,:)
      ap  = where(ismissing(ap),0,ap)  
      prof = mopitt_profile(mopitt_comp,:)
      prof  = where(ismissing(prof),0,prof)
      prof2 = mopitt_profile_2(mopitt_comp,:) 
      prof2  = where(ismissing(prof2),0,prof2)
      prof3 = mopitt_profile_3(mopitt_comp,:) 
      prof3  = where(ismissing(prof3),0,prof3)
      ak_colm = (xp_const/log10e)*((prof # transpose(ak)))
      ak2 = (/AvKer2(mopitt_comp,:,:)/)
      ak_colm_2 = (xp_const/log10e)*((prof2 # transpose(ak2)))
      ak3 = (/AvKer3(mopitt_comp,:,:)/)
      ak_colm_3 = (xp_const/log10e)*((prof3 # transpose(ak3)))

      ; apply to FTS column
      ; produces partial columns
      fts_ak_2 =ak_colm # transpose(logfts - logap)



;--------------------------------------------
; convert time
;--------------------------------------------
time_frac = cd_calendar(time_to_plot, 4)

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

