;=======================================================;
;  calc_seasonal_cycle.ncl 
;=======================================================;
;
; Concepts illustrated:
;   - Calculate average seasonal cycles
;
;   To run type:
; To use call within another ncl program:
;          > seasonal_cycle(data_array,time_array,ystart,yend)
;                                      RRB April 19, 2018
;=======================================================;
undef("calc_seasonal_cycle")

function calc_seasonal_cycle(valIN[*]:numeric, timeIN[*]:numeric, ystartIN:numeric, yendIN:numeric, smoothIN:numeric)
;============================================
; Purpose: calculate a smooth seasonal cycle
;          and associated standard deviation (or 98th percentile?)
; 
; Arguments:
;    valIN: Values associated with the time array
;
;    timeIN: The native time array of the values
;            Must be in "time since ..."
;
;    ystartIN: Year the average seasonal cycle starts 
;            
;    yendIN: Year the average seasonal cycle ends      
;
; Return Value:
;    valOUT: Seasonal cycle averaged over the whole dataset
;
;============================================
local date, years, months, days, yyyymmdd, day_yfrac, ymid, smooth_val, detrend_val_smooth, detrend_val, climate_time, climate_doy

begin

  ; check input
  if (dimsizes(valIN).ne.dimsizes(timeIN)) then
    print("calc_seasonal_cycle: Cannot calculate, the input time and variables have different dimensions.")
    return
  end if

  if (.not. isvar("smoothIN")) then        ; is NRT=<boolean> from command line?
       smoothIN = 230
  end if

  ;--------------------------------------------
  ; DATE MANIPULATIONS
  ;--------------------------------------------
  date    = cd_calendar(timeIN, 0)
      years  = floattointeger(date(:,0))
      months = floattointeger(date(:,1))
      days   = floattointeger(date(:,2))
  yyyymmdd       = cd_calendar(timeIN, 2)
  day_yfrac      = cd_calendar(timeIN, 4)

  ; -------------------------------
  ; DETREND
  ; ------------------------------- 
    ymid = (tofloat(yendIN-ystartIN))/2

    smooth_val         = runave(valIN,smoothIN,0)
    detrend_val_smooth = dtrend_msg_n (day_yfrac,smooth_val,False,True,0)
    detrend_val  = valIN - detrend_val_smooth@slope*(day_yfrac-ystartIN-ymid-0.5)

 ; -------------------------------
  ; CLIMATOLOGICAL DAY AVERAGES 
  ; ------------------------------- 
    climate_time = yyyymmdd_time(toint(ystartIN), toint(yendIN), "integer")
    climate_doy = yyyymmdd_to_yyyyddd(climate_time)
    val_array = new((/dimsizes(climate_time),1,1/),double)   ;needs to be 3D for climate calculations
    do j=0,dimsizes(climate_time)-1
      ind_avail := ind(yyyymmdd.eq.climate_time(j))
      if (.not.ismissing(ind_avail(0)))then
        val_array(j,0,0) = detrend_val(ind_avail)
      end if
    end do

   val_ClmDay = clmDayTLL(val_array, climate_doy)         ; daily climatology at each grid point

  ; -------------------------------
  ; SPLINE FIT TO FILL MISSING VALUES
  ; -------------------------------
    ind_data = ind(.not.ismissing(val_ClmDay(:,0,0)))
    Clm_doy = val_ClmDay&year_day                            ;366 days in climate year
    xi = Clm_doy(ind_data)
    yi = val_ClmDay(ind_data,0,0)
    xo = Clm_doy
    yo = ftcurv(xi, yi, xo)
    new_val_ClmDay = val_ClmDay
    new_val_ClmDay = where(ismissing(val_ClmDay(:,0,0)),yo,val_ClmDay(:,0,0))

  ; -------------------------------
  ; CLIMATOLOGOCAL MONTHLY STDDEV
  ; -------------------------------
    climate_year = yyyyddd_to_yyyymmdd(2004000+Clm_doy)        ; use dummy leap year to convert to month
    split_mm =str_split_by_length(tostring(climate_year),2)
    climate_val_day_sd = new((/dimsizes(Clm_doy),1,1/), double)
    do kk=0,11
      month_ind := ind(months.eq.(kk+1))
      mm_ind    := ind(toint(split_mm(:,2)).eq.(kk+1))
      val_to_avg := detrend_val(month_ind)
      climate_val_day_sd(mm_ind,0,0) = dim_stddev_n(tofloat(val_to_avg),0)
    end do
    climate_val_day_sd!0 = "year_day"
    climate_val_day_sd&year_day = Clm_doy

  ; -------------------------------
  ; SMOOTHED DAILY CLIMATOLOGY AND
  ; MONTH STDDEV USING 2 HARMONCS  
  ; -------------------------------
    val_ClmDay_sm = smthClmDayTLL(new_val_ClmDay, 2)  
    val_ClmDaysd_sm = smthClmDayTLL(climate_val_day_sd, 2)

    valCOMB = new((/dimsizes(Clm_doy),2/),double)
      valCOMB(:,0) = val_ClmDay_sm(:,0,0)
      valCOMB(:,1) = val_ClmDaysd_sm(:,0,0)

  ; -------------------------------
  ; RETURN VALUES 
  ; -------------------------------
  valOUT = valCOMB
  return(valOUT)

end

