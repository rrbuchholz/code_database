;================================================;
;  CAM_chem_output.ncl
;================================================;
;
;--------------------------------------------------
; This NCL code plots timeseries of CAM-chem output
;
;--- To use type:
;---             CAM_chem_output.ncl
;
;                                       rrb 20180627
;--------------------------------------------------
; ================================================;

begin

; =========================================
; USER DEFINED
; =========================================
  ;tracer = (/"CO", "O3", "CH2O", "ISOP", "PAN", "OH"/)
  tracer = (/"HPALD", "IEPOX", "ISOPOOH", "MPAN", "ISOP", "FSDS"/)
  ;tracer = (/"NOA", "ONITR", "HONITR", "TERPNIT", "NOY" , "ALKNIT"/)
  ;tracer = (/"ISOP", "MEG_ISOP", "T", "AODVIS", "H2O", "OH" /)
  ;tracer = (/"CO", "O3", "CH2O", "NOY", "PAN","ALKNIT"/)
  reso = "0.9x1.25"
  ystart = 2005
  yend = 2015
  
  PLOT = True
    plottype = "x11"
      plottype@wkWidth  = 1800
      plottype@wkHeight = 1800
      ;plottype@wkPaperWidthF  = 7.0 ;for pdf
      ;plottype@wkPaperHeightF = 20  ;for pdf
    plotname = "~/surf_ts_bteamSUM"

tcol = False
noanth = True

; =========================================
; SET UP
; =========================================

  ;order = (/"QFED x CO", "QFED x CO2", "QFED", "FINN"/)
  ; -------------------------------
  ; emission files
  ; -------------------------------
   top_dir = "/glade2/work/buchholz/CAM_chem_output/anth_v_noanth/"
   e_file_in = systemfunc ("ls "+top_dir+"anth/*COALA_*.nc")
   e_file_in_noanth = systemfunc ("ls "+top_dir+"noanth/*COALA_*.nc")

  ; -------------------------------
  ; data names (from ncl_filedump)
  ; here they specify different regions
  ; -------------------------------
   tgas           = tracer(0)

; ----------------------------------------
; Load data
; ----------------------------------------
print(e_file_in(0))

   fin = addfiles(e_file_in, "r")           ; read in
     ListSetType (fin, "cat")                 ; concatenate
     time_dummy  := fin[:]->time
       yfrac_dummy:= tofloat(cd_calendar(time_dummy,4))
       range_ind  := ind(yfrac_dummy.ge.ystart.and.yfrac_dummy.lt.yend)
       time = time_dummy(range_ind)
       yfrac = tofloat(cd_calendar(time,4))


     tracer_template     := fin[:]->$tgas$
       ;tracer_template = dummy_1(range_ind,:,:,:)
       lat = tracer_template&lat
       lon = tracer_template&lon
       lev = tracer_template&lev

     tracer_array = new((/dimsizes(tracer),dimsizes(time_dummy),dimsizes(lev),dimsizes(lat),dimsizes(lon)/), float)
        tracer_array(0,:,:,:,:)=tracer_template

    ; collect each tracer
    do i=1,dimsizes(tracer)-1
      tgas        := tracer(i)
      dummy_1     := fin[:]->$tgas$
      if (tgas.eq."MEG_ISOP".or.tgas.eq."FSDS".or.tgas.eq."AODVIS") then
        tracer_array(i,:,55,:,:) = dummy_1
      else
        tracer_array(i,:,:,:,:) = dummy_1
      end if
;printVarSummary(dummy_1)
    end do
;exit

    tracer_array!0 = "tracer"
printVarSummary(tracer_array)

    tracer_array_reorder_dummy = tracer_array(tracer|:,lev|:,lat|:,lon|:,time|:)  
    tracer_array_reorder = tracer_array_reorder_dummy(:,:,:,:,range_ind)

  if (noanth) then
     finII = addfiles(e_file_in_noanth, "r")           ; read in

     noanth_tracer_template     := finII[:]->$tgas$
     noanth_time_dummy  := finII[:]->time
       noanth_yfrac_dummy:= tofloat(cd_calendar(noanth_time_dummy,4))
       noanth_range_ind  := ind(noanth_yfrac_dummy.ge.ystart.and.noanth_yfrac_dummy.lt.yend)
       noanth_time = time_dummy(noanth_range_ind)
       noanth_yfrac = tofloat(cd_calendar(noanth_time,4))
     tracer_array_noanth = new((/dimsizes(tracer),dimsizes(noanth_time_dummy),dimsizes(lev),dimsizes(lat),dimsizes(lon)/), float)

    ; collect each tracer
    do i=0,dimsizes(tracer)-1
      tgas        := tracer(i)
      dummy_2     := finII[:]->$tgas$
      if (tgas.eq."MEG_ISOP".or.tgas.eq."FSDS".or.tgas.eq."AODVIS") then
        tracer_array_noanth(i,:,55,:,:) = dummy_2
      else
        tracer_array_noanth(i,:,:,:,:) = dummy_2
      end if
    end do

    tracer_array_noanth!0 = "tracer"
    noanth_tracer_array_reorder_dummy = tracer_array_noanth(tracer|:,lev|:,lat|:,lon|:,time|:)  
    noanth_tracer_array_reorder = noanth_tracer_array_reorder_dummy(:,:,:,:,noanth_range_ind)

  end if

; ----------------------------------------
; Choose December-March
; ----------------------------------------
   dates = tofloat(cd_calendar(time,0))
   yyyy = dates(:,0)
   mm = dates(:,1)
   ;ind_djfm = ind(mm.gt.0)
   ;ind_djfm = ind(mm.eq.12.or.mm.eq.1.or.mm.eq.2)
   ind_djfm = ind(mm.eq.12)
 tracer_array_selected = tracer_array_reorder(:,:,2:4,2:4,ind_djfm)  

printVarSummary(tracer_array_reorder)

; ----------------------------------------
; Summer average
; ----------------------------------------
   datesII = tofloat(cd_calendar(time_dummy,0))
   yyyyII = datesII(:,0)
   mmII = datesII(:,1)

  tracer_array_summer = new((/dimsizes(tracer),dimsizes(lev),dimsizes(lat),dimsizes(lon),yend-ystart/), float) 
  do n=ystart,yend-1
    ind_avg = ind(yyyyII.eq.n.and.(mmII.eq.1.or.mmII.eq.2).or.\
                   yyyyII.eq.(n-1).and.mmII.eq.12)
    tracer_array_summer(:,:,:,:,n-ystart) = dim_avg_n(tracer_array_reorder_dummy(:,:,:,:,ind_avg),4)  
  end do
  tracer_array_summer_selected = tracer_array_summer(:,:,2:4,2:4,:)

  copy_VarMeta(tracer_array_selected,tracer_array_summer_selected)
  ind_djfm := ind(mm.eq.6)
  tracer_array_selected := tracer_array_summer_selected

   if (noanth) then
   datesIII = tofloat(cd_calendar(noanth_time_dummy,0))
     yyyyIII = datesIII(:,0)
     mmIII = datesIII(:,1)
     noanth_tracer_array_summer = new((/dimsizes(tracer),dimsizes(lev),dimsizes(lat),dimsizes(lon),yend-ystart/), float) 
     do n=ystart,yend-1
       ind_avg = ind(yyyyIII.eq.n.and.(mmIII.eq.1.or.mmIII.eq.2).or.\
                   yyyyIII.eq.(n-1).and.mmIII.eq.12)
       noanth_tracer_array_summer(:,:,:,:,n-ystart) = dim_avg_n(noanth_tracer_array_reorder_dummy(:,:,:,:,ind_avg),4)  
     end do

     noanth_tracer_array_summer_selected = noanth_tracer_array_summer(:,:,2:4,2:4,:)
       noanth_tracer_array_summer_selected!0 = "tracer"
       noanth_tracer_array_summer_selected!1 = "lev"
       noanth_tracer_array_summer_selected!2 = "lat"
       noanth_tracer_array_summer_selected!3 = "lon"
       noanth_tracer_array_summer_selected&lev = tracer_array_selected&lev
       noanth_tracer_array_summer_selected&lat = tracer_array_selected&lat
       noanth_tracer_array_summer_selected&lon = tracer_array_selected&lon
       noanth_tracer_array_summer_selected!4 = "time"


    noanth_tracer_array_selected = noanth_tracer_array_summer_selected
   end if

print(lat)
print(lon)

;exit
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

    res@pmLegendDisplayMode      = "Always"        ; turn on legend
      res@lgPerimOn                = False           ; Turn off perimeter
      res@pmLegendWidthF           = 0.10            ; Change width and
      res@pmLegendHeightF          = 0.15             ; height of legend
      res@lgLabelFontHeightF       = 0.028
      res@pmLegendOrthogonalPosF   = -1.5

   ;res@tmXBMode         = "Explicit"
   ;res@tmXBValues       = (/2004.0,2008.0,2012.0/)
   ;res@tmXBLabels       = (/"2004","201406","201501"/)
   res@tmXBLabelFontHeightF = 0.030
   res@tmYLLabelFontHeightF = 0.030
   res@trXMinF          = 2004.5
   res@trXMaxF          = 2015.5
   res@trYMinF          = 0.
  ;--------------------------
  ; Set up markers
  ;--------------------------
   ;res@xyMarkLineModes  = (/"Markers", "Markers", "Markers"/)   ; choose which have markers
   res@xyMarkLineModes  = (/"MarkLines", "MarkLines", "MarkLines"/)   ; choose which have markers
   res@xyDashPatterns      = (/2,2,2/)
     filled_tri = NhlNewMarker(wks, "u", 34, 0.0, 0.0, 1.0, 1.0, 0.0)
     filled_tri2 = NhlNewMarker(wks, "u", 34, 0.0, 0.0, 1.0, 1.0, 180.0)
    res@xyMarkers           := (/filled_tri2,filled_tri2,filled_tri2/)               ; choose type of marker  
    ;res@xyMarkers           := (/16,16,16/)               ; choose type of marker  
    res@xyMarkerThicknessF  = 2.
    res@xyLineThicknessF    = 3.
    res@xyMarkerOpacityF    := (/0.55,0.55,0.55/)
    res@xyMarkerSizes       := (/0.035,0.035,0.035/)    ; Marker size (default 0.01)

  ;--------------------------
  ; Do the plotting
  ;--------------------------
   res@tiYAxisString            = "Surface vmr ppb"
  ; month
  ; Tracer1
   res@trYMaxF          = max((tracer_array_selected(0,55,:,:,:)/1e-09))+0.05
     ;res@trYMinF          = 40.
   res@xyMarkerColors       := (/"orange","red","red4"/)          ; change marker color
   res@xyLineColors         := (/"orange","red","red4"/)          ; change line color
   res@pmLegendParallelPosF   = 0.95
   res@xyExplicitLegendLabels   = "lat:"+sprintf("%4.2g",tracer_array_selected&lat)+" lon:"+sprintf("%4.3g",lon(4))
  plot1  = gsn_csm_xy(wks,yfrac(ind_djfm),tracer_array_selected(0,55,:,2,:)/1e-09,res) ; create plot
   res@xyMarkerColors       := (/"forestgreen","yellowgreen","yellow"/)          ; change line color
   res@xyLineColors         := (/"forestgreen","yellowgreen","yellow"/)          ; change line color
   res@pmLegendParallelPosF   = 0.525
   res@xyExplicitLegendLabels   = "lat:"+sprintf("%4.2g",tracer_array_selected&lat)+" lon:"+sprintf("%4.3g",lon(3))
  plot1a  = gsn_csm_xy(wks,yfrac(ind_djfm),tracer_array_selected(0,55,:,1,:)/1e-09,res) ; create plot
   res@xyMarkerColors       := (/"cyan","blue","mediumpurple4"/)           ; change line color
   res@xyLineColors         := (/"cyan","blue","mediumpurple4"/)          ; change line color
   res@xyExplicitLegendLabels   = "lat:"+sprintf("%4.2g",tracer_array_selected&lat)+" lon:"+sprintf("%4.3g",lon(2))
   res@pmLegendParallelPosF   = 0.1
  plot1b  = gsn_csm_xy(wks,yfrac(ind_djfm),tracer_array_selected(0,55,:,0,:)/1e-09,res) ; create plot
  overlay(plot1,plot1a)
  overlay(plot1,plot1b)
printVarSummary(tracer_array_selected)

  res@pmLegendDisplayMode      = "Never"        ; turn on legend
     ;res@trYMinF          = 22.
  ; Tracer2
  res@trYMaxF          = max(tracer_array_selected(1,55,:,:,:)/1e-09)+0.005
   res@xyMarkerColors       := (/"orange","red","red4"/)          ; change line color
   res@xyLineColors         := (/"orange","red","red4"/)          ; change line color
  plot2  = gsn_csm_xy(wks,yfrac(ind_djfm),tracer_array_selected(1,55,:,2,:)/1e-09,res) ; create plot
   res@xyMarkerColors       := (/"forestgreen","yellowgreen","yellow"/)          ; change line color
   res@xyLineColors         := (/"forestgreen","yellowgreen","yellow"/)          ; change line color
  plot2a  = gsn_csm_xy(wks,yfrac(ind_djfm),tracer_array_selected(1,55,:,1,:)/1e-09,res) ; create plot
    res@xyMarkerColors       := (/"cyan","blue","mediumpurple4"/)          ; change line color
   res@xyLineColors         := (/"cyan","blue","mediumpurple4"/)          ; change line color
  plot2b  = gsn_csm_xy(wks,yfrac(ind_djfm),tracer_array_selected(1,55,:,0,:)/1e-09,res) ; create plot
  overlay(plot2,plot2a)
  overlay(plot2,plot2b)

  ; Tracer3
   ;res@tiYAxisString            = "Surface K"
     res@trYMaxF          = max((tracer_array_selected(2,55,:,:,:)/1e-09))+0.08
     res@trYMinF          = 0.
   res@xyMarkerColors       := (/"orange","red","red4"/)          ; change line color
   res@xyLineColors         := (/"orange","red","red4"/)          ; change line color
  plot3  = gsn_csm_xy(wks,yfrac(ind_djfm),tracer_array_selected(2,55,:,2,:)/1e-09,res) ; create plot
   res@xyMarkerColors       := (/"forestgreen","yellowgreen","yellow"/)          ; change line color
   res@xyLineColors         := (/"forestgreen","yellowgreen","yellow"/)          ; change line color
  plot3a  = gsn_csm_xy(wks,yfrac(ind_djfm),tracer_array_selected(2,55,:,1,:)/1e-09,res) ; create plot
   res@xyMarkerColors       := (/"cyan","blue","mediumpurple4"/)         ; change line color
   res@xyLineColors         := (/"cyan","blue","mediumpurple4"/)          ; change line color
  plot3b  = gsn_csm_xy(wks,yfrac(ind_djfm),tracer_array_selected(2,55,:,0,:)/1e-09,res) ; create plot
  overlay(plot3,plot3a)
  overlay(plot3,plot3b)


  ; Tracer4
   ;res@tiYAxisString            = "AOD"
     res@trYMinF          = 0.
     res@trYMaxF          = max(tracer_array_selected(3,55,:,:,:)/1e-09)
   res@xyMarkerColors       := (/"orange","red","red4"/)          ; change line color
   res@xyLineColors         := (/"orange","red","red4"/)          ; change line color
  plot4  = gsn_csm_xy(wks,yfrac(ind_djfm),tracer_array_selected(3,55,:,2,:)/1e-09,res) ; create plot
   res@xyMarkerColors       := (/"forestgreen","yellowgreen","yellow"/)          ; change line color
   res@xyLineColors         := (/"forestgreen","yellowgreen","yellow"/)          ; change line color
  plot4a  = gsn_csm_xy(wks,yfrac(ind_djfm),tracer_array_selected(3,55,:,1,:)/1e-09,res) ; create plot
   res@xyMarkerColors       := (/"cyan","blue","mediumpurple4"/)          ; change line color
   res@xyLineColors         := (/"cyan","blue","mediumpurple4"/)          ; change line color
  plot4b  = gsn_csm_xy(wks,yfrac(ind_djfm),tracer_array_selected(3,55,:,0,:)/1e-09,res) ; create plot
  overlay(plot4,plot4a)
  overlay(plot4,plot4b)


  ; Tracer5
  ; res@tiYAxisString            = "Surface vmr mol/mol"
  ;   res@trYMinF          = 0.008
     res@trYMaxF          = max(tracer_array_selected(4,55,:,:,:)/1e-09)+4
   res@xyMarkerColors       := (/"orange","red","red4"/)          ; change line color
   res@xyLineColors         := (/"orange","red","red4"/)          ; change line color
  plot5  = gsn_csm_xy(wks,yfrac(ind_djfm),tracer_array_selected(4,55,:,2,:)/1e-09,res) ; create plot
    res@xyMarkerColors       := (/"forestgreen","yellowgreen","yellow"/)          ; change line color
   res@xyLineColors         := (/"forestgreen","yellowgreen","yellow"/)          ; change line color
  plot5a  = gsn_csm_xy(wks,yfrac(ind_djfm),tracer_array_selected(4,55,:,1,:)/1e-09,res) ; create plot
  res@xyMarkerColors       := (/"cyan","blue","mediumpurple4"/)          ; change line color
   res@xyLineColors         := (/"cyan","blue","mediumpurple4"/)          ; change line color
  plot5b  = gsn_csm_xy(wks,yfrac(ind_djfm),tracer_array_selected(4,55,:,0,:)/1e-09,res) ; create plot
  overlay(plot5,plot5a)
  overlay(plot5,plot5b)

   ;res@tiYAxisString            = "Surface vmr ppt"
   res@tiYAxisString            = "Flux W/m2"
     res@trYMinF          = 240.
  ; Tracer6
     ;res@trYMinF          = 1.
     res@trYMaxF          = max(tracer_array_selected(5,55,:,:,:))+5
   res@xyMarkerColors       := (/"orange","red","red4"/)          ; change line color
   res@xyLineColors         := (/"orange","red","red4"/)          ; change line color
  plot6  = gsn_csm_xy(wks,yfrac(ind_djfm),tracer_array_selected(5,55,:,2,:),res) ; create plot
   res@xyMarkerColors       := (/"forestgreen","yellowgreen","yellow"/)          ; change line color
   res@xyLineColors         := (/"forestgreen","yellowgreen","yellow"/)          ; change line color
  plot6a  = gsn_csm_xy(wks,yfrac(ind_djfm),tracer_array_selected(5,55,:,1,:),res) ; create plot
   res@xyMarkerColors       := (/"cyan","blue","mediumpurple4"/)          ; change line color
   res@xyLineColors         := (/"cyan","blue","mediumpurple4"/)          ; change line color
  plot6b  = gsn_csm_xy(wks,yfrac(ind_djfm),tracer_array_selected(5,55,:,0,:),res) ; create plot
  overlay(plot6,plot6a)
  overlay(plot6,plot6b)

; add in NoAnth
   if (noanth) then
    res@xyMarkers           := (/16,16,16/)               ; choose type of marker  
    res@xyMarkerSizes       := (/0.015,0.015,0.015/)    ; Marker size (default 0.01)
    res@xyMarkerColors      := (/"black","gray70","gray45"/)          ; change line color
    res@xyLineColors        := (/"black","gray70","gray45"/)          ; change line color
    res@xyDashPatterns      = (/0,0,0/)
    plot1_na  = gsn_csm_xy(wks,noanth_yfrac(ind_djfm),noanth_tracer_array_selected(0,55,:,2,:)/1e-09,res) ; create plot
    overlay(plot1,plot1_na)

  res@pmLegendDisplayMode      = "Always"        ; turn on legend
   res@xyExplicitLegendLabels   = "lat:"+sprintf("%4.2g",tracer_array_selected&lat)+" lon:"+sprintf("%4.3g",lon(4))+ " No anth."
    plot2_na  = gsn_csm_xy(wks,noanth_yfrac(ind_djfm),noanth_tracer_array_selected(1,55,:,2,:)/1e-09,res) ; create plot
    overlay(plot2,plot2_na)

  res@pmLegendDisplayMode      = "Never"        ; turn on legend
    plot3_na  = gsn_csm_xy(wks,noanth_yfrac(ind_djfm),noanth_tracer_array_selected(2,55,:,2,:)/1e-09,res) ; create plot
    overlay(plot3,plot3_na)

    plot4_na  = gsn_csm_xy(wks,noanth_yfrac(ind_djfm),noanth_tracer_array_selected(3,55,:,2,:)/1e-09,res) ; create plot
    overlay(plot4,plot4_na)

    plot5_na  = gsn_csm_xy(wks,noanth_yfrac(ind_djfm),noanth_tracer_array_selected(4,55,:,2,:)/1e-09,res) ; create plot
    overlay(plot5,plot5_na)

    plot6_na  = gsn_csm_xy(wks,noanth_yfrac(ind_djfm),noanth_tracer_array_selected(5,55,:,2,:),res) ; create plot
    overlay(plot6,plot6_na)

   end if


  panel_res                       = True
      panel_res@txString              = "DJF timeseries " + ystart + " to 2014"
      panel_res@gsnPanelFigureStrings = tracer
      panel_res@gsnPanelFigureStringsJust = "TopLeft"

    gsn_panel(wks,(/plot1,plot2,plot3,plot4,plot5,plot6/),(/2,3/),panel_res)


end if


end
