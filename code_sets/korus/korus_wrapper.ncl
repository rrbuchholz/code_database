;=======================================================;
;  korus_wrapper.ncl
;=======================================================;
;
; Concepts illustrated:
;   - developed for the KORUS 2016 campaign
;   - call other NCL-subroutines
;   - send variables to sub-routines
;   - mainly need to alter this file to alter output plots
;
;   Files needed:
;         -CAM-chem output in netCDF format
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
;         ncl  korus_wrapper.ncl 
;                                  RRB February 29, 2016
;=======================================================;
; load the libraries and sub-routines
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/buchholz/NCL_programs/korus/lat_lon_plot.ncl"
load "/glade/u/home/buchholz/NCL_programs/korus/altitude_ts_plot.ncl"
load "/glade/u/home/buchholz/NCL_programs/korus/curtain_plot.ncl"


begin

  if (.not. isvar("filename")) then      ; is filename from command line?
    filename = "/glade/scratch/barre/archive/KORUS_forecast_3inst/atm/hist/KORUS_forecast_3inst.cam_0001.h1.2016-05-01-00000.nc"
    print("korus_wrapper: Input file not given, setting to "+filename)
    forecast_date = 20160501
  end if

  ; -------------------------------
  ; Select which style/s to plots
  ; -------------------------------
  if (.not. isvar("LATLON")) then       ; is LATLON from command line?
      LATLON = False
      print("Setting LATLON to "+LATLON)
  end if
  if (.not. isvar("LATLON_KOREA")) then       ; is LATLON from command line?
      LATLON_KOREA = False
      print("Setting LATLON_KOREA to "+LATLON_KOREA)
  end if
  if (.not. isvar("STATION")) then      ; is STATION from command line?
      STATION = False
      print("Setting STATION to "+STATION)
      file_prefix = "/glade/scratch/barre/archive/KORUS_forecast_3inst/atm/hist/KORUS_forecast_3inst.cam_0001.h1."
  end if
  if (.not. isvar("CURTAIN")) then      ; is CURTAIN from command line?
      CURTAIN = False
      print("Setting CURTAIN to "+CURTAIN)
  end if

    ;------------
    ; tracers to plot
    ; (note: needs to be 
    ; name in CAM-chem file)
    ;------------
    if (.not. isvar("tracer_array")) then       ; is tracer_array from command line?
        ;tracer_array = (/"CO", "CO01", "CO02", "CO03","CO04","CO05","CO06","CO07","CO08","CO09",\
        ;                 "ISOP_etc", "O3", "NOx", "BC", "OC", "SOA", "SO4", "PAN",  "AEROD_v", \
        ;                  "CO_var", "DUST_ODV"/)
        tracer_array = (/"CO", "CO01", "CO02", "CO03","CO04","CO05","CO06",\
                         "ISOP_etc", "O3", "NOx", "BC", "OC", "SOA", "SO4", "PAN",  "AEROD_v", \
                          "CO_var", "DUST_ODV"/)
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
        contour_levels    := (/40.,60.,80.,100., 120.,140.,160.,\
                            180., 200., 240., 280., 300. ,350.,400.,\
                            450., 500., 600., 800., 1000., 1200., 1600., 2000./)
      else if (tracer.eq."CO01".or.tracer.eq."CO02".or.tracer.eq."CO03".or.\
               tracer.eq."CO04".or.tracer.eq."CO05".or.tracer.eq."CO06".or.\
               tracer.eq."CO07".or.tracer.eq."CO08".or.tracer.eq."CO09") then
        contour_levels    := (/ 0.,1.,2.,5.,10.,15.,20.,25.,30.,40.,60.,80.,120.,250./)
      else if (tracer.eq."CO_var") then
        contour_levels    := (/-0.2,-0.1, 0., 0.05,0.1,0.15,0.2, 0.25,0.3,\
                            0.35,0.4,0.5,0.6,0.7,0.8,0.9,1.0,1.2,1.4/)
      else if (tracer.eq."ISOP_etc") then
        contour_levels    := (/ 0.005,0.01,0.02,0.03,0.04,0.05,0.1,0.15,0.2,0.25,\
                                0.3,0.4,0.6,0.8,1.0,1.2,1.4,1.6,1.8,2.,\
                                3.,4.,5.,6.,7.,8.,10.,15.,20./)
      else if (tracer.eq."NOx") then
        contour_levels    := (/ 0.1,0.2,0.3,0.4,0.5,1.0,1.5,2.,\
                              2.5,3.,4.,5.,6.,7.,8.,10.,15.,20.,40.,60./)
      else if (tracer.eq."O3") then
        contour_levels    := (/25.,30.,35.,40.,45.,50.,55.,60.,65.,70.,75.,\
                              80.,85.,90.,100.,110.,120.,130.,140.,150.,200./)
      else if (tracer.eq."BC".or.tracer.eq."OC") then
        contour_levels    := (/0e-10,1.1e-10,1.2e-10,1.3e-10,1.4e-10,1.6e-10,1.8e-10,\
                              1.0e-09,1.4e-09,1.8e-09,2.2e-09,2.6e-09,3e-09,4e-09,\
                              5e-09,6e-09,1e-08,3e-08/)
      else if (tracer.eq."SOA") then
        contour_levels    := (/0.5e-11,1e-11,2e-11,3e-11,4e-11,5e-11,6e-11,7e-11,8e-11,9e-11,\
                              1e-10,1.2e-10,1.4e-10,1.6e-10,1.8e-10,2.0e-10,4.0e-10,6.0e-10,8.0e-10,\
                              1.0e-09,2e-09,3e-09,4e-09,5e-09,5.0e-08,5.0e-07/)
      else if (tracer.eq."SO4") then
        contour_levels    := (/1e-10,1.2e-10,1.4e-10,1.8e-10,\
                              1.2e-09,1.4e-09,1.6e-09,1.8e-09,1.9e-09,2e-09,3e-09,4e-09,\
                              5e-09,1e-08,1.5e-08,2.0e-08,3.0e-08,4.0e-08,5.0e-08,6.0e-08/)
      else if (tracer.eq."PAN") then
        contour_levels    := (/ 0.,0.2,0.3,0.4,0.5,0.6,0.8,1.0,1.4,\
                              1.8,2.,4.,6.,8.,10.,15.,20./)
      else if (tracer.eq."AEROD_v".or.tracer.eq."DUST_ODV") then
        contour_levels    := (/ 0.,0.05,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,\
                               1.0,1.2,1.4,1.6,1.8,2.,4.,6./)

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
    ; Lat/Lon plots
    ;------------
    ; pressure levels to plot
    pnew = (/ 850., 700., 500., 300./)

    if (LATLON) then
    print("plotting lat/lon for ..."+ filename)
    ; ASIA large boundary
     lat_top     = 60
     lat_bottom  = 20
     lon_left    = 75
     lon_right   = 145
     ; Name region for filename
     region_name = "asia"

     lat_lon_plot(filename, tracer, lat_top, lat_bottom, lon_left, lon_right,\
                  pnew, region_name, contour_levels, forecast_date)

     system("rsync -pI *"+tracer+"*latlon_"+region_name+"*.png buchholz@amadeus.acom.ucar.edu:/data/web/mz4_output/korus_plots/camchem/maps/"+region_name)
    end if ; LATLON

    if (LATLON_KOREA) then
    ; KOREA zoomed boundary
     lat_top_zoom     = 47
     lat_bottom_zoom  = 27
     lon_left_zoom    = 110
     lon_right_zoom   = 135
     ; Name region for filename
     region_name = "east_asia"

     lat_lon_plot(filename, tracer, lat_top_zoom, lat_bottom_zoom, lon_left_zoom, lon_right_zoom,\
                  pnew, region_name, contour_levels, forecast_date)

     system("rsync -pI *"+tracer+"*latlon_"+region_name+"*.png buchholz@amadeus.acom.ucar.edu:/data/web/mz4_output/korus_plots/camchem/maps/"+region_name)

     end if ; LATLON_KOREA


     ;------------
     ; curtain plots
     ;------------
     if (CURTAIN) then

       if (tracer.eq."AEROD_v".or.\
           tracer.eq."DUST_ODV") then
         print("no altitudes for 2D variable")
         continue   ; no curtain for 2D variable
       end if

       print("plotting curtains")
         curtain_plot(filename, tracer, contour_levels, forecast_date)

     ;system("rsync --remove-source-files -pI *"+tracer+"*curtain*.png buchholz@amadeus.acom.ucar.edu:/data/web/mz4_output/korus_plots/camchem/curtains")

     system("rsync -pI *"+tracer+"*curtain*.png buchholz@amadeus.acom.ucar.edu:/data/web/mz4_output/korus_plots/camchem/curtains")

     end if ; CURTAIN

  ;------------
  ; station plots
  ;------------
  if (STATION) then
    if (tracer.eq."AEROD_v".or.\
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

      print("plotting timeseries for ..."+ filenames(0)+" to "+filenames(dimsizes(filenames)-1))

    ; station locations
    ;'Baengnyeong Island',37.9660,124.6300
    ;'Seoul_SNU',37.4580,126.9510
    ;'Gosan, Jeju Island',33.2920,126.1620
    ;'Pusan Univ., Busan',35.2350,129.0830
    ;'GIST, Gwangju',35.2280,126.8430
    ;'Fukue, Japan',32.751626,128.681728
    ;'Gangneung-Wonju Univ.',37.7710,128.8670

    lat_array = (/ 37.9660, 37.4580, 33.2920, 35.2350, 35.2280, 32.751626, 37.7710/)
    lon_array = (/124.6300, 126.9510, 126.1620, 129.0830, 126.8430, 128.681728, 128.8670/)
    station_names = (/"Baeognyeong", "Seoul", "Gosan", "Busan", "Gwangju", "Fukue", "Gangneung-Wonju"/)

    altitude_ts_plot(filenames, tracer, lat_array, lon_array, station_names, contour_levels, forecast_date)

  system("rsync -pI *"+tracer+"*5dForecast*.png buchholz@amadeus.acom.ucar.edu:/data/web/mz4_output/korus_plots/camchem/sites")

  end if ; STATION

end do ;tracer loop


end

