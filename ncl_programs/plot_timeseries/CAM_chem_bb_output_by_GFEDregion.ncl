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
  order = (/ "cmip"/)
  ; -------------------------------
  ; emission files
  ; -------------------------------
   top_dir = "/net/modeling1/data16a/buchholz/CAM_chem_output/EF_processed/"
   e_file_in = (/ top_dir + "cmip_CO_regional_2014.nc",\
                  top_dir + "cmip.finnBBCO_CO_regional_2014.nc",\
                  top_dir + "cmip.gfasBBCO_CO_regional_2014.nc",\
                  top_dir + "cmip.qfedBBCO_CO_regional_2014.nc",\
                  top_dir + "cmip.qfedBBCOmin_CO_regional_2014.nc",\
                  top_dir + "cmip.qfedBBCOmax_CO_regional_2014.nc",\ 
                  top_dir + "cmip.qfedBB_32L_CO_regional_2014.nc",\
                  top_dir + "cmip.qfedBBminCO_32L_CO_regional_2014.nc",\
                  top_dir + "cmip.qfedBBmaxCO_32L_CO_regional_2014.nc",\
                  top_dir + "cmip.qfedBBmin_32L_CO_regional_2014.nc",\
                  top_dir + "cmip.qfedBBmax_32L_CO_regional_2014.nc"/)

print(e_file_in)


; ----------------------------------------
; Load data
; ----------------------------------------
    fin = addfiles(e_file_in, "r")
    ListSetType (fin, "join") 
      time_dummy := fin[:]->time
          yfrac_dummy:= tofloat(cd_calendar(time_dummy(0,:),4))
          range_ind  := ind(yfrac_dummy.ge.ystart.and.yfrac_dummy.lt.yend)
          time = time_dummy(0,range_ind)
          yfrac = tofloat(cd_calendar(time,4))
      vNames = getfilevarnames (fin[0])

      tracer_array = new((/dimsizes(vNames)-2, dimsizes(e_file_in), dimsizes(time)/), float)
      region_names = new((/dimsizes(vNames)-2/), string)


    do i = 2, dimsizes(vNames)-1
      print("Collecting "+vNames(i))
      tracer_dummy = fin[:]->$vNames(i)$
      region_names(i-2) = tracer_dummy@region
      tracer_array(i-2,:,:) = tracer_dummy
    end do

      print(region_names)
      printVarSummary(tracer_array)

; ----------------------------------------
; Calculate week averages
; ----------------------------------------
;*************** Change to use global utility*************
 dims  = dimsizes(tracer_array)
 ntime = dims(2)
 nfiles = dims(1)
 nregions = dims(0)

 days_per_week = 7
 nweeks = ntime / days_per_week

 time_cut = time(0:(days_per_week*nweeks)-1)
print(time_cut)
 tracer_array_cut = tracer_array(:,:,0:(days_per_week*nweeks)-1)

; Reshape into nregions x number of weeks x 7 days
 time_reshape = reshape(time_cut,(/nweeks,days_per_week/))
 tracer_array_4d  = reshape(tracer_array_cut,(/nregions,nfiles,nweeks,days_per_week/))
printVarSummary(tracer_array_4d)

; average across the "week" dimension
 time_weekly_avg = dim_avg_n(time_reshape,1)
   time_weekly_avg@units = time@units
 yfrac2 = tofloat(cd_calendar(time_weekly_avg,4))

 tracer_array_weekly_avg = dim_avg_n(tracer_array_4d,3)

printVarSummary(yfrac2)
printVarSummary(tracer_array_weekly_avg)

printVarSummary(tracer_array)
yyyymm = cd_calendar(time,1)
split_time = str_split_by_length(tostring(yyyymm), 4)
month_val = toint(split_time(:,1))
ind_select = ind(month_val.ge.7.and.month_val.le.9)
rel_diff = dim_avg_n((tracer_array(:,0,ind_select)-tracer_array(:,6,ind_select))/tracer_array(:,6,ind_select),1)
print(region_names + ": " +rel_diff)


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
   res@gsnMaximize = True

   res@vpWidthF         = 0.8
   res@vpHeightF        = 0.5

   res@tiYAxisString            = "Total Column (x 10~S2~18   molec cm~S2~-2  )"

    res@pmLegendDisplayMode      = "Always"        ; turn on legend
      res@lgPerimOn                = False           ; Turn off perimeter
      res@pmLegendWidthF           = 0.15            ; Change width and
      res@pmLegendHeightF          = 0.08             ; height of legend
      res@lgLabelFontHeightF       = 0.032
      res@pmLegendOrthogonalPosF   = -1.1
      res@pmLegendParallelPosF     = 0.3

   ;res@tmXBMode         = "Explicit"
   ;res@tmXBValues       = (/2014.,2014.5,2015./)
   ;res@tmXBLabels       = (/"201401","201406","201501"/)
   ;res@tmXBLabelFontHeightF = 0.030
   ;res@tmYLLabelFontHeightF = 0.030

  ;--------------------------
  ; Do the plotting
  ;--------------------------
   res@xyMarkLineModes  = (/"Markers", "Markers", "Markers", "Markers", "Markers", "Markers", "Markers"/)   ; choose which have markers
    res@xyMarkers           := (/0,1,2,3,4,5,6/)               ; choose type of marker  
    res@xyMarkerColors      := (/"black","mediumpurple4","darkgreen","red4"/)  ; Marker color
    res@xyMarkerThicknessF  = 2
    res@xyMarkerOpacityF    := (/0.25,0.25,0.25/)
    res@xyMarkerSizes       := (/0.008,0.010,0.008,0.008/)    ; Marker size (default 0.01)


  ; daily
   res@pmLegendDisplayMode      = "Never"        ; turn on legend
   res@xyExplicitLegendLabels   = "daily " + order
   res@pmLegendOrthogonalPosF   = -1.8
   ;res@trYMaxF          = 2.1
   plot_array = new(dimsizes(region_names),"graphic")
   do s = 0, dimsizes(region_names)-1
     plot_array(s)  = gsn_csm_xy(wks,yfrac,tracer_array(s,0:3,:)/1e18,res) ; create plot
   end do

  ; weekly
   res@xyMarkLineModes  := "Lines"                               ; choose which have markers
    res@xyLineThicknessF  = 10
   res@xyDashPatterns      = (/0,16,14,3/)
   res@xyLineThicknesses = (/12.0, 12.0, 12.0, 12.0/)                ; make second line thicker
   ;res@xyLineThicknesses = (/6.0, 6.0, 6.0, 6.0/)                ; make second line thicker
   res@xyLineColors      = (/"black","blue","forestgreen","red4","grey"/)          ; change line color
   res@pmLegendDisplayMode      = "Never"        ; turn on legend
   res@xyExplicitLegendLabels   = "weekly " + order
   res@pmLegendOrthogonalPosF   = -1.55

   plot_array_w = new(dimsizes(region_names),"graphic")
   do t = 0, dimsizes(region_names)-1
     plot_array_w(t)  = gsn_csm_xy(wks,yfrac2,tracer_array_weekly_avg(t,0:3,:)/1e18,res) ; create plot
     overlay(plot_array(t),plot_array_w(t))

   dum1a = new(dimsizes(region_names),"graphic")
    if (uncert1) then
      ; -------------------------------
      ; Define a polygon for std-dev
      ; -------------------------------
       ya1    = new( (/2*dimsizes(yfrac2)/), float )
       yb1    = new( (/2*dimsizes(yfrac2)/), float )
       do k=0,dimsizes(yfrac2)-1
         ya1(k) = yfrac2(k)
         yb1(k) = tracer_array_weekly_avg(t,4,k)/1e18
         yb1(2*dimsizes(yfrac2)-1-k) = tracer_array_weekly_avg(t,5,k)/1e18
         ya1(2*dimsizes(yfrac2)-1-k) = yfrac2(k)
       end do
        gsres                          = True                ; poly res
        gsres@gsFillColor            = "red"                ; color chosen
        gsres@gsFillOpacityF         = 0.3                 

        error_bar = gsn_add_polygon(wks,plot_array(t),ya1,yb1,gsres)
        str1 = unique_string("error_bar")
        dummy_plot := plot_array(t)
        dummy_plot@$str1$ = error_bar  
        plot_array(t) = dummy_plot
    end if

   plot_array_v = new(dimsizes(region_names),"graphic")
    if (uncert2) then 
      ; -------------------------------
      ; Define a polygon for std-dev
      ; -------------------------------
       ya1    = new( (/2*dimsizes(yfrac2)/), float )
       yb1    = new( (/2*dimsizes(yfrac2)/), float )
       do k=0,dimsizes(yfrac2)-1
         ya1(k) = yfrac2(k)
         yb1(k) = tracer_array_weekly_avg(t,7,k)/1e18
         yb1(2*dimsizes(yfrac2)-1-k) = tracer_array_weekly_avg(t,8,k)/1e18
         ya1(2*dimsizes(yfrac2)-1-k) = yfrac2(k)
       end do
      
       ya2    = new( (/2*dimsizes(yfrac2)/), float )
       yb2    = new( (/2*dimsizes(yfrac2)/), float )
       do k=0,dimsizes(yfrac2)-1
         ya2(k) = yfrac2(k)
         yb2(k) = tracer_array_weekly_avg(t,9,k)/1e18
         yb2(2*dimsizes(yfrac2)-1-k) = tracer_array_weekly_avg(t,10,k)/1e18
         ya2(2*dimsizes(yfrac2)-1-k) = yfrac2(k)
       end do          

      ; new base
      resVOC=res
      resVOC@xyLineColors      := (/"gray35"/)          ; change line color
      resVOC@xyExplicitLegendLabels   := "weekly qfed - all replaced"
      resVOC@pmLegendDisplayMode        = "Never"        ; turn on legend
        resVOC@pmLegendOrthogonalPosF   = -1.42
        resVOC@pmLegendParallelPosF   = 0.46
      plot_array_v(t)  = gsn_csm_xy(wks,yfrac2,tracer_array_weekly_avg(t,6,:)/1e18,resVOC) ; create plot

        gsres                          = True                ; poly res
        gsres@gsFillColor            = "gray10"                ; color chosen
        gsres@gsFillOpacityF         = 0.4   
        error_bar2 = gsn_add_polygon(wks,plot_array_v(t),ya1,yb1,gsres)

        gsres                          = True                ; poly res
        gsres@gsFillColor            = "gray50"                ; color chosen
        gsres@gsFillOpacityF         = 0.4   
        error_bar3 = gsn_add_polygon(wks,plot_array_v(t),ya2,yb2,gsres)

        ;str2 = unique_string("err2")
        str3 = unique_string("err3")
        dummy2_plot := plot_array(t)
        ;dummy2_plot@$str2$ = error_bar2  
        dummy2_plot@$str3$ = error_bar3 

        plot_array(t) = dummy2_plot

      overlay(plot_array(t),plot_array_v(t))

    end if
   end do


  panel_res                       = True
      panel_res@txString              = "Column "+ tracer + " for " + ystart
      panel_res@gsnPanelFigureStrings = region_names
      panel_res@gsnPanelFigureStringsFontHeightF = 0.008
      panel_res@gsnPanelFigureStringsJust = "TopLeft"
      panel_res@gsnMaximize = True
      panel_res@gsnPanelBottom = 0.045 

    ;gsn_panel(wks,plot_array,(/4,4/),panel_res)  ; plots

  draw(plot_array(2))
  frame(wks)

end if


end
