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
;    timeIN: The native time array of the values, can be in yyyymmdd
;
;    ystartIN: Year the average seasonal cycle starts 
;            
;    yendIN: Year the average seasonal cycle ends      
;
; Return Value:
;    valOUT: Seasonal cycle averaged over the whole dataset
;
;============================================
local date, years, months, days, yyyymmdd, day_yfrac, ystart, ymid, smooth_val, detrend_val_smooth, detrend_val, climate_time, climate_doy, val_array, val_ClmMon

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
    yyyymm = timeIN
    date = str_split_by_length(timeIN,4)
    months = toint(date(:,1))
    day_yfrac = yyyymm_to_yyyyfrac(timeIN, 0.5)

  ; -------------------------------
  ; DETREND
  ; ------------------------------- 
    ystart = toint(date(0,0))
    ymid = (tofloat(yendIN-ystartIN))/2

    smooth_val         = runave(valIN,smoothIN,0)
    detrend_val_smooth = dtrend_msg_n (day_yfrac,smooth_val,False,True,0)
    detrend_val = valIN - detrend_val_smooth@slope*(day_yfrac-ystart-ymid-0.5)

 ; -------------------------------
  ; CLIMATOLOGICAL MONTH AVERAGES 
  ; ------------------------------- 
    climate_time = yyyymm_time(toint(ystartIN), toint(yendIN), "integer")
    val_array = new((/dimsizes(climate_time),1,1/),double)   ;needs to be 3D for climate calculations
    do j=0,dimsizes(climate_time)-1
      ind_avail := ind(yyyymm.eq.climate_time(j))
      if (.not.ismissing(ind_avail(0)))then
        val_array(j,0,0) = detrend_val(ind_avail)
      end if
    end do

    val_array!0 = "time"
    val_array!1 = "lat"
    val_array!2 = "lon"

   val_ClmMon = clmMonTLL(val_array)         ; daily climatology at each grid point

  ; -------------------------------
  ; CLIMATOLOGOCAL MONTHLY STDDEV
  ; -------------------------------
    val_ClmDaysd = new(dimsizes(val_ClmMon), double)
    do kk=0,11
      month_ind := ind(months.eq.(kk+1))
      val_to_avg := detrend_val(month_ind)
      val_ClmDaysd(kk,0,0) = dim_stddev_n(tofloat(val_to_avg),0)
    end do
    val_ClmDaysd!0 = "month"
    val_ClmDaysd&month = val_ClmMon&month

  ; -------------------------------
  ; SETUP OUTPUT  
  ; -------------------------------
    valCOMB = new((/dimsizes(val_ClmMon(:,0,0)),2/),double)
      valCOMB(:,0) = val_ClmMon(:,0,0)
      valCOMB(:,1) = val_ClmDaysd(:,0,0)
    valCOMB!0 = "month"
    valCOMB&month = val_ClmMon&month

  ; -------------------------------
  ; RETURN VALUES 
  ; -------------------------------
  valOUT = valCOMB
  return(valOUT)

end

