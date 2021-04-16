;=======================================================;
;  calculate_anomalies_weekly.ncl 
;=======================================================;
;
; Concepts illustrated:
;   - For use with MOPITT CO station or regional avg data
;   - Can also use FTS station data
;     - loading CO data
;     - weekly mean values
;     - climatological week values
;     - climatological week values - weekly average differences (anomalies)
;
;   Files needed:
;         -MOPITT weekly subset of level 2, hdf files
;
;   To run type:
;         ncl calculate_anomalies_weekly.ncl 
;                                  RRB May 4, 2020
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
  loc = "MSEA" ; Australasia, SAmerica, SAfrica, Indonesia
  region_name = "MSEA"
  data_type = "XCO"

  version = "V8"
  retrieval = "J"
  data_folder = "/IASI/home/buchholz/MOPITT_subset/"
  mopitt_general = "/IASI/home/buchholz/MOPITT_subset/regions_v8/"
  ;mopitt_files = systemfunc ("ls "+mopitt_general+loc+"_stats_"+version+retrieval+"subset*weekavg_VMR.nc")
  mopitt_files = systemfunc ("ls "+mopitt_general+loc+"_stats_"+version+retrieval+"subset*weekavg_WEDCEN_VMR.nc")
print(mopitt_files)


  if (loc.eq."Indonesia") then
    loc = "MaritimeSEA"
  end if

  location_title = loc
    year_s = 2001
    year_e = 2019

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
    plttype      = "png"
    ;plttype@wkPaperSize = "A4"
     ;plttype@wkWidth = 1200
     ;plttype@wkHeight = 1200 
      ;ymin       =-5e17
      ;ymax       =10e17
      ;spacing    =5e17

  scale_factor = 1e-09
  ;scale_factor = 1e18
  
  CSV            = False
  if (CSV) then
     outname      = data_folder+"/"+version+"/anomalies/"+\
                     loc+"_"+version+retrieval+"MOPITT_weeklyanomalies.csv"
  end if

  NETCDF            = False
  if (NETCDF) then
     nc_outname      = data_folder+"/"+version+"/anomalies/"+\
                        loc+"_"+version+retrieval+"MOPITTanomalies.nc"
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
  ;sat_tcol      = "RetrievedCOTotalColumn"
  ;sat_tcol     = "RetrievedCOTotalColumn_WGT"
  sat_tcol      = "RetrievedX_CO"

   
  if (loc.eq."BBCanada".or.loc.eq."BBSiberia".or.loc.eq."CONTRAIL"\
      .or.loc.eq."MSEA".or.loc.eq."MYS".or.data_type.eq."XCO") then
    timearray     = "time"
    sat_err       = "AvgError"
    ;sat_num       = "RetrievedCOtcolRegionStats"
    sat_num       = "RetrievedX_CORegionStats"
    sat_rand      = "AvgRandomError"
  else if (loc.eq."Darwin") then
    region_def = (/"Darwin","-12.42 Lat, 130.89 Lon"/)
    timearray     = "Time_AVG"
    sat_err       = "RetrievedCOTotalColumn_ERR"
    sat_num       = "NumberofRetrievals"
    sat_rand      = "RetrievedCOTotalColumn_ERR"
  else
    timearray     = "Time"
    sat_err       = "RetrievedCOTotalColumnError"
    sat_num       = "NumberInAvg"
    sat_rand      = "RetrievedCOColRandMax"
  end if
  end if

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
    pltname      = version+"mopitt_l2_weekly" + location
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
    ; time as YYYYDOY the mid-point of each week
    mopitt_time    = mopitt_in[:]->$timearray$

    mopitt_err     = mopitt_in[:]->$sat_err$
    mopitt_rand    = mopitt_in[:]->$sat_rand$

  if (loc.eq."MSEA".or.loc.eq."MYS".or.data_type.eq."XCO") then
    mopitt_num     = mopitt_in[:]->$sat_num$(:,7)
    mopitt_date_dummy = yyyyddd_to_yyyymmdd(mopitt_time)
    mopitt_date    = str_split_by_length(tostring(mopitt_date_dummy),4)
    years = tointeger(mopitt_date(:,0))
    mopitt_date2    = str_split_by_length(tostring(mopitt_date_dummy),2)
    months = tointeger(mopitt_date2(:,2))
    days = tointeger(mopitt_date2(:,3))
  else
    mopitt_num     = mopitt_in[:]->$sat_num$
    mopitt_date    = cd_calendar(mopitt_time, 0); local time in seconds since 1993-1-1 00:00:00 (TAI93)
    years = floattointeger(mopitt_date(:,0))
    months = floattointeger(mopitt_date(:,1))
    days = floattointeger(mopitt_date(:,2))
    yyyymmdd         = cd_calendar(mopitt_time, 2)
  end if

print(mopitt_time)
    date_split = str_split_by_length(tostring(mopitt_time),4)
print(date_split)
    doy = toint(date_split(:,1))

  ;--------------------------------------------
  ; calculate averages, separate into weeks,
  ; and calculate anomalies
  ;--------------------------------------------

  ;********************************************
  ; -------------------------------
  ; CLIMATOLOGICAL WEEK AVERAGES 
  ; and STANDARD DEVIATION
  ; ------------------------------- 
    climate_co   = new((/52/), float)
    climate_co_sd = new((/52/), float)
    climday = ispan(1,52,1)
    climday = (climday * 7)-3

  do i=0,51
     ; get indices of array related to specific month
     week_ind := ind(doy.eq.climday(i))
     ;print(mopitt_time(week_ind))
     co_to_avg := mopitt_tcol(week_ind)

     climate_co(i) =  dim_avg_n(co_to_avg,0)
     climate_co_sd(i) =  dim_stddev_n(co_to_avg,0)
  end do ;i=0,dimsizes(mopitt_time)-1

   climate_co_ext    = new(dimsizes(mopitt_tcol), float)
   climate_co_sd_ext = new(dimsizes(mopitt_tcol), float)

   climate_time = mopitt_date_dummy
   week_avg_yfrac = yyyymmdd_to_yyyyfrac(climate_time,0.5)

  ; repeat climate values over total time period
  startyear = years(0)
  endyear = years(dimsizes(years)-1)
  years_of_record = endyear - startyear

  do y = 0, years_of_record
    do m=0,51
     climate_co_ext(y*52+m) = climate_co(m)
     climate_co_sd_ext(y*52+m) = climate_co_sd(m)
    end do
  end do


;printVarSummary(climate_co_ext)
;printVarSummary(climate_co_sd_ext)
;printVarSummary(mopitt_tcol)

  ; -------------------------------
  ; e.g. 2009-09 has only one day, 
  ; so fill with missing value
  ; -------------------------------
  week_co_avg = mopitt_tcol
  missing_ind = ind(ismissing(week_co_avg))
  print(climate_time(missing_ind)+ " " +week_co_avg(missing_ind))

  ; -------------------------------
  ; SPLINE FIT TO FILL MISSING VALUES
  ; -------------------------------
  ind_data = ind(.not.ismissing(week_co_avg))
  xi = week_avg_yfrac(ind_data)
  yi = week_co_avg(ind_data)
  xo = week_avg_yfrac
  yo = ftcurv(xi, yi, xo)
  new_week_co_avg = tofloat(where(ismissing(week_co_avg),yo,week_co_avg))
  print(climate_time(missing_ind)+ " " +new_week_co_avg(missing_ind))

  ; -------------------------------
  ; ANOMALIES
  ; -------------------------------

  week_anomaly = new_week_co_avg - climate_co_ext
  week_anomaly_nofill = week_co_avg - climate_co_ext

;print("Maximum error:")
;print(max(month_err_avg))
;rel_err = month_err_avg/climate_co_ext
;print("Maximum relative error:")
;print(max(rel_err))

;print(week_anomaly)
;exit

;--------------------------------------------
; plot
;--------------------------------------------
if (PLOT) then

  wks = gsn_open_wks(plttype,data_folder+"/"+version+"/anomalies/"+pltname)        
  gsn_define_colormap(wks,"BlAqGrYeOrRe")  
   
  res                       = True                  ; plot mods desired
    res@xyMarkLineMode      = "Markers"
    res@xyMarker            = 17
    res@xyMarkerSizeF       = 0.08
    res@gsnDraw		    = False	            ; don't draw it yet
    res@gsnFrame            = False                 ; don't advance frame
    res@gsnMaximize         = True

    ;res@trYMinF             = 55
    ;res@trYMaxF             = 110

    ;res@trYMinF             = 0
    ;res@trYMaxF             = 4

    ;res@trYMinF             = 1e18
    ;res@trYMaxF             = 3.2e18
    res@trXMinF             = year_s
    res@trXMaxF             = year_e

    ;res@tmYLMode            = "Explicit"	
    ;  res@tmYLValues            = (/1e18, 2e18, 3e18/)
    ;  res@tmYLLabels            = (/"1.0", "2.0", "3.0"/)

    res@tmXBMode            = "Explicit"
      res@tmXBValues            = (/2005,2010,2015/)
      res@tmXBLabels            = (/"2005", "2010", "2015"/)
      res@tmXBMinorPerMajor     = 11	
      res@tmXBMinorValues       = tofloat(ispan(year_s,year_e,1))

    res@tmYLMajorOutwardLengthF = 0.0               ; draw tickmarks inward
    res@tmYLMinorOutwardLengthF = 0.0               ; draw minor ticsk inward
    res@tmXBMajorOutwardLengthF = 0.0               
    res@tmXBMinorOutwardLengthF = 0.0              

    res@vpWidthF             = 1.6
    res@vpHeightF            = 0.45                 ; set height of plot

    res@tiMainString         = ""
    res@tiXAxisString        = ""
    ;res@tiYAxisString        = "CO Column"
    res@tiYAxisString        = "X_CO"
    ;res@gsnLeftString        = "molec. cm~S2~-2"
    ;res@tiYAxisString        = "CO"
    res@gsnLeftString        = "column average VMR (ppb)"
    ;res@gsnRightString       = "~F34~4~F21~10~S2~18   molec. cm~S2~-2" 
 
    res@pmLegendDisplayMode      = "Always"        ; turn on legend
    res@lgPerimOn                = False           ; Turn off perimeter
    res@pmLegendWidthF           = 0.20            ; Change width and
    res@pmLegendHeightF          = 0.50            ; height of legend
    res@lgLabelFontHeightF       = 0.050

  ; -------------------------------
  ; timeseries - weekly averages and climatology
  ; -------------------------------
  ; MOPITT
  plottime := week_avg_yfrac
    res@xyExplicitLegendLabels   = "Weekly average"
    res@pmLegendOrthogonalPosF   = 0.8
    res@pmLegendParallelPosF     = 0.615
    res@xyMarkLineMode           = "Markers"
    res@xyMarkerColor            = "grey34"
    res@trYMinF                  = 40
    res@trYMaxF                  = 200
  plot1 = gsn_csm_xy(wks,plottime,new_week_co_avg/scale_factor,res)

    res@tiYAxisString        = ""
    res@gsnLeftString        = ""
    res@xyMarkerSizeF            = 0.05
    res@xyMarkerColor            = "skyblue"
  ;plot1a = gsn_csm_xy(wks,plottime,week_co_avg/scale_factor,res)
  ;overlay(plot1, plot1a)

    res@tiYAxisString             = ""
    res@xyExplicitLegendLabels    = "Climatological seasonal cycle"
    res@pmLegendOrthogonalPosF    = 0.95
    res@pmLegendParallelPosF      = 0.715
    res@xyMarkLineMode            = "Lines"
    res@xyLineThicknessF          = 7.0
    res@xyLineColor               = "black"
  plot2 = gsn_csm_xy(wks,plottime,climate_co_ext/scale_factor,res)
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
    res@trYMinF                  = -50
    res@trYMaxF                  = 110
    res@tiYAxisString             = "CO Anomaly"
    res@tmXBLabelsOn              = True
      res@tmXBLabelFontHeightF    = 0.10

    ;res@trYMinF             = -15
    ;res@trYMaxF             = 25
    ;res@trYMinF             = -1
    ;res@trYMaxF             = 1
    ;res@trYMinF                  = ymin-0.05e18
    ;res@trYMaxF                  = ymax+0.05e18
    ;res@tmYLValues               = (/-0.5e18, 0e18, 0.5e18/)
    ;res@tmYLLabels               = (/"-0.5", "0", "0.5"/)

    res@gsnYRefLine      = 0.0
      res@gsnAboveYRefLineColor = "red"          ; above ref line fill red
      res@gsnBelowYRefLineColor = "blue"         ; below ref line fill blue
  plot5 = gsn_csm_xy(wks,plottime,week_anomaly/scale_factor,res)

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
     ;yb1(k) = climate_co_sd_ext(k)
     ;yb1(2*dimsizes(plottime)-1-k) = 0-climate_co_sd_ext(k)
     yb1(k) = 6.351612628e15
     yb1(2*dimsizes(plottime)-1-k) = 0-6.351612628e15
     ;yb1(k) = 3.11092e15
     ;yb1(2*dimsizes(plottime)-1-k) = 0-3.11092e15
     ya1(2*dimsizes(plottime)-1-k) = plottime(k)
   end do
    gsres                          = True         ; poly res
    gsres@gsFillColor              = "green"       ; color chosen
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
    gsn_text_ndc(wks,location_title,0.76,0.84,txres)

  draw(plot1)
  frame(wks)

end if ; PLOT


;--------------------------------------------
; Write out to a ASCII file
;--------------------------------------------
if (CSV) then

;---Create dummy mixed data to write to CSV file
  ;fields = (/"time",     "tcol_co",  "anomaly_co"/)
  fields = (/"time", "x_co", "anomaly_co", "x_co climatology", "num_obs"/)
  dq = str_get_dq()                ; double quote character
  fields = dq + fields + dq                      ; Pre/append quotes to field names
  header = [/str_join(fields,",")/]              ; Header is field names separated
                                                 ;   by commas.

  week_co_avg@_FillValue         = -999.99

  alist  = [/toint(climate_time),new_week_co_avg/scale_factor,week_anomaly/scale_factor,climate_co_ext/scale_factor,mopitt_num/]   ; List of variables to write.
;  alist  = [/toint(climate_time),week_co_avg/scale_factor,week_anomaly_nofill/scale_factor,climate_co_ext/scale_factor,mopitt_num/]   ; List of variables to write.
;; Note: if you don't want spaces in CSV file, use the following format string.
 format = "%d,%g,%g,%g,%g"

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
  if (loc.eq."Darwin") then
    region_def = (/"Darwin","-12.42 Lat -12.42 Lat, 130.89 Lon 130.89 Lon"/)
  else
    region_def = str_split (mopitt_tcol@average_op_ncl,":")
  end if 
print(region_def(1))
  sep_lat_lon = str_split (region_def(1)," ")

  setfileoption(fout, "DefineMode",True)
    fAtt                      = True
      fAtt@featureType        = "timeSeries"
      fAtt@email              = "buchholz@ucar.edu"
      fAtt@author             = "R. R. Buchholz"
      fAtt@creation_date      = systemfunc ("date")
      fAtt@Conventions        = "CF-1.6"
      ;fAtt@reference          = "Deeter et al., AMT, 2017, doi:10.5194/amt-10-2533-2017"
      fAtt@source             = "MOPITT level 2, version 7, thermal IR retrievals, "+\
                                "doi:10.5067/TERRA/MOPITT/MOP02T_L2.007"
      fAtt@region_definition  = region_name + " -->" +region_def(1)
      fAtt@title              = "Month average anomalies in MOPITT CO for " +region_name

     fileattdef(fout, fAtt)
  setfileoption(fout, "DefineMode",False)

  ;------------
  ; Dimension 
  ; Definitions
  ;------------
  base_julian = greg2jul(2000,1,1,0)
  splitdate = str_split_by_length(tostring(climate_time), 4)
  day_midmonth = (toint(splitdate(:,0))*0)+16
  hour_midmonth = (toint(splitdate(:,0))*0)
  juliandate = greg2jul(toint(splitdate(:,0)),toint(splitdate(:,1)),day_midmonth,hour_midmonth)-base_julian

  time_array = juliandate
  time_array@long_name         = "time"
  time_array@units             = "days since 2000-01-01 00:00:00"
  time_array!0                 = "time"

  lat_boundaries = (/tofloat(sep_lat_lon(0)),tofloat(sep_lat_lon(2))/)
    lat_boundaries@long_name         = "latitude"
    lat_boundaries@units             = "degrees_north"
    lat_boundaries@description       = "Latitude bounds, south is negative"
    lat_boundaries!0                 = "nbounds"

  lon_boundaries = (/tofloat(sep_lat_lon(4)),tofloat(sep_lat_lon(6))/)
    lon_boundaries@long_name         = "longitude"
    lon_boundaries@units             = "degrees_east"
    lon_boundaries@description       = "Longitude bounds, west is negative"
    lon_boundaries!0                 = "nbounds"


   lat_center = (lat_boundaries(0)+lat_boundaries(1))/2
     lat_center@description          = "Latitude center of region, south is negative"
     lat_center@long_name            = "latitude"
     lat_center@units                = "degrees_north"
     lat_center@bounds               = "REGION_LAT_BOUNDS"
     ;lat_center!0                    = "ncenter"

   lon_center = (lon_boundaries(0)+lon_boundaries(1))/2
     lon_center@description          = "Longitude center of region, west is negative"
     lon_center@long_name            = "longitude"
     lon_center@units                = "degrees_east"
     lon_center@bounds               = "REGION_LON_BOUNDS"
     ;lon_center!0                   = "ncenter"

   region_title = tochar(location)
     region_title!0 = "name_strlen"
     region_title@cf_role = "timeseries_id"
     region_title@long_name = "region name"

  nbounds = dimsizes(lat_boundaries)
  ntim = dimsizes(time_array)

  dim_names = (/ "time", "nbounds" /)
  dim_sizes = (/ ntim ,  nbounds /)
  dimUnlim = (/ True , False  /)
  filedimdef( fout, dim_names, dim_sizes, dimUnlim )

  ;------------
  ; Variable 
  ; Attributes
  ;------------
  yyyymm = climate_time
  yyyymm@long_name             = "YearMonth"
  yyyymm@units                 = "1"
  yyyymm@description           = "YearMonth"
  yyyymm!0                     = "time"
  yyyymm&time                  := time_array

  month_co_avg@long_name          = "MOPITT_CO_TotalColumn"
  month_co_avg@units              = "mol/cm^2"
  month_co_avg@description        = "molecules per cm^2"
  month_co_avg!0                  = "time"
  month_co_avg&time               := time_array
  month_co_avg@_FillValue         = 9.969209968386869e+36
  ;delete(month_co_avg@average_op_ncl)

  month_co_avg@long_name          = "MOPITT_CO_TotalColumn"
  month_co_avg@units              = "mol/cm^2"
  month_co_avg@description        = "molecules per cm^2"
  month_co_avg!0                  = "time"
  month_co_avg&time               = time_array
  month_co_avg@_FillValue         = 9.96921e+36 

  month_co_sd@long_name           = "MOPITT_CO_StdDev"
  month_co_sd@units               = "mol/cm^2"
  month_co_sd@description        = "molecules per cm^2"
  month_co_sd!0                   = "time"
  month_co_sd&time                = time_array
  month_co_sd@_FillValue          = 9.96921e+36 

  month_err_avg@long_name         = "MOPITT_CO_Column_Error"
  month_err_avg@units             = "mol/cm^2"
  month_err_avg@description       = "molecules per cm^2"
  month_err_avg!0                 = "time"
  month_err_avg&time              = time_array
  month_err_avg@_FillValue        = 9.96921e+36 
  ;delete(month_err_avg@average_op_ncl)

  new_month_co_avg@long_name      = "MOPITT_CO_TotalColumn_SplineFit"
  new_month_co_avg@units          = "mol/cm^2"
  new_month_co_avg@description    = "molecules per cm^2"
  new_month_co_avg!0              = "time"
  new_month_co_avg&time           = time_array
  new_month_co_avg@_FillValue     = 9.96921e+36
  new_month_co_avg@comment        = "Missing values filled using spline fit. Required for regression analysis."

  month_anomaly@long_name         = "MOPITT_CO_Anomaly"
  month_anomaly@units             = "mol/cm^2"
  month_anomaly@description       = "molecules per cm^2"
  month_anomaly!0                 = "time"
  month_anomaly&time              = time_array

  ;------------
  ; Write to
  ; file
  ;------------
  fout->MOPITT_CO_TCOL = month_co_avg
  fout->MOPITT_CO_SD = month_co_sd
  fout->MOPITT_CO_ERR = month_err_avg
  fout->MOPITT_CO_TCOL_FILLED = new_month_co_avg
  fout->MOPITT_CO_ANOMALY = month_anomaly
  fout->YYYYMM = yyyymm
  fout->REGION_LAT_BOUNDS = lat_boundaries
  fout->REGION_LON_BOUNDS = lon_boundaries
  fout->REGION_NAME = region_title

  filevardef (fout,(/"XLAT","XLON"/), (/"float","float"/), "ncl_scalar")
  filevarattdef (fout,"XLAT",lat_center)
  filevarattdef (fout,"XLON",lon_center)

  fout->XLAT = (/lat_center/)
  fout->XLON = (/lon_center/)


end if ;NETCDF

end
