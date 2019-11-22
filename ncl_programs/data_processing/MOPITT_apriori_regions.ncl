;============================================
; apply_MOPITT_AK_reanalysis.ncl
;============================================
;
; Concepts Illustrated
;          - Open reanalysis files
;          - Load MOPITT L3 AK and a priori
;          - Convolve the model with AK and ap
;          - average over regions
;          - write out to netCDF
;
; To use type on the command line:
;          > ncl apply_MOPITT_AK_reanalysis.ncl
;                            RRB Oct 1, 2019
;============================================
load "/IASI/home/buchholz/code_database/ncl_programs/buchholz_global_util/ultrafine_mopitt.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------
  year = 2018
  meas_dir = "/MOPITT/V8T/Archive/L3/"
  meas_files = systemfunc ("ls "+meas_dir+year+"*/month/*.he5")

  ;------------
  ; toggles
  ;------------
  PLOT           = False
    plotType      = "x11"
    plotName      = "test"
   ; -------------------------------
   ; Plotting
   ; -------------------------------
    minlev = 0.5
    maxlev = 4.
    lev_spacing = 0.25

  NETCDF           = True
     outfolder = "~/CAM_chem/regions_MOPITT_apriori/"


;--------------------------------------------
; end user input
;--------------------------------------------
;
;--------------------------------------------
; set up
;--------------------------------------------
  ; -------------------------------
  ; REGIONS
  ; -------------------------------
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
                     (/  0.,  60.,      -180.,     180./),\  ;NH
                     (/-60.,   0.,      -180.,     180./) /) ;SH

  ; -------------------------------
  ; TIME arrays
  ; -------------------------------
  yearmonth = yyyymm_time(year,year, "integer")

;--------------------------------------------
; load data
;--------------------------------------------
do i = 0, dimsizes(meas_files)-1
  fin = addfile(meas_files(i), "r")            ; read in

    sat_time := fin@StartTime_MOP03
      ;units value presumes use of TAI93 (International Atomic Time) format
      sat_time@units = "seconds since 1993-1-1 00:00:00"
    sat_yyyymm = cd_calendar(sat_time,-1)

    ind_compare = ind(yearmonth.eq.sat_yyyymm)
    meas_data_dummy  := fin->APrioriCOTotalColumnDay_MOP03
    dry_air  := fin->DryAirColumnDay_MOP03
    meas_data_vmr  = meas_data_dummy/dry_air
    meas_data_vmr = where(ismissing(meas_data_dummy),meas_data_vmr@_FillValue,meas_data_vmr)
    
    ; set up a collection array
    if (i.eq.0) then
       meas_data = new((/dimsizes(yearmonth), dimsizes(meas_data_dummy(:,0)), dimsizes(meas_data_dummy(0,:))/), float)
    end if

    meas_data(ind_compare,:,:) = meas_data_vmr

end do
    meas_data!0 = "time"
    meas_data&time = yearmonth
    meas_data!1 = "lon"
    meas_data&lon = meas_data_dummy&XDim_MOP03
    meas_data!2 = "lat"
    meas_data&lat = meas_data_dummy&YDim_MOP03

;--------------------------------------------
; Regional averages
;--------------------------------------------
print("*******************************************")

  ;--------------------------------------------
  ; set up map weighting
  ;--------------------------------------------
  ; Calculate averages
     ; weight by gridbox area
     ; prevent negative weights
     re   = 6.37122e06                 ; Earth radius (in metres)
     rad  = 4.0 * atan(1.0) / 180.0    ; Convert degrees to radians (pi radians per 180 deg)
     con  = re * rad                   ; constant for determining arc length 

     newlat = meas_data&lat
     newlon = meas_data&lon
      nlat = dimsizes(newlat)
      mlon = dimsizes(newlon)

     clat = cos(newlat * rad)           ; cosine of latitude
     dlon = (newlon(2) - newlon(1))        ; assume dlon is constant
     dlat = (newlat(2) - newlat(1))        ; assume dlat is constant
     dx   = con * dlon * clat        ; dx (in metres) at each latitude
     dy   = con * dlat               ; dy (in metres) is constant
     dydx = dy * dx                  ; dydx(nlat)

     wgt  = new((/mlon, nlat/), float)
     wgt  = conform(wgt, tofloat(dydx), 1)
      wgt!0 = "lon"
      wgt&lon = newlon
      wgt!1 = "lat"
      wgt&lat = newlat

  ;--------------------------------------------
  ; do the averaging
  ;--------------------------------------------
do r = 0, dimsizes(region_names)-1

   location = region_names(r)

   topboundary     = region_select(r,1)
   bottomboundary  = region_select(r,0)
   rightboundary   = region_select(r,3)
   leftboundary    = region_select(r,2)

   region_smoothed_vmr := meas_data(:,{leftboundary:rightboundary},{topboundary:bottomboundary})
   wgt_region := wgt({leftboundary:rightboundary},{topboundary:bottomboundary})

  ;--------------------------------------------
  ; average over region with spatial weighting
  ;--------------------------------------------
   region_average_vmr := dim_avg_n_Wrap(dim_avg_n_Wrap(region_smoothed_vmr,1),1)
   region_average_vmr_wgt  := wgt_areaave2(region_smoothed_vmr,wgt_region,0)  ; g -> Tg
       region_average_vmr_wgt@units = "ppb"
       region_average_vmr_wgt!0 = "time"
       region_average_vmr_wgt&time = yearmonth
   region_vmr_sd := dim_stddev_n_Wrap(dim_avg_n_Wrap(region_smoothed_vmr,1),1)

print(location+" :"+region_average_vmr/1e-09+" "+region_average_vmr_wgt/1e-09)


  ;--------------------------------------------
  ; Write out region averages
  ;--------------------------------------------
  if (NETCDF) then

     outname      = outfolder+location+"_MOP_apriori_"+year+"monthavg.nc"

  ; saves region average
    print("Creating file...")
    fout = addfile(outname, "c")
    ;------------
    ; File 
    ; Attributes
    ;------------
    setfileoption(fout, "DefineMode",True)
    fAtt                      = True
      fAtt@title              = "MOPITT AK smoothed CAM-chem Reanalysis for " +\
                                 location+" in "+year
      fAtt@source             = "MOPITT level 3, version 8, TIR retrievals and "+\
                                "Gaubert 2017 Renalysis"
      fAtt@info               = "Monthly spatial average over "+location+": "+\
                                    topboundary+" to "+bottomboundary+ " Lat, "+\
                                    leftboundary+" to "+rightboundary+" Lon"
      fAtt@creation_date      = systemfunc ("date")
      fAtt@conventrions       = "CF"

     fileattdef(fout, fAtt)
     setfileoption(fout, "DefineMode",False)

  ;------------
  ; Variables
  ;------------

   ;--- total column
   fout->Model_smoothed_X_CO     = region_average_vmr
   fout->Model_smoothed_X_CO_wgt = region_average_vmr_wgt
   fout->StdDev_smoothed_X_CO    = region_vmr_sd

  end if ; NETCDF

end do ; region averages

end

