;================================================;
;  CAM_chem_bb_output_by_region.ncl
;================================================;
;
;--------------------------------------------------
; This NCL code plots timeseries of BB emissions
; that have already been extracted for a region.
; 
; Currently hardwired to work with four regions.
;
;--- To use type:
;---             CAM_chem_bb_output_by_region.ncl
;
;                                       rrb 20180618
;--------------------------------------------------
; ================================================;

begin

; =========================================
; USER DEFINED
; =========================================
  tracer = "CO"
  reso = "0.9x1.25"
  ystart = 2014
  yend = 2015
  
  PLOT = True
    plottype = "png"
      plottype@wkWidth  = 1800
      plottype@wkHeight = 1800
      ;plottype@wkPaperWidthF  = 7.0 ;for pdf
      ;plottype@wkPaperHeightF = 20  ;for pdf
    plotname = "~/BB_tcol_all_uncert"

uncert1 = True
uncert2 = True

; =========================================
; SET UP
; =========================================

  ;order = (/"QFED x CO", "QFED x CO2", "QFED", "FINN"/)
  order = (/ "qfed", "finn", "gfas"/)
  ; -------------------------------
  ; emission files
  ; -------------------------------
   top_dir = "/glade2/work/buchholz/CAM_chem_output/fire_uncert/"
   e_file_in = (/ ;"cmip/cmip_CO_regional_2014.nc",\
                   "qfedBBCO/qfedBBCO_CO_regional_2014.nc",\
                   "finnBBCO/finnBBCO_CO_regional_2014.nc",\
                   "gfasBBCO/gfasBBCO_CO_regional_2014.nc",\
                   "qfedBBCOmin/qfedBBCOmin_CO_regional_2014.nc",\
                   "qfedBBCOmax/qfedBBCOmax_CO_regional_2014.nc",\ 
                   "qfedBB/qfedBB_CO_regional_2014.nc",\
                   "qfedBBmin/qfedBBmin_CO_regional_2014.nc",\
                   "qfedBBmax/qfedBBmax_CO_regional_2014.nc"/)
                 ;qfed_dir+"regridded/region_sums/qfed.emis_"+tracer+"_Tg_regional_2016.nc",\/)  
print(top_dir+e_file_in(0))
  ; -------------------------------
  ; data names (from ncl_filedump)
  ; here they specify different regions
  ; -------------------------------
   emiss1           = "total_column_0"
   emiss2           = "total_column_1"
   emiss3           = "total_column_2"
   emiss4           = "total_column_3"
   emiss5           = "total_column_4"
   emiss6           = "total_column_5"

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
      dummy_1     := fin->$emiss1$
      dummy_2     := fin->$emiss2$
      dummy_3     := fin->$emiss3$
      dummy_4     := fin->$emiss4$
      dummy_5     := fin->$emiss5$
      dummy_6     := fin->$emiss6$

printVarSummary(range_2_ind)
printVarSummary(dummy_1)
printVarSummary(emiss_in1)
      emiss_in1(i,:) = dummy_1(range_2_ind)
      emiss_in2(i,:) = dummy_2(range_2_ind)
      emiss_in3(i,:) = dummy_3(range_2_ind)
      emiss_in4(i,:) = dummy_4(range_2_ind)
      emiss_in5(i,:) = dummy_5(range_2_ind)
      emiss_in6(i,:) = dummy_6(range_2_ind)
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

 emiss1_weekly_avg = dim_avg_n(emiss1_4d,2)/1e18
 emiss2_weekly_avg = dim_avg_n(emiss2_4d,2)/1e18
 emiss3_weekly_avg = dim_avg_n(emiss3_4d,2)/1e18
 emiss4_weekly_avg = dim_avg_n(emiss4_4d,2)/1e18
 emiss5_weekly_avg = dim_avg_n(emiss5_4d,2)/1e18
 emiss6_weekly_avg = dim_avg_n(emiss6_4d,2)/1e18


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

   res@tiYAxisString            = "Total Column (x 10~S2~18   molec cm~S2~-2  )"

    res@pmLegendDisplayMode      = "Always"        ; turn on legend
      res@lgPerimOn                = False           ; Turn off perimeter
      res@pmLegendWidthF           = 0.15            ; Change width and
      res@pmLegendHeightF          = 0.1             ; height of legend
      res@lgLabelFontHeightF       = 0.032
      res@pmLegendOrthogonalPosF   = -1.1
      res@pmLegendParallelPosF     = 0.3

   res@tmXBMode         = "Explicit"
   res@tmXBValues       = (/2014.,2014.5,2015./)
   res@tmXBLabels       = (/"201401","201406","201501"/)
   res@tmXBLabelFontHeightF = 0.030
   res@tmYLLabelFontHeightF = 0.030



  ;--------------------------
  ; Do the plotting
  ;--------------------------
   res@xyMarkLineModes  = (/"Markers", "Markers", "Markers", "Markers", "Markers", "Markers", "Markers"/)   ; choose which have markers
    res@xyMarkers           := (/0,1,2,3,4,5,6/)               ; choose type of marker  
    res@xyMarkerColors      := (/"red4","mediumpurple4","darkgreen"/)  ; Marker color
    res@xyMarkerThicknessF  = 2
    res@xyMarkerOpacityF    := (/0.25,0.25,0.25/)
    res@xyMarkerSizes       := (/0.008,0.010,0.008,0.008/)    ; Marker size (default 0.01)

  ; daily
   res@xyExplicitLegendLabels   = "daily " + order
    res@pmLegendOrthogonalPosF   = -1.8
   res@trYMaxF          = 2.1
  plot1  = gsn_csm_xy(wks,yfrac,emiss_in1(0:2,:)/1e18,res) ; create plot
  res@pmLegendDisplayMode      = "Never"        ; turn on legend
   res@trYMaxF          = 1.7
  plot2  = gsn_csm_xy(wks,yfrac,emiss_in2(0:2,:)/1e18,res) ; create plot
   res@trYMaxF          = 2.0
  plot3  = gsn_csm_xy(wks,yfrac,emiss_in3(0:2,:)/1e18,res) ; create plot
  plot4  = gsn_csm_xy(wks,yfrac,emiss_in4(0:2,:)/1e18,res) ; create plot
   res@trYMaxF          = 2.1
  plot5  = gsn_csm_xy(wks,yfrac,emiss_in5(0:2,:)/1e18,res) ; create plot
  plot6  = gsn_csm_xy(wks,yfrac,emiss_in6(0:2,:)/1e18,res) ; create plot

   res@xyMarkLineModes  := "Lines"                               ; choose which have markers
    res@xyLineThicknessF  = 10
   res@xyDashPatterns      = (/0,16,14,3/)
   res@xyLineThicknesses = (/8.0, 8.0, 8.0, 8.0/)                ; make second line thicker
   res@xyLineColors      = (/"red4","blue","forestgreen","grey"/)          ; change line color

  ; weekly
  res@xyExplicitLegendLabels   = "weekly " + order
  res@pmLegendDisplayMode        = "Always"        ; turn on legend
    res@pmLegendOrthogonalPosF   = -1.55
  plot1a  = gsn_csm_xy(wks,yfrac2,emiss1_weekly_avg(0:2,:),res) ; create plot
  res@pmLegendDisplayMode      = "Never"        ; turn on legend
  plot2a  = gsn_csm_xy(wks,yfrac2,emiss2_weekly_avg(0:2,:),res) ; create plot
  plot3a  = gsn_csm_xy(wks,yfrac2,emiss3_weekly_avg(0:2,:),res) ; create plot
  plot4a  = gsn_csm_xy(wks,yfrac2,emiss4_weekly_avg(0:2,:),res) ; create plot
  plot5a  = gsn_csm_xy(wks,yfrac2,emiss5_weekly_avg(0:2,:),res) ; create plot
  plot6a  = gsn_csm_xy(wks,yfrac2,emiss6_weekly_avg(0:2,:),res) ; create plot
      

  overlay(plot1,plot1a)
  overlay(plot2,plot2a)
  overlay(plot3,plot3a)
  overlay(plot4,plot4a)
  overlay(plot5,plot5a)
  overlay(plot6,plot6a)  


if (uncert1) then
  ; -------------------------------
  ; Define a polygon for std-dev
  ; -------------------------------
   ya1    = new( (/2*dimsizes(yfrac2)/), float )
   yb1    = new( (/2*dimsizes(yfrac2)/), float )
   do k=0,dimsizes(yfrac2)-1
     ya1(k) = yfrac2(k)
     yb1(k) = emiss1_weekly_avg(4,k)
     yb1(2*dimsizes(yfrac2)-1-k) = emiss1_weekly_avg(3,k)
     ya1(2*dimsizes(yfrac2)-1-k) = yfrac2(k)
   end do
    gsres                          = True                ; poly res
    gsres@gsFillColor            = "red"                ; color chosen
    gsres@gsFillOpacityF         = 0.3                 
    dum1a = gsn_add_polygon(wks,plot1,ya1,yb1,gsres)

  ; -------------------------------
  ; Define a polygon for std-dev
  ; -------------------------------
   ya1    = new( (/2*dimsizes(yfrac2)/), float )
   yb1    = new( (/2*dimsizes(yfrac2)/), float )
   do k=0,dimsizes(yfrac2)-1
     ya1(k) = yfrac2(k)
     yb1(k) = emiss2_weekly_avg(4,k)
     yb1(2*dimsizes(yfrac2)-1-k) = emiss2_weekly_avg(3,k)
     ya1(2*dimsizes(yfrac2)-1-k) = yfrac2(k)
   end do
    gsres                          = True                ; poly res
    gsres@gsFillColor            = "red"                ; color chosen
    gsres@gsFillOpacityF         = 0.3                 
    dum2a = gsn_add_polygon(wks,plot2,ya1,yb1,gsres)

  ; -------------------------------
  ; Define a polygon for std-dev
  ; -------------------------------
   ya1    = new( (/2*dimsizes(yfrac2)/), float )
   yb1    = new( (/2*dimsizes(yfrac2)/), float )
   do k=0,dimsizes(yfrac2)-1
     ya1(k) = yfrac2(k)
     yb1(k) = emiss3_weekly_avg(4,k)
     yb1(2*dimsizes(yfrac2)-1-k) = emiss3_weekly_avg(3,k)
     ya1(2*dimsizes(yfrac2)-1-k) = yfrac2(k)
   end do
    gsres                          = True                ; poly res
    gsres@gsFillColor            = "red"                ; color chosen
    gsres@gsFillOpacityF         = 0.3                 
    dum3a = gsn_add_polygon(wks,plot3,ya1,yb1,gsres)


  ; -------------------------------
  ; Define a polygon for std-dev
  ; -------------------------------
   ya1    = new( (/2*dimsizes(yfrac2)/), float )
   yb1    = new( (/2*dimsizes(yfrac2)/), float )
   do k=0,dimsizes(yfrac2)-1
     ya1(k) = yfrac2(k)
     yb1(k) = emiss4_weekly_avg(4,k)
     yb1(2*dimsizes(yfrac2)-1-k) = emiss4_weekly_avg(3,k)
     ya1(2*dimsizes(yfrac2)-1-k) = yfrac2(k)
   end do
    gsres                          = True                ; poly res
    gsres@gsFillColor            = "red"                ; color chosen
    gsres@gsFillOpacityF         = 0.3                 
    dum4a = gsn_add_polygon(wks,plot4,ya1,yb1,gsres)

  ; -------------------------------
  ; Define a polygon for std-dev
  ; -------------------------------
   ya1    = new( (/2*dimsizes(yfrac2)/), float )
   yb1    = new( (/2*dimsizes(yfrac2)/), float )
   do k=0,dimsizes(yfrac2)-1
     ya1(k) = yfrac2(k)
     yb1(k) = emiss5_weekly_avg(4,k)
     yb1(2*dimsizes(yfrac2)-1-k) = emiss5_weekly_avg(3,k)
     ya1(2*dimsizes(yfrac2)-1-k) = yfrac2(k)
   end do
    gsres                          = True                ; poly res
    gsres@gsFillColor            = "red"                ; color chosen
    gsres@gsFillOpacityF         = 0.3                 
    dum5a = gsn_add_polygon(wks,plot5,ya1,yb1,gsres)

  ; -------------------------------
  ; Define a polygon for std-dev
  ; -------------------------------
   ya1    = new( (/2*dimsizes(yfrac2)/), float )
   yb1    = new( (/2*dimsizes(yfrac2)/), float )
   do k=0,dimsizes(yfrac2)-1
     ya1(k) = yfrac2(k)
     yb1(k) = emiss6_weekly_avg(4,k)
     yb1(2*dimsizes(yfrac2)-1-k) = emiss6_weekly_avg(3,k)
     ya1(2*dimsizes(yfrac2)-1-k) = yfrac2(k)
   end do
    gsres                          = True                ; poly res
    gsres@gsFillColor            = "red"                ; color chosen
    gsres@gsFillOpacityF         = 0.3                 
    dum6a = gsn_add_polygon(wks,plot6,ya1,yb1,gsres)
end if


if (uncert2) then 
  ; -------------------------------
  ; Define a polygon for std-dev
  ; -------------------------------
   ya1    = new( (/2*dimsizes(yfrac2)/), float )
   yb1    = new( (/2*dimsizes(yfrac2)/), float )
   do k=0,dimsizes(yfrac2)-1
     ya1(k) = yfrac2(k)

     yb1(k) = emiss1_weekly_avg(7,k)
     yb1(2*dimsizes(yfrac2)-1-k) = emiss1_weekly_avg(6,k)
     ya1(2*dimsizes(yfrac2)-1-k) = yfrac2(k)
   end do
    gsres                          = True                ; poly res
    gsres@gsFillColor            = "gray40"                ; color chosen
    gsres@gsFillOpacityF         = 0.4                 
    dum1b = gsn_add_polygon(wks,plot1,ya1,yb1,gsres)

  ; -------------------------------
  ; Define a polygon for std-dev
  ; -------------------------------
   ya1    = new( (/2*dimsizes(yfrac2)/), float )
   yb1    = new( (/2*dimsizes(yfrac2)/), float )
   do k=0,dimsizes(yfrac2)-1
     ya1(k) = yfrac2(k)
     yb1(k) = emiss2_weekly_avg(7,k)
     yb1(2*dimsizes(yfrac2)-1-k) = emiss2_weekly_avg(6,k)
     ya1(2*dimsizes(yfrac2)-1-k) = yfrac2(k)
   end do             
    dum2b = gsn_add_polygon(wks,plot2,ya1,yb1,gsres)

  ; -------------------------------
  ; Define a polygon for std-dev
  ; -------------------------------
   ya1    = new( (/2*dimsizes(yfrac2)/), float )
   yb1    = new( (/2*dimsizes(yfrac2)/), float )
   do k=0,dimsizes(yfrac2)-1
     ya1(k) = yfrac2(k)
     yb1(k) = emiss3_weekly_avg(7,k)
     yb1(2*dimsizes(yfrac2)-1-k) = emiss3_weekly_avg(6,k)
     ya1(2*dimsizes(yfrac2)-1-k) = yfrac2(k)
   end do             
    dum3b = gsn_add_polygon(wks,plot3,ya1,yb1,gsres)


  ; -------------------------------
  ; Define a polygon for std-dev
  ; -------------------------------
   ya1    = new( (/2*dimsizes(yfrac2)/), float )
   yb1    = new( (/2*dimsizes(yfrac2)/), float )
   do k=0,dimsizes(yfrac2)-1
     ya1(k) = yfrac2(k)
     yb1(k) = emiss4_weekly_avg(7,k)
     yb1(2*dimsizes(yfrac2)-1-k) = emiss4_weekly_avg(6,k)
     ya1(2*dimsizes(yfrac2)-1-k) = yfrac2(k)
   end do           
    dum4b = gsn_add_polygon(wks,plot4,ya1,yb1,gsres)

  ; -------------------------------
  ; Define a polygon for std-dev
  ; -------------------------------
   ya1    = new( (/2*dimsizes(yfrac2)/), float )
   yb1    = new( (/2*dimsizes(yfrac2)/), float )
   do k=0,dimsizes(yfrac2)-1
     ya1(k) = yfrac2(k)
     yb1(k) = emiss5_weekly_avg(7,k)
     yb1(2*dimsizes(yfrac2)-1-k) = emiss5_weekly_avg(6,k)
     ya1(2*dimsizes(yfrac2)-1-k) = yfrac2(k)
   end do              
    dum5b = gsn_add_polygon(wks,plot5,ya1,yb1,gsres)

  ; -------------------------------
  ; Define a polygon for std-dev
  ; -------------------------------
   ya1    = new( (/2*dimsizes(yfrac2)/), float )
   yb1    = new( (/2*dimsizes(yfrac2)/), float )
   do k=0,dimsizes(yfrac2)-1
     ya1(k) = yfrac2(k)
     yb1(k) = emiss6_weekly_avg(7,k)
     yb1(2*dimsizes(yfrac2)-1-k) = emiss6_weekly_avg(6,k)
     ya1(2*dimsizes(yfrac2)-1-k) = yfrac2(k)
   end do            
    dum6b = gsn_add_polygon(wks,plot6,ya1,yb1,gsres)

  ; new base
  res@xyLineColors      := (/"gray35"/)          ; change line color
  res@xyExplicitLegendLabels   := "weekly qfed - all replaced"
  res@pmLegendDisplayMode        = "Always"        ; turn on legend
    res@pmLegendOrthogonalPosF   = -1.42
    res@pmLegendParallelPosF   = 0.46
  plot1b  = gsn_csm_xy(wks,yfrac2,emiss1_weekly_avg(5,:),res) ; create plot
  res@pmLegendDisplayMode      = "Never"        ; turn on legend
  plot2b  = gsn_csm_xy(wks,yfrac2,emiss2_weekly_avg(5,:),res) ; create plot
  plot3b  = gsn_csm_xy(wks,yfrac2,emiss3_weekly_avg(5,:),res) ; create plot
  plot4b  = gsn_csm_xy(wks,yfrac2,emiss4_weekly_avg(5,:),res) ; create plot
  plot5b  = gsn_csm_xy(wks,yfrac2,emiss5_weekly_avg(5,:),res) ; create plot
  plot6b  = gsn_csm_xy(wks,yfrac2,emiss6_weekly_avg(5,:),res) ; create plot

  overlay(plot1,plot1b)
  overlay(plot2,plot2b)
  overlay(plot3,plot3b)
  overlay(plot4,plot4b)
  overlay(plot5,plot5b)
  overlay(plot6,plot6b) 

end if

  panel_res                       = True
      panel_res@txString              = "BB emissions for "+ tracer + " " + ystart + " to " + yend
      panel_res@gsnPanelFigureStrings = (/emiss_in1@region, emiss_in2@region, emiss_in3@region, emiss_in4@region,emiss_in5@region,emiss_in6@region/)
      panel_res@gsnPanelFigureStringsJust = "TopLeft"

    gsn_panel(wks,(/plot1,plot2,plot3,plot4,plot5,plot6/),(/2,3/),panel_res)


end if


end
