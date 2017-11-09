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
  location = "CentralSAmerica"
  plot_title = "(f) Central South America"
    ;pltname      = "~/"+location+"_laggedcorr2"
    pltname      = "/net/mopfl/home/buchholz/"+location+"_laggedcorr2"
  maxlag = 12
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
   mopitt_dir = "/IASI/home/buchholz/MOPITT_subset/V7/anomalies/"
  ; mopitt_dir = "/net/mopfl/home/buchholz/MOPITT_subset/V7/anomalies/"
   mopitt_file = mopitt_dir+location+"_V7TMOPITTanomalies.nc"

  ; -------------------------------
  ; CLIMATE INDEX
  ; -------------------------------
   ci_dir = "/IASI/home/buchholz/Climate_Indices/converted/"
   ;ci_dir = "/net/mopfl/home/buchholz/Climate_Indices/converted/"
   ci_files = systemfunc ("ls "+ci_dir+"*_index_month_avg.nc")

  ;------------
  ; toggles
  ;------------
  PLOT           = True
    plttype      = "png"
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
    ;pltname      = location+"_laggedcorr2"
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
   overlap_index_vals= new((/dimsizes(ci_files),maxlag+1, dimsizes(mopitt_time)/), float)
   index_names = new(dimsizes(ci_files),string)


  do i = 0,dimsizes(ci_files)-1
    i_fin := addfile(ci_files(i), "r")            ; read in
      var_names := getfilevarnames( i_fin )
      index_names(i) = var_names(0)
      index_anom    := i_fin->$var_names(0)$
      index_time    := index_anom&time
    ; -------------------------------
    ; Crop index series to MOPITT size
    ; -------------------------------   
       overlap_times := ind(index_time.ge.mopitt_time(0).and.\
                           index_time.le.mopitt_time(dimsizes(mopitt_time)-1))
       ind_overlap = new(dimsizes(mopitt_time), integer)

     do j = 0,maxlag
       do k = 0,j
         ind_overlap(j-k) = overlap_times(0)-k
       end do
       ind_overlap(j+1:dimsizes(ind_overlap)-1) = overlap_times(1:(dimsizes(overlap_times)-1-j))
       overlap_index_vals(i,j,:) = tofloat(index_anom(ind_overlap))
     end do

   end do

   overlap_index_vals!2 = "time"
   overlap_index_vals&time = mopitt_time
   overlap_index_vals!0 = "index"
   overlap_index_vals@indices =  index_names
   overlap_index_vals!1 = "month_lag"

;--------------------------------------------
; calculate cross correlations
;--------------------------------------------  
; x_lead_y = esccr(x,y,maxlag)
acr = esccr(overlap_index_vals(:,0,:),mopitt_anom,maxlag)
   acr!0 = "index"
   acr@indices =  index_names
  xx = ispan(0,maxlag,1)

;--------------------------------------------
; correlations for only Aug-Nov
;--------------------------------------------  
  split_dates = str_split_by_length(tostring(mopitt_time),4)
  m_select_ind = ind(split_dates(:,1).eq."09".or.\
                     split_dates(:,1).eq."10".or.\
                     split_dates(:,1).eq."11".or.\
                     split_dates(:,1).eq."12")
  m_select_data = mopitt_anom(m_select_ind)
  i_select_data =  overlap_index_vals(:,:,m_select_ind)

 sond_lagcorrs = escorc(m_select_data,i_select_data)
 alldata_lagcorrs = escorc(overlap_index_vals,mopitt_anom)

print(sond_lagcorrs)
;print(alldata_lagcorrs)
;print(split_dates(m_select_ind,:))

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
    res@gsnRightString      = plot_title
    res@gsnRightStringFontHeightF =0.034

    res@xyLineThicknessF    = 10.0
    res@xyDashPatterns      = (/0,1,2,3,4/)
    res@xyLineColors         = (/"red2","orange", "forestgreen", "purple4"/)

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
    res@trYMaxF             = 0.8

    res@vpWidthF             = 1
    res@vpHeightF            = 0.7          ; set height of plot

    res@tiMainString        = ""
    res@tiXAxisString       = "Monthly lag"
    res@tiYAxisString       = "Correlation (r)"

    res@pmLegendDisplayMode      = "Never"        ; turn on legend
    res@lgPerimOn                = True           ; Turn off perimeter
    res@pmLegendWidthF           = 0.20           ; Change width and
    res@pmLegendHeightF          = 0.20             ; height of legend
    res@lgLabelFontHeightF       = 0.030
    plot_index_names = str_split_csv(index_names, "_",0)
    ;res@xyExplicitLegendLabels   = plot_index_names(:,0)
    res@xyExplicitLegendLabels   = (/"SAM", "DMI", "Nino3.4", "TSA"/)
    res@pmLegendOrthogonalPosF   = -1.155
    res@pmLegendParallelPosF     = 0.83
  ; -------------------------------
  ; create plot
  ; -------------------------------
    plot = gsn_csm_xy(wks,xx,acr,res)

    ; selected month correlations
    plot1 = gsn_csm_xy(wks,xx,sond_lagcorrs,res)

    ; all data with sliding anomaly method
    plot2 = gsn_csm_xy(wks,xx,alldata_lagcorrs,res)

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
    dum1 = gsn_add_polyline(wks,plot1,xxx,yyy,res_lines)      ; add polyline
    dum2 = gsn_add_polyline(wks,plot2,xxx,yyy,res_lines)      ; add polyline

  ; -------------------------------
  ; print
  ; -------------------------------
   ;overlay(plot, plot1)
   ;overlay(plot, plot2)

    ;draw(plot)
    draw(plot1)
    frame(wks)

end if



end

