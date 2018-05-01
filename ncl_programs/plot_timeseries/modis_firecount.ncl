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
general = "/amadeus-data/emmons/finn/fire_counts/"
infiles_dummy = systemfunc ("ls "+ general +"MODIS_C6*.txt")

;infiles = infiles_dummy(0:50)
infiles = infiles_dummy


  ;------------
  ; toggles
  ;------------
  PLOT           = True

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

firecount = new(dimsizes(infiles), integer)
modis_date = new(dimsizes(infiles), string)
date_array = new((/dimsizes(infiles),3/), string)
modis_yyyymmdd = new(dimsizes(infiles), integer)

;--------------------------------------------
; load file, extract and build up array
;--------------------------------------------

do i = 0, dimsizes(infiles)-1
 ;---Read the values in as 1D, since we don't know rows and columns yet.
  lines  := asciiread(infiles(i),-1,"string")
  delim  = ","

    ncols  := dimsizes(str_split(lines(2),delim))
    nlines := dimsizes(lines)-1
    print("File "+i+", Columns:"+ncols+", Lines:"+nlines)
    firecount(i) = nlines-1
    modis_date(i) = str_get_field(lines(2),6,delim)
    date_array(i,:) = str_split(modis_date(i), "-")
    modis_yyyymmdd(i) = toint(date_array(i,0))*10000+toint(date_array(i,1))*100+toint(date_array(i,2))
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
    res@xyExplicitLegendLabels   = "MODIS Collection 6 NRT (MCD14DL)"
    res@pmLegendOrthogonalPosF   = -1.5
    res@pmLegendParallelPosF     = 0.76

  plot1  = gsn_csm_xy (wks,yfrac,firecount,res)  ; create plot

 draw(plot1)
 frame(wks)

end if

end

