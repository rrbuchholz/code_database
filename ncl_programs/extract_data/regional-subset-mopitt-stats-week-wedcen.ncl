;=======================================================;
;  regional-subset-mopitt-stats.ncl
;=======================================================;
;
; Concepts illustrated:
;   - For use with MOPITT CO version 6,7 and 8 level 2 products
;   - Loading CO data from MOPITT .he5 file
;          - select daytime retrievals
;          - select for spatial region
;          - select land or ocean only pixels
;          - determine, mean, median, 5th, 
;            25th, 75th, 95th percentiles
;            in week average values
;   - Write data out to netCDF
;
;   Files needed:
;         -MOPITT level 2, daily hdf files
;
;   To run type:
;         ncl regional-subset-mopitt.ncl 
;                                  RRB Ocotber 11, 2020
;=======================================================;
; load the libraries
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------
  ystart = 2001
  yend = 2019
  version = "V8J"
  infolder = "/MOPITT/"+version+"/Archive/L2/"

  ;------------
  ; select location
  ;------------
  location = "SEAust_stats"

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
  COLAVG_VMR     = True
  PIXELS         = False
    pixel_number_select = 1


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
  date           = "Time"+suff
  deg_freedom    = "DegreesofFreedomforSignal"+suff
  tcol_apriori   = "APrioriCOTotalColumn"+suff
  vmr_aprior     = "APrioriCOMixingRatioProfile"+suff
  vmr_surface    = "APrioriCOSurfaceMixingRatio"+suff
  vmr_aposterior = "RetrievedCOMixingRatioProfile"+suff
  apost_surf     = "RetrievedCOSurfaceMixingRatio"+suff
  avker          = "TotalColumnAveragingKernel"+suff
  vmr_avker      = "RetrievalAveragingKernelMatrix"+suff
  pressure_surf  = "SurfacePressure"+suff
  diag           = "RetrievedCOTotalColumnDiagnostics"+suff
  dryair         = "DryAirColumn"+suff

  ; used for selecting, but not written out:
  solarza        = "SolarZenithAngle"+suff
  surface_index  = "SurfaceIndex"+suff
  diag_2         = "RetrievalAnomalyDiagnostic"+suff
  swath_index    = "SwathIndex"+suff
  snr_calc       = "Level1RadiancesandErrors"+suff

   ;region_names = (/"AnthChina", "AnthIndi", "AnthEuro", "AnthUSA",\
   ;                 "BBUSA", "BBCanada", "BBSiberia", "BBWRus",\
   ;                 "BBCAmerica", "BBSAmerica","BBSAmOcean",\
   ;                  "BBCAfrica", "BBSAfrica","BBSAfOcean", \
   ;                 "BBMSEA", "BBNWAu","BBEAu", "NH_monthly", "SH_monthly"/)

   ;                   minlat, maxlat, minlon, maxlon
   ;region_select = (/(/ 30.,  40.,      110.,      123./),\  ;AnthChina
   ;                  (/ 20.,  30.,       70.,       95./),\  ;AnthIndi
   ;                  (/ 45.,  55.,        0.,       15./),\  ;AnthEuro
   ;                  (/ 35.,  40.,      -95.,      -75./),\  ;AnthUSA
   ;                  (/ 38.,  50.,     -125.,     -105./),\  ;BBUSA
   ;                  (/ 50.,  60.,     -125.,      -90./),\  ;BBCanada
   ;                  (/ 50.,  60.,       90.,      140./),\  ;BBSiberia
   ;                  (/ 35.,  50.,       40.,       85./),\  ;BBWRus
   ;                  (/ 10.,  23.5,    -105.,      -70./),\  ;BBCAmerica
   ;                  (/-25.,  -5.,      -75.,      -50./),\  ;BBSAmerica
   ;                  (/-35., -15.,      -40.,      -25./),\  ;BBSAmericaOcean
   ;                  (/  5.,  15.,      -20.,       38./),\  ;BBCAfrica
   ;                  (/-20.,  -5.,       10.,       40./),\  ;BBSAfrica
   ;                  (/-15.,   0.,      -10.,       10./),\  ;BBSAfOcean
   ;                  (/-10.,   8.,        95.,     125./),\  ;BBMSEA
   ;                  (/-25., -10.,       115.,     140./),\  ;BBNWAu
   ;                  (/-45., -10.,       140.,     155./),\  ;BBEAu
   ;                  (/  0.,  60.,      -180.,     180./),\  ;NH
   ;                  (/-60.,   0.,      -180.,     180./) /) ;SH

   region_names := (/"CONTRAIL","MSEA_stats","MYS_stats","MYS_pen",\
                     "CSAm","SSAm","CSAf","SSAf",\
                     "NAus","SAus","SEAust_stats","TEST"/)

   ;                   minlat, maxlat, minlon, maxlon
   region_select := (/(/ -25.,  -10.,      145.,      151.5/),\ ;CONTRAIL
                      (/ -10.,   10.,       90.,     160./),\   ;MSEA_stats
                      (/   0.5,   7.5,      99.5,    119.5/),\  ;MYS_stats
                      (/   0.5,   7.5,      99.5,    115.0/),\  ;MYS_pen
                      (/ -25.,   -5.,      -83.,     -32./),\   ;CSAm
                      (/ -58.,  -25.,      -80.,     -32./),\   ;SSAm
                      (/ -25.,  -10.,        0.,      59./),\   ;CSaf
                      (/ -40.,  -25.,        0.,      59./),\   ;SSAf
                      (/ -25.,  -10.,      112.,     181./),\   ;NAus
                      (/ -48.,  -25.,      112.,     181./),\   ;SAus
                      (/ -48.,  -25.,      134.,     155./),\   ;SEAust_stats
                      (/ -60.,    0.,     -180.,     180./) /)  ; TEST

   ;region_names = (/"PNW", "CentralUSA", "EastUSA"/)

   ;                   minlat, maxlat, minlon, maxlon
   ;region_select = (/(/ 38.,  60.,     -130.,     -110./),\ ;PNW
   ;                  (/ 35.,  49.,     -110.,     -95./),\  ;Central Mountain USA
   ;                  (/ 32.5,  42.,     -95.,     -75./) /) ;East USA


   ind_region = ind(region_names.eq.location)

   topboundary     = region_select(ind_region,1)
   bottomboundary  = region_select(ind_region,0)
   rightboundary   = region_select(ind_region,3)
   leftboundary    = region_select(ind_region,2)

  
  ;Carriage return
   cr = tochar(10)
  ; -------------------------------
  ; SELECTION SETUP
  ; -------------------------------
  if (surface.eq."land") then           ; land left
     s_id = 1
  else if (surface.eq."water") then     ; ocean left
     s_id = 0
  end if
  end if

do y = ystart,yend ; loop through years
  year = y
  ; -------------------------------
  ; SETUP OUTPUT
  ; -------------------------------
  if (netCDF) then
     outfolder = "~/MOPITT_subset/regions_v8/"
     outname      = outfolder+location+"_"+version+"subset_"+year+"weekavg_WEDCEN.nc"
     if (COLAVG_VMR) then
        outname      = outfolder+location+"_"+version+"subset_"+year+"weekavg_WEDCEN_VMR.nc"
        if (PIXELS) then
          print("Collecting pixel " +pixel_number_select)
          outname      = outfolder+location+"_"+version+"subset_"+year+"weekavg_VMR_p"+\
                       pixel_number_select+".nc"
          print("Will write to " +outname)
        end if
     end if
  end if


  ; -------------------------------
  ; SETUP ARRAYS 
  ; -------------------------------
  ; -------------------------------
  ; Create the weekly aligned year
  ; array for collection
  ; -------------------------------
   start_dow = day_of_week(year,1,1)
   end_dow = day_of_week(year,12,31)
   weeknames = (/"Sunday", "Monday", "Tuesdsay", "Wednesday",\
                 "Thursday", "Friday", "Saturday"/)

  yeardays_dummy := yyyymmdd_time(year-1, year+1, "integer")

   ; Get start day
   if (start_dow.gt.3) then
     ; 4 days in January
     jan = yeardays_dummy({(y)*10000+101:(y)*10000+104})
       jan_split := str_split_by_length(tostring(jan),4)
       jan_split2 := str_split_by_length(tostring(jan),2)
       jan_dow = day_of_week(toint(jan_split(:,0)),\
                                  toint(jan_split2(:,2)),\
                                  toint(jan_split2(:,3)))
     ; skip to Sunday
     ind_start = ind(yeardays_dummy.eq.jan(ind(jan_dow.eq.0)))
   else if (start_dow.gt.0.and.\
            start_dow.le.3) then
     ; collect previous year
     ; 3 days into previous year
     prevyear = yeardays_dummy({(y-1)*10000+1229:(y-1)*10000+1231})
       py_split := str_split_by_length(tostring(prevyear),4)
       py_split2 := str_split_by_length(tostring(prevyear),2)
       prevyear_dow = day_of_week(toint(py_split(:,0)),\
                                  toint(py_split2(:,2)),\
                                  toint(py_split2(:,3)))
     ind_start = ind(yeardays_dummy.eq.prevyear(ind(prevyear_dow.eq.0)))
   else
     ; starts on Sunday
     ind_start = ind(yeardays_dummy.eq.(y)*10000+101)
   end if
   end if

   ; Get end day
   if (end_dow.lt.3) then
     ; 4 last days of December
     dec = yeardays_dummy({(y)*10000+1228:(y)*10000+1231})
       dec_split := str_split_by_length(tostring(dec),4)
       dec_split2 := str_split_by_length(tostring(dec),2)
       dec_dow = day_of_week(toint(dec_split(:,0)),\
                                  toint(dec_split2(:,2)),\
                                  toint(dec_split2(:,3)))
     ; skip past Saturday
     ind_end = ind(yeardays_dummy.eq.dec(ind(dec_dow.eq.6)))
   else if (end_dow.ge.3.and.\
            end_dow.lt.6) then
     ; 3 day into next year
     nextyear = yeardays_dummy({(y+1)*10000+101:(y+1)*10000+103})
       ny_split := str_split_by_length(tostring(nextyear),4)
       ny_split2 := str_split_by_length(tostring(nextyear),2)
       nextyear_dow = day_of_week(toint(ny_split(:,0)),\
                                  toint(ny_split2(:,2)),\
                                  toint(ny_split2(:,3)))
     ; collect next year
      ind_end = ind(yeardays_dummy.eq.nextyear(ind(nextyear_dow.eq.6)))
   else
     ; ends on Saturday
     ind_end = ind(yeardays_dummy.eq.(y)*10000+1231)
   end if
   end if

print("Start day = " + start_dow + " : " + weeknames(start_dow))
print("Start year collection: " + ind_start )
print("End day = " + end_dow+ " : " + weeknames(end_dow))
print("End year collection: " + ind_end)
;exit

  ; -------------------------------
  ; Set up collection arays
  ; -------------------------------
   yeardays := yeardays_dummy(ind_start:ind_end)
   print("Number of days in data to collect: " +dimsizes(yeardays))

   doy := ind(yeardays)+1
   week := ceil(doy/7.0)

  if (start_dow.eq.3) then
    week_vals := ispan(1,53,1)
  else if (start_dow.eq.2.and.end_dow.eq.3) then
    week_vals := ispan(1,53,1)
  else
    week_vals := ispan(1,52,1)
  end if
  end if

  yearweek_string := year+""+sprinti("%2.2i",week_vals)
  yearweek := toint(yearweek_string)
  week_avg_day := yeardays(3:dimsizes(yeardays)-1:7)
  ;week_avg_time = yyyyddd_to_yyyymmdd(week_avg_day)

print(week_vals)
print(yearweek_string)
print(yearweek)
print(week_avg_day)
print("Day " + yeardays + " = Week " + week)
;exit

  month_stats := new((/dimsizes(yearweek_string),12/), float)
  month_5_95 := new((/dimsizes(yearweek_string),2/), float)
  month_tcol := new((/dimsizes(yearweek_string)/), float)
  month_tcol_collected := new((/dimsizes(yearweek_string)/), float)
  month_err := new((/dimsizes(yearweek_string)/), float)
  month_rande := new((/dimsizes(yearweek_string)/), float)
  month_smoothe := new((/dimsizes(yearweek_string)/), float)
  month_dofs := new((/dimsizes(yearweek_string)/), float)
  month_apriori := new((/dimsizes(yearweek_string)/), float)
  month_psurf := new((/dimsizes(yearweek_string)/), float)
  month_dryair := new((/dimsizes(yearweek_string)/), float)

  month_prior := new((/dimsizes(yearweek_string), 10/), float)
  month_prof := new((/dimsizes(yearweek_string), 10/), float)
  month_colak := new((/dimsizes(yearweek_string), 10/), float)

  month_vmrak := new((/dimsizes(yearweek_string), 10, 10/), float)

;--------------------------------------------
; load file and extract
;--------------------------------------------
   total_files_y0 := systemfunc ("ls "+infolder+tostring(year-1)+"*12/12*/MOP02J-"+tostring(year-1)+"*.he5")
   total_files_y1 := systemfunc ("ls "+infolder+year+"*/*/MOP02J-"+year+"*.he5")
   total_files_y2 := systemfunc ("ls "+infolder+tostring(year+1)+"*01/01*/MOP02J-"+tostring(year+1)+"*.he5")
   total_files_a := array_append_record(total_files_y0,total_files_y1,0)

   total_files := array_append_record(total_files_a,total_files_y2,0)


  ;------------
  ; loop over
  ; weeks
  ;------------
  ;do m=0,11
  do m=0,dimsizes(week_vals)-1
    ; counter for counting number of files with selected values
    dcount = 0
    print("==================================")
    print("Collecting: "+ yearweek_string(m))
    if (isvar("all_files")) then       ; are we somewhat through analysis
      delete(all_files)
    end if

    ; -------------------------------
    ; MOPITT
    ; -------------------------------
    ; Find files of days in this week
     ind_week := ind(week.eq.week_vals(m))
     do i=0,dimsizes(ind_week)-1

       file_ind = str_match_ind(total_files,tostring(yeardays(ind_week(i))))
       if (.not.ismissing(file_ind)) then
          ;print(total_files(file_ind))
          if (isvar("all_files")) then      
            dummy := all_files
            dummy2 := total_files(file_ind)
            all_files := array_append_record (dummy, dummy2, 0)
          else
            all_files = total_files(file_ind)
          end if
       end if
     end do

    if (.not.isvar("all_files")) then
      print("No MOPITT files for date: "+cd_calendar(time(i),2))
      continue  ; skip all the next bit and go to next file
    else
      print(all_files)
      ; number of files to be read
      ndates = dimsizes(all_files)
    end if


    ;------------
    ; loop over
    ; files in week
    ;------------
    do i=0,ndates-1
      ; read data
      fin = addfile(all_files(i), "r")            ; read in
      sza          := fin->$solarza$
      surf_type    := fin->$surface_index$
      pixel_num    := fin->$swath_index$(:,0)
      sn_5A        := fin->$snr_calc$(:,3,:)
        snr_5A := sn_5A(:,0)/sn_5A(:,1)
      lat          := fin->$latitude$
      lon          := fin->$longitude$
      diag_anom    := fin->$diag_2$
      time         := fin->$date$
      dofs         := fin->$deg_freedom$
        ;units value presumes use of TAI93 (International Atomic Time) format
        time@units = "seconds since 1993-1-1 00:00:00"


      ;--------------------------------------------
      ; Select region to bin (daytime retrievals)
      ;--------------------------------------------
       region := ind(sza.le.dayflag.and.\
                 surf_type.eq.s_id.and.\
                 pixel_num.ne.3.and.\
                 snr_5A.gt.1000.and.\
                 lat.le.topboundary.and.\
                 lat.ge.bottomboundary.and.\
                 lon.ge.leftboundary.and.\
                 lon.le.rightboundary.and.\
                 ;dofs.gt.1.and.\
                 diag_anom(:,0).ne.1.and.\
                 diag_anom(:,1).ne.1.and.\
                 diag_anom(:,2).ne.1.and.\
                 diag_anom(:,3).ne.1.and.\
                 diag_anom(:,4).ne.1)

      if (all(ismissing(region))) then
        print("only one value from MOPITT at " + location +\
              " for file " + i +", date: "+cd_calendar(time(i),2))
        continue  ; skip all the next bit and go to next file
      end if

      if (dimsizes(region).eq.1) then
        print("No MOPITT data at " + location +\
              " for file " + i +", date: "+cd_calendar(time(i),2))
        continue  ; skip all the next bit and go to next file
      end if

      tempcount = dcount
      dcount := tempcount+1
      print("***Collecting MOPITT data at " + location +\
              " for file " + i +", date: "+cd_calendar(time(i),2))

      ;--------------------------------------------
      ; Load remaining variables
      ;--------------------------------------------
      tgas          := fin->$tracer$(region,:)
        region_tcol := tgas(:,0)
        region_err  := tgas(:,1)
        region_two_diag  := fin->$diag$(region,:)
          region_smooth_e:= max(abs(region_two_diag(:,0)))
          region_rand_e  := max(abs(region_two_diag(:,1)))
        region_dofs       := fin->$deg_freedom$(region)
        region_apriori    := fin->$tcol_apriori$(region)
        region_psurf      := fin->$pressure_surf$(region)
        region_dryair     := fin->$dryair$(region)
     if (COLAVG_VMR) then
       region_tcol_collected := region_tcol
       col_vmr      := region_tcol/region_dryair
       col_vmr_err  := region_err/region_dryair
       ap_vmr       := region_apriori/region_dryair
       region_tcol  := col_vmr
       region_err   := col_vmr_err
       region_apriori := ap_vmr
     end if 

      ; a priori and retrieved profile have surface layer separate to rest
      vmr_dummy    := fin->$vmr_aprior$(region,:,0)
      vmr_surf     := fin->$vmr_surface$(region,0)
      region_prior := new((/dimsizes(region_tcol),10/),float,-9999)
         region_prior(:,1:9)  = vmr_dummy(:,:)
      ret_dummy    := fin->$vmr_aposterior$(region,:,0)
      ret_surf     := fin->$apost_surf$(region,0)
      region_prof  := new((/dimsizes(region_tcol),10/),float,-9999)
         region_prof(:,1:9)  = ret_dummy(:,:)
      region_ak    := fin->$avker$(region,:)
      region_vmr_ak:= fin->$vmr_avker$(region,:,:)

     ;--------------------------------------------------------------
     ; Correct for where MOPITT surface pressure <900 hPa
     ;--------------------------------------------------------------
     dp := new((/dimsizes(region_psurf), 10/), float) ; Pressure difference array
     do z= 0, 9, 1
       dp(:,z) = 1000.-(z*100) - region_psurf
     end do
     ;print(region_psurf)

     do p = 0, dimsizes(region_tcol)-1
       region_prior(p,:) = where(ismissing(region_prior(p,:)),vmr_surf(p),region_prior(p,:))
       region_prof(p,:) = where(ismissing(region_prof(p,:)),ret_surf(p),region_prof(p,:))
     end do
     region_prior = where(dp.ge.100,region_prior@_FillValue,region_prior)
     region_prof = where(dp.ge.100,region_prof@_FillValue,region_prof)


      if (any(.not.ismissing(region_tcol))) then
      ;--------------------------------------------
      ; Collect MOPITT data into timeseries
      ;--------------------------------------------
          if (.not.(isdefined("mopitt_selected"))) then

            ;--- total column
            mopitt_selected  = region_tcol
            print("New data points: " +dimsizes(region_tcol)+\
                  ", Total data points "+dimsizes(mopitt_selected))

            if (COLAVG_VMR) then
              mopitt_tcol_selected = region_tcol_collected
            end if

            ;--- 1D vars
            dofs_selected    = region_dofs
            apriori_selected = region_apriori
            psurf_selected   = region_psurf
            dryair_selected  = region_dryair
            err_selected     = region_err
            rande_selected   = region_rand_e
            smoothe_selected = region_smooth_e

            ;--- 2D vars
            m_apriori_selected = region_prior
            m_profile_selected = region_prof
            ak_selected        = region_ak

            ;--- 3D vars
            vmr_ak_selected    = region_vmr_ak

          else
            ;--- total column
            temp1 := mopitt_selected
            mopitt_selected := array_append_record(temp1,region_tcol,0)
            if (COLAVG_VMR) then
              temp1a := mopitt_tcol_selected
              mopitt_tcol_selected := array_append_record(temp1a,region_tcol_collected,0)
            end if

            ;--- 1D vars
            temp2 := dofs_selected
            temp3 := apriori_selected
            temp4 := psurf_selected
            temp5 := dryair_selected
            temp6 := err_selected
            temp7 := rande_selected
            temp8 := smoothe_selected
            dofs_selected    := array_append_record(temp2,region_dofs,0)
            apriori_selected := array_append_record(temp3,region_apriori,0)
            psurf_selected   := array_append_record(temp4,region_psurf,0)
            dryair_selected  := array_append_record(temp5,region_dryair,0)
            err_selected     := array_append_record(temp6,region_err,0)
            rande_selected   := array_append_record(temp7,region_rand_e,0)
            smoothe_selected := array_append_record(temp8,region_smooth_e,0)

            ;--- 2D vars
            temp9 := m_apriori_selected
            temp10 := m_profile_selected
            temp11 := ak_selected
            m_apriori_selected := array_append_record(temp9,region_prior,0)
            m_profile_selected := array_append_record(temp10,region_prof,0)
            ak_selected        := array_append_record(temp11,region_ak,0)

            ;--- 3D vars
            temp12 := vmr_ak_selected
            vmr_ak_selected := array_append_record(temp12,region_vmr_ak,0)

            print("New data points: " +dimsizes(region_tcol)+\
                  ", Total data points "+dimsizes(mopitt_selected)+\
                  ", check1 "+dimsizes(dofs_selected)+\
                  ", check2 "+dimsizes(apriori_selected))
          end if
      end if

      end do ; file loop

      ; still no data
      if (.not.(isdefined("mopitt_selected"))) then
        print("No MOPITT data at " + location +\
              " for " +", date: "+yearweek_string(m))
        continue  ; skip all the next bit and go to next file
      end if

    ;--------------------------------------------
    ; Perform percentile calculations
    ;--------------------------------------------
      opt = False
      stats_array = stat_dispersion(mopitt_selected, opt )
      sorted_array := dim_pqsort(mopitt_selected,2) 
      ind_5th = toint(ceil(0.05*dimsizes(sorted_array)))
      ind_95th = toint(ceil(0.95*dimsizes(sorted_array)))
      if (ind_95th.ge.dimsizes(mopitt_selected))then
        ind_95th = dimsizes(mopitt_selected)-1
      end if

      ; Stats Output
      ;(0)	   ===> Robust Dispersion Statistics: RetrievedCOTotalColumn <===
      ;(0)	 [0]            Mean
      ;(0)	 [1]          StdDev
      ;(0)	 [2]             Min
      ;(0)	 [6]     LowQuartile
      ;(0)	 [8]          Median
      ;(0)	 [10]   HighQuartile
      ;(0)	 [14]            Max
      ;(0)	 [18]      #   Total
      ;(0)	 [19]      #    Used=
      ;(0)	 [20]      # Missing
      ;(0)	 [24]     Lower 5.0%=-9999   <------- n > 1000
      ;(0)	 [25]     Upper 5.0%=-9999   <------- n > 1000
    ;------------
    ; collect week
    ; stats
    ;------------
    ; tcol
    month_stats(m,:) = stats_array((/0,1,2,6,8,10,14,18,19,20,24,25/))
    month_5_95(m,0) = mopitt_selected(ind_5th)
    month_5_95(m,1) = mopitt_selected(ind_95th)
    month_tcol(m) = dim_avg_n_Wrap(mopitt_selected,0)
      if (COLAVG_VMR) then
        month_tcol_collected(m) = dim_avg_n_Wrap(mopitt_tcol_selected,0)
      end if

    ; 1D vars
    month_dofs(m) = dim_avg_n_Wrap(dofs_selected,0)
    month_apriori(m) = dim_avg_n_Wrap(apriori_selected,0)
    month_psurf(m) = dim_avg_n_Wrap(psurf_selected,0)
    month_dryair(m) = dim_avg_n_Wrap(dryair_selected,0)
    ; errors are summed in quadrature
    month_err(m) = sqrt(dim_avg_n_Wrap(err_selected^2,0))
    month_rande(m) = sqrt(dim_avg_n_Wrap(rande_selected^2,0))
    month_smoothe(m) = sqrt(dim_avg_n_Wrap(smoothe_selected^2,0))

    ; 2D vars
    month_prior(m,:) = dim_avg_n_Wrap(m_apriori_selected,0)
    month_prof(m,:) = dim_avg_n_Wrap(m_profile_selected,0)
    month_colak(m,:) = dim_avg_n_Wrap(ak_selected,0)

    ; 3D vars
    month_vmrak(m,:,:) = dim_avg_n_Wrap(vmr_ak_selected,0)

    records = num(mopitt_selected)
    print("Number of files checked = " + ndates)
    print("Number of files with " +location+" info for "+ yearweek_string(m)+" = " + dcount)
    print("Number of retrievals in week values = " + records)
    
    ;------------
    ; release variable
    ;------------
      delete([/mopitt_selected,dofs_selected,apriori_selected,psurf_selected,\
              dryair_selected,err_selected,rande_selected,smoothe_selected,\
              m_apriori_selected,m_profile_selected,ak_selected,vmr_ak_selected/])

      if (COLAVG_VMR) then
        delete([/mopitt_tcol_selected/])
      end if
  end do ; week loop


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
      fAtt@title              = "Subset of week average MOPITT CO for " +location+"_"+year
      fAtt@source             = "MOPITT level 2, version 8, TIR retrievals"
      fAtt@creation_date      = systemfunc ("date")
      fAtt@conventrions       = "CF"

     fileattdef(fout, fAtt)
     setfileoption(fout, "DefineMode",False)


  ;------------
  ; Variables
  ;------------
   month_tcol!0              = "time"
   month_tcol&time           = week_avg_day
   month_tcol@average_op_ncl = "weekly spatial average over "+location+": "+\
                                    topboundary+" to "+bottomboundary+ " Lat, "+\
                                    leftboundary+" to "+rightboundary+" Lon"
   month_stats!0               = "time"
   month_stats&time            = week_avg_day
   month_stats@average_op_ncl  = "weekly spatial statistics over "+location+": "+\
                                    topboundary+" to "+bottomboundary+ " Lat, "+\
                                    leftboundary+" to "+rightboundary+" Lon"
   month_stats@definitions ="[0] Mean, [1] StdDev, [2] Min, [3] LowQuartile, [4] Median, "+cr+\
       "[5] HighQuartile, [6] Max, [7] Total n, [8] Used n, [9] Missing, "+cr+\
       "[10] Lower 5.0% (for n > 1000), [11] Upper 5.0% (for n > 1000)"

   month_5_95!0               = "time"
   month_5_95&time            = week_avg_day
   month_5_95@average_op_ncl  = "weekly 5th and 95th percentiles over "+location+": "+\
                                    topboundary+" to "+bottomboundary+ " Lat, "+\
                                    leftboundary+" to "+rightboundary+" Lon"

   month_apriori!0               = "time"
   month_apriori&time            = week_avg_day

   if (COLAVG_VMR) then
     ;--- total column
       fout->RetrievedX_CO       = month_tcol
     ;--- stats
       fout->RetrievedX_CORegionStats    = month_stats
       fout->RetrievedX_CORegion5th95th  = month_5_95
       fout->AvgAPrioriX_CO              = month_apriori
     ;--- total column
       month_tcol_collected!0              = "time"
       month_tcol_collected&time           = week_avg_day
       month_tcol_collected@average_op_ncl = "weekly spatial average over "+location+": "+\
                                    topboundary+" to "+bottomboundary+ " Lat, "+\
                                    leftboundary+" to "+rightboundary+" Lon"
       fout->RetrievedCOTotalColumn        = month_tcol_collected
   else
     ;--- total column
       fout->RetrievedCOTotalColumn        = month_tcol
     ;--- stats
       fout->RetrievedCOtcolRegionStats    = month_stats
       fout->RetrievedCOtcolRegion5th95th  = month_5_95
       fout->AvgAPrioriCOTotalColumn      = month_apriori
   end if
   ;--- 1D vars
   month_dofs!0               = "time"
   month_dofs&time            = week_avg_day
     fout->AvgDegreesofFreedomforSignal = month_dofs
   month_psurf!0               = "time"
   month_psurf&time            = week_avg_day
     fout->AvgSurfacePressure           = month_psurf
   month_dryair!0               = "time"
   month_dryair&time            = week_avg_day
     fout->AvgDryAirColumn              = month_dryair
   month_err!0               = "time"
   month_err&time            = week_avg_day
     fout->AvgError                     = month_err
   month_rande!0               = "time"
   month_rande&time            = week_avg_day
     fout->AvgRandomError               = month_rande
   month_smoothe!0               = "time"
   month_smoothe&time            = week_avg_day
     fout->AvgSmoothingError            = month_smoothe

   ;--- 2D vars
   month_prior!0               = "time"
   month_prior&time            = week_avg_day
   month_prior!1               = "lev"
     fout->AvgAPrioriCOMixingRatioProfile = month_prior
   month_prof!0               = "time"
   month_prof&time            = week_avg_day
   month_prof!1               = "lev"
     fout->AvgRetrievedCOMixingRatioProfile = month_prof
   month_colak!0               = "time"
   month_colak&time            = week_avg_day
   month_colak!1               = "lev"
     fout->AvgTotalColumnAveragingKernel = month_colak

   ;--- 3D vars
   month_vmrak!0               = "time"
   month_vmrak&time            = week_avg_day
     fout->AvgRetrievalAveragingKernelMatrix = month_vmrak


end if ;NETCDF

end do ; year loop

end
