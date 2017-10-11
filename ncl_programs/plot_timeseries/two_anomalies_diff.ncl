;================================================;
;  sh_var_fit_v_meas.ncl
;================================================;
;
;
;--------------------------------------------------
; This NCL plots modeled and measured CO anomalies
; with residuals.
;--- To use type:
;---             ncl sh_var_fit_v_meas.ncl
;
;                                       rrb 20170417
;--------------------------------------------------
;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"   
; ================================================;

begin

; =========================================
; USER DEFINED
; =========================================
 
  location = "WestSAmerica"
  location_title = "West South America"

  anom_file1 = systemfunc ("ls /IASI/home/buchholz/MOPITT_subset/V7/anomalies/"+location+"_V7T*.nc")
  anom_file2 = systemfunc ("ls /IASI/home/buchholz/MOPITT_subset/V7/anomalies/"+location+"_V7J*.nc")

  PLOT = True
    plottype = "x11"
      plottype@wkWidth  = 1500
      plottype@wkHeight = 800
      ;plottype@wkPaperWidthF  = 7.0 ;for pdf
      ;plottype@wkPaperHeightF = 20  ;for pdf
    plotname = "~/Documents/BB_variability/"+location+"_meas_v_mod"


; =========================================
; SET UP
; =========================================

  anom          = "MOPITT_CO_ANOMALY"
  timearray     = "time"

   print("***Reading MOPITT data at " + location)

; ----------------------------------------
; Load data 1
; ----------------------------------------
  ; read data from region
  fin = addfile(anom_file1, "r")            ; read in

    anom1_vals     = fin->$anom$
    mopitt_time    = fin->$timearray$         ;  YYYYMM
      plottime = yyyymm_to_yyyyfrac(mopitt_time,0.5)


; ----------------------------------------
; Load data 2
; ----------------------------------------
  ; read data from region
  fin_2 = addfile(anom_file2, "r")            ; read in

    anom2_vals     = fin_2->$anom$


; ----------------------------------------
; Calculate residual
; ----------------------------------------
  residual = anom1_vals - anom2_vals


; =========================================
; PLOT the timeseries
; =========================================
if (PLOT) then
  wks   = gsn_open_wks (plottype,plotname)         ; open workstation

  res                   = True                     ; plot mods desired
   res@gsnDraw          = False
   res@gsnFrame         = False
   res@tiMainString     = ""                       ; add title
   res@xyMarkLineModes  = "Markers"                ; choose which have markers
   res@gsnMaximize      = True
   
   res@vpWidthF         = 1
   res@vpHeightF        = 0.25
   res@trXMinF          = 2001
   res@trXMaxF          = 2017
   
   ;res@tmYRBorderOn     = False                    ; turn off right border
   ;res@tmYROn           = False                    ; no YR tick marks
   ;res@tmXTBorderOn     = False                    ; turn off top border
   ;res@tmXTOn           = False                    ; no XT tick marks
   ;res@tmXBBorderOn     = False                    ; turn off bottom border
   res@tmBorderThicknessF  = 4
   res@tmXBMajorThicknessF = 4
   res@tmYLMajorThicknessF = 4

    res@tmYLMajorOutwardLengthF = 0.0               ; draw tickmarks inward
    res@tmYLMinorOutwardLengthF = 0.0                 ; draw minor ticsk inward
    res@tmXBMajorOutwardLengthF = 0.0
    res@tmXBMinorOutwardLengthF = 0.0

   
   res@tmXBMode         = "Explicit"
   res@tmXBValues       = (/2005,2010,2015/)
   res@tmXBLabels       = (/"2005","2010","2015"/)
   res@tmXBLabelFontHeightF = 0.024
   res@tmYLLabelFontHeightF = 0.024
   
   res@trYMinF          = -7.1e17
   res@trYMaxF          = 12.5e17
   res@tmYLMode         = "Explicit"
   res@tmYLValues       = (/-5e17,0,5e17,10e17/)
   res@tmYLLabels       = (/"-5.0","0","5.0","10.0"/)

   res@tiYAxisString   = ""
   res@tiYAxisFontHeightF = 0.024

      
  res2 = res ; copy res up to here (want to avoid repeating anomaly colors)
  
  ;-----------------------------------
  ; Add in legend for measured
  ;-----------------------------------
    res2@pmLegendDisplayMode      = "Always"        ; turn on legend
    res2@lgPerimOn                = False           ; Turn off perimeter
    res2@pmLegendWidthF           = 0.10            ; Change width and
    res2@lgLabelFontHeightF       = 0.024
    res2@xyExplicitLegendLabels   = "V7T"
    res2@pmLegendOrthogonalPosF   = -1.22
    res2@pmLegendParallelPosF     = 0.76

  ;-----------------------------------
  ; Measured
  ;-----------------------------------
    res2@gsnLeftString            := "x 10~S2~17   molec cm~S2~-2"             ; Label Bar title
    res2@xyMarkers                = 16               ; choose type of marker  
    res2@xyMarkerColor            = "gray80"         ; Marker color
    res2@xyMarkerOpacityF         = 0.85
    res2@xyMarkerSizeF            = 0.02             ; Marker size (default 0.01)
    res2@tiYAxisString            = "CO Anomaly"
  plot1  = gsn_csm_xy (wks,plottime,anom1_vals,res2)  ; create plot

    ;-----------------------------------
    ; Add in legend for fit
    ;-----------------------------------
     res2@gsnLeftString            := ""             ; Label Bar title
     res2@xyExplicitLegendLabels   := "V7J"
     res2@pmLegendOrthogonalPosF   = -1.22
     res2@pmLegendParallelPosF     = 0.92
    ;-----------------------------------
    ; Fit
    ;-----------------------------------
     res2@xyMarkers               =  16            ; choose type of marker  
     res2@xyMarkerColor           = "darkorange2"  ; Marker color
     res2@xyMarkerOpacityF        = 0.75
     res2@xyMarkerSizeF           = 0.013          ; Marker size (default 0.01)

  plot2  = gsn_csm_xy (wks,plottime,anom2_vals,res2) ; create plot

    res2@xyMarkers                = 4               ; choose type of marker  
    res2@xyMarkerColor            = "darkorange4"         ; Marker color
    res2@xyMarkerThicknessF       = 4
  plot3  = gsn_csm_xy (wks,plottime,anom2_vals,res2)  ; create plot


   overlay(plot1,plot2)
   overlay(plot1,plot3)
  ;-----------------------------------
  ; add zero line to anomaly plot
  ;-----------------------------------
    plres = True
      plres@gsLineThicknessF      = 3
    dum1 = gsn_add_polyline(wks, plot1, (/2000,2019/), (/0,0/), plres)

  ;-----------------------------------
  ; Residual
  ;-----------------------------------
     res2@tmYLLabelsOn            = False
     res2@tmYRLabelsOn            = True
     res2@tiYAxisSide             = "Right"  
     res2@tmYRLabelJust           = "CenterRight"
     res2@tiYAxisString           = "Residual"
     res2@xyMarkers               :=  2             ; choose type of marker  
     res2@xyMarkerOpacityF        := 1
     res2@xyMarkerThicknessF      = 4
     res2@xyExplicitLegendLabels  := ""
     res2@xyMarkerColor           = "grey50"       ; Marker color
     res2@trYMinF                 = -1.5e17
     res2@trYMaxF                 = 1.5e17
     res2@tmYLValues             := (/-1.0e17,1.0e17/)
     res2@tmYLLabels             := (/"-1.0","1.0"/)
     res2@vpWidthF                = 1
     res2@vpHeightF               = 0.09
     res2@pmLegendDisplayMode      = "Never"        ; turn off legend
   plot4  = gsn_csm_xy (wks,plottime,residual,res2) ; create plot

  ;-----------------------------------
  ; add zero line to residual
  ;-----------------------------------
    dum2 = gsn_add_polyline(wks, plot4, (/2000,2019/), (/0,0/), plres)

  ;-----------------------------------
  ; Add in title
  ;-----------------------------------
   ;drawNDCGrid(wks)
   ; add station
    txres                   = True                     ; polyline mods desired
     txres@txFontHeightF    = 0.022                    ; font smaller. default big
     txres@txJust           = "CenterLeft"             ; font smaller. default big
     txres@txPerimOn        = True
     txres@txPerimThicknessF= 2.0
    gsn_text_ndc(wks,location_title,0.150,0.590,txres)
            
; ----------------------------------------
;  attach plots
; ----------------------------------------
  resa                     = True
  resb                     = True
  ;resa@gsnMaximize         = True         
  ;resb@gsnMaximize         = True
  resb@gsnAttachPlotsXAxis = True
  newplot = gsn_attach_plots(plot1,(/plot4/),resa,resb)

 draw(plot1)
 frame(wks)

end if

end
