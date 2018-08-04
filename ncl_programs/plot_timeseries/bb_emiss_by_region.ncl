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
  tracer = "C2H6"
  reso = "0.9x1.25"
  ystart = 2000
  yend = 2018
  
  PLOT = True
    plottype = "x11"
      plottype@wkWidth  = 1800
      plottype@wkHeight = 1800
      ;plottype@wkPaperWidthF  = 7.0 ;for pdf
      ;plottype@wkPaperHeightF = 20  ;for pdf
    plotname = "~/BB_Emiss"

  CMIP = False
  MONTHAVG = True
; =========================================
; SET UP
; =========================================

  ;order = (/"QFED x CO", "QFED x CO2", "QFED", "FINN"/)
  ;order = (/ "QFED", "FINN"/)
  ;order = (/  "QFED regridded","QFED native","QFED x FINN", "FINN 1.5"/)
  ;order = (/  "QFED regridded","QFED x FINN", "FINN 1.5","GFAS x FINN", "GFAS regridded"/)
  ;order = (/  "QFED", "FINN 1.5", "GFAS"/)
  order = (/  "QFED", "FINN 1.5", "FINN1.6", "FINN1.6new" /)
  ; -------------------------------
  ; emission files
  ; -------------------------------
   top_dir = "/data14b/buchholz/"
   qfed_dir = "qfed/cam_"+reso+"/"
   finn_dir = "finn/cam_"+reso+"/"
   gfas_dir = "gfas/cam_"+reso+"/"
   cmip6_dir ="gfed/cmip6_cam_"+reso+"/"
   ;e_file_in = (/;qfed_dir+"regridded/region_sums/qfed.emis_"+tracer+"_"+reso+"_QFED_Tg_regional_2014_2017.nc",\
   ;              ;qfed_dir+"regridded/region_sums/qfed.emis_"+tracer+"_Tg_regional_2016.nc",\
   ;              qfed_dir+"from_co2/v2.5/region_sums/qfed.emis_"+tracer+"_"+reso+"_QFED_cross_FINN_Tg_regional.nc",\                 
   ;              finn_dir+"region_sums/finn.emis_"+tracer+"_"+reso+"_FINN_Tg_regional_2014_2017.nc", \
   ;              ;gfas_dir+"regridded/region_sums/gfas.emis_"+tracer+"_"+reso+"_GFAS_Tg_regional.nc",\  
   ;              gfas_dir+"from_co2/region_sums/gfas.emis_"+tracer+"_"+reso+"_GFAS_cross_FINN_Tg_regional.nc"/)

   e_file_in = (/;qfed_dir+"regridded/region_sums/qfed.emis_"+tracer+"_"+reso+"_QFED_Tg_regional_2014_2017.nc",\
                 ;qfed_dir+"regridded/region_sums/qfed.emis_"+tracer+"_Tg_regional_2016.nc",\
                 qfed_dir+"from_co2/v2.5/region_sums/qfed.emis_"+tracer+"_"+reso+"_QFED_cross_FINN_Tg_regional_2000_2018.nc",\                 
                 finn_dir+"region_sums/finn.emis_"+tracer+"_"+reso+"_FINN_Tg_regional_2002_2017.nc"/)


   ; cheyenne
   ;top_dir = "/glade/work/buchholz/data_processing/CAM-chem/emissions/"
   ;e_file_in := (/"qfed.emis_"+tracer+"_0.9x1.25_QFED_cross_FINN_Tg_regional_2005_2017.nc",\               
   ;              "finn.emis_"+tracer+"_0.9x1.25_FINN1.5_Tg_regional_2005_2017.nc",\
   ;              "finn.emis_"+tracer+"_0.9x1.25_FINN1.6_Tg_regional_2002_2017.nc",\
   ;              "finn.emis_"+tracer+"_0.9x1.25_FINN1.6_Tg_regional_2017_2017.nc"/)
print(top_dir+e_file_in)

  ; -------------------------------
  ; data names (from ncl_filedump)
  ; here they specify different regions
  ; -------------------------------
   emiss1           = "bb_0"
   emiss2           = "bb_1"
   emiss3           = "bb_2"
   emiss4           = "bb_3"
   emiss5           = "bb_4"
   emiss6           = "bb_5"

   ;region_names = (/"Maritime SEA", "Australasia", \
   ;                 "Southern Africa", "South America",\
   ;                 "Siberia", "North America" /)

; ----------------------------------------
; Load data
; ----------------------------------------
print(top_dir+e_file_in(0))

    fin = addfile(top_dir+e_file_in(0), "r")
      time_dummy := fin->time
      yfrac_dummy:= tofloat(cd_calendar(time_dummy,4))
      range_ind  := ind(yfrac_dummy.ge.ystart.and.yfrac_dummy.lt.yend)
      time = time_dummy(range_ind)
      yfrac = tofloat(cd_calendar(time,4))
      yyyymmdd = (cd_calendar(time,2))

   emiss_in1 = new((/dimsizes(e_file_in),dimsizes(time)/), float)
   emiss_in2 = new((/dimsizes(e_file_in),dimsizes(time)/), float)
   emiss_in3 = new((/dimsizes(e_file_in),dimsizes(time)/), float)
   emiss_in4 = new((/dimsizes(e_file_in),dimsizes(time)/), float)
   emiss_in5 = new((/dimsizes(e_file_in),dimsizes(time)/), float)
   emiss_in6 = new((/dimsizes(e_file_in),dimsizes(time)/), float)

  ; collect each file
  do i=0,dimsizes(e_file_in)-1
  ;do i=0,2
    fin := addfile(top_dir+e_file_in(i), "r")
      time_2_dummy := fin->time
      yfrac_2_dummy:= tofloat(cd_calendar(time_2_dummy,4))
      range_2_ind  := ind(yfrac_2_dummy.ge.ystart.and.yfrac_2_dummy.lt.yend)
      timenew := time_2_dummy(range_2_ind)
      yyyymmddnew := (cd_calendar(timenew,2))

      dummy_1     := fin->$emiss1$
      dummy_2     := fin->$emiss2$
      dummy_3     := fin->$emiss3$
      dummy_4     := fin->$emiss4$
      dummy_5     := fin->$emiss5$
      dummy_6     := fin->$emiss6$

     ind_overlap := ind(yyyymmdd.ge.yyyymmddnew(0).and.yyyymmdd.le.yyyymmddnew(dimsizes(yyyymmddnew)-1))

     if (yyyymmddnew(dimsizes(yyyymmddnew)-1).gt.yyyymmdd(dimsizes(yyyymmdd)-1))
        print("*--------------------------------New file ends after old file")
        cut_range := ind(yyyymmddnew.le.yyyymmdd(dimsizes(yyyymmdd)-1))
        newrange := range_2_ind(cut_range)
        range_2_ind := newrange
     end if

;printVarSummary(ind_overlap)
;printVarSummary(range_2_ind)
printVarSummary(dummy_1)
printVarSummary(emiss_in1)
      emiss_in1(i,ind_overlap) = dummy_1(range_2_ind)
      emiss_in2(i,ind_overlap) = dummy_2(range_2_ind)
      emiss_in3(i,ind_overlap) = dummy_3(range_2_ind)
      emiss_in4(i,ind_overlap) = dummy_4(range_2_ind)
      emiss_in5(i,ind_overlap) = dummy_5(range_2_ind)
      emiss_in6(i,ind_overlap) = dummy_6(range_2_ind)
  end do

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
 emiss_in5_cut = emiss_in5(:,0:(days_per_week*nweeks)-1)
 emiss_in6_cut = emiss_in6(:,0:(days_per_week*nweeks)-1)

; Reshape into nregions x number of weeks x 7 days
 time_reshape = reshape(time_cut,(/nweeks,days_per_week/))
 emiss1_4d  = reshape(emiss_in1_cut,(/nregions,nweeks,days_per_week/))
 emiss2_4d  = reshape(emiss_in2_cut,(/nregions,nweeks,days_per_week/))
 emiss3_4d  = reshape(emiss_in3_cut,(/nregions,nweeks,days_per_week/))
 emiss4_4d  = reshape(emiss_in4_cut,(/nregions,nweeks,days_per_week/))
 emiss5_4d  = reshape(emiss_in5_cut,(/nregions,nweeks,days_per_week/))
 emiss6_4d  = reshape(emiss_in6_cut,(/nregions,nweeks,days_per_week/))

; average across the "week" dimension
 time_weekly_avg = dim_avg_n(time_reshape,1)
   time_weekly_avg@units = time@units
 yfrac2 = tofloat(cd_calendar(time_weekly_avg,4))

 emiss1_weekly_avg = dim_avg_n(emiss1_4d,2)
 emiss2_weekly_avg = dim_avg_n(emiss2_4d,2)
 emiss3_weekly_avg = dim_avg_n(emiss3_4d,2)
 emiss4_weekly_avg = dim_avg_n(emiss4_4d,2)
 emiss5_weekly_avg = dim_avg_n(emiss5_4d,2)
 emiss6_weekly_avg = dim_avg_n(emiss6_4d,2)

; ----------------------------------------
; Month averages
; ----------------------------------------
if(CMIP) then
    fin2 = addfile(top_dir+cmip6_dir+"region_sums/finn.emis_CO_0.9x1.25_CMIP6_Tg_regional_1750_2015.nc", "r")
      cmip_time_dummy := fin2->time
      cmip_yfrac_dummy:= tofloat(cd_calendar(cmip_time_dummy,4))
      cmip_range_ind  := ind(cmip_yfrac_dummy.ge.ystart.and.cmip_yfrac_dummy.lt.yend)
      cmip_time = cmip_time_dummy(cmip_range_ind)
      cmip_yfrac = tofloat(cd_calendar(cmip_time,4))

      cmip_emiss1_monthly     := fin2->$emiss1$(cmip_range_ind)
      cmip_emiss2_monthly     := fin2->$emiss2$(cmip_range_ind)
      cmip_emiss3_monthly     := fin2->$emiss3$(cmip_range_ind)
      cmip_emiss4_monthly     := fin2->$emiss4$(cmip_range_ind)
      cmip_emiss5_monthly     := fin2->$emiss5$(cmip_range_ind)
      cmip_emiss6_monthly     := fin2->$emiss6$(cmip_range_ind)

end if


if(MONTHAVG) then

  yyyymm = yyyymm_time(ystart, yend, "integer")
  month_yfrac = yyyymm_to_yyyyfrac(yyyymm, 0.5)
  yyyymm_compare = cd_calendar(time, -1)
      emiss1_monthly     = new((/dimsizes(e_file_in),dimsizes(yyyymm)/), float)
      emiss2_monthly     = new((/dimsizes(e_file_in),dimsizes(yyyymm)/), float)
      emiss3_monthly     = new((/dimsizes(e_file_in),dimsizes(yyyymm)/), float)
      emiss4_monthly     = new((/dimsizes(e_file_in),dimsizes(yyyymm)/), float)
      emiss5_monthly     = new((/dimsizes(e_file_in),dimsizes(yyyymm)/), float)
      emiss6_monthly     = new((/dimsizes(e_file_in),dimsizes(yyyymm)/), float)

  do i=0,dimsizes(yyyymm)-1
    ind_month := ind(yyyymm_compare.eq.yyyymm(i))
    if (.not.ismissing(ind_month(0))) then
      emiss1_monthly(:,i)     = dim_sum_n(emiss_in1(:,ind_month),1)
      emiss2_monthly(:,i)     = dim_sum_n(emiss_in2(:,ind_month),1)
      emiss3_monthly(:,i)     = dim_sum_n(emiss_in3(:,ind_month),1)
      emiss4_monthly(:,i)     = dim_sum_n(emiss_in4(:,ind_month),1)
      emiss5_monthly(:,i)     = dim_sum_n(emiss_in5(:,ind_month),1)
      emiss6_monthly(:,i)     = dim_sum_n(emiss_in6(:,ind_month),1)
    end if
  end do


end if


; =========================================
; PLOT the timeseries
; =========================================
if (PLOT) then

 wks   = gsn_open_wks (plottype,plotname)               ; send graphics to PNG file

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

   ;res@tmXBMode         = "Explicit"
   ;res@tmXBValues       = (/2014.,2014.5,2015./)
   ;res@tmXBLabels       = (/"201401","201406","201501"/)
   res@tmXBLabelFontHeightF = 0.030
   res@tmYLLabelFontHeightF = 0.030
  ;--------------------------
  ; Do the plotting
  ;--------------------------
   res@xyMarkLineModes  = (/"Markers", "Markers", "Markers", "Markers"/)   ; choose which have markers
    res@xyMarkers           := (/0,1,2,3/)               ; choose type of marker  
    res@xyMarkerColors      := (/"mediumpurple4", "red4","red","darkgreen"/)  ; Marker color
    res@xyMarkerThicknessF  = 2
    res@xyMarkerOpacityF    := (/0.25,0.25,0.25,0.25/)
    res@xyMarkerSizes       := (/0.008,0.010,0.008,0.008/)    ; Marker size (default 0.01)

  ; daily
   res@xyExplicitLegendLabels   = "daily " + order
    res@pmLegendOrthogonalPosF   = -1.42
    res@pmLegendParallelPosF     = 0.7
   ;res@trYMaxF          = 0.2
  ; res@trYMaxF          = 0.0016
  plot1  = gsn_csm_xy(wks,yfrac,emiss_in1,res) ; create plot
  res@pmLegendDisplayMode      = "Never"        ; turn on legend
   ;res@trYMaxF          = 0.4
  ; res@trYMaxF          = 0.009
  plot2  = gsn_csm_xy(wks,yfrac,emiss_in2,res) ; create plot
   ;res@trYMaxF          = 1.3
  ; res@trYMaxF          = 0.012
  plot3  = gsn_csm_xy(wks,yfrac,emiss_in3,res) ; create plot
   ;res@trYMaxF          = 2.0
  plot4  = gsn_csm_xy(wks,yfrac,emiss_in4,res) ; create plot
   ;res@trYMaxF          = 0.6
  ; res@trYMaxF          = 0.0034
  plot5  = gsn_csm_xy(wks,yfrac,emiss_in5,res) ; create plot
   ;res@trYMaxF          = 1.0
  plot6  = gsn_csm_xy(wks,yfrac,emiss_in6,res) ; create plot

   res@xyMarkLineModes  := "Lines"                               ; choose which have markers
   res@xyDashPatterns      = (/0,16,14,3/)
   res@xyLineThicknesses = (/8.0, 10.0, 4.0, 4.0/)                ; make second line thicker
   res@xyLineColors      = (/"blue3", "red4","red","limegreen"/)          ; change line color

  ; weekly
  res@xyExplicitLegendLabels   = "weekly " + order
  res@pmLegendDisplayMode        = "Always"        ; turn on legend
    res@pmLegendOrthogonalPosF   = -1.42
    res@pmLegendParallelPosF     = 0.2
  plot1a  = gsn_csm_xy(wks,yfrac2,emiss1_weekly_avg,res) ; create plot
  res@pmLegendDisplayMode      = "Never"        ; turn on legend
  plot2a  = gsn_csm_xy(wks,yfrac2,emiss2_weekly_avg,res) ; create plot
  plot3a  = gsn_csm_xy(wks,yfrac2,emiss3_weekly_avg,res) ; create plot
  plot4a  = gsn_csm_xy(wks,yfrac2,emiss4_weekly_avg,res) ; create plot
  plot5a  = gsn_csm_xy(wks,yfrac2,emiss5_weekly_avg,res) ; create plot
  plot6a  = gsn_csm_xy(wks,yfrac2,emiss6_weekly_avg,res) ; create plot


if(CMIP) then
  res@xyLineColors      := (/"black"/)  ; Line color
  res@xyExplicitLegendLabels   := "monthly CMIP6"
  res@pmLegendDisplayMode        = "Always"        ; turn on legend
    res@pmLegendOrthogonalPosF   = -1.30
      res@pmLegendParallelPosF     = 0.28
  plot1b  = gsn_csm_xy(wks,cmip_yfrac,cmip_emiss1_monthly,res) ; create plot
  res@pmLegendDisplayMode      = "Never"        ; turn on legend
  plot2b  = gsn_csm_xy(wks,cmip_yfrac,cmip_emiss2_monthly,res) ; create plot
  plot3b  = gsn_csm_xy(wks,cmip_yfrac,cmip_emiss3_monthly,res) ; create plot
  plot4b  = gsn_csm_xy(wks,cmip_yfrac,cmip_emiss4_monthly,res) ; create plot
  plot5b  = gsn_csm_xy(wks,cmip_yfrac,cmip_emiss5_monthly,res) ; create plot
  plot6b  = gsn_csm_xy(wks,cmip_yfrac,cmip_emiss6_monthly,res) ; create plot

  overlay(plot1,plot1b)
  overlay(plot2,plot2b)
  overlay(plot3,plot3b)
  overlay(plot4,plot4b)
  overlay(plot5,plot5b)
  overlay(plot6,plot6b)
end if


  overlay(plot1,plot1a)
  overlay(plot2,plot2a)
  overlay(plot3,plot3a)
  overlay(plot4,plot4a)
  overlay(plot5,plot5a)
  overlay(plot6,plot6a)



  panel_res                       = True
      panel_res@txString              = "BB emissions for "+ tracer + " " + ystart + " to " + yend
      panel_res@gsnPanelFigureStrings = (/emiss_in1@region, emiss_in2@region, emiss_in3@region, emiss_in4@region,emiss_in5@region,emiss_in6@region/)
      panel_res@gsnPanelFigureStringsJust = "TopRight"

   ; gsn_panel(wks,(/plot1,plot2,plot3,plot4,plot5,plot6/),(/2,3/),panel_res)



if(MONTHAVG) then
  res@pmLegendDisplayMode        = "Always"        ; turn on legend
  res@xyExplicitLegendLabels   = "monthly " + order
  res@pmLegendHeightF          = 0.08             ; height of legend
  res@pmLegendOrthogonalPosF   = -1.65
  res@pmLegendParallelPosF     = 0.22
   res@tmXBLabelFontHeightF = 0.020
   res@tmYLLabelFontHeightF = 0.020
   res@vpWidthF         = 0.8
   res@vpHeightF        = 0.3

   res@gsnRightString   = emiss_in2@region
  plot2b  = gsn_csm_xy(wks,month_yfrac,emiss2_monthly,res) ; create plot
   res@gsnRightString   = emiss_in4@region
  plot4b  = gsn_csm_xy(wks,month_yfrac,emiss4_monthly,res) ; create plot

  ;overlay(plot2b,plot4b)
  draw(plot4b)
  frame(wks)
end if

end if


end
