;================================================;
;  MOPITT_hotcal_analysis.nc
;================================================;
;
;
;--------------------------------------------------
; This NCL analyses extracted hotcal counts.
;--- To use type:
;---             ncl MOPITT_hotcal_analysis.nc
;
;                                     rrb 20180710
;--------------------------------------------------
;
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"   
; ================================================;

begin

; =========================================
; USER DEFINED
; =========================================

  radtype = "avg"   ; avg or diff

  PLOT = True
    plottype = "x11"
      ;plottype@wkWidth  = 1500
      ;plottype@wkHeight = 800
      ;plottype@wkPaperWidthF  = 9 ;for pdf
      ;plottype@wkPaperHeightF = 20  ;for pdf
    plotname = "~/MOPITT_hotcals"

; =========================================
; SET UP
; =========================================
  cal_loc = "/net/mopfl2015.acom.ucar.edu/home/buchholz/MOPITT_diags/"
  cal_file = cal_loc+"MOPCH_HOT_6_all.csv"

; ----------------------------------------
; Load data 1
; ----------------------------------------
;---Read the values in as 1D, since we don't know rows and columns yet.
  lines  = asciiread(cal_file,-1,"string")
  delim  = ","
  ncols  = dimsizes(str_split(lines(1),delim))
  nlines = dimsizes(lines)-1          ; No header

;---Reshape as 2D array, and convert to float for ppm/ppb.
  fields = new((/nlines,ncols-1/),float)
  headers = new((/ncols-1/),string)
   do nf=0,ncols-2                   ;Remember that fields start at 1, not 0.
     fields(:,nf) = tofloat(str_get_field(lines(1:),nf+2,delim)) 
     headers(nf) = str_get_field(lines(0),nf+2,delim)
   end do

   date = fields(:,1)
   date@units = "days since 1958-01-01"
   split_date = cd_calendar(date,0)
   yyyymmdd = cd_calendar(date,2)
   yfrac = cd_calendar(date,4)

   if (radtype.eq."avg") then
     pix_avg_array = fields(:,6:18:4)
     labels = headers(6:18:4)
   else if (radtype.eq."diff") then
     pix_avg_array = fields(:,7:19:4)
     labels = headers(7:19:4)
   end if
   end if
     pix_avg_array!0 = "time"
     pix_avg_array!1 = "pixels"
   pix_avg_array := pix_avg_array(pixels|:, time|:)

print(headers)
print(labels)

; ----------------------------------------
; Day Averages
; ----------------------------------------
mm = 1
dd = 1

  yyyymmdd_array = yyyymmdd_time(toint(split_date(0,0)),toint(split_date(dimsizes(yyyymmdd)-1,0)),"integer")
  dayavg_yfrac = yyyymmdd_to_yyyyfrac(yyyymmdd_array,0.5)
  day_avgs = new((/dimsizes(fields(0,:)),dimsizes(yyyymmdd_array)/),float)

  do i = 0,dimsizes(yyyymmdd_array)-1
       yyyy_dummy = str_split_by_length(tostring(yyyymmdd_array(i)),4)
       mmdd_dummy = str_split_by_length(yyyy_dummy(1),2)
       indavg := ind(split_date(:,0).eq.toint(yyyy_dummy(0)).and.\
                    split_date(:,1).eq.toint(mmdd_dummy(0)))
       if(ismissing(indavg(0))) then
         continue
       else
         ;print(yyyymmdd(indavg))
         day_avgs(:,i) = dim_avg_n(fields(indavg,:),0)
       end if
  end do

   if (radtype.eq."avg") then
     pix_avg_array_day = day_avgs(6:18:4,:)
   else if (radtype.eq."diff") then
     pix_avg_array_day = day_avgs(7:19:4,:)
   end if
   end if

; ----------------------------------------
; Trend analysis after 2001
; ----------------------------------------
  time_select = ind(yfrac.ge.2002)
  trend_all = regline_stats(yfrac(time_select),fields(time_select,6))

  time2_select = ind(dayavg_yfrac.ge.2002)
  trend_temp =  regline_stats(dayavg_yfrac(time2_select),day_avgs(5,time2_select))
print(trend_temp)
   tempest_array = new(2,float)
   tempest_array(0) = trend_temp@Yest(0)
   tempest_array(1) = trend_temp@Yest(dimsizes(trend_temp@Yest)-1)

  ; ----------------------------------------
  ; Collect stats
  ; ----------------------------------------
   selected_yfrac_dummy = dayavg_yfrac(time2_select)
   time3_select = ind(.not.ismissing(day_avgs(0,time2_select)))
   ;selected_yfrac = selected_yfrac_dummy(time3_select)

   r2_array = new(4,float)
   b0_array = new(4,float)
   b1_array = new(4,float)
   yest_array = new((/4,2/),float)
   selected_yfrac = (/selected_yfrac_dummy(0),selected_yfrac_dummy(dimsizes(selected_yfrac_dummy)-1)/)
   do j = 0,3
     trend_dayavg =  regline_stats(dayavg_yfrac(time2_select),pix_avg_array_day(j,time2_select))
     yest_array(j,0) = trend_dayavg@Yest(0)
     yest_array(j,1) = trend_dayavg@Yest(dimsizes(trend_dayavg@Yest)-1)
     r2_array(j) = trend_dayavg@r
     b0_array(j) = trend_dayavg@b(0)
     b1_array(j) = trend_dayavg@b(1)
   end do

; =========================================
; PLOT the timeseries
; =========================================
if (PLOT) then
  wks   = gsn_open_wks (plottype,plotname)         ; open workstation

  res                   = True                     ; plot mods desired
   res@gsnDraw          = False
   res@gsnFrame         = False
   res@tiMainString     = ""                       ; add title
   res@xyMarkLineModes = (/"Markers","Markers","Markers","Markers"/)
   res@gsnMaximize      = True
   
   res@vpWidthF         = 1
   res@vpHeightF        = 0.4
   res@trXMinF          = 1999
   res@trXMaxF          = 2020
   
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

  
   ;res@tmXBLabelFontHeightF = 0.032
   ;res@tmYLLabelFontHeightF = 0.032
   ;res@tiYAxisFontHeightF   = 0.032
   ;res@tiXAxisFontHeightF   = 0.032
   
   ;res@trYMinF          = -6.1e17
   ;res@trYMaxF          = 12.5e17
   ;res@tmYLMode         = "Explicit"
   ;res@tmYLValues       = (/-5e17,0,5e17,10e17/)
   ;res@tmYLLabels       = (/"-5.0","0","5.0","10.0"/)


   res@tiYAxisString   = ""
   res@gsnLeftString  := ""             ; Label Bar title
      
  res2 = res ; copy res up to here (want to avoid repeating anomaly colors)
 

  ;-----------------------------------
  ; Measured
  ;-----------------------------------

    res2@xyMarkerColors           = (/"purple","blue3","forestgreen","red3"/)        ; Marker color
    res2@xyMarkerOpacityF         = 0.65
    res2@xyMarkerSizeF            = 0.004             ; Marker size (default 0.01)
    res2@tiYAxisString            = "Counts"
    res2@tiXAxisString            = "Year"
   plot1  = gsn_csm_xy (wks,yfrac,pix_avg_array,res2)  ; create plot


  ;-----------------------------------
  ; Day Average
  ;-----------------------------------
    res2@pmLegendDisplayMode      = "Always"        ; turn on legend
    res2@xyExplicitLegendLabels   = labels +" slope = "+ sprintf("%5.4g",b1_array)\
                                     +", r = " + sprintf("%4.2g",r2_array)
    res2@lgPerimOn                = False           ; Turn off perimeter
    res2@pmLegendWidthF           = 0.10            ; Change width and
    res2@lgLabelFontHeightF       = 0.022
    res2@pmLegendOrthogonalPosF   = -1.4
    res2@pmLegendParallelPosF     = 0.43

    res2@xyMarkers                = (/16,16,16,16/)               ; choose type of marker  
    res2@xyMarkerSizeF            = 0.008             ; Marker size (default 0.01)
   plot1a  = gsn_csm_xy (wks,dayavg_yfrac,pix_avg_array_day,res2)  ; create plot
   overlay(plot1,plot1a)

  ;-----------------------------------
  ; Temperature
  ;-----------------------------------
   res2@pmLegendDisplayMode    = "Never"        ; turn on legend
    res2@tiYAxisString         = "Internal Temperature (K)"
    res2@xyMarkerColors       := "black"        ; Marker color
    res2@xyMarkerSizeF            = 0.004             ; Marker size (default 0.01)
   plot2  = gsn_csm_xy (wks,yfrac,fields(:,5),res2)  ; create plot
    res2@xyMarkerSizeF            = 0.008             ; Marker size (default 0.01)
   plot2a  = gsn_csm_xy (wks,dayavg_yfrac,day_avgs(5,:),res2)  ; create plot
   overlay(plot2,plot2a)

  ;-----------------------------------
  ; Trends
  ;-----------------------------------
   res2@xyMarkLineModes = (/"Lines","Lines","Lines","Lines"/)
   res2@xyLineColors           = (/"purple","blue3","forestgreen","red3"/)        ; Marker color
    res2@tiYAxisString         = "Internal Temperature (K)"
    res2@xyMarkerColors       := "black"        ; Marker color
    res2@xyMarkerSizeF            = 0.004             ; Marker size (default 0.01)
   plot1b  = gsn_csm_xy (wks,selected_yfrac,yest_array,res2)  ; create plot
   overlay(plot1,plot1b)

   res2@xyLineColors           := (/"black"/)        ; Marker color
   plot2b  = gsn_csm_xy (wks,selected_yfrac,tempest_array,res2)  ; create plot
   overlay(plot2,plot2b)

  ;-----------------------------------
  ; Add in title
  ;-----------------------------------
   ;drawNDCGrid(wks)
   ; add station
    txres                   = True                     ; polyline mods desired
     txres@txJust           = "CenterLeft"             ; font smaller. default big
     txres@txPerimOn        = False
     txres@txPerimSpaceF    = 0.3
     txres@txPerimThicknessF= 2.0
     txres@txFontHeightF    = 0.022                    ; font smaller. default big
    gsn_text_ndc(wks,"MOPITT hot calibration timeseries - "+radtype,0.25,0.95,txres)

    txres@txFontHeightF    = 0.018                    ; font smaller. default big
    gsn_text_ndc(wks,"slope = "+sprintf("%5.3g", trend_temp@b(1))\
                 +", r = "+sprintf("%4.2g",trend_temp@r),0.65,0.20,txres)

; ----------------------------------------
;  attach plots
; ----------------------------------------

  resa                     = True
    resa@tiYAxisFontHeightF    = 0.026
    resa@gsnAttachBorderOn   = True
  resb                     = True
    resb@tiYAxisFontHeightF    = 0.026
    resb@tiXAxisFontHeightF    = 0.026
  resa@gsnMaximize         = True    
  resb@gsnMaximize         = True
  resb@gsnAttachPlotsXAxis = True
  newplot = gsn_attach_plots(plot1,plot2,resa,resb)

 draw(plot1)
 frame(wks)

end if

end
