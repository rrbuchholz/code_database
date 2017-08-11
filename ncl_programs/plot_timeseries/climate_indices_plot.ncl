;=======================================================;
;  climate_indices_plot.ncl
;=======================================================;
;
; Concepts illustrated:
;   - Load and plot climate indices
;   - Write month averages out to a .csv or .nc file
;
;   Files needed:
;         -Climate index files
;
;   To run type:
;         ncl climate_indices_plot.ncl
;                                  RRB February 11, 2015
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
  index = "satl"

  if (index.eq."dmi_2") then
    index_file = "/IASI/home/buchholz/Climate_Indices/dmi_2.nc"
  else
    index_file = "/IASI/home/buchholz/Climate_Indices/"+index+".txt"
  end if

  ;------------
  ; toggles
  ;------------
  PLOT           = True
    plttype      = "png"
    ;plttype@wkPaperSize = "A4"
      plttype@wkWidth = 1200
      plttype@wkHeight = 1200
    year_s = 2001
    year_e = 2017
    index_name = "TSA"
    sub_label = "(e) "
    ymin       = -1.0
    ymax       = 1.0
    minlab     = -0.8
    maxlab     = 0.8
    ylab_min   = "-0.8"
    ylab_max   = "0.8"
    spacing    = 0.8
    units      = "(~F34~0~F~C)"
    ;units      = ""


  CSV            = False
  if (CSV) then
     outname      = index+"_month_avg.csv"
  end if

  NETCDF            = False
  if (NETCDF) then
     nc_outname      = index+"_index_month_avg.nc"
  end if


  
;--------------------------------------------
; end user input
;--------------------------------------------
;
;--------------------------------------------
; set up
;--------------------------------------------

  ; -------------------------------
  ; OUTPUT RELATED SETUP
  ; -------------------------------
  if (PLOT) then
    pltdir       = "/IASI/home/buchholz/"
    pltname      = pltdir+index+"_plot"
  end if


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
  ; Indecies
  ; -------------------------------
  ;---Read the values in as 1D, since we don't know rows and columns yet.
  lines  = asciiread(index_file,-1,"string")
  delim  = " "

  if (index.eq."dmi_2") then
    fin = addfile(index_file, "r")            ; read in
    index_anomaly_dummy    = fin->$"DMI"$
    index_date_dummy       = fin->$"WEDCEN2"$
    index_time_dummy  = cd_calendar(index_date_dummy,0)
      ; MONTH AVERAGES and ANOMALIES
      startyear = index_time_dummy(0,0)
      endyear = index_time_dummy(dimsizes(index_date_dummy)-1,0)

      do y=startyear,endyear
        do m=1,12
          print(y+"_"+m)
          date_ind := ind(index_time_dummy(:,0).eq.y.and.\
                      index_time_dummy(:,1).eq.m)
        if (ismissing(date_ind(0))) then
          continue
        end if
        if (.not.(isdefined("index_anomaly"))) then
          index_anomaly := avg(index_anomaly_dummy(date_ind))
          index_date = y*100 +m
        else
          dummy0 := index_anomaly
          dummy1 := index_date
          index_anomaly := array_append_record(dummy0,avg(index_anomaly_dummy(date_ind)),0)
          index_date := array_append_record(dummy1,y*100 +m,0)
        end if
        end do
      end do

  else
    ncols  = dimsizes(str_split(lines(3),delim))
    nlines = dimsizes(lines)-1
    print("Columns:"+ncols+", Lines:"+nlines)

    ;---Reshape as 2D array, and convert to float for ppm/ppb/ppt.
    fields = new((/nlines,ncols/),float)
    do nf=0,ncols-1                    ;Remember that fields start at 1, not 0.
      fields(:,nf) = tofloat(str_get_field(lines(1:),nf+1,delim)) 
    end do

    if (index.eq."nino34") then
      index_date    = fields(:,0)*100 +fields(:,1)
      index_anomaly = fields(:,4)

    else if (index.eq."satl") then
      index_date    = fields(:,0)*100 +fields(:,1)
      index_anomaly = fields(:,5)

    else if (index.eq."dmi") then
      index_anomaly_dummy = fields(:,1)
      fieldsII = new((/nlines,4/),float)
      do nf=0,3                   ;Remember that fields start at 1, not 0.
        fieldsII(:,nf) = tofloat(str_get_field(lines(1:),nf+1,":")) 
      end do
      ; MONTH AVERAGES and ANOMALIES
      startyear = fieldsII(0,0)
      endyear = fieldsII(nlines-1,0)
      do y=startyear,endyear
        do m=1,12
          print(y+"_"+m)
          date_ind := ind(fieldsII(:,0).eq.y.and.\
                      fieldsII(:,1).eq.m)
        if (ismissing(date_ind(0))) then
          continue
        end if
        if (.not.(isdefined("index_anomaly"))) then
          index_anomaly := avg(index_anomaly_dummy(date_ind))
          index_date = y*100 +m
        else
          dummy0 := index_anomaly
          dummy1 := index_date
          index_anomaly := array_append_record(dummy0,avg(index_anomaly_dummy(date_ind)),0)
          index_date := array_append_record(dummy1,y*100 +m,0)
        end if
        end do
      end do

    else if (index.eq."aao".or.index.eq."amo".or.index.eq."tsa") then
      index_date    = fields(:,0)*100 +fields(:,1)
      index_anomaly = fields(:,2)
      ;index_anomaly_dummy = fields(:,1::)
      ;index_anomaly = ndtooned(index_anomaly_dummy)
      ;index_date = yyyymm_time(toint(fields(0,0)),toint(fields(nlines-1,0)),"float")
    end if
    end if
    end if
    end if
  end if

  index_time = yyyymm_to_yyyyfrac(index_date,0)

;print(dimsizes(index_time))
;print(dimsizes(index_anomaly))

;--------------------------------------------
; plot
;--------------------------------------------
if (PLOT) then

  wks = gsn_open_wks(plttype,pltname)        
  gsn_define_colormap(wks,"BlAqGrYeOrRe")  
   
  res                       = True                      ; plot mods desired
    res@gsnDraw		    = False	                ; don't draw it yet
    res@gsnFrame            = False                     ; don't advance frame
    res@gsnMaximize         = True

;---Turn off top, bottom, and right axis.
    res@tmXTOn       = False
    res@tmXTBorderOn = False
    res@tmXBOn       = True
    res@tmXBBorderOn = False

    res@tmBorderThicknessF   = 3
    res@tmXBMajorThicknessF  = 3
    res@tmYLMajorThicknessF  = 3

    res@tiXAxisString        = "Year"	
    res@tmXBMode            = "Explicit"
      res@trXMinF             = year_s
      res@trXMaxF             = year_e
      res@tmXBValues           = tofloat(ispan(year_s,year_e,3))
      res@tmXBLabels           = tofloat(ispan(year_s,year_e,3))
      res@tmXBMinorValues      = tofloat(ispan(year_s,year_e,1))
      res@tmXBLabelsOn         = True
      res@tmYLLabelsOn         = True
      ;res@tmYRLabelsOn        = True

    res@tmXBLabelFontHeightF  = 0.048
    res@tmYLLabelFontHeightF  = 0.048
    res@tiYAxisFontHeightF    = 0.049
    res@tiXAxisFontHeightF    = 0.049

    res@tmYLMajorOutwardLengthF = 0.0               ; draw tickmarks inward
    res@tmYLMinorOutwardLengthF = 0.0                 ; draw minor ticsk inward
    res@tmXBMajorOutwardLengthF = 0.0               
    res@tmXBMinorOutwardLengthF = 0.0              

    res@vpWidthF             = 1.8
    res@vpHeightF            = 0.30          ; set height of plot

    res@tiMainString        = ""

  ; -------------------------------
  ; Anomaly plot
  ; -------------------------------
    res@xyMarkLineMode      = "Lines"
    res@xyLineThicknessF    = 1.5
    res@tmYLMode        = "Explicit"
      res@trYMinF             = ymin
      res@trYMaxF             = ymax
      res@tmYLValues          := (/minlab, 0.0, maxlab/)
      res@tmYLLabels          := (/ylab_min, "0", ylab_max/)
      res@tmYLMinorValues     := (/-0.25e18, 0.25e18, 0.75e18/)

    res@tiYAxisString       = "Anomaly "+ units
    res@xyLineColor         = "black"

    res@gsnYRefLine      = 0
    res@gsnAboveYRefLineColor = "red"          ; above ref line fill red
    res@gsnBelowYRefLineColor = "blue"         ; below ref line fill blue

  plottime := index_time
  plot = gsn_csm_xy(wks,plottime,index_anomaly,res)

 ; add zero line
  res_lines                   = True                     ; polyline mods desired
    res_lines@gsLineDashPattern = 0                 ; line style
    res_lines@gsLineThicknessF  = 2.5                     ; line thicker
    res_lines@gsLineColor       = "black"                 ; line color
    res_lines@tfPolyDrawOrder   = "PreDraw"              ; send to back
  xx = (/year_s,year_e/)
  yy = (/0,0/)
  dum = gsn_add_polyline(wks,plot,xx,yy,res_lines)      ; add polyline

  ; Add in text
  ;drawNDCGrid(wks)
  txres                   = True                     ; polyline mods desired
    txres@txJust           = "CenterLeft"             ; font smaller. default big
    txres@txFontHeightF     = 0.024                   ; font smaller. default big
  gsn_text_ndc(wks,sub_label+index_name,0.17,0.565,txres)

  draw(plot)    ; All three plots will be drawn.
  frame(wks)

end if

;--------------------------------------------
; Write out to a ASCII file
;--------------------------------------------
if (CSV) then

;---Create dummy mixed data to write to CSV file
  field_strings = (/"time","anomaly"/)
  dq = str_get_dq()                ; double quote character
  field_strings = dq + field_strings + dq                      ; Pre/append quotes to field names
  header = [/str_join(field_strings,",")/]              ; Header is field names separated
                                                 ;   by commas.

  index_time_2 = toint(index_date*100)+1

  alist  = [/index_time_2,index_anomaly/]   ; List of variables to write.
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
  setfileoption(fout, "DefineMode",True)
    fAtt                      = True
      fAtt@title              = "Anomalies for " +index
      ;fAtt@source             = "NOAA"
      fAtt@creation_date      = systemfunc ("date")
      fAtt@conventrions       = "CF"

     fileattdef(fout, fAtt)
  setfileoption(fout, "DefineMode",False)

  ;------------
  ; Variable 
  ; Attributes
  ;------------
  index_date@units             = "YYYYMM"

  time_array = index_date
  time_array@long_name         = "time"
  time_array@units             = "YYYYMM"
  time_array!0                 = "time"

  index_anomaly@units             = "molec/cm^2"
  index_anomaly!0                 = "time"
  index_anomaly&time              = index_date


  if (index.eq."satl") then
    name = "SATL_ANOMALY"
    index_anomaly@long_name         = "SouthAtlantic_Anomaly"
  else if (index.eq."dmi_2".or.index.eq."dmi") then
    name = "DMI_ANOMALY"
    index_anomaly@long_name         = "IndianOceanDipole_Anomaly"
  else if (index.eq."aao") then
    name = "AAO_ANOMALY"
    index_anomaly@long_name         = "AntarcticOscillation_Anomaly"
  else if (index.eq."nino34") then
    name = "NINO34_ANOMALY"
    index_anomaly@long_name         = "ENSO_Anomaly"
  else
    name = "INDEX_ANOMALY"
    index_anomaly@long_name         = "Climate_Anomaly"
  end if
  end if
  end if
  end if

  ;fout->TIME  = time_array
  fout->$name$ = index_anomaly


end if ;NETCDF


end

