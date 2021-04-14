;  modis_seasonal_cycles.ncl 
;=======================================================;
;
; Concepts illustrated:
;   - For use with TERRA/MODIS extracted seasonal cycles
;
;   Files needed:
;         -MODIS extracted seasonal cycles
;
;   To run type:
;         > ncl modis_seasonal_cycles.ncl
;                                  RRB Novemner 18, 2019
;=======================================================;
; load the libraries
load "~/code_database/ncl_programs/buchholz_global_util/calc_seasonal_cycle.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------
location = "EastUSA"

  ; -------------------------------
  ; MODIS
  ; -------------------------------
  ;timeseries_files = systemfunc ("ls /IASI/home/buchholz/MODIS/modis_terra_aod_climNstdNcnt_19regions.dat")
  ;timeseries_files = systemfunc ("ls /IASI/home/buchholz/MODIS/modis_terra_aod_climNstdNcnt_3usregions.dat")
  timeseries_files = systemfunc ("ls /IASI/home/buchholz/MODIS/modis_aod_terra_3usrgns_95N25N75thNmean_allyrs_new.dat")

print(timeseries_files)


  ;------------
  ; toggles
  ;------------
  PLOT           = True
    plttype      = "x11"
    ;plttype@wkPaperSize = "A4"
    ;plttype@wkWidth = 0.5
    ;plttype@wkHeight = 0.5
    year_e = 2017

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
   ;region_names = (/"AnthChina", "AnthIndi", "AnthEuro", "AnthUSA",\
   ;                 "BBUSA", "BBCanada", "BBSiberia", "BBWRus",\
   ;                 "BBCAmerica", "BBSAmerica","BBSAmOcean",\
   ;                  "BBCAfrica", "BBSAfrica","BBSAfOcean", \
   ;                 "BBMSEA", "BBNWAu","BBEAu", "NH_monthly", "SH_monthly"/)

   region_names = (/"PNW", "CentralUSA", "EastUSA"/)
  ; -------------------------------
  ; OUTPUT RELATED SETUP
  ; -------------------------------
  if (PLOT) then
    pltdir       = "./"
    pltname      = "modis_seasonal_cycle" + location
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
  ; MODIS
  ; -------------------------------
     print("Collecting MODIS")
   modis_infile = timeseries_files(0)
     ;---Read the values in as 1D, since we don't know rows and columns yet.
     lines  := asciiread(modis_infile,-1,"string")
     delim  = " "
     ncols  := dimsizes(str_split(lines(3),delim))
     nlines := dimsizes(lines)
     print("Columns:"+ncols+", Lines:"+nlines)

     ;---Reshape as 2D array, and convert to float for ppm/ppb/ppt.
     ; climatology, stddev, data count for 1st period then 2nd period
     fields := new((/nlines-1,ncols/),float)
      do nf=0,ncols-1                    ;Remember that fields start at 1, not 0.
        fields(:,nf) = tofloat(str_get_field(lines(1:),nf+1,delim)) 
      end do

   nyears = 18
   ind_for_plot = ind(region_names.eq.location)
   start_index = (nyears*2)*ind_for_plot
   start_index_95 = (nyears*2)*(ind_for_plot+3)
   start_index_25 = (nyears*2)*(ind_for_plot+6)
   start_index_75 = (nyears*2)*(ind_for_plot+9)
   start_index_num = (nyears*2)*(ind_for_plot+12)

  time_dummy = yyyymm_time(2002,2019,"integer")
      ind_for_trend = ind(time_dummy.ge.200201.and.time_dummy.le.201812)
      time = time_dummy(ind_for_trend)
    split_dates = str_split_by_length(tostring(time),4)
    yfrac = yyyymm_to_yyyyfrac(time,0.5)

  timeseries_dummy = new((/dimsizes(time_dummy),5/), "float")
    ;vmn_all,v95_all,v25_all,v75_all,vct_all
    timeseries_dummy(:,0) = ndtooned(fields(start_index_25:start_index_25+nyears*2-1,:))
    timeseries_dummy(:,1) = ndtooned(fields(start_index:start_index+nyears*2-1,:))
    timeseries_dummy(:,2) = ndtooned(fields(start_index_75:start_index_75+nyears*2-1,:))
    timeseries_dummy(:,3) = ndtooned(fields(start_index_95:start_index_95+nyears*2-1,:))
    timeseries_dummy(:,4) = ndtooned(fields(start_index_num:start_index_num+nyears*2-1,:))
    name_array = (/"25th", "mean", "75th", "95th"/)

   timeseries = timeseries_dummy(ind_for_trend,1)
   dataset_average = avg(timeseries)
   n_points = timeseries_dummy(ind_for_trend,4)

print(timeseries)
print(time)
;exit

  ; -------------------------------
  ; detrend
  ; -------------------------------
    ystart = 2002
    ymid = (tofloat(2018-2002))/2

printVarSummary(timeseries)

print(timeseries(0:10))

    smooth_val         = runave(timeseries,12,0)
    detrend_val_smooth = dtrend_msg_n (yfrac,smooth_val,False,True,0)
    detrend_val = timeseries - detrend_val_smooth@slope*(yfrac-ystart-ymid-0.5)

   ;timeseries = (/detrend_val/)

printVarSummary(timeseries)
print(timeseries(0:10))


  ; -------------------------------
  ; Avg seasonal cycle
  ; -------------------------------
  modis_seas_avg_a = calc_seasonal_cycle(timeseries,time,2002,2011, 12)
  modis_seas_avg_b = calc_seasonal_cycle(timeseries,time,2012,2018, 12)


print(modis_seas_avg_a)
print(modis_seas_avg_b)

  ; -------------------------------
  ; CALCULATE SIGNIFICANCE
  ; -------------------------------
var_a = modis_seas_avg_a(:,1)*modis_seas_avg_a(:,1)
var_b = modis_seas_avg_b(:,1)*modis_seas_avg_b(:,1)
num_a = modis_seas_avg_a(:,0)*0
num_a = 10
num_b = modis_seas_avg_b(:,0)*0
num_b = 7

t_test_result = ttest(modis_seas_avg_a(:,0),var_a,num_a,modis_seas_avg_b(:,0),var_b,num_b,False,True)
print(t_test_result)


sig_a = where(t_test_result(0,:).lt.(0.05), modis_seas_avg_a(:,0), modis_seas_avg_a@_FillValue)
sig_b = where(t_test_result(0,:).lt.(0.05), modis_seas_avg_b(:,0), modis_seas_avg_b@_FillValue)
sig_a01 = where(t_test_result(0,:).lt.(0.01), modis_seas_avg_a(:,0), modis_seas_avg_a@_FillValue)
sig_b01 = where(t_test_result(0,:).lt.(0.01), modis_seas_avg_b(:,0), modis_seas_avg_b@_FillValue)

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

      res@trYMaxF             = 0.5
      res@trYMinF             = 0.05
    ;res@tmYLMode        = "Manual"	
    ;  res@tmYLTickStartF  = 0.0
    ;  res@tmYLTickEndF    = 4.5
    ;  res@tmYLTickSpacingF= 0.5
    ;  res@tmYLLabelFontHeightF = 0.028
    ;  res@tiYAxisFontHeightF  = 0.028

    res@trXMinF             = -0.5
    res@trXMaxF             = 11.5
    res@tmXBMode              = "Explicit"
      res@tmXBValues           = modis_seas_avg_a&month
      res@tmXBLabels           = (/"Jan", "Feb", "Mar", "Apr", "May", "Jun",\
                                   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"/)
      res@tiXAxisString          = "Year"
      ;res@tmXBLabelsOn = False
      res@tmXBLabelFontHeightF = 0.028
      res@tiXAxisFontHeightF  = 0.028

    res@tmYLMajorOutwardLengthF = 0.0               ; draw tickmarks inward
    res@tmYLMinorOutwardLengthF = 0.0               ; draw minor ticks inward
    res@tmXBMajorOutwardLengthF = 0.0               
    res@tmXBMinorOutwardLengthF = 0.0              

    res@vpWidthF             = 1.0
    res@vpHeightF            = 0.5          ; set height of plot
    ;res@vpYF                 = 1.0

    res@tiMainString        = ""
    res@tiXAxisString       = "Month"
    res@tiYAxisString       = "AOD at 550 nm"
    res@gsnLeftString       = location

  ; -------------------------------
  ; timeseries - weekly averages and climatology
  ; -------------------------------
  res@pmLegendDisplayMode      = "Never"        ; turn on legend
    res@xyLineColor         = "black"
    res@xyLineThicknessF    = 10.5
    res@xyDashPatterns      =0
  plot1 = gsn_csm_xy(wks,modis_seas_avg_a&month,modis_seas_avg_a(:,0),res)


    res@gsnLeftString       = ""
    res@xyLineColor         = "red3"
    res@xyDashPatterns      =2
  plot2 = gsn_csm_xy(wks,modis_seas_avg_b&month,modis_seas_avg_b(:,0),res)
  overlay(plot1, plot2)

  ; -------------------------------
  ; add std dev
  ; -------------------------------

  ; -------------------------------
  ; Define a polygon for std-dev
  ; -------------------------------
   month_time = modis_seas_avg_a&month
   ya1    = new( (/2*dimsizes(month_time)/), float )
   yb1    = new( (/2*dimsizes(month_time)/), float )
   do k=0,dimsizes(month_time)-1
     ya1(k) = month_time(k)
     yb1(k) = tofloat((modis_seas_avg_a(k,0)+modis_seas_avg_a(k,1)))
     yb1(2*dimsizes(month_time)-1-k) = tofloat((modis_seas_avg_a(k,0)-modis_seas_avg_a(k,1)))
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
     yb2(k) = tofloat((modis_seas_avg_b(k,0)+modis_seas_avg_b(k,1)))
     yb2(2*dimsizes(month_time)-1-k) = tofloat((modis_seas_avg_b(k,0)-modis_seas_avg_b(k,1)))
     ya2(2*dimsizes(month_time)-1-k) = month_time(k)
   end do
    gsres                          = True                ; poly res
    gsres@gsFillColor            = "indianred2"                ; color chosen
    gsres@gsFillOpacityF         = 0.3                 
    dum2a = gsn_add_polygon(wks,plot2,ya2,yb2,gsres)

  ; -------------------------------
  ; plot significant points
  ; -------------------------------
    res@xyMarkLineModes = "Markers"
    res@xyMarkerColors = "black"
    res@xyMarkers = 16
    res@xyMarkerSizeF    = 15.5
  plot1s = gsn_csm_xy(wks,modis_seas_avg_a&month,sig_a,res)
    res@xyMarkerSizeF    = 25.5
  plot1s01 = gsn_csm_xy(wks,modis_seas_avg_a&month,sig_a01,res)
  overlay(plot1, plot1s)
  overlay(plot1, plot1s01)

    res@xyMarkerColors = "red3"
    res@xyMarkerSizeF    = 15.5
  plot2s = gsn_csm_xy(wks,modis_seas_avg_b&month,sig_b,res)
    res@xyMarkerSizeF    = 25.5
  plot2s01 = gsn_csm_xy(wks,modis_seas_avg_a&month,sig_b01,res)
  overlay(plot1, plot2s)
  overlay(plot1, plot2s01)

  ; add label
    txres                   = True                     ; polyline mods desired
     txres@txFontHeightF    = 0.018                   ; font smaller. default big
     txres@txJust           = "CenterCenter"
     txres@txPerimOn        = False
     txres@txFontColor      = "black" 
    pmres = True
    pmres@gsMarkerIndex = 16
    pmres@gsMarkerSizeF = 0.010
    pmres@gsMarkerColor := "black"
    gsn_polymarker_ndc (wks,0.15,0.67,pmres)
    gsn_text_ndc(wks,"p < 0.05",0.214,0.67,txres)
    pm01res = True
    pm01res@gsMarkerIndex = 16
    pm01res@gsMarkerSizeF = 0.020
    pm01res@gsMarkerColor := "black"
    gsn_polymarker_ndc (wks,0.15,0.69,pm01res)
    gsn_text_ndc(wks,"p < 0.01",0.214,0.69,txres)


  ; -------------------------------
  ; ADD CUSTOM TEXT
  ; -------------------------------
  ;drawNDCGrid(wks)
  ; STATIONS
  txres                   = True                ; polyline mods desired
  txres@txFontHeightF = 0.022                   ; font smaller. default big
  txres@txJust = "CenterLeft"                   ; font smaller. default big
  txres@txFontColor = "black"
  gsn_text_ndc(wks,"MODIS 2002-2011",0.68,0.69,txres)
  txres@txFontColor = "red3"
  gsn_text_ndc(wks,"MODIS 2012-2018",0.68,0.66,txres)

  ; -------------------------------
  ; DRAW IT OUT
  ; -------------------------------
  draw(plot1)
  frame(wks)

end if



end

