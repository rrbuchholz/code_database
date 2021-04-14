;=======================================================;
;  model_anomaly_analysis.ncl 
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
;         -Text file with anomaly dates
;
;
;   To run type:
;         model_anomaly_analysis.ncl
;                                  RRB April 23, 2018
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
  network = "NDACC"

  ; -------------------------------
  ; CAM-chem files
  ; -------------------------------
  anomaly_folder = "~/MOPITT_subset/V7/"
  anomaly_filename = systemfunc ("ls "+anomaly_folder+location+"*sigma.txt")

  ; -------------------------------
  ; CAM-chem files
  ; -------------------------------
  folder = "~/CAM_chem/stations/"
  ;folder = "~/CAM_chem/stations/constE/"
  model_files_dummy = systemfunc ("ls "+folder+"CAM_Chem_DWL*.nc")
  model_filenames = model_files_dummy

  ;------------
  ; toggles
  ;------------
  PLOT           = True
    plttype      = "pdf"
    ;plttype@wkPaperSize = "A4"
    ;plttype@wkWidth = 0.5
    ;plttype@wkHeight = 0.5
    year_e = 2017

  
;--------------------------------------------
; end user input
;--------------------------------------------
;
;--------------------------------------------
; set up
;--------------------------------------------

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
  ; OUTPUT RELATED SETUP
  ; -------------------------------
  if (PLOT) then
    pltdir       = "./"
    pltname      = "Anomaly_analysis_" + location
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
  ; ANOMALIES
  ; -------------------------------
  ;---Read the values in as 1D, since we don't know rows and columns yet.
  lines  := asciiread(anomaly_filename,-1,"string")
  delim  = ", "

    ncols  := dimsizes(str_split(lines(3),delim))
    nlines := dimsizes(lines)-3
    print("File , Columns:"+ncols+", Lines:"+nlines)

  fields  := readAsciiTable(anomaly_filename,ncols-1,"integer",3)

  ;---Reshape as 2D array, and convert to float for ppm/ppb/ppt.
  event_names := new(nlines,"string")
    ;Remember that fields start at 1, not 0.
    event_names = str_get_field(lines(3:),1,delim)

   event_dates = toint(fields(:,1))


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
      model_years        = floattointeger(model_date(:,0))
    model_yyyymmdd       = cd_calendar(model_time, 2)

  ; -------------------------------
  ; loop over extracting tracers
  ; -------------------------------
  tracer = (/"CO", "CO01", "CO02", "CO03", "CO04", "CO05", "CO06", "CO07", "CO08", "CO09", "CO10",\
            "CO11", "CO12", "CO13", "CO14", "CO15", "CO16", "CO17", "CO18", "CO19", "CO20",\
            "CO21", "CO22", "CO23", "CO24", "CO25", "CO26", "CO27", "CO28", "CO29", "CO30"/)

  ; set-up tcol collection array
    tcol_arr   = new((/dimsizes(tracer), dimsizes(model_time)/), float)

  do i = 0, dimsizes(tracer)-1
     varname = tracer(i)+"_TotalColumn"
     tcol     := model_in[:]->$varname$
     if (location.eq."Darwin") then
       tcol_arr(i,:) = tcol(:,0)
     else if (location.eq."Wollongong") then
       tcol_arr(i,:) = tcol(:,1)
     else if (location.eq."Lauder") then
       tcol_arr(i,:) = tcol(:,2)
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
  ; CAM-chem seaonality
  ; -------------------------------

    methox_co = tcol_arr(1,:)
    biog_co = tcol_arr(2,:)
    anth_co = dim_sum_n(tcol_arr(29:30,:),0)
      nh_anth_co = tcol_arr(30,:)
      sh_anth_co = tcol_arr(29,:)
    bb_co = dim_sum_n(tcol_arr(15:16,:),0)
      bb_aus = tcol_arr(3,:)
      bb_SAm = tcol_arr(12,:)
      bb_SAf = tcol_arr(9,:)
      bb_MSEA = tcol_arr(4,:)
      other_bb = bb_co-(bb_aus+bb_SAm+bb_SAf)
    residual_co = tcol_arr(0,:)-bb_co-anth_co-biog_co-methox_co
    data_collect = (/todouble(tcol_arr(0,:)), todouble(methox_co), todouble(nh_anth_co), \
                     todouble(sh_anth_co), todouble(residual_co),todouble(biog_co), \
                     todouble(bb_aus), todouble(bb_SAm), todouble(bb_SAf), todouble(other_bb)/)

    model_seas_avg = new((/dimsizes(data_collect(:,0)), 366/), double)
    model_seas_sd = new((/dimsizes(data_collect(:,0)), 366/), double)

    do j=0,dimsizes(model_seas_avg(:,0))-1
      model_seas_return := calc_seasonal_cycle(data_collect(j,:), model_time,model_years(0),\
                                         model_years(dimsizes(model_years)-1), 300)
      model_seas_avg(j,:)=model_seas_return(:,0)
      model_seas_sd(j,:)=model_seas_return(:,1)
    end do 

    model_ClmDay = model_seas_avg&year_day

  ; -------------------------------
  ; EXPAND TO WHOLE TIME PERIOD
  ; -------------------------------
    model_doy = yyyymmdd_to_yyyyddd(toint(model_yyyymmdd))
    model_split_doy = str_split_by_length(tostring(model_doy),4)
    model_day_climate_sm = new((/dimsizes(model_seas_avg(:,0)), dimsizes(model_yyyymmdd)/),double)
    do t=0, dimsizes(model_seas_avg(:,0))-1
    do d=0,dimsizes(model_ClmDay)-1
      clm_index := ind((toint(model_split_doy(:,1)).eq.model_ClmDay(d)))
      model_day_climate_sm(t, clm_index)=model_seas_avg(t, d)
    end do
    end do
    model_yfrac = cd_calendar(model_time, 4)

  ; -------------------------------
  ; DAILY ANOMALIES
  ; -------------------------------
    model_day_anom = data_collect-model_day_climate_sm
printVarSummary(model_day_anom)

;--------------------------------------------
; GET CAM-chem anomaly dates
;--------------------------------------------
   model_anomaly_dummy=new(dimsizes(event_dates), integer)
   do k= 0, dimsizes(event_dates)-1
     model_anomaly_dummy(k) = ind(model_yyyymmdd.eq.event_dates(k))
   end do

   ; account for missing values
   remove_missing = ind(.not.ismissing(model_anomaly_dummy))
   model_anomaly = model_anomaly_dummy(remove_missing)
   anomaly_yfrac = yyyymmdd_to_yyyyfrac(event_dates(remove_missing),0.5)
   plot_xvals = ispan(0,dimsizes(anomaly_yfrac)-1,1)

print(event_dates)
print(model_anomaly)
print(transpose(model_day_anom(:,model_anomaly)))
 
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

    res@trYMinF             = -1.0
    ; MAX for Different stations
    if (location.eq."Darwin") then
       res@trYMaxF             = 0.7
       res@trYMinF             = -0.3
    else if (location.eq."Lauder") then
       res@trYMaxF             = 0.85
       res@trYMinF             = -0.2
    else if (location.eq."Wollongong") then
       res@trYMaxF             = 0.9
       res@trYMinF             = -0.2
    else
       res@trYMaxF             = 3.5
    end if
    end if
    end if
    ;res@trXMinF             = -0.5
    ;res@trXMaxF             = plot_xvals(dimsizes(plot_xvals)-1)+1.5

    res@tmYLMode        = "Manual"	
      res@tmYLTickStartF  = -1.0
      res@tmYLTickEndF    = 4.5
      res@tmYLTickSpacingF= 0.5
      res@tmYLLabelFontHeightF = 0.024
      res@tiYAxisFontHeightF  = 0.024

    res@tmXBMode              = "Explicit"
      res@tmXBValues           = plot_xvals
      res@tmXBLabels           = event_names(remove_missing)
      ;res@tmXBLabelsOn = False
      res@tmXBLabelFontHeightF = 0.024
      res@tiXAxisFontHeightF  = 0.024

    res@tmYLMajorOutwardLengthF = 0.0               ; draw tickmarks inward
    res@tmYLMinorOutwardLengthF = 0.0               ; draw minor ticks inward
    res@tmXBMajorOutwardLengthF = 0.0               
    res@tmXBMinorOutwardLengthF = 0.0              

    res@vpWidthF             = 0.85
    res@vpHeightF            = 0.2          ; set height of plot
    ;res@vpYF                 = 1.0

    res@tiMainString        = ""
    res@tiXAxisString       = "Event"
    res@tiYAxisString       = "CO column"

    res@gsnStringFontHeightF     = 0.024

    colors_tags = (/"steelblue3","lemonchiffon4","lemonchiffon3","lightgoldenrod1","springgreen3",\
                     "firebrick4", "firebrick2", "sienna2", "orange", "black"/)
  ; -------------------------------
  ; timeseries - weekly averages and climatology
  ; -------------------------------
  ; daily smooth seasonal cycle
  ; CAM-chem
    res@xyLineColor         = "black"
    res@gsnYRefLine           = 0.              ; reference line   
    res@gsnXYBarChart         = True            ; create bar chart 
    res@gsnXYBarChartBarWidth = 0.10           ; change bar widths
    ; base plot
    plot1 = gsn_csm_xy(wks,plot_xvals,model_day_anom(0,model_anomaly)*0,res)

    ; -------------------------------
    ; add in model sums
    ; -------------------------------
    ;data      = new((/dimsizes(model_day_anom(:,:))/),double)
    ; data(0,:) = model_day_anom&year_day*0
    ;do k=1, dimsizes(model_day_anom(:,0))-1
    ;   data(k,:) = data(k-1,:)+ model_seas_avg(k,:)
    ;end do

    do i = 0,dimsizes(data_collect(:,0))-2
      res@gsnXYBarChartColors = colors_tags(i)	
      plot1b = gsn_csm_xy(wks,plot_xvals+(0.10*(i+1)),model_day_anom(i+1,model_anomaly)/1e18,res)
      overlay(plot1,plot1b)
    end do

    res@gsnXYBarChartColors = "black"	
    res@gsnLeftString            := "x 10~S2~18   molec cm~S2~-2"             ; Label Bar title
    plot1_final = gsn_csm_xy(wks,plot_xvals,model_day_anom(0,model_anomaly)/1e18,res)
    overlay(plot1,plot1_final)


  ; -------------------------------
  ; add in model sums
  ; -------------------------------
  data      = new((/dimsizes(model_seas_avg(:,:))/),double)
   data(0,:) = model_seas_avg&year_day*0
   do k=1, dimsizes(model_seas_avg(:,0))-1
     data(k,:) = data(k-1,:)+ model_seas_avg(k,:)
   end do

    above_colors = (/"steelblue3","lemonchiffon4","lemonchiffon3","lightgoldenrod1","springgreen3",\
                     "firebrick4", "firebrick2", "sienna2", "orange", "black"/)
    below_colors = (/"steelblue3","lemonchiffon4","lemonchiffon3","lightgoldenrod1","springgreen3",\
                     "firebrick4", "firebrick2", "sienna2", "orange"/)
    res@xyLineColors =(/"steelblue3","lemonchiffon4","lemonchiffon3","lightgoldenrod1","springgreen3",\
                     "firebrick4", "firebrick2", "sienna2", "orange", "black"/)
    res@gsnXYAboveFillColors = above_colors
    res@gsnXYBelowFillColors = below_colors


    res@xyLineThicknessF         = 0.25
    res@pmLegendDisplayMode      = "Always"        ; turn on legend
    res@xyExplicitLegendLabels   = (/"Methane oxidation", "NH Anthropogenic", "SH Anthropogenic",\
                                     "VOC oxidation", "Biogenic CO",\
                                     "Australian fire","South American fire",\
                                     "Southern African fire","Other fire","CAM-chem"/)
    res@lgPerimOn                = False           ; Turn off perimeter
    res@pmLegendWidthF           = 0.15            ; Change width and
    res@pmLegendHeightF          = 0.34             ; height of legend
    res@lgLabelFontHeightF       = 0.024
    ;res@lbJustification          = "TopLeft"


  ;plot1d = gsn_csm_xy(wks,model_seas_avg&year_day,data/1e18,res)
  ;overlay(plot1, plot1d)

  ; -------------------------------
  ; ADD CUSTOM TEXT
  ; -------------------------------
  ;drawNDCGrid(wks)
  ; STATIONS
  txres                   = True                ; polyline mods desired
  txres@txFontHeightF = 0.022                   ; font smaller. default big
  txres@txJust = "CenterLeft"                   ; font smaller. default big
  txres@txFontColor = "black"
  gsn_text_ndc(wks,location,0.15,0.56,txres)

  ; -------------------------------
  ; DRAW IT OUT
  ; -------------------------------
  draw(plot1)
  frame(wks)

end if



end

