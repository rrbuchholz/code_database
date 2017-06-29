;=======================================================;
;  subset-mopitt.ncl
;=======================================================;
;
; Concepts illustrated:
;   - For use with MOPITT CO version 6 or 7, level 2 product
;   - Loading CO data from MOPITT .he5 file
;          - select daytime retrievals
;          - select for spatial region around station
;   - Write data out to netCDF
;
;   Files needed:
;         -MOPITT level 2, daily hdf files
;
;   To run type:
;         ncl subset-mopitt.ncl 
;                                  RRB January 8, 2015
;=======================================================;
; load the libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------

  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  version = "V7J"
  location_name = "Arrival Heights"
  if (version.eq."V6J") then
  ; remove 200003/0303 for V6J - nTime is defined too large for NCL (unlimited)
    dummy = systemfunc ("ls /MOPITT/"+version+"/Archive/L2/*/*/MOP02J-*.he5")
    all_files = dummy(235:dimsizes(dummy)-1)
  else 
    all_files = systemfunc ("ls /MOPITT/"+version+"/Archive/L2/*/*/MOP02J-*.he5")
  end if
   ;print(all_files(0:10))

  ; -------------------------------
  ; Start and truncation dates
  ; (beta files when prelim calibration)
  ; -------------------------------
   start_date = 20000101
   truncation_date = 20170101

  ;------------
  ; select location
  ; not defined below
  ;------------
  USERDEF     = False
    if (USERDEF) then
      location_lat = -10
      location_lon = 120
      location     = "location_name"
    end if

  ;------------
  ; distance around 
  ; station
  ;------------
  delta_deg   = 1.0

  ;------------
  ; select daytime 
  ; retrievals
  ;------------
  ; For SZA < 80
  dayflag = 80

  ;------------
  ; toggles
  ;------------
  netCDF         = True
    outdir = "/IASI/home/buchholz/MOPITT_subset/V7/"

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
    suff           = "_MOP02"
    date           = "Time"+suff
    longitude      = "Longitude"+suff
    latitude       = "Latitude"+suff
    tracer         = "RetrievedCOTotalColumn"+suff
    solarza        = "SolarZenithAngle"+suff
    swath_index    = "SwathIndex"+suff
    surface_index  = "SurfaceIndex"+suff
    deg_freedom    = "DegreesofFreedomforSignal"+suff
    tcol_apriori   = "APrioriCOTotalColumn"+suff
    vmr_aprior     = "APrioriCOMixingRatioProfile"+suff
    vmr_surface    = "APrioriCOSurfaceMixingRatio"+suff
    vmr_aposterior = "RetrievedCOMixingRatioProfile"+suff
    apost_surf     = "RetrievedCOSurfaceMixingRatio"+suff
    vmr_avker      = "RetrievalAveragingKernelMatrix"+suff
    pressure_surf  = "SurfacePressure"+suff


  if (location_name.eq."Arrival Heights") then
    location_lat = -77.82
    location_lon = 166.65
    location = "ArrivalHeights"
  else if (location_name.eq."Boulder") then
    location_lat = 48.04
    location_lon = -105.2
    location = "Boulder"
  else if (location_name.eq."Bremen") then
    location_lat = 53.10
    location_lon = 8.85
    location = "Bremen"
  else if (location_name.eq."Darwin") then
    location_lat = -12.424
    location_lon = 130.892
    location = "Darwin"
  else if (location_name.eq."Eureka") then
    location_lat = 80.05
    location_lon = -82.42
    location = "Eureka"
  else if (location_name.eq."Izana") then
    location_lat = 28.30
    location_lon = -16.48
    location = "Izana"
  else if (location_name.eq."Jungfraujoch") then
    location_lat = 46.55
    location_lon = 7.98
    location = "Jungfrau"
  else if (location_name.eq."Kiruna") then
    location_lat = 67.84
    location_lon = 20.41
    location = "Kiruna"
  else if (location_name.eq."Lauder") then
    location_lat = -45.038
    location_lon = 169.684
    location = "Lauder"
  else if (location_name.eq."La Reunion") then
    location_lat = -20.901
    location_lon = 55.485
    location = "Reunion"
  else if (location_name.eq."Mauna Loa") then
    location_lat = 19.54
    location_lon = -155.58
    location = "MaunaLoa"
  else if (location_name.eq."Ny Alesund") then
    location_lat = 78.923
    location_lon = 11.923
    location = "NyAlesund"
  else if (location_name.eq."Paris") then
    location_lat = 48.97
    location_lon = 2.366
    location = "Paris"
  else if (location_name.eq."Rikubetsu") then
    location_lat = 43.46
    location_lon = 143.8
    location = "Rikubetsu"
  else if (location_name.eq."St Petersburg") then
    location_lat = 59.88
    location_lon = 29.83
    location = "StPete"
  else if (location_name.eq."Thule") then
    location_lat = 76.53
    location_lon = -68.74
    location = "Thule"
  else if (location_name.eq."Toronto") then
    location_lat = 43.66
    location_lon = -79.40
    location = "Toronto"
  else if (location_name.eq."Wollongong") then
    location_lat = -34.406
    location_lon = 150.879
    location = "Wollongong"
  else if (location_name.eq."Zugspitze") then
    location_lat = 47.42
    location_lon = 10.98
    location = "Zugspitze"
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
  end if
  end if
  end if
  end if
  end if

  if (netCDF) then
     outname      = outdir+location+"_"+delta_deg+"deg_"+version+"subset.nc"
  end if

   topboundary     = location_lat+delta_deg
   bottomboundary  = location_lat-delta_deg
   rightboundary   = location_lon+delta_deg
   leftboundary    = location_lon-delta_deg

  ; number of files to be read
  ndates = dimsizes(all_files)
  
  ; counter for number of measurements
  dcount = 0

  ; -------------------------------
  ; Truncation to ignore beta files
  ; (prelim calibration applied)
  ; -------------------------------
   file_date = str_split_csv(all_files, "-" ,0)
   select_dates_ind = ind(file_date(:,1).ge.start_date.and.\
                          file_date(:,1).lt.truncation_date)
   selected_files = all_files(select_dates_ind)
   all_files := selected_files

   ;print(all_files(0:10))
   ;print(all_files(dimsizes(all_files)-10:dimsizes(all_files)-1))

;--------------------------------------------
; load file and extract
;--------------------------------------------
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  ;------------
  ; loop over
  ; files
  ;------------
  do i=0,ndates-1
      fin = addfile(all_files(i), "r")            ; read in

      tgas         := fin->$tracer$
      tcol         := tgas(:,0)
      tcol_err     := tgas(:,1)
      lon          := fin->$longitude$
      lat          := fin->$latitude$
      sza          := fin->$solarza$
      time         := fin->$date$
        ;units value presumes use of TAI93 (International Atomic Time) format
        time@units = "seconds since 1993-1-1 00:00:00"
      pixels       := fin->$swath_index$
      surf_type    := fin->$surface_index$
      dofs         := fin->$deg_freedom$
      apriori      := fin->$tcol_apriori$
      vmr_dummy    := fin->$vmr_aprior$
      vmr_surf     := fin->$vmr_surface$
      vmr_apriori  := new((/dimsizes(tcol),10/),float,-9999)
         vmr_apriori(:,0)    = (/vmr_surf(:,0)/)
         vmr_apriori(:,1:9)  = vmr_dummy(:,:,0)
      ret_dummy    := fin->$vmr_aposterior$
      ret_surf     := fin->$apost_surf$
      ret_profile  := new((/dimsizes(tcol),10/),float,-9999)
         ret_profile(:,0)    = (/ret_surf(:,0)/)
         ret_profile(:,1:9)  = ret_dummy(:,:,0)
      ak           := fin->$vmr_avker$
      psurf        := fin->$pressure_surf$


    ;--------------------------------------------
    ; select region to bin (daytime retrievals)
    ;--------------------------------------------
    region := ind(sza.le.dayflag.and.\
                 lat.le.topboundary.and.\
                 lat.ge.bottomboundary.and.\
                 lon.ge.leftboundary.and.\
                 lon.le.rightboundary)

    if (all(ismissing(region))) then
      print("No MOPITT data at " + location +\
            " for file " + i +", date: "+cd_calendar(time(i),4))
      continue  ; skip all the next bit and go to next file
    end if
    
    tempcount = dcount
    dcount := tempcount+1

    print("***Collecting MOPITT data at " + location +\
          " for file "+i+", date: "+cd_calendar(time(i),4))
    region_tcol    := tcol(region)
    region_lat     := lat(region)
    region_lon     := lon(region)
    region_time    := time(region)     ; time in seconds since 1993-1-1 00:00:00 (TAI93)
    region_err     := tcol_err(region)
    region_pix     := pixels(region,0)
    region_stype   := surf_type(region)
    region_dofs    := dofs(region)
    region_ap      := apriori(region)
    region_psurf   := psurf(region)
    region_v_ap    := vmr_apriori(region, :)
    region_profile := ret_profile(region, :)
    region_ak      := ak(region, :, :)  

      ;--------------------------------------------
      ; append to arrays
      ;--------------------------------------------
    if (any(.not.ismissing(region_tcol))) then
      ;--------------------------------------------
      ; Collect MOPITT data that correspond 
      ; with FTS dates
      ;--------------------------------------------
      do k=0,dimsizes(region_tcol)-1
        if (.not.ismissing(region_tcol(k))) then

          if (dimsizes(region_ap).eq.1) then
            ;accounting for loss of 1st dim if only 1 pixel around station
            a=region_v_ap(:)
            b=region_profile(:)
            c=region_ak(:,:)
          else
            a=region_v_ap(k,:)
            b=region_profile(k,:)
            c=region_ak(k,:,:)
          end if

          if (.not.(isdefined("time_selected"))) then
          ;--- time
            time_selected = region_time(k)
          ;--- total column
            mopitt_selected  = region_tcol(k)
          ;--- latitude
            lat_selected = region_lat(k)
          ;--- longitude
            lon_selected = region_lon(k)
          ;--- errors
            err_selected = region_err(k)
          ;--- surface pressure
            psurf_selected = region_psurf(k)
          ;--- pixel number
            pixel_selected = region_pix(k)
          ;--- surface type
            stype_selected = region_stype(k)
          ;--- dofs
            dofs_selected = region_dofs(k)
          ;--- a priori (column)
            ap_selected = region_ap(k)
          ;--- a priori (vmr profile)
            m_apriori_selected = new((/1,10/),float)
            m_apriori_selected(0,:) = a
          ;--- a posteriori (vmr profile)
            m_profile_selected = new((/1,10/),float)
            m_profile_selected(0,:) = b
          ;--- zveraging kernel
            m_ak_selected = new((/1,10,10/),float)
            m_ak_selected(0,:,:) = c
          else
            temp0 := time_selected
            temp1 := mopitt_selected
            temp2 := lat_selected
            temp3 := lon_selected
            temp4 := err_selected
            temp5 := psurf_selected
            temp6 := pixel_selected
            temp7 := stype_selected
            temp8 := dofs_selected
            temp9 := ap_selected
            temp10 := m_apriori_selected
            temp11 := m_profile_selected
            temp12 := m_ak_selected

          ;--- time 
            time_selected := array_append_record(temp0,region_time(k),0)
          ;--- total column
            mopitt_selected := array_append_record(temp1,region_tcol(k),0)
          ;--- latitude
            lat_selected := array_append_record(temp2,region_lat(k),0)
          ;--- longitude
            lon_selected := array_append_record(temp3,region_lon(k),0)
          ;--- errors
            err_selected := array_append_record(temp4,region_err(k),0)
          ;--- surface pressure
            psurf_selected := array_append_record(temp5,region_psurf(k),0)
          ;--- pixel number
            pixel_selected := array_append_record(temp6,region_pix(k),0)
          ;--- surface type
            stype_selected := array_append_record(temp7,region_stype(k),0)
          ;--- dofs
            dofs_selected := array_append_record(temp8,region_dofs(k),0)
          ;--- a priori (column)
            ap_selected := array_append_record(temp9,region_ap(k),0)
          ;--- a priori (vmr profile)
            dummy := new((/1,10/),float)
            dummy(0,:) = a
            m_apriori_selected := array_append_record(temp10,dummy,0)
          ;--- a posteriori (vmr profile)
            dummy2 := new((/1,10/),float)
            dummy2(0,:) = b
            m_profile_selected := array_append_record(temp11,dummy2,0)
          ;--- zveraging kernel
            dummy3 := new((/1,10,10/),float)
            dummy3(0,:,:) = c
            m_ak_selected := array_append_record(temp12,dummy3,0)
          end if      
        end if
      end do
    end if ; collect if not missing in region_tcol

  end do
  ;printVarSummary(mopitt_selected)
  ;printVarSummary(time_selected)
  ;print(mopitt_selected)
  ;print(time_selected)
  ;printVarSummary(m_ak_selected)

  records = num(mopitt_selected)
  print("******************************")
  print(version)
  print("Number of files checked = " + ndates)
  print("Number of files with " +location+" info = " + dcount)
  print("Number of pixels = " + records)


;--------------------------------------------
; Write out to a netCDF file
;--------------------------------------------
if (netCDF) then
  ; saves MOPITT subset

  fout = addfile(outname, "c")
  ;------------
  ; File 
  ; Attributes
  ;------------
  setfileoption(fout, "DefineMode",True)
    fAtt                      = True
      fAtt@title              = "Subset of MOPITT CO at " + delta_deg + \
                                " degrees radius around " +location+ " station"
      fAtt@source             = "MOPITT level 2, version 6, thermal IR retrievals"
      fAtt@creation_date      = systemfunc ("date")
      fAtt@conventrions       = "CF"

     fileattdef(fout, fAtt)
  setfileoption(fout, "DefineMode",False)

  ;------------
  ; Variables
  ;------------

   mopitt_selected!0              = "time"

   err_selected@long_name         = "RetrievedCOTotalColumnError"
   err_selected!0                 = "time"

   lat_selected!0                 = "time"
   lon_selected!0                 = "time"
   time_selected!0                = "time"
   pixel_selected!0               = "time"
   stype_selected!0               = "time"
   psurf_selected!0               = "time"
   dofs_selected!0                = "time"
   ap_selected!0                  = "time"

   m_apriori_selected!0           = "time"
   m_profile_selected!0           = "time"
   m_ak_selected!0                = "time"

   ;--- total column
     fout->RetrievedCOTotalColumn        = mopitt_selected
   ;--- total column error
     fout->RetrievedCOTotalColumnError   = err_selected
   ;--- latitude
     fout->Latitude                      = lat_selected
   ;--- longitude
     fout->Longitude                     = lon_selected
   ;--- time
     fout->Time                          = time_selected
   ;--- pixel number
     fout->SwathIndex                    = pixel_selected
   ;--- surface type
     fout->SurfaceIndex                  = stype_selected
   ;--- surface pressure
     fout->SurfacePressure               = psurf_selected
   ;--- dofs
     fout->DegreesofFreedomforSignal     = dofs_selected
   ;--- a priori (column)
     fout->APrioriCOTotalColumn          = ap_selected
   ;--- a priori (vmr profile)
     fout->APrioriCOMixingRatioProfile   = m_apriori_selected
   ;--- a posteriori (vmr profile)
     fout->RetrievedCOMixingRatioProfile = m_profile_selected
   ;--- averaging kernel
     fout->RetrievalAvKerMatrix          = m_ak_selected

end if ;NETCDF


end

