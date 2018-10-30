;============================================
; apply_AK_model.ncl
;============================================
;
; Concepts Illustrated
;          - Open model files
;          - Load AK and a priori
;          - Convolve the model with AK and AP
;          - plot profile
;          - plot timeseries
;          - write out to netCDF
;
; To use type on the command line:
;          > ncl apply_AK_model.ncl
;                            RRB Oct 17, 2018
;============================================

begin

;--------------------------------------------
; user input
;--------------------------------------------
  loc = "wollongong"
  model_dir = "/IASI/home/buchholz/CAM_chem/stations/"
  model_file = "CAM_Chem_DWLstations2001.nc"

  meas_dir = "/IASI/home/buchholz/MOPITT_subset/V7/stations/"
  meas_file = "Wollongong_1deg_V7J_20010101-20170101.nc"


  ;fts_files =  systemfunc ("ls /IASI/home/buchholz/FTS_data/NDACC/co/"+loc2+"/groundbased_ftir.co_*.hdf")
 ; version = "V6T"
 ; loc = "Toronto"
 ; mopitt_binned = "Lauder_1deg_MOPITTpixels.nc"
 ; mopitt_general     = "/IASI/home/buchholz/MOPITT_subset/pixelbinning/"+loc+"/"+loc+"_1deg_"+version+"MOPITTavg_"
 ; mopitt_binned      = mopitt_general+"all.nc"

  ;------------
  ; toggles
  ;------------
  PLOT           = False
    plotType      = "x11"
    plotName      = "test"
   ; -------------------------------
   ; Plotting
   ; -------------------------------
     titlestring          = "Applying Averaging Kernels at Lauder, 2010"
     ymax                 = 2e18
     ymin                 = 0.5e18
     xmax                 = 2e18
     xmin                 = 0.5e18

  PLOTPROFILE     = False
    plot2Type      = "x11"
    plot2Name      = "profile-plot"
;--------------------------------------------
; end user input
;--------------------------------------------
;
;--------------------------------------------
; set up
;--------------------------------------------

  if (PLOT) then
    pltdir       = "./"
    pltname      = "test_" + location
  end if

  ; -------------------------------
  ; FTS
  ; -------------------------------
  ; names of data structures
  ; determined from an ncl_filedump
  model_tracer         = "COMixingRatioProfile"

  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  ; names of data structures
  ; determined from an ncl_filedump
  timearray     = "Time"
  sat_ap        = "APrioriCOMixingRatioProfile"
  sat_ak        = "RetrievalAvKerMatrix"

  counter = 0
  pvect = (/900.,800.,700.,600.,500.,400.,300.,200.,100./)

                                             ; CONSTANTS
   NAv    = 6.0221415e+23                    ;--- Avogadro's number
   g      = 9.81                             ;--- m/s - gravity
   H = (8.314*240)/(0.0289751*9.8)           ;--- scale height
   MWair = 28.94                             ;--- g/mol
   xp_const = (NAv* 10)/(MWair*g)*1.0e-09    ;--- scaling factor for turning vmr into pcol
                                             ;--- (note 1*e-09 because in ppb)

;--------------------------------------------
; load file and extract
;--------------------------------------------
mopitt_in = addfile(meas_dir+meas_file, "r")
    time         = mopitt_in->$timearray$
   ; Date is in seconds since 1993-1-1 00:00:00
    meas_date  = cd_calendar(time, 2)
;    psurf        = mopitt_in->$sat_psurf$
    apriori      = mopitt_in->$sat_ap$
    AvKer        = mopitt_in->$sat_ak$
    meas_press = (/1000, 900,800,700,600,500,400,300,200,100/); add in floating surface pressure

model_in = addfile(model_dir+model_file, "r")
;model_in = addfiles (fts_files, "r")
  ;ListSetType (fts_in, "cat")             ; concatenate or "merge" (default)

  mod_prof            = model_in->$model_tracer$
  test = mod_prof@locations  ; need to split up sgtring by comma
  mod_press = mod_prof&lev  ;need to convert to true pressure

  loc_prof = mod_prof(:,:,1)
  loc_prof@locations = "Wollongong"
  mod_time = loc_prof&time
  mod_date  = cd_calendar(mod_time, 2)

  mod_interp = int2p_n_Wrap(mod_press,loc_prof,meas_press,1,1)

printVarSummary(mod_interp)
;print(mod_date)
exit

  ; Date in MJD2000, fraction of days since 
  ; Jan 1st, 2000, 00:00:00
  fts_mjd2000         = fts_in[:]->$fts_datetime$
  fts_local           = fts_mjd2000+(time_diff/24.)
    fts_local@units   = "days since 2000-01-01 00:00:0.0"
  fts_date            = cd_calendar(fts_local, 0)
  fts_ppmv            = fts_in[:]->$fts_posterior$
  fts_prof            = fts_ppmv*1000           ; ppm to ppb
  fts_alt             = fts_in[:]->$fts_press$
  fts_AvKer           = fts_in[:]->$fts_ak$
  fts_levels          = fts_in[:]->$fts_edges$

;--------------------------------------------
; Set up MOPITT pressure arrays
;--------------------------------------------
  parray = new((/dimsizes(psurf), 10/), float)
  parray(:,0) = doubletofloat(psurf)
  do i=0,dimsizes(psurf)-1
    parray(i,1:9) = pvect
  end do

  ; FTS values are averages for the whole box, 
  ; centred at an altitude while MOPITT values are averages described for box above level.
  pinterp = new((/dimsizes(psurf), 10/), float)
  pinterp(:,0)= doubletofloat(psurf) - (doubletofloat(psurf)-900)/2
  pmids = (/850.,750.,650.,550.,450.,350.,250.,150.,87./)
  do i=0,dimsizes(psurf)-1
    pinterp(i,1:9) = pmids
  end do

  AvKer = where(ismissing(AvKer),0,AvKer)       ; missing values -> zero for array calculations
;--------------------------------------------
; build comparison array
;--------------------------------------------
do i=0,dimsizes(fts_tcol)-1

   ; collect MOPITT pixels and FTS for comparison
   mopitt_comp = ind(mopitt_date(:,0).eq.fts_date(i,0)\
                 .and.mopitt_date(:,1).eq.fts_date(i,1)\
                 .and.mopitt_date(:,2).eq.fts_date(i,2))

  if (any(.not.ismissing(mopitt_comp))) then
    do j=0,dimsizes(mopitt_comp)-1

      ;--------------------------------------------
      ; Interpolate FTS to MOPITT vertical levels
      ;--------------------------------------------
      ; note, interpolation automatically turns the fts profile upside down
      ; to align with MOPITT parray
      fts_interp = new((/10/), float)
      ; extrapolate
      ;fts_interp = int2p_n_Wrap(fts_alt(i,:),fts_prof(i,:),parray(mopitt_comp(j),:),-1,0)
      ;fts_interp = int2p_n_Wrap(fts_alt(i,:),fts_prof(i,:),pinterp(mopitt_comp(j),:),-1,0)
      ; no extrapolate
      fts_interp = int2p_n_Wrap(fts_alt(i,:),fts_prof(i,:),parray(mopitt_comp(j),:),1,0)

      ;--------------------------------------------
      ; Apply AK to FTS
      ; note AK applies to log(vmr) values
      ;--------------------------------------------
      logfts = log10(fts_interp)
      logap = log10(apriori(mopitt_comp,:))
      mopitt_pared = mopitt_prof(mopitt_comp(j),:)

      logfts_ak = new((/10/), float)
      print("Convolving with averaging kernel. . .") ; AK calculations
         ak = (/AvKer(mopitt_comp,:,:)/)
         ; missing values -> zero for array calculations
         ;ak  = where(ismissing(ak),0,ak)  
         logap  = where(ismissing(logfts),logap@_FillValue,logap)  
         mopitt_pared = where(ismissing(logfts),mopitt_pared@_FillValue,mopitt_pared)
         ;logfts  = where(ismissing(logfts),0,logfts)
         ; calculate
       do l =0,dimsizes(logfts)-1         
         logfts_ak(l) = logap(l) + sum((ak(:,l)) * (logfts - logap))
       end do
       print(". . . Done!")
       ; change zero back to missing values for plotting etc
       logfts_ak = where(logfts_ak.eq.0,logfts_ak@_FillValue, logfts_ak)
       ; change back to vmr
       fts_wmak = 10^logfts_ak


      ;--------------------------------------------
      ; Apply MOPITT AK to CAM-Chem a priori
      ; note AK applies to log(vmr) values
      ;--------------------------------------------
      ap = apriori(mopitt_comp(j),:)
      logap_ak = new((/10/), double)
      print("Convolving with averaging kernel. . .") ; AK calculations
         ak = (/AvKer(mopitt_comp(j),:,:)/)
         logap_ak = transpose(ak) # (logap)
         ;logfts_ak = logap + transpose(ak) # logfts - transpose(ak) # logap
     print(". . . Done!")
     ; change zero back to missing values for plotting etc
     logap_ak = where(logap_ak.eq.0,logap_ak@_FillValue, logap_ak)
     ; change zero back to vmr
     ap_ak = 10^logap_ak

      ;--------------------------------------------
      ; Apply FTS AK to CAM-Chem a priori
      ;--------------------------------------------
      ap_interp = int2p_n_Wrap(parray(mopitt_comp(j),:),ap,fts_alt(i,:),-1,0) ; note ap on edges
      ftsak  = (/fts_AvKer(i,:,:)/)
      ap_fts_ak = transpose(ftsak) # ap_interp
      ap_fts_ak_interp = int2p_n_Wrap(fts_alt(i,:),ap_fts_ak,parray(mopitt_comp(j),:),-1,0)

      ;--------------------------------------------
      ; Pressure difference array
      ;--------------------------------------------
      ; MOPITT pressures are level edges.
      ; see V5 User Guide for more info
      delta_p = new((/10/), double)
      delta_p(0) = parray(mopitt_comp(j),0) - parray(mopitt_comp(j),1)
      delta_p(1:8) = 100
      delta_p(9) = 74

      fts_levs = dimsizes(fts_alt(i,:))
      ; use mopitt surface pressure to convert level edges into pressures
      fts_levels_p = parray(mopitt_comp(j),0)*exp(-(fts_levels*1000)/H)

      delta_p_fts = new((/fts_levs/), double)
      do z=0,fts_levs-1
        delta_p_fts(z) = fts_levels_p(1,z)-fts_levels_p(0,z)
      end do


      ;--------------------------------------------
      ; Calculate total column
      ;--------------------------------------------
      xp_ap = new((/10/), double)
      xp_ap_ak = new((/10/), double)
      ;xp_ap_ftsak = new((/fts_levs/), double)
      xp_ap_ftsak = new((/10/), double)

      xp_ap= (xp_const * ap) * delta_p 
      ap_tcol = dim_sum(xp_ap) 

      xp_ap_ak= (xp_const * ap_ak) * delta_p 
      ap_tcol_ak = dim_sum(xp_ap_ak) 

      ;xp_ap_ftsak= (xp_const * ap_fts_ak) * delta_p_fts
      ;ap_tcol_ftsak = dim_sum(xp_ap_ftsak) 

      xp_ap_ftsak= (xp_const * ap_fts_ak_interp) * delta_p
      ap_tcol_ftsak = dim_sum(xp_ap_ftsak) 


     if (counter.eq.0) then
              mopitt_to_plot  = mopitt_tcol(mopitt_comp(j))
              fts_to_plot     = fts_tcol(i)
              ap_to_plot      = ap_tcol
              ap_ak_plot      = ap_tcol_ak
              ap_ftsak_plot   = ap_tcol_ftsak
              ;profiles
              ap_interp_plot  = ap_interp 
              ap_prof_ak      = ap_ak
              ap_prof_ftsak   = ap_fts_ak
              fts_prof_comp   = fts_prof(i,:)
              fts_prof_interp = fts_interp
              fts_prof_wak    = fts_wmak
              m_prof_pared    = mopitt_pared
              temp = counter
              delete(counter)
              counter = temp + 1
              delete(temp)
          else
              temp1 = mopitt_to_plot
              temp2 = fts_to_plot
              temp3 = ap_to_plot
              temp4 = ap_ak_plot
              temp5 = ap_ftsak_plot
              delete([/mopitt_to_plot, fts_to_plot, ap_to_plot, ap_ak_plot, ap_ftsak_plot/])
              mopitt_to_plot = array_append_record(temp1,mopitt_tcol(mopitt_comp(j)),0)
              fts_to_plot    = array_append_record(temp2,fts_tcol(i),0)
              ap_to_plot     = array_append_record(temp3,ap_tcol,0)
              ap_ak_plot     = array_append_record(temp4,ap_tcol_ak,0)
              ap_ftsak_plot  = array_append_record(temp5,ap_tcol_ftsak,0)
              delete([/temp1, temp2, temp3, temp4, temp5/])
       end if  
     end do        
   end if
   delete(mopitt_comp)
end do

;--------------------------------------------
; Calculate correlation coefficients
;--------------------------------------------
cval1 = escorc(ap_to_plot, ap_ak_plot)
rc1   = regline(ap_to_plot, ap_ak_plot) 
print(cval1)
print(rc1)

cval2 = escorc(ap_to_plot, ap_ftsak_plot) 
rc2   = regline(ap_to_plot, ap_ftsak_plot)
print(cval2)
print(rc2)

;--------------------------------------------
; plot
;--------------------------------------------
if (PLOT) then

;************************************************
; Setting up correlation plot
;************************************************
 wks  = gsn_open_wks(plotType,plotName) ; specifies a ps plot
 
 res                     = True                         ; plot mods desired
  res@gsnFrame                 = False                  ; don't advance frame yet
  res@gsnDraw                  = False                  ; don't draw plot
  res@xyMarkLineModes          = (/"Markers","Lines"/)  ; choose which have markers
  res@xyMarkers                = 16                     ; choose type of marker 
  res@xyMarkerColor            = "red"                  ; Marker color
  res@xyMarkerSizeF            = 0.004                  ; Marker size (default 0.01)
  res@xyDashPatterns           = 11                     ; dashed line 
  res@xyLineThicknesses        = (/1,2/)                ; set second line to 2

  ; Set axes limits
  res@trYMaxF                  = ymax
  res@trYMinF                  = ymin
  res@trXMaxF                  = xmax
  res@trXMinF                  = xmin

  res@tmEqualizeXYSizes        = True
  res@tmLabelAutoStride        = True

  res@tiMainString        = titlestring  ; title
  res@tiYAxisString            ="AK applied total column"
  res@tiXAxisString            ="a priori total column"

  res@pmLegendDisplayMode      = "Always"        ; turn on legend
  res@lgAutoManage             = False           ; turn off auto-manage
  res@pmLegendSide             = "top"           ; Change location of 
  res@lgPerimOn                = False           ; turn off box around
  res@pmLegendParallelPosF     = 0.25           ; move units right
  res@pmLegendOrthogonalPosF   = -0.4            ; move units down
  res@pmLegendWidthF           = 0.2             ; Change width and
  res@pmLegendHeightF          = 0.3             ; height of legend
  res@lgLabelFontHeightF       = 0.01

  res@xyExplicitLegendLabels   = "CAM-Chem versus MOPITT AK applied"  ; create explicit labels
 plot1  = gsn_csm_xy (wks, ap_to_plot, ap_ak_plot,res)     ; create plot

  res@xyExplicitLegendLabels   = "CAM-Chem versus FTS AK applied"  ; create explicit labels
  res@pmLegendOrthogonalPosF   = -0.45                     ; move units down
  res@xyMarkerColor            = "blue"                    ; Marker color
  res@xyMarkerSizeF            = 0.003                     ; Marker size (default 0.01)
 plot2  = gsn_csm_xy (wks, ap_to_plot, ap_ftsak_plot,res)  ; create plot

  res@xyExplicitLegendLabels   = "CAM-Chem versus FTS AK applied"  ; create explicit labels
  res@pmLegendOrthogonalPosF   = -0.45                     ; move units down
  res@xyMarkerColor            = "green"                    ; Marker color
  res@xyMarkerSizeF            = 0.003                     ; Marker size (default 0.01)
 ;plot3  = gsn_csm_xy (wks, ap_ak_plot, ap_ftsak_plot,res)  ; create plot


 ; create a blank plot for grey line
  bres              = True
    bres@trXMinF      = xmin
    bres@trXMaxF      = xmax
    bres@trYMinF      = ymin
    bres@trYMaxF      = ymax
    bres@tmEqualizeXYSizes        = True
    bres@tmLabelAutoStride        = True
    blank_plot = gsn_csm_blank_plot(wks,bres)

 ; add 1:1 line 
  res_lines                   = True                     ; polyline mods desired
    res_lines@gsLineDashPattern = 0.                     ; solid line
    res_lines@gsLineThicknessF  = 5.                     ; line thicker
    res_lines@gsLineColor       = "gray"                 ; line color
    res_lines@tfPolyDrawOrder   = "PreDraw"              ; send to back
  xx = (/0,3e18/)
  yy = (/0,3e18/)
  dum1 = gsn_add_polyline(wks,blank_plot,xx,yy,res_lines)      ; add polyline


 overlay(blank_plot,plot1)
 overlay(blank_plot,plot2)
 ;overlay(blank_plot,plot3)
 draw(blank_plot)
 frame(wks)

end if ; PLOT

;************************************************
; Setting up profile plot
;************************************************
 if (PLOTPROFILE) then
  wks  = gsn_open_wks(plot2Type,plot2Name)            ; open a workstation
  
  ;-----------------------------------
  ; define resources to use for plotting
  ;-----------------------------------
  res = True
    res@gsnFrame                 = False          ; don't advance frame
    res@trYMaxF                  = 1020
    res@trYMinF                  = 100
    res@trXMaxF                  = 160
    res@trXMinF                  = 0
    res@xyMarkLineMode           = "Markers"      ; Markers *and* lines
    res@xyMarkers                = 16             ; marker style
    res@xyMarkerSizeF            = 0.015

    res@trYReverse               = True 
    res@tmXTOn                   = False          ; turn off tickmarks
    res@tmYROn                   = False
    res@tmXTBorderOn             = False          ; turn off outline
    res@tmYRBorderOn             = False
    res@tmXBMode                 = "Manual"	
    res@tmXBTickStartF           = 0
    res@tmXBTickEndF             = 160
    res@tmXBTickSpacingF         = 50

    res@pmLegendDisplayMode      = "Always"        ; turn on legend
    res@lgAutoManage             = False           ; turn off auto-manage
    res@pmLegendSide             = "top"           ; Change location of 
    res@lgPerimOn                = False           ; turn off box around
    res@pmLegendParallelPosF     = 1.1             ; move units right
    res@pmLegendOrthogonalPosF   = -0.9            ; move units down
    res@pmLegendWidthF           = 0.2             ; Change width and
    res@pmLegendHeightF          = 0.3             ; height of legend
    res@lgLabelFontHeightF       = 0.01
    ;res@lgLabelJust              = "LeftCenter"


    res@tiMainString             ="CO at Lauder - mole fraction profiles"
    res@tiYAxisString            ="Altitude (hPa)"
    res@tiXAxisString            ="Mole fraction"

    res@tfPolyDrawOrder          = "Predraw"       ; line on top
  ;-----------------------------------
  ; end define resources
  ;-----------------------------------

  ;-----------------------------------
  ; Draw different vertical profiles
  ;-----------------------------------
  ; 1
    res@xyExplicitLegendLabels = "MOPITT a priori"  ; create explicit labels
    res@xyLineColors            = "blue"
    res@xyMarkerColors          = "blue"
  plot = gsn_csm_xy(wks,  apriori(0,:), parray(0,:), res)

  ; 2
    res@xyLineColors            = "black"
    res@xyMarkerColors          = "black" 
    res@xyExplicitLegendLabels = "MOPITT retrieved profile" ; create explicit labels
    res@pmLegendOrthogonalPosF = -1               ; move units down

  plot = gsn_csm_xy(wks,  m_prof_pared, parray(0,:), res)
print(m_prof_pared)
print(parray(0,:))

  ; 3
    res@xyLineColors            = "red"
    res@xyMarkerColors          = "red" 
    res@xyExplicitLegendLabels = "FTS retrieved profile"    ; create explicit labels
    res@pmLegendOrthogonalPosF = -1.1                ; move units down

  plot = gsn_csm_xy(wks,  fts_prof_comp , fts_alt(0,:), res)

  ; 4
    res@xyLineColors            = "orange"
    res@xyMarkerColors          = "orange" 
    res@xyExplicitLegendLabels = "FTS interpolated profile"    ; create explicit labels
    res@pmLegendOrthogonalPosF = -1.2               ; move units down

  plot = gsn_csm_xy(wks,  fts_prof_interp, parray(0,:), res)


  ; 5
    res@xyLineColors            = "green"
    res@xyMarkerColors          = "green" 
    res@xyExplicitLegendLabels = "FTS with MOPITT AK"    ; create explicit labels
    res@pmLegendOrthogonalPosF = -1.3               ; move units down

  plot = gsn_csm_xy(wks,  fts_prof_wak, parray(0,:), res)


  ; Draw background vertical grid
  mopittres = True
    mopittres@gsLineThicknessF        = 1
    mopittres@gsLineDashPattern       = 1
    mopittres@gsLineColor             = "black"

  dummy_alt = new(10, graphic)
  do i = 0, 9
    dummy_alt(i) = gsn_add_polyline(wks, plot, (/0,200/), (/parray(0,i), \
                   parray(0,i)/), mopittres)
  end do

; ===================
; Now draw map with texts strings and polygon
; ===================
  draw(plot)
  frame(wks)
  end if    ; PLOTPROFILE

end

