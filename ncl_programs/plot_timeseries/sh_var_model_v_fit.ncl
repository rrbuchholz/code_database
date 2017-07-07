;================================================;
;  sh_var_model_v_fit.ncl
;================================================;
;
;
;--------------------------------------------------
; This NCL plots modeled and measured CO anomalies
; with residuals.
;--- To use type:
;---             ncl sh_var_model_v_fit.ncl
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

; ===================
; USER DEFINED
; ===================
 
  location = "SouthAustralasia"
  location_title = "South Australasia"
  
  PLOT = True
    plottype = "png"
      plottype@wkWidth  = 2200
      plottype@wkHeight = 2200
    plotname = location+"_meas_v_mod"

; ===================
; SET UP
; ===================
  fili = location+"_meas_n_fit.csv"           ; file
  
  anom_loc = "/Users/Rebecca/Dropbox/Work/SH_CO_Variability/data/CO_spline_fit_filled_to_2017/"
  anom_file = location+"_V7TMOPITTanomalies.csv"
  
; ========================================
; Load data 1
; ========================================
;---Read the values in as 1D, since we don't know rows and columns yet.
  lines  = asciiread(fili,-1,"string")
  header = lines(0)
  delim  = ","
  ncols  = dimsizes(str_split(lines(1),delim))
  nlines = dimsizes(lines)-1          ; First lines is a header

;---Reshape as 2D array, and convert to float for ppm/ppb.
  fields = new((/nlines,ncols/),float)
   do nf=0,ncols-1                    ;Remember that fields start at 1, not 0.
     fields(:,nf) = tofloat(str_get_field(lines(1:),nf+1,delim)) 
   end do
   
   yyyymm = fields(:,0)
   model_anom = fields(:,1)
   meas_anom = fields(:,2)
   
   split_data = new((/2,dimsizes(meas_anom)/),float)
   split_data(0,:) = where(meas_anom.gt.0,meas_anom,meas_anom@_FillValue)
   split_data(1,:) = where(meas_anom.lt.0,meas_anom,meas_anom@_FillValue)


; ========================================
; Load data 2
; ========================================   
;---Read the values in as 1D, since we don't know rows and columns yet.
  linesII  = asciiread(anom_loc+anom_file,-1,"string")
  headerII = lines(0)
  delim  = ","
  ncolsII  = dimsizes(str_split(linesII(1),delim))
  nlinesII = dimsizes(linesII)-1          ; First lines is a header

;---Reshape as 2D array, and convert to float for ppm/ppb.
  fieldsII = new((/nlinesII,ncolsII/),float)
   do nf=0,ncolsII-1                    ;Remember that fields start at 1, not 0.
     fieldsII(:,nf) = tofloat(str_get_field(linesII(1:),nf+1,delim)) 
   end do

   yyyymmII = fieldsII(:,0)
   meas_anom_all = fieldsII(:,2)
   data = new((/3,dimsizes(meas_anom_all)/),float)
   data(0,:) = where(meas_anom_all.gt.0,meas_anom_all,0)
   data(1,:) = meas_anom_all*0
   data(2,:) = where(meas_anom_all.lt.0,meas_anom_all,0)
   
  
; ========================================
; Create date array
; ========================================
  yearfrac = yyyymm_to_yyyyfrac(yyyymm,0)
  yearfracII = yyyymm_to_yyyyfrac(yyyymmII,0)


; ========================================
; Calculate residual
; ========================================
  residual = meas_anom - model_anom

; ========================================
; PLOT the timeseries
; ========================================
if (PLOT) then
  wks   = gsn_open_wks (plottype,plotname)         ; open workstation

  res                   = True                     ; plot mods desired
   res@gsnDraw          = False
   res@gsnFrame         = False
   res@tiMainString     = ""                       ; add title
   res@xyMarkLineModes  = "Lines"                  ; choose which have markers
   res@xyLineThicknessF = 5                     ; Marker size (default 0.01)
   res@xyDashPattern  = 0                         ; Make curves all solid
   res@xyLineColors      = (/"red","black","blue"/)          ; change line color
   res@xyMarkers        =  16                      ; choose type of marker  
   res@xyMarkerColor    = "black"                  ; Marker color
   res@xyMarkerSizeF    = 0.02                     ; Marker size (default 0.01)
   
   res@vpWidthF         = 0.8
   res@vpHeightF        = 0.2
   res@trXMinF          = 2001
   res@trXMaxF          = 2017
   res@trYMinF          = -5.2e17
   res@trYMaxF          = 5.2e17
   
   res@tmYRBorderOn     = False                    ; turn off right border
   res@tmYROn           = False                    ; no YR tick marks
   res@tmXTBorderOn     = False                    ; turn off top border
   res@tmXTOn           = False                    ; no XT tick marks
   res@tmXBBorderOn     = False                    ; turn off bottom border
   res@tmBorderThicknessF = 5
   res@tmXBMajorThicknessF = 5
   res@tmYLMajorThicknessF = 5
   
   res@tmXBMode         = "Explicit"
   res@tmXBValues       = (/2005,2010,2015/)
   res@tmXBLabels       = (/"2005","2010","2015"/)
   res@tmXBLabelFontHeightF = 0.024
   res@tmYLLabelFontHeightF = 0.024
   
   res@tmYLMode         = "Manual"
   res@tmYLTickStartF   = -5e17
   res@tmYLTickEndF     = 5e17
   res@tmYLTickSpacingF = 5e17

   res@tiYAxisString   = "CO Anomaly"
   res@tiYAxisFontHeightF = 0.024
      
  res2 = res ; copy res up to here (want to avoid repeating anomaly colors)
  
  ;-----------------------------------
  ; Add in legend
  ;-----------------------------------
    res2@pmLegendDisplayMode      = "Always"        ; turn on legend
    res2@lgPerimOn                = False           ; Turn off perimeter
    res2@pmLegendWidthF           = 0.20           ; Change width and
    res2@lgLabelFontHeightF       = 0.024
    res2@xyExplicitLegendLabels   = "Measured anomaly"
    res2@pmLegendOrthogonalPosF   = 0.5

   res@gsnMaximize      = True
   res@gsnXYFillColors = (/"red","blue"/)
   res@gsnXYFillOpacities = (/0.3,0.3/)
 plot1  = gsn_csm_xy (wks,yearfracII,data,res) ; create plot

 ; res@xyLineColors      = (/"black","black","black"/)          ; change line color
 ; plot1 = gsn_csm_xy(wks, (/2000,2019/), (/0,0/), res)

   res2@vpHeightF         = 0.1
   res2@xyMarkerColor    = "red"                  ; Marker color
   res2@xyMarkerSizeF    = 0.009                  ; Marker size (default 0.01)
   res2@xyMarkLineModes  = "Markers"              ; choose which have markers

 plot2a  = gsn_csm_xy (wks,yearfrac,split_data(0,:),res2) ; create plot
 overlay(plot1,plot2a)
  res2@xyExplicitLegendLabels   = "Measured anomaly"
  res2@pmLegendOrthogonalPosF   = 0.3
  res2@xyMarkerColor    = "blue"                  ; Marker color
 plot2b  = gsn_csm_xy (wks,yearfrac,split_data(1,:),res2) ; create plot
 overlay(plot1,plot2b)

   res2@xyExplicitLegendLabels   = "Modeled anomaly"
   res2@pmLegendOrthogonalPosF   = 0.1
   res2@pmLegendParallelPosF   = 0.48
   res2@xyMarkerColor    = "black"                 ; Marker color
   res2@xyMarkerSizeF    = 0.011                    ; Marker size (default 0.01)
   res2@xyMarkers        =  16                     ; choose type of marker  

plot3  = gsn_csm_xy (wks,yearfrac,model_anom,res2) ; create plot
 overlay(plot1,plot3)

   res2@trYMinF          = -2.5e17
   res2@trYMaxF          = 2.5e17
 plot4  = gsn_csm_xy (wks,yearfrac,residual,res2) ; create plot
; add zero line to residual
    plres = True
    dum = gsn_add_polyline(wks, plot4, (/2000,2019/), (/0,0/), plres)

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
    gsn_text_ndc(wks,location_title,0.24,0.64,txres)
        
    

;==============================================
;  attach plots
;=============================================
  resa                     = True
  resb                     = True
  resa@gsnMaximize         = True
  resb@gsnAttachPlotsXAxis = True
 ;newplot = gsn_attach_plots(plot1,(/plot4/),resa,resb)
 
 draw (plot1)
 frame(wks)

end if

end
