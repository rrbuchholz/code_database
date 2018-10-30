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
 
  location = "CONTRAIL"
  location_title = "CONTRAIL no 1997"
  
  PLOT = True
    plottype = "x11"
      ;plottype@wkWidth  = 1500
      ;plottype@wkHeight = 800
      plottype@wkPaperWidthF  = 9 ;for pdf
      plottype@wkPaperHeightF = 20  ;for pdf
    plotname = "~/Documents/BB_variability/"+location+"_meas_v_mod"

  PREDICT = False
  TOP_THREE = False
; =========================================
; SET UP
; =========================================
  ;anom_loc = "~/Dropbox/Work/SH_CO_Variability/data/FittedResults/"
  anom_loc = "~/Dropbox/Work/CONTRAST_CO_Variability/model_output/"
  anom_file = location+"coanom.txt"

  ;fit_loc = "~/Dropbox/Work/SH_CO_Variability/data/FittedResults/"
  fit_loc = "~/Dropbox/Work/CONTRAST_CO_Variability/model_output/"
  fit_file = location+"no97fitted.txt"
  
; ----------------------------------------
; Load data 1
; ----------------------------------------
;---Read the values in as 1D, since we don't know rows and columns yet.
  lines  = asciiread(anom_loc+anom_file,-1,"string")
  delim  = ""
  ncols  = dimsizes(str_split(lines(1),delim))
  nlines = dimsizes(lines)          ; No header

;---Reshape as 2D array, and convert to float for ppm/ppb.
  fields = new((/nlines,ncols/),float)
   do nf=0,ncols-1                    ;Remember that fields start at 1, not 0.
     fields(:,nf) = tofloat(str_get_field(lines(0:),nf+1,delim)) 
   end do
   
   meas_anom = fields(:,0)

printVarSummary(meas_anom)

; ----------------------------------------
; Create date array
; ----------------------------------------
  ;yyyymm = yyyymm_time(2001,2016,"integer")
  yyyymm = yyyymm_time(1994,2016,"integer")
  yyyymm_select = new((dimsizes(yyyymm)/12*4), float)
   yyyymm_select(0:dimsizes(yyyymm_select)-1:4) = yyyymm(7:dimsizes(yyyymm)-1:12)
   yyyymm_select(1:dimsizes(yyyymm_select)-1:4) = yyyymm(8:dimsizes(yyyymm)-1:12)
   yyyymm_select(2:dimsizes(yyyymm_select)-1:4) = yyyymm(9:dimsizes(yyyymm)-1:12)
   yyyymm_select(3:dimsizes(yyyymm_select)-1:4) = yyyymm(10:dimsizes(yyyymm)-1:12)
  yearfrac = yyyymm_to_yyyyfrac(yyyymm_select,0)

;print(yyyymm_select)

; ----------------------------------------
; Load data 2
; ----------------------------------------
;---Read the values in as 1D, since we don't know rows and columns yet.
  linesII  = asciiread(fit_loc+fit_file,-1,"string")
  delim  = ""
  ncolsII  = dimsizes(str_split(linesII(1),delim))
  nlinesII = dimsizes(linesII)          ; No header

;---Reshape as 2D array, and convert to float for ppm/ppb.
  fieldsII = new((/nlinesII,ncolsII/),float)
   do nf=0,ncolsII-1                    ;Remember that fields start at 1, not 0.
     fieldsII(:,nf) = tofloat(str_get_field(linesII(0:),nf+1,delim)) 
   end do

   fit_anom = fieldsII(:,0)

if (PREDICT) then
  fit_file2 = location+"_2014_fitted.txt"
  fit_file3 = location+"_2014_pred.txt"

else if (TOP_THREE) then
  fit_file2 = location+"2fitted.txt"
  fit_file3 = location+"3fitted.txt"

end if
end if


if (PREDICT.or.TOP_THREE) then
  ;---Read in Fit #2 
  linesIII  = asciiread(fit_loc+fit_file2,-1,"string")
  delim  = ""
  nlinesIII = dimsizes(linesIII)          ; No header

  fit_anom_2 = new((dimsizes(fit_anom)),float)
  fit_anom_2(0:nlinesIII-1) = tofloat(linesIII)

  ;---Read in Fit #3
  linesIV  = asciiread(fit_loc+fit_file3,-1,"string")
  delim  = ""
  nlinesIV = dimsizes(linesIV)          ; No header

  fit_anom_3 = new((dimsizes(fit_anom)),float)
  fit_anom_3((dimsizes(fit_anom)-nlinesIV):(dimsizes(fit_anom)-1)) = tofloat(linesIV)

  data = new((/3,dimsizes(fit_anom)/), float)
  data(0,:) = fit_anom
  data(1,:) = fit_anom_2
  data(2,:) = fit_anom_3

end if


; ----------------------------------------
; Calculate residual
; ----------------------------------------
  residual = meas_anom - fit_anom


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
   res@trXMinF          = 1992
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
   res@tmXBValues       = (/1995,2000,2005,2010,2015/)
   res@tmXBLabels       = (/"1995","2000","2005","2010","2015"/)
   res@tmXBLabelFontHeightF = 0.032
   res@tmYLLabelFontHeightF = 0.032
   res@tiYAxisFontHeightF   = 0.032
   res@tiXAxisFontHeightF   = 0.032

   res@trYMinF          = -30.
   res@trYMaxF          = 100.  

   ;res@trYMinF          = -6.1e17
   ;res@trYMaxF          = 12.5e17
   ;res@tmYLMode         = "Explicit"
   ;res@tmYLValues       = (/-5e17,0,5e17,10e17/)
   ;res@tmYLLabels       = (/"-5.0","0","5.0","10.0"/)


   res@tiYAxisString   = ""

      
  res2 = res ; copy res up to here (want to avoid repeating anomaly colors)
  
  ;-----------------------------------
  ; Add in legend for measured
  ;-----------------------------------
    res2@pmLegendDisplayMode      = "Always"        ; turn on legend
    res2@lgPerimOn                = False           ; Turn off perimeter
    res2@pmLegendWidthF           = 0.10            ; Change width and
    res2@lgLabelFontHeightF       = 0.030
  if (PREDICT.or.TOP_THREE) then
    res2@xyExplicitLegendLabels   = "Measured anomaly"
    res2@pmLegendOrthogonalPosF   = -1.75
    res2@pmLegendParallelPosF     = 0.60
    res2@gsnLeftString            := "x 10~S2~17   molec cm~S2~-2  "             ; Label Bar title
    res2@gsnLeftStringFontHeightF = 0.030
  else
    ;res2@xyExplicitLegendLabels   = "Measured anomaly (x 10~S2~17   molec cm~S2~-2  )"
    res2@xyExplicitLegendLabels   = "Measured anomaly"
    res2@pmLegendOrthogonalPosF   = -1.5
    res2@pmLegendParallelPosF     = 0.83
    res2@gsnLeftString            := ""             ; Label Bar title
   end if

  ;-----------------------------------
  ; Measured
  ;-----------------------------------
    ;res2@gsnLeftString            := "x 10~S2~17   molec cm~S2~-2"             ; Label Bar title
    res2@xyMarkers                = 16               ; choose type of marker  
    res2@xyMarkerColor            = "gray70"         ; Marker color
    res2@xyMarkerOpacityF         = 0.85
    res2@xyMarkerSizeF            = 0.02             ; Marker size (default 0.01)
    res2@tiYAxisString            = "CO Anomaly"
    res2@tiXAxisString            = "Year"
  plot1  = gsn_csm_xy (wks,yearfrac,meas_anom,res2)  ; create plot


  if (PREDICT) then
    ;-----------------------------------
    ; Remove overplot of legend
    ;-----------------------------------
    ;res2@pmLegendDisplayMode      = "Never"        ; turn on legend
    ;-----------------------------------
    ; Add in legend for fit
    ;-----------------------------------
     res2@pmLegendDisplayMode      = "Always"        ; turn on legend
     res2@gsnLeftString            := ""             ; Label Bar title
     res2@xyExplicitLegendLabels   := (/ "Model predicted anomaly 2015-2016", "Model predicted anomaly to 2014"/)
     res2@pmLegendOrthogonalPosF   = -2.08
     res2@pmLegendParallelPosF     = 0.65

    ;-----------------------------------
    ; Fit
    ;-----------------------------------
     ; new tickmark
     filled_tri = NhlNewMarker(wks, "u", 34, 0.0, 0.0, 1.0, 1.0, 0.0)
     filled_tri2 = NhlNewMarker(wks, "u", 34, 0.0, 0.0, 1.0, 1.0, 180.0)

     res2@xyMarkLineModes         := (/"Markers","Markers"/)
     res2@xyMarkers               :=  (/filled_tri2,filled_tri/)    ; choose type of marker  
     res2@xyMarkerColors          := (/"mediumpurple2","darkorange2"/)  ; Marker color
     res2@xyMarkerOpacityF        = 0.75
     res2@xyMarkerSizeF           = 0.016          ; Marker size (default 0.01)

   plot2  = gsn_csm_xy (wks,yearfrac,data(2:1,:),res2) ; create plot

    ;-----------------------------------
    ; Outlines
    ;-----------------------------------
     res2@xyExplicitLegendLabels   := (/ "", ""/)
    res2@xyMarkers                := (/8,7/)               ; choose type of marker  
    res2@xyMarkerColors           := (/"mediumpurple4","darkorange4"/)         ; Marker color
    res2@xyMarkerThicknessF       = 4
     res2@xyMarkerOpacityF        = 1
     res2@xyMarkerSizeF           = 0.013          ; Marker size (default 0.01)
     res2@pmLegendOrthogonalPosF   = -2.07
     res2@pmLegendParallelPosF     = 0.318
   plot3  = gsn_csm_xy (wks,yearfrac,data(2:1,:),res2)  ; create plot

  else if (TOP_THREE) then
    ;-----------------------------------
    ; Remove overplot of legend
    ;-----------------------------------
    ;-----------------------------------
    ; Add in legend for fits
    ;-----------------------------------
     res2@pmLegendDisplayMode      = "Always"        ; turn on legend
     res2@gsnLeftString            := ""             ; Label Bar title
     res2@xyExplicitLegendLabels   := (/"Model 3","Model 2","Model 1" /)
     res2@pmLegendOrthogonalPosF   = -1.70
     res2@pmLegendParallelPosF     = 0.58

    ;-----------------------------------
    ; Fit
    ;-----------------------------------
     ; new tickmark
     filled_tri = NhlNewMarker(wks, "u", 34, 0.0, 0.0, 1.0, 1.0, 0.0)
     filled_tri2 = NhlNewMarker(wks, "u", 34, 0.0, 0.0, 1.0, 1.0, 180.0)
     filled_sq = NhlNewMarker(wks, "y", 35, 0.0, 0.0, 1.0, 1.0, 0.0)

     res2@xyMarkLineModes         := (/"Markers","Markers","Markers"/)
     res2@xyMarkers               :=  (/filled_sq,filled_tri,16/)    ; choose type of marker  
     res2@xyMarkerColors          := (/"limegreen","mediumpurple2","darkorange2"/)  ; Marker color
     res2@xyMarkerOpacityF        := (/0.75,0.75,0.75/)
     res2@xyMarkerSizes           := (/0.013,0.019,0.014/)         ; Marker size (default 0.01)

   plot2  = gsn_csm_xy (wks,yearfrac,data(2:0,:),res2) ; create plot

    ;-----------------------------------
    ; Outlines
    ;-----------------------------------
    res2@xyMarkers                := (/6,7,4/)               ; choose type of marker  
    res2@xyMarkerColors           := (/"darkgreen","mediumpurple4","darkorange4"/)         ; Marker color
    res2@xyMarkerThicknessF       = 4
     ;res2@xyMarkerOpacityF        := (/1,1,1/)
     res2@xyMarkerSizes           := (/0.014,0.015,0.013/)    ; Marker size (default 0.01)
   plot3  = gsn_csm_xy (wks,yearfrac,data(2:0,:),res2)  ; create plot

  else
    ;-----------------------------------
    ; Add in legend for fit
    ;-----------------------------------
     res2@gsnLeftString            := ""             ; Label Bar title
     ;res2@xyExplicitLegendLabels   := "Model predicted anomaly (x 10~S2~17   molec cm~S2~-2  )"
     res2@xyExplicitLegendLabels   := "Model predicted anomaly"
     res2@pmLegendOrthogonalPosF   = -1.7
     res2@pmLegendParallelPosF     = 0.82
    ;-----------------------------------
    ; Fit
    ;-----------------------------------
     res2@xyMarkers               =  16            ; choose type of marker  
     res2@xyMarkerColor           = "darkorange2"  ; Marker color
     res2@xyMarkerOpacityF        = 0.75
     res2@xyMarkerSizeF           = 0.013          ; Marker size (default 0.01)

   plot2  = gsn_csm_xy (wks,yearfrac,fit_anom,res2) ; create plot

    res2@xyMarkers                = 4               ; choose type of marker  
    res2@xyMarkerColor            = "darkorange4"         ; Marker color
    res2@xyMarkerThicknessF       = 4
    res2@xyExplicitLegendLabels   := ""
     res2@pmLegendParallelPosF     = 0.590
  plot3  = gsn_csm_xy (wks,yearfrac,fit_anom,res2)  ; create plot

  end if
  end if

   overlay(plot1,plot2)
   overlay(plot1,plot3)
  ;-----------------------------------
  ; add zero line to anomaly plot
  ;-----------------------------------
    plres = True
      plres@gsLineThicknessF      = 3
    dum1 = gsn_add_polyline(wks, plot1, (/1990,2019/), (/0,0/), plres)

  ;-----------------------------------
  ; Residual
  ;-----------------------------------
     res2@pmLegendDisplayMode     = "Never"        ; turn off legend
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
     res2@trYMinF          = -10.
     res2@trYMaxF          = 10. 
     ;res2@trYMinF                 = -4.5e17
     ;res2@trYMaxF                 = 5e17
     ;res2@tmYLValues             := (/-2.5e17,2.5e17/)
     ;res2@tmYLLabels             := (/"-2.5","2.5"/)
     res2@vpWidthF                = 1
     res2@vpHeightF               = 0.09
   plot4  = gsn_csm_xy (wks,yearfrac,residual,res2) ; create plot

  ;-----------------------------------
  ; add zero line to residual
  ;-----------------------------------
    dum2 = gsn_add_polyline(wks, plot4, (/1990,2019/), (/0,0/), plres)

  ;-----------------------------------
  ; Add in title
  ;-----------------------------------
   ;drawNDCGrid(wks)
   ; add station
    txres                   = True                     ; polyline mods desired
     txres@txJust           = "CenterLeft"             ; font smaller. default big
     txres@txPerimOn        = True
     txres@txPerimSpaceF    = 0.3
     txres@txPerimThicknessF= 2.0
  if (PREDICT.or.TOP_THREE) then
     txres@txFontHeightF    = 0.024                  ; font smaller. default big
    gsn_text_ndc(wks,location_title,0.190,0.575,txres)
  else
     txres@txFontHeightF    = 0.022                    ; font smaller. default big
    gsn_text_ndc(wks,location_title,0.175,0.675,txres)
  end if
            
; ----------------------------------------
;  attach plots
; ----------------------------------------

  if (PREDICT.or.TOP_THREE) then
    ; no residual
  else
  resa                     = True
    resa@tiYAxisFontHeightF    = 0.026
  resb                     = True
    resb@tiYAxisFontHeightF    = 0.026
    resb@tiXAxisFontHeightF    = 0.026
  ;resa@gsnMaximize         = True    
  ;resb@gsnMaximize         = True
  resb@gsnAttachPlotsXAxis = True
  newplot = gsn_attach_plots(plot1,(/plot4/),resa,resb)
  end if

 draw(plot1)
 frame(wks)

end if

end
