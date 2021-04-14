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

systemfunc ("export NCARG_COLORMAPS=/IASI/home/buchholz/code_database/ncl_programs/custom_colormaps:$NCARG_ROOT/lib/ncarg/colormaps")

begin

;--------------------------------------------
; user input
;--------------------------------------------
; PNW, EastUSA, CentralUSA
  location = "PNW"
    pltname      = "/net/mopfl/home/buchholz/"+location+"_trend"
  maxlag = 12
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  timeseries_files = systemfunc ("ls /IASI/home/buchholz/MOPITT_subset/regions_v8/"+location+"_*monthavg_VMR.nc")
  ;timeseries_files = systemfunc ("ls /IASI/home/buchholz/MOPITT_subset/regions_v8/no_snr_filter/"+location+"_*monthavg_VMR.nc")
  ;timeseries_files = systemfunc ("ls /IASI/home/buchholz/MOPITT_subset/regions_v8/pix3_and_snr/"+location+"_*monthavg_VMR.nc")

  ;------------
  ; toggles
  ;------------
  PLOT           = True
    plttype      = "x11"
    ;plttype@wkPaperSize = "A4"
      plttype@wkWidth = 1200
      plttype@wkHeight = 1200
      plot_title = "Test"

  PLOTGRID        = False
    plt2type      = "x11"
    ;plt2type@wkPaperSize = "A4"
      plt2type@wkWidth = 1200
      plt2type@wkHeight = 1200

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

  if (PLOTGRID) then
    pltdir       = "./"
    plt2name      = location+"_trendarray"
  end if

  ;Carriage return
   cr = tochar(10)

  ;Month names
  ; month_names = (/"Year Ave","Jan", "Feb", "Mar", "Apr", "May", "Jun",\
  ;                  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"/)
   month_names = (/"Ann","J", "F", "M", "A", "M", "J",\
                    "J", "A", "S", "O", "N", "D"/)
;--------------------------------------------
; load file and extract timeseries
;--------------------------------------------
  fin = addfiles(timeseries_files, "r")            ; read in
    ListSetType (fin, "cat")                 ; concatenate
    timeseries_in     = fin[:]->RetrievedX_CORegionStats
    time_dummy        = fin[:]->time
      ind_for_trend = ind(time_dummy.ge.200201.and.time_dummy.le.201812)
      time = time_dummy(ind_for_trend)
      timeseries_dummy = timeseries_in(ind_for_trend,:)

    split_dates = str_split_by_length(tostring(time),4)
    yfrac = yyyymm_to_yyyyfrac(time,0.5)

   ; [0] Mean, [1] StdDev, [2] Min, [3] LowQuartile, [4] Median, 
   ; [5] HighQuartile, [6] Max, [7] Total n, [8] Used n, [9] Missing, 
   ; [10] Lower 5.0% (for n > 1000), [11] Upper 5.0% (for n > 1000)
   ;timeseries = timeseries_dummy(:,(/10,3,0,4,5,11/))
   ;name_array = (/"5th", "25th", "mean", "median", \
   ;               "75th", "95th"/)
   timeseries = timeseries_dummy(:,(/3,0,4,5/))
   name_array = (/"25th", "mean", "median", \
                  "75th"/)
   tcol_monthavg = timeseries_dummy(:,0)
   dataset_average = avg(tcol_monthavg)
   n_points = timeseries_dummy(:,(/8/))
   std_dev = timeseries_dummy(:,(/1/))

;--------------------------------------------
; De-season
;--------------------------------------------  

;--------------------------------------------
; Initialize trend collection arrays
;--------------------------------------------  
   trend_array = new((/13,dimsizes(name_array)/),float)
   trend_array_col = new((/13,dimsizes(name_array)/),float)
   pval_array = new((/13,dimsizes(name_array)/),float)
   ols_trends = new((/12,3/),float)
   monthly_n_points = new((/12/),float)
   monthly_std_dev = new((/12/),float)

;--------------------------------------------
; Loop through months
;--------------------------------------------  
  do m = 0,11
    mm = sprintf("%02g", m+1)
    select_ind := ind(split_dates(:,1).eq.mm)
    select_data := timeseries(select_ind,:)
    select_yfrac := yfrac(select_ind)
    avg_value = dim_avg_n(select_data, 0)

    ; Theil-Sen
    p    = trend_manken(select_data, False, 0)


    ;trend_array(m,:) = (p(1,:)/avg_value)*100
    trend_array(m+1,:) = (p(1,:)/dataset_average)*100
    trend_array_col(m+1,:) = p(1,:)
    pval_array(m+1,:) = 1-p(0,:)

    ; OLS
    rc   = regline(select_yfrac,select_data(:,1))
    ols_trends(m,0) = rc
    ols_trends(m,1) = rc@yave                    ;average month tcol
    ols_trends(m,2) = rc@xave

    ; Average MOPITT points
    ;monthly_n_points(m) = ceil(avg(n_points(select_ind))/1000)
    monthly_n_points(m) = avg(n_points(select_ind))/1000
    monthly_std_dev(m) = ((avg(std_dev(select_ind)))/avg_value(0))*100
    ;monthly_std_dev(m) = avg(std_dev(select_ind))
  end do

   avg_month_tcol = ols_trends(:,1)/1e-09


;--------------------------------------------
; Year average values
;--------------------------------------------  
    ystart = toint(split_dates(0,0))
    yend = toint(split_dates(dimsizes(time)-1,0))
    years = ispan(ystart,yend,1)

    year_average = new((/dimsizes(years),dimsizes(name_array)/),float)
    do y = 0, dimsizes(years)-1
      ind_year := ind(yfrac.ge.years(y).and.yfrac.lt.years(y)+1)
      year_average(y,:) = dim_avg_n(timeseries(ind_year,:),0)
    end do

    ind_trend = ind(years.gt.2001)

    ; Theil-Sen
    p_year    = trend_manken(year_average(ind_trend,:), False, 0)

    trend_array(0,:) = (p_year(1,:)/dataset_average)*100
    pval_array(0,:) = 1-p_year(0,:)



;--------------------------------------------
; Calculate significance
;-------------------------------------------- 
  sig_trend_05 = where(pval_array.gt.0.05,trend_array@_FillValue,trend_array)
  sig_trend_01 = where(pval_array.gt.0.01,trend_array@_FillValue,trend_array)
  sig_trend_001 = where(pval_array.gt.0.001,trend_array@_FillValue,trend_array)

;--------------------------------------------
; Calculate trends for plotting
;--------------------------------------------
   dplt = new ( (/3,dimsizes(select_yfrac)/), typeof(select_data), select_data@_FillValue)

   dplt = select_data@_FillValue
   ;dplt(0,:) = select_data
   dplt(1,:) = rc*(select_yfrac-rc@xave) + rc@yave
   dplt(2,:) = p(1,0)*(select_yfrac-rc@xave) + rc@yave

   perc_trend = (p(1,:)/abs(avg_value))*100

print("Percent trends")
print(name_array+": "+perc_trend+ ", p-value "+(1-p(0,:)))

print(avg(monthly_n_points))
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

    res@xyLineThicknessF    = 10.0
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
    ;res@trYMaxF             = 0.8

    res@vpWidthF             = 1
    res@vpHeightF            = 0.6          ; set height of plot

    res@tiMainString        = ""
    res@tiXAxisString       = "Year"
    res@tiYAxisString       = "Column Avg CO VMR (ppb)"

    res@pmLegendDisplayMode      = "Always"        ; turn on legend
    res@lgPerimOn                = True           ; Turn off perimeter
    res@pmLegendWidthF           = 0.20           ; Change width and
    res@pmLegendHeightF          = 0.20             ; height of legend
    res@lgLabelFontHeightF       = 0.030
    res@pmLegendOrthogonalPosF   = -1.155
    res@pmLegendParallelPosF     = 0.83
  ; -------------------------------
  ; create plot
  ; -------------------------------
    res@pmLegendDisplayMode = "Never"        ; turn on legend
    res@xyMarkLineModes      = (/"Markers","Lines","Lines"/)
    res@xyMarkers           = (/4,4,4,4/)            ; choose type of marker  
    res@xyMarkerThicknessF  = (/6,6,6,6/)
    res@xyMarkerSizeF       = 0.024
    res@xyMarkerColors      = (/"black","red","blue"/)
    res@xyLineColors        := (/"black","red","blue"/)
    ;plot1a = gsn_csm_xy(wks,max_vals(0,:),max_vals(1,:),res)
    ;overlay(plot1, plot1a)

    ; plot timeseries
    plot_arr = new(12,graphic)
    plot_line_arr = new(12,graphic)
    do i = 0, 11
         mm = sprintf("%02g", i+1)
         select_ind := ind(split_dates(:,1).eq.mm)
         select_yfrac := yfrac(select_ind)
         res@gsnRightString = month_names(i+1) +": p="+sprintf("%5.3f",pval_array(i+1,1))+\
                              "  trend="+sprintf("%5.3f",trend_array(i+1,1))+"%"
         dplt := new ( (/3,dimsizes(select_yfrac)/), typeof(select_data), select_data@_FillValue)
         dplt = select_data@_FillValue
           dplt(0,:) = tcol_monthavg(select_ind)
           dplt(1,:) = ols_trends(i,0)*(select_yfrac-ols_trends(i,2)) + ols_trends(i,1)
           dplt(2,:) = trend_array_col(i+1,1)*(select_yfrac-ols_trends(i,2)) + ols_trends(i,1)
         plot_arr(i) = gsn_csm_xy(wks,select_yfrac,dplt/1e-09,res)
    end do

  ; -------------------------------
  ; add legend
  ; -------------------------------
    txres                   = True                     ; polyline mods desired
     txres@txFontHeightF    = 0.020                   ; font smaller. default big
     txres@txJust           = "CenterCenter"
     txres@txPerimOn        = False
     txres@txFontColor      = "blue"                  
    gsn_text_ndc(wks,"Theil-Sen",0.90,0.95,txres)
     txres@txFontColor      = "red"                  
    gsn_text_ndc(wks,"OLS",0.80,0.95,txres)


  ; -------------------------------
  ; panel the plots
  ; -------------------------------
     resP = True
       resP@gsnPanelMainString         = location
    gsn_panel(wks,plot_arr,(/4,3/),resP) 
   ;overlay(plot, plot1)

    ;draw(plot)
    ;frame(wks)

end if


;--------------------------------------------
; plot
;--------------------------------------------
if (PLOTGRID) then

  ;xval = fspan(1,7,7)
  ;yval = fspan(1,13,13)
  xval = fspan(1,5,5)
  yval = fspan(1,13,13)
  grid_array = new((/dimsizes(yval), dimsizes(xval)/), float)
  do i = 1, dimsizes(xval)-1
    grid_array(:,i) = yval(:)
  end do
  new_name_array = array_append_record ((/"XCO"/), name_array, 0)

  wks2 = gsn_open_wks(plt2type,plt2name)        
  gsn_define_colormap(wks2,"BlAqGrYeOrRe")  
   
  res                       = True                      ; plot mods desired
    res@gsnDraw		    = False	                ; don't draw it yet
    res@gsnFrame            = False                     ; don't advance frame
    res@gsnMaximize         = True

    res@tmBorderThicknessF  = 3.0
    res@tmXBMajorThicknessF = 3.0
    res@tmYLMajorThicknessF = 3.0

    res@tmYLMajorOutwardLengthF = 0.0               ; draw tickmarks inward
    res@tmYLMinorOutwardLengthF = 0.0               ; draw minor ticks inward
    res@tmXBMajorOutwardLengthF = 0.0               
    res@tmXBMinorOutwardLengthF = 0.0   

    res@tmXBBorderOn      = False
    ;res@tmXBOn            = False
    res@tmXTBorderOn      = False
    res@tmXTOn            = False
    res@tmYLBorderOn      = False
    ;res@tmYLOn            = False
    res@tmYRBorderOn      = False
    res@tmYROn            = False

    res@vpWidthF             = 0.63
    res@vpHeightF            = 1.0          ; set height of plot

    res@tmYLMode            = "Explicit"
      res@trYMinF             = 0
      res@trYMaxF             = 14
      res@tmYLValues          = yval
      res@tmYLLabels          = month_names

    res@tmXBMode            = "Explicit"
      res@trXMinF             = 0
      res@trXMaxF             = 8
      res@tmXBValues          = xval
      res@tmXBLabels          = new_name_array
      res@tmXBLabelAngleF     = -45	; tilt the XB labels 45 degrees
      res@tmXBLabelDeltaF     = 1.5	; push the XB labels down from plot

    res@tiMainString        = location
    res@gsnRightString     := "" 
    ;res@gsnLeftString      := "Dataset Average CO: "+ sprintf("%4.3g",dataset_average/1e-09) +\
    ;                           " ~F34~4~F21~10~S2~18   molec. cm~S2~-2  "
    res@tiXAxisString       = "Statistic"
    res@tiYAxisString       = ""

    res@pmLegendDisplayMode      = "Always"        ; turn on legend
    res@lgPerimOn                = True           ; Turn off perimeter
    res@pmLegendWidthF           = 0.20           ; Change width and
    res@pmLegendHeightF          = 0.20             ; height of legend
    res@lgLabelFontHeightF       = 0.030
    res@xyExplicitLegendLabels   = (/"SAM", "DMI", "Nino3.4", "TSA"/)
    res@pmLegendOrthogonalPosF   = -1.155
    res@pmLegendParallelPosF     = 0.83
  ; -------------------------------
  ; create plot
  ; -------------------------------

    res@pmLegendDisplayMode = "Never"        ; turn on legend
    res@xyMarkLineModes     := (/"Markers","Markers","Markers","Markers","Markers",\
                                 "Markers","Markers","Markers","Markers","Markers",\
                                 "Markers","Markers","Markers"/)
    res@xyMarkers           = (/6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6/)  ; choose type of marker  
    res@xyMarkerThicknessF  = 3
    res@xyMarkerSizeF       = 0.070
    res@xyMarkerColor      = "grey85"

    ; plot timeseries
    plot = gsn_csm_xy(wks2,xval,grid_array,res)

  ; -------------------------------
  ; add trend values
  ; -------------------------------
  cmap = read_colormap_file("temp_19lev")
  colour_arr := (/cmap(1,:),cmap(2,:),cmap(3,:),cmap(4,:),cmap(5,:),cmap(6,:),\
                 cmap(7,:), cmap(8,:),cmap(9,:),cmap(10,:),\
                 cmap(11,:),cmap(12,:),cmap(14,:),cmap(16,:),cmap(19,:)/)

  levels = (/-1.6,-1.4,-1.2,-1.,-0.8,-0.6,-0.4,-0.2,0,0.25,0.5,0.75,1.0/)
  nlevels = dimsizes(levels)
  filled_sq = NhlNewMarker(wks2, "y", 35, 0.0, 0.0, 1.0, 1.0, 0.0)
  ;filled_dia = NhlNewMarker(wks2, "y", 35, 0.0, 0.0, 1.0, 1.0, 45.0)
  ;filled_tri = NhlNewMarker(wks2, "u", 34,  0.0, 0.0, 1.3, 1.0, -90.0)
  pmres = True
   pmres@tfPolyDrawOrder = "PostDraw"
   pmres@gsMarkerIndex = filled_sq

   pm01res = pmres
   pm01res@gsMarkerIndex = 16
   pm001res = pm01res
   pm01res@gsMarkerSizeF = 0.030
   pm001res@gsMarkerSizeF = 0.048

  print(sig_trend_001)   
  tarray_1D      = ndtooned(sig_trend_05)
  dsizes_tarray  = dimsizes(sig_trend_05)
  tarray_1D_01   = ndtooned(sig_trend_01)
  dsizes_tarray_01 = dimsizes(sig_trend_01)
  tarray_1D_001    = ndtooned(sig_trend_001)
  dsizes_tarray_001= dimsizes(sig_trend_001)

    pmres@gsMarkerColor := "grey85"
    pmres@gsMarkerSizeF = 0.055
    do j = 0,12
      gsn_polymarker(wks2,plot,xval,grid_array(j,:),pmres)
    end do

  lnres = True
    lnres@gsLineColor = "white"
    lnres@gsLineThicknessF  = 8
  lnid = gsn_add_polyline(wks2,plot,(/0,6/),(/1.5,1.5/),lnres)

  indices  := ind_resolve(ind(ismissing(tarray_1D)),dsizes_tarray)
  indices01 := ind_resolve(ind(ismissing(tarray_1D_01)),dsizes_tarray_01)
  indices001  := ind_resolve(ind(ismissing(tarray_1D_001)),dsizes_tarray+001)

   pmres@gsMarkerIndex = 16
    pmres@gsMarkerSizeF = 0.015
  ; group trend indices into colour groups
  do l=0,nlevels
    if (l.eq.0) then
      indices  := ind_resolve(ind(tarray_1D.lt.levels(0)),dsizes_tarray)       ; bottom limit
      indices01 := ind_resolve(ind(tarray_1D_01.lt.levels(0)),dsizes_tarray_01)       ; bottom limit
      indices001 := ind_resolve(ind(tarray_1D_001.lt.levels(0)),dsizes_tarray_001)       ; bottom limit
    else if (l.eq.nlevels) then
      indices  := ind_resolve(ind(tarray_1D.gt.levels(nlevels-1)),dsizes_tarray)       ; top limit
      indices01 := ind_resolve(ind(tarray_1D_01.gt.levels(nlevels-1)),dsizes_tarray_01)       ; bottom limit
      indices001 := ind_resolve(ind(tarray_1D_001.gt.levels(nlevels-1)),dsizes_tarray_001)       ; bottom limit
    else
      indices  := ind_resolve(ind(tarray_1D.ge.levels(l-1).and.\
                            tarray_1D.lt.levels(l)),dsizes_tarray)       ; middle levels
      indices01  := ind_resolve(ind(tarray_1D_01.ge.levels(l-1).and.\
                            tarray_1D_01.lt.levels(l)),dsizes_tarray_01)       ; middle levels
      indices001  := ind_resolve(ind(tarray_1D_001.ge.levels(l-1).and.\
                            tarray_1D_001.lt.levels(l)),dsizes_tarray_001)       ; middle levels
    end if
    end if
    ;--------------
    ; p<0.05
    if (ismissing(indices(0,0))) then
      continue
    end if
      pmres@gsMarkerColor := colour_arr(l,:)
      gsn_polymarker(wks2,plot,indices(:,1)+2,indices(:,0)+1,pmres)
    ;--------------
    ; p<0.01
    if (ismissing(indices01(0,0))) then
      continue
    end if
      pm01res@gsMarkerColor := colour_arr(l,:)
      gsn_polymarker(wks2,plot,indices01(:,1)+2,indices01(:,0)+1,pm01res)
    ;--------------
    ; p<0.001
    if (ismissing(indices001(0,0))) then
      continue
    end if
      pm001res@gsMarkerColor := colour_arr(l,:)
      gsn_polymarker(wks2,plot,indices001(:,1)+2,indices001(:,0)+1,pm001res)
  end do

  ;------------
  ; add labelbarl
  ;------------
  lbres = True
     lbres@vpWidthF                  = 0.1
     lbres@vpHeightF                 = 0.60
     lbres@lbPerimOn                 = False
     lbres@lbOrientation             = "Vertical"
     ;lbres@vpYF                      = 0.89                   ; y-location of label bar
     ;lbres@vpXF                      = 0.85                    ; x-location of label bar
     lbres@lbLabelAlignment          = "InteriorEdges"
     lbres@lbFillColors              = colour_arr
     lbres@lbMonoFillPattern         = True
     lbres@lbLabelFontHeightF        = 0.020

     lbres@lbTitleOn                 = True
     lbres@lbTitleString             = "% p.y."
     lbres@lbTitleFontHeightF        = 0.020
     lbres@lbTitlePosition           = "Bottom"

     lbres@lbLabelStrings            := levels

  labels = sprintf("%4.2e",levels)
  ;lbres@lbLabelStride             = 1
  gsn_labelbar_ndc(wks2, nlevels+1, labels, 0.71, 0.89, lbres)

    txres                   = True                     ; polyline mods desired
     txres@txFontHeightF    = 0.018                   ; font smaller. default big
     txres@txJust           = "CenterCenter"
     txres@txPerimOn        = False
     txres@txFontColor      = "black"                  

    pmres@gsMarkerSizeF = 0.010
    pmres@gsMarkerColor := "black"
    gsn_polymarker_ndc (wks2,0.74,0.22,pmres)
    gsn_text_ndc(wks2,"p < 0.05",0.804,0.22,txres)
    pm01res@gsMarkerSizeF = 0.015
    pm01res@gsMarkerColor := "black"
    gsn_polymarker_ndc (wks2,0.74,0.24,pm01res)
    gsn_text_ndc(wks2,"p < 0.01",0.804,0.24,txres)
    pm001res@gsMarkerSizeF = 0.020
    pm001res@gsMarkerColor := "black"
    gsn_polymarker_ndc (wks2,0.74,0.265,pm001res)
    gsn_text_ndc(wks2,"p < 0.001",0.81,0.26,txres)
    pmres@gsMarkerSizeF = 0.020
    pmres@gsMarkerColor := "grey85"
    pmres@gsMarkerIndex = filled_sq
    gsn_polymarker_ndc (wks2,0.72,0.20,pmres)
    gsn_text_ndc(wks2,"not significant",0.81,0.20,txres)


  ; -------------------------------
  ; add mean col avg vmr for CO
  ; -------------------------------
  cmap_2 = read_colormap_file("WhiteBlueGreenYellowRed")
  ;cmap_2 = read_colormap_file("WhiteBlueGreenYellowRed_rrb")
  lev_split = dimsizes(cmap_2(:,0))-1
;print(lev_split)

print(avg_month_tcol)


  tcol_levels = fspan(50.,176.,lev_split)
  ;tcol_levels = fspan(1.2,3.6,lev_split)
  tcol_nlevels = dimsizes(tcol_levels)
  pmres@gsMarkerIndex = filled_sq
  sd_perc = ispan(6,24,2)

  ; group total column values into colour groups
  do m=0,dimsizes(avg_month_tcol)-1

    ind_tcol_val := ind(tcol_levels.gt.avg_month_tcol(m))
;print(ind_tcol_val)
;print(avg_month_tcol(m))

    ind_sd_val := ind(sd_perc.gt.monthly_std_dev(m))
    if (ismissing(ind_sd_val(0))) then
        pmres@gsMarkerSizeF = 0.030
    else 
        pmres@gsMarkerSizeF = tofloat(sd_perc(ind_sd_val(0))+4)/1000
    end if

    x_point := 0.9
    pmres@gsMarkerColor := cmap_2(ind_tcol_val(0),:)
    gsn_polymarker(wks2,plot,x_point,m+2,pmres)

  end do

  ;------------
  ; add tcol labelbarl
  ;------------
  lbres = True
     lbres@vpWidthF                  = 0.1
     lbres@vpHeightF                 = 0.60
     lbres@lbPerimOn                 = False
     lbres@lbOrientation             = "Vertical"
     ;lbres@vpYF                     = 0.29                   ; y-location of label bar
     lbres@vpXF                      = 0.08                    ; x-location of label bar
     lbres@lbLabelAlignment          = "InteriorEdges"
     lbres@lbFillColors              := cmap_2
     lbres@lbMonoFillPattern         = True
     lbres@lbLabelFontHeightF        = 0.020

     lbres@lbTitleOn                 = True
     ;lbres@lbTitleString             = "    ~F34~4~F21~10~S2~18  ~CR~  molec. cm~S2~-2  "
     lbres@lbTitleString             = "ppb"
     lbres@lbTitleFontHeightF        = 0.020
     lbres@lbTitlePosition           = "Bottom"
     lbres@lbBoxLinesOn              = False

     lbres@lbLabelStrings           := sprintf("%5.4g",tcol_levels)

  labels := sprintf("%4.3g",tcol_levels)
  gsn_labelbar_ndc(wks2, tcol_nlevels+1, labels, 0.84, 0.89, lbres)

    pmres@gsMarkerSizeF = 0.010
    pmres@gsMarkerColor := "black"
    gsn_polymarker_ndc (wks2,0.11,0.245,pmres)
    gsn_text_ndc(wks2,"cv < 6%",0.175,0.25,txres)
    pmres@gsMarkerSizeF = 0.030
    gsn_polymarker_ndc (wks2,0.11,0.285,pmres)
    gsn_text_ndc(wks2,"cv > 24%",0.182,0.285,txres)

  ; -------------------------------
  ; add dataset average value
  ; -------------------------------
   text = gsn_add_text(wks2,plot,sprintf("%4.3g",dataset_average/1e-09),0.9,0.9,txres)

  ; -------------------------------
  ; add dataset number of points
  ; -------------------------------
     txres@txFontHeightF    = 0.012                   ; font smaller. default big
     txres@txFontColor      = "gray30"    
     gsn_text_ndc(wks2,"n (K)",0.67,0.91,txres)              
   do n=0,dimsizes(monthly_n_points)-1
      gsn_text_ndc(wks2,sprintf("%4.3g", monthly_n_points(n)),0.665,0.28+n*0.055,txres)
   end do
  ; -------------------------------
  ; print
  ; -------------------------------
   ;overlay(plot, plot1)

   draw(plot)
   frame(wks2)

end if



end

