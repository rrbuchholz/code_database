;=======================================================;
;  station_anomalies.ncl 
;=======================================================;
;
; Concepts illustrated:
;   - For use with MOPITT CO version 7, station avg data
;   - Also uses FTS station data
;   - loading CO data
;   - daily mean values
;   - whole dataset average month values
;   - whole dataset month means - weekly average differences (anomalies)
;   - climate variability
;
;   Files needed:
;         -MOPITT subset of level 2, daily hdf files
;         -FTS files
;
;   To run type:
;         avg-plus-event-identify.ncl
;                                  RRB February 11, 2015
;=======================================================;
; load the libraries
load "~/code_database/ncl_programs/buchholz_global_util/week_average.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------

  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  version = "V7"
  suff = "J"
  location = "Wollongong"
  surface = "land"
  year_s = 2001
  network = "NDACC"

  ;------------
  ; scale of outside sd
  ; to denote event
  ;------------
    event_scale = 3.0
    neg_event = -3.0

  ;------------
  ; toggles
  ;------------
  PLOT           = True
    plttype      = "x11"
    ;plttype@wkPaperSize = "A4"
    ;plttype@wkWidth = 0.5
    ;plttype@wkHeight = 0.5
    year_e = 2017

  
  PLOTFTS        = True
  ASCII          = False
  
;--------------------------------------------
; end user input
;--------------------------------------------
;
;--------------------------------------------
; set up
;--------------------------------------------
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  ; names of data structures
  ; determined from an ncl_filedump
  sat_tcol      = "RetrievedCOTotalColumn_WGT"
  timearray     = "Time_AVG"

  ; -------------------------------
  ; FTS
  ; -------------------------------
  ; names of data structures
  ; determined from an ncl_filedump
  fts_tracer         = "CO_COLUMN_ABSORPTION_SOLAR"
  fts_datetime       = "DATETIME"

  ; -------------------------------
  ; STATION PARAMETERS
  ; -------------------------------
  if (location.eq."Darwin") then
    location_lat = -12.42
    location_lon = 130.89
    sm_location = "darwin"
    ; UTC +
    time_diff    = 9.5
  else if (location.eq."Lauder") then
    location_lat = -45.038
    location_lon = 169.684
    sm_location = "lauder"
    ; UTC +
    time_diff    = 12
  else if (location.eq."Wollongong") then
    location_lat = -34.41
    location_lon = 150.88
    sm_location = "wollongong"
    ; UTC +
    time_diff    = 10
  end if
  end if
  end if

  ; -------------------------------
  ; Input file set-up
  ; -------------------------------
  ; MOPITT
  mopitt_general = "/IASI/home/buchholz/MOPITT_subset/"+version+"/stations/"
  mopitt_file = systemfunc ("ls "+mopitt_general+location+"_1deg_"+version+suff+"*all_"+surface+".nc")

  ; FTS
  if (network.eq."TCCON") then
      fts_files =  systemfunc ("ls /IASI/home/buchholz/FTS_data/TCCON/co/"+sm_location+"/*.public.nc")
  else
      fts_files =  systemfunc ("ls /IASI/home/buchholz/FTS_data/NDACC/co/"+sm_location+"/groundbased_ftir.co_*.hdf")
  end if

;print(fts_files)
;exit


  ; -------------------------------
  ; OUTPUT RELATED SETUP
  ; -------------------------------
  if (PLOT) then
    pltdir       = "./"
    pltname      = version+"mopitt_l2_vs_fts_" + location
  end if

  if (ASCII) then
     outname      = location+"_"+delta_deg+"deg_"+version+"MOPITTavg_"+f1suffix+".txt"
  end if

  time_diff_sec = time_diff*60*60


  ; -------------------------------
  ; CONSTANTS
  ; -------------------------------                                          
   NAv    = 6.0221415e+23                    ;--- Avogadro's number
   g      = 9.81                             ;--- m/s - gravity
   H = (8.314*240)/(0.0289751*9.8)           ;--- scale height
   MWair = 28.94                             ;--- g/mol
   xp_const = (NAv* 10)/(MWair*g)*1.0e-09    ;--- scaling factor for turning vmr into pcol
                                             ;--- (note 1*e-09 because in ppb)

;--------------------------------------------
; load file and extract
;--------------------------------------------
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  ; read data from region
  fin = addfile(mopitt_file, "r")            ; read in

    ; select over a time slice
    mopitt_time_dummy    = fin->$timearray$  
    mopitt_date_dummy    = cd_calendar(mopitt_time_dummy, 0)
      years_dummy = floattointeger(mopitt_date_dummy(:,0))
      year_select_ind = ind(years_dummy.ge.year_s)

    ; read in MOPITT data
    print("***Reading MOPITT data at " + location)
    mopitt_tcol    = fin->$sat_tcol$(year_select_ind)
    mopitt_time    = mopitt_time_dummy(year_select_ind)     
     ; local time in seconds since 1993-1-1 00:00:00 (TAI93)
    mopitt_date    = cd_calendar(mopitt_time, 0)
      years  = floattointeger(mopitt_date(:,0))
      months = floattointeger(mopitt_date(:,1))
      days   = floattointeger(mopitt_date(:,2))
    yyyymmdd       = cd_calendar(mopitt_time, 2)
    day_yfrac      = cd_calendar(mopitt_time, 4)

  if (PLOTFTS) then
  ; -------------------------------
  ; FTS
  ; -------------------------------
    fts_in = addfiles (fts_files, "r")
    ListSetType (fts_in, "cat")             ; concatenate or "merge" (default)

   if (network.eq."TCCON") then
    print("***Reading FTS data at " + location)
    fts_xco            = fts_in[:]->$"xco_ppb"$
    fts_psurf          = fts_in[:]->$"pout_hPa"$
    ; convert xCO to tcol
    fts_tcol = (xp_const * fts_xco) * fts_psurf
    ; Date in MJD2000, fraction of days since 
    ; 1970/1/1 00:00:00
    fts_mjd2000         = fts_in[:]->$"time"$
    fts_local           = fts_mjd2000+(time_diff/24.)
    fts_local@units     = "days since 1970-01-01 00:00:0.0"

   else
    print("***Reading FTS data at " + location)
    ; SELECT FTS DATA AFTER STARTDATE
    fts_mjd2000_dummy    = fts_in[:]->$fts_datetime$
    fts_local_dummy      = fts_mjd2000_dummy +(time_diff/24.)
      fts_local_dummy@units = "days since 2000-01-01 00:00:0.0"
    fts_date_dummy       = cd_calendar(fts_local_dummy , 0)
      fts_years_dummy    = floattointeger(fts_date_dummy(:,0))
      year_select_fts    = ind(fts_years_dummy.ge.year_s)

    fts_tcol_dummy       = fts_in[:]->$fts_tracer$
      fts_tcol           = fts_tcol_dummy(year_select_fts)
      copy_VarMeta(fts_tcol_dummy, fts_tcol)
    fts_local            = fts_local_dummy(year_select_fts)
  end if

    fts_date             = cd_calendar(fts_local, 0)
      fts_years          = floattointeger(fts_date(:,0))
      fts_months         = floattointeger(fts_date(:,1))
      fts_days           = floattointeger(fts_date(:,2))
    fts_yyyymmdd         = cd_calendar(fts_local, 2)

  end if ;(PLOTFTS)

;********************************************
;--------------------------------------------
; perform calculations
;--------------------------------------------
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  ; -------------------------------
  ; DETREND
  ; ------------------------------- 
    startyear = year_s
    endyear = years(dimsizes(years)-1)
    ymid = (tofloat(endyear-startyear))/2

    smooth_mopitt         = runave(mopitt_tcol,230,0)
    detrend_mopitt_smooth = dtrend_msg_n (day_yfrac,smooth_mopitt,False,True,0)
    detrend_mopitt_tcol   = mopitt_tcol - detrend_mopitt_smooth@slope*(day_yfrac-startyear-ymid-0.5)

  ; -------------------------------
  ; CLIMATOLOGICAL DAY AVERAGES 
  ; ------------------------------- 
    climate_time = yyyymmdd_time(toint(startyear), toint(endyear), "integer")
    climate_doy = yyyymmdd_to_yyyyddd(climate_time)
    climate_yfrac = yyyymmdd_to_yyyyfrac(climate_time, 0.5)
    mopitt_array = new((/dimsizes(climate_time),1,1/),double)   ;needs to be 3D for climate calculations
    do j=0,dimsizes(climate_time)-1
      ind_avail := ind(yyyymmdd.eq.climate_time(j))
      if (.not.ismissing(ind_avail(0)))then
        mopitt_array(j,0,0) = detrend_mopitt_tcol(ind_avail)
      end if
    end do

   mopitt_ClmDay = clmDayTLL(mopitt_array, climate_doy)         ; daily climatology at each grid point

  ; -------------------------------
  ; SPLINE FIT TO FILL MISSING VALUES
  ; -------------------------------
    ind_data = ind(.not.ismissing(mopitt_ClmDay(:,0,0)))
    Clm_doy = mopitt_ClmDay&year_day                              ;366 days in climate year
    xi = Clm_doy(ind_data)
    yi = mopitt_ClmDay(ind_data,0,0)
    xo = Clm_doy
    yo = ftcurv(xi, yi, xo)
    new_mopitt_ClmDay = mopitt_ClmDay
    new_mopitt_ClmDay = where(ismissing(mopitt_ClmDay(:,0,0)),yo,mopitt_ClmDay(:,0,0))

  ; -------------------------------
  ; CLIMATOLOGOCAL MONTHLY STDDEV
  ; -------------------------------
    climate_year = yyyyddd_to_yyyymmdd(2004000+Clm_doy)
    split_mm =str_split_by_length(tostring(climate_year),2)
    climate_mopitt_day_sd = new((/dimsizes(Clm_doy),1,1/), float)
    do kk=0,11
      month_ind := ind(months.eq.(kk+1))
      mm_ind    := ind(toint(split_mm(:,2)).eq.(kk+1))
      co_to_avg := detrend_mopitt_tcol(month_ind)
      climate_mopitt_day_sd(mm_ind,0,0) = dim_stddev_n(tofloat(co_to_avg),0)
    end do
    climate_mopitt_day_sd!0 = "year_day"
    climate_mopitt_day_sd&year_day = Clm_doy

  ; -------------------------------
  ; SMOOTHED DAILY CLIMATOLOGY AND
  ; MONTH STDDEV USING 2 HARMONCS  
  ; -------------------------------
    mopitt_ClmDay_sm = smthClmDayTLL(new_mopitt_ClmDay, 2)  
  ; printVarSummary(mopitt_ClmDay_sm)
    mopitt_ClmDaysd_sm = smthClmDayTLL(climate_mopitt_day_sd, 2)

  ; -------------------------------
  ; EXPAND TO WHOLE TIME PERIOD
  ; -------------------------------
    split_doy = str_split_by_length(tostring(climate_doy),4)
    mopitt_day_climate_sm = new(dimsizes(climate_time),double)
    mopitt_day_climate_sd = new(dimsizes(climate_time),double)
    do d=0,dimsizes(climate_doy)-1
      clm_index = toint(split_doy(d,1))
      mopitt_day_climate_sm(d)=mopitt_ClmDay_sm(clm_index-1,0,0)
      mopitt_day_climate_sd(d)=mopitt_ClmDaysd_sm(clm_index-1,0,0)
    end do

  ; -------------------------------
  ; DAILY ANOMALIES
  ; -------------------------------
    day_anom = mopitt_array(:,0,0)-mopitt_day_climate_sm

  ; -------------------------------
  ; DETERMINE EVENTS
  ; -------------------------------
    select_events = where(day_anom.gt.(event_scale*tofloat(mopitt_day_climate_sd)).or.\
                          day_anom.lt.(neg_event*tofloat(mopitt_day_climate_sd)),day_anom,day_anom@_FillValue)
    ind_m_events = ind(.not.ismissing(select_events))
    m_events = climate_time(ind_m_events)

  ;********************************************
  if (PLOTFTS) then
  ; -------------------------------
  ; FTS
  ; -------------------------------
    fts_ymid = (tofloat(fts_years(dimsizes(fts_years)-1)-fts_years(0)))/2
  ; -------------------------------
  ; DAY AVERAGE VALUES
  ; ------------------------------- 
    fts_dayavg = new(dimsizes(climate_time),double)   ;needs to be 3D for climate calculations
    do i = 0, dimsizes(climate_time)-1
      fts_dayavg_ind := ind(toint(fts_yyyymmdd).eq.climate_time(i))
      if (.not.ismissing(fts_dayavg_ind(0)))then
        fts_dayavg(i) = avg(fts_tcol(fts_dayavg_ind))
      end if
    end do

  ; -------------------------------
  ; DETREND
  ; ------------------------------- 
    ind_nomissing = ind(.not.ismissing(fts_dayavg))
    smooth_fts            = runave(fts_dayavg(ind_nomissing),300,0)
    detrend_fts_smooth    = dtrend_msg_n (climate_yfrac(ind_nomissing),smooth_fts,False,True,0)
    detrend_fts_tcol      = fts_dayavg(ind_nomissing) - detrend_fts_smooth@slope*(climate_yfrac(ind_nomissing)-fts_years(0)-fts_ymid-0.5)
    YYYYMMDD_fts_new = str_split_by_length(tostring(climate_time(ind_nomissing)),2)
    fts_months_new = toint(YYYYMMDD_fts_new(:,2))

printVarSummary(detrend_fts_smooth)
;exit
  ; -------------------------------
  ; CLIMATOLOGICAL DAY AVERAGES 
  ; ------------------------------- 
  if (location.eq."Darwin") then
    fts_climate_time = yyyymmdd_time(toint(fts_years(0)), toint(fts_years(dimsizes(fts_years)-1)), "integer")
  else
    fts_climate_time = yyyymmdd_time(year_s, toint(fts_years(dimsizes(fts_years)-1)), "integer")
  end if
    fts_climate_doy = yyyymmdd_to_yyyyddd(fts_climate_time)
    fts_climate_yfrac = yyyymmdd_to_yyyyfrac(fts_climate_time, 0.5)

    fts_array = new((/dimsizes(fts_climate_time),1,1/),double)   ;needs to be 3D for climate calculations
    fts_array(ind_nomissing,0,0) = detrend_fts_tcol
    fts_ClmDay = clmDayTLL(fts_array, fts_climate_doy)         ; daily climatology at each grid point

  ; -------------------------------
  ; SPLINE FIT TO FILL MISSING VALUES
  ; -------------------------------
    ind_data_fts = ind(.not.ismissing(fts_ClmDay(:,0,0)))
    xii = Clm_doy(ind_data_fts)
    yii = fts_ClmDay(ind_data_fts,0,0)
    xoo = Clm_doy
    yoo = ftcurv(xii, yii, xoo)
    new_fts_ClmDay = fts_ClmDay
    new_fts_ClmDay = where(ismissing(fts_ClmDay(:,0,0)),yoo,fts_ClmDay(:,0,0))

  ; -------------------------------
  ; CLIMATOLOGOCAL MONTHLY STDDEV
  ; -------------------------------
    climate_fts_day_sd = new((/dimsizes(Clm_doy),1,1/), float)
    do kk=0,11
      month_ind := ind(fts_months_new.eq.(kk+1))
      mm_ind    := ind(toint(split_mm(:,2)).eq.(kk+1))
      co_to_avg := detrend_fts_tcol(month_ind)
      climate_fts_day_sd(mm_ind,0,0) = dim_stddev_n(tofloat(co_to_avg),0)
    end do
    climate_fts_day_sd!0 = "year_day"
    climate_fts_day_sd&year_day = Clm_doy

  ; -------------------------------
  ; SMOOTHED DAILY CLIMATOLOGY AND
  ; MONTH STDDEV USING 2 HARMONCS  
  ; -------------------------------
    fts_ClmDay_sm = smthClmDayTLL(new_fts_ClmDay, 2)  
    fts_ClmDaysd_sm = smthClmDayTLL(climate_fts_day_sd, 2)

  ; -------------------------------
  ; EXPAND TO WHOLE TIME PERIOD
  ; -------------------------------
    fts_split_doy = str_split_by_length(tostring(fts_climate_doy),4)
    fts_day_climate    = new(dimsizes(fts_climate_time),double)
    fts_day_climate_sm = new(dimsizes(fts_climate_time),double)
    fts_day_climate_sd = new(dimsizes(fts_climate_time),double)
    do d=0,dimsizes(fts_climate_doy)-1
      clm_index = toint(fts_split_doy(d,1))
      fts_day_climate(d)=fts_ClmDay(clm_index-1,0,0)
      fts_day_climate_sm(d)=fts_ClmDay_sm(clm_index-1,0,0)
      fts_day_climate_sd(d)=fts_ClmDaysd_sm(clm_index-1,0,0)
    end do

  ; -------------------------------
  ; DAILY ANOMALIES
  ; -------------------------------
    fts_day_anom = fts_array(:,0,0)-fts_day_climate_sm

  ; -------------------------------
  ; DETERMINE EVENTS
  ; -------------------------------
    select_fts_events = where(fts_day_anom.gt.(event_scale*fts_day_climate_sd).or.\
                              fts_day_anom.lt.(neg_event*fts_day_climate_sd),fts_day_anom,fts_day_anom@_FillValue)
    ind_f_events = ind(.not.ismissing(select_fts_events))
    f_events = fts_climate_time(ind_f_events)

  end if ;(PLOTFTS)


; -------------------------------
; COMBINE SIGNIFICANT ANOMALIES
; FOR PLOTTING
; -------------------------------

  ; MOPITT
  ind_eventtime = new(dimsizes(m_events), integer)
  combined_events = m_events
  combined_events@_FillValue = default_fillvalue("integer")
   do i=0, dimsizes(m_events)-1
      ind_eventtime(i) = ind(climate_time.eq.m_events(i))
   end do
   do j=1, dimsizes(m_events)-1
     if (ind_eventtime(j).ge.(ind_eventtime(j-1)+8)) then
        ; Keep event
        continue
     else
        combined_events(j) = combined_events@_FillValue
     end if
   end do
   remove_events = ind(.not.ismissing(combined_events))
   m_events_new = combined_events(remove_events)

  ; FTS
  ind_f_eventtime = new(dimsizes(f_events), integer)
  combined_f_events = f_events
  combined_f_events@_FillValue = default_fillvalue("integer")
   do i=0, dimsizes(f_events)-1
      ind_f_eventtime(i) = ind(climate_time.eq.f_events(i))
   end do
   do j=1, dimsizes(f_events)-1
     if (ind_f_eventtime(j).ge.(ind_f_eventtime(j-1)+8)) then
        ; Keep event
        continue
     else
        combined_f_events(j) = combined_f_events@_FillValue
     end if
   end do
   remove_f_events = ind(.not.ismissing(combined_f_events))
   f_events_new = combined_f_events(remove_f_events)

  ; MANUAL ADJUSTMENT
  if (location.eq."Darwin") then
    ; No separate adjustment
  else if (location.eq."Lauder") then
    if (network.eq."TCCON") then 
       manual_fts_times = where(f_events_new.gt.20151227.and.\
                               f_events_new.lt.20160201,f_events_new@_FillValue,f_events_new)
     else
       manual_fts_times = where(f_events_new.gt.20160114.and.\
                               f_events_new.lt.20160201,f_events_new@_FillValue,f_events_new)
     end if
     f_events_new := manual_fts_times((ind(.not.ismissing(manual_fts_times))))
  else if (location.eq."Wollongong") then
    if (network.eq."TCCON") then 
       manual_fts_times = where(f_events_new.gt.20100106.and.\
                               f_events_new.lt.20100128,f_events_new@_FillValue,f_events_new)
       manual_fts_times = where(manual_fts_times.gt.20100705.and.\
                               manual_fts_times.lt.20100727,manual_fts_times@_FillValue,manual_fts_times)
       manual_fts_times = where(manual_fts_times.gt.20100921.and.\
                               manual_fts_times.lt.20101021,manual_fts_times@_FillValue,manual_fts_times)
       manual_fts_times = where(manual_fts_times.gt.20130408.and.\
                               manual_fts_times.lt.20130430,manual_fts_times@_FillValue,manual_fts_times)
       manual_fts_times = where(manual_fts_times.gt.20130711.and.\
                               manual_fts_times.lt.20130802,manual_fts_times@_FillValue,manual_fts_times)
       manual_fts_times = where(manual_fts_times.gt.20140703.and.\
                               manual_fts_times.lt.20140715,manual_fts_times@_FillValue,manual_fts_times)
     else
       manual_fts_times = where(f_events_new.gt.20021120.and.\
                               f_events_new.lt.20021210,f_events_new@_FillValue,f_events_new)
       manual_fts_times = where(manual_fts_times.gt.20050906.and.\
                               manual_fts_times.lt.20050925,manual_fts_times@_FillValue,manual_fts_times)
       manual_fts_times = where(manual_fts_times.gt.20130510.and.\
                               manual_fts_times.lt.20130527,manual_fts_times@_FillValue,manual_fts_times)
     end if
     f_events_new := manual_fts_times((ind(.not.ismissing(manual_fts_times))))
     manual_m_times = where(m_events_new.gt.20030121.and.\
                               m_events_new.lt.20030210,m_events_new@_FillValue,m_events_new)
     m_events_new := manual_m_times((ind(.not.ismissing(manual_m_times))))
  end if
  end if
  end if

;--------------------------------------------
; print interesting station values
;--------------------------------------------
  perc_trend = (detrend_mopitt_smooth@slope/(avg(detrend_mopitt_smooth)))*100
  perc_fts_trend = (detrend_fts_smooth@slope/(avg(detrend_fts_smooth)))*100
  print("MOPITT trend for "+location+" = "+perc_trend+" %")
  print("FTS trend for "+location+" = "+perc_fts_trend+" %")
  print("MOPITT event dates for "+location+" = ")
  print("  " + m_events + " " + sprintf("%7.3e", day_anom(ind_eventtime)))
  print("FTS event dates for "+location+" = ")
  print("  " + f_events + " " + sprintf("%7.3e", fts_day_anom(ind_f_eventtime)))

;above_top = ind(fts_dayavg.ge.3.8e18)
;print(fts_dayavg(above_top))
;print(climate_time(above_top))


;********************************************
;--------------------------------------------
; plot
;--------------------------------------------
if (PLOT) then

  wks = gsn_open_wks(plttype,pltname)        
  gsn_define_colormap(wks,"BlAqGrYeOrRe")  
   
  res                       = True                      ; plot mods desired
    res@gsnDraw		    = False	                ; don't draw it yet
    res@gsnFrame            = False                     ; don't advance frame

    res@trYMinF             = 0.6e18
    ; MAX for Different stations
    if (location.eq."Darwin") then
       res@trYMaxF             = 3.8e18
       res@trYMinF             = 0.8e18
       loc_labels              = 3.6e18
    else if (location.eq."Lauder") then
       res@trYMaxF             = 3.0e18
       res@trYMinF             = 0.4e18
       loc_labels              = 2.8e18
    else if (location.eq."Wollongong") then
       res@trYMaxF             = 3.8e18
       res@trYMinF             = 0.8e18
       loc_labels              = 3.6e18
    else
       res@trYMaxF             = 3.5e18
       loc_labels              = 3.2e18
    end if
    end if
    end if
    res@trXMinF             = tofloat(year_s)-0.5
    res@trXMaxF             = tofloat(year_e)+0.5
    ;res@trXMinF             = 2002
    ;res@trXMaxF             = 2003.5

    res@tmYLMode        = "Manual"	
      res@tmYLTickStartF  = 0.5e18
      res@tmYLTickEndF    = 4.5e18
      res@tmYLTickSpacingF= 0.5e18

    res@tmXBMode        = "Manual"
      res@tmXBTickStartF  = year_s
      res@tmXBTickEndF    = year_e
      res@tmXBTickSpacingF= 2
      ;res@tmLabelAutoStride=True
      res@tmXBMinorPerMajor  = 1	
      res@tmXBBorderOn    = False
      res@tmXBLabelsOn = False
      res@tmXBLabelFontHeightF = 0.05

    res@tmYLMajorOutwardLengthF = 0.0               ; draw tickmarks inward
    res@tmYLMinorOutwardLengthF = 0.0               ; draw minor ticks inward
    res@tmXBMajorOutwardLengthF = 0.0               
    res@tmXBMinorOutwardLengthF = 0.0              

    res@vpWidthF             = 1.5
    res@vpHeightF            = 0.4          ; set height of plot

    res@tiMainString        = ""
    res@tiXAxisString       = "Year"

  ; -------------------------------
  ; timeseries - weekly averages and climatology
  ; -------------------------------
  ; MOPITT
  ; daily averages
    res@tiYAxisString       = "CO Column (molec. cm~S2~-2  )"
    res@xyMarkLineMode      = "Markers"
    res@xyMarkerSizeF       = 0.04
    res@xyMarker            = 17
    res@xyMarkerOpacityF    = 0.8
    res@xyMarkerColor       = "red"
   plot1 = gsn_csm_xy(wks,day_yfrac,mopitt_tcol,res)

    res@tiYAxisString       = ""
    res@xyMarkLineMode      = "Lines"
    res@xyLineThicknessF    = 5.5
    res@xyLineColor         = "red3"
  plot2 = gsn_csm_xy(wks,climate_yfrac, mopitt_day_climate_sm,res)
  overlay(plot1, plot2)

  if (PLOTFTS) then
  ; FTS
  ;plottime1 = week_fts_avg_yfrac
    res@xyMarkLineMode      = "Markers"
    res@xyMarkerSizeF       = 0.006
    res@xyMarkerThicknessF  = 3
    res@xyMarker            = 5
    res@xyMarkerOpacityF    = 0.5
    res@xyMarkerColor       = "blue"
  plot1b = gsn_csm_xy(wks,climate_yfrac,fts_dayavg,res)
  overlay(plot1, plot1b)

    res@xyMarkLineMode      = "Lines"
    res@xyLineThicknessF    = 5.5
    res@xyLineColor         = "blue3"
  plot2b = gsn_csm_xy(wks,fts_climate_yfrac,fts_day_climate_sm,res)
  overlay(plot1, plot2b)

  end if ;(PLOTFTS)

  ; -------------------------------
  ; Anomaly plot FTS
  ; -------------------------------
    res@xyLineThicknessF    = 3.0
    res@xyLineColor         = "blue"
    res@trYMinF             = -0.8e18
      res@tmYLTickStartF    = -1.5e18
      res@tmYLTickSpacingF  = 0.5e18
    ; MAX for Different stations
    if (location.eq."Darwin") then
       res@trYMaxF             = 2.0e18
       res@tmYLTickEndF        = 1.5e18
       res@tmYLTickSpacingF    = 1.0e18
    else if (location.eq."Lauder") then
       res@trYMaxF             = 1.2e18
       res@tmYLTickEndF        = 0.5e18
    else if (location.eq."Wollongong") then
       res@trYMaxF             = 2.5e18
       res@tmYLTickEndF        = 1.5e18
       res@tmYLTickSpacingF    = 1.5e18
    else
       res@trYMaxF             = 1.2e18
       res@tmYLTickEndF        = 0.5e18
    end if
    end if
    end if

      ;res@tmYLLabelsOn     = False
      ;res@tmYRLabelsOn     = True
    res@vpHeightF            = .15         ; set height of plot

  if (PLOTFTS) then
   res@gsnYRefLine           = 0.              ; reference line   
   res@gsnXYBarChart         = True            ; create bar chart 
   plot4 = gsn_csm_xy(wks,fts_climate_yfrac, fts_day_anom,res)

  ; -------------------------------
  ; Add standard deviation
  ; -------------------------------
   res@gsnXYBarChart         = False            ; create bar chart 
    ya    = new( (/2*dimsizes(fts_climate_yfrac)/), float )
    yb    = new( (/2*dimsizes(fts_climate_yfrac)/), float )
    do k=0,dimsizes(fts_climate_yfrac)-1
      ya(k) = fts_climate_yfrac(k)
      yb(k) = tofloat(fts_day_climate_sd(k))
      yb(2*dimsizes(fts_climate_yfrac)-1-k) = 0-tofloat(fts_day_climate_sd(k))
      ya(2*dimsizes(fts_climate_yfrac)-1-k) = fts_climate_yfrac(k)
    end do
    gsres                          = True                ; poly res
      gsres@gsFillColor            = "blue"         ; color chosen
      gsres@gsFillOpacityF         = 0.3                 
      gsres@tfPolyDrawOrder        = "PostDraw"              ; send to back
      dumsd_a = gsn_add_polygon(wks,plot4,ya,yb,gsres)

    ;yaa    = new( (/2*dimsizes(climate_yfrac)/), float )
    ;ybb    = new( (/2*dimsizes(climate_yfrac)/), float )
    ;do k=0,dimsizes(climate_yfrac)-1
    ;  yaa(k) = climate_yfrac(k)
    ;  ybb(k) = tofloat(event_scale*fts_day_climate_sd(k))
    ;  ybb(2*dimsizes(climate_yfrac)-1-k) = 0+tofloat(neg_event*fts_day_climate_sd(k))
    ;  yaa(2*dimsizes(climate_yfrac)-1-k) = climate_yfrac(k)
    ;end do
    ;gsres                          = True                ; poly res
    ;  gsres@gsFillColor            = "blue"         ; color chosen
    ;  gsres@gsFillOpacityF         = 0.1                 
    ;  dumsd_b = gsn_add_polygon(wks,plot4,yaa,ybb,gsres)

  else
    plot4 = plot2b
  end if ;(PLOTFTS)

 ; add zero line 
  res_lines                   = True                     ; polyline mods desired
    res_lines@gsLineDashPattern = 0                 ; line style
    res_lines@gsLineThicknessF  = 2.5                     ; line thicker
    res_lines@gsLineColor       = "black"                 ; line color
    ;res_lines@tfPolyDrawOrder   = "PreDraw"              ; send to back
  xx = (/year_s,year_e/)
  yy = (/0,0/)
  dum1 = gsn_add_polyline(wks,plot4,xx,yy,res_lines)      ; add polyline


  ; -------------------------------
  ; Anomaly plot MOPITT
  ; -------------------------------
    res@tiYAxisString       = "Anomaly"
    res@xyLineColor         = "red"
    res@xyLineThicknessF    = 3.0
    res@tmXBBorderOn        = True
    res@tmXBLabelsOn        = True
    res@vpHeightF           = .15              ; set height of plot
 
   res@gsnYRefLine           = 0.              ; reference line   
   res@gsnXYBarChart         = True            ; create bar chart 
   plot5 = gsn_csm_xy(wks,climate_yfrac, day_anom,res)

  ; -------------------------------
  ; Add standard deviation
  ; -------------------------------
   res@gsnXYBarChart         = False            ; create bar chart 

  ;daily
  ; define a polygon for std-dev
   ya2    = new( (/2*dimsizes(climate_yfrac)/), double )
   yb2    = new( (/2*dimsizes(climate_yfrac)/), double )
   do k=0,dimsizes(climate_yfrac)-1
     ya2(k) = climate_yfrac(k)
     yb2(k) = mopitt_day_climate_sd(k)
     yb2(2*dimsizes(climate_yfrac)-1-k) = 0-mopitt_day_climate_sd(k)
     ya2(2*dimsizes(climate_yfrac)-1-k) = climate_yfrac(k)
   end do
    gsres                          = True                ; poly res
    gsres@gsFillColor            = "Red"         ; color chosen
    gsres@gsFillOpacityF         = 0.2                 
    dum2 = gsn_add_polygon(wks,plot5,ya2,yb2,gsres)

 ; add zero line
  dum3 = gsn_add_polyline(wks,plot5,xx,yy,res_lines)      ; add polyline

  ; -------------------------------
  ; HIGHLIGHT ANOMALIES
  ; -------------------------------
   plottime_m_events_new = yyyymmdd_to_yyyyfrac(m_events_new,0.5)
   ya22    = new( (/4*dimsizes(m_events_new)/), float )
   yb22    = new( (/4*dimsizes(m_events_new)/), float )
   do l=0,dimsizes(m_events_new)-1
     yb22(l*4) = -1e18
     yb22(l*4+1) = 5e18
     yb22(l*4+2) = 5e18
     yb22(l*4+3) = -1e18
     ya22(l*4) = plottime_m_events_new(l)-0.05
     ya22(l*4+1) = plottime_m_events_new(l)-0.05
     ya22(l*4+2) = plottime_m_events_new(l)+0.05
     ya22(l*4+3) = plottime_m_events_new(l)+0.05
   end do
  anres                          = True            ; poly res
    anres@gsFillColor            = "orange"         ; color chosen
    anres@tfPolyDrawOrder        = "PreDraw"       ; send to back
    anres@gsFillOpacityF         = 0.3 
    dum4 = gsn_add_polygon(wks,plot1,ya22,yb22,anres)
    dum5 = gsn_add_polygon(wks,plot5,ya22,yb22,anres)
    dum6 = gsn_add_polygon(wks,plot4,ya22,yb22,anres)

  if (PLOTFTS) then    
   plottime_f_events_new = yyyymmdd_to_yyyyfrac(f_events_new,0.5)
   ya33    = new( (/4*dimsizes(f_events_new)/), float )
   yb33    = new( (/4*dimsizes(f_events_new)/), float )
   do l=0,dimsizes(f_events_new)-1
     yb33(l*4) = -1e18
     yb33(l*4+1) = 5e18
     yb33(l*4+2) = 5e18
     yb33(l*4+3) = -1e18
     ya33(l*4) = plottime_f_events_new(l)-0.05
     ya33(l*4+1) = plottime_f_events_new(l)-0.05
     ya33(l*4+2) = plottime_f_events_new(l)+0.05
     ya33(l*4+3) = plottime_f_events_new(l)+0.05
   end do
    anres@gsFillColor            = "lightblue"         ; color chosen
    anres@gsFillOpacityF         = 0.5 
    dum7 = gsn_add_polygon(wks,plot1,ya33,yb33,anres)
    dum8 = gsn_add_polygon(wks,plot4,ya33,yb33,anres)  
    dum9 = gsn_add_polygon(wks,plot5,ya33,yb33,anres)  

   end if ;(PLOTFTS)

  ; -------------------------------
  ; ADD CUSTOM TEXT
  ; -------------------------------
  ;drawNDCGrid(wks)
  ; STATIONS
  txres                   = True                ; polyline mods desired
  txres@txFontHeightF = 0.022                   ; font smaller. default big
  txres@txJust = "CenterLeft"                   ; font smaller. default big
  txres@txFontColor = "red"
  gsn_text_ndc(wks,"MOPITT "+version+suff,0.78,0.75,txres)
  txres@txFontColor = "blue"
  gsn_text_ndc(wks,"FTS ("+network+")",0.78,0.72,txres)
  txres@txFontColor = "black"
  gsn_text_ndc(wks,location,0.18,0.72,txres)

  ; -------------------------------
  ; LABEL EVENTS
  ; -------------------------------
  if (PLOTFTS) then
    ; COMBINE AND SORT
    event_times_dummy = array_append_record(m_events_new,f_events_new,0)
    qsort(event_times_dummy)
    ind_event= new(dimsizes(event_times_dummy), integer)
    do i=0, dimsizes(event_times_dummy)-1
       ind_event(i) = ind(fts_climate_time.eq.event_times_dummy(i))
    end do
    do k=1, dimsizes(event_times_dummy)-1
      if (ind_event(k).gt.(ind_event(k-1))) then
         ; Keep event
         continue
      else
        event_times_dummy(k) = event_times_dummy@_FillValue
      end if
    end do
    event_times = event_times_dummy(ind(.not.ismissing(event_times_dummy)))
  else
    event_times = m_events_new
  end if

  print("All main events:")
  print(" " + event_times)

  ; MANUAL ADJUSTMENT
  if (location.eq."Darwin") then
    if (suff.eq."J") then 
      manual_times = where(event_times.gt.20061116.and.\
                                event_times.lt.20061206,event_times@_FillValue,event_times)
      event_times := manual_times((ind(.not.ismissing(manual_times))))
    end if
  else if (location.eq."Lauder") then
    if (network.eq."TCCON") then 
      manual_times = where(event_times.gt.20101005.and.\
                           event_times.lt.20101023,event_times@_FillValue,event_times)
    else
      manual_times = where(event_times.gt.20101012.and.\
                           event_times.lt.20101023,event_times@_FillValue,event_times)
    end if
    manual_times = where(manual_times.gt.20140118.and.\
                                manual_times.lt.20140212,manual_times@_FillValue,manual_times)
    event_times := manual_times((ind(.not.ismissing(manual_times))))
  else if (location.eq."Wollongong") then
    if (network.eq."NDACC".and.suff.eq."J") then 
      manual_times = where(event_times.gt.20011227.and.\
                             event_times.lt.20011230,event_times@_FillValue,event_times)
      manual_times = where(manual_times.gt.20030121.and.\
                             manual_times.lt.20030208,manual_times@_FillValue,manual_times)
      manual_times = where(manual_times.gt.20041012.and.\
                             manual_times.lt.20041014,manual_times@_FillValue,manual_times)
      manual_times = where(manual_times.gt.20050906.and.\
                             manual_times.lt.20050908,manual_times@_FillValue,manual_times)
      event_times := manual_times((ind(.not.ismissing(manual_times))))
    end if
  end if
  end if
  end if

  print("****************")
  print(" " + event_times)

  event_time_plot = yyyymmdd_to_yyyyfrac(event_times,0.5)
  event_label = (/"a", "b", "c" , "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z","a1", "b1", "c1" , "d1", "e1", "f1", "g1", "h1", "i1", "j1", "k1", "l1", "m1", "n1", "o1", "p1"/)

  tres       =  True
  tres@txFontHeightF = 0.018
  tres@txJust = "CenterLeft"
     text=gsn_add_text(wks,plot1,event_label(0:dimsizes(event_times)-1),event_time_plot(0:dimsizes(event_times)-1),loc_labels,tres)



  ; -------------------------------
  ; PANEL PLOTS
  ; -------------------------------
  res1                     = True
    res1@gsnAttachBorderOn   = False
    res1@tiYAxisFontHeightF  = 0.016
  res2                     = True
    res2@gsnMaximize         = True
    res2@gsnAttachPlotsXAxis = True
    res2@tiXAxisFontHeightF  = 0.016
    res2@tiYAxisFontHeightF  = 0.016
    ;res2@tmXBMode            = "Explicit"
    ;res2@tmXBValues         = tofloat(ispan(year_s,year_e,1))
    ;res2@tmXBLabels         = (/"2006", "2007", "2008", "2009", "2010"/)

  ; plot1 will be the base plot.
  amid = gsn_attach_plots(plot1,(/plot4, plot5/),res1,res2)

  psres = True                                                               
  maximize_output(wks,psres)

end if

;--------------------------------------------
; Write out to a ASCII file
;--------------------------------------------
if (ASCII) then
  ; saves MOPITT events


end if ;ASCII


end

