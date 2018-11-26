;=======================================================;
;  anomaly_plot.ncl 
;=======================================================;
;
; Concepts illustrated:
;   - For use with MOPITT CO anomaly and average 
;     total column timeseries files
;     - loading CO anomalies
;
;   Files needed:
;         -MOPITT anomaly files
;
;   To run type:
;         ncl anomaly_plot.ncl 
;                                  RRB August 10, 2017
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

  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  loc = "AnthChina"
  version = "V8T"
  mopitt_file = systemfunc ("ls /IASI/home/buchholz/MOPITT_subset/regions_v8/"+loc+"_*2002.nc")
  mopitt_file_2 = systemfunc ("ls /IASI/home/buchholz/MOPITT_subset/regions_v8/"+loc+"_*monthavg.nc")

  location_title = "China"
  sub_label = "(a) "
    year_s = 2002
    year_e = 2003

  ;------------
  ; toggles
  ;------------
  PLOT           = True
    plttype      = "x11"
    ;plttype@wkPaperSize = "A4"
     plttype@wkWidth = 1200
     plttype@wkHeight = 1000
      ymin       =-5e17
      ymax       =12e17

  
;--------------------------------------------
; end user input
;--------------------------------------------
;
;--------------------------------------------
; set up
;--------------------------------------------
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  ; names of data structures
  ; determined from an ncl_filedump
  sat_tcol      = "RetrievedCOtcolRegionStats"
  timearray     = "Time"

  ; -------------------------------
  ; OUTPUT RELATED SETUP
  ; -------------------------------
  if (PLOT) then
    pltdir       = "/IASI/home/buchholz/"
    pltname      = pltdir+version+"mopitt_l2_stats" + loc
  end if


;--------------------------------------------
; load file and extract
;--------------------------------------------
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  ; read data from region
  fin = addfiles(mopitt_file,"r")           ; read in
    ListSetType (fin, "cat")                 ; concatenate

    print("***Reading MOPITT data at " + loc)
    mopitt_tcol    = fin[:]->$sat_tcol$
    mopitt_date    = fin[:]->$timearray$
      mopitt_date@units = "seconds since 1993-1-1 00:00:00"
    yfrac = cd_calendar(mopitt_date,4)
    YYYYMM = cd_calendar(mopitt_date,1)

printVarSummary(mopitt_tcol)
   ; [0] Mean, [1] StdDev, [2] Min, [3] LowQuartile, [4] Median, 
   ; [5] HighQuartile, [6] Max, [7] Total n, [8] Used n, [9] Missing, 
   ; [10] Lower 5.0% (for n > 1000), [11] Upper 5.0% (for n > 1000)
   mopitt_stats = mopitt_tcol(:,(/2,3,4,5,6/))
   mopitt_avg = mopitt_tcol(:,0)

  fin2 = addfiles(mopitt_file_2, "r")           ; read in
    ListSetType (fin2, "cat")                 ; concatenate

    print("***Reading MOPITT data at " + loc)
    mopitt_monthstats_dummy    = fin2[:]->$sat_tcol$
    mopitt_yyyymm   = fin2[:]->time
   mopitt_monthstats_25_75 = mopitt_monthstats_dummy(:,(/3,3,4,5,5/))
   mopitt_monthstats_5_95 = mopitt_monthstats_dummy(:,(/2,10,4,11,6/))
   mopitt_ymfrac = yyyymm_to_yyyyfrac(mopitt_yyyymm,0.5)

print(mopitt_monthstats_5_95)

  ; -------------------------------
  ; Calculate monthly values
  ; -------------------------------
  yearmonth = yyyymm_time(year_s,year_e, "double")
  ymfrac = yyyymm_to_yyyyfrac(yearmonth,0.5)
  
  new_avg_then_stats = new((/dimsizes(yearmonth),5/), float)
  mopitt_monthavg= new((/dimsizes(yearmonth)/), float)

  do i = 0, dimsizes(yearmonth)-1
    ym_ind := ind(YYYYMM.eq.yearmonth(i))
    if (ismissing(ym_ind(0))) then
      continue
    end if
    ;---------------
    ; avg_then_stats
    ;---------------
    temp_mopitt := mopitt_avg(ym_ind)
    opt = False
    mopitt_newstats = stat_dispersion(temp_mopitt, opt )

    new_avg_then_stats(i,0) = mopitt_newstats(2)
    new_avg_then_stats(i,1) = mopitt_newstats(6)
    new_avg_then_stats(i,2) = mopitt_newstats(8)
    new_avg_then_stats(i,3) = mopitt_newstats(10)
    new_avg_then_stats(i,4) = mopitt_newstats(14)

  end do 

printVarSummary(mopitt_stats)



;--------------------------------------------
; plot
;--------------------------------------------
if (PLOT) then

  wks = gsn_open_wks(plttype,pltname)        
  gsn_define_colormap(wks,"BlAqGrYeOrRe")  
   
 res                 = True
    res@gsnDraw		    = False	                ; don't draw it yet
    res@gsnFrame            = False                     ; don't advance frame
    ;res@gsnMaximize         = True
    ;res@vpWidthF            = 0.85
    res@vpHeightF           = 0.3
    res@trXMinF             = 2002.0
    res@trXMaxF             = 2018.0
    res@trYMinF             = 1.5
    res@trYMaxF             = 5.5

    res@tmXBMode        = "Manual"
     res@tmXBTickStartF  = 2002.0
     res@tmXBTickEndF    = 2017.5
     res@tmXBTickSpacingF= 5.0

    res@tmYLMode        = "Manual"
     res@tmYLTickStartF  = 1.0
     res@tmYLTickEndF    = 9.5
     res@tmYLTickSpacingF= 1.0

    res@tiYAxisString       = "CO (~F34~4~F21~10~S2~18   molec. cm~S2~-2  )"
    res@tiXAxisString       = "Year"

    res@tmXBLabelFontHeightF  = 0.022
    res@tmYLLabelFontHeightF  = 0.022
    res@tiYAxisFontHeightF    = 0.022
    res@tiXAxisFontHeightF    = 0.022

    res@tmYLMajorOutwardLengthF = 0.0                    ; draw tickmarks inward
    res@tmYLMinorOutwardLengthF = 0.0                    ; draw minor ticsk inward
    res@tmXBMajorOutwardLengthF = 0.0               
    res@tmXBMinorOutwardLengthF = 0.0 

  llres                   = True			
  llres@gsLineThicknessF  = 3.5                 ; line thickness 

  res2 = res
  res2@xyMarkLineModes  = "Markers"                ; choose which have markers
    res2@xyMarkers                = 16               ; choose type of marker  
    res2@xyMarkerColor            = "forestgreen"         ; Marker color
    res2@xyMarkerOpacityF         = 0.50
    res2@xyMarkerSizeF            = 0.015             ; Marker size (default 0.01)
  plot = gsn_csm_xy(wks,mopitt_ymfrac,mopitt_monthstats_dummy(:,0)/1e18,res2)
    res2@xyMarkerColor            = "lightskyblue"         ; Marker color
    res2@xyMarkerSizeF            = 0.005             ; Marker size (default 0.01)
  plot1 = gsn_csm_xy(wks,yfrac,mopitt_avg/1e18,res2)
 ; overlay(plot, plot1)

  opti          = True			
  opti@boxWidth = 0.025		                ; Width of box (x units)
  llres@gsLineThicknessF  = 6.5                 ; line thickness 
 ; opti@boxColors = "red"  	                ; Color of box(es)
 ; plotm1 = boxplot(wks,ymfrac,new_avg_then_stats/1e18,opti,res,llres)

  llres@gsLineThicknessF  = 4.5                 ; line thickness 
  opti@boxWidth = 0.015		                ; Width of box (x units)
  opti@boxColors = "black"  	; Color of box(es)
  plotm2 = boxplot(wks,mopitt_ymfrac,mopitt_monthstats_25_75/1e18,opti,res,llres)
  opti@boxColors = "gray40"  	; Color of box(es)
  res@xyDashPattern = 3
  plotm2a = boxplot(wks,mopitt_ymfrac,mopitt_monthstats_5_95/1e18,opti,res,llres)

  ;-----------------------------------
  ; Add in legend
  ;-----------------------------------
   ;drawNDCGrid(wks)
   ; add station
    txres                   = True                     ; polyline mods desired
     txres@txFontHeightF    = 0.018                   ; font smaller. default big
     txres@txJust           = "CenterLeft"
     txres@txPerimOn        = False
     txres@txFontColor      = "black"                  
    ;gsn_text_ndc(wks,"monthly stats all retrievals in region",0.35,0.78,txres)
     ;txres@txFontColor      = "red"                  ; font smaller. default big
    ;gsn_text_ndc(wks,"monthly stats of day regional averages",0.35,0.76,txres)
     txres@txFontColor      = "skyblue"                 
    ;gsn_text_ndc(wks,"daily averages",0.35,0.76,txres)
     txres@txFontColor      = "forestgreen"                 
    gsn_text_ndc(wks,"month averages",0.35,0.84,txres)

    res2@xyMarkerColor            = "forestgreen"         ; Marker color
    res2@xyMarkerSizeF            = 0.008             ; Marker size (default 0.01)
    res2@xyMarkerOpacityF         = 1.0
  plotover = gsn_csm_xy(wks,mopitt_ymfrac,mopitt_monthstats_dummy(:,0)/1e18,res2)
  overlay(plotm2, plotover)

 ; overlay(plot, plotm1)
 ; overlay(plot, plotm2a)
 ; overlay(plot, plotm2)


  draw(plot)
  frame(wks)

end if ; PLOT





end

