;=======================================================;
;  trend_analysis_vmr_L3.ncl
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
;         ncl trend_analysis_vmr_L3.ncl
;                                  RRB November 25, 2020
;=======================================================;
;systemfunc ("export NCARG_COLORMAPS=/IASI/home/buchholz/code_database/ncl_programs/custom_colormaps:$NCARG_ROOT/lib/ncarg/colormaps")

begin

;--------------------------------------------
; user input
;--------------------------------------------
  location = "BBSAmerica"
    pltname      = "/net/mopfl/home/buchholz/"+location+"_trend"
  yend = 2023
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  ;timeseries_files = systemfunc ("ls /MOPITT/V8J/Archive/L3/20*/month/*.he5")
  timeseries_files = systemfunc ("ls /MOPITT/V9J/Archive/L3/20*/month/*.he5")
print(timeseries_files)
  ;------------
  ; toggles
  ;------------
  PLOT           = True
    plttype      = "x11"
    ;plttype@wkPaperSize = "A4"
      plttype@wkWidth = 1200
      plttype@wkHeight = 1200
      plot_title = "Test"

  CSV            = False
  if (CSV) then
     ;outname      = "/net/mopfl/home/buchholz/"+location+"_MOPITT_V8J_aggregated_data.csv"
     outname      = "/IASI/home/buchholz/MOPITT_subset/V9/"+location+"_MOPITT_V9J_L3M_data.csv"
  end if


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
    pltname      = location+"_timeseries"
  end if

  ;Carriage return
   cr = tochar(10)

  ;Month names
  ; month_names = (/"Year Ave","Jan", "Feb", "Mar", "Apr", "May", "Jun",\
  ;                  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"/)

   ; Region definitions
   region_names = (/"AnthChina", "Australia","BBSAmerica", "Mid-Lat", "NH","SH"/)

   ;                   minlat, maxlat, minlon, maxlon
   region_select = (/(/ 30.,  40.,      110.,      123./),\  ;AnthChina
                     (/-45., -10.,      112.,      180./),\  ;Australasia
                     (/-25.,  -5.,      -75.,      -50./),\  ;BBSAmerica
                     (/-30.,  30.,      -180.,     180./),\  ;Mid-Lat
                     (/ 30.,  60.,      -180.,     180./),\  ;NH
                     (/-60.,  -30.,     -180.,     180./) /) ;SH
   ;                  (/-45., -10.,      112.,      155./)/)  ;Australia

   ind_region = ind(region_names.eq.location)

   topboundary     = region_select(ind_region,1)
   bottomboundary  = region_select(ind_region,0)
   rightboundary   = region_select(ind_region,3)
   leftboundary    = region_select(ind_region,2)

;--------------------------------------------
; load file and extract timeseries
;--------------------------------------------
  fin = addfiles(timeseries_files, "r")            ; read in
    ListSetType (fin, "join")                 ; concatenate
  print(getfileatts(fin[0]))
  time_dummy = fin[:]@StartTime_MOP03
      ;units value presumes use of TAI93 (International Atomic Time) format
      time_dummy@units = "seconds since 1993-1-1 00:00:00"
  yyyymm = cd_calendar(time_dummy,-1)
  ;ind_for_trend = ind(yyyymm.ge.200201.and.yyyymm.le.202012)
  ind_for_trend = ind(yyyymm.ge.200501.and.yyyymm.le.202112)
print(ind_for_trend)
  plottime = yyyymm(ind_for_trend)
  plottime_yfrac = cd_calendar(time_dummy(ind_for_trend),4)

  timeseries_in = fin[ind_for_trend]->RetrievedCOTotalColumnDay_MOP03
  dryair_in     = fin[ind_for_trend]->DryAirColumnDay_MOP03

  vmr_monthavg = timeseries_in/dryair_in


;--------------------------------------------
; Regional Average
;-------------------------------------------- 
  lat  = fin[0]->YDim_MOP03
  lon  = fin[0]->XDim_MOP03

  region_lat = ind(lat.le.topboundary.and.\
                 lat.ge.bottomboundary)
  region_lon = ind(lon.ge.leftboundary.and.\
                 lon.le.rightboundary)

  region_timeseries = vmr_monthavg(:,region_lon,region_lat)
  region_monthavg = dim_avg_n_Wrap(dim_avg_n_Wrap(region_timeseries,1),1)
   region_monthavg!0               = "time"
   region_monthavg&time            = plottime

  ; the lat and lon separation underestimates std
  region_monthstd = dim_stddev_n_Wrap(dim_stddev_n_Wrap(region_timeseries,1),1)
   region_monthstd!0               = "time"
   region_monthstd&time            = plottime

  ; a better estimate of std
  region_std =new(dimsizes(plottime), float)
   do m=0,dimsizes(plottime)-1
     ; calculate standard deviation
     region_std(m) = stddev(region_timeseries(m,:,:))
   end do ;month loop


;--------------------------------------------
; De-season
;--------------------------------------------  
  dataset_average = avg(region_monthavg)
   ;n_points = timeseries_dummy(:,(/8/))
   ;std_dev = timeseries_dummy(:,(/1/))

;--------------------------------------------
; Anomalies
;--------------------------------------------
; average annual cycle
  yyyymm_all = yyyymm_time(2002,yend,"integer")
  date_array = str_split_by_length(yyyymm_all,2)
  month_all = tointeger(date_array(:,2))
  plottime_all = yyyymm_to_yyyyfrac(yyyymm_all, 0)
  region_monthavg_ext = new(dimsizes(yyyymm_all), float)
  region_std_ext = new(dimsizes(yyyymm_all), float)

  climate_co_ext = new(dimsizes(yyyymm_all), float)

  ; account for MOPITT missing
  do t=0,dimsizes(plottime)-1
    ind_sel = ind(yyyymm_all.eq.tointeger(plottime(t)))
    region_monthavg_ext(ind_sel) = region_monthavg(t)
    region_std_ext(ind_sel) = region_std(t)
  end do

  region_monthavg_ext!0 = "time"
  region_monthavg_ext&time = yyyymm_all
  copy_VarMeta(region_monthavg_ext,region_std_ext)

  mopitt_date = cd_calendar(time_dummy(ind_for_trend),0)
  months = tointeger(mopitt_date(:,1))

  do i=0,11
     ; get indices of array related to specific month
     if ( .not.any(ismissing(ind(months.eq.(i+1)))) )
       print("months avail")
       month_ind := ind(months.eq.(i+1))
       co_to_avg := region_monthavg(month_ind)
       avg_co_month := dim_avg_n(co_to_avg,0)
       month_all_ind := ind(month_all.eq.(i+1))
       print("avg done")
       climate_co_ext(month_all_ind) = avg_co_month
     end if
  end do ;month loop

  copy_VarMeta(region_monthavg_ext,climate_co_ext)

  co_anomaly = region_monthavg_ext-climate_co_ext
  copy_VarMeta(region_monthavg_ext,co_anomaly)

 print("Done processing")
;--------------------------------------------
; Calculate trends
;--------------------------------------------
   ; Weighted Least Squares
   ; weighted by the standard deviation
   rc   = regline_weight(plottime_all,co_anomaly,region_std,1)
   ; Ordinary Least Squares
   rc2   = regline(plottime_all,co_anomaly)
   xave = avg(plottime_all)
   ;yave = avg(region_monthavg)
   yave = avg(co_anomaly)
   ols_trendplot = (yave + (rc*(plottime_all) + rc@yintercept))/1e-09 ;
   rc_perc = (rc/avg(region_monthavg))* 100
   ;se_perc = (rc2@rstd/avg(region_monthavg))* 100
   se_perc = (rc@std_rc/avg(region_monthavg))* 100

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

    res@xyLineThicknessF    = 10.0
    res@xyDashPatterns      = (/0,1,2,3,4/)

    res@tmBorderThicknessF  = 3.0
    res@tmXBMajorThicknessF = 3.0
    res@tmYLMajorThicknessF = 3.0

    res@tmYLMajorOutwardLengthF = 0.0               ; draw tickmarks inward
    res@tmYLMinorOutwardLengthF = 0.0               ; draw minor ticks inward
    res@tmXBMajorOutwardLengthF = 0.0               
    res@tmXBMinorOutwardLengthF = 0.0   

    ;res@trYMinF             = -45.
    ;res@trYMaxF             = 70.
    ;res@trYMinF             = -12.
    ;res@trYMaxF             = 22.
    res@trYMinF             = 50.
    res@trYMaxF             = 240.
    res@trXMinF             = 2004.
    res@trXMaxF             = yend

    res@vpWidthF             = 1
    res@vpHeightF            = 0.5          ; set height of plot

    res@tiMainString        = location + " month average carbon monoxide"
    ;res@tiMainString        = location + " month average carbon monoxide anomaly"
    res@tiXAxisString       = "Year"
    res@tiYAxisString       = "Column Average VMR (ppb)"
    ;res@tiYAxisString       = "Anomaly VMR (ppb)"

    res@pmLegendDisplayMode      = "Always"        ; turn on legend
    res@lgPerimOn                = False           ; Turn off perimeter
    res@pmLegendWidthF           = 0.25           ; Change width and
    res@pmLegendHeightF          = 0.20             ; height of legend
    res@lgLabelFontHeightF       = 0.024
    ;res@pmLegendParallelPosF     = 0.38
    res@pmLegendParallelPosF     = 0.05
    res@lgJustification          = "BottomLeft"

  ; -------------------------------
  ; create plot
  ; -------------------------------
    res@xyLineColors        = (/"black"/)
    ;res@xyExplicitLegendLabels   := (/"MOPITT CO anomaly ~F34~t~F~ standard deviation"/)
    res@xyExplicitLegendLabels   := (/"MOPITT CO"/)
    res@pmLegendOrthogonalPosF   = -1.355
    ;plot = gsn_csm_xy(wks,plottime_yfrac,region_monthavg/1e-09,res)
    ;plot = gsn_csm_xy(wks,plottime_yfrac,co_anomaly/1e-09,res)
    ;plot = gsn_csm_xy(wks,plottime_all,co_anomaly/1e-09,res)
    plot = gsn_csm_xy(wks,plottime_all,region_monthavg_ext/1e-09,res)
    res@tiMainString        = ""
    res@tiXAxisString       = ""
    res@tiYAxisString       = ""

    res@xyLineColors        = (/"grey"/)
    res@pmLegendOrthogonalPosF   = -1.255
    res@xyDashPatterns      := (/2/)
    res@xyExplicitLegendLabels   := (/"Climatological Annual Cycle"/)
    ;plot1 = gsn_csm_xy(wks,plottime_all,climate_co_ext/1e-09,res)
    ;overlay(plot, plot1)

  ; -------------------------------
  ; add standard deviation
  ; -------------------------------
   ya    = new( (/2*dimsizes(plottime_all)/), float )
   yb    = new( (/2*dimsizes(plottime_all)/), float )
   do k=0,dimsizes(plottime_all)-1
     ya(k) = tofloat(plottime_all(k))
     ;yb(k) = tofloat(co_anomaly(k)/1e-09+region_std_ext(k)/1e-09)
     ;yb(2*dimsizes(plottime_all)-1-k) = tofloat(co_anomaly(k)/1e-09-region_std_ext(k)/1e-09)
     yb(k) = tofloat(region_monthavg_ext(k)/1e-09+region_std_ext(k)/1e-09)
     yb(2*dimsizes(plottime_all)-1-k) = tofloat(region_monthavg_ext(k)/1e-09-region_std_ext(k)/1e-09)
     ya(2*dimsizes(plottime_all)-1-k) = tofloat(plottime_all(k))
   end do
    gsres                          = True                ; poly res
    gsres@gsFillColor            = "grey"                ; color chosen
    gsres@gsFillOpacityF         = 0.2                 
    dum2a = gsn_add_polygon(wks,plot,ya,yb,gsres)


  ; -------------------------------
  ; overlay trend
  ; -------------------------------
    res@xyLineColors        := (/"red"/)
    res@xyDashPatterns      := (/1/)
    res@xyExplicitLegendLabels   := (/"Trend: "+sprintf("%4.2g",rc_perc)+" ~F34~1 ~F21~"+sprintf("%3.1g",se_perc)+"% p.y."/)
    ;res@pmLegendOrthogonalPosF   = -1.155
    res@pmLegendOrthogonalPosF   = -1.255
    plot_t1 = gsn_csm_xy(wks,plottime_all,ols_trendplot,res)
    ;overlay(plot,plot_t1)

  ; -------------------------------
  ; add in zero line
  ; -------------------------------
    res@pmLegendDisplayMode = "Never"        ; turn on legend
    res@xyLineColors        := (/"grey"/)
    res@xyDashPatterns      := (/2/)
    res@xyCurveDrawOrder = "PreDraw"

    zero = (/0,0/)
    z_time = (/2000.0, 2024.0/)
      plot_z = gsn_csm_xy(wks,z_time,zero,res)
      ;overlay(plot,plot_z)


  ; -------------------------------
  ; add legend
  ; -------------------------------
    txres                   = True                     ; polyline mods desired
     txres@txFontHeightF    = 0.020                   ; font smaller. default big
     txres@txJust           = "CenterCenter"
     txres@txPerimOn        = False
     txres@txFontColor      = "blue"                  
    ;gsn_text_ndc(wks,"Theil-Sen",0.90,0.95,txres)
     txres@txFontColor      = "red"                  
    ;gsn_text_ndc(wks,"OLS",0.80,0.95,txres)


  draw(plot)
  frame(wks)

end if

;--------------------------------------------
; Write out to a ASCII file
;--------------------------------------------
if (CSV) then

;---Create dummy mixed data to write to CSV file
  ;fields = (/"time",     "tcol_co",  "stddev_co", "anomaly_co", "num_obs"/)
  fields = (/"time", "x_co", "stddev_x_co", "anomaly_x_co", "x_co_climatology"/)
  fields2 = (/"YYYYMM", "ppb", "ppb", "ppb", "ppb", ""/)
  dq = str_get_dq()                ; double quote character
  fields = dq + fields + dq                      ; Pre/append quotes to field names
  fields2 = dq + fields2 + dq                      ; Pre/append quotes to field names
  header = [/str_join(fields,",")/]              ; Header is field names separated
                                                 ;   by commas.
  header2 = [/str_join(fields2,",")/]            ; Header is field names separated
                                                 ;   by commas.

  region_monthavg@_FillValue    = -999.99
  co_anomaly@_FillValue         = -999.99

  alist  = [/toint(yyyymm_all),region_monthavg_ext/1e-09,co_anomaly/1e-09,region_std_ext/1e-09,climate_co_ext/1e-09/]   ; List of variables to write.
;; Note: if you don't want spaces in CSV file, use the following format string.
 format = "%d,%g,%g,%g,%g"

  system("rm -rf " + outname)               ; Remove file in case it exists.

  write_table(outname, "w", header, "%s")   ; Write header to CSV file.
  write_table(outname, "a", header2, "%s")   ; Write units to CSV file.
  write_table(outname, "a", alist, format)  ; Write mixed data to CSV file.


;---Echo the new file to the screen so you can see it.
  print("====== Contents of '" + outname + "' ======")
  system("cat " + outname)
  print("========================================")
end if ;CSV


end

