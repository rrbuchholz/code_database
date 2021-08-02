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
  location = "SH"
  location_2 = "NH"
  location_3 = "BBSAfrica"
   name_array = (/location, location_2, location_3/)
  location_name = "DFS"
    pltname      = "/net/mopfl/home/buchholz/"+location+"_trend"
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  timeseries_files = systemfunc ("ls /IASI/home/buchholz/MOPITT_subset/regions_v8/"+location+"_*monthavg_VMR.nc")
  timeseries_files_2 = systemfunc ("ls /IASI/home/buchholz/MOPITT_subset/regions_v8/"+location_2+"_*monthavg_VMR.nc")
  timeseries_files_3 = systemfunc ("ls /IASI/home/buchholz/MOPITT_subset/regions_v8/"+location_3+"_*monthavg_VMR.nc")

  ;scale_factor = 1e18              ;column
  ;unit = "~F34~4~F21~10~S2~18   molec. cm~S2~-2"
  ;yaxis = "Total column"

  ;scale_factor = 1e-09              ;vmr
  ;unit = "ppb"
  ;yaxis = "Column average VMR (" +unit +")"
  scale_factor = 1                 ;normalized
  ;yaxis = "Normalized CO"

  yaxis = "DFS"
  unit = ""

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
  fin = addfiles(timeseries_files, "r")      ; read in
    ListSetType (fin, "cat")                 ; concatenate
    time        = fin[:]->time
    timeseries_dummy  = fin[:]->AvgDegreesofFreedomforSignal

  fin2 = addfiles(timeseries_files_2, "r")      ; read in
    ListSetType (fin2, "cat")                 ; concatenate
    timeseries_dummy_2  = fin2[:]->AvgDegreesofFreedomforSignal

    split_dates = str_split_by_length(tostring(time),4)
    yfrac = yyyymm_to_yyyyfrac(time,0.5)


  fin3 = addfiles(timeseries_files_3, "r")      ; read in
    ListSetType (fin3, "cat")                 ; concatenate
    timeseries_dummy_3  = fin3[:]->AvgDegreesofFreedomforSignal



   timeseries = new((/3, dimsizes(time)/),float)
     timeseries(0, :) = timeseries_dummy
     timeseries(1, :) = timeseries_dummy_2
     timeseries(2, :) = timeseries_dummy_3

printVarSummary(yfrac)
printVarSummary(timeseries)

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

    res@trYMinF             = 1.0
    res@trYMaxF             = 1.9
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
    res@xyLineColors        := (/"black","grey50","red","grey60","red","red4"/)
    plot = gsn_csm_xy(wks,yfrac,timeseries,res)

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

