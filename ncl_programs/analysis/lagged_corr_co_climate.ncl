;=======================================================;
;  lagged_corr_co_climate.ncl 
;=======================================================;
;
; Concepts illustrated:
;   - For use with MOPITT CO version 7, month anomalies
;     - load CO data
;     - load climate indices
;     - calculate lagged correlations
;     - 
;
;   Files needed:
;         -MOPITT anomalies
;         -Climate Mode Index values
;
;   To run type:
;         ncl lagged_corr_co_climate.ncl 
;                                  RRB August 8, 2017
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
  location = "MaritimeSEA"
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
   mopitt_dir = "/IASI/home/buchholz/MOPITT_subset/V7/anomalies/"
   mopitt_file = mopitt_dir+location+"_V7TMOPITTanomalies.nc"

  ; -------------------------------
  ; CLIMATE INDEX
  ; -------------------------------
   ci_dir = "/IASI/home/buchholz/Climate_Indices/converted/"
   ci_files = systemfunc ("ls "+ci_dir+"*_index_month_avg.nc")

  ;------------
  ; toggles
  ;------------
  PLOT           = True
    plttype      = "x11"
    ;plttype@wkPaperSize = "A4"
      plttype@wkWidth = 1200
      plttype@wkHeight = 1200

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
    pltname      = location+"_laggedcorr"
  end if


;--------------------------------------------
; load file and extract
;--------------------------------------------

  ; -------------------------------
  ; MOPITT Anomaly
  ; -------------------------------
  m_fin = addfile(mopitt_file, "r")            ; read in
  mopitt_anom    = m_fin->MOPITT_CO_ANOMALY
  mopitt_time    = mopitt_anom&time

  ; -------------------------------
  ; Indices
  ; -------------------------------
   overlap_index_vals= new((/dimsizes(ci_files),dimsizes(mopitt_time)/), float)
   index_names = new(dimsizes(ci_files),string)

  do i = 0,dimsizes(ci_files)-1
    i_fin := addfile(ci_files(i), "r")            ; read in
      var_names := getfilevarnames( i_fin )
    index_anom    := i_fin->$var_names(0)$
      index_time    := index_anom&time
    ; -------------------------------
    ; Crop index series to MOPITT size
    ; -------------------------------   
     overlap_times := ind(index_time.ge.mopitt_time(0).and.\
                       index_time.le.mopitt_time(dimsizes(mopitt_time)-1))

     overlap_index_vals(i,:) = tofloat(index_anom(overlap_times))
     index_names(i) = var_names(0)
   end do

   overlap_index_vals!1 = "time"
   overlap_index_vals&time = mopitt_time
   overlap_index_vals!0 = "index"
   overlap_index_vals@indices =  index_names

;--------------------------------------------
; calculate cross correlations
;--------------------------------------------  
; x_lead_y = esccr(x,y,12)
acr = esccr(overlap_index_vals,mopitt_anom,12)
   acr!0 = "index"
   acr@indices =  index_names
  xx = ispan(0,12,1)


;--------------------------------------------
; correlations for only Aug-Nov
;--------------------------------------------  
  split_dates = str_split_by_length(tostring(mopitt_time),4)
  m_select_ind = ind(split_dates(:,1).eq."07".or.\
                     split_dates(:,1).eq."08".or.\
                     split_dates(:,1).eq."09".or.\
                     split_dates(:,1).eq."10")
  m_select_data = mopitt_time(m_select_ind)
  i_select_data =  overlap_index_vals(:,m_select_ind)

printVarSummary(i_select_data)
printVarSummary(m_select_data)

 test = escorc(m_select_data,i_select_data)
 test2 = escorc(overlap_index_vals,mopitt_anom)

print(test)
print(test2)
print(acr(:,0)) 
exit

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

    res@xyLineThicknessF    = 5.0
    res@xyDashPatterns      = (/0,1,2,3,4/)
    res@xyLineColors         = (/"red4","red2","darkorange3","orange","gold","olivedrab1",\
                               "limegreen", "forestgreen","darkgreen","seagreen2","cyan2",\
                               "cornflowerblue","blue","navy","purple4"/)

    res@tmBorderThicknessF  = 3.0
    res@tmXBMajorThicknessF = 3.0
    res@tmYLMajorThicknessF = 3.0

    res@tmYLMajorOutwardLengthF = 0.0               ; draw tickmarks inward
    res@tmYLMinorOutwardLengthF = 0.0               ; draw minor ticks inward
    res@tmXBMajorOutwardLengthF = 0.0               
    res@tmXBMinorOutwardLengthF = 0.0   

    ;res@tmXBMode            = "Explicit"
      ;res@tmXBValues         = (/0,6,12/)
      ;res@tmXBLabels         = (/"0", "6", "12"/)
      res@tmXBMinorPerMajor  = 1	
      ;res@tmXBLabelFontHeightF = 0.028
      ;res@tmYLLabelFontHeightF = 0.028
      ;res@tiXAxisFontHeightF  = 0.028
      ;res@tiYAxisFontHeightF  = 0.028

    res@trYMinF             = -0.6
    res@trYMaxF             = 0.6

    res@vpWidthF             = 1
    res@vpHeightF            = 0.8          ; set height of plot

    res@tiMainString        = ""
    res@tiXAxisString       = "Monthly lag"
    res@tiYAxisString       = "Correlation (r)"

    res@pmLegendDisplayMode      = "Always"        ; turn on legend
    res@lgPerimOn                = True           ; Turn off perimeter
    res@pmLegendWidthF           = 0.20           ; Change width and
    res@pmLegendHeightF          = 0.20             ; height of legend
    res@lgLabelFontHeightF       = 0.020
    res@xyExplicitLegendLabels   = index_names
    res@pmLegendOrthogonalPosF   = -1.125
    res@pmLegendParallelPosF     = 0.75
  ; -------------------------------
  ; create plot
  ; -------------------------------
    plot = gsn_csm_xy(wks,xx,acr,res)

  ; -------------------------------
  ; add zero line
  ; -------------------------------
    res_lines                   = True                     ; polyline mods desired
      res_lines@gsLineDashPattern = 0                 ; line style
      res_lines@gsLineThicknessF  = 2.5                     ; line thicker
      res_lines@gsLineColor       = "black"                 ; line color
      res_lines@tfPolyDrawOrder   = "PreDraw"              ; send to back
    xxx = (/0,12/)
    yyy = (/0,0/)
    dum = gsn_add_polyline(wks,plot,xxx,yyy,res_lines)      ; add polyline

  ; -------------------------------
  ; print
  ; -------------------------------
    draw(plot)
    frame(wks)

end if



end

