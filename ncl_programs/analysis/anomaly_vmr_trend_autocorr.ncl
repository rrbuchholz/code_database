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
load "/IASI/home/buchholz/code_database/ncl_programs/buchholz_global_util/calc_seasonal_cycle.ncl"


begin

;--------------------------------------------
; user input
;--------------------------------------------
  location = "BBSAfOcean"
    pltname      = "/net/mopfl/home/buchholz/"+location+"_trend"
  maxlag = 12
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  timeseries_files = systemfunc ("ls /IASI/home/buchholz/MOPITT_subset/regions_v8/"+location+"_*monthavg_VMR.nc")

  ;scale_factor = 1e18
  ;unit = "~F34~4~F21~10~S2~18   molec. cm~S2~-2"
  ;yaxis = "Total column"

  scale_factor = 1e-09
  unit = "ppb"
  yaxis = "Column average VMR anomaly"
  ;------------
  ; toggles
  ;------------
  PLOT           = True
    plttype      = "x11"
    ;plttype@wkPaperSize = "A4"
      plttype@wkWidth = 1200
      plttype@wkHeight = 1200
      plot_title = "Test"

  PRIORtest        = False
    apriori_files = systemfunc ("ls /IASI/home/buchholz/CAM_chem/regions_MOPITT_apriori/"+location+"_*monthavg.nc")

  AKtest        = False
    smooth_files = systemfunc ("ls /IASI/home/buchholz/CAM_chem/regions_MOPITT_AK/"+location+"_*monthavg.nc")

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

  ; -------------------------------
  ; constants
  ; -------------------------------
   NAv = 6.022e23                    ; Avogadro's number, molecules mole^-1
   g      = 9.81                             ;--- m/s - gravity
   H = (8.314*240)/(0.0289751*9.8)           ;--- scale height
   MWair = 28.94                             ;--- g/mol
   vmr_const = (10)/(MWair*g)            ;--- scaling factor for turning tcol into vmr

   re   = 6.37122e06                 ; Earth radius (in metres)
   rad  = 4.0 * atan(1.0) / 180.0    ; Convert degrees to radians (pi radians per 180 deg)
   con  = re * rad                   ; constant for determining arc length 

   region_names = (/"AnthChina", "AnthIndi", "AnthEuro", "AnthUSA",\
                    "BBUSA", "BBCanada", "BBSiberia", "BBWRus",\
                    "BBCAmerica", "BBSAmerica","BBSAmOcean",\
                     "BBCAfrica", "BBSAfrica","BBSAfOcean", \
                    "BBMSEA", "BBNWAu","BBEAu", "NH", "SH"/)

;--------------------------------------------
; load file and extract timeseries
;--------------------------------------------
  fin = addfiles(timeseries_files, "r")            ; read in
    ListSetType (fin, "cat")                 ; concatenate
    timeseries_dummy  = fin[:]->RetrievedX_CORegionStats
    apriori_dummy  = fin[:]->AvgAPrioriX_CO
    time        = fin[:]->time
    split_dates = str_split_by_length(tostring(time),4)
    yfrac = yyyymm_to_yyyyfrac(time,0.5)

   ; [0] Mean, [1] StdDev, [2] Min, [3] LowQuartile, [4] Median, 
   ; [5] HighQuartile, [6] Max, [7] Total n, [8] Used n, [9] Missing, 
   ; [10] Lower 5.0% (for n > 1000), [11] Upper 5.0% (for n > 1000)
   timeseries = timeseries_dummy(:,(/0,3,4,5/))
   name_array = (/"mean", "25th", "median", \
                  "75th"/)
   tcol_monthavg = timeseries_dummy(:,0)
   timeseries_sd = timeseries_dummy(:,(/1/))
    ;timeseries_sd = where(ismissing(timeseries_sd), 1000, timeseries_sd)

   ;-------------------------------------------------
   ; a priori
   ;timeseries = new((/dimsizes(apriori_dummy), 2/), float)
   ;timeseries(:,0) = apriori_dummy
   ;timeseries(:,1) = apriori_dummy*0+1e-9
   ;timeseries!1 = "ncl1"
   ;name_array = (/"a priori","fill values"/)
   ;tcol_monthavg = apriori_dummy

   ;-------------------------------------------------
   ; A priori from LVL 3
   if (PRIORtest) then
     fin2 = addfiles(apriori_files, "r")            ; read in
       ListSetType (fin2, "cat")                 ; concatenate
       apriori_dummy  = fin2[:]->Model_smoothed_X_CO_wgt
       timeseries := new((/dimsizes(apriori_dummy), 2/), float)
         timeseries(:,0) = apriori_dummy
         timeseries(:,1) = apriori_dummy*0
         timeseries!1 = "ncl1"
       timeseries_sd  := fin2[:]->StdDev_smoothed_X_CO
       time  := fin2[:]->time
      split_dates := str_split_by_length(tostring(time),4)
      yfrac := yyyymm_to_yyyyfrac(time,0.5)
      name_array := (/"a priori","fill values"/)
   end if

   ;-------------------------------------------------
   ; AK smoothed model
   if (AKtest) then
     fin2 = addfiles(smooth_files, "r")            ; read in
       ListSetType (fin2, "cat")                 ; concatenate
       smoothed_dummy  = fin2[:]->Model_smoothed_X_CO_wgt
       timeseries := new((/dimsizes(smoothed_dummy), 2/), float)
         timeseries(:,0) = smoothed_dummy
         timeseries(:,1) = smoothed_dummy*0
         timeseries!1 = "ncl1"
       timeseries_sd  := fin2[:]->StdDev_smoothed_X_CO
       time  := fin2[:]->time
      split_dates := str_split_by_length(tostring(time),4)
      yfrac := yyyymm_to_yyyyfrac(time,0.5)
      name_array := (/"smoothed reanalysis","fill values"/)
   end if

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
    new_timeseries_dummy := tofloat(where(ismissing(working_timeseries),yo,working_timeseries))
    new_timeseries(:,n) = new_timeseries_dummy
  end do
  copy_VarMeta(timeseries,new_timeseries)

;--------------------------------------------
; Deaseasonalize
;--------------------------------------------
  ;climate_co     = new((/12/), float)
  climate_co_ext = new(dimsizes(timeseries), float)
  climate_co_ext2 = new(dimsizes(timeseries), float)
  mopitt_date  = str_split_by_length(tostring(time),4)
  months       = tointeger(mopitt_date(:,1))
  harmonic_seas = calc_seasonal_cycle(new_timeseries(:,0), time, 2002, 2018, 12)

  do i=0,11
     ; get indices of array related to specific month
     month_ind := ind(months.eq.(i+1))
     co_to_avg := new_timeseries(month_ind,:)
     avg_co_month := dim_avg_n(co_to_avg,0)
     print(avg_co_month)
    do j = 0, dimsizes(name_array)-1
     ;print(avg_co_month(j)+ "..." +(harmonic_seas(i,0)))
     ;print("Month "+ (i+1) +": "+ avg_co_month(j))
     climate_co_ext(month_ind,j) = avg_co_month(j)
     ;climate_co_ext(month_ind,0) = tofloat(harmonic_seas(i,0))
    end do
  end do ;i=0,dimsizes(mopitt_time)-1
  copy_VarMeta(timeseries,climate_co_ext)

  co_anomaly = new_timeseries-climate_co_ext


  copy_VarMeta(timeseries,co_anomaly)

;--------------------------------------------
; Remove 2015 El Nino Fire
;--------------------------------------------
 ind_remove = ind(time.ge.201507.and.time.le.201606)
 ;new_timeseries(ind_remove,:) = new_timeseries@_FillValue
 ;co_anomaly(ind_remove,:) = co_anomaly@_FillValue
 ;timeseries_sd(ind_remove) = timeseries_sd@_FillValue
;print(timeseries_sd)

;--------------------------------------------
; Remove 2008 GFC
;--------------------------------------------
 ind_remove_2 = ind(time.ge.200802.and.time.le.201001)
; timeseries_sd(ind_remove_2) = timeseries_sd@_FillValue
;print(timeseries_sd)

;--------------------------------------------
; Running average
;--------------------------------------------
 timeseries_runave_dummy = co_anomaly
 ;timeseries_runave_dummy = runave_n_Wrap(co_anomaly,12,0,0) ; anomaly runave
 ;timeseries_runave_dummy = runave_n_Wrap(new_timeseries,12,0,0) ; runave
 ;timeseries_runave_dummy = new_timeseries ; whole timeseries
 ind_for_trend = ind(time.ge.200207.and.time.le.201806)
 ; dataset average over 200207-201806
 dataset_average = avg(tcol_monthavg(ind_for_trend))
 timeseries_runave = timeseries_runave_dummy(ind_for_trend,:)
 stddev_timeseries = timeseries_sd(ind_for_trend)

 yfrac_trend = yfrac(ind_for_trend)
 avg_value = dim_avg_n(timeseries_runave, 0)

;print(time(ind_for_trend) +" "+ timeseries_runave(:,0) )

;--------------------------------------------
; Yearly average
;--------------------------------------------
    ystart = floor(yfrac_trend(0))
    yend = floor(yfrac_trend(dimsizes(yfrac_trend)-1))
    years = ispan(toint(ystart),toint(yend),1)
    year_average = new((/dimsizes(years),dimsizes(name_array)/),float)
    year_sd = new((/dimsizes(years),dimsizes(name_array)/),float)

    do y = 0, dimsizes(years)-1
      ind_year := ind(yfrac.ge.years(y).and.yfrac.lt.years(y)+1)
      year_average(y,:) = dim_avg_n(timeseries_runave_dummy(ind_year,:),0)
      year_sd(y,:) = dim_stddev_n(timeseries_runave_dummy(ind_year,:),0)
    end do


;--------------------------------------------
; Calculate trends for plotting
;--------------------------------------------
   ; Theil-Sen
    p    = trend_manken(timeseries_runave, False, 0)
    trend_array = (p(1,:)/abs(dataset_average))*100
    trend_array_col = p(1,:)
    pval_array = 1-p(0,:)

    ; Weighted Least Squares
    ; weighted by the standard deviation
    rc   = regline_weight(yfrac_trend,timeseries_runave(:,0),stddev_timeseries,1)
    ;rc   = regline_weight(tofloat(years),year_average(:,0),year_sd(:,0),1)
    ;rc   = regline_stats(tofloat(years),year_average(:,0))
    print(rc)
    print(rc@p_value)
;    df = dimsizes(timeseries_runave(:,0))-2
    ;prob = 
;    print(df)
;exit
    print("WLS trend: "+(rc/dataset_average)*100+ ", std err "+ (rc@std_rc/dataset_average)*100)

    print("Mean trend: "+trend_array_col(0)+ ", p-value "+(1-p(0,0)))
    ols_trendplot = (rc*(yfrac_trend) + rc@yintercept) + dataset_average


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
; Year average values
;--------------------------------------------  
    ind_trend = ind(years.gt.2001.and.years.lt.2019)
    ; Theil-Sen
    p_year    = trend_manken(year_average(ind_trend,:), False, 0)
    trend_array2 = (p_year(1,:)/dataset_average)*100
    pval_array2 = 1-p_year(0,:)

    print("Percent trends Theil-Sen")
    print(name_array+": "+trend_array+ ", p-value "+(1-p(0,:)))
    print("Percent trends Theil-Sen on yearly avg")
    print(name_array+": "+sprintf("%4.3g",trend_array2)+ " ("+sprintf("%4.3g",pval_array2)+ ")")

    ts_trend_plot = p_year(1,0)*(years-dim_avg(years)) + dataset_average


;--------------------------------------------
; Split trends for plotting
;--------------------------------------------
  ; 2002-2010
  ;----------
  ind_2002 = ind(time.ge.200207.and.time.le.201006)
  dataset_2002 = timeseries_runave_dummy(ind_2002,:)
  stddev_2002 = timeseries_sd(ind_2002)
  yfrac_2002 = yfrac(ind_2002)

  ; WLS
  rc_2002 = regline_weight(yfrac_2002,dataset_2002(:,0),stddev_2002,1)
  ols_trendplot_2002 = rc_2002*(yfrac_2002) + rc_2002@yintercept+ dataset_average

  ;----------
  ; 2010-2018
  ind_2010 = ind(time.ge.201007.and.time.le.201806)
  dataset_2010 = timeseries_runave_dummy(ind_2010,:)
  stddev_2010 = timeseries_sd(ind_2010)
  yfrac_2010 = yfrac(ind_2010)

  ; WLS
  ;rc_2010   = regline(yfrac_2010,dataset_2010(:,0))
  rc_2010 = regline_weight(yfrac_2010,dataset_2010(:,0),stddev_2010,1)
  ols_trendplot_2010 = rc_2010*(yfrac_2010) + rc_2010@yintercept + dataset_average

  ; end point test
  ind_2002_b = ind(time.ge.200207.and.time.le.200806)
  dataset_2002_b = timeseries_runave_dummy(ind_2002_b,:)
  stddev_2002_b = timeseries_sd(ind_2002_b)
  yfrac_2002_b = yfrac(ind_2002_b)
  rc_2002_b = regline_weight(yfrac_2002_b,dataset_2002_b(:,0),stddev_2002_b,1)

  ind_2011 = ind(time.ge.201107.and.time.le.201806)
  dataset_2011 = timeseries_runave_dummy(ind_2011,:)
  stddev_2011 = timeseries_sd(ind_2011)
  yfrac_2011 = yfrac(ind_2011)
  rc_2011 = regline_weight(yfrac_2011,dataset_2011(:,0),stddev_2011,1)

  ind_2011_b = ind(time.ge.201107.and.time.le.201706)
  dataset_2011_b = timeseries_runave_dummy(ind_2011_b,:)
  stddev_2011_b = timeseries_sd(ind_2011_b)
  yfrac_2011_b = yfrac(ind_2011_b)
  rc_2011_b = regline_weight(yfrac_2011_b,dataset_2011_b(:,0),stddev_2011_b,1)

  print("********************************")
  print("Percent trends WLS (+/- std err)")
  print("********************************")
  print("Dataset Average VMR: " +sprintf("%5.4g",dataset_average*1e09))
  print("Total ppb trend: " + rc*1e09 + "("+ rc@std_rc*1e09 +")")
  print("Total: " + sprintf("%4.3g",(rc/dataset_average)*100) +\
              " (" + sprintf("%3.1g",(rc@std_rc/dataset_average)*100) +")")
  print("--------------------------------")
  print(" 2002-2008: " + sprintf("%4.3g",(rc_2002_b/dataset_average)*100) +\
              " (" + sprintf("%4.1g",(rc_2002_b@std_rc/dataset_average)*100) +")")
  print("*2002-2010: " + sprintf("%4.3g",(rc_2002/dataset_average)*100) +\
              " (" + sprintf("%3.1g",(rc_2002@std_rc/dataset_average)*100) +")")
  print("*2010-2018: " + sprintf("%4.3g",(rc_2010/dataset_average)*100) +\
              " (" + sprintf("%3.1g",(rc_2010@std_rc/dataset_average)*100) +")")
  print(" 2011-2018: " + sprintf("%4.3g",(rc_2011/dataset_average)*100) +\
              " (" + sprintf("%4.1g",(rc_2011@std_rc/dataset_average)*100) +")")
  print(" 2011-2017: " + sprintf("%4.3g",(rc_2011_b/dataset_average)*100) +\
              " (" + sprintf("%4.1g",(rc_2011_b@std_rc/dataset_average)*100) +")")

;exit
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

    ;res@trYMinF             = 60.
    ;res@trYMaxF             = 280.
    res@trXMinF             = 2002.0
    res@trXMaxF             = 2019.0

    res@vpWidthF             = 1
    res@vpHeightF            = 0.4          ; set height of plot

    res@tiMainString        = ""
    res@gsnLeftString       = unit
    res@tiXAxisString       = "Year"
    res@tiYAxisString       = yaxis

    res@pmLegendDisplayMode      = "Always"        ; turn on legend
    res@lgPerimOn                = False           ; Turn off perimeter
    res@pmLegendWidthF           = 0.10           ; Change width and
    res@pmLegendHeightF          = 0.20             ; height of legend
    res@lgLabelFontHeightF       = 0.030
    ;res@xyExplicitLegendLabels   = (/"mean", "5th", "25th", "median", "75th", "95th"/)
    res@xyExplicitLegendLabels   = name_array
    res@pmLegendOrthogonalPosF   = -1.755
    res@pmLegendParallelPosF     = 0.93

  ; -------------------------------
  ; create plot
  ; -------------------------------
    res@pmLegendDisplayMode = "Always"        ; turn on legend
    res@xyMarkLineModes      = (/"Lines","Lines","Lines"/)
    res@xyMarkers           = (/4,4,4,4/)            ; choose type of marker  

    res@xyLineColors        := (/"black","blue","skyblue","grey60","red","red4"/)
    plot = gsn_csm_xy(wks,yfrac,new_timeseries(ncl1|:, time|:)/scale_factor,res)
    ;plot = gsn_csm_xy(wks,yfrac,timeseries_runave_dummy(ncl1|:, time|:)/scale_factor,res)
    ;plot = gsn_csm_xy(wks,yfrac,timeseries_runave_dummy(ncl1|0, time|:)/scale_factor,res)
    res@gsnLeftString       = "" 

    ; Year average
    ;res@pmLegendDisplayMode      = "Never"        ; turn on legend
    res@xyExplicitLegendLabels   := "yr average"
    res@pmLegendOrthogonalPosF   = -1.455
    res@xyMarkLineModes      = (/"Markers","Lines","Lines"/)
    res@xyMarkerColors      = "red"
    res@xyMarkerThicknessF  = 8
    res@xyMarkerSizeF       = 0.024
    ;plot1 = gsn_csm_xy(wks,years,year_average(:,0)/scale_factor,res)
    ;overlay(plot,plot1)

    ; Theil-Sen
    res@xyMarkLineModes      = (/"Lines","Lines","Lines"/)
    res@pmLegendDisplayMode      = "Never"        ; turn on legend
    res@xyLineColors        := (/"red"/)
    res@xyLineThicknessF    = 10.0
    ;plot2 = gsn_csm_xy(wks,yfrac,trend_plot(ncl1|:, time|:),res)
    ;plot2 = gsn_csm_xy(wks,yfrac_trend,trend_plot(:,0)/scale_factor,res)
    plot2 = gsn_csm_xy(wks,years,ts_trend_plot/scale_factor,res)
    ;overlay(plot,plot2)

    ; OLS
    res@pmLegendDisplayMode      = "Always"        ; turn on legend
    res@xyExplicitLegendLabels   := (/"OLS"/)
    res@xyLineColors        := (/"black"/)
    res@pmLegendOrthogonalPosF   = -1.82
    res@pmLegendParallelPosF     = 0.67
    plot3 = gsn_csm_xy(wks,yfrac_trend,ols_trendplot/scale_factor,res)
    overlay(plot,plot3)

    res@pmLegendParallelPosF     = 0.43
    res@xyExplicitLegendLabels   := (/"2010-2017"/)
    res@xyDashPatterns      := (/2/)
    plot4 = gsn_csm_xy(wks,yfrac_2010,ols_trendplot_2010/scale_factor,res)
    overlay(plot,plot4)

    res@pmLegendParallelPosF     = 0.15
    res@xyExplicitLegendLabels   := (/"2002-2009"/)
    res@xyDashPatterns      := (/1/)
    plot5 = gsn_csm_xy(wks,yfrac_2002,ols_trendplot_2002/scale_factor,res)
    overlay(plot,plot5)

  ; -------------------------------
  ; add legend
  ; -------------------------------
    txres                   = True                     ; polyline mods desired
     txres@txFontHeightF    = 0.020                   ; font smaller. default big
     txres@txJust           = "CenterCenter"
     txres@txPerimOn        = False
     txres@txFontColor      = "red"                  
    ;gsn_text_ndc(wks,"Theil-Sen",0.66,0.76,txres)
    ;gsn_text_ndc(wks,sprintf("%4.2e",trend_array_col(0)),0.71,0.82,txres)
    ;gsn_text_ndc(wks,sprintf("%4.3g",trend_array2(0))+" % p.y.",0.66,0.72,txres)

     txres@txFontColor      = "black"                  
    ;gsn_text_ndc(wks,sprintf("%4.2e",rc),0.66,0.84,txres)
    gsn_text_ndc(wks,sprintf("%4.3g",(rc/dataset_average)*100)+" % p.y.",0.66,0.69,txres)

    ;gsn_text_ndc(wks,sprintf("%4.2e",rc_2010),0.45,0.84,txres)
    gsn_text_ndc(wks,sprintf("%4.3g",(rc_2010/dataset_average)*100)+" % p.y.",0.45,0.69,txres)

    ;gsn_text_ndc(wks,sprintf("%4.2e",rc_2002),0.25,0.84,txres)
    gsn_text_ndc(wks,sprintf("%4.3g",(rc_2002/dataset_average)*100)+" % p.y.",0.25,0.69,txres)


    txres@txPerimOn        = True
    gsn_text_ndc(wks,"MOPITT CO " + location,0.80,0.59,txres)


  ; -------------------------------
  ; panel the plots
  ; -------------------------------
     resP = True
   ; gsn_panel(wks,plot_arr,(/4,3/),resP) 

    draw(plot)
    frame(wks)

end if



end

