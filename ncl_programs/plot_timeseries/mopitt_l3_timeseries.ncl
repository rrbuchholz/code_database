;=======================================================;
;  mopitt_l3_timeseries.ncl 
;=======================================================;
;
; Concepts illustrated:
;   - For use with MOPITT L3 Data
;     - load CO data
;     - average over region
;     - plot
;
;   Files needed:
;         -MOPITT L3 files
;         -Other instruments if desired: IASI, AIRS. Use Booleans.
;
;   To run type:
;         ncl regional_timeseries.ncl 
;                                  RRB May 7, 2019
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
  location = "SH"
  location_name = "SH"
    pltname      = "/net/mopfl/home/buchholz/"+location+"_trend"
  maxlag = 12
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  timeseries_files = systemfunc ("ls /MOPITT/V8T/Archive/L3/20*/month/*.he5")
  timeseries_files2 = systemfunc ("ls /MOPITT/V5T/Archive/L3/20*/month/*.hdf")

  scale_factor = 1e18
  unit = "~F34~4~F21~10~S2~18   molec. cm~S2~-2"
  yaxis = "Total column"

  ;scale_factor = 1e-09
  ;scale_factor = 1                 ;normalized
  ;unit = "ppb"
  ;yaxis = "Column average VMR (" +unit +")"
  ;yaxis = "Normalized CO"

  ;------------
  ; toggles
  ;------------
  PLOT           = True
    plttype      = "x11"
    ;plttype@wkPaperSize = "A4"
      plttype@wkWidth = 1200
      plttype@wkHeight = 1200
      plot_title = "Test"
 
   ADD_IASI      = False
      iasia_infiles = systemfunc ("ls /IASI/home/buchholz/IASI_subset/IASI_FORLI_CO_LATMOS_ULB_MetopA_day_monthlyMeans_*_v2.txt")
      iasib_infiles = systemfunc ("ls /IASI/home/buchholz/IASI_subset/IASI_FORLI_CO_LATMOS_ULB_MetopB_day_monthlyMeans_*_v2.txt")

   ADD_AIRS      = False
     if (location.eq."NH_thinned_2_5") then
       airs_infile = "/IASI/home/buchholz/AIRS/Data_for_Helen_NH.txt"
     else
       airs_infile = "/IASI/home/buchholz/AIRS/Data_for_Helen_SH.txt"
     end if

   ADD_TES      = False
     tes_infile = "/IASI/home/buchholz/TES/TES_xCO_monthly_n_s_V007.txt"


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
  ; determined from an ncl_filed
  suff           = "_MOP03"
  tracer         = "RetrievedCOTotalColumnDay"+suff
  oldtracer      = "Retrieved_CO_Total_Column_Day"
  latitude         = "Latitude"+suff
  longitude         = "Longitude"+suff

  ; -------------------------------
  ; OUTPUT RELATED SETUP
  ; -------------------------------
  if (PLOT) then
    pltdir       = "./"
    pltname      = location+"_MOPITT"
  end if

  ;Carriage return
   cr = tochar(10)

  ;Month names
  ; month_names = (/"RunAve","Jan", "Feb", "Mar", "Apr", "May", "Jun",\
  ;                  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"/)
   month_names = (/"RunAve","J", "F", "M", "A", "M", "J",\
                    "J", "A", "S", "O", "N", "D"/)

  ; -------------------------------
  ; constants
  ; -------------------------------
   NAv = 6.022e23                    ; Avogadro's number, molecules mole^-1
   g      = 9.81                             ;--- m/s - gravity
   H = (8.314*240)/(0.0289751*9.8)           ;--- scale height
   MWair = 28.94                             ;--- g/mol
   vmr_const = (10)/(MWair*g)            ;--- scaling factor for turning tcol into vmr

   re   = 6.37122e06                 ; Earth radius (in metres)
   rad  = 4.0 * atan(1.0) / 180.0    ; Convert degrees to radians (pi radians per 180 deg)
   con  = re * rad                   ; constant for determining arc length 

  region_names = (/"AnthChina", "AnthIndi", "AnthEuro", "AnthUSA",\
                    "BBUSA", "BBCanada", "BBSiberia", "BBWRus",\
                    "BBCAmerica", "BBSAmerica","BBSAmOcean",\
                     "BBCAfrica", "BBSAfrica","BBSAfOcean", \
                    "BBMSEA", "BBNWAu","BBEAu", "NH", "SH"/)

   ;                   minlat, maxlat, minlon, maxlon
   region_select = (/(/ 30.,  40.,      110.,      123./),\  ;AnthChina
                     (/ 20.,  30.,       70.,       95./),\  ;AnthIndi
                     (/ 45.,  55.,        0.,       15./),\  ;AnthEuro
                     (/ 35.,  40.,      -95.,      -75./),\  ;AnthUSA
                     (/ 38.,  50.,     -125.,     -105./),\  ;BBUSA
                     (/ 50.,  60.,     -125.,      -90./),\  ;BBCanada
                     (/ 50.,  60.,       90.,      140./),\  ;BBSiberia
                     (/ 35.,  50.,       40.,       85./),\  ;BBWRus
                     (/ 10.,  23.5,    -105.,      -70./),\  ;BBCAmerica
                     (/-25.,  -5.,      -75.,      -50./),\  ;BBSAmerica
                     (/-35., -15.,      -40.,      -25./),\  ;BBSAmericaOcean
                     (/  5.,  15.,      -20.,       38./),\  ;BBCAfrica
                     (/-20.,  -5.,       10.,       40./),\  ;BBSAfrica
                     (/-15.,   0.,      -10.,       10./),\  ;BBSAfOcean
                     (/-10.,   8.,        95.,     125./),\  ;BBMSEA
                     (/-25., -10.,       115.,     140./),\  ;BBNWAu
                     (/-45., -10.,       140.,     155./),\  ;BBEAu
                     (/  0.,  60.,      -179.5,    179.5/),\ ;NH
                     (/-60.,   0.,      -179.5,    179.5/) /);SH

   ind_region = ind(region_names.eq.location)

   topboundary     = region_select(ind_region,1)
   bottomboundary  = region_select(ind_region,0)
   rightboundary   = region_select(ind_region,3)
   leftboundary    = region_select(ind_region,2)

;--------------------------------------------
; load file and extract timeseries
;--------------------------------------------
  date_collect = str_split_csv(timeseries_files,"-",0)
  dates = toint(date_collect(:,1))
  yyyymm = yyyymm_time(2000,2018,"integer")   ; full timeseries
  yfrac = yyyymm_to_yyyyfrac(yyyymm,0)

  fin = addfiles(timeseries_files, "r")            ; read in
    ListSetType (fin, "join")                 ; concatenate
    timeseries_dummy          := fin[:]->$tracer$
    timeseries = dim_avg_n(dim_avg_n(timeseries_dummy(:,{leftboundary:rightboundary},{bottomboundary:topboundary}),1),1)

  fin2 = addfiles(timeseries_files2, "r")            ; read in
    ListSetType (fin2, "join")                 ; concatenate
    timeseries_dummy2  := fin2[:]->$oldtracer$
    dfs                := fin2[:]->Degrees_of_Freedom_for_Signal_Day
    oqi                := fin2[:]->Observation_Quality_Index_Day
  fin3 = addfile(timeseries_files2(0), "r")            ; read in
      lat2          := fin3->Latitude
      lon2          := fin3->Longitude

    timeseries_dummy2!1 = "latitude"
    timeseries_dummy2&latitude = lat2
    timeseries_dummy2!2 = "longitude"
    timeseries_dummy2&longitude = lon2
    timeseries_dummy2@_FillValue = -9999

printVarSummary(dfs)
printVarSummary(timeseries_dummy2)

    timeseries_dummy2_dfs = timeseries_dummy2
    timeseries_dummy2_dfs = where(dfs.lt.0.75,timeseries_dummy2@_FillValue,timeseries_dummy2)

    timeseries2 = dim_avg_n(dim_avg_n(timeseries_dummy2(:,{bottomboundary:topboundary},{leftboundary:rightboundary}),1),1)
    timeseries2a = dim_avg_n(dim_avg_n(timeseries_dummy2_dfs(:,{bottomboundary:topboundary},{leftboundary:rightboundary}),1),1)

    plot_timeseries_V8 = new(dimsizes(yyyymm), float)
    plot_timeseries_V5 = new(dimsizes(yyyymm), float)
    plot_timeseries_V5a = new(dimsizes(yyyymm), float)

    do i = 0,dimsizes(timeseries)-1
      ind_replace = ind(yyyymm.eq.dates(i))
      if (ismissing(ind_replace)) then
        continue
      else
        plot_timeseries_V8(ind_replace) = timeseries(i)
      end if
    end do

  date_collect2 = str_split_csv(timeseries_files2,"-",0)
  dates2 = toint(date_collect(:,1))
    do j = 0,dimsizes(timeseries2)-1
      ind_replace = ind(yyyymm.eq.dates2(j))
      plot_timeseries_V5(ind_replace) = timeseries2(j)
      plot_timeseries_V5a(ind_replace) = timeseries2a(j)
    end do

      plot_timeseries_V8!0 = "time"
      plot_timeseries_V8&time = yyyymm
      plot_timeseries_V8@_FillValue = -9999

      plot_timeseries_V5!0 = "time"
      plot_timeseries_V5&time = yyyymm
      plot_timeseries_V5@_FillValue = -9999

      plot_timeseries_V5a!0 = "time"
      plot_timeseries_V5a&time = yyyymm
      plot_timeseries_V5a@_FillValue = -9999

; Hack remove values that look weirdly low
plot_timeseries_V5(16) = plot_timeseries_V5@_FillValue
plot_timeseries_V5(19) = plot_timeseries_V5@_FillValue
plot_timeseries_V5(35) = plot_timeseries_V5@_FillValue



   ; [0] Mean, [1] StdDev, [2] Min, [3] LowQuartile, [4] Median, 
   ; [5] HighQuartile, [6] Max, [7] Total n, [8] Used n, [9] Missing, 
   ; [10] Lower 5.0% (for n > 1000), [11] Upper 5.0% (for n > 1000)
   ;timeseries = timeseries_dummy(:,(/0,10,3,4,5,11/))
   ;name_array = (/"mean", "5th", "25th", "median", \
   ;               "75th", "95th"/)

   if (ADD_IASI) then

     print(dimsizes(iasia_infiles))
     print("Collecting IASI")
   ; collect IASI_A data
   do filenum=0,dimsizes(iasia_infiles)-1
     iasia_infile = iasia_infiles(filenum)
     ;---Read the values in as 1D, since we don't know rows and columns yet.
     lines  := asciiread(iasia_infile,-1,"string")
     delim  = " "
     ncols  := dimsizes(str_split(lines(3),delim))
     nlines := dimsizes(lines)
     print("Columns:"+ncols+", Lines:"+nlines)

     ;---Reshape as 2D array, and convert to float for ppm/ppb/ppt.
     fields := new((/nlines,ncols/),float)
      do nf=0,ncols-1                    ;Remember that fields start at 1, not 0.
        fields(:,nf) = tofloat(str_get_field(lines(0:),nf+1,delim)) 
      end do

     if (.not.(isdefined("iasia_yyyymm"))) then
       iasia_yyyymm = (fields(0,0:ncols-1:6))
       iasia_tcol = fields(:,1:ncols-1:6)
       iasia_tcol!0 = "row"
       iasia_tcol!1 = "col"
       iasia_tcol_sd = fields(:,2:ncols-1:6)
       iasia_tcol_sd!0 = "row"
       iasia_tcol_sd!1 = "col"
       iasia_psurf = fields(:,3:ncols-1:6)
       iasia_psurf!0 = "row"
       iasia_psurf!1 = "col"
     else
       tempyyyymm := iasia_yyyymm
       temp_iasia_tcol := iasia_tcol
       temp_iasia_tcol_sd := iasia_tcol_sd
       temp_iasia_psurf := iasia_psurf

       dummy_yyyymm := fields(0,0:ncols-1:6)
       iasia_yyyymm := array_append_record(tempyyyymm,dummy_yyyymm,0)

       dummy_iasia_tcol := fields(:,1:ncols-1:6)
       dummy_iasia_tcol!0 = "row"
       dummy_iasia_tcol!1 = "col"
       iasia_tcol := table_attach_columns(temp_iasia_tcol,dummy_iasia_tcol,0)

       dummy_iasia_tcol_sd := fields(:,2:ncols-1:6)
       dummy_iasia_tcol_sd!0 = "row"
       dummy_iasia_tcol_sd!1 = "col"
       iasia_tcol_sd := table_attach_columns(temp_iasia_tcol_sd,dummy_iasia_tcol_sd,0)

       dummy_iasia_psurf := fields(:,3:ncols-1:6)
       dummy_iasia_psurf!0 = "row"
       dummy_iasia_psurf!1 = "col"
       iasia_psurf := table_attach_columns(temp_iasia_psurf,dummy_iasia_psurf,0)

     end if

    end do

; collect IASI_B data
   do filenum=0,dimsizes(iasib_infiles)-1
     iasib_infile = iasib_infiles(filenum)
     ;---Read the values in as 1D, since we don't know rows and columns yet.
     lines  := asciiread(iasib_infile,-1,"string")
     delim  = " "
     ncols  := dimsizes(str_split(lines(3),delim))
     nlines := dimsizes(lines)
     print("Columns:"+ncols+", Lines:"+nlines)

     ;---Reshape as 2D array, and convert to float for ppm/ppb/ppt.
     fields := new((/nlines,ncols/),float)
      do nf=0,ncols-1                    ;Remember that fields start at 1, not 0.
        fields(:,nf) = tofloat(str_get_field(lines(0:),nf+1,delim)) 
      end do

     if (.not.(isdefined("iasib_yyyymm"))) then
       iasib_yyyymm = (fields(0,0:ncols-1:6))
       iasib_tcol = fields(:,1:ncols-1:6)
       iasib_tcol!0 = "row"
       iasib_tcol!1 = "col"
       iasib_tcol_sd = fields(:,2:ncols-1:6)
       iasib_tcol_sd!0 = "row"
       iasib_tcol_sd!1 = "col"
       iasib_psurf = fields(:,3:ncols-1:6)
       iasib_psurf!0 = "row"
       iasib_psurf!1 = "col"
     else
       tempyyyymm := iasib_yyyymm
       temp_iasib_tcol := iasib_tcol
       temp_iasib_tcol_sd := iasib_tcol_sd
       temp_iasib_psurf := iasib_psurf

       dummy_yyyymm := fields(0,0:ncols-1:6)
       iasib_yyyymm := array_append_record(tempyyyymm,dummy_yyyymm,0)

       dummy_iasib_tcol := fields(:,1:ncols-1:6)
       dummy_iasib_tcol!0 = "row"
       dummy_iasib_tcol!1 = "col"
       iasib_tcol := table_attach_columns(temp_iasib_tcol,dummy_iasib_tcol,0)

       dummy_iasib_tcol_sd := fields(:,2:ncols-1:6)
       dummy_iasib_tcol_sd!0 = "row"
       dummy_iasib_tcol_sd!1 = "col"
       iasib_tcol_sd := table_attach_columns(temp_iasib_tcol_sd,dummy_iasib_tcol_sd,0)

       dummy_iasib_psurf := fields(:,3:ncols-1:6)
       dummy_iasib_psurf!0 = "row"
       dummy_iasib_psurf!1 = "col"
       iasib_psurf := table_attach_columns(temp_iasib_psurf,dummy_iasib_psurf,0)

     end if

    end do

       yfrac_iasia = yyyymm_to_yyyyfrac(toint(iasia_yyyymm), 0.5)
       yfrac_iasib = yyyymm_to_yyyyfrac(toint(iasib_yyyymm), 0.5)
   ; convert IASI to column average VMR
       colum_air_vmr_a = vmr_const * iasia_psurf * NAv
       colum_air_vmr_b = vmr_const * iasib_psurf * NAv
       iasia_region_loc = ind(region_names.eq.location)
       iasib_region_loc = ind(region_names.eq.location)

       ; Convert to X_CO
       iasia_xco = new((/3, dimsizes(yfrac_iasia)/),float)
       iasia_xco(0,:) = iasia_tcol(iasia_region_loc,:)/colum_air_vmr_a(iasia_region_loc,:)
       iasia_xco(1,:) = (iasia_tcol(iasia_region_loc,:)+iasia_tcol_sd(iasia_region_loc,:))\
                        /colum_air_vmr_a(iasia_region_loc,:)
       iasia_xco(2,:) = (iasia_tcol(iasia_region_loc,:)-iasia_tcol_sd(iasia_region_loc,:))\
                        /colum_air_vmr_a(iasia_region_loc,:)

       iasib_xco = new((/3, dimsizes(yfrac_iasib)/),float)
       iasib_xco(0,:) = iasib_tcol(iasib_region_loc,:)/colum_air_vmr_b(iasib_region_loc,:)
       iasib_xco(1,:) = (iasib_tcol(iasib_region_loc,:)+iasib_tcol_sd(iasib_region_loc,:))\
                        /colum_air_vmr_b(iasib_region_loc,:)
       iasib_xco(2,:) = (iasib_tcol(iasib_region_loc,:)-iasib_tcol_sd(iasib_region_loc,:))\
                        /colum_air_vmr_b(iasib_region_loc,:)
  
   end if


   if (ADD_AIRS) then

   ; collect AIRS data
     print("Collecting AIRS")
     ;---Read the values in as 1D, since we don't know rows and columns yet.
     lines  := asciiread(airs_infile,-1,"string")
printVarSummary(lines)
     delim  := " "
     ncols  := dimsizes(str_split(lines(3),delim))
     nlines := dimsizes(lines)
     print("Columns:"+ncols+", Lines:"+nlines)


     ;---Reshape as 2D array, and convert to float for ppm/ppb/ppt.
     fields := new((/nlines-3,ncols/),float)
      do nf=0,ncols-1                    ;Remember that fields start at 1, not 0.
        fields(:,nf) = tofloat(str_get_field(lines(3:),nf+1,delim)) 
      end do


     airs_yyyymm = fields(:,0)
        yfrac_airs = yyyymm_to_yyyyfrac(toint(airs_yyyymm), 0.5)
     airs_co = fields(:,4)*1e17
     airs_psurf = fields(:,2)
       aurs_air_vmr = vmr_const * airs_psurf * NAv
       airs_xco = airs_co/aurs_air_vmr
   end if



   if (ADD_TES) then

   ; collect TES data
     print("Collecting AIRS")
     ;---Read the values in as 1D, since we don't know rows and columns yet.
     lines  := asciiread(tes_infile,-1,"string")
printVarSummary(lines)
     delim  := " "
     ncols  := dimsizes(str_split(lines(3),delim))
     nlines := dimsizes(lines)
     print("Columns:"+ncols+", Lines:"+nlines)

     ;---Reshape as 2D array, and convert to float for ppm/ppb/ppt.
     fields := new((/nlines-1,ncols/),string)
      do nf=0,ncols-1                    ;Remember that fields start at 1, not 0.
        fields(:,nf) = str_get_field(lines(1:),nf+1,delim)
      end do

     tes_splitdate = str_split_csv(fields(:,0),"-",0)
     tes_yyyymm = tofloat(tes_splitdate(:,0))*100+tofloat(tes_splitdate(:,1))
        yfrac_tes = yyyymm_to_yyyyfrac(toint(tes_yyyymm), 0.5)
     if (location.eq."NH_thinned_2_5") then
        tes_xco = tofloat(fields(:,1))*1e-09
     else
        tes_xco = tofloat(fields(:,3))*1e-09
     end if

   end if


;--------------------------------------------
; Spline Fit to fill missing values
;--------------------------------------------
  new_timeseries = new(dimsizes(yyyymm), float)
    working_timeseries = plot_timeseries_V8
    ind_m_data := ind(.not.ismissing(working_timeseries))
    xi := yfrac(ind_m_data)
    yi := working_timeseries(ind_m_data)
    xo = yfrac
    yo = ftcurv(xi, yi, xo)
    new_timeseries_dummy = tofloat(where(ismissing(working_timeseries),yo,working_timeseries))
  copy_VarMeta(plot_timeseries_V8,new_timeseries)
   ind_trend = ind(yyyymm.lt.200201.or.yyyymm.ge.201901)
   new_timeseries(ind_trend) = timeseries@_FillValue

;--------------------------------------------
; Running average
;--------------------------------------------
 timeseries_runave = runave_n_Wrap(new_timeseries,12,0,0)

   if (ADD_IASI) then
     iasia_runave= runave_n_Wrap(iasia_xco,12,0,1)
     iasib_runave= runave_n_Wrap(iasib_xco,12,0,1)
   end if

   if (ADD_AIRS) then
     airs_runave = runave_n_Wrap(airs_xco,12,0,0)
   end if

   if (ADD_TES) then
     tes_runave = runave_n_Wrap(tes_xco,12,0,0)
   end if

;--------------------------------------------
; Normalize
;--------------------------------------------
ind_norm = ind(yyyymm.ge.200101.and.yyyymm.lt.201001)
  ;norm_average = avg(timeseries_runave(ind_norm))
  ;norm_average = 1
  ;norm_conform = conform_dims(dimsizes(timeseries_runave),norm_average,1)
  ;timeseries_runave_norm = timeseries_runave/norm_conform
  timeseries_runave_norm = timeseries_runave

   if (ADD_IASI) then
     ind_norm_iasia = ind(iasia_yyyymm.ge.200901.and.iasia_yyyymm.lt.201001)
       iasia_norm_average = dim_avg_n_Wrap(iasia_runave(:,ind_norm_iasia),1)
       iasia_norm_conform = conform_dims(dimsizes(iasia_runave),iasia_norm_average,0)
       iasia_runave_norm = iasia_runave/iasia_norm_conform

     ind_norm_iasib = ind(iasib_yyyymm.ge.201301.and.iasib_yyyymm.lt.201401)
       iasib_norm_average = dim_avg_n_Wrap(iasib_runave(:,ind_norm_iasib),1)
       iasib_norm_conform = conform_dims(dimsizes(iasib_runave),iasib_norm_average,0)
       iasib_runave_norm = iasib_runave/iasib_norm_conform
   end if

   if (ADD_AIRS) then
     ind_norm_airs = ind(airs_yyyymm.ge.200901.and.airs_yyyymm.lt.201001)
       airs_norm_average = dim_avg_n_Wrap(airs_runave(ind_norm_airs),0)
       airs_norm_conform = conform_dims(dimsizes(airs_runave),airs_norm_average,0)
       airs_runave_norm = airs_runave/airs_norm_conform
   end if

   if (ADD_TES) then
     ind_norm_tes = ind(tes_yyyymm.ge.200901.and.tes_yyyymm.lt.201001)
       tes_norm_average = dim_avg_n_Wrap(tes_runave(ind_norm_tes),0)
       tes_norm_conform = conform_dims(dimsizes(tes_runave),tes_norm_average,0)
       tes_runave_norm = tes_runave/tes_norm_conform
   end if



;--------------------------------------------
; Calculate trends
;--------------------------------------------
   rc   = regline(yfrac,timeseries_runave_norm)
   ols_trendplot = (rc*(yfrac-rc@xave) + rc@yave) ;* norm_average(0)
   rc_perc = (rc/(avg(timeseries_runave_norm)))* 100

   if (ADD_IASI) then
     iasia_rc   = regline(yfrac_iasia,iasia_runave_norm(0,:))
     iasia_ols_trendplot = (iasia_rc*(yfrac_iasia-iasia_rc@xave) + iasia_rc@yave) ;* iasia_norm_average(0)
     iasia_rc_perc = (iasia_rc/(avg(iasia_runave_norm)))* 100

     iasib_rc   = regline(yfrac_iasib,iasib_runave_norm(0,:))
     iasib_ols_trendplot = (iasib_rc*(yfrac_iasib-iasib_rc@xave) + iasib_rc@yave) ;* iasib_norm_average(0)
     iasib_rc_perc = (iasib_rc/(avg(iasib_runave_norm)))* 100
   end if

   if (ADD_AIRS) then
     airs_rc   = regline(yfrac_airs,airs_runave_norm)
     airs_ols_trendplot = (airs_rc*(yfrac_airs-airs_rc@xave) + airs_rc@yave) ;* airs_norm_average
     airs_rc_perc = (airs_rc/(avg(airs_runave_norm)))* 100
   end if


   if (ADD_TES) then
     tes_rc   = regline(yfrac_tes,tes_runave_norm)
     tes_ols_trendplot = (tes_rc*(yfrac_tes-tes_rc@xave) + tes_rc@yave) ;* tes_norm_average
     tes_rc_perc = (tes_rc/(avg(tes_runave_norm)))* 100
   end if

;--------------------------------------------
; plot
;--------------------------------------------
if (PLOT) then

  wks = gsn_open_wks(plttype,pltname)        
  gsn_define_colormap(wks,"BlAqGrYeOrRe")  
   
  res                       = True                      ; plot mods desired
    res@xyMarkLineMode      = "Lines"
    res@gsnDraw		    = False	                ; don't draw it yet
    res@gsnFrame            = False                     ; don't advance frame
    res@gsnMaximize         = True
    res@gsnRightStringFontHeightF =0.034

    res@xyLineThicknessF    = 7.0
    res@xyDashPatterns      = (/0,1,2,3,4/)
    res@xyLineColors        = (/"red2","orange", "forestgreen", "purple4"/)

    res@tmBorderThicknessF  = 3.0
    res@tmXBMajorThicknessF = 3.0
    res@tmYLMajorThicknessF = 3.0

    res@tmYLMajorOutwardLengthF = 0.0               ; draw tickmarks inward
    res@tmYLMinorOutwardLengthF = 0.0               ; draw minor ticks inward
    res@tmXBMajorOutwardLengthF = 0.0               
    res@tmXBMinorOutwardLengthF = 0.0   

    ;res@trYMinF             = 40
    ;res@trYMaxF             = 110
    res@trYMinF             = 1.0
    res@trYMaxF             = 2.0
    res@trXMinF             = 2001.0
    res@trXMaxF             = 2019.0

    res@vpWidthF             = 1
    res@vpHeightF            = 0.6          ; set height of plot

    res@tiMainString        = location + " average total column"
    res@gsnLeftString       = unit
    res@tiXAxisString       = "Year"
    res@tiYAxisString       = yaxis

    res@pmLegendDisplayMode      = "Always"        ; turn on legend
    res@lgPerimOn                = False           ; Turn off perimeter
    res@pmLegendWidthF           = 0.10           ; Change width and
    res@pmLegendHeightF          = 0.20             ; height of legend
    res@lgLabelFontHeightF       = 0.030
    ;res@xyExplicitLegendLabels   = "test"
    res@pmLegendOrthogonalPosF   = -1.605
    res@pmLegendParallelPosF     = 0.93

  ; -------------------------------
  ; create plot
  ; -------------------------------
    res@pmLegendDisplayMode = "Always"        ; turn on legend
    res@xyMarkLineModes      = (/"Lines","Lines","Lines"/)
    res@xyMarkers           = (/4,4,4,4/)            ; choose type of marker  
    res@xyMarkerThicknessF  = (/6,6,6,6,6,6/)
    res@xyMarkerSizeF       = 0.024
    res@xyMarkerColors      = (/"black","red","blue"/)
    res@xyExplicitLegendLabels   = (/"V8T"/)
    res@xyLineColors        := (/"grey"/)
    res@xyLineThicknessF    = 9.0
;V8T
    plot = gsn_csm_xy(wks,yfrac,plot_timeseries_V8/scale_factor,res)
    res@pmLegendOrthogonalPosF   = -1.505
    res@xyExplicitLegendLabels   = (/"V5T"/)
    res@xyLineThicknessF    = 7.0
    res@xyLineColors        := (/"red"/)
;V5T
    ;plot2 = gsn_csm_xy(wks,yfrac,plot_timeseries_V5/scale_factor,res)
    ;overlay(plot,plot2)
    plot3 = gsn_csm_xy(wks,yfrac,plot_timeseries_V5a/scale_factor,res)
    overlay(plot,plot3)

    if (ADD_IASI) then
    res@pmLegendOrthogonalPosF   = -1.555
      res@xyExplicitLegendLabels   = (/"IASI_A", "+sd", "-sd"/)
      res@xyLineColors        := (/"green","pink","grey60","red","red4"/)
      ;plot2a = gsn_csm_xy(wks,yfrac_iasia,iasia_xco(0,:)/scale_factor,res)
      plot2a = gsn_csm_xy(wks,yfrac_iasia,iasia_runave_norm(1,:),res)
      res@xyLineColors        := (/"forestgreen","pink","grey60","red","red4"/)
      res@xyExplicitLegendLabels   = (/"IASI_B", "+sd", "-sd"/)
      res@pmLegendOrthogonalPosF   = -1.505
      ;plot2b = gsn_csm_xy(wks,yfrac_iasib,iasib_xco(0,:)/scale_factor,res)
      plot2b = gsn_csm_xy(wks,yfrac_iasib,iasib_runave_norm(1,:),res)
      overlay(plot,plot2a)
      overlay(plot,plot2b)
    end if

    if (ADD_AIRS) then
    res@pmLegendOrthogonalPosF   = -1.455
      res@xyExplicitLegendLabels   = (/"AIRS", "+sd", "-sd"/)
      res@xyLineColors        := (/"red","red","pink","grey60","red","red4"/)
      ;plot3 = gsn_csm_xy(wks,yfrac_airs,airs_xco/scale_factor,res)
      plot3 = gsn_csm_xy(wks,yfrac_airs,airs_runave_norm,res)
      overlay(plot,plot3)
    end if

    if (ADD_TES) then
    res@pmLegendOrthogonalPosF   = -1.405
      res@xyExplicitLegendLabels   = (/"TES", "+sd", "-sd"/)
      res@xyLineColors        := (/"blue","red","pink","grey60","red","red4"/)
      ;plot4 = gsn_csm_xy(wks,yfrac_tes,tes_xco/scale_factor,res)
      plot4 = gsn_csm_xy(wks,yfrac_tes,tes_runave_norm,res)
      overlay(plot,plot4)
    end if
    res@gsnLeftString       = "" 

  ; -------------------------------
  ; plot trend
  ; -------------------------------
    ; OLS
    res@pmLegendDisplayMode      = "Always"        ; turn on legend
    res@xyLineColors        := (/"black"/)
    res@xyDashPatterns      := (/1/)
    res@xyExplicitLegendLabels   := (/"MOPITT: "+sprintf("%4.3g",rc_perc)+"%"/)
    res@pmLegendOrthogonalPosF   = -1.605
    res@pmLegendParallelPosF     = 0.62
    plot_t1 = gsn_csm_xy(wks,yfrac,ols_trendplot/scale_factor,res)
    ;overlay(plot,plot_t1)

    if (ADD_IASI) then
    res@pmLegendDisplayMode = "Never"        ; turn on legend
    res@xyLineColors        := (/"green"/)
    res@pmLegendOrthogonalPosF   = -1.555
    res@xyExplicitLegendLabels   := (/"IASI_A: "+sprintf("%4.3g",iasia_rc_perc)+"%"/)
      plot_t2a = gsn_csm_xy(wks,yfrac_iasia,iasia_ols_trendplot/scale_factor,res)
      ;overlay(plot,plot_t2a)
    res@xyLineColors        := (/"forestgreen"/)
    res@pmLegendOrthogonalPosF   = -1.505
    res@xyExplicitLegendLabels   := (/"IASI_B: "+sprintf("%4.3g",iasib_rc_perc)+"%"/)
      plot_t2a = gsn_csm_xy(wks,yfrac_iasib,iasib_ols_trendplot/scale_factor,res)
      ;overlay(plot,plot_t2a)
    end if

    if (ADD_AIRS) then
    res@pmLegendDisplayMode = "Always"        ; turn on legend
    res@xyLineColors        := (/"red"/)
    res@pmLegendOrthogonalPosF   = -1.455
    res@xyExplicitLegendLabels   := (/"AIRS: "+sprintf("%4.3g",airs_rc_perc)+"%"/)
      plot_t3 = gsn_csm_xy(wks,yfrac_airs,airs_ols_trendplot/scale_factor,res)
      overlay(plot,plot_t3)
    end if

    if (ADD_TES) then
    res@pmLegendDisplayMode = "Never"        ; turn on legend
    res@xyLineColors        := (/"blue"/)
    res@pmLegendOrthogonalPosF   = -1.405
    res@xyExplicitLegendLabels   := (/"TES: "+sprintf("%4.3g",tes_rc_perc)+"%"/)
      plot_t4 = gsn_csm_xy(wks,yfrac_tes,tes_ols_trendplot/scale_factor,res)
      ;overlay(plot,plot_t4)
    end if


  ; -------------------------------
  ; add legend
  ; -------------------------------
    txres                   = True                     ; polyline mods desired
     txres@txFontHeightF    = 0.020                   ; font smaller. default big
     txres@txJust           = "CenterCenter"
     txres@txPerimOn        = False
     txres@txFontColor      = "black"                  
    ;gsn_text_ndc(wks,"Theil-Sen",0.71,0.86,txres)
    ;gsn_text_ndc(wks,sprintf("%4.2e",trend_array_col(0)),0.71,0.82,txres)
    ;gsn_text_ndc(wks,sprintf("%4.3g",trend_array(0))+" % p.y.",0.71,0.78,txres)


    txres@txPerimOn        = True
    ;gsn_text_ndc(wks,location_name,0.78,0.67,txres)


  ; -------------------------------
  ; panel the plots
  ; -------------------------------
     resP = True
   ; gsn_panel(wks,plot_arr,(/4,3/),resP) 

    draw(plot)
    frame(wks)

    ;draw(plot4)
    ;frame(wks)

end if



end

