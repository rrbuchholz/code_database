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
  location = "Lauder"
  surface = "land"
  year_s = 2002

  ;------------
  ; scale of outside sd
  ; to denote event
  ;------------
    event_scale = 2.5
    neg_event = -2.5

  ;------------
  ; toggles
  ;------------
  PLOT           = True
    plttype      = "x11"
    ;plttype@wkPaperSize = "A4"
    ;plttype@wkWidth = 0.5
    ;plttype@wkHeight = 0.5
    year_e = 2017

  
  PLOTFTS        = False
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
  if (sm_location.eq."lauder") then
    fts_files =  systemfunc ("ls /IASI/home/buchholz/FTS_data/NDACC/co/"+sm_location+"/co_lauder_2001_2016.hdf")
  else if (sm_location.eq."darwin") then
    fts_files =  systemfunc ("ls /IASI/home/buchholz/FTS_data/TCCON/co/"+sm_location+"/db20050828_20131230.public.nc")
  else
    fts_files =  systemfunc ("ls /IASI/home/buchholz/FTS_data/NDACC/co/"+sm_location+"/groundbased_ftir.co_*.hdf")
  end if
  end if


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
    mopitt_time    = fin->$timearray$(year_select_ind)     
     ; local time in seconds since 1993-1-1 00:00:00 (TAI93)
    mopitt_date    = cd_calendar(mopitt_time, 0)
      years  = floattointeger(mopitt_date(:,0))
      months = floattointeger(mopitt_date(:,1))
      days   = floattointeger(mopitt_date(:,2))
    doy            = day_of_year(years,months,days)
    yyyymmdd       = cd_calendar(mopitt_time, 2)
    day_yfrac      = cd_calendar(mopitt_time, 4)

  if (PLOTFTS) then
  ; -------------------------------
  ; FTS
  ; -------------------------------
  fts_in = addfiles (fts_files, "r")
  ListSetType (fts_in, "cat")             ; concatenate or "merge" (default)
  ;fts_in = addfile(fts_file, "r")

  if (sm_location.eq."darwin") then
    print("***Reading FTS data at " + location)
    fts_xco            = fts_in[:]->$"xco_ppb"$
    fts_psurf          = fts_in[:]->$"pout_hPa"$
    ; convert xCO to tcol
    fts_tcol = (xp_const * fts_xco) * fts_psurf
    ; Date in MJD2000, fraction of days since 
    ; 1970/1/1 00:00:00
    fts_mjd2000         = fts_in[:]->$"time"$
    fts_local           = fts_mjd2000+(time_diff/24.)
    fts_local@units   = "days since 1970-01-01 00:00:0.0"

  else
    print("***Reading FTS data at " + location)
    fts_mjd2000_dummy      = fts_in[:]->$fts_datetime$
    fts_local_dummy        = fts_mjd2000_dummy +(time_diff/24.)
    fts_local_dummy@units   = "days since 2000-01-01 00:00:0.0"
    fts_date_dummy         = cd_calendar(fts_local_dummy , 0)
    fts_years_dummy = floattointeger(fts_date_dummy(:,0))
    year_select_fts = ind(fts_years_dummy.ge.year_s)

    print(fts_years_dummy(0:10))

    fts_tcol_dummy            = fts_in[:]->$fts_tracer$
    fts_tcol = fts_tcol_dummy(year_select_fts)
    copy_VarMeta(fts_tcol_dummy, fts_tcol)
    ; Date in MJD2000, fraction of days since 
    ; Jan 1st, 2000, 00:00:00
    fts_mjd2000         = fts_mjd2000_dummy(year_select_fts)
    copy_VarMeta(fts_mjd2000_dummy, fts_mjd2000)
    fts_local           = fts_mjd2000+(time_diff/24.)
    fts_local@units   = "days since 2000-01-01 00:00:0.0"
   end if

  fts_date            = cd_calendar(fts_local, 0)
  fts_years = floattointeger(fts_date(:,0))
  fts_months = floattointeger(fts_date(:,1))
  fts_days = floattointeger(fts_date(:,2))
    fts_doy            = day_of_year(fts_years,fts_months,fts_days)
  fts_yyyymmdd         = cd_calendar(fts_local, 2)

;printVarSummary(fts_tcol)
;print(fts_tcol(0:20))
   end if ;(PLOTFTS)

  ;--------------------------------------------
  ; calculate averages - separate into weeks, 
  ; months and anomalies
  ;--------------------------------------------
  ;********************************************
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  ; -------------------------------
  ; DETREND
  ; ------------------------------- 
    startyear = years(0)
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
        mopitt_array(j,0,0) = mopitt_tcol(ind_avail)
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
  ; SMOOTHED DAILY CLIMATOLOGY 
  ; USING 2 HARMONCS  
  ; -------------------------------
   mopitt_ClmDay_sm = smthClmDayTLL(new_mopitt_ClmDay, 3)  
  ; printVarSummary(mopitt_ClmDay_sm)

  ; -------------------------------
  ; CLIMATOLOGOCAL MONTHLY STD-DEV
  ; -------------------------------
  climate_mopitt_month_sd = new((/12/), float)
  do k=0,11
     month_ind := ind(months.eq.(k+1))
     co_to_avg := mopitt_tcol(month_ind)
     climate_mopitt_month_sd(k) = dim_stddev_n(co_to_avg,0)
  end do ;k=0,11

  ; -------------------------------
  ; EXPAND TO WHOLE TIME PERIOD
  ; -------------------------------
    split_doy = str_split_by_length(tostring(climate_doy),4)
    mopitt_day_climate_sm = new(dimsizes(climate_time),double)
    mopitt_day_climate_sd = new(dimsizes(climate_time),double)
    do d=0,dimsizes(climate_doy)-1
      clm_index = toint(split_doy(d,1))
      mopitt_day_climate_sm(d)=mopitt_ClmDay_sm(clm_index-1,0,0)
    end do

    test_month = str_split_by_length(tostring(climate_time), 2)
    do m=0,11
      ind_months := ind(toint(test_month(:,2)).eq.m+1)
      mopitt_day_climate_sd(ind_months)=climate_mopitt_month_sd(m)
    end do

  ; -------------------------------
  ; DAILY ANOMALIES
  ; -------------------------------
   day_anom = mopitt_array(:,0,0)-mopitt_day_climate_sm


  ; -------------------------------
  ; PLOT CAPTURING
  ; -------------------------------
    mopitt_day_climateb = new(dimsizes(climate_time),double)
    mopitt_day_climated = new(dimsizes(climate_time),double)
    ;do i=0,dimsizes(climate_time)-1
    do i=0,364
      ;doy_match = mod(i,365)
      mopitt_day_climateb(i)=mopitt_ClmDay(i,0,0)
      ;mopitt_day_climatec(i)=mopitt_ClmDay_sm(i,0,0)
      mopitt_day_climated(i)=new_mopitt_ClmDay(i,0,0)
    end do

    mopitt_day_climatec=mopitt_day_climate_sm

;exit


  ; -------------------------------
  ; CLIMATOLOGICAL MONTH AVERAGES 
  ; and STANDARD DEVIATION
  ; ------------------------------- 
    climate_co   = new((/12/), float)
    climate_co_sd = new((/12/), float)

  do i=0,11
     ; get indices of array related to specific month
     month_ind := ind(months.eq.(i+1))
     co_to_avg := mopitt_tcol(month_ind)

     climate_co(i) = dim_avg_n(co_to_avg,0)
     climate_co_sd(i) = dim_stddev_n(co_to_avg,0)
  end do ;i=0,11

  ; repeat climate values over total time period
  startyear = year_s
  endyear = year_e-1
  climate_time := yyyymm_time(toint(startyear), toint(endyear), "integer")
  years_of_record = endyear - startyear
   climate_co_ext    = new((/toint(years_of_record+1)*12/), float)
   climate_co_sd_ext = new((/toint(years_of_record+1)*12/), float)

  do y = 0, years_of_record
    do m=0,11
     climate_co_ext(y*12+m) = climate_co(m)
     climate_co_sd_ext(y*12+m) = climate_co_sd(m)
    end do
  end do


  ; -------------------------------
  ; WEEK AVERAGES
  ; -------------------------------
   tcol_all_week = week_average(mopitt_tcol,mopitt_time)
   week_time = tcol_all_week&time
   week_yfrac = yyyymmdd_to_yyyyfrac(week_time,0)

   weekly_co_compare = new(dimsizes(tcol_all_week(:,0)), float)
   weekly_sd_compare = new(dimsizes(tcol_all_week(:,0)), float)

   ; -------------------------------
   ; CLIMATOLOGICAL WEEK AVERAGES 
   ; and STANDARD DEVIATION
   ; -------------------------------

printVarSummary(tcol_all_week)

    do m=0,51
      weekly_co_compare(m:dimsizes(week_time)-1:52) = avg(tcol_all_week(m:dimsizes(week_time)-1:52,0))
      weekly_sd_compare(m:dimsizes(week_time)-1:52) = avg(tcol_all_week(m:dimsizes(week_time)-1:52,1))
    end do

print( weekly_co_compare(0:57))
;exit


   ; -------------------------------
   ; ANOMALIES
   ; -------------------------------
   weekly_anomaly = tcol_all_week(:,0)-weekly_co_compare
   weekly_significance = new(dimsizes(tcol_all_week(:,0)), integer)
    do w=0,dimsizes(weekly_anomaly)-1
      weekly_significance(w) = where(weekly_anomaly(w).gt.(weekly_sd_compare(w)*event_scale).or.\
                                     weekly_anomaly(w).lt.(weekly_sd_compare(w)*neg_event),\
                                     week_time(w),weekly_significance@_FillValue)
    end do

printVarSummary(tcol_all_week)

test2 = ind(.not.ismissing(weekly_significance))
print(weekly_significance(test2))

;exit

  ; -------------------------------
  ; WEEK AVERAGES and ANOMALIES
  ; -------------------------------
  do i=0,dimsizes(mopitt_time)-1

       ; calculate week from day of year
       if (doy(i)/7.0.gt.floor(doy(i)/7.0)) then
           week=floor(doy(i)/7.0)+1.0
       else
           week=doy(i)/7.0
       end if

      if (week.eq.53) then 
        week1=52.
        week:=52.
      end if

     ; if date comparisons don't exist set them up
       if (.not.(isdefined("currentweek"))) then
          print("initialising sum")
          currentyear = mopitt_date(i,0)
          currentmonth = mopitt_date(i,1)
          currentweek = week
       end if

     ; collect and average data in weeks
      if (mopitt_date(i,0).eq.currentyear.and.\ 
          week.eq.currentweek) then

         if (.not.(isdefined("week_co"))) then
           week_co = mopitt_tcol(i)
         else
           ; sum if the same date
           print("collecting sum")
           temp0 := week_co
           week_co :=  array_append_record(temp0,mopitt_tcol(i),0)
         end if

      else ; average and append to arrays
         print("calculating average because:")
         print(currentyear+" "+currentweek)
         print("...doesnt match...")
         print(mopitt_date(i,0)+" "+week)
         print("-------------------")


         if (.not.(isdefined("week_co_avg"))) then
           week_co_avg := avg(week_co)
           week_avg_time := currentyear+sprinti("%0.3i",floattointeger(currentweek*7)-6)
           ; anomlay from climatology
           mop_diff := avg(week_co)- climate_co(floattointeger(currentmonth)-1)
           week_anomaly :=  mop_diff
           ; -------------------------------
           ; SIGNIFICANT ANOMALIES
           ; -------------------------------
           ; collect event
           if (mop_diff.ge.event_scale*climate_co_sd(floattointeger(currentmonth)-1).or.\
               mop_diff.le.neg_event*climate_co_sd(floattointeger(currentmonth)-1)) then
              m_event := currentyear+sprinti("%0.3i",floattointeger(currentweek*7)-6)
           end if
         else
           mop_diff := avg(week_co)- climate_co(floattointeger(currentmonth)-1)
           dummy0 := week_co_avg
           dummy1 := week_avg_time
           dummy2 := week_anomaly
           week_co_avg := array_append_record(dummy0,avg(week_co),0)
           week_avg_time:= array_append_record(dummy1,currentyear+sprinti("%0.3i",floattointeger(currentweek*7)-6),0)
           week_anomaly:= array_append_record(dummy2,mop_diff,0)
           ; -------------------------------
           ; SIGNIFICANT ANOMALIES
           ; -------------------------------
           ; collect event
           if (.not.(isdefined("m_event"))) then
             if (mop_diff.ge.event_scale*climate_co_sd(floattointeger(currentmonth)-1).or.\
                 mop_diff.le.neg_event*climate_co_sd(floattointeger(currentmonth)-1)) then
               m_event := currentyear+sprinti("%0.3i",floattointeger(currentweek*7)-6)
             end if
           else
             if (mop_diff.ge.event_scale*climate_co_sd(floattointeger(currentmonth)-1).or.\
                 mop_diff.le.neg_event*climate_co_sd(floattointeger(currentmonth)-1)) then
               dummy3 := m_event
               m_event := array_append_record(dummy3,currentyear+sprinti("%0.3i",floattointeger(currentweek*7)-6),0)
             end if
           end if
         end if

         ; re-initialise comparison dates
         currentyear = mopitt_date(i,0)
         currentmonth = mopitt_date(i,1)
         currentweek = week

         ; re-initialise holding array
         week_co := mopitt_tcol(i)

      end if

      ; scoop up last average
      if (i.eq.dimsizes(mopitt_time)-1) then
         print("calculating last average")
         print("-------------------")
         dummy0 := week_co_avg
         dummy1 := week_avg_time
         dummy2 := week_anomaly
         week_co_avg := array_append_record(dummy0,avg(week_co),0)
         week_avg_time:= array_append_record(dummy1,currentyear+sprinti("%0.3i",floattointeger(currentweek*7)-6),0)
         week_anomaly:= array_append_record(dummy2,avg(week_co)- climate_co(floattointeger(currentmonth)-1),0)
      end if

  end do ;i=0,dimsizes(mopitt_time)-1; WEEK AVERAGES
  ; clean up variables
  delete([/currentyear, currentmonth, currentweek, week_co/])

  week_avg_yyyymmdd = yyyyddd_to_yyyymmdd(stringtointeger(week_avg_time))
  week_avg_yfrac = yyyymmdd_to_yyyyfrac(todouble(week_avg_yyyymmdd),0.5)

  event_yyyymmdd = yyyyddd_to_yyyymmdd(stringtointeger(m_event))
  print("MOPITT events: "+(event_yyyymmdd))
print(weekly_significance(test2))
;printVarSummary(week_co_avg)
;print(week_co_avg-tcol_all_week)

;exit

  if (PLOTFTS) then
  ;********************************************
  ; -------------------------------
  ; FTS
  ; -------------------------------
  ; -------------------------------
  ; CLIMATOLOGICAL MONTH AVERAGES 
  ; and STANDARD DEVIATION
  ; ------------------------------- 
  do ii=0,11
     ; get indices of array related to specific month
     fts_month_ind := ind(fts_months.eq.(ii+1))
     fts_co_to_avg := fts_tcol(fts_month_ind)
     ; if date comparisons don't exist set them up
     if (.not.(isdefined("climate_fts_co"))) then
          print("initialising climate average")
          climate_fts_co = avg(fts_co_to_avg)
          climate_fts_co_sd = stddev(fts_co_to_avg)
     else
          temp0 := climate_fts_co
          temp1 := climate_fts_co_sd
          climate_fts_co :=  array_append_record(temp0,avg(fts_co_to_avg),0)
          climate_fts_co_sd :=  array_append_record(temp1,stddev(fts_co_to_avg),0)
     end if

  end do ;ii=1,12
  
  ; repeat climate values over total time period
  fts_startyear = fts_years(0)
  fts_endyear = fts_years(dimsizes(fts_years)-1)
  years_of_fts_record = fts_endyear - fts_startyear
  do y=fts_startyear,fts_endyear
    do m=0,11
      if (.not.(isdefined("climate_time_fts"))) then
          print("initialising climate average extension")
          climate_fts_co_ext = climate_fts_co(m)
          climate_fts_co_sd_ext = climate_fts_co_sd(m)
          climate_time_fts = y+sprinti("%0.2i",m+1)+"01"
     else
          temp0 := climate_fts_co_ext
          temp1 := climate_fts_co_sd_ext 
          temp2 := climate_time_fts
          climate_fts_co_ext :=  array_append_record(temp0,climate_fts_co(m),0)
          climate_fts_co_sd_ext :=  array_append_record(temp1,climate_fts_co_sd(m),0)
          climate_time_fts :=  array_append_record(temp2,y+sprinti("%0.2i",m+1)+"01",0)
     end if
    end do
  end do

  ; -------------------------------
  ; WEEK AVERAGES and ANOMALIES
  ; -------------------------------
  do i=0,dimsizes(fts_local)-1

       ; calculate week from day of year
       if (fts_doy(i)/7.0.gt.floor(fts_doy(i)/7.0)) then
           fts_week=floor(fts_doy(i)/7.0)+1.0
       else
           fts_week=fts_doy(i)/7.0
       end if

      if (fts_week.eq.53) then 
        fts_week1=52.
        fts_week:=52.
      end if

     ; if date comparisons don't exist set them up
       if (.not.(isdefined("currentweek"))) then
          print("initialising sum")
          currentyear = fts_date(i,0)
          currentmonth = fts_date(i,1)
          currentweek = fts_week
       end if

     ; collect and average data in weeks
      if (fts_date(i,0).eq.currentyear.and.\ 
          fts_week.eq.currentweek) then

         if (.not.(isdefined("fts_week_co"))) then
           fts_week_co = fts_tcol(i)
         else
           ; sum if the same date
           print("collecting sum")
           temp0 := fts_week_co
           fts_week_co :=  array_append_record(temp0,fts_tcol(i),0)
         end if

      else ; average and append to arrays
         print("calculating average because:")
         print(currentyear+" "+currentweek)
         print("...doesnt match...")
         print(fts_date(i,0)+" "+week)
         print("-------------------")


         if (.not.(isdefined("week_fts_co_avg"))) then
           week_fts_co_avg := avg(fts_week_co)
           ;week_avg_time := yyyymmdd(i)
           week_fts_avg_time := currentyear+sprinti("%0.3i",floattointeger(currentweek*7)-6)
           ;week_avg_time := currentweek
           ; anomlay from climatology
           fts_diff := avg(fts_week_co)- climate_fts_co(floattointeger(currentmonth)-1)
           week_anomaly_fts :=  fts_diff

           ; -------------------------------
           ; SIGNIFICANT ANOMALIES
           ; -------------------------------
           ; collect event
           if (fts_diff.ge.event_scale*climate_fts_co_sd(floattointeger(currentmonth)-1).or.\
               fts_diff.le.neg_event*climate_fts_co_sd(floattointeger(currentmonth)-1)) then
              fts_event := currentyear+sprinti("%0.3i",floattointeger(currentweek*7)-6)
           end if
         else
           fts_diff := avg(fts_week_co)- climate_fts_co(floattointeger(currentmonth)-1)
           dummy0a := week_fts_co_avg
           dummy1a := week_fts_avg_time
           dummy2a := week_anomaly_fts
           week_fts_co_avg := array_append_record(dummy0a,avg(fts_week_co),0)
           week_fts_avg_time:= array_append_record(dummy1a,currentyear+sprinti("%0.3i",floattointeger(currentweek*7)-6),0)
           week_anomaly_fts:= array_append_record(dummy2a,fts_diff,0)
           ; -------------------------------
           ; SIGNIFICANT ANOMALIES
           ; -------------------------------
           ; collect event
           if (.not.(isdefined("fts_event"))) then
             if (fts_diff.ge.event_scale*climate_fts_co_sd(floattointeger(currentmonth)-1).or.\
               fts_diff.le.neg_event*climate_fts_co_sd(floattointeger(currentmonth)-1)) then
               fts_event := currentyear+sprinti("%0.3i",floattointeger(currentweek*7)-6)
             end if
           else
             if (fts_diff.ge.event_scale*climate_fts_co_sd(floattointeger(currentmonth)-1).or.\
               fts_diff.le.neg_event*climate_fts_co_sd(floattointeger(currentmonth)-1)) then
               dummy3a := fts_event
               fts_event := array_append_record(dummy3a,currentyear+sprinti("%0.3i",floattointeger(currentweek*7)-6),0)
             end if
           end if
         end if

         ; re-initialise comparison dates
          currentyear = fts_date(i,0)
          currentmonth = fts_date(i,1)
          currentweek = fts_week

         ; re-initialise holding array
         fts_week_co := fts_tcol(i)

      end if

      ; scoop up last average
      if (i.eq.dimsizes(fts_local)-1) then
         print("calculating last average")
         print("-------------------")
         fts_diff := avg(fts_week_co)- climate_fts_co(floattointeger(currentmonth)-1)
         dummy0a := week_fts_co_avg
         dummy1a := week_fts_avg_time
         dummy2a := week_anomaly_fts
         week_fts_co_avg := array_append_record(dummy0a,avg(fts_week_co),0)
         week_fts_avg_time:= array_append_record(dummy1a,currentyear+sprinti("%0.3i",floattointeger(currentweek*7)-6),0)
         week_anomaly_fts:= array_append_record(dummy2a,fts_diff,0)
           ; -------------------------------
           ; SIGNIFICANT ANOMALIES
           ; -------------------------------
           ; collect event
           if (.not.(isdefined("fts_event"))) then
             if (fts_diff.ge.event_scale*climate_fts_co_sd(floattointeger(currentmonth)-1)) then
               fts_event := fts_yyyymmdd(i)
             end if
           else
             if (fts_diff.ge.event_scale*climate_fts_co_sd(floattointeger(currentmonth)-1)) then
               dummy3a := fts_event
               fts_event := array_append_record(dummy3a,fts_yyyymmdd(i),0)
             end if
           end if
      end if

  end do ;i=0,dimsizes(fts_local)-1; WEEK AVERAGES
  ; clean up variables
  delete([/currentyear, currentmonth, currentweek, fts_week_co/])

  week_fts_avg_yyyymmdd = yyyyddd_to_yyyymmdd(stringtointeger(week_fts_avg_time))
  week_fts_avg_yfrac = yyyymmdd_to_yyyyfrac(todouble(week_fts_avg_yyyymmdd),0.5)

  fts_event_yyyymmdd = yyyyddd_to_yyyymmdd(stringtointeger(fts_event))

  print("FTS events: "+(fts_event_yyyymmdd))
end if ;(PLOTFTS)

  print("MOPITT events: "+(event_yyyymmdd))

; -------------------------------
; CULL SIGNIFICANT ANOMALIES
; -------------------------------

; Wollongong
;fts_event_indices = ispan(11,25,1)

;fts_event_dummy = fts_event_yyyymmdd
;fts_event_yyyymmdd := (fts_event_dummy(fts_event_indices))

;m_event_indices = (/7,8,10,11,12,13,14,16,18,\
;                    20,21,23,24,25,26,27,28/)
;m_event_dummy = event_yyyymmdd
;event_yyyymmdd := (m_event_dummy(m_event_indices))


; Darwin
;fts_event_indices = (/5,6,8,9,12/)
;fts_event_dummy = fts_event_yyyymmdd
;fts_event_yyyymmdd := (fts_event_dummy(fts_event_indices))

; Lauder
;fts_event_indices = (/5,6,8,9,12/)
;fts_event_dummy = fts_event_yyyymmdd
;fts_event_yyyymmdd := (fts_event_dummy(fts_event_indices))

;--------------------------------------------
; print spectra vals to see exact
; dates of event
;--------------------------------------------

;ind_event_m = ind(years.eq.2006.and.(months.eq.11.or.months.eq.12))
;ind_event_f = ind(fts_years.eq.2006.and.(fts_months.eq.11.or.fts_months.eq.12))

ind_event_m = ind(years.eq.2006.and.months.eq.11)
;ind_event_f = ind(fts_years.eq.2006.and.fts_months.eq.11)

print("******************************")
print("MOPITT")
print(yyyymmdd(ind_event_m)+": "+mopitt_tcol(ind_event_m))
print("FTS")
;print(fts_yyyymmdd(ind_event_f)+": "+fts_tcol(ind_event_f))
;exit

;--------------------------------------------
; print interesting station values
;--------------------------------------------
perc_trend = (detrend_mopitt_smooth@slope/(avg(detrend_mopitt_smooth)))*100
print("MOPITT trend for "+location+" = "+perc_trend+" %")

;--------------------------------------------
; plot
;--------------------------------------------
if (PLOT) then

  wks = gsn_open_wks(plttype,pltname)        
  gsn_define_colormap(wks,"BlAqGrYeOrRe")  
   
  res                       = True                      ; plot mods desired
    res@gsnDraw		    = False	                ; don't draw it yet
    res@gsnFrame            = False                     ; don't advance frame
    ;res@gsnMaximize         = True

    res@trYMinF             = 0.5e18
    res@trYMaxF             = 3.0e18
    res@trXMinF             = tofloat(year_s)-0.5
    res@trXMaxF             = tofloat(year_e)+0.5
    ;res@trXMinF             = 2002
    ;res@trXMaxF             = 2003.5

    res@tmYLMode        = "Manual"	
      res@tmYLTickStartF  = 0.5e18
      res@tmYLTickEndF    = 3.0e18
      res@tmYLTickSpacingF= 0.5e18

    res@tmXBMode        = "Manual"
    ;res@tmXBMode            = "Explicit"
      ;res@tmXBValues         = tofloat(ispan(year_s,year_e,1))
      ;res@tmXBLabels         = (/"2006", "2007", "2008", "2009"/)
      res@tmXBTickStartF  = year_s
      res@tmXBTickEndF    = year_e
      res@tmXBTickSpacingF= 2
      ;res@tmLabelAutoStride=True
      res@tmXBMinorPerMajor  = 1	
      res@tmXBBorderOn    = False
      res@tmXBLabelsOn = False
      res@tmXBLabelFontHeightF = 0.05

    res@tmYLMajorOutwardLengthF = 0.0               ; draw tickmarks inward
    res@tmYLMinorOutwardLengthF = 0.0                 ; draw minor ticsk inward
    res@tmXBMajorOutwardLengthF = 0.0               
    res@tmXBMinorOutwardLengthF = 0.0              

    ;res@vpWidthF             = 0.7
    res@vpWidthF             = 1.2
    res@vpHeightF            = 0.4          ; set height of plot

    ;res@tiMainString        = location + " MOPITT and FTS timeseries"
    res@tiMainString        = ""
    res@tiXAxisString       = "Year"
    res@tiYAxisString       = "CO Column (molec. cm~S2~-2  )"
  
  ; -------------------------------
  ; timeseries - weekly averages and climatology
  ; -------------------------------
  ; MOPITT
  ; daily averages
    res@xyMarkLineMode      = "Markers"
    res@xyMarkerSizeF       = 0.04
    res@xyMarker            = 17
    res@xyMarkerColor       = "red"
   plot1 = gsn_csm_xy(wks,day_yfrac,mopitt_tcol,res)

    res@xyMarkerSizeF       = 0.02
    res@xyMarkerColor       = "black"
  plot1a = gsn_csm_xy(wks,day_yfrac,detrend_mopitt_tcol,res)
  overlay(plot1, plot1a)

    res@xyMarkLineMode      = "Lines"
    res@xyLineThicknessF    = 5.5
    res@xyLineColor         = "red"
  plot2 = gsn_csm_xy(wks,climate_yfrac, mopitt_day_climate_sm,res)
  overlay(plot1, plot2)

  if (PLOTFTS) then
  ; FTS
  ;plottime1 = week_fts_avg_yfrac
    res@xyMarkLineMode      = "Markers"
    res@xyMarkerColor       = "blue"
  ;plot = gsn_csm_xy(wks,week_fts_avg_yfrac,week_fts_co_avg,res)
  ;plot1 = gsn_csm_xy(wks,week_fts_avg_yfrac,week_fts_co_avg,res)
  overlay(plot1, plot)

    res@xyMarkLineMode      = "Lines"
    res@xyLineThicknessF    = 3.5
    res@xyLineColor         = "blue"
  plottime3 = yyyymmdd_to_yyyyfrac(stringtointeger(climate_time_fts),0.5)
  ;plot3 = gsn_csm_xy(wks,plottime3,climate_fts_co_ext,res)
  overlay(plot1, plot3)
  end if ;(PLOTFTS)

  ; -------------------------------
  ; Anomaly plot FTS
  ; -------------------------------
    res@tiYAxisString       = ""
    res@xyLineThicknessF    = 4.5
    res@trYMinF             = -0.8e18
    res@trYMaxF             = 1.0e18
      res@tmYLTickStartF  = -0.5e18
      res@tmYLTickEndF    = 0.5e18
      res@tmYLTickSpacingF= 0.5e18
      ;res@tmYLLabelsOn     = False
      ;res@tmYRLabelsOn     = True
    res@vpHeightF            = .15         ; set height of plot

  if (PLOTFTS) then
    plot4 = gsn_csm_xy(wks,week_fts_avg_yfrac,week_anomaly_fts,res)


    ; define a polygon for std-dev
    ya    = new( (/2*dimsizes(plottime3)/), float )
    yb    = new( (/2*dimsizes(plottime3)/), float )
    do k=0,dimsizes(plottime3)-1
      ya(k) = plottime3(k)
      yb(k) = climate_fts_co_sd_ext(k)
      yb(2*dimsizes(plottime3)-1-k) = 0-climate_fts_co_sd_ext(k)
      ya(2*dimsizes(plottime3)-1-k) = plottime3(k)
    end do
    gsres                          = True                ; poly res
      gsres@gsFillColor            = "blue"         ; color chosen
      gsres@gsFillOpacityF         = 0.2                 
      dum = gsn_add_polygon(wks,plot4,ya,yb,gsres)

  else
    ;plot4 = gsn_csm_xy(wks,plottime2,climate_co_ext,res)\
     dummy_plot = weekly_co_compare*0
    ;plot4 = gsn_csm_xy(wks,week_yfrac,dummy_plot,res)
  end if ;(PLOTFTS)

 ; add zero line 
  res_lines                   = True                     ; polyline mods desired
    res_lines@gsLineDashPattern = 0                 ; line style
    res_lines@gsLineThicknessF  = 2.5                     ; line thicker
    res_lines@gsLineColor       = "black"                 ; line color
    ;res_lines@tfPolyDrawOrder   = "PreDraw"              ; send to back
  xx = (/year_s,year_e/)
  yy = (/0,0/)
  ;dum1 = gsn_add_polyline(wks,plot4,xx,yy,res_lines)      ; add polyline


  ; -------------------------------
  ; Anomaly plot MOPITT
  ; -------------------------------
    res@tiYAxisString       = "Anomaly"
    res@xyLineColor         = "red"
    res@xyLineThicknessF    = 2.5
    res@tmXBBorderOn        = True
    res@tmXBLabelsOn        = True
    res@vpHeightF           = .15         ; set height of plot
 
   res@gsnYRefLine           = 0.              ; reference line   
   res@gsnXYBarChart         = True            ; create bar chart 
   res@gsnAboveYRefLineColor = "red"           ; above ref line fill red
   res@gsnBelowYRefLineColor = "blue"          ; below ref line fill blue
   plot5 = gsn_csm_xy(wks,climate_yfrac, day_anom,res)

  ; -------------------------------
  ; Add standard deviation
  ; -------------------------------
   res@gsnXYBarChart         = False            ; create bar chart 

  ;daily
  ; define a polygon for std-dev
   ya3    = new( (/2*dimsizes(climate_yfrac)/), double )
   yb3    = new( (/2*dimsizes(climate_yfrac)/), double )
   do k=0,dimsizes(climate_yfrac)-1
     ya3(k) = climate_yfrac(k)
     yb3(k) = mopitt_day_climate_sd(k)
     yb3(2*dimsizes(climate_yfrac)-1-k) = 0-mopitt_day_climate_sd(k)
     ya3(2*dimsizes(climate_yfrac)-1-k) = climate_yfrac(k)
   end do
    gsres                          = True                ; poly res
    gsres@gsFillColor            = "Red"         ; color chosen
    gsres@gsFillOpacityF         = 0.2                 
    dum2 = gsn_add_polygon(wks,plot5,ya3,yb3,gsres)

 ; add zero line
  dum3 = gsn_add_polyline(wks,plot5,xx,yy,res_lines)      ; add polyline



  ; -------------------------------
  ; Combine significant anomalies
  ; that occur in the same month
  ; -------------------------------
  plottime_dummy = yyyymmdd_to_yyyyfrac(todouble(event_yyyymmdd),0.5)
   do l=0,dimsizes(plottime_dummy)-1
     if (.not.(isdefined("plottime4"))) then
       plottime4 := plottime_dummy(l)
     else
       if (plottime_dummy(l).ge.plottime4(dimsizes(plottime4)-1)+0.04) then
         dummy_ev := plottime4
         plottime4 := array_append_record(dummy_ev,plottime_dummy(l),0)
       end if
     end if
   end do

  if (PLOTFTS) then
  plottime_dummy2 = yyyymmdd_to_yyyyfrac(todouble(fts_event_yyyymmdd),0.5)
   do l=0,dimsizes(plottime_dummy2)-1
     if (.not.(isdefined("plottime5"))) then
       plottime5 := plottime_dummy2(l)
     else
       if (plottime_dummy2(l).ge.plottime5(dimsizes(plottime5)-1)+0.04) then
         dummy2_ev := plottime5
         plottime5 := array_append_record(dummy2_ev,plottime_dummy2(l),0)
       end if
     end if
   end do
   end if ;(PLOTFTS)

  ; -------------------------------
  ; Highlight significant anomalies
  ; -------------------------------
   ya2    = new( (/4*dimsizes(plottime4)/), float )
   yb2    = new( (/4*dimsizes(plottime4)/), float )
   do l=0,dimsizes(plottime4)-1
     yb2(l*4) = -1e18
     yb2(l*4+1) = 5e18
     yb2(l*4+2) = 5e18
     yb2(l*4+3) = -1e18
     ya2(l*4) = doubletofloat(plottime4(l))-0.06
     ya2(l*4+1) = doubletofloat(plottime4(l))-0.06
     ya2(l*4+2) = doubletofloat(plottime4(l))+0.06
     ya2(l*4+3) = doubletofloat(plottime4(l))+0.06
   end do
  anres                          = True            ; poly res
    anres@gsFillColor            = "gold"         ; color chosen
    anres@tfPolyDrawOrder        = "PreDraw"       ; send to back
    anres@gsFillOpacityF         = 0.2 
;    dum6 = gsn_add_polygon(wks,plot1,ya2,yb2,anres)
;    dum4 = gsn_add_polygon(wks,plot4,ya2,yb2,anres)              
;    dum5 = gsn_add_polygon(wks,plot5,ya2,yb2,anres)

  if (PLOTFTS) then
   ya3    = new( (/4*dimsizes(plottime5)/), float )
   yb3    = new( (/4*dimsizes(plottime5)/), float )
   do l=0,dimsizes(plottime5)-1
     yb3(l*4) = -1e18
     yb3(l*4+1) = 5e18
     yb3(l*4+2) = 5e18
     yb3(l*4+3) = -1e18
     ya3(l*4) = doubletofloat(plottime5(l))-0.06
     ya3(l*4+1) = doubletofloat(plottime5(l))-0.06
     ya3(l*4+2) = doubletofloat(plottime5(l))+0.06
     ya3(l*4+3) = doubletofloat(plottime5(l))+0.06
   end do
    anres@gsFillColor            = "cyan"         ; color chosen
    anres@gsFillOpacityF         = 0.2 
;    dum7 = gsn_add_polygon(wks,plot1,ya3,yb3,anres)
;    dum8 = gsn_add_polygon(wks,plot4,ya3,yb3,anres)              
;    dum9 = gsn_add_polygon(wks,plot5,ya3,yb3,anres)
   end if ;(PLOTFTS)

  ; -------------------------------
  ; Add custom text
  ; -------------------------------
  ;drawNDCGrid(wks)
  txres                   = True                ; polyline mods desired
  txres@txFontHeightF = 0.022                   ; font smaller. default big
  txres@txJust = "CenterLeft"                   ; font smaller. default big
  txres@txFontColor = "red"
  gsn_text_ndc(wks,"MOPITT",0.8,0.82,txres)
  txres@txFontColor = "blue"
  gsn_text_ndc(wks,"FTS",0.8,0.79,txres)

  ; label events
  event_label = (/"a", "b", "c" , "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z","a1", "b1", "c1" , "d1", "e1", "f1", "g1", "h1", "i1", "j1", "k1", "l1", "m1", "n1", "o1", "p1"/)
  if (PLOTFTS) then
    event_dummy = array_append_record(plottime4,plottime5,0)
  else
    event_dummy = plottime4
  end if

  ; select events greater than 2001
  event_dummy2 = event_dummy(dim_pqsort(event_dummy,1))
  do e_date=0,dimsizes(event_dummy2)-1
    if (event_dummy2(e_date).le.2001.) then
       ; move onto next event
       print("not plotting event " + event_dummy2(e_date))
       continue
    else
      if (.not.(isdefined("event_times"))) then
        event_times := event_dummy2(e_date)
      else
        event_dummy3 := event_times
        event_times := array_append_record(event_dummy3,event_dummy2(e_date),0)
      end if
    end if
  end do

print(event_times)

  tres       =  True
  tres@txFontHeightF = 0.012
  tres@txJust = "CenterLeft"
  ;if (LAUDER) then
   do l_event=0,dimsizes(event_times)-1
     ;text=gsn_add_text(wks,plot1,event_label(l_event),event_times(l_event),2.9e18,tres)
   end do
  ;end if

  ; -------------------------------
  ; panel the plots
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

  ;amid = gsn_attach_plots(plot1,(/plot4, plot5/),res1,res2)
  amid = gsn_attach_plots(plot1,(/plot5/),res1,res2)

  ;panel_res                       = True
  ;panel_res@txString              = "rows x columns"
  ;panel_res@gsnPanelFigureStrings = (/"A","B","C"/)
  ;gsn_panel(wks,(/plot1,plot4,plot5/),(/3,1/),panel_res)
  ;draw(plot1)    ; All three plots will be drawn.
 ; frame(wks)

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

