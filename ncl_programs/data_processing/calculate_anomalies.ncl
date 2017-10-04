;=======================================================;
;  anomaly_plot.ncl 
;=======================================================;
;
; Concepts illustrated:
;   - For use with MOPITT CO station or regional avg data
;   - Can also use FTS station data
;     - loading CO data
;     - monthly mean values
;     - weekly mean values
;     - whole dataset average month values
;     - whole dataset month means - weekly average differences (anomalies)
;     - climate variability
;
;   Files needed:
;         -MOPITT subset of level 2, daily hdf files
;         -FTS files
;
;   To run type:
;         ncl anomaly_plot.ncl 
;                                  RRB August 10, 2017
;=======================================================;
; load the libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------

  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  loc = "EastSAmerica" ; Australasia, SAmerica, SAfrica, Indonesia

  version = "V7J"
  data_folder = "/IASI/home/buchholz/MOPITT_subset/"
  mopitt_files = systemfunc ("ls "+data_folder+"SH_regions_v7/"+loc+"_"+version+"*.nc")

  if (loc.eq."Indonesia") then
    loc = "MaritimeSEA"
  end if


  location_title = loc
    year_s = 2001
    year_e = 2017

  ;------------
  ; scale of outside sd
  ; to denote event
  ;------------
    event_scale = 1
    neg_event = -1

  ;------------
  ; toggles
  ;------------
  PLOT           = True
    plttype      = "x11"
    ;plttype@wkPaperSize = "A4"
     plttype@wkWidth = 1200
     plttype@wkHeight = 1200 
      ymin       =-5e17
      ymax       =10e17
      spacing    =5e17


  
  CSV            = True
  if (CSV) then
     outname      = data_folder+"/V7/anomalies/"+\
                     loc+"_"+version+"MOPITTanomalies.csv"
  end if

  NETCDF            = False
  if (NETCDF) then
     nc_outname      = data_folder+"/V7/anomalies/"+\
                        loc+"_"+version+"MOPITTanomalies.nc"
  end if

  
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
  sat_tcol      = "RetrievedCOTotalColumn"
  timearray     = "Time"

  sat_err       = "RetrievedCOTotalColumnError"

  ; -------------------------------
  ; STATION PARAMETERS
  ; -------------------------------
    location = loc

  if (loc.eq."darwin") then
    location_lat = -12.42
    location_lon = 130.89
    location = "Darwin"
    ; UTC +
    time_diff    = 9.5
  else if (loc.eq."lauder") then
    location_lat = -45.038
    location_lon = 169.684
    location = "Lauder"
    ; UTC +
    time_diff    = 12
  else if (loc.eq."wollongong") then
    location_lat = -34.41
    location_lon = 150.88
    location = "Wollongong"
    fts_files2 =  fts_files
    ; UTC +
    time_diff    = 10
  else if (loc.eq."thule") then
    location_lat = 76.53
    location_lon = -68.74
    location = "Thule"
    fts_files2 =  fts_files
    ; UTC +
    time_diff    = -4
  end if
  end if
  end if
  end if

  ; -------------------------------
  ; Set first day of week date array
  ; -------------------------------
  do i=0,51
    first_dow = 0
  end do

  ; -------------------------------
  ; OUTPUT RELATED SETUP
  ; -------------------------------
  if (PLOT) then
    pltdir       = "./"
    pltname      = version+"mopitt_l2_vs_fts_" + location
  end if

;--------------------------------------------
; load file and extract
;--------------------------------------------
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  ; read data from region
  mopitt_in = addfiles (mopitt_files, "r")
  ListSetType (mopitt_in, "cat")             ; concatenate or "merge" (default)

  print("***Reading MOPITT data at " + location)
    mopitt_tcol    = mopitt_in[:]->$sat_tcol$
    mopitt_err     = mopitt_in[:]->$sat_err$
    mopitt_time    = mopitt_in[:]->$timearray$       ; local time in seconds since 1993-1-1 00:00:00 (TAI93)
    mopitt_date    = cd_calendar(mopitt_time, 0)
    years = floattointeger(mopitt_date(:,0))
    months = floattointeger(mopitt_date(:,1))
    days = floattointeger(mopitt_date(:,2))
      doy            = day_of_year(years,months,days)
    yyyymmdd         = cd_calendar(mopitt_time, 2)

  ;--------------------------------------------
  ; calculate averages - separate into weeks, 
  ; months and anomalies
  ;--------------------------------------------
  ;********************************************
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
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

     climate_co(i) =  dim_avg_n(co_to_avg,0)
     climate_co_sd(i) =  dim_stddev_n(co_to_avg,0)
  end do ;i=0,dimsizes(mopitt_time)-1
  
  ; repeat climate values over total time period
  startyear = years(0)
  endyear = years(dimsizes(years)-1)
  climate_time = yyyymm_time(toint(startyear), toint(endyear), "integer")
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
  ; MONTH AVERAGES
  ; -------------------------------
  month_co_avg  = new(dimsizes(climate_co_ext), float)
  month_err_avg  = new(dimsizes(climate_co_ext), float)
  month_co_sd   = new(dimsizes(climate_co_ext), float)

  do y = toint(startyear), toint(endyear)
    do m=0,11
      ind_yearmonth := ind(years.eq.y.and.months.eq.(m+1))
      index_month = (y-toint(startyear))*12+m
      if (.not.ismissing(ind_yearmonth(0))) then
        if (dimsizes(ind_yearmonth).eq.1) then
          month_co_avg(index_month)=mopitt_tcol(ind_yearmonth)
          month_err_avg(index_month)=mopitt_err(ind_yearmonth)
          ;month_anomaly_orig(index_month)= mopitt_tcol(ind_yearmonth)-climate_co(m)
        else 
          month_co_avg(index_month)=dim_avg_n(mopitt_tcol(ind_yearmonth),0)
          month_err_avg(index_month)=dim_avg_n(mopitt_err(ind_yearmonth),0)
          month_co_sd(index_month)=dim_stddev_n(mopitt_tcol(ind_yearmonth),0)
          ;month_anomaly_orig(index_month)= dim_avg_n(mopitt_tcol(ind_yearmonth),0)-climate_co(m)
        end if
      end if
    end do
  end do

  month_avg_yfrac = yyyymm_to_yyyyfrac(stringtodouble(climate_time),0.5)

  ; -------------------------------
  ; 2009-09 has only one day, 
  ; so fill with missing value
  ; -------------------------------
   sep09 = ind(climate_time.eq.200909)
   month_co_avg(sep09) = month_co_avg@_FillValue
print(month_co_avg(sep09))

  ; -------------------------------
  ; SPLINE FIT TO FILL MISSING VALUES
  ; -------------------------------
  ind_data = ind(.not.ismissing(month_co_avg))
  xi = month_avg_yfrac(ind_data)
  yi = month_co_avg(ind_data)
  xo = month_avg_yfrac
  yo = ftcurv(xi, yi, xo)
  new_month_co_avg = tofloat(where(ismissing(month_co_avg),yo,month_co_avg))
print(new_month_co_avg(sep09))

  ; -------------------------------
  ; ANOMALIES
  ; -------------------------------
  month_dummy = str_split_by_length(climate_time,2)
  month_array = toint(month_dummy(:,2))-1
  month_anomaly = new(dimsizes(climate_co_ext), float)

  do j = 0, dimsizes(climate_time)-1
    month_anomaly(j)= tofloat(new_month_co_avg(j))-climate_co(month_array(j))
  end do


;--------------------------------------------
; plot
;--------------------------------------------
if (PLOT) then

  wks = gsn_open_wks(plttype,pltname)        
  gsn_define_colormap(wks,"BlAqGrYeOrRe")  
   
  res                       = True                  ; plot mods desired
    res@xyMarkLineMode      = "Markers"
    res@xyMarker            = 17
    res@xyMarkerSizeF       = 0.08
    res@gsnDraw		    = False	            ; don't draw it yet
    res@gsnFrame            = False                 ; don't advance frame
    res@gsnMaximize         = True

    res@trYMinF             = 1e18
    res@trYMaxF             = 3.2e18
    res@trXMinF             = year_s
    res@trXMaxF             = year_e

    res@tmYLMode            = "Explicit"	
      res@tmYLValues            = (/1e18, 2e18, 3e18/)
      res@tmYLLabels            = (/"1.0", "2.0", "3.0"/)

    res@tmXBMode            = "Explicit"
      res@tmXBValues            = (/2005,2010,2015/)
      res@tmXBLabels            = (/"2005", "2010", "2015"/)
      res@tmXBMinorPerMajor     = 11	
      res@tmXBMinorValues       = tofloat(ispan(year_s,year_e,1))

    res@tmYLMajorOutwardLengthF = 0.0               ; draw tickmarks inward
    res@tmYLMinorOutwardLengthF = 0.0               ; draw minor ticsk inward
    res@tmXBMajorOutwardLengthF = 0.0               
    res@tmXBMinorOutwardLengthF = 0.0              

    res@vpWidthF             = 1.8
    res@vpHeightF            = 0.45                 ; set height of plot

    res@tiMainString         = ""
    res@tiXAxisString        = ""
    res@tiYAxisString        = "CO Column"
    res@gsnLeftString        = "molec. cm~S2~-2"
    res@gsnRightString       = "~F34~4~F21~10~S2~18   molec. cm~S2~-2" 
 
    res@pmLegendDisplayMode      = "Always"        ; turn on legend
    res@lgPerimOn                = False           ; Turn off perimeter
    res@pmLegendWidthF           = 0.20            ; Change width and
    res@pmLegendHeightF          = 0.50            ; height of legend
    res@lgLabelFontHeightF       = 0.050

  ; -------------------------------
  ; timeseries - weekly averages and climatology
  ; -------------------------------
  ; MOPITT
  plottime := month_avg_yfrac
    res@xyExplicitLegendLabels   = "Month average"
    res@pmLegendOrthogonalPosF   = 0.8
    res@pmLegendParallelPosF     = 0.615
    res@xyMarkLineMode           = "Markers"
    res@xyMarkerColor            = "grey34"
  plot1 = gsn_csm_xy(wks,plottime,new_month_co_avg,res)

    res@xyMarkerSizeF            = 0.05
    res@xyMarkerColor            = "skyblue"
  ;plot1a = gsn_csm_xy(wks,plottime,month_co_avg,res)
  ;overlay(plot1, plot1a)

    res@tiYAxisString             = ""
    res@xyExplicitLegendLabels    = "Climatological seasonal cycle"
    res@pmLegendOrthogonalPosF    = 0.95
    res@pmLegendParallelPosF      = 0.715
    res@xyMarkLineMode            = "Lines"
    res@xyLineThicknessF          = 7.0
    res@xyLineColor               = "black"
  plot2 = gsn_csm_xy(wks,plottime,climate_co_ext,res)
  overlay(plot1, plot2)

  ; -------------------------------
  ; Anomaly plot MOPITT
  ; -------------------------------
    res@vpHeightF                 = 0.45          ; reset height of plot

    res@pmLegendDisplayMode       = "Never"       ; turn on legend
    res@gsnLeftString             = ""
    res@gsnRightString            = "" 
    res@xyLineThicknessF          = 1.5
    res@xyLineColor               = "black"
    res@trYMinF                   = -0.55e18
    res@trYMaxF                   = 1.0e18
    res@tiYAxisString             = "CO Anomaly"
    res@tmXBLabelsOn              = True
      res@tmXBLabelFontHeightF    = 0.10

    res@trYMinF                  = ymin-0.05e18
    res@trYMaxF                  = ymax+0.05e18
    res@tmYLValues               = (/-0.5e18, 0e18, 0.5e18/)
    res@tmYLLabels               = (/"-0.5", "0", "0.5"/)

    res@gsnYRefLine      = 0.0
      res@gsnAboveYRefLineColor = "red"          ; above ref line fill red
      res@gsnBelowYRefLineColor = "blue"         ; below ref line fill blue
  plot5 = gsn_csm_xy(wks,plottime,month_anomaly,res)

 ; add zero line
  res_lines                   = True              ; polyline mods desired
    res_lines@gsLineDashPattern = 0               ; line style
    res_lines@gsLineThicknessF  = 2.5             ; line thicker
    res_lines@gsLineColor       = "black"         ; line color
    res_lines@tfPolyDrawOrder   = "PreDraw"       ; send to back
  xx = (/year_s,year_e/)
  yy = (/0,0/)
  dum2 = gsn_add_polyline(wks,plot5,xx,yy,res_lines) ; add polyline

  ; -------------------------------
  ; Add standard deviation
  ; -------------------------------
   ya1    = new( (/2*dimsizes(plottime)/), double )
   yb1    = new( (/2*dimsizes(plottime)/), double )
   do k=0,dimsizes(plottime)-1
     ya1(k) = plottime(k)
     yb1(k) = climate_co_sd_ext(k)
     yb1(2*dimsizes(plottime)-1-k) = 0-climate_co_sd_ext(k)
     ya1(2*dimsizes(plottime)-1-k) = plottime(k)
   end do
    gsres                          = True         ; poly res
    gsres@gsFillColor              = "grey"       ; color chosen
    gsres@gsFillOpacityF           = 0.4                 
    dum3 = gsn_add_polygon(wks,plot5,ya1,yb1,gsres)

  ; -------------------------------
  ; panel the plots
  ; -------------------------------
  res1                     = True
    res1@gsnAttachBorderOn   = False
    res1@tiYAxisFontHeightF  = 0.028
  res2                     = True
    res2@gsnMaximize         = True
    res2@gsnAttachPlotsXAxis = True
    res2@tiXAxisFontHeightF  = 0.028
    res2@tiYAxisFontHeightF  = 0.028


  ; plot1 will be the base plot.
  amid = gsn_attach_plots(plot1,plot5,res1,res2)

  ;-----------------------------------
  ; Add in title
  ;-----------------------------------
   ;drawNDCGrid(wks)
   ; add station
    txres                   = True                 ; polyline mods desired
     txres@txFontHeightF    = 0.024                ; font smaller. default big
     txres@txJust           = "CenterLeft"         ; font smaller. default big
     txres@txPerimOn        = True
     txres@txPerimThicknessF= 2.0
    gsn_text_ndc(wks,location_title,0.16,0.84,txres)

  draw(plot1)
  frame(wks)

end if ; PLOT


;--------------------------------------------
; Write out to a ASCII file
;--------------------------------------------
if (CSV) then

;---Create dummy mixed data to write to CSV file
  fields = (/"time",     "tcol_co",  "anomaly_co"/)
  dq = str_get_dq()                ; double quote character
  fields = dq + fields + dq                      ; Pre/append quotes to field names
  header = [/str_join(fields,",")/]              ; Header is field names separated
                                                 ;   by commas.

  month_co_avg@_FillValue         = -999.99

  alist  = [/toint(climate_time),new_month_co_avg,month_anomaly/]   ; List of variables to write.
;; Note: if you don't want spaces in CSV file, use the following format string.
 format = "%d,%g,%g"

  system("rm -rf " + outname)               ; Remove file in case it exists.

  write_table(outname, "w", header, "%s")   ; Write header to CSV file.
  write_table(outname, "a", alist, format)  ; Write mixed data to CSV file.


;---Echo the new file to the screen so you can see it.
  print("====== Contents of '" + outname + "' ======")
  system("cat " + outname)
  print("========================================")
end if ;CSV


;--------------------------------------------
; Write out to a netCDF file
;--------------------------------------------
if (NETCDF) then
  ; saves MOPITT averages
  system("rm -rf " + nc_outname)               ; Remove file in case it exists.
  fout = addfile(nc_outname, "c")
  ;------------
  ; File 
  ; Attributes
  ;------------
  region_def = str_split (month_co_avg@average_op_ncl,":")

  setfileoption(fout, "DefineMode",True)
    fAtt                      = True
      fAtt@email              = "buchholz@ucar.edu"
      fAtt@author             = "R. R. Buchholz"
      fAtt@creation_date      = systemfunc ("date")
      fAtt@conventrions       = "CF"
      fAtt@reference          = "Deeter et al., AMT, 2017, doi:10.5194/amt-10-2533-2017"
      fAtt@source             = "MOPITT level 2, version 7, thermal IR retrievals, doi:10.5067/TERRA/MOPITT/MOP02T_L2.007"
      fAtt@region_definition  = location + " -->" +region_def(1)
      fAtt@title              = "Month average anomalies from MOPITT CO for " +location

     fileattdef(fout, fAtt)
  setfileoption(fout, "DefineMode",False)

  ;------------
  ; Variable 
  ; Attributes
  ;------------
  time_array = climate_time
  time_array@long_name         = "time"
  time_array@units             = "YYYYMM"
  time_array!0                 = "time"

  month_co_avg@long_name          = "MOPITT_CO_TotalColumn"
  month_co_avg@units              = "molec/cm^2"
  month_co_avg!0                  = "time"
  month_co_avg&time               = climate_time
  month_co_avg@_FillValue         = 9.969209968386869e+36
  delete(month_co_avg@average_op_ncl)

  month_co_avg@long_name          = "MOPITT_CO_TotalColumn"
  month_co_avg@units              = "molec/cm^2"
  month_co_avg!0                  = "time"
  month_co_avg&time               = climate_time
  month_co_avg@_FillValue         = 9.96921e+36 

  month_co_sd@long_name           = "MOPITT_CO_StdDev"
  month_co_sd@units               = "molec/cm^2"
  month_co_sd!0                   = "time"
  month_co_sd&time                = climate_time
  month_co_sd@_FillValue          = 9.96921e+36 

  month_err_avg@long_name         = "MOPITT_CO_Column_Error"
  month_err_avg@units             = "molec/cm^2"
  month_err_avg!0                 = "time"
  month_err_avg&time              = climate_time
  month_err_avg@_FillValue        = 9.96921e+36 
  delete(month_err_avg@average_op_ncl)

  new_month_co_avg@long_name      = "MOPITT_CO_TotalColumn_SplineFit"
  new_month_co_avg@units          = "molec/cm^2"
  new_month_co_avg!0              = "time"
  new_month_co_avg&time           = climate_time
  new_month_co_avg@_FillValue     = 9.96921e+36
  new_month_co_avg@comment        = "Missing values filled using spline fit. Required for regression analysis."

  month_anomaly@long_name         = "MOPITT_CO_Anomaly"
  month_anomaly@units             = "molec/cm^2"
  month_anomaly!0                 = "time"
  month_anomaly&time              = climate_time

  ;------------
  ; Write to
  ; file
  ;------------
  fout->MOPITT_CO_TCOL = month_co_avg
  fout->MOPITT_CO_SD = month_co_sd
  fout->MOPITT_CO_ERR = month_err_avg
  fout->MOPITT_CO_TCOL_FILLED = new_month_co_avg
  fout->MOPITT_CO_ANOMALY = month_anomaly


end if ;NETCDF

end

