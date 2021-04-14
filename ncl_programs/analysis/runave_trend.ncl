;=======================================================;
;  trend_analysis.ncl 
;=======================================================;
;
; Concepts illustrated:
;   - For use with MOPITT CO month anomalies
;     - load CO data
;     - calculate Theil-Sen trend
;
;   Files needed:
;         -MOPITT anomalies
;
;   To run type:
;         ncl trend_analysis.ncl 
;                                  RRB November 12, 2018
;=======================================================;
; load the libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------
  location = "AnthIndi"
    pltname      = "/net/mopfl/home/buchholz/"+location+"_trend"
  maxlag = 12
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  timeseries_files = systemfunc ("ls /IASI/home/buchholz/MOPITT_subset/regions_v8/column_extractions/"+location+"_*monthavg.nc")


  ;------------
  ; toggles
  ;------------
  PLOT           = True
    plttype      = "x11"
    ;plttype@wkPaperSize = "A4"
      plttype@wkWidth = 1200
      plttype@wkHeight = 1200
      plot_title = "Test"

;--------------------------------------------
; end user input
;--------------------------------------------
;
;--------------------------------------------
; set up
;--------------------------------------------

  ; -------------------------------
  ; OUTPUT RELATED SETUP
  ; -------------------------------
  if (PLOT) then
    pltdir       = "./"
    pltname      = location+"_laggedcorr2"
  end if

  ;Carriage return
   cr = tochar(10)

  ;Month names
  ; month_names = (/"RunAve","Jan", "Feb", "Mar", "Apr", "May", "Jun",\
  ;                  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"/)
   month_names = (/"RunAve","J", "F", "M", "A", "M", "J",\
                    "J", "A", "S", "O", "N", "D"/)
;--------------------------------------------
; load file and extract timeseries
;--------------------------------------------
  fin = addfiles(timeseries_files, "r")            ; read in
    ListSetType (fin, "cat")                 ; concatenate
    timeseries_dummy  = fin[:]->RetrievedCOtcolRegionStats
    time        = fin[:]->time
    split_dates = str_split_by_length(tostring(time),4)
    yfrac = yyyymm_to_yyyyfrac(time,0.5)


   ; [0] Mean, [1] StdDev, [2] Min, [3] LowQuartile, [4] Median, 
   ; [5] HighQuartile, [6] Max, [7] Total n, [8] Used n, [9] Missing, 
   ; [10] Lower 5.0% (for n > 1000), [11] Upper 5.0% (for n > 1000)
   timeseries = timeseries_dummy(:,(/0,10,3,4,5,11/))
   name_array = (/"mean", "5th", "25th", "median", \
                  "75th", "95th"/)
   tcol_monthavg = timeseries_dummy(:,0)
   dataset_average = avg(tcol_monthavg)

;--------------------------------------------
; Spline Fit to fill missing values
;--------------------------------------------
  new_timeseries = new(dimsizes(timeseries), float)
  do n = 0, dimsizes(name_array)-1
    working_timeseries = timeseries(:,n)
    ind_m_data := ind(.not.ismissing(working_timeseries))
    xi := yfrac(ind_m_data)
    yi := working_timeseries(ind_m_data)
    xo = yfrac
    yo = ftcurv(xi, yi, xo)
    new_timeseries_dummy = tofloat(where(ismissing(working_timeseries),yo,working_timeseries))
    new_timeseries(:,n) = new_timeseries_dummy
  end do
  copy_VarMeta(timeseries,new_timeseries)

;--------------------------------------------
; Deaseasonalize
;--------------------------------------------
  ;climate_co     = new((/12/), float)
  climate_co_ext = new(dimsizes(timeseries), float)
  mopitt_date  = str_split_by_length(tostring(time),4)
  months       = tointeger(mopitt_date(:,1))

  do i=0,11
     ; get indices of array related to specific month
     month_ind := ind(months.eq.(i+1))
     co_to_avg := new_timeseries(month_ind,:)
     avg_co_month := dim_avg_n(co_to_avg,0)
     print(avg_co_month)
    do j = 0, dimsizes(name_array)-1
     climate_co_ext(month_ind,j) = avg_co_month(j)
    end do
  end do ;i=0,dimsizes(mopitt_time)-1
  copy_VarMeta(timeseries,climate_co_ext)

  co_anomaly = new_timeseries-climate_co_ext
  copy_VarMeta(timeseries,co_anomaly)

;--------------------------------------------
; Running average
;--------------------------------------------
 ;timeseries_runave_dummy = co_anomaly
 timeseries_runave_dummy = runave_n_Wrap(new_timeseries,12,1,0)
 ind_for_trend = ind(time.ge.200201)
 timeseries_runave = timeseries_runave_dummy(ind_for_trend,:)
 yfrac_trend = yfrac(ind_for_trend)
 avg_value = dim_avg_n(timeseries_runave, 0)

;--------------------------------------------
; Calculate trends for plotting
;--------------------------------------------
   ; Theil-Sen
    p    = trend_manken(timeseries_runave, False, 0)
    trend_array = (p(1,:)/abs(dataset_average))*100
    trend_array_col = p(1,:)
    pval_array = 1-p(0,:)

    print("Percent trends")
    print(name_array+": "+trend_array+ ", p-value "+(1-p(0,:)))

    ; OLS
    rc   = regline(yfrac_trend,timeseries_runave(:,0))
    print(rc)
    print("Mean trend: "+trend_array_col(0)+ ", p-value "+(1-p(0,0)))

    ;rc
    ;rc@yave                    ;average month tcol
    ;rc@xave
    ols_trendplot = rc*(yfrac_trend-rc@xave) + rc@yave

  sig_trend_05 = where(pval_array.gt.0.05,trend_array@_FillValue,trend_array)
  sig_trend_01 = where(pval_array.gt.0.01,trend_array@_FillValue,trend_array)
  sig_trend_001 = where(pval_array.gt.0.001,trend_array@_FillValue,trend_array)
  print(trend_array)
  print(pval_array)

  trend_plot = new ( dimsizes(timeseries_runave), typeof(timeseries_runave), timeseries_runave@_FillValue)
  avg_stat_tcol = dim_avg_n(timeseries_runave,0)
  do j = 0,dimsizes(name_array)-1
    trend_plot(:,j) = p(1,j)*(yfrac_trend-rc@xave) + avg_stat_tcol(j)
  end do
  trend_plot!0 = "time"
  trend_plot!1 = "ncl1"
  ;copy_VarMeta(timeseries,trend_plot)


;--------------------------------------------
; Split trends for plotting
;--------------------------------------------
  ind_2002 = ind(time.ge.200201.and.time.lt.201001)
  dataset_2002 = timeseries_runave_dummy(ind_2002,:)
  yfrac_2002 = yfrac(ind_2002)

  ind_2010 = ind(time.ge.201001)
  dataset_2009 = timeseries_runave_dummy(ind_2010,:)
  yfrac_2010 = yfrac(ind_2010)

  ; OLS
  rc_2002   = regline(yfrac_2002,dataset_2002(:,0))
  print(rc_2002)
  ols_trendplot_2002 = rc_2002*(yfrac_2002-rc_2002@xave) + rc_2002@yave

  rc_2010   = regline(yfrac_2010,dataset_2009(:,0))
  print(rc_2010)
  ols_trendplot_2010 = rc_2010*(yfrac_2010-rc_2010@xave) + rc_2010@yave

  print("Percent trends OLS")
  print("Total:" + (rc/dataset_average)*100)
  print("2002-2009:" + (rc_2002/dataset_average)*100)
  print("2010-2017:" + (rc_2010/dataset_average)*100)
;--------------------------------------------
; plot
;--------------------------------------------
if (PLOT) then

  wks = gsn_open_wks(plttype,pltname)        
  gsn_define_colormap(wks,"BlAqGrYeOrRe")  
   
  res                       = True                      ; plot mods desired
    res@xyMarkLineMode      = "Lines"
    res@gsnDraw		    = False	                ; don't draw it yet
    res@gsnFrame            = False                     ; don't advance frame
    res@gsnMaximize         = True
    res@gsnRightStringFontHeightF =0.034

    res@xyLineThicknessF    = 7.0
    res@xyDashPatterns      = (/0,1,2,3,4/)
    res@xyLineColors        = (/"red2","orange", "forestgreen", "purple4"/)

    res@tmBorderThicknessF  = 3.0
    res@tmXBMajorThicknessF = 3.0
    res@tmYLMajorThicknessF = 3.0

    res@tmYLMajorOutwardLengthF = 0.0               ; draw tickmarks inward
    res@tmYLMinorOutwardLengthF = 0.0               ; draw minor ticks inward
    res@tmXBMajorOutwardLengthF = 0.0               
    res@tmXBMinorOutwardLengthF = 0.0   

    ;res@trYMinF             = -0.6
    ;res@trYMaxF             = 1.5
    ;res@trXMinF             = 2001.5

    res@vpWidthF             = 1
    res@vpHeightF            = 0.6          ; set height of plot

    res@tiMainString        = ""
    res@gsnLeftString       = "~F34~4~F21~10~S2~18   molec. cm~S2~-2" 
    res@tiXAxisString       = "Year"
    res@tiYAxisString       = "Column CO"

    res@pmLegendDisplayMode      = "Always"        ; turn on legend
    res@lgPerimOn                = False           ; Turn off perimeter
    res@pmLegendWidthF           = 0.10           ; Change width and
    res@pmLegendHeightF          = 0.20             ; height of legend
    res@lgLabelFontHeightF       = 0.030
    res@xyExplicitLegendLabels   = (/"mean", "5th", "25th", "median", "75th", "95th"/)
    res@pmLegendOrthogonalPosF   = -1.555
    res@pmLegendParallelPosF     = 0.93

  ; -------------------------------
  ; create plot
  ; -------------------------------
    res@pmLegendDisplayMode = "Always"        ; turn on legend
    res@xyMarkLineModes      = (/"Lines","Lines","Lines"/)
    res@xyMarkers           = (/4,4,4,4/)            ; choose type of marker  
    res@xyMarkerThicknessF  = (/6,6,6,6,6,6/)
    res@xyMarkerSizeF       = 0.024
    res@xyMarkerColors      = (/"black","red","blue"/)
    res@xyLineColors        := (/"black","blue","skyblue","grey60","red","red4"/)
    plot = gsn_csm_xy(wks,yfrac,timeseries_runave_dummy(ncl1|:, time|:)/1e18,res)
    res@gsnLeftString       = "" 

    ; Theil-Sen
    res@pmLegendDisplayMode      = "Never"        ; turn on legend
    res@xyLineThicknessF    = 10.0
    ;plot2 = gsn_csm_xy(wks,yfrac,trend_plot(ncl1|:, time|:),res)
    plot2 = gsn_csm_xy(wks,yfrac_trend,trend_plot(:,0)/1e18,res)
    ;overlay(plot,plot2)

    ; OLS
    res@pmLegendDisplayMode      = "Always"        ; turn on legend
    res@xyExplicitLegendLabels   := (/"OLS"/)
    res@xyLineColors        := (/"black"/)
    res@pmLegendOrthogonalPosF   = -1.68
    res@pmLegendParallelPosF     = 0.72
    plot3 = gsn_csm_xy(wks,yfrac_trend,ols_trendplot/1e18,res)
    overlay(plot,plot3)

    res@pmLegendParallelPosF     = 0.48
    res@xyExplicitLegendLabels   := (/"2010-2017"/)
    res@xyDashPatterns      := (/2/)
    plot4 = gsn_csm_xy(wks,yfrac_2010,ols_trendplot_2010/1e18,res)
    overlay(plot,plot4)

    res@pmLegendParallelPosF     = 0.20
    res@xyExplicitLegendLabels   := (/"2002-2009"/)
    res@xyDashPatterns      := (/1/)
    plot5 = gsn_csm_xy(wks,yfrac_2002,ols_trendplot_2002/1e18,res)
    overlay(plot,plot5)

  ; -------------------------------
  ; add legend
  ; -------------------------------
    txres                   = True                     ; polyline mods desired
     txres@txFontHeightF    = 0.020                   ; font smaller. default big
     txres@txJust           = "CenterCenter"
     txres@txPerimOn        = False
     txres@txFontColor      = "black"                  
    ;gsn_text_ndc(wks,"Theil-Sen",0.71,0.86,txres)
    ;gsn_text_ndc(wks,sprintf("%4.2e",trend_array_col(0)),0.71,0.82,txres)
    ;gsn_text_ndc(wks,sprintf("%4.3g",trend_array(0))+" % p.y.",0.71,0.78,txres)

     txres@txFontColor      = "black"                  
    gsn_text_ndc(wks,sprintf("%4.2e",rc),0.71,0.82,txres)
    gsn_text_ndc(wks,sprintf("%4.3g",(rc/dataset_average)*100)+" % p.y.",0.71,0.78,txres)

    gsn_text_ndc(wks,sprintf("%4.2e",rc_2010),0.50,0.82,txres)
    gsn_text_ndc(wks,sprintf("%4.3g",(rc_2010/dataset_average)*100)+" % p.y.",0.50,0.78,txres)

    gsn_text_ndc(wks,sprintf("%4.2e",rc_2002),0.30,0.82,txres)
    gsn_text_ndc(wks,sprintf("%4.3g",(rc_2002/dataset_average)*100)+" % p.y.",0.30,0.78,txres)


    txres@txPerimOn        = True
    gsn_text_ndc(wks,location,0.85,0.67,txres)


  ; -------------------------------
  ; panel the plots
  ; -------------------------------
     resP = True
   ; gsn_panel(wks,plot_arr,(/4,3/),resP) 

    draw(plot)
    frame(wks)

end if



end

