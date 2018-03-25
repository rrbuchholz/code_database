;============================================
; plot_tcol_ak_mopitt.ncl
;============================================
;
; Concepts Illustrated
;          - Re-open several binned v6, level 2, he5 files
;          - Works with data averaged around station
;          - Calculate total column averaging kernel
;          - Apply normal AK and tcol AK to FTS
;          - plot results for comparison
;
; To use type on the command line:
;          > ncl plot_corr_fts_mopitt.ncl
;                            RRB Oct 28, 2014
;============================================
; load the libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------
  fts_dir = "/home/buchholz/FTS_data/NDACC/lauder2/"
  fts_file = "ld_co_1994_2011.hdf"

  ; MOPITT version
  version = "V6T"
  location="Lauder"
  mopitt_general     = "/home/buchholz/NCL_programs/pixelbinning/"+location+"_1deg_"+version+"MOPITTavg_"
 ; mopitt_general     = "/home/buchholz/NCL_programs/Lauder_1deg_"+version+"MOPITTavg_"
  mopitt_binned_pix = mopitt_general+"all.nc"
  pixelnum="all "+version

  mopitt_binned_pix2 = "/home/buchholz/NCL_programs/pixelbinning/"+location+"_1deg_V6JMOPITTavg_all.nc"
  mopitt_binned_pix3 = "/home/buchholz/NCL_programs/pixelbinning/"+location+"_1deg_V6NMOPITTavg_all.nc"

  ;------------
  ; select location
  ;------------
  WOLLONGONG = False
  LAUDER     = True
  USERDEF    = False
    if (USERDEF) then
      location_lat = -10
      location_lon = 10
      location     = "location name"
      ; UTC +
      time_diff    = 0
    end if

  ;------------
  ; toggles
  ;------------
  PLOT            = False
    plotType      = "x11"

  PLOTPROFILE       = True
    plot2Type       = "x11"

;--------------------------------------------
; end user input
;--------------------------------------------
;
;--------------------------------------------
; set up
;--------------------------------------------
  if (WOLLONGONG) then
    location_lat = -34.41
    location_lon = 150.88
    location = "Wollongong"
    time_diff    = 10
  else if (LAUDER) then
    location_lat = -45.038
    location_lon = 169.684
    location = "Lauder"
    ; UTC +
    time_diff    = 12
  end if
  end if

   ; -------------------------------
   ; Plotting set up
   ; -------------------------------
     ; PLOT
     plotName      = version+"diffAKs"+location
     titlestring          = "FTS with matrix and vector AK at Lauder, 2000-2012"
     ymax                 = 1e17
     ymin                 = -1e17
     xmin                 = 1999
     xmax                 = 2014

     ; PLOTPROFILE
     plot2Name      = version+"averaging_kernels"+location
     titlestring2          = "MOPITT and FTS Averaging kernels, "+pixelnum+" for Lauder, 2000-2012"
     y2max                 = 1000
     y2min                 = 100
     x2min                 = -0.05
     x2max                 = 1.5

  ; -------------------------------
  ; FTS
  ; -------------------------------
  ; names of data structures
  ; determined from an ncl_filedump
  fts_tracer         = "CO_COLUMN_ABSORPTION_SOLAR"
  fts_datetime       = "DATETIME"
  fts_posterior      = "CO_MIXING_RATIO_ABSORPTION_SOLAR"
  fts_press          = "PRESSURE_INDEPENDENT"
  fts_tcol_ak        = "CO_COLUMN_ABSORPTION_SOLAR_AVK"

  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  ; names of data structures
  ; determined from an ncl_filedump
  sat_tcol      = "MOPITT_TCOL_CO_WGT"
  sat_profile   = "MOPITT_PROFILE_CO_WGT"
  timearray     = "TIME_AVG"
  sat_psurf     = "MOPITT_PSURF_WGT"
  sat_ap        = "MOPITT_APRIORI_CO_WGT"
  sat_ak        = "MOPITT_AVKER_CO_WGT"
  sat_err       = "MOPITT_TCOL_CO_ERR"


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
mopitt_in = addfile(mopitt_binned_pix, "r")
    mopitt_tcol  = mopitt_in->$sat_tcol$
    mopitt_profile = mopitt_in->$sat_profile$
    time         = mopitt_in->$timearray$
   ; Date is in seconds since 1993-1-1 00:00:00
    mopitt_date  = cd_calendar(time, 0)
    psurf        = mopitt_in->$sat_psurf$
    apriori      = mopitt_in->$sat_ap$
    AvKer        = mopitt_in->$sat_ak$
    error        = mopitt_in->$sat_err$

mopitt_in2 = addfile(mopitt_binned_pix2, "r")
    AvKer2           = mopitt_in2->$sat_ak$
    mopitt_profile_2 = mopitt_in2->$sat_profile$

mopitt_in3 = addfile(mopitt_binned_pix3, "r")
    AvKer3           = mopitt_in3->$sat_ak$
    mopitt_profile_3 = mopitt_in3->$sat_profile$

fts_in = addfile(fts_dir+fts_file, "r")
  fts_tcol            = fts_in->$fts_tracer$
  ; Date in MJD2000, fraction of days since 
  ; Jan 1st, 2000, 00:00:00
  fts_mjd2000         = fts_in->$fts_datetime$
  fts_local           = fts_mjd2000+(time_diff/24.)
    fts_local@units   = "days since 2000-01-01 00:00:0.0"
  fts_date            = cd_calendar(fts_local, 0)
  fts_ppmv            = fts_in->$fts_posterior$
  fts_prof            = fts_ppmv*1000           ; ppm to ppb
  fts_alt             = fts_in->$fts_press$
  fts_AvKer           = fts_in->$fts_tcol_ak$

;--------------------------------------------
; Set up MOPITT pressure arrays
;--------------------------------------------
  parray = new((/dimsizes(psurf), 10/), float)
  parray(:,0) = psurf
  do i=0,dimsizes(psurf)-1
    parray(i,1:9) = pvect
  end do
  ;--------------------------------------------------------------
  ; Correct for where surface pressure <900 hPa
  ;--------------------------------------------------------------
  dp = new((/dimsizes(psurf), 10/), float) ; Pressure difference array
    do z= 0, 8, 1
      dp(:,z) = parray(:,0) - parray(:,z+1)
    end do
   dp(:,9) = 1000

  ; Repeat surface values at all levels to replace if needed
  psurfarray = new((/dimsizes(psurf), 10/), float) 
   do z= 0, 9, 1
    psurfarray(:,z) = psurf
   end do

   test = ind(dp(:,0).le.0)

   parray = where(dp.le.0,parray@_FillValue,parray)
   parray = where((dp.le.100 .and. dp.ge.0),psurfarray,parray)

  ; Repeat surface apriori values at all levels to replace if needed
  apsurfarray = new((/dimsizes(psurf), 10/), float) 
   do z= 0, 9, 1
    apsurfarray(:,z) = (apriori(:,0))
   end do
   apriori = where(dp.le.0,apriori@_FillValue,apriori) ; re-order apriori array
   apriori = where((dp.le.100 .and. dp.ge.0),apsurfarray,apriori)

  ; FTS values are averages for the whole box, 
  ; centred at an altitude while MOPITT values are averages described for box above level.
  pinterp = new((/dimsizes(psurf), 10/), double)
  do z=0,8,1
    pinterp(:,z) = parray(:,z) - (parray(:,z)-parray(:,z+1))/2
  end do
  pinterp(:,9) = 87.


;--------------------------------------------
; build comparison array
;--------------------------------------------
do i=0,dimsizes(fts_tcol)-1
   ; collect MOPITT and FTS for comparison
   mopitt_comp = ind(mopitt_date(:,0).eq.fts_date(i,0)\
                 .and.mopitt_date(:,1).eq.fts_date(i,1)\
                 .and.mopitt_date(:,2).eq.fts_date(i,2))

  if (any(.not.ismissing(mopitt_comp))) then
      ;--------------------------------------------
      ; Interpolate FTS to MOPITT vertical levels
      ;--------------------------------------------
      ; note, interpolation automatically turns the fts profile upside down
      ; to align with MOPITT parray
      fts_interp = new((/10/), float)
      ; extrapolate
      fts_interp = int2p_n_Wrap(fts_alt(i,:),fts_prof(i,:),pinterp(mopitt_comp,:),-1,0)
      ; interpolation doesn't cover missing values correctly (probably due to extrapolation,
      ; so replace levels where pinterp is missing
      levs_missing = ind(ismissing(pinterp(mopitt_comp,:)))
      if (.not.ismissing(levs_missing)) then
         fts_interp(levs_missing) = fts_interp@_FillValue
      end if
      ; no extrapolate
      ;fts_interp = int2p_n_Wrap(fts_alt(i,:),fts_prof(i,:),pinterp(mopitt_comp,:),1,0)

      ;--------------------------------------------
      ; Apply AK to FTS
      ; note AK applies to log(vmr) values
      ;--------------------------------------------
      logfts = log10(fts_interp)
        ;logfts = where(ismissing(logfts),0,logfts)
      logap = log10(apriori(mopitt_comp,:))
        ;logap = where(ismissing(logap),0,logap)

      logfts_ak = new((/10/), float)
      print("Convolving with averaging kernel. . .") ; AK calculations
         ak = (/AvKer(mopitt_comp,:,:)/)
         ; missing values -> zero for array calculations
         ak  = where(ismissing(ak),0,ak)  
         logap  = where(ismissing(logap),0,logap)       
         logfts  = where(ismissing(logfts),0,logfts)
         ; calculate         
         logfts_ak = logap + transpose(ak) # (logfts - logap)
         ;logfts_ak_1 = transpose(ak) # (logfts - logap)
       print(". . . Done!")
       ; change zero back to missing values for plotting etc
       logfts_ak = where(logfts_ak.eq.0,logfts_ak@_FillValue, logfts_ak)
       ;logfts_ak = where(logfts_ak_1.eq.0,logfts_ak_1@_FillValue, logfts_ak_1)
       ; change back to vmr
       fts_ak = 10^logfts_ak
       ;fts_ak = 10^logfts_ak

      ;--------------------------------------------
      ; Pressure difference array
      ;--------------------------------------------
      ; MOPITT pressures are level edges.
      ; see V5 User Guide for more info
      delta_p = new((/10/), float)
      do z= 0, 8, 1
         delta_p(z) = parray(mopitt_comp,z)-parray(mopitt_comp,z+1)
      end do
      delta_p(9) = 74   ; 26 top level
      ;delta_p(9) = 67  ; 33 top level
      ;delta_p(9) = 100  ; 0 top level


      ;--------------------------------------------
      ; Calculate tcol AK
      ;--------------------------------------------
      log10e = log10(exp(1.))
      ap = apriori(mopitt_comp,:)
      ap  = where(ismissing(ap),0,ap)  
      prof = mopitt_profile(mopitt_comp,:)
      prof  = where(ismissing(prof),0,prof)
      prof2 = mopitt_profile_2(mopitt_comp,:) 
      prof2  = where(ismissing(prof2),0,prof2)
      prof3 = mopitt_profile_3(mopitt_comp,:) 
      prof3  = where(ismissing(prof3),0,prof3)
      ak_colm = (xp_const/log10e)*((prof # transpose(ak)))
      ak2 = (/AvKer2(mopitt_comp,:,:)/)
      ak_colm_2 = (xp_const/log10e)*((prof2 # transpose(ak2)))
      ak3 = (/AvKer3(mopitt_comp,:,:)/)
      ak_colm_3 = (xp_const/log10e)*((prof3 # transpose(ak3)))

      ; apply to FTS column
      ; produces partial columns
      fts_ak_2 =ak_colm # transpose(logfts - logap)

      ;--------------------------------------------
      ; Calculate total column
      ;--------------------------------------------
      ; apriori total column
      xp_ap = new((/10/), double)
      xp_ap= (xp_const * ap) * delta_p 
      ap_tcol = dim_sum(xp_ap)

      ; FTS interpolated and smoothed total column
      xp_tcol = new((/10/), float)
      xp_tcol= (xp_const * fts_ak) * delta_p 
      tcol_ak = dim_sum(xp_tcol)

      ; FTS interpolated and smoothed total column (tcol AK)
      tcol_ak_2 = ap_tcol + fts_ak_2 

      ; sanity check for surface pressures less than 900 hPa
      if (.not.ismissing(levs_missing)) then  
         print("found a surface pressure below 900 hPa")
         print(delta_p)
         ;print(fts_interp)
         print(fts_ak)
         ;print(tcol_ak)
        ;exit
      end if

     if (counter.eq.0) then
              time_to_plot    = time(mopitt_comp)
              fts_to_plot     = fts_tcol(i)
              fts_ak_plot     = tcol_ak
              fts_ak_plot2    = tcol_ak_2

              ak_vector = new((/1,10/),float)
              ak_vector(0,:) = ak_colm
              ak_vector_2 = new((/1,10/),float)
              ak_vector_2(0,:) = ak_colm_2
              ak_vector_3 = new((/1,10/),float)
              ak_vector_3(0,:) = ak_colm_3

              ;ak_vector(0,:) = (ak_colm/delta_p)/ xp_const
              p_levs = new((/1,10/),float)
              p_levs(0,:) = parray(mopitt_comp,:)
              fts_ak_vector = new((/1,29/),float)
              fts_ak_vector(0,:) = fts_AvKer(i,:)
              fts_p_levs = new((/1,29/),float)
              fts_p_levs(0,:) = fts_alt(i,:)

              temp = counter
              delete(counter)
              counter = temp + 1
              delete(temp)
          else
              temp1 := time_to_plot
              temp2 := fts_to_plot
              temp3 := fts_ak_plot
              temp4 := fts_ak_plot2
              temp5 := ak_vector
              temp5_2 := ak_vector_2
              temp5_3 := ak_vector_3
              temp6 := p_levs
              temp7 := fts_ak_vector
              temp8 := fts_p_levs

              time_to_plot   := array_append_record(temp1, time(mopitt_comp),0)
              fts_to_plot    := array_append_record(temp2,fts_tcol(i),0)
              fts_ak_plot    := array_append_record(temp3,tcol_ak,0)
              fts_ak_plot2   := array_append_record(temp4,tcol_ak_2,0)

              temp5a := new((/1,10/),float)
              temp5a(0,:) = ak_colm
              ;temp5a(0,:) = (ak_colm/delta_p)/ xp_const
              ak_vector      := array_append_record(temp5,temp5a,0)
              temp5_2a := new((/1,10/),float)
              temp5_2a(0,:) = ak_colm_2
              ak_vector_2      := array_append_record(temp5_2,temp5_2a,0)
              temp5_3a := new((/1,10/),float)
              temp5_3a(0,:) = ak_colm_3
              ak_vector_3      := array_append_record(temp5_3,temp5_3a,0)

              temp6a := new((/1,10/),float)
              temp6a(0,:) = parray(mopitt_comp,:)
              p_levs         := array_append_record(temp6,temp6a,0)
              temp7a = new((/1,29/),float)
              temp7a = fts_AvKer(i,:)
              fts_ak_vector   := array_append_record(temp7,temp7a,0)
              temp8a = new((/1,29/),float)
              temp8a = fts_alt(i,:)
              fts_p_levs      := array_append_record(temp8,temp8a,0)


       end if         
   end if
   delete(mopitt_comp)
end do


print("****")
print(ind(ismissing(fts_ak_plot)))
printVarSummary(ak_vector)
printVarSummary(p_levs)

;--------------------------------------------
; Calculate mean MOPITT averaging kernel
;--------------------------------------------
mean_levs = dim_avg_n_Wrap(p_levs,0)
mean_ak = dim_avg_n_Wrap(ak_vector,0)
;norm_ak = mean_ak/dim_sum(mean_ak)
;ak_sd = dim_stddev_n_Wrap(ak_vector,0)/dim_sum(mean_ak)
norm_ak = mean_ak/max(mean_ak)
ak_sd = dim_stddev_n_Wrap(ak_vector,0)/max(mean_ak)

mean_ak_2 = dim_avg_n_Wrap(ak_vector_2,0)
norm_ak_2 = mean_ak_2/max(mean_ak_2)
mean_ak_3 = dim_avg_n_Wrap(ak_vector_3,0)
norm_ak_3 = mean_ak_3/max(mean_ak_3)
print(mean_ak_3)
;check = sum(norm_ak)

print(dimsizes(ak_vector))
print(dimsizes(ak_vector_2))
print(dimsizes(ak_vector_3))

print(ak_vector_2)
;exit

;--------------------------------------------
; Calculate mean FTS averaging kernel
;--------------------------------------------
mean_fts_levs = dim_avg_n_Wrap(fts_p_levs,0)
mean_fts_ak = dim_avg_n_Wrap(fts_ak_vector,0)

norm_fts_ak = mean_fts_ak
ak_fts_sd = dim_stddev_n_Wrap(fts_ak_vector,0)
print(ak_fts_sd)

;--------------------------------------------
; Calculate difference
;--------------------------------------------
diff = (fts_ak_plot - fts_ak_plot2)
diff_mean = avg(diff)
print(diff_mean)


;--------------------------------------------
; convert time
;--------------------------------------------
time_frac = cd_calendar(time_to_plot, 4)

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
  res@xyMarkers                = 9                     ; choose type of marker 
  res@xyMarkerColor            = "dodgerblue"                  ; Marker color
  res@xyMarkerSizeF            = 0.008                  ; Marker size (default 0.01)
  res@xyDashPatterns           = 2                      ; dashed line 
  res@xyLineThicknesses        = 5                ; thickness

  ; Set axes limits
  res@trYMaxF                  = ymax
  res@trYMinF                  = ymin
  res@trXMaxF                  = xmax
  res@trXMinF                  = xmin

  res@tmEqualizeXYSizes        = True
  res@tmLabelAutoStride        = True

  res@tiMainString        = titlestring  ; title
  res@tiYAxisString            ="MOPITT total column"
  res@tiXAxisString            ="FTS total column"

 plot1  = gsn_csm_xy (wks, time_frac, diff,res)      ; create plot


 draw(plot1)
; draw(plot2)
 frame(wks)

end if ; PLOT


;************************************************
; Setting up profile plot
;************************************************
 if (PLOTPROFILE) then
  wks  = gsn_open_wks(plot2Type,plot2Name)            ; open a workstation

  ;-----------------------------------
  ; define a polygon centered the width of std-dev MOPITT
  ;-----------------------------------
   ya    = new( (/2*dimsizes(mean_levs)/), float )
   yb    = new( (/2*dimsizes(mean_levs)/), float )
   do k=0,dimsizes(mean_levs)-1
     dx = ak_sd(k)
     ya(k) = norm_ak(k) + dx
     yb(k) = mean_levs(k)
     yb(2*dimsizes(mean_levs)-1-k) = mean_levs(k)
     ya(2*dimsizes(mean_levs)-1-k) = norm_ak(k) - dx
   end do

  ;-----------------------------------
  ; define a polygon centered the width of std-dev FTS
  ;-----------------------------------
   ya1    = new( (/2*dimsizes(mean_fts_levs)/), float )
   yb1    = new( (/2*dimsizes(mean_fts_levs)/), float )
   do k=0,dimsizes(mean_fts_levs)-1
     dx1 = ak_fts_sd(k)
     ya1(k) = norm_fts_ak(k) + dx1
     yb1(k) = mean_fts_levs(k)
     yb1(2*dimsizes(mean_fts_levs)-1-k) = mean_fts_levs(k)
     ya1(2*dimsizes(mean_fts_levs)-1-k) = norm_fts_ak(k) - dx1
   end do

  
  ;-----------------------------------
  ; define resources to use for plotting
  ;-----------------------------------
  res2 = True
    res2@gsnFrame                 = False          ; don't advance frame
    ; Set axes limits
    res2@trYMaxF                  = y2max
    res2@trYMinF                  = y2min
    res2@trXMaxF                  = x2max
    res2@trXMinF                  = x2min
    res2@xyMarkLineMode           = "MarkLines"    ; Markers *and* lines
    res2@xyMarkers                = 9             ; marker style
    res2@xyMarkerSizeF            = 0.015
    res2@xyLineThicknessF         = 4
    res2@vpWidthF                 = 0.5
    res2@vpHeightF                = 0.4 

    res2@trYLog                   = True           ; convert axes to logaritmic\
    ;res2@trXLog                   = False           ; convert axes to logaritmic
    res2@trYReverse               = True 
    res2@tmXTOn                   = False          ; turn off tickmarks
    res2@tmYROn                   = False
    res2@tmXTBorderOn             = False          ; turn off outline
    res2@tmYRBorderOn             = False
    res2@tmXBMode                 = "Manual"	
    res2@tmXBTickStartF           = 0
    res2@tmXBTickEndF             = x2max
    res2@tmXBTickSpacingF         = 0.5

    res2@tmYLMode                 = "Explicit"
    res2@tmYLValues               = (/100,300,500,700,1000/)
    res2@tmYLLabels               = "" + res2@tmYLValues

    res2@pmLegendDisplayMode      = "Always"        ; turn on legend
    res2@lgAutoManage             = False           ; turn off auto-manage
    res2@pmLegendSide             = "top"           ; Change location of 
    res2@lgPerimOn                = False           ; turn off box around
    res2@pmLegendParallelPosF     = 0.9             ; move units right
    res2@pmLegendOrthogonalPosF   = -0.4            ; move units down
    res2@pmLegendWidthF           = 0.2             ; Change width and
    res2@pmLegendHeightF          = 0.3             ; height of legend
    res2@lgLabelFontHeightF       = 0.01
    res2@lgLabelJust              = "Right"


    res2@tiMainString             ="CO at Lauder - Averaging Kernels"
    res2@tiYAxisString            ="Altitude (hPa)"
    res2@tiXAxisString            ="AK value"

    res2@tfPolyDrawOrder          = "Predraw"       ; line on top
  ;-----------------------------------
  ; end define resources
  ;-----------------------------------

  ;-----------------------------------
  ; Draw different AKs
  ;-----------------------------------
  ; 1
    res2@xyExplicitLegendLabels = "MOPITT AK "+version+ " (norm)"   ; create explicit labels
    res2@xyLineColors            = "red"
    res2@xyMarkerColors          = "red"
    res2@pmLegendOrthogonalPosF  = -0.5            ; move units down
  plot = gsn_csm_xy(wks,  norm_ak, mean_levs, res2)
;  plot = gsn_csm_xy(wks,  mean_ak, mean_levs, res2)
    res2@xyExplicitLegendLabels = "MOPITT AK V6J (norm)"   ; create explicit labels
    res2@xyLineColors            = "orange"
    res2@xyMarkerColors          = "orange"
    res2@pmLegendOrthogonalPosF  = -0.65            ; move units down
  plot = gsn_csm_xy(wks,  norm_ak_2, mean_levs, res2)
 ; plot = gsn_csm_xy(wks,  mean_ak_2, mean_levs, res2)

    res2@xyExplicitLegendLabels = "MOPITT AK V6N (norm)"   ; create explicit labels
    res2@xyLineColors            = "grey"
    res2@xyMarkerColors          = "grey"
    res2@pmLegendOrthogonalPosF  = -0.8            ; move units down
  plot = gsn_csm_xy(wks,  norm_ak_3, mean_levs, res2)
 ; plot = gsn_csm_xy(wks,  mean_ak_3, mean_levs, res2)

  ; 2
    res2@xyLineColors            = "blue"
    res2@xyMarkerColors          = "blue" 
    res2@xyExplicitLegendLabels  = "FTS AK"      ; create explicit labels
    res2@pmLegendOrthogonalPosF  = -0.95            ; move units down
    res2@xyMarkers               = 7             ; marker style

 ; plot = gsn_csm_xy(wks,  norm_fts_ak, mean_fts_levs, res2)


  ; Draw background vertical grid
  mopittres = True
    mopittres@gsLineThicknessF        = 1
    mopittres@gsLineDashPattern       = 1
    mopittres@gsLineColor             = "grey"

  dummy_alt = new(10, graphic)
  do i = 0, 9
    dummy_alt(i) = gsn_add_polyline(wks, plot, (/x2min,x2max/), (/mean_levs(i), \
                   mean_levs(i)/), mopittres)
  end do

  ;-----------------------------------
  ; Draw different standard deviations
  ;-----------------------------------

;  gsres                          = True                ; poly res
;    gsres@gsFillColor            = "SlateBlue"         ; color chosen
;    gsres@gsFillOpacityF         = 0.1                 

;    dummy2 = gsn_add_polygon(wks,plot,ya,yb,gsres)

;    gsres@gsFillColor            = "Red"         ; color chosen
;    dummy3 = gsn_add_polygon(wks,plot,ya1,yb1,gsres)


; ===================
; Now draw map with texts strings and polygon
; ===================
  draw(plot)
  frame(wks)
  end if    ; PLOTPROFILE

end

