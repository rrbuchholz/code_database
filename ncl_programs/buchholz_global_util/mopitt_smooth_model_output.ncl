;============================================
; mopitt_smooth_model_output.ncl
;============================================
;
; Concepts Illustrated
;          - Use satellite averaging kernels and
;            a priori to smooth model output
;
; To use call within another ncl program:
;        smoothed_column = mopitt_smooth_model_output(data_array,pressure_array,satellite_file)
;          
;                            RRB Feb 26, 2020
;============================================
load "/IASI/home/buchholz/code_database/ncl_programs/buchholz_global_util/ultrafine_mopitt.ncl"

undef("mopitt_smooth_model_output")

function mopitt_smooth_model_output(valIN[*][*][*]:numeric, pressIN[*][*]:numeric,P0:numeric,hyam:numeric,hybm:numeric, satIN:string)
;============================================
; Purpose: regrid to higher resolution vertical grid
; 
; Arguments:
;    valIN: The model values. Needs lat, lon, lev coordinate variables.
;
;    pressIN: Surface pressure associated with model data. Needs lat, lon coordinate variables.
;
;    P0, hyam and hybm: Model constants used to create true pressure array of the output.
;
;    satIN: Satellite file coinciding with model date.
;
;
; Return Value:
;    valOUT: Model output smoothed to measurement space
;
;============================================
local tcol_gas_orig, tcol_gas, tcol_smooth, tracer_remap, ps_remap, pi_remap, meas_lon, meas_lat, valOUT, valSMOOTH

begin

  ; -------------------------------
  ; MOPITT VARIABLES
  ; -------------------------------
  ; names of data structures
  ; determined from an ncl_filedump
  sat_surfap    = "APrioriCOSurfaceMixingRatioDay_MOP03"
  sat_ap        = "APrioriCOMixingRatioProfileDay_MOP03"
  sat_colap     = "APrioriCOTotalColumnDay_MOP03"
  sat_colak     = "TotalColumnAveragingKernelDay_MOP03"
  sat_co        = "RetrievedCOTotalColumnDay_MOP03"
  sat_psurf     = "SurfacePressureDay_MOP03"

  ; -------------------------------
  ; LOAD SATELLITE FILE
  ; -------------------------------
  mopitt_in := addfile(satIN, "r")

  ;--------------------------------------------
  ; COLLECT MEASURED TCOL
  ;--------------------------------------------
  tcol_gas_orig:= mopitt_in->$sat_co$
    tcol_gas_orig!0    = "lon"
    delete_VarAtts(tcol_gas_orig&lon, (/"Units", "projection"/))
    tcol_gas_orig!1    = "lat"
    delete_VarAtts(tcol_gas_orig&lat, (/"Units", "projection"/))
    tcol_gas = tcol_gas_orig(lat|:, lon|:)

   tcol_smooth = new(dimsizes(tcol_gas_orig),float)

   delete([/tcol_gas_orig/])

  ;--------------------------------------------
  ; HORIZONTAL REGRID
  ; Model downscaled to MOPITT Grid
  ;--------------------------------------------
  ; grab MOPITT dimensions
  meas_lon      := mopitt_in->Longitude_MOP03
  meas_lat      := mopitt_in->Latitude_MOP03

  ; remap tracer
  tracer_remap := area_conserve_remap_Wrap(valIN&lon, valIN&lat, valIN, meas_lon, meas_lat, False)
  tracer_remap@_FillValue=-9999
    tracer_remap!0         = "lev"
    tracer_remap!1         = "lat"
    tracer_remap!2         = "lon"

  ; create associated remapped model pressure levels
  ps_remap = area_conserve_remap_Wrap(valIN&lon, valIN&lat, pressIN, meas_lon, meas_lat, False)
  pi_remap = pres_hybrid_ccm(ps_remap, P0, hyam, hybm) ; pi(ntim,klevi,nlat,mlon)
    pi_remap!0         = "lev"
    pi_remap!1         = "lat"
    pi_remap!2         = "lon"
    pi_remap&lev       = tracer_remap&lev
    pi_remap&lat       = tracer_remap&lat
    pi_remap&lon       = tracer_remap&lon
    pi_remap@long_name = "mid-level pressures"
    pi_remap@units     = "Pa"

   delete([/ps_remap/])

  ;--------------------------------------------
  ; SETUP MOPITT VERTICAL ARRAY
  ;--------------------------------------------
  ; grab MOPITT layer information
  psurf         := mopitt_in->$sat_psurf$
  pres_array    := mopitt_in->Pressure_MOP03

  meas_parray := new((/dimsizes(meas_lon), dimsizes(meas_lat), 10/), float)
    meas_parray(:,:,0) = psurf
    do i=0,dimsizes(pres_array)-1
      meas_parray(:,:,i+1) = pres_array(i)
    end do

   ; Correct for where MOPITT surface pressure <900 hPa
   ; Determine the level where the surface pressure needs to sit
   meas_delta_p := new((/dimsizes(meas_lon), dimsizes(meas_lat), 10/), float)
      do z= 0, 9, 1
        if (z.eq.9) then
          meas_delta_p(:,:,z) = meas_parray(:,:,0)-0
        else
          meas_delta_p(:,:,z) = meas_parray(:,:,0)-meas_parray(:,:,z+1)
        end if
      end do

   ; Repeat surface values at all levels in order to replace for <900 hPa
   meas_psurfarray = new((/dimsizes(meas_lon), dimsizes(meas_lat), 10/), float) 
    do z= 0, 9, 1
     meas_psurfarray(:,:,z) = psurf
    end do
   ; add fill values below true surface
   meas_parray = where(meas_delta_p.le.0,meas_parray@_FillValue,meas_parray)
   meas_parray = where((meas_delta_p.le.100 .and. meas_delta_p.ge.0),meas_psurfarray,meas_parray)
   meas_parray = where(ismissing(meas_delta_p),meas_parray@_FillValue,meas_parray)

   ; Sanity check for psurf for <900 hPa
   p1D      := ndtooned(psurf)
   dsizes_psurf = dimsizes(psurf)
   indices_lt900  := ind_resolve(ind(p1D.lt.900),dsizes_psurf)
   ;print(meas_parray(indices_lt900(0,0),indices_lt900(0,1),:))

      delete([/meas_psurfarray/])


  ;--------------------------------------------
  ; MOPITT combine a priori profile info
  ; (surface values are separate to profiles)
  ;--------------------------------------------
  apriori_surf  := mopitt_in->$sat_surfap$
  apriori_prof  := mopitt_in->$sat_ap$

  apriori_prof_all := new((/dimsizes(meas_lon), dimsizes(meas_lat),10/),float,-9999)
     apriori_prof_all(:,:,1:9)  = apriori_prof
     apriori_prof_all(:,:,0)  = apriori_surf

  ; Repeat surface a priori values at all levels to replace if needed
  apsurfarray := new((/dimsizes(meas_lon), dimsizes(meas_lat), 10/), float) 
    do z= 0, 9, 1
      apsurfarray(:,:,z) = apriori_surf
    end do

  ; Correct for where MOPITT surface pressure <900 hPa
   apriori_prof_all = where(meas_delta_p.le.0,apriori_prof_all@_FillValue,apriori_prof_all)
   apriori_prof_all = where((meas_delta_p.le.100 .and. meas_delta_p.ge.0),apsurfarray,apriori_prof_all)
   apriori_prof_all = where(ismissing(meas_delta_p),apriori_prof_all@_FillValue,apriori_prof_all)

   logap = log10(apriori_prof_all)

   delete([/apsurfarray,apriori_prof_all/])

  ;--------------------------------------------
  ; APPLY AK
  ;--------------------------------------------
  apriori_col   := mopitt_in->$sat_colap$
  AvKer         := mopitt_in->$sat_colak$

  sublevs = 100
  AvKer_calcs = where(ismissing(AvKer), 0, AvKer)
  logap_calcs = where(ismissing(logap), 0, logap)

  delete([/AvKer,logap/])

  ;Loop over Latitude
  do l = 0, dimsizes(meas_lat)-1
    ;Loop over Longitude
    do m = 0, dimsizes(meas_lon)-1
    ;--------------------------------------------
    ; NO MEASURED VALUES
    ;--------------------------------------------
    if (all(ismissing(meas_parray(m,l,:)))) then
      continue
    else 
    ;--------------------------------------------
    ; VERTICAL REGRID
    ; Model to MOPITT Grid
    ;--------------------------------------------
      model_interp := ultrafine_mopitt(tracer_remap(:,l,m), pi_remap(:,l,m)/100, meas_parray(m,l,:), sublevs)
      log_modelinterp = log10(model_interp/1e-09)
      log_modelinterp_calc = where(ismissing(log_modelinterp), 0, log_modelinterp)
    ;--------------------------------------------
    ; DO THE CALCULATION
    ;--------------------------------------------
      tcol_smooth(m,l) = apriori_col(m,l) + sum(AvKer_calcs(m,l,:)*(log_modelinterp-logap_calcs(m,l,:)))
    end if
    end do
  end do 

    tcol_smooth!0    = "lon"
    tcol_smooth!1    = "lat"
    tcol_smooth&lat = tcol_gas&lat
    tcol_smooth&lon = tcol_gas&lon

  ;--------------------------------------------
  ; RETURN MEASURED AND SMOOTHED MODEL TCOL
  ;--------------------------------------------
  valOUT := tcol_gas
  smoothOUT := tcol_smooth(lat|:, lon|:)
  return([/valOUT,smoothOUT/])
  
  delete([/tracer_remap,pi_remap,AvKer_calcs,logap_calcs,tcol_gas,tcol_smooth/])


end
