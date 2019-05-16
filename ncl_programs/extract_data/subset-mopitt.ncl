;=======================================================;
;  subset-mopitt.ncl
;=======================================================;
;
; Concepts illustrated:
;   - For use with MOPITT CO version 6, 7 or 8, level 2 product
;   - Choose from stations:
;       Arrival Heights, Ascension, Boulder, Bremen, Darwin, Eureka, Izana,
;       Jungfraujoch, Kiruna, Lauder, La Reunion, Mauna Loa, Ny Alesund, 
;       Paris, Rikubetsu, St Petersburg, Thule, Toronto, Wollongong, Zugspitze
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
  ystart = 2001
  yend = 2019
  version = "V8"
  ret = "J"
  location_name = "Eureka"
  if (version.eq."V6".and.ret.eq."J") then
   ;remove 200003/0303 for V6J - nTime is defined too large for NCL (unlimited)
    dummy = systemfunc ("ls /MOPITT/"+version+ret+"/Archive/L2/*/*/MOP02"+ret+"-*.he5")
    all_files = dummy(235:dimsizes(dummy)-1)
  else 
    infolder = "/MOPITT/"+version+ret+"/Archive/L2/"
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
    outdir = "/IASI/home/buchholz/MOPITT_subset/"+version+"/stations/"

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


    ; New parameters in MOPITT files from V7 onwards
    if (version.eq."V7".or.version.eq."V8") then
      diag_1       = "RetrievalAnomalyDiagnostic"+suff
      diag_2       = "RetrievedCOTotalColumnDiagnostics"+suff
      col_avker    = "TotalColumnAveragingKernel"+suff
      col_avker_nodim = "TotalColumnAveragingKernelDimless"+suff
      dry_air_col    = "DryAirColumn"+suff
    end if   

   ; set up station coordinate parameters
   station_names = (/"Altzomoni","Arrival Heights", "Ascension", "Boulder", "Bremen", "Darwin",\
                     "Eureka", "Izana", "Jungfraujoch", "Kiruna", "Lauder", "La Reunion",\
                     "Mauna Loa", "Ny Alesund", "Paris", "Paramibo", "Rikubetsu", "St Petersburg",\
                     "Thule", "Toronto", "Tsukuba", "Wollongong", "Zugspitze"/)

   station_name_comp = (/"Altzomoni","ArrivalHeights", "Ascension", "Boulder", "Bremen", "Darwin",\
                     "Eureka", "Izana", "Jungfrau", "Kiruna", "Lauder", "Reunion",\
                     "MaunaLoa", "NyAlesund", "Paris", "Paramibo", "Rikubetsu", "StPete",\
                     "Thule", "Toronto", "Tsukuba", "Wollongong", "Zugspitze"/)

   ;                   minlat, maxlat, minlon, maxlon
   station_select = (/(/  19.12,  -98.66 /),\  ;Altzomoni
                      (/ -77.82,  166.65 /),\  ;ArrivalHeights
                      (/  -7.91,  -14.33 /),\  ;Ascension
                      (/  39.99, -105.26 /),\  ;Boulder
                      (/  53.10,    8.85 /),\  ;Bremen
                      (/ -12.424, 130.892/),\  ;Darwin
                      (/  80.05,  -82.42 /),\  ;Eureka
                      (/  28.30,  -16.48 /),\  ;Izana
                      (/  46.55,    7.98 /),\  ;Jungfrau
                      (/  67.84,   20.41 /),\  ;Kiruna
                      (/ -45.038, 169.684/),\  ;Lauder
                      (/ -20.901,  55.485/),\  ;Reunion
                      (/  19.54, -155.58 /),\  ;MaunaLoa
                      (/  78.923,  11.923/),\  ;NyAlesund
                      (/  48.97,    2.366/),\  ;Paris
                      (/   5.75,  -55.2  /),\  ;Paramibo
                      (/  43.46,  143.8  /),\  ;Rikubetsu
                      (/  59.88,   29.83 /),\  ;StPete
                      (/  76.53,  -68.74 /),\  ;Thule
                      (/  43.66,  -79.40 /),\  ;Toronto
                      (/  36.05,  140.13 /),\  ;Tsukuba
                      (/ -34.406, 150.879/),\  ;Wollongong
                      (/  47.42,   10.98 /) /) ;Zugspitze


   ind_station = ind(station_names.eq.location_name)

   location_lat    = station_select(ind_station,0)
   location_lon    = station_select(ind_station,1)
   location        = station_name_comp(ind_station)

  print(location +" Lat: " +location_lat+", Lon: " + location_lon)

   topboundary     = location_lat+delta_deg
   bottomboundary  = location_lat-delta_deg
   rightboundary   = location_lon+delta_deg
   leftboundary    = location_lon-delta_deg

; begin year loop
do y = ystart,yend ; loop through years
  year = y

  if (netCDF) then
     outname      = outdir+location+"_"+delta_deg+"deg_"+version+ret+"_"+\
                    year+".nc"
  end if

  ; counter for number of measurements
  dcount = 0


;--------------------------------------------
; load file and extract
;--------------------------------------------
  print("==================================")
  print("Collecting: "+ year)
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
   all_files := systemfunc ("ls "+infolder+year+"*/*/MOP02"+ret+"-*.he5")

   print("from:" + all_files(0))
   print("to..."+ all_files(dimsizes(all_files)-1))
  ; number of files to be read in year
   ndates := dimsizes(all_files)
   print("#files = " + ndates)

  ;------------
  ; loop over
  ; files
  ;------------
  do i=0,ndates-1
      fin = addfile(all_files(i), "r")            ; read in
      sza          := fin->$solarza$
      lon          := fin->$longitude$
      lat          := fin->$latitude$
      time         := fin->$date$
        ;units value presumes use of TAI93 (International Atomic Time) format
        time@units = "seconds since 1993-1-1 00:00:00"

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
            " for file " + i +", date: "+cd_calendar(time(0),4))
      continue  ; skip all the next bit and go to next file
    end if

    if (dimsizes(region).eq.1) then
      print("Only one MOPITT pixel at " + location +\
            " for file " + i +", date: "+cd_calendar(time(0),4)+\
            "...skipping")
      continue  ; skip all the next bit and go to next file
    end if

    tempcount = dcount
    dcount := tempcount+1

    ;--------------------------------------------
    ; extract all other variables over region
    ;--------------------------------------------
    print("***Collecting MOPITT data at " + location +\
          " for file "+i+", date: "+cd_calendar(time(i),4))

      region_time  := time(region)                 ; time in seconds since 1993-1-1 00:00:00 (TAI93)
      region_lat   := lat(region)
      region_lon   := lon(region)
      tgas         := fin->$tracer$(region,:)
        region_tcol:= tgas(:,0)
        region_err := tgas(:,1)
      region_pix   := fin->$swath_index$(region,0)
      region_stype := fin->$surface_index$(region)
      region_dofs  := fin->$deg_freedom$(region)
      region_ap    := fin->$tcol_apriori$(region)
      region_psurf := fin->$pressure_surf$(region)

      vmr_dummy    := fin->$vmr_aprior$(region,:,0)
      vmr_surf     := fin->$vmr_surface$(region,0)
      region_v_ap  := new((/dimsizes(region),10/),float,-9999)
         region_v_ap(:,0)    = (/vmr_surf(:)/)
         region_v_ap(:,1:9)  = vmr_dummy(:,:)
      ret_dummy    := fin->$vmr_aposterior$(region,:,0)
      ret_surf     := fin->$apost_surf$(region,0)
      region_profile := new((/dimsizes(region),10/),float,-9999)
         region_profile (:,0)    = (/ret_surf(:)/)
         region_profile (:,1:9)  = ret_dummy(:,:)
      ret_err_dummy    := fin->$vmr_aposterior$(region,:,1)
      ret_err_surf     := fin->$apost_surf$(region,1)
      region_profile_err := new((/dimsizes(region),10/),float,-9999)
         region_profile_err (:,0)    = (/ret_err_surf(:)/)
         region_profile_err (:,1:9)  = ret_err_dummy(:,:)
      if (version.eq."V7".or.version.eq."V8") then
        region_anom_diag    := fin->$diag_1$(region,:)
        region_col_diag     := fin->$diag_2$(region,:)
        region_ak_col       := fin->$col_avker$(region,:)
        region_ak_col_nd    := fin->$col_avker_nodim$(region,:)
        region_dry_air_col  := fin->$dry_air_col$(region)
      end if  

      region_ak           := fin->$vmr_avker$(region,:,:)

      ;--------------------------------------------
      ; append to arrays
      ;--------------------------------------------
    if (any(.not.ismissing(region_tcol))) then
      ;--------------------------------------------
      ; Collect MOPITT data into timeseries
      ;--------------------------------------------
      do k=0,dimsizes(region_tcol)-1
        if (.not.ismissing(region_tcol(k))) then

          if (dimsizes(region_ap).eq.1) then
            ;accounting for loss of 1st dim if only 1 pixel around station
            a=region_v_ap(:)
            b=region_profile(:)
            b_1=region_profile_err(:)
            c=region_ak(:,:)
          else
            a=region_v_ap(k,:)
            b=region_profile(k,:)
            b_1=region_profile_err(k,:)
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
          ;--- a posteriori error (vmr profile error)
            m_profile_err_selected = new((/1,10/),float)
            m_profile_err_selected(0,:) = b_1
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
            temp11a := m_profile_err_selected
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
          ;--- a posteriori error (vmr profile error)
            dummy2a := new((/1,10/),float)
            dummy2a(0,:) = b_1
            m_profile_err_selected := array_append_record(temp11a,dummy2a,0)
          ;--- averaging kernel
            dummy3 := new((/1,10,10/),float)
            dummy3(0,:,:) = c
            m_ak_selected := array_append_record(temp12,dummy3,0)
          end if 

            if (version.eq."V7".or.version.eq."V8") then
              if (dimsizes(region_ap).eq.1) then
              ;accounting for loss of 1st dim if only 1 pixel around station
                d=region_anom_diag(:) 
                e=region_col_diag(:)
                f=region_ak_col(:)
                g=region_ak_col_nd(:)
              else
                d=region_anom_diag(k,:) 
                e=region_col_diag(k,:)
                f=region_ak_col(k,:)
                g=region_ak_col_nd(k,:)
              end if

              if (.not.(isdefined("anom_diag_selected"))) then
                ;--- diagnostics for anomalies
                anom_diag_selected = new((/1,dimsizes(region_anom_diag(0,:))/),float)
                anom_diag_selected(0,:) = d
                ;--- diagnostics for column values
                col_diag_selected = new((/1,dimsizes(region_col_diag(0,:))/),float)
                col_diag_selected(0,:) = e
                ;--- column averaging kernel
                ak_col_selected = new((/1,10/),float)
                ak_col_selected(0,:) = f
                ;--- dimensionless column averaging kernel
                ak_col_nd_selected = new((/1,10/),float)
                ak_col_nd_selected(0,:) = g
                ;--- dry air column
                dry_air_selected = region_dry_air_col(k)

              else
                temp13 := anom_diag_selected
                temp14 := col_diag_selected
                temp15 := ak_col_selected
                temp16 := ak_col_nd_selected
                temp17 := dry_air_selected 

              ;--- retrieval anomalies
                dummy4 := new((/1,dimsizes(region_anom_diag(0,:))/),float)
                dummy4(0,:) = d
                anom_diag_selected := array_append_record(temp13,dummy4,0)
              ;--- column errors
                dummy5 := new((/1,dimsizes(region_col_diag(0,:))/),float)
                dummy5(0,:) = e
                col_diag_selected := array_append_record(temp14,dummy5,0)
              ;--- column ak
                dummy6 := new((/1,10/),float)
                dummy6(0,:) = f
                ak_col_selected := array_append_record(temp15,dummy6,0)
              ;--- column ak dimless
                dummy7 := new((/1,10/),float)
                dummy7(0,:) = g
                ak_col_nd_selected := array_append_record(temp16,dummy7,0)
              ;--- latitude
                dry_air_selected := array_append_record(temp17,region_dry_air_col(k),0)

              end if
            end if 

     
        end if
      end do
    end if ; collect if not missing in region_tcol

  end do
  ;printVarSummary(mopitt_selected)
  ;printVarSummary(time_selected)
  ;printVarSummary(m_ak_selected)

  records = num(mopitt_selected)
  print("******************************")
  print(version+ret)
  print("Number of files checked = " + ndates)
  print("Number of files with " +location+" info = " + dcount)
  print("Number of pixels = " + records)


;--------------------------------------------
; Write out to a netCDF file
;--------------------------------------------
if (netCDF) then
  ; saves MOPITT subset
  print("Writing out to file..."+ outname)
  fout = addfile(outname, "c")
  ;------------
  ; File 
  ; Attributes
  ;------------
  setfileoption(fout, "DefineMode",True)
    fAtt                      = True
      fAtt@title              = "Subset of MOPITT CO at " + delta_deg + \
                                " degrees radius around " +location_name+ " station"
      fAtt@source             = "MOPITT level 2, " + version+ret
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
   m_profile_err_selected!0       = "time"
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
   ;--- a posteriori error (vmr profile error)
     fout->RetrievedCOMixingRatioProfileError = m_profile_err_selected
   ;--- averaging kernel
     fout->RetrievalAvKerMatrix          = m_ak_selected

   if (version.eq."V7".or.version.eq."V8") then
     anom_diag_selected!0        = "time"
     col_diag_selected!0         = "time"
     ak_col_selected!0           = "time"
     ak_col_nd_selected!0        = "time"
     dry_air_selected!0        = "time"

     ;--- diagnostic 1
       fout->RetrievalAnomalyDiagnostic         = anom_diag_selected
     ;--- diagnostic 2
       fout->RetrievedCOTotalColumnDiagnostics  = col_diag_selected
     ;--- column averaging kernel
       fout->TotalColumnAveragingKernel         = ak_col_selected
     ;--- column averaging kernel (dimensionless)
       fout->TotalColumnAveragingKernelDimless  = ak_col_nd_selected
     ;--- dry air column
       fout->DryAirColumn                       = dry_air_selected
   end if

   print("Created file: "+outname)

end if ;NETCDF
end do ; year loop

end

