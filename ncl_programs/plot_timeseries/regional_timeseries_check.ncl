;=======================================================;
;  regional_timeseries.ncl 
;=======================================================;
;
; Concepts illustrated:
;   - For use with MOPITT CO month anomalies
;     - load CO data
;     - calculate OLS trend
;     - plot
;
;   Files needed:
;         -MOPITT extractions
;         -Other instruments if desired: IASI, AIRS. Use Booleans.
;
;   To run type:
;         ncl regional_timeseries.ncl 
;                                  RRB May 7, 2019
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
  location = "NH"
  location_name = "NH"
    pltname      = "/net/mopfl/home/buchholz/"+location+"_trend"
  maxlag = 12
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  timeseries_files = systemfunc ("ls /IASI/home/buchholz/data/"+location+"_CO_instruments.csv")
print(timeseries_files)

  ;scale_factor = 1e18              ;column
  ;unit = "~F34~4~F21~10~S2~18   molec. cm~S2~-2"
  ;yaxis = "Total column"

  ;scale_factor = 1e-09              ;vmr
  ;unit = "ppb"
  ;yaxis = "Column average VMR (" +unit +")"
  scale_factor = 1                 ;normalized
  ;yaxis = "Normalized CO"

  yaxis = "CO Anomaly (ppb)"
  unit = "ppb"

  ;------------
  ; toggles
  ;------------
  PLOT           = True
    plttype      = "x11"
    ;plttype@wkPaperSize = "A4"
      plttype@wkWidth = 1200
      plttype@wkHeight = 1200
      plot_title = "Test"
 
   ADD_IASI      = True
      iasia_infiles = systemfunc ("ls /IASI/home/buchholz/IASI_subset/IASI_FORLI_CO_LATMOS_ULB_MetopA_day_monthlyMeans_*_v2.txt")
      iasib_infiles = systemfunc ("ls /IASI/home/buchholz/IASI_subset/IASI_FORLI_CO_LATMOS_ULB_MetopB_day_monthlyMeans_*_v2.txt")

   ADD_AIRS      = True
     if (location.eq."NH") then
       airs_infile = "/IASI/home/buchholz/AIRS/Data_for_Helen_NH.txt"
     else
       airs_infile = "/IASI/home/buchholz/AIRS/Data_for_Helen_SH.txt"
     end if

   ADD_TES      = True
     tes_infile = "/IASI/home/buchholz/TES/TES_xCO_monthly_n_s_V007.txt"

   ADD_CRIS      = True
     ;cris_infile = "/IASI/home/buchholz/CrIS/CrIS_20191017.txt"
     cris_infile = "/IASI/home/buchholz/CrIS/CrIS_PASS1_and_PASS220191118.csv"

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
     ;---Read the values in as 1D, since we don't know rows and columns yet.
     lines  := asciiread(timeseries_files,-1,"string")
     delim  = ","
     ncols  := dimsizes(str_split(lines(3),delim))
     nlines := dimsizes(lines)
     print("Columns:"+ncols+", Lines:"+nlines)

     ;---Reshape as 2D array, and convert to float for ppm/ppb/ppt.
     fields := new((/nlines-2,ncols/),float)
      do nf=0,ncols-1                    ;Remember that fields start at 1, not 0.
        fields(:,nf) = tofloat(str_get_field(lines(2:),nf+1,delim)) 
      end do
      fields@_FillValue = -9999

    time        = fields(:,0)
    split_dates = str_split_by_length(tostring(time),4)
    yfrac = yyyymm_to_yyyyfrac(time,0.5)
    timeseries = fields(:,(/1,2,2/))
    timeseries_sd = fields(:,(/2/))
     timeseries(:,1) = timeseries(:,0)+timeseries_sd
     timeseries(:,2) = timeseries(:,0)-timeseries_sd
    name_array = (/"MOPITT", "+std_dev","-std_dev"/)


   if (ADD_IASI) then
   ; convert IASI to column average VMR

       iasia_yyyymm = time
       yfrac_iasia = yfrac

       iasib_yyyymm = time
       yfrac_iasib = yfrac

       ; Convert to X_CO
       iasia_xco = new((/3, dimsizes(yfrac_iasia)/),float)
       iasia_xco(0,:) = fields(:,(/10/))
       iasia_xco(1,:) = fields(:,(/11/))
       iasia_xco(2,:) = fields(:,(/11/))

       iasib_xco = new((/3, dimsizes(yfrac_iasib)/),float)
       iasib_xco(0,:) = fields(:,(/13/))
       iasib_xco(1,:) = fields(:,(/14/))
       iasib_xco(2,:) = fields(:,(/14/))
  
   end if

   if (ADD_AIRS) then

       airs_yyyymm = time
       yfrac_airs = yfrac

       airs_num = fields(:,(/6/))
       airs_xco = fields(:,(/4/))
       airs_xco_sd = fields(:,(/5/))

   end if


   if (ADD_TES) then

       tes_yyyymm = time
       yfrac_tes = yfrac

       tes_xco = fields(:,(/7/))
       tes_xco_num = fields(:,(/9/))

   end if


   if (ADD_CRIS) then

       cris_yyyymm = time
       yfrac_cris = yfrac

       cris_xco = fields(:,(/16/))
       cris_xco_sd = fields(:,(/17/))
       cris_num = fields(:,(/18/))

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
    new_timeseries_dummy = tofloat(where(ismissing(working_timeseries),yo,working_timeseries))
    new_timeseries(:,n) = new_timeseries_dummy
  end do
  copy_VarMeta(timeseries,new_timeseries)
   ind_trend = ind(time.lt.200201.or.time.ge.201901)
   new_timeseries(ind_trend,:) = timeseries@_FillValue

;--------------------------------------------
; Running average
;--------------------------------------------
 timeseries_runave = runave_n_Wrap(new_timeseries,12,0,0)

   if (ADD_IASI) then
     iasia_runave= runave_n_Wrap(iasia_xco,12,0,1)
     iasib_runave= runave_n_Wrap(iasib_xco,12,0,1)
   end if

   if (ADD_AIRS) then
     airs_runave = runave_n_Wrap(airs_xco,12,0,0)
   end if

   if (ADD_TES) then
     tes_runave = runave_n_Wrap(tes_xco,12,0,0)
   end if

   if (ADD_CRIS) then
     cris_runave = runave_n_Wrap(cris_xco,12,0,0)
   end if

;--------------------------------------------
; Anomalies
;--------------------------------------------
; average annual cycle
  climate_co_ext = new(dimsizes(new_timeseries), float)
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
  end do ;month loop
  copy_VarMeta(new_timeseries,climate_co_ext)

  co_anomaly = new_timeseries-climate_co_ext
  copy_VarMeta(timeseries,co_anomaly)


   if (ADD_AIRS) then
      airs_co_ext = new(dimsizes(airs_xco), float)
      airs_date  = str_split_by_length(tostring(airs_yyyymm),4)
      airs_months = tointeger(airs_date(:,1))

    do i=0,11
       ; get indices of array related to specific month
       month_ind := ind(airs_months.eq.(i+1))
       co_to_avg := airs_xco(month_ind)
       avg_airs_month := dim_avg_n(co_to_avg,0)
       print(avg_airs_month)
       airs_co_ext(month_ind) = avg_airs_month
    end do ;month loop
    copy_VarMeta(airs_xco,airs_co_ext)

    airs_anomaly = airs_xco-airs_co_ext
    copy_VarMeta(airs_xco,airs_anomaly)
   end if


   if (ADD_IASI) then
      iasia_co_ext = new(dimsizes(iasia_xco(0,:)), float)
      iasia_date  = str_split_by_length(tostring(iasia_yyyymm),4)
      iasia_months = tointeger(iasia_date(:,1))

      iasib_co_ext = new(dimsizes(iasib_xco(0,:)), float)
      iasib_date  = str_split_by_length(tostring(iasib_yyyymm),4)
      iasib_months = tointeger(iasib_date(:,1))

    do i=0,11
       ; get indices of array related to specific month
       ; iasi a
       month_ind := ind(iasia_months.eq.(i+1))
       co_to_avg := iasia_xco(0,month_ind)
       avg_iasia_month := dim_avg_n(co_to_avg,0)
       iasia_co_ext(month_ind) = avg_iasia_month
       ; iasi b
       month_ind := ind(iasib_months.eq.(i+1))
       co_to_avg := iasib_xco(0,month_ind)
       avg_iasib_month := dim_avg_n(co_to_avg,0)
       iasib_co_ext(month_ind) = avg_iasib_month
    end do ;month loop
    copy_VarMeta(iasia_xco,iasia_co_ext)
    copy_VarMeta(iasib_xco,iasib_co_ext)

    iasia_anomaly = iasia_xco(0,:)-iasia_co_ext
    copy_VarMeta(iasia_xco,iasia_anomaly)

    iasib_anomaly = iasib_xco(0,:)-iasib_co_ext
    copy_VarMeta(iasib_xco,iasib_anomaly)
   end if

   if (ADD_TES) then
      tes_co_ext = new(dimsizes(tes_xco), float)
      tes_date  = str_split_by_length(tostring(tes_yyyymm),4)
      tes_months = tointeger(tes_date(:,1))

    do i=0,11
       ; get indices of array related to specific month
       month_ind := ind(tes_months.eq.(i+1))
       co_to_avg := tes_xco(month_ind)
       avg_tes_month := dim_avg_n(co_to_avg,0)
       print(avg_tes_month)
       tes_co_ext(month_ind) = avg_tes_month
    end do ;month loop
    copy_VarMeta(tes_xco,tes_co_ext)

    tes_anomaly = tes_xco-tes_co_ext
    copy_VarMeta(tes_xco,tes_anomaly)
   end if

   if (ADD_CRIS) then
      cris_co_ext = new(dimsizes(cris_xco), float)
      cris_date  = str_split_by_length(tostring(cris_yyyymm),4)
      cris_months = tointeger(cris_date(:,1))

    do i=0,11
       ; get indices of array related to specific month
       month_ind := ind(cris_months.eq.(i+1))
       co_to_avg := cris_xco(month_ind)
       avg_cris_month := dim_avg_n(co_to_avg,0)
       print(avg_cris_month)
       cris_co_ext(month_ind) = avg_cris_month
    end do ;month loop
    copy_VarMeta(cris_xco,cris_co_ext)

    cris_anomaly = cris_xco-cris_co_ext
    copy_VarMeta(cris_xco,cris_anomaly)
   end if

;--------------------------------------------
; Normalize
;--------------------------------------------
ind_norm = ind(time.ge.200901.and.time.lt.201001)
  norm_average = dim_avg_n_Wrap(timeseries_runave(ind_norm,:),0)
  norm_conform = conform_dims(dimsizes(timeseries_runave),norm_average,1)
  timeseries_runave_norm = timeseries_runave/norm_conform
  clim_avg = dim_avg_n(climate_co_ext(ind_norm,:),0)
  co_anomaly_norm = co_anomaly

   if (ADD_IASI) then
     ind_norm_iasia = ind(iasia_yyyymm.ge.200901.and.iasia_yyyymm.lt.201001)
       iasia_norm_average = dim_avg_n_Wrap(iasia_runave(:,ind_norm_iasia),1)
       iasia_norm_conform = conform_dims(dimsizes(iasia_runave),iasia_norm_average,0)
       iasia_runave_norm = iasia_runave/iasia_norm_conform
       iasia_clim_avg = dim_avg_n(iasia_co_ext(ind_norm_iasia),0)
       norm_diff = (iasia_clim_avg(0)-clim_avg(0))
       iasia_anomaly_norm = (iasia_anomaly)

     ind_norm_iasib = ind(iasib_yyyymm.ge.201701.and.iasib_yyyymm.lt.201801)
       iasib_norm_average = dim_avg_n_Wrap(iasib_runave(:,ind_norm_iasib),1)
       ;iasib_norm_conform = conform_dims(dimsizes(iasib_runave),iasib_norm_average,0)
       iasib_norm_conform = conform_dims(dimsizes(iasib_runave),iasia_norm_average,0)
       iasib_runave_norm = iasib_runave/iasib_norm_conform
       iasib_clim_avg = dim_avg_n(iasib_co_ext(ind_norm_iasib),0)
       iasi_b_norm_diff = (iasib_clim_avg(0)-clim_avg(0))
       iasib_anomaly_norm = (iasib_anomaly)
   end if

   if (ADD_AIRS) then
     ind_norm_airs = ind(airs_yyyymm.ge.200901.and.airs_yyyymm.lt.201001)
       airs_norm_average = dim_avg_n_Wrap(airs_runave(ind_norm_airs),0)
       airs_norm_conform = conform_dims(dimsizes(airs_runave),airs_norm_average,0)
       airs_runave_norm = airs_runave/airs_norm_conform
       airs_norm_ratio = (airs_norm_average/norm_average(0))
       airs_clim_avg = dim_avg_n(airs_co_ext(ind_norm_airs),0)
       airs_norm_diff = (airs_clim_avg-clim_avg(0))
       airs_anomaly_norm = (airs_anomaly)
   end if

   if (ADD_TES) then
     ind_norm_tes = ind(tes_yyyymm.ge.200901.and.tes_yyyymm.lt.201001)
       tes_norm_average = dim_avg_n_Wrap(tes_runave(ind_norm_tes),0)
       tes_norm_conform = conform_dims(dimsizes(tes_runave),tes_norm_average,0)
       tes_runave_norm = tes_runave/tes_norm_conform
       tes_norm_ratio = (tes_norm_average/norm_average(0))
       tes_clim_avg = dim_avg_n(tes_co_ext(ind_norm_tes),0)
       tes_norm_diff = (tes_clim_avg-clim_avg(0))
       tes_anomaly_norm = (tes_anomaly)
   end if

   if (ADD_CRIS) then
print(dimsizes(cris_runave))
print(iasia_norm_average)
     ind_norm_cris = ind(cris_yyyymm.ge.201701.and.cris_yyyymm.lt.201801)
       cris_norm_average = dim_avg_n_Wrap(cris_runave(ind_norm_cris),0)
       ;cris_norm_conform = conform_dims(dimsizes(cris_runave),cris_norm_average,0)
       cris_norm_conform = conform_dims(dimsizes(cris_runave),iasia_norm_average(0),0)
       cris_runave_norm = cris_runave/cris_norm_conform
       cris_clim_avg = avg(cris_co_ext)
       cris_norm_diff = (cris_clim_avg(0)-clim_avg(0))
       cris_anomaly_norm = (cris_anomaly)
   end if



;--------------------------------------------
; Calculate trends
;--------------------------------------------
  timeseries_runave_norm = co_anomaly_norm
  airs_runave_norm = airs_anomaly_norm
  iasia_runave_norm(0,:) = iasia_anomaly_norm
  iasib_runave_norm(0,:) = iasib_anomaly_norm
  tes_runave_norm = tes_anomaly_norm
  cris_runave_norm = cris_anomaly_norm

   ind_for_trend = ind(time.ge.200207.and.time.le.201806)
   yfrac_trend = yfrac(ind_for_trend)
   rc   = regline_weight(yfrac_trend,co_anomaly(ind_for_trend,0),timeseries_sd(ind_for_trend),1)
   rc2   = regline(yfrac_trend,co_anomaly(ind_for_trend,0))
   xave = avg(yfrac_trend)
   yave = avg(timeseries_runave(ind_for_trend,0))
   ols_trendplot = ((rc*(yfrac_trend) + rc@yintercept)) ;
   rc_perc = (rc/yave)* 100
   se_perc = (rc@std_rc/yave)* 100


   if (ADD_AIRS) then
     airs_rc   = regline(yfrac_airs,airs_runave_norm)
     ;airs_rc   = regline_weight(yfrac_airs,airs_anomaly,airs_xco_sd,1)
     airs_xave = avg(yfrac_airs)
     airs_yave = avg(airs_runave)
     airs_ols_trendplot = (airs_rc*(yfrac_airs) + airs_rc@yintercept) ;* airs_norm_average
     airs_ave = avg(airs_runave)
     airs_rc_perc = (airs_rc/airs_yave)* 100
     airs_se_perc = (airs_rc@std_rc/airs_yave)* 100
   end if

   ;if (ADD_IASI) then
   ;  ;airs_rc   = regline(yfrac_airs,airs_runave_norm)
   ;  iasia_xco_sd = iasia_xco(1,:)
   ;  iasia_rc   = regline_weight(yfrac_iasia,iasia_anomaly,iasia_xco_sd,1)
   ;  iasia_xave = avg(yfrac_iasia)
   ;  iasia_yave = avg(iasia_runave)
   ;  iasia_ols_trendplot = (iasia_rc*(yfrac_iasia) + iasia_rc@yintercept)/1e-09 ;* iasia_norm_average
   ;  iasia_ave = avg(iasia_runave)
   ;  iasia_rc_perc = (iasia_rc/iasia_yave)* 100
   ;  iasia_se_perc = (iasia_rc@std_rc/iasia_yave)* 100
   ;end if

print(airs_rc)
print(airs_rc_perc)
print(airs_se_perc)

print(rc_perc)
print((rc2/yave)* 100)
print(se_perc)




;--------------------------------------------
; Timeseries differences
;--------------------------------------------

iasia_long = new(dimsizes(new_timeseries(:,0)), float)
do t=0,dimsizes(iasia_yyyymm)-1
  ind_compare = ind(time.eq.iasia_yyyymm(t))
  iasia_long(ind_compare) = iasia_xco(0,t)
end do
printVarSummary(timeseries(:,0))
printVarSummary(iasia_long)
mop_iasia_diff = timeseries(:,0)-iasia_long


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

   ; res@trYMinF             = 40
   ; res@trYMaxF             = 120
   ; res@trYMinF             = 0.90
   ; res@trYMaxF             = 1.30
    res@trYMinF             = -11
    res@trYMaxF             = 24
    res@trXMinF             = 2001.0
    res@trXMaxF             = 2019.0

    res@vpWidthF             = 1
    res@vpHeightF            = 0.6          ; set height of plot

    res@tiMainString        = ""
    ;res@gsnLeftString       = unit
    res@tiXAxisString       = "Year"
    res@tiYAxisString       = yaxis

    res@pmLegendDisplayMode      = "Always"        ; turn on legend
    res@lgPerimOn                = False           ; Turn off perimeter
    res@pmLegendWidthF           = 0.10           ; Change width and
    res@pmLegendHeightF          = 0.20             ; height of legend
    res@lgLabelFontHeightF       = 0.030
    res@xyExplicitLegendLabels   = name_array
    res@lgJustification          = "Centerleft"
    res@pmLegendOrthogonalPosF   = -1.655
    res@pmLegendParallelPosF     = 0.83

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
    ;plot = gsn_csm_xy(wks,yfrac,timeseries(:,0)/scale_factor,res)
    plot = gsn_csm_xy(wks,yfrac,timeseries_runave_norm(:,0),res)

  ; -------------------------------
  ; add in zero line
  ; -------------------------------
    res@pmLegendDisplayMode = "Never"        ; turn on legend
    res@xyLineColors        := (/"grey"/)
    res@xyDashPatterns      := (/2/)
    zero = (/0,0/)
    z_time = (/2000.0, 2020.0/)
      plot_z = gsn_csm_xy(wks,z_time,zero,res)
      overlay(plot,plot_z)
    res@xyDashPatterns      := (/0/)
    
;IASI Difference
;    res@pmLegendDisplayMode      = "Never"        ; turn on legend
;    res@tiYAxisString       = "MOPITT-IASI_A (ppb)"
;    res@trYMinF             = 3
;    res@trYMaxF             = -8
;    plot = gsn_csm_xy(wks,yfrac,mop_iasia_diff/1e-09,res)


    res@pmLegendDisplayMode = "Always"        ; turn on legend
    if (ADD_IASI) then
    res@pmLegendOrthogonalPosF   = -1.605
      res@xyExplicitLegendLabels   = (/"IASI_A", "+sd", "-sd"/)
      res@xyLineColors        := (/"green","pink","grey60","red","red4"/)
      ;plot2a = gsn_csm_xy(wks,yfrac_iasia,iasia_xco(0,:)/scale_factor,res)
      plot2a = gsn_csm_xy(wks,yfrac_iasia,iasia_runave_norm(0,:),res)
      res@xyLineColors        := (/"forestgreen","pink","grey60","red","red4"/)
      res@xyExplicitLegendLabels   = (/"IASI_B", "+sd", "-sd"/)
      res@pmLegendOrthogonalPosF   = -1.555
      ;plot2b = gsn_csm_xy(wks,yfrac_iasib,iasib_xco(0,:)/scale_factor,res)
      plot2b = gsn_csm_xy(wks,yfrac_iasib,iasib_runave_norm(0,:),res)
      overlay(plot,plot2a)
      overlay(plot,plot2b)
    end if

    if (ADD_AIRS) then
    res@pmLegendOrthogonalPosF   = -1.505
      res@xyExplicitLegendLabels   = (/"AIRS", "+sd", "-sd"/)
      res@xyLineColors        := (/"red","red","pink","grey60","red","red4"/)
      ;plot3 = gsn_csm_xy(wks,yfrac_airs,airs_xco/scale_factor,res)
      plot3 = gsn_csm_xy(wks,yfrac_airs,airs_runave_norm,res)
      overlay(plot,plot3)
    end if

    if (ADD_TES) then
    res@pmLegendOrthogonalPosF   = -1.455
      res@xyExplicitLegendLabels   = (/"TES", "+sd", "-sd"/)
      res@xyLineColors        := (/"blue","red","pink","grey60","red","red4"/)
      ;plot4 = gsn_csm_xy(wks,yfrac_tes,tes_xco/scale_factor,res)
      plot4 = gsn_csm_xy(wks,yfrac_tes,tes_runave_norm,res)
      overlay(plot,plot4)
    end if

    if (ADD_CRIS) then
    res@pmLegendOrthogonalPosF   = -1.405
      res@xyExplicitLegendLabels   = (/"CrIS", "+sd", "-sd"/)
      res@xyLineColors        := (/"magenta"/)
      ;plot5 = gsn_csm_xy(wks,yfrac_cris,cris_xco/scale_factor,res)
      plot5 = gsn_csm_xy(wks,yfrac_cris,cris_runave_norm,res)
      overlay(plot,plot5)
    end if
    res@gsnLeftString       = "" 

  ; -------------------------------
  ; plot trend
  ; -------------------------------
    res@xyExplicitLegendLabels   := ""
    ; OLS
    res@pmLegendDisplayMode      = "Always"        ; turn on legend
    res@xyLineColors        := (/"black"/)
    res@xyDashPatterns      := (/1/)
    res@xyExplicitLegendLabels   := (/"MOPITT: "+sprintf("%4.2g",rc_perc)+" ~F34~1 ~F21~"+sprintf("%4.1g",se_perc)+"% p.y."/)
    res@pmLegendOrthogonalPosF   = -1.280
    res@pmLegendParallelPosF     = 0.05
    plot_t1 = gsn_csm_xy(wks,yfrac_trend,ols_trendplot/scale_factor,res)
    overlay(plot,plot_t1)

    if (ADD_AIRS) then
    res@pmLegendDisplayMode = "Always"        ; turn on legend
    res@xyLineColors        := (/"red"/)
    res@pmLegendOrthogonalPosF   = -1.210
    res@xyExplicitLegendLabels   := (/"AIRS: "+sprintf("%4.2g",airs_rc_perc)+" ~F34~1 ~F21~"+sprintf("%4.1g",airs_se_perc)+"% p.y."/)
      plot_t3 = gsn_csm_xy(wks,yfrac_airs,airs_ols_trendplot/scale_factor,res)
      overlay(plot,plot_t3)
    end if

;    if (ADD_IASI) then
;    res@pmLegendDisplayMode = "Always"        ; turn on legend
;    res@xyLineColors        := (/"green"/)
;    res@pmLegendOrthogonalPosF   = -1.150
;    res@xyExplicitLegendLabels   := (/"IASI: "+sprintf("%4.2g",iasia_rc_perc)+" ~F34~1 ~F21~"+sprintf("%4.1g",iasia_se_perc)+"% p.y."/)
;      plot_t3 = gsn_csm_xy(wks,yfrac_iasia,iasia_ols_trendplot/scale_factor,res)
;      overlay(plot,plot_t3)
;    end if


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


    txres@txPerimOn        = True
    gsn_text_ndc(wks,location_name,0.88,0.65,txres)
    ;gsn_text_ndc(wks,location_name,0.88,0.72,txres)


  ; -------------------------------
  ; panel the plots
  ; -------------------------------
     resP = True
   ; gsn_panel(wks,plot_arr,(/4,3/),resP) 

    draw(plot)
    frame(wks)

    ;draw(plot4)
    ;frame(wks)

end if



end

