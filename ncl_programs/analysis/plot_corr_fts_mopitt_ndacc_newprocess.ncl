;============================================
; plot_corr_fts_mopitt_ndacc.ncl
;============================================
;
; Concepts Illustrated
;          - Re-open several binned v6, level 2, he5 files
;          - Works with data averaged around station
;          - Compare results for each pixel against FTS
;          - plot results for comparison
;          - calculate bias
;
; To use type on the command line:
;          > ncl {optional variables: 'loc="string"'\
;            'pnum = "l"'} plot_corr_fts_mopitt.ncl
;                            RRB Oct 28, 2014/IASI/home/buchholz/FTS_data/NDACC/co/
;============================================
; load the libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/IASI/home/buchholz/code_database/ncl_programs/buchholz_global_util/ultrafine_mopitt.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------
REPLACE = False
REMOVE = False

  if (.not. isvar("loc")) then      ; is location defined from command line?
      loc = "Wollongong"
      print("Setting Location to "+loc)
  end if


  ; MOPITT version
  version = "V6"
  ret = "J"
  ;mopitt_general     = "/IASI/home/buchholz/MOPITT_subset/V6/pixelbinning/"+loc+"/"+loc+"_1deg_"+version+ret+"MOPITTavg_"
  mopitt_general     = "/IASI/home/buchholz/MOPITT_subset/"+version+"/stations/timeseries/"+loc+"_1deg_"+version+ret+"MOPITTavg_"
  if (.not. isvar("pnum")) then      ; is location defined from command line?
      pnum = "l"
      print("Setting surface to "+l)
  end if  
       ; "l" - land
       ; "o" - water
       ; "m" - mixed scenes

       ; "b" - land and water scenes
       ; "a" - all scene types
       ; "1-4" - pixels 1 to 4
       ; "x1"- masked pixel 1

   station_name = (/"Altzomoni","ArrivalHeights", "Ascension", "Boulder", "Bremen", "Darwin",\
                     "Eureka", "Izana", "Jungfrau", "Kiruna", "Lauder", "Reunion",\
                     "MaunaLoa", "NyAlesund", "Paris", "Paramibo", "Rikubetsu", "StPete",\
                     "Thule", "Toronto", "Tsukuba", "Wollongong", "Zugspitze"/)

   ind_station = ind(station_name.eq.loc)


  ; FTS files
   fts_name = (/"altzomoni","arrival", "ascension", "boulder", "bremen", "darwin",\
                     "eureka", "izana", "jungfrau", "kiruna", "lauder", "reunion",\
                     "maunaloa", "nyalesund", "paris", "paramibo", "rikubetsu", "stpete",\
                     "thule", "toronto", "tsukuba", "wollongong", "zugspitze"/)
  fts_type = "NDACC/"
  loc2 = fts_name(ind_station)
  if (loc2.eq."lauder") then
    ;fts_files =  systemfunc ("ls /IASI/home/buchholz/FTS_data/NDACC/co/"+loc2+"/previous_iterations/lauder_combined_NDACC.nc")
    ;fts_files2 =  systemfunc ("ls /IASI/home/buchholz/FTS_data/NDACC/co/"+loc2+"/previous_iterations/ld_co_*.hdf")
    fts_files =  systemfunc ("ls /IASI/home/buchholz/FTS_data/NDACC/co/"+loc2+"/co_lauder_2001_2016.hdf")
    fts_files2 =  systemfunc ("ls /IASI/home/buchholz/FTS_data/NDACC/co/"+loc2+"/co_lauder_2001_2016.hdf")
  else if (loc2.eq."arrival") then
    ;fts_files =  systemfunc ("ls /IASI/home/buchholz/FTS_data/NDACC/co/"+loc2+"/previous_iterations/arrivalheights_combined_NDACC.nc")
    ;fts_files2 =  systemfunc ("ls /IASI/home/buchholz/FTS_data/NDACC/co/"+loc2+"/previous_iterations/ahts_co_*.hdf")
    fts_files =  systemfunc ("ls /IASI/home/buchholz/FTS_data/NDACC/co/"+loc2+"/co_ahts_*.hdf")
    fts_files2 =  systemfunc ("ls /IASI/home/buchholz/FTS_data/NDACC/co/"+loc2+"/co_ahts_*.hdf")
  else
    fts_files =  systemfunc ("ls /IASI/home/buchholz/FTS_data/NDACC/co/"+loc2+"/groundbased*.hdf")
  end if 
  end if


; WACCM files
  waccm_files = systemfunc ("ls /IASI/home/buchholz/waccm/*.nc")

  ;------------
  ; toggles
  ;------------
  PLOT            = False
     plotType     = "png"
     ; -------------------------------
     ymax                 = 3.0e18
     ymin                 = 0.5e18
     xmax                 = 3.0e18
     xmin                 = 0.5e18

  PLOTBIAS         = True
     plot2Type     = "png"
     ; -------------------------------
     y2max                 = 1e18
     y2min                 = -1e18
     x2min                 = 2000.9
     if (version.eq."V6") then
        x2max                 = 2015.5
     else
        x2max                 = 2015.5
     end if

  CSV_COLLECT         = False
    outname           ="/IASI/home/buchholz/MOPITT_subset/"+version+"/analysis_output/"+\
                        version+ret+"_NDACC_comparison_results.csv"

;--------------------------------------------
; end user input
;--------------------------------------------
;
;--------------------------------------------
; set up
;--------------------------------------------
   ;                      lat,      lon,    time diff
   station_select = (/(/  19.12,  -98.66,    0/),\  ;Altzomoni
                      (/ -77.82,  166.65,    12. /),\  ;ArrivalHeights
                      (/  -7.91,  -14.33,     0. /),\  ;Ascension
                      (/  39.99, -105.26,    0/),\  ;Boulder
                      (/  53.10,    8.85,     1. /),\  ;Bremen
                      (/ -12.424, 130.892,    9.5/),\  ;Darwin
                      (/  80.05,  -82.42,    -6. /),\  ;Eureka
                      (/  28.30,  -16.48,     0. /),\  ;Izana
                      (/  46.55,    7.98,     1. /),\  ;Jungfrau
                      (/  67.84,   20.41,     1. /),\  ;Kiruna
                      (/ -45.038, 169.684,   12. /),\  ;Lauder
                      (/ -20.901,  55.485,    4. /),\  ;Reunion
                      (/  19.54, -155.58,   -10. /),\  ;MaunaLoa
                      (/  78.923,  11.923,    1. /),\  ;NyAlesund
                      (/  48.97,    2.366,   0/),\  ;Paris
                      (/   5.75,  -55.2,     0/),\  ;Paramibo
                      (/  43.46,  143.8 ,    0/),\  ;Rikubetsu
                      (/  59.88,   29.83,    0/),\  ;StPete
                      (/  76.53,  -68.74,    -4. /),\  ;Thule
                      (/  43.66,  -79.40,    -5. /),\  ;Toronto
                      (/  36.05,  140.13,    0/),\  ;Tsukuba
                      (/ -34.406, 150.879,   10. /),\  ;Wollongong
                      (/  47.42,   10.98,     1. /) /) ;Zugspitze

   location_lat     = station_select(ind_station,0)
   location_lon     = station_select(ind_station,1)
   time_diff        = station_select(ind_station,2)
   location_lon_360 = location_lon
   press_diff       = 20
   location         = loc

  print(location +" Lat: " +location_lat+", Lon: " + location_lon)
  print("FTS: "+loc2 +" time difference to UTC: " +time_diff)

  if (loc2.eq."arrival") then
    press_diff   = 50
  else if (loc.eq."Eureka") then
    location_lon_360 = 360 + location_lon
    press_diff   = 50
  else if (loc2.eq."izana") then
    location_lon_360 = 360 + location_lon
    fts_files2 =  fts_files
  else if (loc2.eq."maunaloa") then
    location_lon_360 = 360 + location_lon
  else if (loc.eq."Thule") then
    location_lon_360 = 360 + location_lon
  else if (loc2.eq."toronto") then
    location_lon_360 = 360 + location_lon
  else if (loc2.eq."wollongong") then
    fts_files2 =  fts_files
    press_diff   = 50
  end if
  end if
  end if
  end if
  end if
  end if
  end if
  
  ; -------------------------------
  ; Filenames
  ; -------------------------------
  if (pnum.eq."l") then
      mopitt_binned_pix = mopitt_general+"all_land.nc"
      pixelnum="land"
  else if (pnum.eq."o") then
      mopitt_binned_pix = mopitt_general+"all_ocean.nc"
      pixelnum="water"
  else if (pnum.eq."m") then
      mopitt_binned_pix = mopitt_general+"m-all.nc"
      pixelnum="mixed"
  else if (pnum.eq."b") then
      mopitt_binned_pix = mopitt_general+"lo-all.nc"
      pixelnum="land and water"
  else if (pnum.eq."a") then
      mopitt_binned_pix = mopitt_general+"allscenes.nc"
      pixelnum="all scene types"
  else if (pnum.eq."1".or.pnum.eq."2".or.pnum.eq."3".or.pnum.eq."4") then
      mopitt_binned_pix = mopitt_general+"pixel"+pnum+".nc"
      pixelnum="pixel "+pnum
  else if (pnum.eq."x1") then
      mopitt_binned_pix = mopitt_general+"mask1.nc"
      pixelnum="masked pixel 1"
  end if
  end if
  end if
  end if
  end if
  end if
  end if

  ; -------------------------------
  ; Plot variables
  ; -------------------------------
  if (PLOT) then
    pltdir       = "/IASI/home/buchholz/MOPITT_subset/"+version+"/analysis_output/"
    plotName      = pltdir+version+ret+"-"+loc2+"-corr-"+pnum
    titlestring          = "MOPITT "+pixelnum+" vs FTS at "+loc
  end if

  if (PLOTBIAS) then
    pltdir       = "/IASI/home/buchholz/MOPITT_subset/"+version+"/analysis_output/"
    plot2Name      = pltdir+version+ret+"-"+loc2+"-bias-"+pnum
    titlestring2          = "MOPITT-FTS bias, "+pixelnum+" vs time at "+loc
  end if

     if (ret.eq."T") then
        version_name      = "TIR-only"
     else if (ret.eq."J") then
        version_name      = "TIR-NIR"
     else if (ret.eq."N") then
        version_name      = "NIR-only"
     end if
     end if
     end if

  ; Initialise negative VMR count
   count = 0

  ; Initialise psurf count
   psurf_count = 0

  ; -------------------------------
  ; FTS
  ; -------------------------------
  ; names of data structures
  ; determined from an ncl_filedump
  fts_tracer         = "CO_COLUMN_ABSORPTION_SOLAR"
  fts_datetime       = "DATETIME"
  fts_press          = "PRESSURE_INDEPENDENT"
  if (loc2.eq."kiruna") then
    fts_posterior      = "CO_MIXING_RATIO_ABSORPTION_SOLAR"
  else
    fts_posterior      = "CO_MIXING_RATIO_VOLUME_ABSORPTION_SOLAR"
  end if

  fts_psurf          = "SURFACE_PRESSURE_INDEPENDENT"
  fts_ledges         = "ALTITUDE_BOUNDARIES"


  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  ; names of data structures
  ; determined from an ncl_filedump
  if (version.eq."V6") then
    sat_tcol      = "MOPITT_TCOL_CO_WGT"
    timearray     = "TIME_AVG"
    sat_psurf     = "MOPITT_PSURF_WGT"
    sat_ap        = "MOPITT_APRIORI_CO_WGT"
    sat_ak        = "MOPITT_AVKER_CO_WGT"
    sat_err       = "MOPITT_TCOL_CO_ERR"
    sat_prof      = "MOPITT_PROFILE_CO_WGT"
  else
    sat_tcol      = "RetrievedCOTotalColumn_WGT"
    timearray     = "Time_AVG"
    sat_psurf     = "SurfacePressure_WGT"
    sat_ap        = "APrioriCOMixingRatioProfile_WGT"
    sat_ak        = "RetrievalAvKerMatrix_WGT"
    sat_err       = "RetrievedCOTotalColumn_ERR"
    sat_prof      = "RetrievedCOMixingRatioProfile_WGT"
  end if

  pvect = (/900.,800.,700.,600.,500.,400.,300.,200.,100./)

                                             ; CONSTANTS
   NAv    = 6.0221415e+23                    ;--- Avogadro's number
   g      = 9.81                             ;--- m/s - gravity
   H = (8.314*240)/(0.0289751*9.8)           ;--- scale height
   MWair = 28.94                             ;--- g/mol
   xp_const = (NAv* 10)/(MWair*g)*1.0e-09    ;--- scaling factor for turning vmr into pcol
                                             ;--- (note 1*e-09 because in ppb)



;--------------------------------------------
; load files and extract
;--------------------------------------------
mopitt_in = addfile(mopitt_binned_pix, "r")
    mopitt_tcol  = mopitt_in->$sat_tcol$
    time         = mopitt_in->$timearray$
   ; Date is in seconds since 1993-1-1 00:00:00
    mopitt_date  = cd_calendar(time, 0)
    psurf        = mopitt_in->$sat_psurf$
    apriori      = mopitt_in->$sat_ap$
    AvKer        = mopitt_in->$sat_ak$
    error        = mopitt_in->$sat_err$
    m_profile    = mopitt_in->$sat_prof$


;fts_in = addfile(fts_dir+fts_type+fts_location+"/"+fts_file, "r")
fts_in = addfiles (fts_files, "r")
  ListSetType (fts_in, "cat")             ; concatenate or "merge" (default)

  fts_tcol            = fts_in[:]->$fts_tracer$
  ; Date in MJD2000, fraction of days since 
  ; Jan 1st, 2000, 00:00:00
  fts_mjd2000         = fts_in[:]->$fts_datetime$
  fts_local           = fts_mjd2000+(time_diff/24.)
    fts_local@units   = "days since 2000-01-01 00:00:0.0"
  fts_date            = cd_calendar(fts_local, 0)
  fts_ppmv            = fts_in[:]->$fts_posterior$
  fts_prof            = fts_ppmv*1000           ; ppm to ppb
  fts_alt             = fts_in[:]->$fts_press$



    ; surface pressure values are missing for Lauder, Wollongong and Arrival Heights
    ; compute from level center height and pressure values
    if (loc2.eq."lauder".or.loc2.eq."arrival".or.loc2.eq."wollongong") then
      fts_in2 = addfiles (fts_files2, "r")
      lev_alt = fts_in2[0]->$"ALTITUDE"$
      inst_alt = fts_in2[0]->$"ALTITUDE_INSTRUMENT"$
      surf_p_holder   :=new((/dimsizes(fts_alt)/), float)

      do z = 0,dimsizes(fts_alt(0,:))-1
        surf_p_holder(:,z) = fts_alt(:,z) / exp(-(lev_alt(z)*1000)/H)  
      end do
      fts_surf   :=new((/dimsizes(fts_tcol)/), float)
      do t = 0,dimsizes(fts_tcol)-1
        avg_psurf = avg(surf_p_holder(t,:))
        p_ground  = avg_psurf*exp(-(inst_alt*1000)/H)
        fts_surf(t) = p_ground
      end do
    else
      fts_surf            = fts_in[:]->$fts_psurf$   ;other stations have correct surface pressures
      fts_surf_missing    = ind(ismissing(fts_surf)) ; there may be one or two missing values
      if (any(.not.ismissing(fts_surf_missing))) then
        lev_alt = fts_in[0]->$"ALTITUDE"$
        inst_alt = fts_in[0]->$"ALTITUDE_INSTRUMENT"$

      if (loc2.eq."izana") then
        dummy_lev = lev_alt
        lev_alt   := dummy_lev(0,:)
      end if

        print(fts_surf(fts_surf_missing))
        do m=0, dimsizes(fts_surf_missing)-1
          surf_p_holder = fts_alt(fts_surf_missing(m),:) / exp(-(lev_alt(:)*1000)/H)
          avg_psurf = avg(surf_p_holder)
          p_ground  = avg_psurf*exp(-(inst_alt*1000)/H)
          fts_surf(fts_surf_missing(m)) = p_ground
        end do
      end if
    end if

; Load WACCM a priori profile
print(waccm_files)
  waccm_in = addfiles(waccm_files, "r")
  ListSetType (waccm_in, "cat")             ; concatenate or "merge" (default)
  waccm_prof    = waccm_in[:]->CO       ; ppm to ppb
  waccm_p0      = waccm_in[0]->P0
  waccm_ps      = waccm_in[:]->PS
  waccm_hyam    = waccm_in[0]->hyam
  waccm_hybm    = waccm_in[0]->hybm

  waccm_date = cd_calendar(waccm_prof&time,0)
  lon = waccm_prof&lon
  lat = waccm_prof&lat
  LON = (/location_lon_360/)   ; lon needs to be in 0 to 360 format
  LAT = (/location_lat/)

  waccm_prof_loc = rm_single_dims(linint2_points (lon,lat,waccm_prof, True, LON, LAT, 0)) 
      waccm_prof_loc!0         = "time"
      waccm_prof_loc!1         = "lev"
      waccm_prof_loc&time      = waccm_prof&time
      waccm_prof_loc@long_name = waccm_prof@long_name
      waccm_prof_loc@units     = waccm_prof@units

  ; -------------------------------
  ; Hybrid levels to pressure levels
  ; -------------------------------
    pm = pres_hybrid_ccm(waccm_ps, waccm_p0, waccm_hyam, waccm_hybm) ; pi(ntim,klevi,nlat,mlon)
      pm!0         = "time"
      pm!1         = "lev"
      pm!2         = "lat"
      pm!3         = "lon"
      pm&time      = waccm_prof&time
      pm&lat       = lat
      pm&lon       = lon
      pm@long_name = "mid-level pressures"
      pm@units     = "Pa"

    waccm_pm_loc = rm_single_dims(linint2_points (lon,lat,pm,True,LON, LAT, 0))/100
      waccm_pm_loc!0         = "time"
      waccm_pm_loc!1         = "lev"
      waccm_pm_loc&time      = waccm_prof&time
      waccm_pm_loc@long_name = "mid-level pressures"
      waccm_pm_loc@units     = "hPa"

    waccm_ps_loc = rm_single_dims(linint2_points (lon,lat,waccm_ps,True,LON, LAT, 0))/100


;--------------------------------------------
; Set up MOPITT pressure arrays
;--------------------------------------------
  parray = new((/dimsizes(psurf), 10/), float)
  parray(:,0) = psurf
  do i=0,dimsizes(psurf)-1
    parray(i,1:9) = pvect
  end do
  ;--------------------------------------------------------------
  ; Correct for where MOPITT surface pressure <900 hPa
  ;--------------------------------------------------------------
  dp = new((/dimsizes(psurf), 10/), float) ; Pressure difference array
    do z= 0, 8, 1
      dp(:,z) = parray(:,0) - parray(:,z+1)
    end do
   dp(:,9) = 1000

  ; Repeat surface values at all levels to replace
  ; in equivalent position in parray if needed
  psurfarray = new((/dimsizes(psurf), 10/), float) 
   do z= 0, 9, 1
    psurfarray(:,z) = psurf
   end do
  ; add fill values below true surface
   parray = where(dp.le.0,parray@_FillValue,parray)
   parray = where((dp.le.100 .and. dp.ge.0),psurfarray,parray)

  ; Repeat surface a priori values at all levels to replace if needed
  apsurfarray = new((/dimsizes(psurf), 10/), float) 
   do z= 0, 9, 1
    apsurfarray(:,z) = (apriori(:,0))
   end do
  ; add fill values below true surface
   apriori = where(dp.le.0,apriori@_FillValue,apriori)
   apriori = where((dp.le.100 .and. dp.ge.0),apsurfarray,apriori)

  ; Repeat surface retrieved profile values at all levels to replace if needed
  postsurfarray = new((/dimsizes(psurf), 10/), float) 
   do z= 0, 9, 1
    postsurfarray(:,z) = (m_profile(:,0))
   end do
  ; add fill values below true surface
   m_profile = where(dp.le.0,m_profile@_FillValue,m_profile)
   m_profile = where((dp.le.100 .and. dp.ge.0),postsurfarray,m_profile)

  ; FTS values are averages for the whole box, 
  ; centred at an altitude while MOPITT values are averages described for box above level.
  ; therefore need to interp MOPITT pressures to mid-box
  pinterp = new((/dimsizes(psurf), 10/), double)
  do z=0,8,1
    pinterp(:,z) = parray(:,z) - (parray(:,z)-parray(:,z+1))/2
  end do
  pinterp(:,9) = 87.

;--------------------------------------------
; build comparison array
;--------------------------------------------
do i=0,dimsizes(fts_tcol)-1
   if (fts_date(i,0).lt.2001) then
     continue
   else if (fts_date(i,0).ge.2017) then
     continue
   end if
   end if

   if (loc2.eq."kiruna".and.fts_date(i,0).ge.2003) then
     continue
   end if


   ; collect MOPITT and FTS for comparison
   mopitt_comp := ind(mopitt_date(:,0).eq.fts_date(i,0)\
                 .and.mopitt_date(:,1).eq.fts_date(i,1)\
                 .and.mopitt_date(:,2).eq.fts_date(i,2))

  if (any(.not.ismissing(mopitt_comp))) then
      ;--------------------------------------------
      ; Interpolate FTS to MOPITT vertical levels
      ;--------------------------------------------
      ; note, interpolation automatically turns the fts profile upside down in indexed differently
      ; to align with MOPITT parray
      ;fts_interp = int2p_n_Wrap(fts_alt(i,:),fts_prof(i,:),pinterp(mopitt_comp,:),-1,0) ; old way - errors

      ; New interpolation (ultrafine_mopitt.ncl) to first interpolate to high res 
      ; profile then average over MOPITT layers
      ; Note this method will re-order levels if index order is different for different instruments
      ; eg MOPITT surface = index 0, FTS surface = index 46
      sublevs = 100
      fts_interp := ultrafine_mopitt(fts_prof(i,:), fts_alt(i,:), parray(mopitt_comp,:), sublevs)

      ; Need to account for missing values of FTS levels correctly
      ; (where FTS surface is higher than MOPITT)
      ; Everest is lowest possible at ~300 hPa
      ; replace with scaled values

; ignore profiles with missing lower levels
; - i.e. MOPITT lower than FTS
;if (fts_surf(i).lt.psurf(mopitt_comp)) then
;continue
;end if

      if (fts_surf(i).lt.psurf(mopitt_comp)) then
        ;------------------------
        ; Choose WACCM same date
        ; Stored on first day of next month
        monthcomp = fts_date(i,1)+1
        if (monthcomp.eq.13) then
          yearcomp  = fts_date(i,0)+1
           monthcomp = 1
        else
          yearcomp  = fts_date(i,0)
        end if
print(yearcomp)
        waccm_ind = ind(waccm_date(:,0).eq.yearcomp.and.\
                        waccm_date(:,1).eq.monthcomp)
        waccm_prof_compare = waccm_prof_loc(waccm_ind,:)
        waccm_pm_compare = waccm_pm_loc(waccm_ind,:)
        ;------------------------
        ; Interpolate WACCM to MOPITT profile
         waccm_interp = ultrafine_mopitt(waccm_prof_compare, waccm_pm_compare, parray(mopitt_comp,:), sublevs)
        ;------------------------
        ; Check if WACCM pressure is lower than MOPITT
        if (waccm_ps_loc(waccm_ind).lt.(psurf(mopitt_comp)-press_diff)) then
          ;print("waccm higher than mopitt!!!")
          ;print(waccm_ps_loc(waccm_ind))
          ;print(psurf(mopitt_comp))
          dummy_psurf_count = psurf_count
          psurf_count := dummy_psurf_count +1
          continue
        end if

        ;------------------------
        ; Calculate scaling factor
        ; if MOPITT pressure is missing, then WACCM interp is missing
        scale_factor_array = fts_interp/(waccm_interp*1e09)
         if (fts_surf(i).lt.400) then
           scale_factor= scale_factor_array(6)
           fts_interp(5) = scale_factor*(waccm_interp(5)*1e09)
           fts_interp(4) = scale_factor*(waccm_interp(4)*1e09)
           fts_interp(3) = scale_factor*(waccm_interp(3)*1e09)
           fts_interp(2) = scale_factor*(waccm_interp(2)*1e09)
           fts_interp(1) = scale_factor*(waccm_interp(1)*1e09)
           fts_interp(0) = scale_factor*(waccm_interp(0)*1e09)
         else if (fts_surf(i).lt.500) then
           scale_factor= scale_factor_array(5)
           fts_interp(4) = scale_factor*(waccm_interp(4)*1e09)
           fts_interp(3) = scale_factor*(waccm_interp(3)*1e09)
           fts_interp(2) = scale_factor*(waccm_interp(2)*1e09)
           fts_interp(1) = scale_factor*(waccm_interp(1)*1e09)
           fts_interp(0) = scale_factor*(waccm_interp(0)*1e09)
         else if (fts_surf(i).lt.600) then
           scale_factor= scale_factor_array(4)
           fts_interp(3) = scale_factor*(waccm_interp(3)*1e09)
           fts_interp(2) = scale_factor*(waccm_interp(2)*1e09)
           fts_interp(1) = scale_factor*(waccm_interp(1)*1e09)
           fts_interp(0) = scale_factor*(waccm_interp(0)*1e09)
         else if (fts_surf(i).lt.700) then
           scale_factor= scale_factor_array(3)
           fts_interp(2) = scale_factor*(waccm_interp(2)*1e09)
           fts_interp(1) = scale_factor*(waccm_interp(1)*1e09)
           fts_interp(0) = scale_factor*(waccm_interp(0)*1e09)
         else if (fts_surf(i).lt.800) then
           scale_factor= scale_factor_array(2)
           fts_interp(1) = scale_factor*(waccm_interp(1)*1e09)
           fts_interp(0) = scale_factor*(waccm_interp(0)*1e09)
         else
           scale_factor= scale_factor_array(1)
           fts_interp(0) = scale_factor*(waccm_interp(0)*1e09)
         end if
         end if
         end if
         end if
         end if
      end if


      ;--------------------------------------------
      ; Calculate tcol AK
      ;--------------------------------------------
      log10e = log10(exp(1.))
      ap = apriori(mopitt_comp,:)
      ap  = where(ismissing(ap),0,ap)  
      prof = m_profile(mopitt_comp,:)
      prof  = where(ismissing(prof),0,prof)
      ak = (/AvKer(mopitt_comp,:,:)/)
      ak_colm = (xp_const/log10e)*((prof # transpose(ak)))


if (.not.ismissing(fts_interp(0)).and.REPLACE) then
  ;profile_comparison = apriori(mopitt_comp,:)
  ;scale_factor = avg(fts_interp(1)/profile_comparison(1))
  ;print(scale_factor)
  ;fts_interp(0) = profile_comparison(0)*scale_factor
printVarSummary(mopitt_comp)
  ;------------------------
  ; Choose WACCM same date
  ; Stored on first day of next month
  monthcomp = fts_date(i,1)+1
  if (monthcomp.eq.13) then
    yearcomp  = fts_date(i,0)+1
    monthcomp = 1
  else
    yearcomp  = fts_date(i,0)
  end if
  waccm_ind = ind(waccm_date(:,0).eq.yearcomp.and.\
                  waccm_date(:,1).eq.monthcomp)
  waccm_prof_compare = waccm_prof_loc(waccm_ind,:)
  waccm_pm_compare = waccm_pm_loc(waccm_ind,:)
  ;------------------------
  ; Interpolate WACCM to MOPITT profile
  ;waccm_interp = vinth2p(tracer_all,hyam, hybm, pnew ,Psurf, 1    \
  ;               ,P0mb, 1, False)
  waccm_interp = ultrafine_mopitt(waccm_prof_compare, waccm_pm_compare, parray(mopitt_comp,:), sublevs)
  ;------------------------
  ; Calculate scaling factor
  scale_factor = avg(fts_interp(1)/(waccm_interp(1)*1e09))
  ;------------------------
  ; Replace lowest level

  ;fts_interp(0) = scale_factor*(waccm_interp(0)*1e09)
  fts_interp(0) = fts_interp(1)
  ;fts_dummy := fts_interp
  ;fts_dummy(0) = fts_dummy@_FillValue
  ;fts_interp_dummy := ultrafine_mopitt(fts_dummy, parray(mopitt_comp,:), parray(mopitt_comp,:), sublevs)
  ;fts_interp(0)=fts_interp_dummy(0)

end if

      ;--------------------------------------------
      ; Apply AK to FTS
      ; note AK applies to log(vmr) values
      ;--------------------------------------------
      logfts = log10(fts_interp)

if (.not.ismissing(logfts(0)).and.REMOVE) then
  logfts(0) = logfts@_FillValue
end if

;print(logfts)
;exit

      ; Check for negative profile elements
      test_ind := ind(logfts.eq."nan")
        if (any(.not.ismissing(test_ind))) then
          print("**** Negative profile elements!!! ***")
          print(test_ind)
          print(fts_interp(test_ind))
          print(fts_prof(i,:))
          dummy_count = count
          count = dummy_count + 1
          continue
      end if

      logap = log10(apriori(mopitt_comp,:))
;***** NEW
         logap = where(ismissing(logfts),logap@_FillValue,logap)
;***** END NEW
      logfts_ak = new((/10/), float)
      ;print("Convolving with averaging kernel. . .") ; AK calculations
         ak = (/AvKer(mopitt_comp,:,:)/)
         ; calculate (need to do vector wise because array calcs don't handle missing vals)         
         ;do l = 0, dimsizes(logfts)-1
         ;  logfts_ak(l) = logap(l) + sum(ak(:,l) * (logfts-logap))
         ;end do

           logfts_ak = logap + ak # (logfts-logap)

       print(". . . Done!")

      ; apply column AK to FTS column
      ; produces partial columns
      logfts  = where(ismissing(logfts),0,logfts)
      logap  = where(ismissing(logap),0,logap)
      fts_ak_2 =ak_colm # transpose(logfts - logap)

      logfts  = where(logfts.eq.0,logfts@_FillValue,logfts)
      logap  = where(logap.eq.0,logap@_FillValue,logap)

;print(logfts)
print(logfts_ak)

print(logfts)
print(logap)
print(fts_ak_2)
;exit

; Check for negative profile elements
test2_ind := ind(logfts_ak.eq."nan")
  if (any(.not.ismissing(test2_ind))) then
    print("**** Negative profile elements in smoothed profile!!! ***")
    print(test2_ind)
    exit
end if
       ; change back to vmr
       fts_ak = 10^logfts_ak
       ;fts_ak = fts_interp

      ;--------------------------------------------
      ; Pressure difference array
      ;--------------------------------------------
      ; MOPITT pressures are level edges.
      ; see V5 User Guide for more info
      delta_p = new((/10/), float)
      do z= 0, 8, 1
         delta_p(z) = parray(mopitt_comp,z)-parray(mopitt_comp,z+1)
      end do
      delta_p(9) = 74

      ; sanity check for MOPITT surface pressures less than 900 hPa
      levs_missing := ind(ismissing(parray(mopitt_comp,:)))
      if (.not.ismissing(levs_missing(0))) then  
         print("There are less than 10 'true' MOPITT levels!!!")
         print(delta_p)
         ;print(apriori(mopitt_comp,:))
         ;print(m_profile(mopitt_comp,:))
         print(fts_ak)
         print("MOPITT surf="+psurf(mopitt_comp))
        ;exit
      end if

      ;--------------------------------------------
      ; Calculate MOPITT tcol from profile
      ;--------------------------------------------
         xp_mopitt = new((/10/), float)
         xp_mopitt = (xp_const * m_profile(mopitt_comp,:)) * delta_p
         mopitt_collect := dim_sum(xp_mopitt)
         mopitt_profile_collect := m_profile(mopitt_comp,:)

      ;--------------------------------------------
      ; Calculate total column
      ;--------------------------------------------
      xp_interp = new((/10/), float)
      xp_tcol = new((/10/), float)

      xp_interp = (xp_const * fts_interp) * delta_p
      tcol_interp = dim_sum(xp_interp)
      xp_tcol= (xp_const * fts_ak) * delta_p 
      tcol_ak = dim_sum(xp_tcol) 

      ; apriori total column
      xp_ap = new((/10/), double)
      xp_ap= (xp_const * ap) * delta_p 
      ap_tcol = dim_sum(xp_ap)
      tcol_ak_2 = ap_tcol + fts_ak_2

print(tcol_ak)
print(tcol_ak_2)
print(mopitt_collect)
;exit

      ;--------------------------------------------
      ; Collect arrays
      ;--------------------------------------------
      if (.not.(isdefined("mopitt_to_plot"))) then
              print("***Collecting first values***")
              mopitt_to_plot  = mopitt_collect
              mopitt_error    = error(mopitt_comp)
              time_to_plot    = time(mopitt_comp)
              fts_to_plot     = fts_tcol(i)
              fts_interp_plot = tcol_interp
              fts_ak_plot     = tcol_ak
              fts_prof_ak := new((/1,dimsizes(fts_ak)/),float)
              fts_prof_ak(0,:) = fts_ak
              mopitt_prof := new((/1,dimsizes(mopitt_profile_collect)/),float)
              mopitt_prof(0,:) = mopitt_profile_collect
          else
              temp1 := mopitt_to_plot
              temp2 := mopitt_error
              temp3 := time_to_plot
              temp4 := fts_to_plot
              temp5 := fts_interp_plot
              temp6 := fts_ak_plot
              temp7 := fts_prof_ak
              temp8 := mopitt_prof

              mopitt_to_plot := array_append_record(temp1,mopitt_collect,0)
              mopitt_error   := array_append_record(temp2,error(mopitt_comp),0)
              time_to_plot   := array_append_record(temp3, time(mopitt_comp),0)
              fts_to_plot    := array_append_record(temp4,fts_tcol(i),0)
              fts_interp_plot := array_append_record(temp5,tcol_interp,0)
              fts_ak_plot     := array_append_record(temp6,tcol_ak,0)
              temp7a := new((/1,dimsizes(fts_ak)/),float)
              temp7a(0,:) = fts_ak
              fts_prof_ak    := array_append_record(temp7,temp7a,0)
              temp8a := new((/1,dimsizes(mopitt_profile_collect)/),float)
              temp8a(0,:) = mopitt_profile_collect
              mopitt_prof    := array_append_record(temp8,temp8a,0)
       end if         
   end if
end do

print("****")
print("Missing FTS: "+ind(ismissing(fts_ak_plot)))
print("Missing MOPITT: "+ind(ismissing(mopitt_to_plot)))
print(dimsizes(fts_ak_plot))
print(dimsizes(mopitt_to_plot))

; hack for nan values - found: nan occur when the profile values are negative
; the below section should no longer be needed, this was a hack when I didn't know why nan was occurring
fts_ak_plot=where(fts_ak_plot.eq."nan".or.fts_ak_plot.eq."inf",fts_ak_plot@_FillValue,fts_ak_plot)
print(ind(ismissing(fts_ak_plot)))
print(ind(ismissing(mopitt_to_plot)))
dummy_fts = fts_ak_plot(ind(.not.ismissing(fts_ak_plot)))
dummy_mopitt = mopitt_to_plot(ind(.not.ismissing(fts_ak_plot)))
dummy_err = mopitt_error(ind(.not.ismissing(fts_ak_plot)))
dummy_time = time_to_plot(ind(.not.ismissing(fts_ak_plot)))

fts_ak_plot     := dummy_fts
mopitt_to_plot  := dummy_mopitt
time_to_plot    := dummy_time
mopitt_error    := dummy_err

;print(dimsizes(fts_ak_plot))
;print(dimsizes(mopitt_to_plot))

;************************************************
; POST COLLECTION CALCULATIONS
;************************************************
;--------------------------------------------
; Select for dates after instrument cooler 
; failure in May 2001
;--------------------------------------------
; get indices of Phase 2
failure_time = yyyymm_to_yyyyfrac(200105,0)
time_convert = cd_calendar(time_to_plot,4)
ymd_convert = cd_calendar(time_to_plot,0)
  years = ymd_convert(:,0)
  months = ymd_convert(:,1)

  if (version.eq."V6") then
    ind_phase2 = ind(time_convert.gt.failure_time)
    ;ind_phase2 = ind(time_convert.gt.failure_time.and.\
    ;                 (years.lt.2012.or.\
    ;                 (years.eq.2012.and.months.le.2)) )
  else 
    ind_phase2 = ind(time_convert.gt.failure_time)
    ;ind_phase2 = ind(time_convert.gt.failure_time.and.\
    ;                 (years.lt.2013))
  end if

time_array=time_convert(ind_phase2)

; select data in Phase 2
fts_ak_corr = fts_ak_plot(ind_phase2)
mopitt_to_corr = mopitt_to_plot(ind_phase2)

alt_names = (/"surface below 900 hPa", "900 hPa", "800hPa", "700hPa", "600hPa",\
              "500 hPa", "400 hPa", "300 hPa", "200 hPa", "100 hPa"/)
mopitt_prof_all = mopitt_prof
fts_prof_all = fts_prof_ak

mopitt_prof_dummy = mopitt_prof(ind_phase2,:)
fts_prof_dummy = fts_prof_ak(ind_phase2,:)
mopitt_prof := mopitt_prof_dummy 
fts_prof_ak := fts_prof_dummy

;--------------------------------------------
; Calculate correlation coefficients
;--------------------------------------------
cval1 = escorc(fts_ak_plot,mopitt_to_plot) 
rc1   = regline(fts_ak_plot,mopitt_to_plot)
df    = rc1@nptxy-2
prob = (betainc(df/(df+rc1@tval^2), df/2.0, 0.5) )

;--- phase 2 only
cval1_a = escorc(fts_ak_corr,mopitt_to_corr) 
rc1_a   = regline(fts_ak_corr,mopitt_to_corr)
df_a    = rc1_a@nptxy-2
prob_a = (betainc(df_a/(df+rc1_a@tval^2), df_a/2.0, 0.5) )

;--- different altitudes
cval1_alt :=new((/dimsizes(fts_prof_ak(0,:))/), double)
rc1_alt :=new((/dimsizes(fts_prof_ak(0,:))/), double)
rc1_alt_sd :=new((/dimsizes(fts_prof_ak(0,:))/), double)
  do i=0,dimsizes(fts_prof_ak(0,:))-1
    cval1_alt(i) = escorc(fts_prof_ak(:,i),mopitt_prof(:,i))
    dummy_reg := regline(fts_prof_ak(:,i),mopitt_prof(:,i))
    rc1_alt(i) = dummy_reg
    rc1_alt_sd(i) = dummy_reg@rstd
  end do

;--------------------------------------------
; Calculate bias
;--------------------------------------------
bias = (sum(flt2dble(mopitt_to_plot)-fts_ak_plot)/sum(fts_ak_plot))*100
mean_bias = avg(flt2dble(mopitt_to_plot)-fts_ak_plot)
bias_sd = stddev(flt2dble(mopitt_to_plot)-fts_ak_plot)

;--- phase 2 only
bias_a = (avg(flt2dble(mopitt_to_corr)-fts_ak_corr)/avg(fts_ak_corr))*100
mean_bias_a = avg(flt2dble(mopitt_to_corr)-fts_ak_corr)
bias_sd_a = stddev(flt2dble(mopitt_to_corr)-fts_ak_corr)
percent_bias_sd_a = (stddev(flt2dble(mopitt_to_corr)-fts_ak_corr)/avg(fts_ak_corr))*100

;--------------------------------------------
; Calculate seasonal bias
;--------------------------------------------
time_phase2 = time_to_plot(ind_phase2)
dates_phase2 = cd_calendar(time_phase2,0)
  ; -------------------------------
  ; Seasonal arrays
  ; -------------------------------
   seas_names = (/"DJF","MAM","JJA","SON"/)
   seas_months = (/(/12,1,2/),(/3,4,5/),\
                    (/6,7,8/),(/9,10,11/)/)

  p_bias_seas :=new((/dimsizes(seas_names)/), double)
  mean_bias_seas :=new((/dimsizes(seas_names)/), double)
  bias_sd_seas :=new((/dimsizes(seas_names)/), double)
  p_bias_sd_seas :=new((/dimsizes(seas_names)/), double)

  do i=0,dimsizes(seas_names)-1
     seas_ind      := ind(dates_phase2(:,1).eq.seas_months(i,0).or.\
                      dates_phase2(:,1).eq.seas_months(i,1).or.\
                      dates_phase2(:,1).eq.seas_months(i,2))
     if (.not.(all(ismissing(seas_ind)))) then
       p_bias_seas(i) = (avg(flt2dble(mopitt_to_corr(seas_ind))-fts_ak_corr(seas_ind))/\
                     avg(fts_ak_corr(seas_ind)))*100
       mean_bias_seas(i) = avg(flt2dble(mopitt_to_corr(seas_ind))-fts_ak_corr(seas_ind))
       bias_sd_seas(i) = stddev(flt2dble(mopitt_to_corr(seas_ind))-fts_ak_corr(seas_ind))
       p_bias_sd_seas(i) = bias_sd_seas(i)/avg(fts_ak_corr(seas_ind))*100
     end if
  end do

;--------------------------------------------
; Calculate bias time drift
;--------------------------------------------
diff = (flt2dble(mopitt_to_plot) - fts_ak_plot)
diff_percent = (diff/fts_ak_plot)*100
err_percent = (mopitt_error/flt2dble(mopitt_to_plot))*100
time_frac = cd_calendar(time_to_plot, 4)
rc2   = regline(time_frac,diff)
;expected = rc2*time_frac
;sb = (sqrt(sum(diff - expected)^2 /(rc2@nptxy - 2)))/(sqrt(sum(time_to_plot - rc2@xave)^2))
;t_score = rc2/rc2@rstd
df2    = rc2@nptxy-2
prob2 = (betainc(df2/(df2+rc2@tval^2), df2/2.0, 0.5) )
;print("number of degrees of freedom="+df2)
;print("drift t value = "+sprintf("%6.2e",rc2@tval))

;--- phase 2 only
diff_a = (flt2dble(mopitt_to_corr) - fts_ak_corr)
rc2_a   = regline(time_array,diff_a)
df2_a    = rc2_a@nptxy-2
prob2_a = (betainc(df2_a/(df2_a+rc2_a@tval^2), df2_a/2.0, 0.5) )

p_rc_2a = (rc2_a / avg(fts_ak_corr) ) * 100
p_se_2a = (rc2_a@rstd / avg(fts_ak_corr) ) * 100


;--------------------------------------------
; Print out validation results
;--------------------------------------------
print("****************************************")
print("mean bias +/- sd = "+sprintf("%6.2e",mean_bias)+" +/-"+sprintf("%6.2e",bias_sd))
print("percent mean bias = "+sprintf("%6.2f",bias)+"%")
print("drift = "+sprintf("%6.2e",rc2) +" +/- "+ sprintf("%6.2e",rc2@rstd))
print("prob 2 = "+sprintf("%6.2e",prob2))
print("----------------")
print("r = "+cval1)
print("corr slope = "+rc1+" +/- "+sprintf("%6.2e",rc1@rstd))
print("number in comparison="+dimsizes(mopitt_to_plot))
print("****************************************")

print("*******Only for Phase2******************")
print("mean bias +/- sd = "+sprintf("%6.2e",mean_bias_a)+" +/- "+sprintf("%6.2e",bias_sd_a))
print("percent mean bias = "+sprintf("%6.2f",bias_a)+" %"+" +/- "+sprintf("%6.2f",percent_bias_sd_a)+" %")
print("drift = "+sprintf("%6.2e",rc2_a) +" +/- "+ sprintf("%6.2e",rc2_a@rstd))
print("drift = "+sprintf("%6.4f",p_rc_2a) +" +/- "+ sprintf("%6.4f",p_se_2a) +" %")
print("prob 2 = "+sprintf("%6.2e",prob2_a))
print("----------------")
print("r = "+cval1_a)
print("corr slope = "+rc1_a+" +/- "+sprintf("%6.2e",rc1_a@rstd))
print("number in comparison="+dimsizes(mopitt_to_corr))
print("Number of profiles with negative VMR = "+count)
print("Number of instances where waccm < MOPITT p-surf = "+psurf_count)
avg_tcol = avg(fts_ak_corr)
print("Average "+avg_tcol)
print("List:"+avg(fts_ak_corr)+","+sprintf("%4.2f",cval1_a)+","+sprintf("%6.2f",bias_a)+","+sprintf("%5.2f",percent_bias_sd_a)+","+sprintf("%5.3f",rc1_a)+","+sprintf("%4.2f",p_rc_2a)+","+dimsizes(mopitt_to_corr))
print("Seasonal Bias:  "+seas_names(0)+",    "+seas_names(1)+",    "+seas_names(2)+",    "+seas_names(3))
print("Seasonal Bias:"+sprintf("%6.3f",p_bias_seas(0))+", "+sprintf("%6.3f",p_bias_seas(1))+", "+\
                       sprintf("%6.3f",p_bias_seas(2))+", "+sprintf("%6.3f",p_bias_seas(3)))
print("****************************************")

;--------------------------------------------
; Calc reg-lines for plots
;--------------------------------------------
x1 = (/0.8e16,1e18,ymax/)
reg_line = rc1_a*(x1) + rc1_a@yintercept

x2 = (/1999,2007.5,x2max/)
reg_line2 = rc2_a*(x2) + rc2_a@yintercept


;--------------------------------------------
; plot
;--------------------------------------------
if (PLOT) then
;************************************************
; Setting up correlation plot
;************************************************
 wks  = gsn_open_wks(plotType,plotName) ; specifies a ps plot
 
 res                     = True                         ; plot mods desired
  res@gsnFrame                 = False                  ; don't advance frame yet
  res@gsnDraw                  = False                  ; don't draw plot
  res@xyMarkLineModes          = (/"Markers","Lines"/)  ; choose which have markers
  res@xyMarkers                = 9                     ; choose type of marker 
  res@xyMarkerColor            = "dodgerblue"                  ; Marker color
  res@xyMarkerSizeF            = 0.012                  ; Marker size (default 0.01)
  res@xyDashPatterns           = 2                      ; dashed line 
  res@xyLineThicknesses        = 5                ; thickness
  res@xyMarkerThicknessF       = 3                      ; thickness of outline of marker

  ; Set axes limits
  res@trYMaxF                  = ymax/1e18
  res@trYMinF                  = ymin/1e18
  res@trXMaxF                  = xmax/1e18
  res@trXMinF                  = xmin/1e18

  res@tmEqualizeXYSizes        = True
  res@tmLabelAutoStride        = True

  ;res@tiMainString        = titlestring  ; title
  res@tiMainString        = ""  ; title
  res@tiYAxisString            ="MOPITT total column (10~S2~18   molec. cm~S2~-2  )"
  res@tiXAxisString            ="FTS total column (10~S2~18   molec. cm~S2~-2  )"

 plot1  = gsn_csm_xy (wks, fts_ak_plot/1e18, mopitt_to_plot/1e18,res)      ; create plot


;************************************************
; add error bars
;************************************************  
  polyres                   = True                      ; marker resources
  polyres@gsLineColor       = "dodgerblue"                 ; color
  polyres@gsLineThicknessF  = 3                ; line thickness
; loop through the points  
  do t=0,dimsizes(mopitt_to_plot)-1
; the error bar is draw in two segements, above and below the value
    gsn_polyline(wks,plot1,(/fts_ak_plot(t)/1e18,fts_ak_plot(t)/1e18/),\
                 (/mopitt_to_plot(t)/1e18+mopitt_error(t)/1e18,mopitt_to_plot(t)/1e18-mopitt_error(t)/1e18/),polyres)
  end do


;************************************************
; add regression line
;************************************************ 
 ; create a blank plot for grey line
  bres              = True
    bres@trXMinF      = xmin/1e18
    bres@trXMaxF      = xmax/1e18
    bres@trYMinF      = ymin/1e18
    bres@trYMaxF      = ymax/1e18
    bres@tmEqualizeXYSizes        = True
    bres@tmLabelAutoStride        = True
    blank_plot = gsn_csm_blank_plot(wks,bres)
    blank_plot_alt = new(6,graphic)                         ; create graphics array
    blank_plot_alt = gsn_csm_blank_plot(wks,bres)

 ; add 1:1 line 
  res_lines                   = True                     ; polyline mods desired
    res_lines@gsLineDashPattern = 0                 ; line style
    res_lines@gsLineThicknessF  = 7.                     ; line thicker
    res_lines@gsLineColor       = "black"                 ; line color
    res_lines@tfPolyDrawOrder   = "PostDraw"              ; send to back
  xx = (/0,ymax/1e18/)
  yy = (/0,ymax/1e18/)
  dum1 = gsn_add_polyline(wks,blank_plot,xx,yy,res_lines)      ; add polyline

 ; add bias line 
  res_lines2                   = True                     ; polyline mods desired
    res_lines2@gsLineDashPattern = 2                      ; line style
    res_lines2@gsLineThicknessF  = 7.                     ; line thicker
    res_lines2@gsLineColor       = "black"                 ; line color
    res_lines2@tfPolyDrawOrder   = "PostDraw"              ; send to back
  xx2 = (/0,xmax/1e18/)
  yy2 = (/0+mean_bias/1e18,xmax/1e18+mean_bias/1e18/)
  dum2 = gsn_add_polyline(wks,plot1,xx2,yy2,res_lines2)      ; add polyline

 
 ; add reg line 
  res_reg                   = True                     ; polyline mods desired
    res_reg@gsLineDashPattern    = 1.                     ; solid line
    res_reg@gsLineThicknessF     = 7.                     ; line thicker
    res_reg@gsLineColor          = "royalblue2"                ; line color

  dum3 = gsn_add_polyline(wks,plot1,x1/1e18,reg_line/1e18,res_reg)      ; add polyline

 ;drawNDCGrid(wks)
 ; add formula
  txres                   = True                     ; polyline mods desired
  txres@txFontHeightF = 0.018                    ; font smaller. default big
  txres@txJust = "CenterLeft"                   ; font smaller. default big
  gsn_text_ndc(wks,location +" "+version_name+": "+pixelnum,0.21,0.77,txres)
;  gsn_text_ndc(wks,version_name+": ",0.21,0.77,txres)
  gsn_text_ndc(wks,"daytime",0.21,0.72,txres)\
;  gsn_text_ndc(wks,"daytime ,land",0.21,0.72,txres)
  txres@txJust = "CenterRight"                   ; font smaller. default big
  gsn_text_ndc(wks,"slope = "+sprintf("%5.2f", rc1_a)+" ~F34~1~F~ "+sprintf("%6.3f",rc1_a@rstd),0.78,0.25,txres)
  gsn_text_ndc(wks,"bias = "+sprintf("%5.3f", mean_bias_a/1e18)+" (x 10~S2~18   )",0.78,0.3,txres)
  gsn_text_ndc(wks,"sdev = "+sprintf("%5.3f",bias_sd_a/1e18)+" (x 10~S2~18   )",0.78,0.35,txres)
  gsn_text_ndc(wks,"r = "+sprintf("%5.2f",cval1_a),0.78,0.4,txres)

 ;overlay(blank_plot,plot1)
 ;draw(blank_plot)
 overlay(plot1,blank_plot)
 draw(plot1)
 frame(wks)

  ; Trim png files to remove white space
  if (plotType.eq."png") then
     system("convert -density 96 -trim "+plotName+"."+plotType+" "+plotName+"."+plotType) 
  end if


end if ; PLOT

;--------------------------------------------
; plot bias versus time
;--------------------------------------------
if (PLOTBIAS) then

;************************************************
; Setting up correlation plot
;************************************************
 wks  = gsn_open_wks(plot2Type,plot2Name) ; specifies a ps plot
 
 res                     = True                         ; plot mods desired
  res@gsnFrame                 = False                  ; don't advance frame yet
  res@gsnDraw                  = False                  ; don't draw plot
  res@gsnMaximize              = True                  ; don't draw plot
  res@xyMarkLineModes          = (/"Markers","Lines"/)  ; choose which have markers
  res@xyMarkers                = 9                    ; choose type of marker 
  res@xyMarkerColor            = "dodgerblue"                  ; Marker color
  res@xyMarkerSizeF            = 0.005                  ; Marker size (default 0.01)
  res@xyDashPatterns           = 2                      ; dashed line 
  res@xyLineThicknesses        = 5                      ; thickness
  res@xyMarkerThicknessF       = 6                      ; thickness of outline of marker

  ; Set axes limits
  res@trYMaxF                  = y2max
  res@trYMinF                  = y2min
  res@trXMaxF                  = x2max
  res@trXMinF                  = x2min

  res@vpWidthF                 = 0.8
  res@vpHeightF                = 0.4

  ;res@tmEqualizeXYSizes        = False
  ;res@tmLabelAutoStride        = True

  ;res@tiMainString        = titlestring2  ; title
  res@tiMainString        = ""  ; title
  res@tiYAxisString            ="bias (10~S2~17   molec. cm~S2~-2  )"
  res@tiXAxisString            ="date"
  res@tmXBLabelFontHeightF     = 0.014
  res@tmYLLabelFontHeightF     = 0.014

 plot1  = gsn_csm_xy (wks, time_array, diff_a/1e17,res)      ; create plot
 ;plot1  = gsn_csm_xy (wks, time_frac, diff_percent,res)      ; create plot

;************************************************
; add error bars
;************************************************  
  polyres                   = True                      ; marker resources
  polyres@gsLineColor       = "dodgerblue"                 ; color
  polyres@gsLineThicknessF  = 2                ; line thickness
; loop through the points  
  error_bar = new(dimsizes(mopitt_to_plot),graphic)
  do t=0,dimsizes(mopitt_to_plot)-1
; the error bar is draw in two segements, above and below the value
;    error_bar(t) = gsn_add_polyline(wks,plot1,(/time_frac(t),time_frac(t)/),\
;                   (/diff(t)+mopitt_error(t),diff(t)-mopitt_error(t)/),polyres)

;    error_bar(t) = gsn_add_polyline(wks,plot1,(/time_frac(t),time_frac(t)/),\
;                   (/diff(t)+err_percent(t),diff(t)-err_percent(t)/),polyres)
  end do


;************************************************
; add regression line
;************************************************ 
 ; create a blank plot for grey line
  bres              = True
    bres@trXMinF      = x2min
    bres@trXMaxF      = x2max
    bres@trYMinF      = y2min/1e17
    bres@trYMaxF      = y2max/1e17
    bres@vpWidthF     = 0.6
    bres@vpHeightF    = 0.4
    bres@vpXF                     = 0.21
    bres@tmXBLabelFontHeightF     = 0.020
    bres@tmYLLabelFontHeightF     = 0.020
  bres@tmXBMode             = "Explicit" ; Define own tick mark labels.
  years_plot  = ispan(2002,2014,2)
  bres@tmXBValues           = years_plot
  bres@tmXBLabels           = years_plot
  bres@tmXBMinorPerMajor  =11
  blank_plot = gsn_csm_blank_plot(wks,bres)

 ; add zero line 
  res_lines                   = True                     ; polyline mods desired
    res_lines@gsLineDashPattern = 0                 ; line style
    res_lines@gsLineThicknessF  = 4.                     ; line thicker
    res_lines@gsLineColor       = "black"                 ; line color
    res_lines@tfPolyDrawOrder   = "PostDraw"              ; send to back
  xx = (/1999,x2max/)
  yy = (/0,0/)
  dum1 = gsn_add_polyline(wks,blank_plot,xx,yy,res_lines)      ; add polyline

 ; add reg line 
  res_reg                   = True                     ; polyline mods desired
    res_reg@gsLineDashPattern    = 1.                     ; solid line
    res_reg@gsLineThicknessF     = 7.                     ; line thicker
    res_reg@gsLineColor          = "royalblue2"                ; line color

  dum2 = gsn_add_polyline(wks,plot1,x2,reg_line2/1e17,res_reg)      ; add polyline

 ;drawNDCGrid(wks)
 ; add formula
  txres                   = True                     ; polyline mods desired
  txres@txFontHeightF = 0.018                    ; font smaller. default big
  txres@txJust = "CenterLeft"                   ; font smaller. default big
  gsn_text_ndc(wks,location +" "+version_name+": daytime, "+pixelnum,0.22,0.77,txres)
  gsn_text_ndc(wks,"bias drift = "+sprintf("%5.3f", rc2_a/1e17)+" ~F34~1~F~ "+sprintf("%5.3f",rc2_a@rstd/1e17)+" (10~S2~17   molec. cm~S2~-2  /year)",0.22,0.45,txres)
  gsn_text_ndc(wks,"sdev = "+sprintf("%5.3f",bias_sd_a/1e17)+" (x 10~S2~17   molec. cm~S2~-2   )",0.22,0.42,txres)

 overlay(blank_plot,plot1)
 draw(blank_plot)
 frame(wks)

  ; Trim png files to remove white space
  if (plot2Type.eq."png") then
     system("convert -density 96 -trim "+plot2Name+"."+plot2Type+" "+plot2Name+"."+plot2Type) 
  end if

end if ; PLOTBIAS

if (CSV_COLLECT) then

;---Create mixed data to write to CSV file

         ;location,latitude,longitude,surface_type,bias,sd,drift,r,slope,bias_%,sd_%,drift_%,trend_p,#
  alist  = [/loc,pnum,location_lat, location_lon,mean_bias_a,bias_sd_a,rc2_a,cval1_a,\
            rc1_a,bias_a,percent_bias_sd_a,p_rc_2a,prob2_a,dimsizes(mopitt_to_corr)/] 
;; Note: if you don't want spaces in CSV file, use the following format string.
 format = "%s,%s,%f,%f,%g,%g,%g,%f,%f,%f,%f,%f,%g,%d"


   if (.not.fileexists(outname)) then
    ; create file
     fields = (/"location", "latitude", "longitude", "surface_type", "mean_bias",  "mean_sd", \
                "drift", "r", "slope", "mean_bias_percent", "mean_sd_percent", "drift_percent",\
                "trend_p", "number_of_comparisons"/)
     dq = str_get_dq()                              ; double quote character
     fields = dq + fields + dq                      ; Pre/append quotes to field names
     header = [/str_join(fields,",")/]              ; Header is field names separated
                                                    ; by commas.
     write_table(outname, "w", header, "%s")   ; Write header to CSV file.
     write_table(outname, "a", alist, format)  ; Write mixed data to CSV file.
   else
     ; add to file
     write_table(outname, "a", alist, format)  ; Write mixed data to CSV file.
   end if

;---Echo the new file to the screen so you can see it.
  print("====== Contents of '" + outname + "' ======")
  system("cat " + outname)
  print("========================================")


print("*******Only for Phase2******************")
print("drift = "+sprintf("%6.2e",rc2_a) +" +/- "+ sprintf("%6.2e",rc2_a@rstd))
print("drift = "+sprintf("%6.4f",p_rc_2a) +" +/- "+ sprintf("%6.4f",p_se_2a) +" %")
print("----------------")
print("r = "+cval1_a)
print("corr slope = "+rc1_a+" +/- "+sprintf("%6.2e",rc1_a@rstd))
print("****************************************")


end if ; create CSV of comparisons

end

