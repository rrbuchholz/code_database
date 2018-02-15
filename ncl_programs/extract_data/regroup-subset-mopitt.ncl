;=======================================================;
;  regroup-subset-mopitt.ncl
;=======================================================;
;
; Concepts illustrated:
;   - For use with MOPITT CO version 6 or 7, subsetted data
;   - Loading CO data from subsetted data
;          - option to select for pixel type
;          - option to select for surface type
;   - Compute error weighted average
;   - Write data out to netCDF
;
;   Files needed:
;         -MOPITT subset of level 2, daily hdf files
;
;   To run type:
;         regroup-subset-mopitt.ncl 
;                                  RRB November 17, 2014
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
  end_year = 2017
  location_name = "Lauder"

  ;------------
  ; distance around 
  ; station
  ;------------
  delta_deg   = 1

  ;------------
  ; toggles
  ;------------
  PLOT           = True
    plttype      = "x11"

  netCDF         = True
    f1suffix     = "all_land"

  PIXEL_SELECT   = False
    pixelnum     = 4
    PMASK        = False      ; PMASK = True to mask pixel number, i.e. leave everything else
                              ; False to select pixel number
  SURFACE_MASK = True
    smask        = "ocean"   ; select land, ocean, oceanland or mixed to mask
                             ; i.e the opposite of what you select will be left
  
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
  tracer         = "RetrievedCOTotalColumn"
  error          = "RetrievedCOTotalColumnError"
  longitude      = "Longitude"
  latitude       = "Latitude"
  sat_date       = "Time"
  pressure_surf  = "SurfacePressure"
  deg_freedom    = "DegreesofFreedomforSignal"
  tcol_apriori   = "APrioriCOTotalColumn"
  vmr_aprior     = "APrioriCOMixingRatioProfile"
  vmr_aposterior = "RetrievedCOMixingRatioProfile"
  err_vmr        = "TBA"
  vmr_avker      = "RetrievalAvKerMatrix"
  col_avker      = "TotalColumnAveragingKernel"
  diag_1         = "RetrievedCOTotalColumnDiagnostics"
  dryair         = "DryAirColumn"


  ; used for selecting, but not written out:
  swath_index    = "SwathIndex"
  surface_index  = "SurfaceIndex"
  diag_2         = "RetrievalAnomalyDiagnostic"

  ; -------------------------------
  ; STATION PARAMETERS
  ; -------------------------------
    location = location_name

  if (location_name.eq."Arrival Heights") then
    location = "ArrivalHeights"
    time_diff    = 12               ; from UTC
  else if (location_name.eq."Ascension") then
    time_diff    = 0               ; from UTC
    location_lat = -7.91
    location_lon = -14.33
  else if (location_name.eq."Boulder") then
  else if (location_name.eq."Bremen") then
    time_diff    = 1                ; from UTC
  else if (location_name.eq."Darwin") then ; TCCON
    time_diff    = 9.5              ; from UTC
    location_lat = -12.424
    location_lon = 130.892
  else if (location_name.eq."Eureka") then
    time_diff    = -6               ; from UTC 
  else if (location_name.eq."Izana") then
    time_diff    = 0                ; from UTC 
  else if (location_name.eq."Jungfraujoch") then
    location = "Jungfrau"
    time_diff    = 1                ; from UTC 
  else if (location_name.eq."Kiruna") then
    time_diff    = 1                ; from UTC
  else if (location_name.eq."Lauder") then
    time_diff    = 12               ; from UTC
    location_lat = -45.038
    location_lon = 169.684
  else if (location_name.eq."La Reunion") then
    location = "Reunion"
    time_diff    = 4                ; from UTC
    location_lat = -20.901
    location_lon = 55.485
  else if (location_name.eq."Mauna Loa") then
    location = "MaunaLoa"
    time_diff    = -10              ; from UTC
  else if (location_name.eq."Ny Alesund") then
    location = "NyAlesund"
    time_diff    = 1                ; from UTC
  else if (location_name.eq."Paris") then
  else if (location_name.eq."Rikubetsu") then
  else if (location_name.eq."St Petersburg") then
    location = "StPete"
  else if (location_name.eq."Thule") then
    time_diff    = -4               ; from UTC
  else if (location_name.eq."Toronto") then
    time_diff    = -5               ; from UTC
  else if (location_name.eq."Wollongong") then
    time_diff    = 10               ; from UTC
    location_lat = -34.406
    location_lon = 150.879
  else if (location_name.eq."Zugspitze") then
    time_diff    = 1                ; from UTC
  else
    print("Valid location not defined... exiting")
    exit
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
  end if

  ; -------------------------------
  ; INPUT RELATED SETUP
  ; -------------------------------
  mopitt_file = "/IASI/home/buchholz/MOPITT_subset/V7/stations/"+location+"_1deg_V7J_20010101-20170101.nc"

  ; -------------------------------
  ; OUTPUT RELATED SETUP
  ; -------------------------------
  if (PLOT) then
    pltdir       = "./"
    pltname      = "mopitt_l2_vs_fts_" + location
  end if

  if (netCDF) then
     outname      = "/IASI/home/buchholz/MOPITT_subset/V7/stations/"+location+"_"+delta_deg+"deg_"+version+"MOPITTavg_"+f1suffix+".nc"
  end if


  ; -------------------------------
  ; SELECTION SETUP
  ; -------------------------------
  if (SURFACE_MASK) then
    if (smask.eq."ocean") then           ; land left
       s_id = 0
       s_id2 = 2
    else if (smask.eq."land") then       ; ocean left
       s_id = 1
       s_id2 = 2
    else if (smask.eq."mixed") then      ; land and ocean left
       s_id = 2
       s_id2 = 2
    else if (smask.eq."oceanland") then  ; mixed pixels left
       s_id = 0
       s_id2 = 1
    end if
    end if
    end if
    end if
  end if

  time_diff_sec = time_diff*60*60
  
  ; counters for setting up selected arrays
  counter= 0
  avgcounter=0

;--------------------------------------------
; load file and extract
;--------------------------------------------
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  ; read data from region
  fin = addfile(mopitt_file, "r")            ; read in

    region_time_dummy    = fin->$sat_date$        ; time in seconds since 1993-1-1 00:00:00 (TAI93)
      region_yfrac = cd_calendar(region_time_dummy,4)
      time_cut = ind(region_yfrac.lt.2011)
      ;index_stop = time_cut(dimsizes(time_cut)-1)
      index_stop = (dimsizes(region_time_dummy)-1)

    print("***Reading MOPITT data at " + location)
    region_tcol    = fin->$tracer$(0:index_stop)
      ;region_tcol@_FillValue = -999.99
      ;test = ind(region_tcol.eq.0)
      ;region_tcol(test)=region_tcol@_FillValue
    region_err     = fin->$error$(0:index_stop)
    region_rel_err = region_err/region_tcol
    region_wgt     = 1/(region_rel_err^2)
    region_lat     = fin->$latitude$(0:index_stop)
    region_lon     = fin->$longitude$(0:index_stop)
    region_time    = fin->$sat_date$(0:index_stop)      ; time in seconds since 1993-1-1 00:00:00 (TAI93)
    region_time    = region_time+time_diff_sec          ; change to local time
    region_pix     = fin->$swath_index$(0:index_stop)
    region_stype   = fin->$surface_index$(0:index_stop)
    region_psurf   = fin->$pressure_surf$(0:index_stop)
    region_dofs    = fin->$deg_freedom$(0:index_stop)
    region_ap      = fin->$tcol_apriori$(0:index_stop)
    region_v_ap    = fin->$vmr_aprior$(0:index_stop,:)
    region_profile = fin->$vmr_aposterior$(0:index_stop,:)
    region_ak      = fin->$vmr_avker$(0:index_stop,:,:)
    region_col_ak  = fin->$col_avker$(0:index_stop,:)
    region_diag_col= fin->$diag_1$(0:index_stop,:)
    region_diag_anom = fin->$diag_2$(0:index_stop,:)
    region_dryair  = fin->$dryair$(0:index_stop)


    ;--------------------------------------------
    ; screen to mask anomalous data
    ;--------------------------------------------
    anomaly_ind := ind(region_diag_anom(:,0).eq.1.or.\
                       region_diag_anom(:,1).eq.1.or.\
                       region_diag_anom(:,2).eq.1.or.\
                       region_diag_anom(:,3).eq.1.or.\
                       region_diag_anom(:,4).eq.1)

      if (any(.not.ismissing(anomaly_ind))) then
        region_tcol(anomaly_ind)   = region_tcol@_FillValue
        region_time(anomaly_ind)   = region_time@_FillValue
        region_err(anomaly_ind)    = region_err@_FillValue
        region_wgt(anomaly_ind)    = region_wgt@_FillValue
        region_dofs(anomaly_ind)   = region_dofs@_FillValue
        region_ap(anomaly_ind)     = region_ap@_FillValue
        region_psurf(anomaly_ind)  = region_psurf@_FillValue
        region_dryair(anomaly_ind) = region_dryair@_FillValue
        if (dimsizes(region_ap).eq.1) then
          region_v_ap    = region_v_ap@_FillValue
          region_profile = region_profile@_FillValue
          region_ak(:,:) = region_ak@_FillValue
        else
          region_v_ap(anomaly_ind,:)    = region_v_ap@_FillValue
          region_profile(anomaly_ind,:) = region_profile@_FillValue
          region_ak(anomaly_ind,:,:)    = region_ak@_FillValue
          region_col_ak(anomaly_ind,:)  = region_col_ak@_FillValue
          region_diag_col(anomaly_ind,:)= region_diag_col@_FillValue
        end if
      end if


    ;--------------------------------------------
    ; select for pixels
    ;--------------------------------------------
    if (PIXEL_SELECT) then
      if (PMASK) then
        ; mask chosen pixel
        print("masking pixel:"+pixelnum)
        pix_ind = ind(region_pix.eq.pixelnum)
      else
        ; select chosen pixel (mask everything else)
        print("selecting pixel:"+pixelnum)
        pix_ind = ind(region_pix.ne.pixelnum)
      end if
      if (any(.not.ismissing(pix_ind))) then
        region_tcol(pix_ind)   = region_tcol@_FillValue
        region_time(pix_ind)   = region_time@_FillValue
        region_err(pix_ind)    = region_err@_FillValue
        region_wgt(pix_ind)    = region_wgt@_FillValue
        region_dofs(pix_ind)   = region_dofs@_FillValue
        region_ap(pix_ind)     = region_ap@_FillValue
        region_psurf(pix_ind)  = region_psurf@_FillValue
        region_dryair(pix_ind) = region_dryair@_FillValue
        if (dimsizes(region_ap).eq.1) then
          region_v_ap    = region_v_ap@_FillValue
          region_profile = region_profile@_FillValue
          region_ak(:,:) = region_ak@_FillValue
        else
          region_v_ap(pix_ind,:)    = region_v_ap@_FillValue
          region_profile(pix_ind,:) = region_profile@_FillValue
          region_ak(pix_ind,:,:)    = region_ak@_FillValue
          region_col_ak(pix_ind,:)  = region_col_ak@_FillValue
          region_diag_col(pix_ind,:)= region_diag_col@_FillValue
        end if
      end if
    end if

  ;--------------------------------------------
  ; select for surface type
  ;--------------------------------------------
  if (SURFACE_MASK) then
    print("masking "+smask)\
      ; replace missing values for mixed only 
      ; or mixed and choice of ocean or land 
      surf_ind = ind(region_stype.eq.s_id.or.region_stype.eq.s_id2)
    if (any(.not.ismissing(surf_ind))) then
        region_tcol(surf_ind)   = region_tcol@_FillValue
        region_time(surf_ind)   = region_time@_FillValue
        region_err(surf_ind)    = region_err@_FillValue
        region_wgt(surf_ind)    = region_wgt@_FillValue
        region_dofs(surf_ind)   = region_dofs@_FillValue
        region_ap(surf_ind)     = region_ap@_FillValue
        region_psurf(surf_ind)  = region_psurf@_FillValue
        region_dryair(surf_ind) = region_dryair@_FillValue
      if (dimsizes(region_ap).eq.1) then
          region_v_ap    = region_v_ap@_FillValue
          region_profile = region_profile@_FillValue
          region_ak(:,:) = region_ak@_FillValue
      else
          region_v_ap(surf_ind,:)    = region_v_ap@_FillValue
          region_profile(surf_ind,:) = region_profile@_FillValue
          region_ak(surf_ind,:,:) = region_ak@_FillValue
          region_col_ak(surf_ind,:)  = region_col_ak@_FillValue
          region_diag_col(surf_ind,:)= region_diag_col@_FillValue
      end if
    end if
  end if


  ;--------------------------------------------
  ; DO THE DAILY AVERAGING
  ;--------------------------------------------
  ;--------------------------------------------
  ; human readable dates
  ;--------------------------------------------
   date = cd_calendar(region_time,0)
   ind_there = ind(.not.ismissing(date(:,0)))
   mopitt_YYYYMMDD = cd_calendar(region_time,-2)
   YYYYMMDD = yyyymmdd_time(toint(date(ind_there(0),0)), end_year, "integer")

   do i=0,dimsizes(YYYYMMDD)-1
     dayind := ind(mopitt_YYYYMMDD.eq.YYYYMMDD(i))

     if (any(.not.ismissing(dayind))) then
       if (dimsizes(dayind).eq.1) then
         print("Only one relevant MOPITT pixel at " + location +\
            " for date " + mopitt_YYYYMMDD(dayind) +\
            "...skipping")
         continue  ; skip all the next bit and go to next file
       end if

       print("Calculating day average")
       ;--------------------------------------------
       ; calculations
       ;--------------------------------------------
       tcolwgtavg = sum(region_tcol(dayind)*region_wgt(dayind))/sum(region_wgt(dayind))
       err_avg  = sqrt((sum((region_err(dayind))^2))/dimsizes(dayind))
       dofs_wgtavg = sum(region_dofs(dayind)*region_wgt(dayind))/sum(region_wgt(dayind))
       ap_wgtavg = sum(region_ap(dayind)*region_wgt(dayind))/sum(region_wgt(dayind))
       psurf_wgtavg = sum(region_psurf(dayind)*region_wgt(dayind))/sum(region_wgt(dayind))
       dryair_wgtavg = sum(region_dryair(dayind)*region_wgt(dayind))/sum(region_wgt(dayind))

       ap_wgt := new(dimsizes(region_v_ap(dayind,:)), float)
       profile_wgt := new(dimsizes(region_profile(dayind,:)), float)
       col_ak_wgt := new(dimsizes(region_col_ak(dayind,:)), float)
       diag_col_wgt := new(dimsizes(region_diag_col(dayind,:)), float)
       ak_wgt := new(dimsizes(region_ak(dayind,:,:)), float)
       do j=0,dimsizes(dayind)-1
          ap_wgt(j,:) = region_v_ap(dayind(j),:)*region_wgt(dayind(j))
          profile_wgt(j,:) = region_profile(dayind(j),:)*region_wgt(dayind(j))
          col_ak_wgt(j,:) = region_col_ak(dayind(j),:)*region_wgt(dayind(j))
          diag_col_wgt(j,:) = region_diag_col(dayind(j),:)*region_wgt(dayind(j))
          ak_wgt(j,:,:) = region_ak(dayind(j),:,:)*region_wgt(dayind(j))
       end do
       ; 2-D
       ap_v_wgtavg = dim_sum_n_Wrap(ap_wgt,0)/sum(region_wgt(dayind))
       profile_wgtavg = dim_sum_n_Wrap(profile_wgt,0)/sum(region_wgt(dayind))
       col_ak_wgtavg = dim_sum_n_Wrap(col_ak_wgt,0)/sum(region_wgt(dayind))
       diag_col_wgtavg = dim_sum_n_Wrap(diag_col_wgt,0)/sum(region_wgt(dayind))
       ; 3-D
       ak_wgtavg = dim_sum_n_Wrap(ak_wgt,0)/sum(region_wgt(dayind))


       ;--------------------------------------------
       ; collect into arrays
       ;--------------------------------------------
       if (.not.(isdefined("num_ret"))) then
         num_ret         = dimsizes(dayind)
         loc_time_avg    = dim_avg_n_Wrap(region_time(dayind),0)
         loc_tcol_wgtavg = tcolwgtavg
         loc_tcol_err    = err_avg
         loc_dofs_wgtavg = dofs_wgtavg
         loc_ap_wgtavg   = ap_wgtavg
         loc_psurf_wgtavg = psurf_wgtavg
         loc_dryair_wgtavg = dryair_wgtavg

         loc_ap_v_wgtavg     = new((/1,10/),float)
         loc_ap_v_wgtavg(0,:) = ap_v_wgtavg
         loc_profile_wgtavg = new((/1,10/),float)
         loc_profile_wgtavg(0,:) = profile_wgtavg
         loc_ak_wgtavg = new((/1,10,10/),float)
         loc_ak_wgtavg(0,:,:) = ak_wgtavg
         loc_col_ak_wgtavg = new((/1,10/),float)
         loc_col_ak_wgtavg(0,:) = col_ak_wgtavg
         loc_diag_col_wgtavg = new((/1,2/),float)
         loc_diag_col_wgtavg(0,:) = diag_col_wgtavg

       else

         dummy  := num_ret
         dummy0 := loc_time_avg
         dummy1 := loc_tcol_wgtavg
         dummy2 := loc_tcol_err
         dummy3 := loc_dofs_wgtavg
         dummy4 := loc_ap_wgtavg
         dummy5 := loc_psurf_wgtavg
         dummy6 := loc_ap_v_wgtavg
         dummy7 := loc_profile_wgtavg
         dummy8 := loc_ak_wgtavg
         dummy9 := loc_col_ak_wgtavg
         dummy10:= loc_diag_col_wgtavg
         dummy11:= loc_dryair_wgtavg

         num_ret          :=  array_append_record(dummy, dimsizes(dayind),0)
         loc_time_avg     :=  array_append_record(dummy0,dim_avg_n_Wrap(region_time(dayind),0),0)
         loc_tcol_wgtavg  :=  array_append_record(dummy1,tcolwgtavg,0)
         loc_tcol_err     :=  array_append_record(dummy2,err_avg,0)
         loc_dofs_wgtavg  :=  array_append_record(dummy3,dofs_wgtavg,0)
         loc_ap_wgtavg    :=  array_append_record(dummy4,ap_wgtavg,0)
         loc_psurf_wgtavg :=  array_append_record(dummy5,psurf_wgtavg,0)

         dummy6a := new((/1,10/),float)
         dummy6a(0,:) = ap_v_wgtavg
         loc_ap_v_wgtavg    := array_append_record(dummy6,dummy6a,0)
         dummy7a := new((/1,10/),float)
         dummy7a(0,:) = profile_wgtavg
         loc_profile_wgtavg := array_append_record(dummy7,dummy7a,0)
         dummy8a := new((/1,10,10/),float)
         dummy8a(0,:,:) = ak_wgtavg
         loc_ak_wgtavg := array_append_record(dummy8,dummy8a,0)
         dummy9a := new((/1,10/),float)
         dummy9a(0,:) = col_ak_wgtavg
         loc_col_ak_wgtavg := array_append_record(dummy9,dummy9a,0)
         dummy10a := new((/1,2/),float)
         dummy10a(0,:) = diag_col_wgtavg
         loc_diag_col_wgtavg := array_append_record(dummy10,dummy10a,0)

         loc_dryair_wgtavg :=  array_append_record(dummy11,dryair_wgtavg,0)

       end if

    else
      print("No data, next timepoint")
    end if

   end do

print("Number of MOPITT pixels: "+sum(num_ret))
print("Number of days retrieved: "+dimsizes(num_ret))


;--------------------------------------------
; plot
;--------------------------------------------
if (PLOT) then

  wks = gsn_open_wks(plttype,pltname)        
  gsn_define_colormap(wks,"BlAqGrYeOrRe")  
   
  res                       = True                      ; plot mods desired
    res@xyMarkLineMode      = "Markers"
    res@xyMarker            = 17
    res@xyMarkerColor       = "red"
    res@xyMarkerSizeF       = 0.05
    res@gsnDraw		    = False	                ; don't draw it yet
    res@gsnFrame            = False                     ; don't advance frame

    res@vpWidthF             = 0.75
    res@vpHeightF            = 0.4

    res@trYMinF             = 5e17
    ;res@trYMaxF             = 2.5e18
    res@trXMinF             = 2000
    res@trXMaxF             = end_year

    res@tiMainString        = location_name + " MOPITT timeseries"
    res@tiXAxisString       = "date"
    res@tiYAxisString       = "Total column CO (molec. cm~S2~-2  )"
  
  plotting_t = cd_calendar(loc_time_avg,4)
  plot1 = gsn_csm_xy(wks,plotting_t,loc_tcol_wgtavg,res)

  draw(plot1)
  frame(wks)
end if


;--------------------------------------------
; Write out to a netCDF file
;--------------------------------------------
if (netCDF) then
  ; saves MOPITT averages
  fout = addfile(outname, "c")
  ;------------
  ; File 
  ; Attributes
  ;------------
  setfileoption(fout, "DefineMode",True)
    fAtt                      = True
      fAtt@title              = "Average of MOPITT CO at " + delta_deg + \
                                " degrees radius around " +location+ " station: "+\
                                "Lat = " +location_lat+", Lon = "+ location_lon
      fAtt@source             = "MOPITT level 2, version 6, thermal IR retrievals"
      fAtt@creation_date      = systemfunc ("date")
      fAtt@conventrions       = "CF"

     fileattdef(fout, fAtt)
  setfileoption(fout, "DefineMode",False)

  ;------------
  ; Variable 
  ; Attributes
  ;------------
  loc_tcol_wgtavg@long_name      = "RetrievedCOTotalColumn_WeightedAverage"
  loc_tcol_wgtavg@units          = "mol/cm^2"
  loc_tcol_wgtavg!0              = "time"

  loc_tcol_err@long_name         = "RetrievedCOTotalColumn_CombinedError"
  loc_tcol_err@units             = "mol/cm^2"
  loc_tcol_err!0                 = "time"

  loc_dofs_wgtavg@long_name      = "RetrievedCODegreesofFreedom_WeightedAverage"
  loc_dofs_wgtavg@units          = "NA"
  loc_dofs_wgtavg!0              = "time"

  loc_ap_wgtavg@long_name        = "Apriori_tcol_WeightedAverage"
  loc_ap_wgtavg@units            = "mol/cm^2"
  loc_ap_wgtavg!0                = "time"

  loc_ap_v_wgtavg@long_name      = "AprioriVMR_WeightedAverage"
  loc_ap_v_wgtavg@units          = "ppb"
  loc_ap_v_wgtavg!0              = "time"
  loc_ap_v_wgtavg!1              = "nPrs_MOP02"

  loc_profile_wgtavg@long_name   = "RetrievedCOMixingRatioProfile_WeightedAverage"
  loc_profile_wgtavg@units       = "ppb"
  loc_profile_wgtavg!0           = "time"
  loc_profile_wgtavg!1           = "nPrs_MOP02"

  loc_col_ak_wgtavg@long_name    = "TotalColumnAveragingKernel_WeightedAverage"
  loc_col_ak_wgtavg@units        = "mol/(cm^2 log(VMR))"
  loc_col_ak_wgtavg!0            = "time"
  loc_col_ak_wgtavg!1            = "nPrs_MOP02"

  loc_diag_col_wgtavg@long_name   = "RetrievedCOTotalColumnDiagnostics_WeightedAverage"
  loc_diag_col_wgtavg@units       = "NA"
  loc_diag_col_wgtavg!0           = "time"

  loc_ak_wgtavg@long_name        = "ProfileAveragingKernel_WeightedAverage"
  loc_ak_wgtavg@units            = "NA"
  loc_ak_wgtavg!0                = "time"
  loc_ak_wgtavg!1                = "nPrs_MOP02"
  loc_ak_wgtavg!2                = "nPrs_MOP02"

  loc_psurf_wgtavg@long_name     = "SurfacePressure_WeightedAverage"
  loc_psurf_wgtavg@units         = "hPa"
  loc_psurf_wgtavg!0             = "time"

  loc_time_avg@long_name         = "Time_BinnedAverage"
  loc_time_avg@units             = "seconds since 1993-1-1 00:00:00"
  loc_time_avg!0                 = "time"

  num_ret@long_name              = "NumberOfRetrievalsInBin"
  num_ret@units                  = "NA"
  num_ret!0                      = "time"

  loc_dryair_wgtavg@long_name    = "DryAirColumn"
  loc_dryair_wgtavg@units        = "mol/cm^2"
  loc_dryair_wgtavg!0            = "time"
  
  fout->RetrievedCOTotalColumn_WGT = loc_tcol_wgtavg
  fout->RetrievedCOTotalColumn_ERR = loc_tcol_err
  fout->DegreesofFreedomforSignal_WGT = loc_dofs_wgtavg
  fout->APrioriCOTotalColumn_WGT = loc_ap_wgtavg
  fout->APrioriCOMixingRatioProfile_WGT = loc_ap_v_wgtavg
  fout->RetrievedCOMixingRatioProfile_WGT = loc_profile_wgtavg
  fout->RetrievalAvKerMatrix_WGT = loc_ak_wgtavg
  fout->TotalColumnAveragingKernel_WGT = loc_col_ak_wgtavg
  fout->RetrievedCOTotalColumnDiagnostics_WGT = loc_diag_col_wgtavg
  fout->SurfacePressure_WGT = loc_psurf_wgtavg
  fout->Time_AVG  = loc_time_avg
  fout->NumberofRetrievals  = num_ret
  fout->DryAirColumn_WGT  = loc_dryair_wgtavg

  print("File created at: " + outname)

end if ;NETCDF

end

