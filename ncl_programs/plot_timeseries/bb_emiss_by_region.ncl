;================================================;
;  bb_emiss_by_region.ncl
;================================================;
;
;--------------------------------------------------
; This NCL code plots timeseries of BB emissions
; that have already been extracted for a region.
; 
; Currently hardwired to work with four regions.
;
;--- To use type:
;---             bb_emiss_by_region.ncl
;
;                                       rrb 20170417
;--------------------------------------------------
; ================================================;

begin

; =========================================
; USER DEFINED
; =========================================
  tracer = "CO"
  reso = "0.94x1.2"
  
  PLOT = True
    plottype = "x11"
      ;plottype@wkWidth  = 1200
      ;plottype@wkHeight = 1200
      ;plottype@wkPaperWidthF  = 7.0 ;for pdf
      ;plottype@wkPaperHeightF = 20  ;for pdf
    ;plotname = "test"


; =========================================
; SET UP
; =========================================

  order = (/"QFED x CO", "QFED x CO2", "QFED"/)
  ; -------------------------------
  ; emission files
  ; -------------------------------
   top_dir = "/data14b/buchholz/"
   emis_dir = "qfed/cam_"+reso+"/"
   indir = top_dir+emis_dir
   ;e_file_in = "qfed.emis_"+tracer+"_"+reso+"_Tg_regional.nc"
   e_file_in = (/"from_co/region_sums/qfed.emis_"+tracer+"_"+reso+"_Tg_regional.nc",\
                 "from_co2/region_sums/qfed.emis_"+tracer+"_"+reso+"_Tg_regional.nc",\
                 "regridded/region_sums/qfed.emis_"+tracer+"_"+reso+"_Tg_regional.nc"/)  

  ; -------------------------------
  ; data names (from ncl_filedump)
  ; here they specify different regions
  ; -------------------------------
   emiss1           = "bb_0"
   emiss2           = "bb_1"
   emiss3           = "bb_2"
   emiss4           = "bb_3"

; ----------------------------------------
; Load data 1
; ----------------------------------------
print(indir+e_file_in(0))

    fin = addfile(indir+e_file_in(0), "r")
      time := fin->time
      yfrac = tofloat(cd_calendar(time,4))

   emiss_in1 = new((/dimsizes(e_file_in),dimsizes(time)/), float)
   emiss_in2 = new((/dimsizes(e_file_in),dimsizes(time)/), float)
   emiss_in3 = new((/dimsizes(e_file_in),dimsizes(time)/), float)
   emiss_in4 = new((/dimsizes(e_file_in),dimsizes(time)/), float)

  ; collect each file
  do i=0,dimsizes(e_file_in)-1
    fin := addfile(indir+e_file_in(i), "r")
      emiss_in1(i,:)     = fin->$emiss1$
      emiss_in2(i,:)     = fin->$emiss2$
      emiss_in3(i,:)     = fin->$emiss3$
      emiss_in4(i,:)     = fin->$emiss4$

      yfrac = tofloat(cd_calendar(time,4))
  end do

printVarSummary(emiss_in1)

; ----------------------------------------
; Calculate week averages
; ----------------------------------------
 dims  = dimsizes(emiss_in1)
 ntime = dims(1)
 nregions = dims(0)

 days_per_week = 7
 nweeks = ntime / days_per_week

 time_cut = time(0:(days_per_week*nweeks)-1)
 emiss_in1_cut = emiss_in1(:,0:(days_per_week*nweeks)-1)
 emiss_in2_cut = emiss_in2(:,0:(days_per_week*nweeks)-1)
 emiss_in3_cut = emiss_in3(:,0:(days_per_week*nweeks)-1)
 emiss_in4_cut = emiss_in4(:,0:(days_per_week*nweeks)-1)

; Reshape into nregions x number of weeks x 7 days
 time_reshape = reshape(time_cut,(/nweeks,days_per_week/))
 emiss1_4d  = reshape(emiss_in1_cut,(/nregions,nweeks,days_per_week/))
 emiss2_4d  = reshape(emiss_in2_cut,(/nregions,nweeks,days_per_week/))
 emiss3_4d  = reshape(emiss_in3_cut,(/nregions,nweeks,days_per_week/))
 emiss4_4d  = reshape(emiss_in4_cut,(/nregions,nweeks,days_per_week/))

; average across the "week" dimension
 time_weekly_avg = dim_avg_n(time_reshape,1)
   time_weekly_avg@units = time@units
 yfrac2 = tofloat(cd_calendar(time_weekly_avg,4))

 emiss1_weekly_avg = dim_avg_n(emiss1_4d,2)
 emiss2_weekly_avg = dim_avg_n(emiss2_4d,2)
 emiss3_weekly_avg = dim_avg_n(emiss3_4d,2)
 emiss4_weekly_avg = dim_avg_n(emiss4_4d,2)



; =========================================
; PLOT the timeseries
; =========================================
if (PLOT) then

 wks   = gsn_open_wks ("x11","xy")               ; send graphics to PNG file

  ;--------------------------
  ; Plot set-up
  ;--------------------------
 res                  = True                     ; plot mods desired
   res@gsnDraw          = False
   res@gsnFrame         = False

   res@vpWidthF         = 0.8
   res@vpHeightF        = 0.5

   res@tiYAxisString            = "Emissions ("+emiss_in1@units+")"

    res@pmLegendDisplayMode      = "Always"        ; turn on legend
      res@lgPerimOn                = False           ; Turn off perimeter
      res@pmLegendWidthF           = 0.15            ; Change width and
      res@pmLegendHeightF          = 0.1             ; height of legend
      res@lgLabelFontHeightF       = 0.024
      res@pmLegendOrthogonalPosF   = -1.1
      res@pmLegendParallelPosF     = 0.3
  ;--------------------------
  ; Do the plotting
  ;--------------------------
   res@xyMarkLineModes  = (/"Markers", "Markers", "Markers", "Markers"/)   ; choose which have markers
    res@xyMarkers           := (/0,1,2,3/)               ; choose type of marker  
    res@xyMarkerColors      := (/"red4","mediumpurple4","darkgreen"/)  ; Marker color
    res@xyMarkerThicknessF  = 2
    res@xyMarkerOpacityF    := (/0.25,0.25,0.25/)
    res@xyMarkerSizes       := (/0.008,0.010,0.008,0.008/)    ; Marker size (default 0.01)

  ; daily
   res@xyExplicitLegendLabels   = "daily " + order
  plot1  = gsn_csm_xy(wks,yfrac,emiss_in1,res) ; create plot
  res@pmLegendDisplayMode      = "Never"        ; turn on legend
  plot2  = gsn_csm_xy(wks,yfrac,emiss_in2,res) ; create plot
  plot3  = gsn_csm_xy(wks,yfrac,emiss_in3,res) ; create plot
  plot4  = gsn_csm_xy(wks,yfrac,emiss_in4,res) ; create plot

   res@xyMarkLineModes  := "Lines"                               ; choose which have markers
   res@xyDashPatterns      = (/0,16,14,3/)
   res@xyLineThicknesses = (/5.0, 5.0, 5.0, 5.0/)                ; make second line thicker
   res@xyLineColors      = (/"red","blue","limegreen"/)          ; change line color

  ; weekly
  res@xyExplicitLegendLabels   = "weekly " + order
  res@pmLegendDisplayMode        = "Always"        ; turn on legend
    res@pmLegendOrthogonalPosF   = -0.9
  plot1a  = gsn_csm_xy(wks,yfrac2,emiss1_weekly_avg,res) ; create plot
  res@pmLegendDisplayMode      = "Never"        ; turn on legend
  plot2a  = gsn_csm_xy(wks,yfrac2,emiss2_weekly_avg,res) ; create plot
  plot3a  = gsn_csm_xy(wks,yfrac2,emiss3_weekly_avg,res) ; create plot
  plot4a  = gsn_csm_xy(wks,yfrac2,emiss4_weekly_avg,res) ; create plot

  overlay(plot1,plot1a)
  overlay(plot2,plot2a)
  overlay(plot3,plot3a)
  overlay(plot4,plot4a)

  panel_res                       = True
      panel_res@txString              = "BB emissions for "+ tracer
      panel_res@gsnPanelFigureStrings = (/emiss_in1@region, emiss_in2@region, emiss_in3@region, emiss_in4@region/)
      panel_res@gsnPanelFigureStringsJust = "TopRight"

    gsn_panel(wks,(/plot1,plot2,plot3,plot4/),(/2,2/),panel_res)


end if


end
