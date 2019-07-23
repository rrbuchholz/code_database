;=======================================================;
;  firex_wrapper.ncl
;=======================================================;
;   - contours adjusted
;                            RS, WT, SW, RRB July 1, 2019 
; ------------------------------------------------------;
; Concepts illustrated:
;   - developed for the FIREX 2019 from the KORUS 2016 campaign
;   - call other NCL-subroutines
;   - send variables to sub-routines
;   - mainly need to alter this file to alter output plots
;
;   Files needed:
;         -model output in netCDF format
;         -NCL code of sub-routines that are called:
;                 lat_lon_plot.ncl
;                 altitude_plot.ncl
;                 curtain_plot.ncl
; 
; ncl {optional variables: 'filename=string' 'file_prefix=string' forecast_date=numeric \
;       STATION=Boolean LATLON=Boolean LATLON_KOREA=Boolean CURTAIN=Boolean \
;       'tracer_array=string array'} korus_wrapper.ncl
;
;   To run type:
;         ncl  firex_wrapper.ncl 
;                                  RRB February 29, 2016
;=======================================================;
; load the libraries and sub-routines
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "lat_lon_plot.ncl"
load "altitude_ts_plot.ncl"
load "curtain_plot.ncl"


begin

  if (.not. isvar("filename")) then      ; is filename from command line?
    filename = "/waccm-output/f.e21.FWSD.f09_f09_mg17.forecast.001.cam.h3.2019-06-30-00000.nc"
    print("korus_wrapper: Input file not given, setting to "+filename)
    forecast_date = 20190620
  end if
  print("Processing " + filename)
  hold_mainfile = filename

  ; -------------------------------
  ; Select which style/s to plots
  ; -------------------------------
  if (.not. isvar("LATLON")) then       ; is LATLON from command line?
      LATLON = False
      print("Setting LATLON to "+LATLON)
  end if
  if (.not. isvar("LATLON_WUS")) then       ; is LATLON from command line?
      LATLON_WUS = False
      print("Setting LATLON_WUS to "+LATLON_WUS)
  end if
  if (.not. isvar("LATLON_SEUS")) then       ; is LATLON from command line?
      LATLON_SEUS = False
      print("Setting LATLON_SEUS to "+LATLON_SEUS)
  end if
  if (.not. isvar("STATION")) then      ; is STATION from command line?
      STATION = False
      print("Setting STATION to "+STATION)
      file_prefix = "/waccm-output/f.e21.FWSD.f09_f09_mg17.forecast.001.cam.h3."
  end if
  if (.not. isvar("CURTAIN")) then      ; is CURTAIN from command line?
      CURTAIN = False
      print("Setting CURTAIN to "+CURTAIN)
  end if

    ;------------
    ; tracers to plot
    ; (note: needs to be 
    ; name in model file)
    ;------------
    if (.not. isvar("tracer_array")) then       ; is tracer_array from command line?
        ;2019 tracers
        tracer_array = (/"ISOP", "NOx","O3","O3S","PAN","BC","POM","SOA","SO4",\
                        "DUST","PM25","AODVISdn","CO","CO01","QFED_CO","CO02","COnotNA"/)
        ;2018 tracers
        ;tracer_array = (/"NOx","O3","O3S","PAN","BC","POM","SOA","SO4",\
        ;                "DUST","CO","CO01","CO02","COnotNA"/)
        ; test tracers
        ; tracer_array = (/"CO", "O3"/)
        print("Setting up tracer list "+tracer_array)
    end if

    ;if (.not. isvar("tracer_array")) then       ; is tracer_array from command line?
    ;    tracer_array = (/ "AEROD_v"/)
    ;    print("Setting up tracer list "+tracer_array)
    ;end if


    ;loop over tracers
    do s = 0,dimsizes(tracer_array)-1
      tracer = tracer_array(s)
      if (tracer.eq."CO") then
        contour_levels    := (/40.,50.,60.,70.,80.,90.,100.,120.,140.,160.,\
                            180.,200.,250.,300.,350.,400.,450.,500.,550.,600.,650.,700.,750.,800.,850.,900./)
        curtain_contour_levels  := (/40.,50.,60.,70.,80.,90.,100.,110.,120.,130.,140.,150.,160.,\
                            170.,180.,190., 200., 240., 280., 300. ,350.,400.,450.,500./)
      else if (tracer.eq."CO01".or.tracer.eq."QFED_CO".or.\
              tracer.eq."CO02".or.tracer.eq."COnotNA") then
        contour_levels    := (/2.,4.,6.,8.,10.,15.,20.,25.,30.,35.,\
                     40.,45.,50.,60.,70.,80.,90.,100.,200.,300.,400.,500.,600.,700.,800./)
        curtain_contour_levels := (/ 0.,1.,2.,4.,6.,8.,10.,12.,14.,16.,18.,20.,22.,24.,26.,28.,\
                             30.,35.,40.,50.,60.,80.,120.,180.,250./)
      else if (tracer.eq."ISOP") then
        contour_levels    := (/ 0.0,0.02,0.04,0.06,0.08,0.1,0.5,\
                                1.0,1.5,2.,2.5,3.,3.5,4.,5.,\
                                6.,7.,8.,9.,10.,15.,20.,25.,30./) 
        curtain_contour_levels :=  (/ 0.005,0.01,0.02,0.03,0.04,0.05,0.1,0.15,0.2,0.25,\
                                0.3,0.4,0.6,0.8,1.0,1.2,1.4,1.6,1.8,2.,\
                                3.,4.,5.,6.,7.,8.,10.,15.,20./)
      else if (tracer.eq."NOx") then
        contour_levels    := (/ 0.0,0.05,0.1,0.2,0.4,0.6,0.8,1.,2.,\
                              3.,4.,5.,6.,7.,8.,9.,10.,12.,14.,16.,18.,20.,25.,30.,35.,40./)
        curtain_contour_levels := (/ 0.005,0.01,0.025,0.05,0.1,0.2,0.3,0.4,0.5,1.0,1.5,2.,\
                              2.5,3.,4.,5.,6.,7.,8.,9.,10.,12.,14.,16.,18.,20./)
      else if (tracer.eq."O3") then
        contour_levels    := (/20.,25.,30.,35.,40.,45.,50.,55.,60.,65.,70.,75.,\
                              80.,85.,90.,100.,110.,120.,130.,140.,160.,180.,200./)
        curtain_contour_levels := contour_levels
      else if (tracer.eq."O3S") then
        contour_levels    := (/0.,1.,2.,3.,4.,5.,10.,15.,20.,25.,30.,\
                              35.,40.,50.,60.,70.,80.,90.,100.,150.,200./)      
        curtain_contour_levels :=  (/10., 15., 20., 25.,30.,35.,40.,45.,50.,55.,\
                              60.,65.,70.,75.,80.,85.,90.,100.,120.,140.,160./)
      else if (tracer.eq."BC") then
        contour_levels    :=  (/ 0.0,0.2,0.4,0.6,0.8,1.0,1.5,2.,\
                              2.5,3.,3.5,4.,4.5,5.,6.,7.,8.,9.,10.,12.,14.,16.,18.,20.,22.,24./)
        curtain_contour_levels := array_append_record(fspan(0, 0.5, 16), (/1.0,2.0,3.0/), 0)
      else if (tracer.eq."POM") then
        contour_levels    :=  (/ 0.0,0.2,0.4,0.6,0.8,1.0,2.,\
                              3.,4.,5.,6.,7.,8.,9.,10.,20.,30.,40.,50.,60.,70.,80.,90.,100./)
        curtain_contour_levels := array_append_record(fspan(0, 1.0, 11), fspan(2.0, 10.0, 9), 0)
      else if (tracer.eq."SOA") then
        contour_levels    :=  (/ 0.0,0.2,0.4,0.6,0.8,1.,2.,\
                              3.,4.,5.,6.,7.,8.,9.,10.,15.,20.,25.,30.,35.,40.,50.,60.,70.,80./)
        curtain_contour_levels := array_append_record(fspan(0, 1.0, 11), fspan(2.0, 10.0, 9), 0)
      else if (tracer.eq."SO4") then
        contour_levels    := (/ 0.0,0.2,0.4,0.6,0.8,1.0,1.5,2.,\
                              2.5,3.,3.5,4.,4.5,5.,6.,7.,8.,9.,10.,15.,20./)
        curtain_contour_levels := array_append_record(fspan(0, 1.0, 11), fspan(2.0, 15.0, 14), 0)
      else if (tracer.eq."DUST") then
        contour_levels    := (/ 0.,0.2,0.4,0.6,0.8,1.,2.,4.,\
                              6.,8.,10.,15.,20.,25.,30.,40.,50.,60.,70.,80./)
        curtain_contour_levels :=  array_append_record(fspan(0, 5.0, 11), fspan(6.0, 30.0, 25), 0)
      else if (tracer.eq."PM25") then
        contour_levels    :=  (/ 0.0,0.5,1.,2.,3.,4.,5.,\
                              6.,7.,8.,9.,10.,15.,20.,25.,30.,35.,40.,50.,60.,70.,80.,90.,100./)
        curtain_contour_levels := array_append_record(fspan(0, 1.0, 11), fspan(2.0, 15.0, 14), 0)
      else if (tracer.eq."PAN") then
        contour_levels    := (/ 0.,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0,1.5,\
                              2.,2.5,3.,3.5,4.,4.5,5.,6.,7.,8.,9.,10./)      
        curtain_contour_levels := (/ 0.,0.2,0.3,0.4,0.5,0.6,0.8,1.0,1.4,\
                              1.8,2.,4.,6.,8.,10.,15.,20./)
      else if (tracer.eq."AODVISdn".or.tracer.eq."DUST_ODV") then
        contour_levels    := (/ 0.,0.025,0.05,0.075,0.1,0.125,0.15,0.175,0.2,0.25,0.3,0.35,0.4,0.45,0.5,0.55,\
                               0.6,0.65,0.7,0.75,0.8/)
      else
        contour_levels    := (/20.,25.,30.,35.,40.,45.,50.,55.,60.,65.,70.,75.,\
                              80.,85.,90.,100.,110.,120.,130.,140.,150.,200./)
        curtain_contour_levels := contour_levels
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if

    ;------------
    ; different infile for QFED fire
    ;------------
     if (tracer.eq."QFED_CO") then
        new_filename_1 = str_sub_str(filename,"forecast.001.cam","forecast.002.cam")
        new_filename = str_sub_str(new_filename_1,"finn","qfed")
        filename = new_filename
      else
        filename = hold_mainfile
      end if


    ;------------
    ; Lat/Lon plots
    ;------------
    ; pressure levels to plot
    pnew = (/ 850., 700., 600., 500., 300., 200./)

    if (LATLON) then
    print("plotting lat/lon for ..."+tracer+" in file "+ filename)
    ; CONUS large boundary
     lat_top     = 65
     lat_bottom  = 15
     lon_left    = -140
     lon_right   = -70
     ; Name region for filename
     region_name = "north_america"

     lat_lon_plot(filename, tracer, lat_top, lat_bottom, lon_left, lon_right,\
                  pnew, region_name, contour_levels, forecast_date)

      ;system("rsync -pI forecast_plots/*"+tracer+"*latlon_"+region_name+"*.png buchholz@modeling1.acom.ucar.edu:/data14b/siyuan/firex-plots/lat-lon")
    end if ; LATLON

    if (LATLON_WUS) then
    ; WESTERN US zoomed boundary
     lat_top_zoom     = 57
     lat_bottom_zoom  = 32
     lon_left_zoom    = -129
     lon_right_zoom   = -104
     ; Name region for filename
     region_name = "west_usa"

     lat_lon_plot(filename, tracer, lat_top_zoom, lat_bottom_zoom, lon_left_zoom, lon_right_zoom,\
                  pnew, region_name, contour_levels, forecast_date)

     ;system("rsync -pI forecast_plots/*"+tracer+"*latlon_"+region_name+"*.png buchholz@modeling1.acom.ucar.edu:/data14b/siyuan/firex-plots/lat-lon")

     end if ; LATLON_WUS

    if (LATLON_SEUS) then
    ; SOUTHEAST US zoomed boundary
     lat_top_zoom     = 42.5
     lat_bottom_zoom  = 25.
     lon_left_zoom    = -102.5
     lon_right_zoom   = -75
     ; Name region for filename
     region_name = "seast_usa"

     lat_lon_plot(filename, tracer, lat_top_zoom, lat_bottom_zoom, lon_left_zoom, lon_right_zoom,\
                  pnew, region_name, contour_levels, forecast_date)

     ;system("rsync -pI forecast_plots/*"+tracer+"*latlon_"+region_name+"*.png buchholz@modeling1.acom.ucar.edu:/data14b/siyuan/firex-plots/lat-lon")

     end if ; LATLON_SEUS

     ;------------
     ; curtain plots
     ;------------
     if (CURTAIN) then

       if (tracer.eq."AODVISdn".or.\
           tracer.eq."DUST_ODV") then
         print("no altitudes for 2D variable")
         continue   ; no curtain for 2D variable
       end if

       print("plotting curtains for "+ tracer)
         curtain_plot(filename, tracer, curtain_contour_levels, forecast_date)

     ;system("rsync --remove-source-files -pI forecast_plots/*"+tracer+"*curtain*.png buchholz@modeling1.acom.ucar.edu:/data14b/siyuan/firex-plots/curtains")

     ;system("rsync -pI forecast_plots/*"+tracer+"*curtain*.png buchholz@modeling1.acom.ucar.edu:/data14b/siyuan/firex-plots/curtains")

     end if ; CURTAIN

  ;------------
  ; station plots
  ;------------
  if (STATION) then
    if (tracer.eq."AODVISdn".or.\
        tracer.eq."DUST_ODV") then
       print("no altitudes for 2D variable")
       continue   ; no altitudes for 2D variable
    end if

    if (.not. isvar("file_prefix")) then      ; is filename from command line?
      print("korus_wrapper: STATION file prefix not given")
    end if

    ; determine 6 files
    current_yeardoy = yyyymmdd_to_yyyyddd(forecast_date)
    date_array= new((/6/), string)
    do i = 0,5
      YYYYMMDD = yyyyddd_to_yyyymmdd(current_yeardoy+i)
      date_array(i) = systemfunc("date --date="+YYYYMMDD+" +%Y-%m-%d")
    end do

    filenames = new((/dimsizes(date_array)/), string)
    do d = 0, dimsizes(date_array)-1
      filenames(d) = systemfunc ("ls "+file_prefix+date_array(d)+"-00000.nc")
    end do


      print("plotting timeseries for "+tracer+"..."+ filenames(0)+" to "+filenames(dimsizes(filenames)-1))

    ; station locations ------------------------------------------------
    ;'Boise, ID Airport',           43.562, -116.228+360     , 243.772
    ;'McCall, ID',                  44.872, -116.115+360     , 243.885
    ;'Mount Bachelor, OR',          43.979, -121.689+360     , 238.311
    ;'Missoula, MT',                46.860, -113.985+360     , 246.015
    ;'DRAGON site',                 46.917, -114.083+360     , 245.917
    ;'Salina, KS Regional Airport', 38.779, -97.6395+360     , 262.3605    
    ;'Portland'                   , 45.516, -122.6793+360    , 237.321
    ;'Spokane'                    , 47.659, -117.4260+360    , 242.574
    ;'Salt-Lake-City'             , 40.761, -111.8910+360    , 248.109
    ;'Kansas-City'                , 39.100, -94.5786+360     , 265.421
    ;'Oklahoma-City'              , 35.468, -97.5164+360     , 262.484
    ;'Denver'                     , 39.739, -104.9903+360    , 255.010
    ;'Omaha'                      , 41.257, -95.9345+360     , 264.066
    ; TOLNet sites ----------------------------------------------------
    ;RO3QET           , 86.645W --> 273.355, 34.725N, POC: Dr. Mike Newchurch (mike@nsstc.uah.edu) loc: Huntsville, AL
    ;TMF              , 117.68W --> 242.32 , 34.38N, POC: Dr. Thierry Leblanc (thierry.leblanc@jpl.nasa.gov) loc: Wrightwood, CA
    ;AMOLITE          , 111.64W --> 248.36 , 57.184N, POC: Dr. Kevin Strawbridge (kevin.b.strawbridge@gmail.com) loc: Alberta, Canada
    ;TROPOZ           , 76.84W  --> 283.16 , 38.99N, POC: Dr. John Sullivan (john.t.sullivan@nasa.gov) loc: Greenbelt, MD
    ;TOPAZ            , 105.262W--> 254.738, 39.993N, POC: Dr. Chris Senff (christoph.senff@noaa.gov) loc: Boulder, CO
    ;LMOL             , 76.385W --> 283.615, 37.096N, POC: Dr. Tim Berkoff (timothy.a.berkoff@nasa.gov) loc: Hampton, VA
    
    lat_array = (/43.562, 44.872, 43.979, 46.860, 46.917, 38.779, 45.516, 47.659, 40.761, 39.100, 35.468, 39.739, 41.257,\
                 34.725, 34.38, 57.184, 38.99, 39.993, 37.096/)
    lon_array = (/243.772, 243.885, 238.311, 246.015, 245.917, 262.3605, 237.321, 242.574, 248.109, 265.421, 262.484, 255.010, 264.066,\
                 273.355, 242.32, 248.36, 283.16, 254.738, 283.615/)
    station_names = (/"Boise-ID-Airport", "McCall-ID", "Mount-Bachelor-OR", "Missoula-MT", "DRAGON-site", "Salina-KS-Regional-Airport", \
                     "Portland", "Spokane", "Salt-Lake-City", "Kansas-City", "Oklahoma-City", "Denver", "Omaha",\
                      "RO3QET", "TMF", "AMOLITE", "TROPOZ", "TOPAZ", "LMOL"/)

    altitude_ts_plot(filenames, tracer, lat_array, lon_array, station_names, curtain_contour_levels, forecast_date)

  ;system("rsync -pI forecast_plots/*"+tracer+"*5dForecast*.png buchholz@modeling1.acom.ucar.edu:/data14b/siyuan/firex-plots/stations")

  end if ; STATION

end do ;tracer loop


end

