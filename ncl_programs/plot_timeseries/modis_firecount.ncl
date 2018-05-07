;============================================
; modis_firecont.ncl
;============================================
;
; Concepts Illustrated
;          - Read
;
; To use type on the command line:
;          > ncl modis_firecont.ncl
;                            RRB Apr 30, 2018
;============================================
; load the libraries

begin

;--------------------------------------------
; user input
;--------------------------------------------
print("Start Time")
print(systemfunc("date"))
;general = "/amadeus-data/emmons/finn/fire_counts/"
;infiles_dummy = systemfunc ("ls "+ general +"MODIS_C6*.txt")
;infiles = infiles_dummy

general = "/home/buchholz/modis/C6/month_files/"
infiles_dummy = systemfunc ("ls "+ general +"*MCD*.txt")

infiles = infiles_dummy(0)
;infiles = infiles_dummy


  ;------------
  ; toggles
  ;------------
  PLOT           = True
  NRT            = False

  if (PLOT) then
    pltdir       = "./"
    pltname      = "modis_firecount"
    plttype      = "x11"                     ; workstation type
        plttype@wkWidth = 1200
        plttype@wkHeight = 1200 
  end if
  
;--------------------------------------------
; end user input
;--------------------------------------------

;--------------------------------------------
; Setup
;--------------------------------------------
; Creat array to collect number of lines
if (NRT) then
  firecount = new(dimsizes(infiles), integer)
  modis_date = new(dimsizes(infiles), string)
  date_array = new((/dimsizes(infiles),3/), string)
  modis_yyyymmdd = new(dimsizes(infiles), integer)
else
  modis_yyyymmdd= yyyymmdd_time(toint(2013), toint(2017), "integer")
  firecount = new(dimsizes(modis_yyyymmdd), integer)
  ;modis_type = new(dimsizes(modis_yyyymmdd), integer)
  ;modis_confidence = new(dimsizes(modis_yyyymmdd), integer)
  ;modis_sat = new(dimsizes(modis_yyyymmdd), string)
end if

;--------------------------------------------
; load file, extract and build up array
;--------------------------------------------

do i = 0, dimsizes(infiles)-1
 ;---Read the values in as 1D, since we don't know rows and columns yet.
  if (NRT) then
  lines  := asciiread(infiles(i),-1,"string")
  delim  = ","
    ncols  := dimsizes(str_split(lines(2),delim))
    nlines := dimsizes(lines)-1
    print("File "+i+", Columns:"+ncols+", Lines:"+nlines)

    firecount(i) = nlines-1
    modis_date(i) = str_get_field(lines(2),6,delim)
    date_array(i,:) = str_split(modis_date(i), "-")
    modis_yyyymmdd(i) = toint(date_array(i,0))*10000+toint(date_array(i,1))*100+toint(date_array(i,2))
  else 
  lines  := asciiread(infiles(i),-1,"string")
  delim  = " "
  ncols  := dimsizes(str_split(lines(2),delim))
  nlines := dimsizes(lines)-1
  print("File "+i+", Columns:"+ncols+", Lines:"+nlines)
  print(lines(0:20))
  read_in_yyyymmdd := toint(str_get_field(lines(1:),1,delim))
  read_in_sat := str_get_field(lines(1:),3,delim)
  read_in_conf := toint(str_get_field(lines(1:),10,delim))
  read_in_type := toint(str_get_field(lines(1:),11,delim))
  read_in_lat := tofloat(str_get_field(lines(1:),4,delim))
  read_in_lon := tofloat(str_get_field(lines(1:),5,delim))

printVarSummary(read_in_sat)
printVarSummary(read_in_lat)
printVarSummary(read_in_lon)
printVarSummary(read_in_yyyymmdd)

    do d = 0,dimsizes(modis_yyyymmdd)-1
      date_ind := ind(read_in_yyyymmdd.eq.modis_yyyymmdd(d))

      if (.not.ismissing(date_ind(0))) then
        date_ind@_FillValue = -999
        conf_select := read_in_conf(date_ind)
        conf_select@_FillValue = -999
        type_select := read_in_type(date_ind)
        type_select@_FillValue = -999
        sat_select := read_in_sat(date_ind)
        lat_select := read_in_lat(date_ind)
        lon_select := read_in_lon(date_ind)

        date_ind = where(conf_select.lt.50, date_ind@_FillValue, date_ind)
        date_ind = where(type_select.gt.0, date_ind@_FillValue, date_ind)

        ;do i = 1, dimsizes(date_ind)-1
        ;end do

        firecount(d) = num(.not.ismissing(date_ind))
      end if
    end do
  end if

end do

 yfrac = yyyymmdd_to_yyyyfrac(modis_yyyymmdd, 0.5)


;--------------------------------------------
; plot
;--------------------------------------------
if (PLOT) then
  print("start plotting")
  print(systemfunc("date"))
  wks = gsn_open_wks(plttype,pltname)    
 
  ;--------------------------
  ; Plot set-up
  ;--------------------------
  res                  = True                     ; plot mods desired   res@gsnDraw          = False
   res@gsnDraw          = False
   res@gsnFrame         = False
   res@gsnMaximize      = True

   res@vpWidthF         = 0.8
   res@vpHeightF        = 0.5   

   res@tmBorderThicknessF  = 4
   res@tmXBMajorThicknessF = 4
   res@tmYLMajorThicknessF = 4

   res@tiYAxisString            = "Number of fires"
   res@tiXAxisString            = "Year"

   res@xyLineThicknessF    = 5.5
   res@xyLineColor         = "red"

  ;-----------------------------------
  ; Add in legend for measured
  ;-----------------------------------
    res@pmLegendDisplayMode      = "Always"        ; turn on legend
    res@lgPerimOn                = False           ; Turn off perimeter
    res@pmLegendWidthF           = 0.10            ; Change width and
    res@lgLabelFontHeightF       = 0.024
    if (NRT) then
      res@xyExplicitLegendLabels   = "MODIS Collection 6 NRT (MCD14DL)"
    else
      res@xyExplicitLegendLabels   = "MODIS Collection 6 (MCD14ML)"
    end if
    res@pmLegendOrthogonalPosF   = -1.5
    res@pmLegendParallelPosF     = 0.76

  plot1  = gsn_csm_xy (wks,yfrac,firecount,res)  ; create plot

 draw(plot1)
 frame(wks)

end if

end

