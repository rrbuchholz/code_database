;=======================================================;
;  station_seasonal_cycles.ncl 
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
; Tagged tracer definitions
;
;   CO01           Methane oxidation produced CO (0.86 * CO from reaction of OH with CH4, Shindell 2006)
;
;   CO02           Biogenic emissions of CO from MEGAN (global)
;
;   CO03           Biomass burning CO in Australasia
;   CO04           Biomass burning CO in Southeast Asia
;   CO05           Biomass burning CO in Northeast Asia
;   CO06           Biomass burning CO in Siberia
;   CO07           Biomass burning CO in India
;   CO08           Biomass burning CO in West Russia
;   CO09           Biomass burning CO in Southern Africa
;   CO10           Biomass burning CO in Northern Africa and Middle East
;   CO11           Biomass burning CO in Europe
;   CO12           Biomass burning CO in South America
;   CO13           Biomass burning CO in Central America
;   CO14           Biomass burning CO in North America
;   CO15           Biomass burning CO in Southern Hemisphere
;   CO16           Biomass burning CO in Northern Hemisphere
;
;   CO17           Anthropogenic CO in Australasia
;   CO18           Anthropogenic CO in Southeast Asia
;   CO19           Anthropogenic CO in Northeast Asia
;   CO20           Anthropogenic CO in Siberia
;   CO21           Anthropogenic CO in India
;   CO22           Anthropogenic CO in West Russia
;   CO23           Anthropogenic CO in Southern Africa
;   CO24           Anthropogenic CO in Northern Africa and Middle East
;   CO25           Anthropogenic CO in Europe
;   CO26           Anthropogenic CO in South America
;   CO27           Anthropogenic CO in Central America
;   CO28           Anthropogenic CO in North America
;   CO29           Anthropogenic CO in Southern Hemisphere
;   CO30           Anthropogenic CO in Northern Hemisphere
;
;   Files needed:
;         -MOPITT subset of level 2, daily hdf files
;         -FTS files
;
;   To run type:
;         avg-plus-event-identify.ncl
;                                  RRB April 19, 2018
;=======================================================;
; load the libraries
load "~/code_database/ncl_programs/buchholz_global_util/calc_seasonal_cycle.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------

  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  version = "V7"
  suff = "J"
  location = "Darwin"
  surface = "land"
  year_s = 2001
  network = "TCCON"

  ; -------------------------------
  ; CAM-chem files
  ; -------------------------------
  folder = "~/CAM_chem/stations/"
  model_files_dummy = systemfunc ("ls "+folder+"CAM_Chem_DWL*.nc")
  model_filenames = model_files_dummy


  ;------------
  ; toggles
  ;------------
  PLOT           = True
    plttype      = "x11"
    ;plttype@wkPaperSize = "A4"
    ;plttype@wkWidth = 0.5
    ;plttype@wkHeight = 0.5
    year_e = 2017

  PLOTFTS        = True
  
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
  if (network.eq."TCCON") then
      fts_files =  systemfunc ("ls /IASI/home/buchholz/FTS_data/TCCON/co/"+sm_location+"/*.public.nc")
  else
      fts_files =  systemfunc ("ls /IASI/home/buchholz/FTS_data/NDACC/co/"+sm_location+"/groundbased_ftir.co_*.hdf")
  end if

  ; -------------------------------
  ; OUTPUT RELATED SETUP
  ; -------------------------------
  if (PLOT) then
    pltdir       = "./"
    pltname      = version+"mopitt_l2_vs_fts_" + location
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
    mopitt_time    = mopitt_time_dummy(year_select_ind)     
     ; local time in seconds since 1993-1-1 00:00:00 (TAI93)
    mopitt_date    = cd_calendar(mopitt_time, 0)
      years  = floattointeger(mopitt_date(:,0))
    yyyymmdd       = cd_calendar(mopitt_time, 2)
    day_yfrac      = cd_calendar(mopitt_time, 4)

  if (PLOTFTS) then
  ; -------------------------------
  ; FTS
  ; -------------------------------
    fts_in = addfiles (fts_files, "r")
    ListSetType (fts_in, "cat")             ; concatenate or "merge" (default)

   if (network.eq."TCCON") then
    print("***Reading FTS data at " + location)
    fts_xco            = fts_in[:]->$"xco_ppb"$
    fts_psurf          = fts_in[:]->$"pout_hPa"$
    ; convert xCO to tcol
    fts_tcol = (xp_const * fts_xco) * fts_psurf
    ; Date in MJD2000, fraction of days since 
    ; 1970/1/1 00:00:00
    fts_mjd2000         = fts_in[:]->$"time"$
    fts_local           = fts_mjd2000+(time_diff/24.)
    fts_local@units     = "days since 1970-01-01 00:00:0.0"

   else
    print("***Reading FTS data at " + location)
    ; SELECT FTS DATA AFTER STARTDATE
    fts_mjd2000_dummy    = fts_in[:]->$fts_datetime$
    fts_local_dummy      = fts_mjd2000_dummy +(time_diff/24.)
      fts_local_dummy@units = "days since 2000-01-01 00:00:0.0"
    fts_date_dummy       = cd_calendar(fts_local_dummy , 0)
      fts_years_dummy    = floattointeger(fts_date_dummy(:,0))
      year_select_fts    = ind(fts_years_dummy.ge.year_s)

    fts_tcol_dummy       = fts_in[:]->$fts_tracer$
      fts_tcol           = fts_tcol_dummy(year_select_fts)
      copy_VarMeta(fts_tcol_dummy, fts_tcol)
    fts_local            = fts_local_dummy(year_select_fts)
  end if

    fts_date             = cd_calendar(fts_local, 0)
      fts_years          = floattointeger(fts_date(:,0))
    fts_yyyymmdd         = cd_calendar(fts_local, 2)

  end if ;(PLOTFTS)

  ; -------------------------------
  ; CAM-chem
  ; -------------------------------
  ; names of data structures
  ; determined from a ncl_filedump
    print("***Reading CAM-chem data at " + location)
    model_in = addfiles(model_filenames, "r")           ; read in
    ListSetType (model_in, "cat")                 ; concatenate
    model_time           = model_in[:]->time
    model_date           = cd_calendar(model_time, 0)
      model_years        = floattointeger(fts_date(:,0))

  ; -------------------------------
  ; loop over extracting tracers
  ; -------------------------------
  tracer = (/"CO", "CO01", "CO02", "CO03", "CO04", "CO05", "CO06", "CO07", "CO08", "CO09", "CO10",\
            "CO11", "CO12", "CO13", "CO14", "CO15", "CO16", "CO17", "CO18", "CO19", "CO20",\
            "CO21", "CO22", "CO23", "CO24", "CO25", "CO26", "CO27", "CO28", "CO29", "CO30"/)

  ; set-up tcol collection array
    tcol_arr   = new((/dimsizes(model_time),dimsizes(tracer)/), float)

  do i = 0, dimsizes(tracer)-1
     varname = tracer(i)+"_TotalColumn"
     tcol     := model_in[:]->$varname$
     if (location.eq."Darwin") then
       tcol_arr(:,i) = tcol(:,0)
     else if (location.eq."Wollongong") then
       tcol_arr(:,i) = tcol(:,1)
     else if (location.eq."Lauder") then
       tcol_arr(:,i) = tcol(:,2)
     end if
     end if
     end if
  end do
     tcol_arr!1 = "tag"
     tcol_arr@locations := location


;********************************************
;--------------------------------------------
; perform calculations
;--------------------------------------------
  ; -------------------------------
  ; Time definitions
  ; ------------------------------- 
    climate_time = yyyymmdd_time(toint(years(0)), toint(years(dimsizes(years)-1)), "integer")
      climate_yyyy  = climate_time/10000 
      climate_mmdd  = climate_time-climate_yyyy*10000
      climate_mm    = climate_mmdd/100
      climate_dd    = climate_mmdd-climate_mm*100
      ; create arrays [*] of required size
      climate_hh    = climate_dd                                 
      climate_mn    = climate_dd
      climate_sc    = climate_dd
      ; replace entries with 0 using array syntax
      climate_hh    = 0                                  
      climate_mn    = 0
      climate_sc    = 0
      climate_units  = "days since 1970-01-01 00:00:0.0" 

      climate_inv_time = cd_inv_calendar(climate_yyyy,climate_mm,climate_dd,climate_hh,climate_mn,\
                                climate_sc,climate_units, 0)
      climate_inv_time!0 = "time"

  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  mopitt_seas_avg = calc_seasonal_cycle(mopitt_tcol,mopitt_time,year_s,years(dimsizes(years)-1), 230)
    Clm_doy = mopitt_seas_avg&year_day                    ;366 days in climate year
    climate_year = yyyyddd_to_yyyymmdd(2004000+mopitt_seas_avg&year_day)
    avg_clim_yfrac = yyyymmdd_to_yyyyfrac(climate_year, 0.5)
    split_mm =str_split_by_length(tostring(climate_year),2)


  ;********************************************
  if (PLOTFTS) then
  ; -------------------------------
  ; FTS
  ; -------------------------------
  ; -------------------------------
  ; DAY AVERAGE VALUES
  ; ------------------------------- 
    fts_dayavg = new(dimsizes(climate_time),double)   ;needs to be 3D for climate calculations
    do i = 0, dimsizes(climate_time)-1
      fts_dayavg_ind := ind(toint(fts_yyyymmdd).eq.climate_time(i))
      if (.not.ismissing(fts_dayavg_ind(0)))then
        fts_dayavg(i) = avg(fts_tcol(fts_dayavg_ind))
      end if
    end do

    ind_nomissing = ind(.not.ismissing(fts_dayavg))

  ; -------------------------------
  ; CALC SEAS CYCLE
  ; ------------------------------- 
  if (location.eq."Darwin") then
    fts_seas_avg = calc_seasonal_cycle(fts_dayavg(ind_nomissing),climate_inv_time(ind_nomissing),\
                                       fts_years(0), fts_years(dimsizes(fts_years)-1), 300)
  else
    fts_seas_avg = calc_seasonal_cycle(fts_dayavg(ind_nomissing),climate_inv_time(ind_nomissing),\
                                       year_s, fts_years(dimsizes(fts_years)-1), 300)
  end if


  end if ;(PLOTFTS)

  ; -------------------------------
  ; CAM-chem
  ; -------------------------------

    methox_co = tcol_arr(:,1)
    biog_co = tcol_arr(:,2)
    anth_co = dim_sum_n(tcol_arr(:,29:30),1)
    bb_co = dim_sum_n(tcol_arr(:,15:16),1)
    residual_co = tcol_arr(:,0)-bb_co-anth_co-biog_co-methox_co
    data_collect = (/todouble(tcol_arr(:,0)), todouble(methox_co), todouble(biog_co), todouble(anth_co), \
                     todouble(bb_co), todouble(residual_co)/)

    model_seas_avg = new((/dimsizes(data_collect(:,0)), 366/), double)
    model_seas_sd = new((/dimsizes(data_collect(:,0)), 366/), double)

    do j=0,dimsizes(model_seas_avg(:,0))-1
      model_seas_return := calc_seasonal_cycle(data_collect(j,:), model_time,model_years(0),\
                                         model_years(dimsizes(model_years)-1), 300)
      model_seas_avg(j,:)=model_seas_return(:,0)
      model_seas_sd(j,:)=model_seas_return(:,1)
    end do 


;********************************************
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

    res@trYMinF             = 0.0
    ; MAX for Different stations
    if (location.eq."Darwin") then
       res@trYMaxF             = 2.5
       res@trYMinF             = 0.0
    else if (location.eq."Lauder") then
       res@trYMaxF             = 2.0
       res@trYMinF             = 0.0
    else if (location.eq."Wollongong") then
       res@trYMaxF             = 2.0
       res@trYMinF             = 0.0
    else
       res@trYMaxF             = 3.5
    end if
    end if
    end if
    res@trXMinF             = 0
    res@trXMaxF             = 367

    res@tmYLMode        = "Manual"	
      res@tmYLTickStartF  = 0.0
      res@tmYLTickEndF    = 4.5
      res@tmYLTickSpacingF= 0.5
      res@tmYLLabelFontHeightF = 0.028
      res@tiYAxisFontHeightF  = 0.028

    res@tmXBMode              = "Explicit"
      res@tmXBValues           = (ispan(15,365,30))
      res@tmXBLabels           = (/"Jan", "Feb", "Mar", "Apr", "May", "Jun",\
                                   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"/)
      res@tiXAxisString          = "Year"
      ;res@tmXBLabelsOn = False
      res@tmXBLabelFontHeightF = 0.028
      res@tiXAxisFontHeightF  = 0.028

    res@tmYLMajorOutwardLengthF = 0.0               ; draw tickmarks inward
    res@tmYLMinorOutwardLengthF = 0.0               ; draw minor ticks inward
    res@tmXBMajorOutwardLengthF = 0.0               
    res@tmXBMinorOutwardLengthF = 0.0              

    res@vpWidthF             = 1.0
    res@vpHeightF            = 0.5          ; set height of plot

    res@tiMainString        = ""
    res@tiXAxisString       = "Month"
    res@tiYAxisString       = "CO column"

  ; -------------------------------
  ; timeseries - weekly averages and climatology
  ; -------------------------------
  ; daily smooth seasonal cycle
  ; MOPITT
    res@xyLineColor         = "black"
    res@xyLineThicknessF    = 10.5
    res@xyDashPatterns      =1
  plot1 = gsn_csm_xy(wks,mopitt_seas_avg&year_day,mopitt_seas_avg(:,0)/1e18,res)

    res@tiYAxisString       = ""
    res@tiXAxisString       = ""

  if (PLOTFTS) then
  ; FTS
    res@xyLineColor         = "gray50"
  plot1b = gsn_csm_xy(wks,fts_seas_avg&year_day,fts_seas_avg(:,0)/1e18,res)
  overlay(plot1, plot1b)
  end if ;(PLOTFTS)

    res@gsnLeftString            := "x 10~S2~18   molec cm~S2~-2"             ; Label Bar title
    res@gsnStringFontHeightF     = 0.028

  ; CAM-chem
    res@xyLineColor         = "black"
    res@xyDashPatterns      =0
  plot1c = gsn_csm_xy(wks,model_seas_avg&year_day,model_seas_avg(0,:)/1e18,res)
  overlay(plot1, plot1c)

  ; -------------------------------
  ; add in model sums
  ; -------------------------------
printVarSummary(model_seas_avg)
  data      = new((/6,dimsizes(model_seas_avg&year_day)/),double)
printVarSummary(data)
   data(0,:) = model_seas_avg&year_day*0
   ;methox
   data(1,:) = model_seas_avg(1,:)
   ;anth
   data(2,:) = model_seas_avg(1,:)+model_seas_avg(3,:)
   ;res
   data(3,:) = model_seas_avg(1,:)+model_seas_avg(3,:)+model_seas_avg(5,:)
   ; biog
   data(4,:) = model_seas_avg(5,:)+model_seas_avg(1,:)+model_seas_avg(3,:)+model_seas_avg(2,:)
   ; bb
   data(5,:) = model_seas_avg(5,:)+model_seas_avg(1,:)+model_seas_avg(3,:)+model_seas_avg(2,:)\
                +model_seas_avg(4,:)

    above_colors = (/"steelblue3","lemonchiffon4","lightgoldenrod1","springgreen3","firebrick2"/)
    below_colors = (/"steelblue3","lemonchiffon4","lightgoldenrod1","springgreen3","firebrick2"/)
    res@xyLineColors         = (/"steelblue3","lemonchiffon4","lightgoldenrod1","springgreen3","firebrick2"/)
    res@gsnXYAboveFillColors = above_colors
    res@gsnXYBelowFillColors = below_colors

    res@xyLineThicknessF         = 14.5
    ;res@pmLegendDisplayMode      = "Always"        ; turn on legend
    res@xyExplicitLegendLabels   = (/"methane ox", "anthropogenic", "VOC oxidation",  "biogenic",\
                                     "biomass burning","total"/)
    res@lgPerimOn                = False           ; Turn off perimeter
    res@pmLegendWidthF           = 0.15            ; Change width and
    res@pmLegendHeightF          = 0.20             ; height of legend
    res@lgLabelFontHeightF       = 0.024
    ;res@lbJustification          = "TopLeft"


  plot1d = gsn_csm_xy(wks,model_seas_avg&year_day,data/1e18,res)
  overlay(plot1, plot1d)

  ; -------------------------------
  ; ADD CUSTOM TEXT
  ; -------------------------------
  ;drawNDCGrid(wks)
  ; STATIONS
  txres                   = True                ; polyline mods desired
  txres@txFontHeightF = 0.022                   ; font smaller. default big
  txres@txJust = "CenterLeft"                   ; font smaller. default big
  txres@txFontColor = "black"
  gsn_text_ndc(wks,"MOPITT "+version+suff,0.78,0.78,txres)
  txres@txFontColor = "gray50"
  gsn_text_ndc(wks,"FTS ("+network+")",0.78,0.75,txres)
  txres@txFontHeightF = 0.024                   ; font smaller. default big
  txres@txFontColor = "black"
  gsn_text_ndc(wks,location,0.15,0.69,txres)

  ; -------------------------------
  ; DRAW IT OUT
  ; -------------------------------
  draw(plot1)
  frame(wks)

end if



end

