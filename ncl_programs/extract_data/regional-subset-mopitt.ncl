;=======================================================;
;  regional-subset-mopitt.ncl
;=======================================================;
;
; Concepts illustrated:
;   - For use with MOPITT CO version 6, level 2 product
;   - Loading CO data from MOPITT .he5 file
;          - select daytime retrievals
;          - select for spatial region
;          - select land or ocean only pixels
;   - Write data out to netCDF
;
;   Files needed:
;         -MOPITT level 2, daily hdf files
;
;   To run type:
;         ncl regional-subset-mopitt.ncl 
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
  version = "V7T"
  year = 2016
  ; V6 T and N work all files, V7 all versions work
  all_files = systemfunc ("ls /MOPITT/"+version+"/Archive/L2/"+year+"*/*/MOP02T-"+year+"*.he5")
  ; remove 200003/0303 for V6J - nTime is defined too large for NCL (unlimited)
  ;dummy = systemfunc ("ls /MOPITT/"+version+"/Archive/L2/"+year+"*/*/MOP02J-"+year+"*.he5")
  ;all_files = dummy(344:346)


  ;------------
  ; select location
  ;------------
  outfolder = "~/MOPITT_subset/SH_regions_v7/"
  location = "CentralSAmerica"
;SAmerica,Indonesia

  ;------------
  ; select daytime 
  ; retrievals
  ;------------
  ; For SZA < 80
  dayflag = 80

  ;------------
  ; select surface type 
  ;------------
  surface = "land"

  ;------------
  ; toggles
  ;------------
  netCDF         = True

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
  tracer         = "RetrievedCOTotalColumn"+suff
  longitude      = "Longitude"+suff
  latitude       = "Latitude"+suff
  solarza        = "SolarZenithAngle"+suff
  date           = "Time"+suff
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
  diag           = "RetrievedCOTotalColumnDiagnostics"+suff


  if (location.eq."SAfrica") then
   topboundary     = 4.
   bottomboundary  = -36.
   rightboundary   = 59.
   leftboundary    = -18.
  else if (location.eq."NorthSAfrica") then
   topboundary     = 4.
   bottomboundary  = -10.
   rightboundary   = 59.
   leftboundary    = -18.
  else if (location.eq."CentralSAfrica") then
   topboundary     = -10.
   bottomboundary  = -25.
   rightboundary   = 59.
   leftboundary    = -18.
  else if (location.eq."SouthSAfrica") then
   topboundary     = -25.
   bottomboundary  = -36.
   rightboundary   = 59.
   leftboundary    = -18.
  else if (location.eq."Australasia") then
   topboundary     = -10.
   bottomboundary  = -48.
   rightboundary   = 181.
   leftboundary    = 112.
  else if (location.eq."NorthAustralasia") then
   topboundary     = -10.
   bottomboundary  = -25.
   rightboundary   = 181.
   leftboundary    = 112.
  else if (location.eq."SouthAustralasia") then
   topboundary     = -25.
   bottomboundary  = -48.
   rightboundary   = 181.
   leftboundary    = 112.
  else if (location.eq."EastAustralasia") then
   topboundary     = -10.
   bottomboundary  = -48.
   rightboundary   = 181.
   leftboundary    = 140.
  else if (location.eq."WestAustralasia") then
   topboundary     = -10.
   bottomboundary  = -48.
   rightboundary   = 140.
   leftboundary    = 112.
  else if (location.eq."SAmerica") then
   topboundary     = 5.
   bottomboundary  = -58.
   rightboundary   = -32.
   leftboundary    = -83.
  else if (location.eq."NorthSAmerica") then
   topboundary     = 10.
   bottomboundary  = -5.
   rightboundary   = -32.
   leftboundary    = -83.
  else if (location.eq."CentralSAmerica") then
   topboundary     = -5.
   bottomboundary  = -25.
   rightboundary   = -32.
   leftboundary    = -83.
  else if (location.eq."ECentralSAmerica") then
   topboundary     = -5.
   bottomboundary  = -25.
   rightboundary   = -32.
   leftboundary    = -60.
  else if (location.eq."WCentralSAmerica") then
   topboundary     = -5.
   bottomboundary  = -25.
   rightboundary   = -60.
   leftboundary    = -83.
  else if (location.eq."SouthSAmerica") then
   topboundary     = -25.
   bottomboundary  = -58.
   rightboundary   = -32.
   leftboundary    = -83.
  else if (location.eq."WestSAmerica") then
   topboundary     = 5.
   bottomboundary  = -58.
   rightboundary   = -60.
   leftboundary    = -83.
  else if (location.eq."EastSAmerica") then
   topboundary     = 5.
   bottomboundary  = -58.
   rightboundary   = -32.
   leftboundary    = -60.
  else if (location.eq."Indonesia") then
   topboundary     = 10.
   bottomboundary  = -10.
   rightboundary   = 165.
   leftboundary    = 91.
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
     outname      = outfolder+location+"_"+version+"subset_"+year+".nc"
  end if

  ; number of files to be read
  ndates = dimsizes(all_files)
  
  ; counter for setting up selected arrays
  counter= 0
  dcount = 0

  ; -------------------------------
  ; SELECTION SETUP
  ; -------------------------------
  if (surface.eq."land") then           ; land left
     s_id = 1
  else if (surface.eq."ocean") then       ; ocean left
     s_id = 0
  end if
  end if

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
    ; read data
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
      two_diag     := fin->$diag$

    ;--------------------------------------------
    ; select region to bin (daytime retrievals)
    ;--------------------------------------------
    region := ind(sza.le.dayflag.and.\
                 surf_type.eq.s_id.and.\
                 lat.le.topboundary.and.\
                 lat.ge.bottomboundary.and.\
                 lon.ge.leftboundary.and.\
                 lon.le.rightboundary)
    if (all(ismissing(region))) then
      print("No MOPITT data at " + location +\
            " for file " + i +", date: "+cd_calendar(time(i),4))
      ;------------
      ; release
      ; variables
      ;------------
      continue  ; skip all the next bit and go to next file
    end if
    
    tempcount = dcount
    dcount := tempcount+1

    print("***Collecting MOPITT data at " + location +\
          " for file "+i+", date: "+cd_calendar(time(i),2))
    region_tcol    := dim_avg_n_Wrap(tcol(region),0)
    region_lat     := dim_avg_n_Wrap(lat(region),0)
    region_lon     := dim_avg_n_Wrap(lon(region),0)
    region_time    := dim_avg_n_Wrap(time(region),0)     ; time in seconds since 1993-1-1 00:00:00 (TAI93)
    region_err     := dim_avg_n_Wrap(tcol_err(region),0)
    region_rel_err := tcol_err(region)/tcol(region)
    region_wgt     := 1/(region_rel_err^2)
    region_dofs    := dim_avg_n_Wrap(dofs(region),0)
    region_ap      := dim_avg_n_Wrap(apriori(region),0)
    region_psurf   := dim_avg_n_Wrap(psurf(region),0)
    region_max_smooth_e := max(abs(two_diag(region,0)))
    region_max_rand_e := max(abs(two_diag(region,1)))

    ak_dims := dimsizes(ak(region, :, :))
    if (dimsizes(ak_dims).eq.2) then
      region_ak      := ak(region, :, :)                ;account for loss of time dimension if 1 point
      region_v_ap    := vmr_apriori(region, :)
      region_profile := ret_profile(region, :)
    else
      region_ak      := dim_avg_n_Wrap(ak(region, :, :),0)
      region_v_ap    := dim_avg_n_Wrap(vmr_apriori(region, :),0)
      region_profile := dim_avg_n_Wrap(ret_profile(region, :),0)  
    end if


    if (any(.not.ismissing(region_tcol))) then
      ;--------------------------------------------
      ; Collect MOPITT data and append to arrays
      ;--------------------------------------------
          if (.not.(isdefined("time_selected"))) then
          ;--- time
            time_selected = region_time
          ;--- total column
            mopitt_selected  = region_tcol
          ;--- latitude
            lat_selected = region_lat
          ;--- longitude
            lon_selected = region_lon
          ;--- errors
            err_selected = region_err
          ;--- num_avg
            num_selected = num(tcol(region))
          ;--- smooth_err
            smooth_e_selected = region_max_smooth_e
          ;--- rand_err
            rand_e_selected = region_max_rand_e
          ;--- surface pressure
            psurf_selected = region_psurf
          ;--- dofs
            dofs_selected = region_dofs
          ;--- a priori (column)
            ap_selected = region_ap
          ;--- a priori (vmr profile)
            m_apriori_selected = new((/1,10/),float)
            m_apriori_selected(0,:) = region_v_ap(:)
          ;--- a posteriori (vmr profile)
            m_profile_selected = new((/1,10/),float)
            m_profile_selected(0,:) = region_profile(:)
          ;--- zveraging kernel
            m_ak_selected = new((/1,10,10/),float)
            m_ak_selected(0,:,:) = region_ak(:,:)
            ;print(counter)


          else
            temp0 := time_selected
            temp1 := mopitt_selected
            temp2 := lat_selected
            temp3 := lon_selected
            temp4 := err_selected
            temp4I := num_selected
            temp4II := smooth_e_selected
            temp4III := rand_e_selected
            temp5 := psurf_selected
            temp8 := dofs_selected
            temp9 := ap_selected
            temp10 := m_apriori_selected
            temp11 := m_profile_selected
            temp12 := m_ak_selected

          ;--- time 
            time_selected := array_append_record(temp0,region_time,0)
          ;--- total column
            mopitt_selected := array_append_record(temp1,region_tcol,0)
          ;--- latitude
            lat_selected := array_append_record(temp2,region_lat,0)
          ;--- longitude
            lon_selected := array_append_record(temp3,region_lon,0)
          ;--- errors
            err_selected := array_append_record(temp4,region_err,0)
            num_selected := array_append_record(temp4I,num(tcol(region)),0)
            smooth_e_selected := array_append_record(temp4II,region_max_smooth_e,0)
            rand_e_selected := array_append_record(temp4III,region_max_rand_e,0)
          ;--- surface pressure
            psurf_selected := array_append_record(temp5,region_psurf,0)
          ;--- dofs
            dofs_selected := array_append_record(temp8,region_dofs,0)
          ;--- a priori (column)
            ap_selected := array_append_record(temp9,region_ap,0)
          ;--- a priori (vmr profile)
            dummy := new((/1,10/),float)
            dummy(0,:) = region_v_ap(:)
            m_apriori_selected := array_append_record(temp10,dummy,0)
          ;--- a posteriori (vmr profile)
            dummy2 := new((/1,10/),float)
            dummy2(0,:) = region_profile(:)
            m_profile_selected := array_append_record(temp11,dummy2,0)
          ;--- averaging kernel
            dummy3 := new((/1,10,10/),float)
            dummy3(0,:,:) = region_ak(:,:)
            m_ak_selected := array_append_record(temp12,dummy3,0)
          end if

    end if ; collect if not missing in region_tcol
  end do

  printVarSummary(mopitt_selected)
  printVarSummary(time_selected)
  ;print(mopitt_selected)
  ;print(time_selected)
  printVarSummary(m_ak_selected)

  records = num(mopitt_selected)
  print("******************************")
  print(version)
  print("Number of files checked = " + ndates)
  print("Number of files with " +location+" info = " + dcount)
  print("Number of written days = " + records)


;--------------------------------------------
; Write out to a netCDF file
;--------------------------------------------
if (netCDF) then
  ; saves MOPITT subset
    print("Creating file...")
    fout = addfile(outname, "c")
    ;------------
    ; File 
    ; Attributes
    ;------------
    setfileoption(fout, "DefineMode",True)
    fAtt                      = True
      fAtt@title              = "Subset of average MOPITT CO for " +location+"_"+year
      fAtt@source             = "MOPITT level 2, version 7, TIR-NIR retrievals"
      fAtt@creation_date      = systemfunc ("date")
      fAtt@conventrions       = "CF"

     fileattdef(fout, fAtt)
     setfileoption(fout, "DefineMode",False)


  ;------------
  ; Variables
  ;------------

   mopitt_selected!0              = "time"
   mopitt_selected@average_op_ncl = "daily spatial average over "+location+": "+\
                                    topboundary+" to "+bottomboundary+ " Lat, "+\
                                    leftboundary+" to "+rightboundary+" Lon"

   err_selected@long_name         = "RetrievedCOTotalColumnError"
   err_selected@average_op_ncl    = mopitt_selected@average_op_ncl
   err_selected!0                 = "time"

   lat_selected!0                 = "time"
   lat_selected@average_op_ncl    = mopitt_selected@average_op_ncl
   lon_selected!0                 = "time"
   lon_selected@average_op_ncl    = mopitt_selected@average_op_ncl
   time_selected!0                = "time"
   time_selected@average_op_ncl   = mopitt_selected@average_op_ncl
   psurf_selected!0               = "time"
   psurf_selected@average_op_ncl  = mopitt_selected@average_op_ncl
   dofs_selected!0                = "time"
   dofs_selected@average_op_ncl   = mopitt_selected@average_op_ncl
   ap_selected!0                  = "time"
   ap_selected@average_op_ncl     = mopitt_selected@average_op_ncl
   num_selected!0                 = "time"
   num_selected@average_op_ncl    = mopitt_selected@average_op_ncl
   smooth_e_selected!0            = "time"
   smooth_e_selected@average_op_ncl = mopitt_selected@average_op_ncl
   rand_e_selected!0              = "time"
   rand_e_selected@average_op_ncl = mopitt_selected@average_op_ncl

   m_apriori_selected!0           = "time"
   m_apriori_selected@average_op_ncl = mopitt_selected@average_op_ncl
   m_profile_selected!0           = "time"
   m_profile_selected@average_op_ncl = mopitt_selected@average_op_ncl
   m_ak_selected!0                = "time"
   m_ak_selected@average_op_ncl   = mopitt_selected@average_op_ncl

   ;--- total column
     fout->RetrievedCOTotalColumn        = mopitt_selected
   ;--- total column error
     fout->RetrievedCOTotalColumnError   = err_selected
   ;--- Number of values in day averages
     fout->NumberInAvg                   = num_selected
   ;--- Maximum regional day smoothing error
     fout->RetrievedCOColSmoothMax       = smooth_e_selected
   ;--- Maximum regional day measurement error
     fout->RetrievedCOColRandMax         = rand_e_selected
   ;--- latitude
     fout->Latitude                      = lat_selected
   ;--- longitude
     fout->Longitude                     = lon_selected
   ;--- time
     fout->Time                          = time_selected
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

