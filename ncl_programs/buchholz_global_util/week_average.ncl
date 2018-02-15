;============================================
; week_average.ncl
;============================================
;
; Concepts Illustrated
;          - Create week average from higher 
;            time resolution data
;
; To use call within another ncl program:
;          > week_average(data_array,time_array)
;          
;                            RRB Sep 22, 2015
;============================================
undef("week_average")

function week_average(valIN[*]:numeric, timeIN[*]:numeric)
;============================================
; Purpose: calculate a week average
; 
; Arguments:
;    valIN: Values associated with the time array
;
;    timeIN: The native time array of the values
;            Must be in "time since ..."
;
; Return Value:
;    valOUT: Week averaged values and associated time array:
;            week times start on first day of year.
;
;============================================
local valAVG, date, years, months, days, doy, week, yearcount, week_avg_time

begin

  ; check input
  if (dimsizes(valIN).ne.dimsizes(timeIN)) then
    print("week_average: Cannot calculate, the input time and variables have different dimensions.")
    return
  end if

;--------------------------------------------
; Date manipulations
;--------------------------------------------
  date    = cd_calendar(timeIN, 0)
     years   = floattointeger(date(:,0))
     months  = floattointeger(date(:,1))
     days    = floattointeger(date(:,2))
     doy     = day_of_year(years,months,days)

     week = floor(doy/7.0)+1
     week = where(mod(doy,7).eq.0, floor(doy/7.0), week)
     week = where(week.eq.53, 52, week)

     yearcount = ispan(years(0), years(dimsizes(years)-1),1)

;--------------------------------------------
; Create a holding array
;--------------------------------------------
  valAVG = new((/dimsizes(yearcount)*52,2/), float)
  week_avg_time := new(dimsizes(yearcount)*52, integer)

;--------------------------------------------
; Do the averaging
;--------------------------------------------
  do i=0,dimsizes(yearcount)-1
    do j =0, 51
       index_value = i*52 + j
       ; find indices of year and week
       currentyear = yearcount(i)
       currentweek = j+1
       week_avg_time(index_value) = currentyear*1000+(floattointeger(currentweek*7)-6)
       ind_toavg := ind(years.eq.currentyear.and.\
                       week.eq.currentweek)

      if (all(ismissing(ind_toavg))) then
        ;print("No data for week "+currentweek+", next timepoint")
        continue          ; if no data move to next timepoint
      end if
 
      ; collect data for available weeks
       ;print("calculating average of:")
       ;print(currentyear+", week "+currentweek)
       ;print("-------------------")
      if (dimsizes(ind_toavg).eq.1) then
           valAVG(index_value,0) = valIN(ind_toavg)
      else
           valAVG(index_value,0) = avg(valIN(ind_toavg))
           valAVG(index_value,1) = stddev(valIN(ind_toavg))
      end if
    end do
  end do

   valAVG!0 = "time"
   valAVG&time = yyyyddd_to_yyyymmdd(week_avg_time)

   valAVG@dims = "At each time point, first value is average column, second is standard deviation"

  valOUT = valAVG
  return(valOUT)

end


