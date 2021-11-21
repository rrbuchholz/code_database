;=======================================================;
;  mopitt_seasonal_cycles.ncl 
;=======================================================;
;
; Concepts illustrated:
;   - For use with MOPITT CO version 8, region avg data
;   - loading CO data
;   - monthly mean values
;   - whole dataset average month values
;
;   Files needed:
;         -MOPITT subset of level 2, daily hdf files
;
;   To run type:
;         > ncl mopitt_seasonal_cycles.ncl
;                                  RRB Octoeber 20, 2019
;=======================================================;
; load the libraries
load "~/code_database/ncl_programs/buchholz_global_util/calc_seasonal_cycle.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------
location = "Colorado"
plot_title = "Colorado"

  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  ;timeseries_files = systemfunc ("ls /IASI/home/buchholz/MOPITT_subset/V9/"+location+"_V9T*monthavg_VMR.nc")
  timeseries_files = systemfunc ("ls /IASI/home/buchholz/MOPITT_subset/regions_v8/"+location+"_*monthavg_VMR.nc")
  ;timeseries_files = systemfunc ("ls /IASI/home/buchholz/MOPITT_subset/regions_v8/seasonal_change_ext_1/"+location+"_*monthavg_VMR.nc")
print(timeseries_files)

  ;------------
  ; toggles
  ;------------
  PLOT           = True
    plttype      = "x11"
    ;plttype@wkPaperSize = "A4"
    ;plttype@wkWidth = 0.5
    ;plttype@wkHeight = 0.5
    miny=90
    maxy=170

  PLOTFTS        = True
  
;--------------------------------------------
; end user input
;--------------------------------------------
;
;--------------------------------------------
; set up
;--------------------------------------------
  ; -------------------------------
  ; REGION PARAMETERS
  ; -------------------------------
   region_names = (/"AnthChina", "AnthIndi", "AnthEuro", "AnthUSA",\
                    "BBUSA", "BBCanada", "BBSiberia", "BBWRus",\
                    "BBCAmerica", "BBSAmerica","BBSAmOcean",\
                     "BBCAfrica", "BBSAfrica","BBSAfOcean", \
                    "BBMSEA", "BBNWAu","BBEAu", "NH_monthly", "SH_monthly"/)
  ; -------------------------------
  ; OUTPUT RELATED SETUP
  ; -------------------------------
  if (PLOT) then
    pltdir       = "./"
    pltname      = "mopitt_seasonal_cycle" + location
  end if

  ; -------------------------------
  ; CONSTANTS
  ; -------------------------------                                          
   NAv    = 6.0221415e+23                    ;--- Avogadro's number
   g      = 9.81                             ;--- m/s - gravity
   H = (8.314*240)/(0.0289751*9.8)           ;--- scale height
   MWair = 28.94                             ;--- g/mol
   xp_const = (NAv* 10)/(MWair*g)*1.0e-09    ;--- scaling factor for turning vmr into pcol
                                             ;--- (note 1*e-09 because in ppb)

;--------------------------------------------
; load file and extract
;--------------------------------------------
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  ; read data from region
  fin = addfiles(timeseries_files, "r")            ; read in
    ListSetType (fin, "cat")                 ; concatenate
    ; Column vmr
    ;timeseries_dummy  = fin[:]->RetrievedX_CORegionStats
    ;scale = 1e-09
    ;global_trend = -0.5*1e-09
    ; Surface vmr
    ;timeseries_dummy  = fin[:]->AvgRetrievedCOMixingRatioProfile
    timeseries_dummy  = fin[:]->AvgSurfaceVMR
    ;global_trend = -0.5
    global_trend = 0.
    scale = 1

    dfs_dummy = fin[:]->AvgDegreesofFreedomforSignal


;printVarSummary(timeseries_dummy)
;exit

    time_dummy        = fin[:]->time
     date_dummy  = str_split_by_length(tostring(time_dummy),4)
     years_dummy        = tointeger(date_dummy(:,0))
     ind_start = ind(years_dummy.gt.2001)
     ind_end = ind(years_dummy.le.2018)


    time       = time_dummy(ind_start(0):ind_end(dimsizes(ind_end)-1))
     mopitt_date  = str_split_by_length(tostring(time),4)
     years        = tointeger(mopitt_date(:,0))
     months       = tointeger(mopitt_date(:,1))
     mopitt_yfrac = yyyymm_to_yyyyfrac(time,0.5)
    ; For temp surface layers
    ;timeseries = dim_avg_n(timeseries_dummy(ind_start(0):ind_end(dimsizes(ind_end)-1),0:1),1)
    ; For column vals and true surface layer
    timeseries = timeseries_dummy(ind_start(0):ind_end(dimsizes(ind_end)-1),0)
    dfs = dfs_dummy(ind_start(0):ind_end(dimsizes(ind_end)-1))

;print("DFS average = "+ avg(dfs))
;print(time+" "+timeseries)

;exit

  ; -------------------------------
  ; detrend
  ; -------------------------------
    ystart = 2002
    ymid = (tofloat(2018-2002))/2

    smooth_val         = runave(timeseries,12,0)
    detrend_val_smooth = dtrend_msg_n (mopitt_yfrac,smooth_val,False,True,0)
    ;detrend_val = timeseries - detrend_val_smooth@slope*(mopitt_yfrac-ystart-ymid-0.5)
    detrend_val = timeseries - (global_trend*(mopitt_yfrac-ystart-ymid-0.5))

   timeseries = (/detrend_val/)

  ; -------------------------------
  ; Avg seasonal cycle
  ; -------------------------------
  mopitt_seas_avg_a = calc_seasonal_cycle(timeseries,time,2002,2011, 12)
;print(mopitt_seas_avg_a)
  mopitt_seas_avg_b = calc_seasonal_cycle(timeseries,time,2012,2018, 12)
;print(mopitt_seas_avg_b)

;--------------------------------------------
; Deaseasonalize
;--------------------------------------------
  mopitt_seas_avg_c = new((/12, 2/), float)
  mopitt_seas_avg_d = new((/12, 2/), float)
  ind_1sthalf = ind(years.lt.2011.and.years.ge.2002)
  ind_2ndhalf = ind(years.ge.2012.and.years.lt.2018)
  timeseries_c = timeseries(ind_1sthalf)
  months_c = months(ind_1sthalf)
  timeseries_d = timeseries(ind_2ndhalf)
  months_d = months(ind_2ndhalf)

  do i=0,11
     ; get indices of array related to specific month
     month_ind_c := ind(months_c.eq.(i+1))
     co_to_avg_c := timeseries_c(month_ind_c)
     mopitt_seas_avg_c(i,0) = dim_avg_n(co_to_avg_c,0)

     month_ind_d := ind(months_d.eq.(i+1))
     co_to_avg_d := timeseries_d(month_ind_d)
     mopitt_seas_avg_d(i,0) = dim_avg_n(co_to_avg_d,0)
  end do


   
  ; -------------------------------
  ; PRINT SEASONAL CYCLE INFORMATION
  ; -------------------------------
;   name_array = (/"MOPITT 2001-2009", "MOPITT 2010-2018"/)
;   peak_date = new(dimsizes(name_array), double)
;   max_vals = new(dimsizes(name_array), double)
;     max_vals(0) = max(mopitt_seas_avg(:,0))/avg(mopitt_seas_avg(:,0))
;     peak_day = ind(mopitt_seas_avg(:,0).eq.max(mopitt_seas_avg(:,0)))
;     peak_date(0) = monthday(2004,Clm_doy(peak_day))
;     max_vals(1) = max(fts_seas_avg(:,0))/avg(fts_seas_avg(:,0))
;     peak_day = ind(fts_seas_avg(:,0).eq.max(fts_seas_avg(:,0)))
;     peak_date(1) = monthday(2004,Clm_doy(peak_day))
;   min_vals = new(dimsizes(name_array), double)
;     min_vals(0) = min(mopitt_seas_avg(:,0))/avg(mopitt_seas_avg(:,0))
;     min_vals(1) = min(fts_seas_avg(:,0))/avg(fts_seas_avg(:,0))

;   peak_to_trough = max_vals-min_vals

;   print("******************************")
;   print(name_array+" Peak-to-trough: "+sprintf("%6.4g",peak_to_trough*100) \
;         + "%; Peak date (MMDD): "+peak_date)

var_a = mopitt_seas_avg_a(:,1)/scale*mopitt_seas_avg_a(:,1)/scale
var_b = mopitt_seas_avg_b(:,1)/scale*mopitt_seas_avg_b(:,1)/scale
num_a = mopitt_seas_avg_a(:,0)*0
num_a = 10
; Note different num_a for August
num_a(7)=9
num_b = mopitt_seas_avg_b(:,0)*0
num_b = 7
df = num_a+num_b-2
pooled_sd = sqrt((var_a+var_b)/2)
pooled_sd_2 = sqrt(((num_a-1)*var_a+(num_b-1)*var_b)/(num_a+num_b-2))
mean1 = mopitt_seas_avg_a(:,0)/scale
mean2 = mopitt_seas_avg_b(:,0)/scale
cohen_d = abs(mean1-mean2)/pooled_sd
t_test_result = ttest(mean1,var_a,num_a,mean2,var_b,num_b,False,True)
print(t_test_result)

;---- 95 % t= 2.447, 90% t = 1.934
CI_lb = (mean1-mean2)-1.934*sqrt(var_a/num_a+var_b/num_b)
CI_ub = (mean1-mean2)+1.934*sqrt(var_a/num_a+var_b/num_b)
mean_diff = (mopitt_seas_avg_a(:,0)-mopitt_seas_avg_b(:,0))/scale

;print(mopitt_seas_avg_a(:,0)/scale)
;print(mopitt_seas_avg_b(:,0)/scale)

print(pooled_sd(7))
print(pooled_sd_2(7)-pooled_sd(7))
print("*****************************")
print("August t-test results:")
print("p-value =   " + sprintf("%9.3f",t_test_result(0,7)) )
print("t-value =   " + sprintf("%9.3f", t_test_result(1,7)) )
print("df =        " + df(7))
print("Cohen's d = " + sprintf("%9.3f", cohen_d(7)) )
print("95%CI =     " + sprintf("%9.3f", CI_lb(7))+ ";" +sprintf("%9.3f", CI_ub(7)) )
print("Mean diff = " + sprintf("%9.3f", mean_diff(7)) )
print("*****************************")
print("All t-test results:")
print("95%CI =     " + sprintf("%9.3f", CI_lb(:))+ ";" +sprintf("%9.3f", CI_ub(:)) )

sig_a = where(t_test_result(0,:).lt.(0.05), mopitt_seas_avg_a(:,0), mopitt_seas_avg_a@_FillValue)
sig_b = where(t_test_result(0,:).lt.(0.05), mopitt_seas_avg_b(:,0), mopitt_seas_avg_b@_FillValue)
sig_a01 = where(t_test_result(0,:).lt.(0.01), mopitt_seas_avg_a(:,0), mopitt_seas_avg_a@_FillValue)
sig_b01 = where(t_test_result(0,:).lt.(0.01), mopitt_seas_avg_b(:,0), mopitt_seas_avg_b@_FillValue)

;********************************************
;--------------------------------------------
; plot
;--------------------------------------------
if (PLOT) then

  wks = gsn_open_wks(plttype,pltname)        
  gsn_define_colormap(wks,"BlAqGrYeOrRe")  
   
  res                       = True                      ; plot mods desired
    res@gsnDraw		    = False	                ; don't draw it yet
    res@gsnFrame            = False                     ; don't advance frame
    res@gsnMaximize         = True

      res@trYMaxF             = maxy
      res@trYMinF             = miny
      res@tmYLMode        = "Manual"	
      res@tmYLTickStartF  = miny
      res@tmYLTickEndF    = maxy
      res@tmYLTickSpacingF= 20
      ;res@tmYLTickStartF  = 180
      ;res@tmYLTickEndF    = 180

    res@trXMinF             = -0.5
    res@trXMaxF             = 11.5

    res@tmXBMode              = "Explicit"
      res@tmXBValues           = mopitt_seas_avg_a&month(1::2)
      res@tmXBLabels           = (/"Feb", "Apr", "Jun",\
                                   "Aug", "Oct", "Dec"/)
      ;res@tmXBLabels           = (/"Jan", "Feb", "Mar", "Apr", "May", "Jun",\
      ;                             "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"/)
      res@tiXAxisString          = "Year"
      ;res@tmXBLabelsOn = False
      res@tmXBLabelFontHeightF = 0.048
      res@tmYLLabelFontHeightF = 0.048
      res@tiYAxisFontHeightF  = 0.048
      res@tiXAxisFontHeightF  = 0.048

    res@tmYLMajorOutwardLengthF = 0.0               ; draw tickmarks inward
    res@tmYLMinorOutwardLengthF = 0.0               ; draw minor ticks inward
    res@tmXBMajorOutwardLengthF = 0.0               
    res@tmXBMinorOutwardLengthF = 0.0  

    res@tmYROn = False            ; Turn off right tickmarks.
    res@tmXTOn = False            ; Turn off top tickmarks.    

    res@vpWidthF             = 1.0
    res@vpHeightF            = 0.5          ; set height of plot
    ;res@vpYF                 = 1.0

    res@tiMainString        = ""
    res@tiXAxisString       = "Month"
    ;res@tiYAxisString       = "X~B2~CO~N~    (ppb)"
    ;res@tiYAxisString       = "Column CO (ppb)"
    res@tiYAxisString       = "Surface CO (ppb)"
    ;res@tiYAxisString       = "DFS"
    ;res@gsnLeftString       = location + " surface"
    res@gsnLeftString       = plot_title                 ; change left 
    ;res@gsnLeftString       = "Colorado surface CO, detrended"

    ;res@pmLegendDisplayMode      = "Never"        ; turn on legend
    res@pmLegendDisplayMode      = "Always"        ; turn on legend
    res@lgPerimOn                = False           ; Turn off perimeter
    res@pmLegendWidthF           = 0.15            ; Change width and
    res@pmLegendHeightF          = 0.20            ; height of legend
    res@lgLabelFontHeightF       = 0.042
    res@lgJustification          = "Centerleft"
    res@pmLegendParallelPosF     = 0.60

  ; -------------------------------
  ; timeseries - weekly averages and climatology
  ; -------------------------------
    res@xyExplicitLegendLabels   = "2002-2011"
    res@pmLegendOrthogonalPosF   = -1.42
    res@xyLineColor         = "black"
    res@xyLineThicknessF    = 10.5
    res@xyDashPatterns      =0
  plot1 = gsn_csm_xy(wks,mopitt_seas_avg_a&month,mopitt_seas_avg_a(:,0)/scale,res)


    res@xyExplicitLegendLabels   = "2012-2020"
    res@pmLegendOrthogonalPosF   = -1.53
    res@lgLabelFontColor       = "blue3"
    res@gsnLeftString       = ""
    res@xyLineColor         = "blue3"
    res@xyDashPatterns      =1
  plot2 = gsn_csm_xy(wks,mopitt_seas_avg_b&month,mopitt_seas_avg_b(:,0)/scale,res)
  overlay(plot1, plot2)

    res@pmLegendDisplayMode      = "Never"        ; turn on legend

  ; -------------------------------
  ; add std dev
  ; -------------------------------

  ; -------------------------------
  ; Define a polygon for std-dev
  ; -------------------------------
   month_time = mopitt_seas_avg_a&month
   ya1    = new( (/2*dimsizes(month_time)/), float )
   yb1    = new( (/2*dimsizes(month_time)/), float )
   do k=0,dimsizes(month_time)-1
     ya1(k) = month_time(k)
     yb1(k) = tofloat((mopitt_seas_avg_a(k,0)+mopitt_seas_avg_a(k,1))/scale)
     yb1(2*dimsizes(month_time)-1-k) = tofloat((mopitt_seas_avg_a(k,0)-mopitt_seas_avg_a(k,1))/scale)
     ya1(2*dimsizes(month_time)-1-k) = month_time(k)
   end do
    gsres                          = True                ; poly res
    gsres@gsFillColor            = "gray60"                ; color chosen
    gsres@gsFillOpacityF         = 0.3                 
    dum1a = gsn_add_polygon(wks,plot1,ya1,yb1,gsres)

  ; -------------------------------
  ; Define a polygon for std-dev
  ; -------------------------------
   ya2    = new( (/2*dimsizes(month_time)/), float )
   yb2    = new( (/2*dimsizes(month_time)/), float )
   do k=0,dimsizes(month_time)-1
     ya2(k) = month_time(k)
     yb2(k) = tofloat((mopitt_seas_avg_b(k,0)+mopitt_seas_avg_b(k,1))/scale)
     yb2(2*dimsizes(month_time)-1-k) = tofloat((mopitt_seas_avg_b(k,0)-mopitt_seas_avg_b(k,1))/scale)
     ya2(2*dimsizes(month_time)-1-k) = month_time(k)
   end do
    gsres                          = True                ; poly res
    gsres@gsFillColor            = "skyblue"                ; color chosen
    gsres@gsFillOpacityF         = 0.3                 
    dum2a = gsn_add_polygon(wks,plot2,ya2,yb2,gsres)

  ; -------------------------------
  ; plot significant points
  ; -------------------------------
    res@xyMarkLineModes = "Markers"
    res@xyMarkerColors = "black"
    res@xyMarkers = 16
    res@xyMarkerSizeF    = 25.5
  plot1s = gsn_csm_xy(wks,mopitt_seas_avg_a&month,sig_a/scale,res)
    res@xyMarkerSizeF    = 25.5
  ;plot1s01 = gsn_csm_xy(wks,mopitt_seas_avg_a&month,sig_a01/scale,res)
  overlay(plot1, plot1s)
  ;overlay(plot1, plot1s01)

    res@xyMarkerColors = "blue3"
    res@xyMarkerSizeF    = 25.5
  plot2s = gsn_csm_xy(wks,mopitt_seas_avg_b&month,sig_b/scale,res)
    res@xyMarkerSizeF    = 25.5
  ;plot2s01 = gsn_csm_xy(wks,mopitt_seas_avg_a&month,sig_b01/scale,res)
  overlay(plot1, plot2s)
  ;overlay(plot1, plot2s01)

  ; add label
    txres                   = True                     ; polyline mods desired
     txres@txFontHeightF    = 0.032                   ; font smaller. default big
     txres@txJust           = "CenterCenter"
     txres@txPerimOn        = False
     txres@txFontColor      = "black" 
    pmres = True
    pmres@gsMarkerIndex = 16
    pmres@gsMarkerSizeF = 0.012
    pmres@gsMarkerColor := "black"
    gsn_polymarker_ndc (wks,0.72,0.60,pmres)
    gsn_text_ndc(wks,"p < 0.05",0.816,0.60,txres)
  ;  pm01res = True
  ;  pm01res@gsMarkerIndex = 16
  ;  pm01res@gsMarkerSizeF = 0.020
  ;  pm01res@gsMarkerColor := "black"
   ; gsn_polymarker_ndc (wks,0.15,0.72,pm01res)
   ; gsn_text_ndc(wks,"p < 0.01",0.214,0.72,txres)


  ; -------------------------------
  ; ADD CUSTOM TEXT
  ; -------------------------------
  ;drawNDCGrid(wks)
  ; STATIONS
  txres                   = True                ; polyline mods desired
  txres@txFontHeightF = 0.028                   ; font smaller. default big
  txres@txJust = "CenterLeft"                   ; font smaller. default big
  txres@txFontColor = "black"
  ;gsn_text_ndc(wks,"MOPITT 2002-2011",0.60,0.69,txres)
  txres@txFontColor = "blue3"
  ;gsn_text_ndc(wks,"MOPITT 2012-2018",0.60,0.66,txres)

  ; -------------------------------
  ; DRAW IT OUT
  ; -------------------------------
  draw(plot1)
  frame(wks)

end if



end

