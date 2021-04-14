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
    plottype = "x11"
      plottype@wkWidth  = 1800
      plottype@wkHeight = 1800
      ;plottype@wkPaperWidthF  = 7.0 ;for pdf
      ;plottype@wkPaperHeightF = 20  ;for pdf
    plotname = "~/BB_tcol_all_corr"

uncert1 = False
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
   e_file_in = (/ top_dir + "cmip_smoothed_CO_regional_2014.nc",\
                  top_dir + "finn_smoothed_CO_regional_2014.nc",\
                  top_dir + "gfas_smoothed_CO_regional_2014.nc",\
                  top_dir + "qfedCO_smoothed_CO_regional_2014.nc",\
                  top_dir + "qfedBB_32L_smoothed_CO_regional_2014.nc",\
                  top_dir + "qfedBBmin_32L_smoothed_CO_regional_2014.nc",\
                  top_dir + "qfedBBmax_32L_smoothed_CO_regional_2014.nc"/)

;qfedBB_32L_smoothed_CO_regional_2014.nc
;qfedBBmax_32L_smoothed_CO_regional_2014.nc
;qfedBBmin_32L_smoothed_CO_regional_2014.nc
;qfedCO_smoothed_CO_regional_2014.nc
;cmip_smoothed_CO_regional_2014.nc
;finn_smoothed_CO_regional_2014.nc
;gfas_smoothed_CO_regional_2014.nc



print(e_file_in)

; ----------------------------------------
; Load data
; ----------------------------------------
    fin = addfiles(e_file_in, "r")
    ListSetType (fin, "join") 
      time_dummy := fin[:]->time
          yfrac_dummy:= tofloat(cd_calendar(time_dummy(0,:),4))
          range_ind  := ind(yfrac_dummy.ge.ystart.and.yfrac_dummy.le.yend)
          time = time_dummy(0,range_ind)
          yfrac = tofloat(cd_calendar(time,4))
      vNames = getfilevarnames (fin[0])

      tracer_array_total = new((/dimsizes(vNames)-2, dimsizes(e_file_in), dimsizes(time)/), float)
      region_names = new((/dimsizes(vNames)-2/), string)


    do i = 2, dimsizes(vNames)-1
      print("Collecting "+vNames(i))
      tracer_dummy = fin[:]->$vNames(i)$
      region_names(i-2) = tracer_dummy@region
      tracer_array_total(i-2,:,:) = tracer_dummy
    end do

      tracer_array = tracer_array_total(0:dimsizes(vNames)-4:2,:,:)
      meas_array = tracer_array_total(1:dimsizes(vNames)-3:2,:,:)
      ;print(region_names)
      ;printVarSummary(tracer_array_total)
      printVarSummary(meas_array)
      printVarSummary(tracer_array)
      ;print(tracer_array_total(0,0,:))
      ;print(tracer_array_total(1,0,:))
      ;print(tracer_array_total(2,0,:))
      ;print(meas_array(0,0,:))
      ;print(tracer_array(0,0,:))


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
   res@vpHeightF        = 0.8

   res@trYMaxF          = 2.8
   res@trYMinF          = 0.3
   res@trXMaxF          = 2.8
   res@trXMinF          = 0.3


   res@tiYAxisString            = "Model Column (x 10~S2~18   molec cm~S2~-2  )"
   res@tiXAxisString            = "MOPITT Column (x 10~S2~18   molec cm~S2~-2  )"

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
   res@pmLegendDisplayMode      = "Never"        ; turn on legend
  ;--------------------------
  ; Do the plotting
  ;--------------------------
   plot_array = new(dimsizes(region_names)/2,"graphic")
   corr_array = new(dimsizes(region_names)/2,"graphic")

   ; 1-1 plot
   res@xyMarkLineModes := (/"Lines"/)   ; choose which have markers
   res@xyLineThicknessF = 10.0
   res@xyLineColors    := (/"grey","mediumpurple4","darkgreen","red4"/)  ; Marker color
   do s = 0, (dimsizes(region_names)/2)-1
     plot_array(s)  = gsn_csm_xy(wks,(/0,5/),(/0,5/),res) ; create plot
   end do

   res@xyMarkLineModes  := (/"Markers", "Markers", "Markers", "Markers", "Markers", "Markers", "Markers"/)   ; choose which have markers
    res@xyMarkers           := (/16,16,16,16,16,16,16/)               ; choose type of marker  
    res@xyMarkerColors      := (/"black","blue","darkgreen","red4","gray20"/)  ; Marker color
    res@xyMarkerThicknessF  = 12
    res@xyMarkerOpacityF    := (/0.85,0.85,0.85,0.85,0.85/)
    res@xyMarkerSizes       := (/0.012,0.012,0.012,0.012,0.012/)    ; Marker size (default 0.01)

  ; correlation plot

   res@xyExplicitLegendLabels   = "daily " + order
   res@pmLegendOrthogonalPosF   = -1.8
   ;res@trYMaxF          = 2.1

   do s = 0, (dimsizes(region_names)/2)-1
     corr_array(s)  = gsn_csm_xy(wks,meas_array(s,0:4,:)/1e18,tracer_array(s,0:4,:)/1e18,res) ; create plot
     overlay(plot_array(s), corr_array(s))
   end do


   do t = 0, (dimsizes(region_names)/2)-1

    if (uncert1) then
      ; -------------------------------
      ; Define a polygon for std-dev
      ; -------------------------------
       ya1    = new( (/2*dimsizes(yfrac2)/), float )
       yb1    = new( (/2*dimsizes(yfrac2)/), float )
       do k=0,dimsizes(yfrac2)-1
         ya1(k) = meas_array(k,0,:)/1e18
         yb1(k) = tracer_array_weekly_avg(t,4,k)/1e18
         yb1(2*dimsizes(yfrac2)-1-k) = tracer_array_weekly_avg(t,5,k)/1e18
         ya1(2*dimsizes(yfrac2)-1-k) = meas_array(k,0,:)/1e18
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

   gsres = True                                          ; add x error bars
   gsres@gsLineColor      = "gray40"
   gsres@gsLineThicknessF = 8.0
    res@xyMarkerThicknessF  = 8
    res@xyMarkerOpacityF    := (/0.8/)
    res@xyMarkerSizes       := (/0.008/)

       do k=0,dimsizes(time)-1
         xpoints = (/meas_array(t,4,k)/1e18, meas_array(t,4,k)/1e18/)
         ypoints = (/ tracer_array(t,5,k)/1e18, tracer_array(t,6,k)/1e18/)
         error_bar2 = gsn_add_polyline(wks, plot_array(t), xpoints, ypoints, gsres )
         str2 = unique_string("error_bar2")
         dummy2_plot := plot_array(t)
         dummy2_plot@$str2$ = error_bar2
         plot_array(t) = dummy2_plot
      end do

    end if
   end do



  panel_res                       = True
      panel_res@txString              = "Column "+ tracer + " for " + ystart
      panel_res@gsnPanelFigureStrings = region_names(0:dimsizes(region_names)-1:2)
      panel_res@gsnPanelFigureStringsFontHeightF = 0.008
      panel_res@gsnPanelFigureStringsJust = "TopLeft"
      panel_res@gsnMaximize = True
      panel_res@gsnPanelBottom = 0.045 

    ;gsn_panel(wks,plot_array,(/3,5/),panel_res)  ; plots


  draw(plot_array(2))
  frame(wks)

end if


end
