;=======================================================;
;  sum_CAMchem_output_GFEDregions.ncl
;=======================================================;
;
; Concepts illustrated:
;   - load CAM files
;    - load GFED mask file
;   - calculate total column
;   - average over GFED regions
;   - write region average timeseries to netCDF
;   
;   To run type:
;         ncl sum_CAMchem_output_GFEDregions.ncl
;
;   Requires:
;         concatenated otuput file
; need ulimit -s unlimited
;                                  RRB 23 January, 2020
;=======================================================;
; load the libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/IASI/home/buchholz/code_database/ncl_programs/buchholz_global_util/mopitt_smooth_model_output.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------
  ystart = 2014
  yend = 2014
  reso = "0.9x1.25"

  tracers = (/"CO"/)

  ;tracers = (/"CH3OH", "C2H6","O3 "NO2", "HCN"/)
  ; no MW data: XYLENE, BENZ

  ; -------------------------------
  ; files and path setup
  ; -------------------------------
   runtype = "cmip.qfedBBmax_32L"
   ;dir_in = "/glade/scratch/buchholz/archive/fmerra.2.0.FCSD.1deg.chey200120.cmip.qfedBBmin/atm/hist/"
   dir_in = "/net/modeling1/data16a/buchholz/CAM_chem_output/fmerra.2.0.FCSD.1deg.chey200408."+runtype+"/atm/hist/"
   ;dir_in = "/net/modeling1/data16a/buchholz/CAM_chem_output/fmerra.2.0.FCSD.1deg.chey180615."+runtype+"/atm/hist/"
   ;dir_in = "/net/modeling1/data16a/buchholz/CAM_chem_output/fmerra.2.0.FCSD.1deg.chey200120."+runtype+"/atm/hist/"
   e_file_in = systemfunc ("ls "+dir_in + "*h1."+ystart+"*.nc")

;fmerra.2.0.FCSD.1deg.chey180615.cmip/
;fmerra.2.0.FCSD.1deg.chey180615.cmip.finnBBCO/
;fmerra.2.0.FCSD.1deg.chey180615.cmip.qfedBBCO/
;fmerra.2.0.FCSD.1deg.chey180615.cmip.qfedBBCOmax/
;fmerra.2.0.FCSD.1deg.chey180615.cmip.qfedBBCOmin/
;fmerra.2.0.FCSD.1deg.chey180617.cmip.gfasBBCO/
<<<<<<< HEAD
=======

>>>>>>> 501d5daafbb9770fac51810cf544f70c3cbfc5c4
;fmerra.2.0.FCSD.1deg.chey200406.cmip.qfedBB_32L/
;fmerra.2.0.FCSD.1deg.chey200406.cmip.qfedBBmaxCO_32L/
;fmerra.2.0.FCSD.1deg.chey200406.cmip.qfedBBminCO_32L/
;fmerra.2.0.FCSD.1deg.chey200408.cmip.qfedBBmax_32L/
;fmerra.2.0.FCSD.1deg.chey200408.cmip.qfedBBmin_32L/
<<<<<<< HEAD
=======

>>>>>>> 501d5daafbb9770fac51810cf544f70c3cbfc5c4


  ; -------------------------------
  ; toggles
  ; -------------------------------
   SAT_SMOOTH = False
     sat_path = "/MOPITT/V8J/Archive/L3/"
   NETCDF = True
    outpath = "/net/modeling1/data16a/buchholz/CAM_chem_output/EF_processed/"
   PLOT = False
    mapType = "x11"
    mapName = "GFED_regions"

  ; -------------------------------
  ; MOZART molecular weights
  ; -------------------------------
  molwts = "~/data/species_molwts.txt"

  ; -------------------------------
  ; GFED region file
  ; -------------------------------
  GFEDmask = "~/data/GFED_mask.csv"

;--------------------------------------------
; end user input
;--------------------------------------------

;********************************************
; set up

  ; -------------------------------
  ; constants
  ; -------------------------------
   NAv = 6.022e23                    ; Avogadro's number, molecules mole^-1
   g      = 9.81                             ;--- m/s - gravity
   H = (8.314*240)/(0.0289751*9.8)           ;--- scale height
   MWair = 28.94                             ;--- g/mol
   xp_const = (NAv* 10)/(MWair*g)            ;--- scaling factor for turning vmr into pcol

   re   = 6.37122e06                 ; Earth radius (in metres)
   rad  = 4.0 * atan(1.0) / 180.0    ; Convert degrees to radians (pi radians per 180 deg)
   con  = re * rad                   ; constant for determining arc length 

   montharray = (/31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31/)

  ; -------------------------------
  ; load molecular weights (g/mol) from a MOZART file,
  ; augmented with additional values for:
  ; CO2, OC and BC copied from OC1 and CB1
  ; -------------------------------
   mw_dummy  = asciiread(molwts,-1,"string")
   mw_dummy2 = mw_dummy(2:)
   mol_wts = new((/dimsizes(mw_dummy2),2/), string)
   do s = 0,dimsizes(mw_dummy2)-1
     mol_wts(s,:) = str_split(mw_dummy2(s)," ")
   end do

  ; -------------------------------
  ; Load GFED mask
  ; -------------------------------
   ;---Read the values in as 1D, since we don't know rows and columns yet.
   lines  := asciiread(GFEDmask,-1,"string")
   delim  = ","
   ncols  := dimsizes(str_split(lines(3),delim))
   nlines := dimsizes(lines)
   print("Lines:"+nlines+", Columns:"+ncols)

   ;---Reshape as 2D array, and convert to float for ppm/ppb/ppt.
   fields := new((/nlines,ncols/),float)
    do nf=0,ncols-1                    ;Remember that fields start at 1, not 0.
      fields(:,nf) = tofloat(str_get_field(lines(0:),nf+1,delim)) 
    end do
      fields!0 = "lon"
      fields!1 = "lat"

    region_mask = fields(lat|:,lon|:)

    region_colors = (/"blue", "dodgerblue1", "steelblue2", "lightskyblue", "red2", "pink1", "orange", "lightgoldenrod2",\
                      "yellow", "yellow3", "yellow4","seagreen1", "seagreen3", "forestgreen", "darkolivegreen1",\
                      "green", "limegreen", "maroon1", "maroon3", "maroon4", "mediumorchid", "mediumpurple",\
                      "royalblue", "darkslateblue", "navy", "cyan", "lightblue2", \
                      "darkslategray4", "darkslategray", "gray", "dimgray"/)

    region_levels = (/0.,1.,2.,3.,4.,5.,6.,7.,8.,9.,10.,11.,12.,13.,14./)

    region_names     = (/"Ocean","BONA","TENA","CEAM","NHSA","SHSA","EURO","MIDE", \
                         "NHAF","SHAF","BOAS","CEAS","SEAS","EQAS","AUST" /)
    ;;class_0 :	Ocean
    ;;class_1 :	BONA (Boreal North America)
    ;;class_2 :	TENA (Temperate North America
    ;;class_3 :	CEAM (Central America)
    ;;class_4 :	NHSA (Northern Hemisphere South America)
    ;;class_5 :	SHSA (Southern Hemisphere South America)
    ;;class_6 :	EURO (Europe)
    ;;class_7 :	MIDE (Middle East)
    ;;class_8 :	NHAF (Northern Hemisphere Africa)
    ;;class_9 :	SHAF (Southern Hemisphere Africa)
    ;;class_10 :	BOAS (Boreal Asia)
    ;;class_11 :	CEAS (Central Asia)
    ;;class_12 :	SEAS (Southeast Asia)
    ;;class_13 :	EQAS (Equatorial Asia)
    ;;class_14 :	AUST (Australia and New Zealand)

    delete([/lines,fields/])

; -------------------------------
; begin a tracer loop
; -------------------------------
do t = 0, dimsizes(tracers)-1

  tracer = tracers(t)

;********************************************
; load files and extract

; Load CAM-chem
    fin = addfiles(e_file_in, "r")
    ListSetType (fin, "cat") 
      tracer_in          = fin[:]->$tracer$
        time := tracer_in&time
        lat = tofloat(tracer_in&lat)
        lon = tofloat(tracer_in&lon)

      yyyymmdd := cd_calendar(time,-2)
       yyyymmdd!0 = "time"
       yyyymmdd&time = time
      date = cd_calendar(time,0)
      yyyy = tointeger(date(:,0))
      mm = tointeger(date(:,1))
      ttime = dimsizes(time)
      nlat = dimsizes(lat)
      mlon = dimsizes(lon)

      ps         = fin[:]->$"PS"$
      hyai       = fin[0]->$"hyai"$
      hybi       = fin[0]->$"hybi"$
      hyam       = fin[0]->$"hyam"$
      hybm       = fin[0]->$"hybm"$
      P0         = fin[0]->$"P0"$
      lev        = fin[0]->$"lev"$
      ilev       = fin[0]->$"ilev"$


  ;********************************************
  ; Calculate total column

  ; -------------------------------
  ; Hybrid levels to pressure levels
  ; -------------------------------
  pi = pres_hybrid_ccm(ps, P0, hyai, hybi) ; pi(ntim,klevi,nlat,mlon)
    pi!0         = "time"
    pi!1         = "lev"
    pi!2         = "lat"
    pi!3         = "lon"
    pi&time      = tracer_in&time
    pi&lat       = tracer_in&lat
    pi&lon       = tracer_in&lon
    pi@long_name = "edge-level pressures"
    pi@units     = "hPa"

  ; -------------------------------
  ; Calculate pressure array delta_p
  ; -------------------------------
  delta_p = new(dimsizes(tracer_in),float)
  copy_VarCoords(tracer_in,delta_p)
  do i = 0, dimsizes(delta_p&lev)-1
    delta_p(:,i,:,:) = pi(:,i+1,:,:) - pi(:,i,:,:)
  end do

  delete([/pi/])


  ; -------------------------------
  ; pressure weighted average
  ; -------------------------------
  ;---------------------------------------------------------------------
  ; Smooth the model data by satellite measured Averaging Kernels and a priori
  if (SAT_SMOOTH) then
   ; list satellite files
   sat_files = systemfunc ("ls "+sat_path + ystart+"*/*/MOP03J-"+ystart+"*.he5")
   ; collect satellite dates
   do f = 0, dimsizes(sat_files)-1
   ;do f = dimsizes(sat_files)-5, dimsizes(sat_files)-1
      sat_in := addfile(sat_files(f), "r")            ; read in
        fAtts = getfileatts(sat_in)

      if (.not.(isdefined("sat_date"))) then
        sat_lat      := sat_in->YDim_MOP03
        sat_lon      := sat_in->XDim_MOP03
        sat_date     := new(dimsizes(sat_files),integer)
          starttime = sat_in@$fAtts(2)$
          starttime@units = "seconds since 1993-1-1 00:00:00"
          sat_yyyymmdd := cd_calendar(starttime,-2)
          sat_date(0) = sat_yyyymmdd
        tcol_meas = new((/dimsizes(time), dimsizes(sat_lat), dimsizes(sat_lon)/), float)
        tcol_all = new((/dimsizes(time), dimsizes(sat_lat), dimsizes(sat_lon)/), float)
      else
        starttime := sat_in@$fAtts(2)$
        starttime@units = "seconds since 1993-1-1 00:00:00"
        sat_yyyymmdd := cd_calendar(starttime,-2)
        sat_date(f) = sat_yyyymmdd
      end if
   end do

    do i=0, dimsizes(time)-1
      ind_compare := ind(sat_date.eq.yyyymmdd(i))
     if (ismissing(ind_compare)) then
        ;---------------------------------------------------
        print("No MOPITT data for model date: "+yyyymmdd(i))
        continue  ; skip all the next bit and go to next file
        ;---------------------------------------------------
     else
      print("Found MOPITT data on "+sat_date(ind_compare)+" for model date: "+yyyymmdd(i))
      ; smooth model data and create total column
      tcol_converted = mopitt_smooth_model_output(tracer_in(i,:,:,:),ps(i,:,:),P0,hyam,hybm,sat_files(ind_compare))
      tcol_meas(i,:,:) = tcol_converted[0]
      tcol_all(i,:,:) = tcol_converted[1]
      delete([/tcol_converted/])
     end if
    end do 

    tcol_meas!0      = "time"
    tcol_meas&time   = yyyymmdd
    tcol_all!0       = "time"
    tcol_all&time    = yyyymmdd


  ;---------------------------------------------------------------------
  ; No smoothing
  else
  ; calculate model output tcol
   tcol_all  = dim_sum_n((tracer_in*xp_const*delta_p)/100,1)  ; dp Pa -> hPa
     tcol_all!0         = "time"
     tcol_all!1         = "lat"
     tcol_all!2         = "lon"
     tcol_all@long_name = "total column "+tracer
     tcol_all@units = "molec/cm^2"
     tcol_all&time      = tracer_in&time
     tcol_all&lat       = tracer_in&lat
     tcol_all&lon       = tracer_in&lon
  end if


  ;********************************************
  ; Calculate averages
     ; weight by gridbox area
       ; prevent negative weights 
       ; (redundant because no emissions over artic and anatarctica)

       newlat = tcol_all&lat
       newlat(0)= 89.99999
       newlat(dimsizes(newlat)-1)= -89.99999   

     clat = cos(tcol_all&lat * rad)               ; cosine of latitude
     dlon = (tcol_all&lon(2) - tcol_all&lon(1))   ; assume dlon is constant
     dlat = (tcol_all&lat(2) - tcol_all&lat(1))   ; assume dlat is constant

     dx   = con * dlon * clat        ; dx (in metres) at each latitude
     dy   = con * dlat               ; dy (in metres) is constant
     dydx = dy * dx                  ; dydx(nlat)

     wgt  = new((/dimsizes(tcol_all&lat), dimsizes(tcol_all&lon)/), float)
     wgt  = conform(wgt, tofloat(dydx), 0)
      wgt!0 = "lat"
      wgt&lat = newlat
      wgt!1 = "lon"
      wgt&lon = tcol_all&lon

     globsum  = wgt_areaave2(tcol_all,wgt,0)  ; g -> Tg
       globsum@units = "molec/cm^2"
       globsum!0 = "time"
       globsum&time = yyyymmdd


    ;------------------
    ; Year averages
    ;------------------
    year_array = ispan(ystart,yend,1)
    year_sum_array = new((/dimsizes(year_array)/), float)
    do i = 0, dimsizes(year_array)-1
      year_ind := ind(globsum&time.gt.year_array(i)*10000.and.\
                 globsum&time.lt.(year_array(i)+1)*10000)
      year_sum_array(i) = avg(globsum(year_ind))
    end do

     print("Year average total column amounts of "+tracer+" (Tg)")
     print(year_array+" "+year_sum_array)

    ;------------------
    ; Month averages
    ;------------------
    month_array = new(dimsizes(year_array)*12, integer)
    month_sum_array = new(dimsizes(month_array), float)
    do i = 0, dimsizes(year_array)-1
      do j = 0, 11
        month_ind := ind(mm.eq.j+1.and.yyyy.eq.year_array(i))
        month_array(i*12+j) = year_array(i)*100 + j+1
        if (.not.(ismissing(month_ind(0)))) then
          month_sum_array(i*12+j) = avg(globsum(month_ind))
        end if
      end do
    end do

     print("Month, avg total column of "+tracer+" (Tg)")
     print(month_array+" "+month_sum_array)

    ;------------------
    ; Total average
    ;------------------
     total_avg = avg(year_sum_array)
     print(ystart+" to "+yend+", average yearly total column of "+tracer+" (molec/cm^2): " + total_avg)


  ;********************************************
  ; Extract regional timeseries
  ; copy coords to regions
  if (SAT_SMOOTH) then
    lat@units = "degrees_north"
    lon@units = "degrees_east"
    region_mask&lat = lat
    region_mask&lon = lon
    region_mask_remap := area_conserve_remap_Wrap(region_mask&lon, region_mask&lat, region_mask, tcol_all&lon, tcol_all&lat, False)
    region_mask_remap@_FillValue=-9999
      region_mask_remap!0         = "lat"
      region_mask_remap!1         = "lon"
    region_mask := region_mask_remap
   else
     ; no need to overwrite region mask
    lat@units = "degrees_north"
    lon@units = "degrees_east"
    region_mask&lat = lat
    region_mask&lon = lon
   end if

    printVarSummary(region_mask)

    region_mask_extend = conform(tcol_all, (/region_mask/), (/1,2/))
    region_mask_extend!0 = "time"
    region_mask_extend!1 = "lat"
    region_mask_extend!2 = "lon"
    region_mask_extend&time = time
    region_mask_extend&lat = tcol_all&lat
    region_mask_extend&lon = tcol_all&lon

    printVarSummary(region_mask_extend)

     ; -------------------------------
     ; sums
     ; -------------------------------
     regsum = new((/dimsizes(region_names), dimsizes(yyyymmdd)/), float)
     if (SAT_SMOOTH) then
     ; collect measured tcol as well
       meas_regsum = new((/dimsizes(region_names), dimsizes(yyyymmdd)/), float)
     end if
     ; overwrite -89.999 and 89.999 so subset works correctly.
      wgt&lat = tcol_all&lat
     do r = 0, dimsizes(region_names)-1
       print(region_names(r))
       tracer_region = where(region_mask_extend.eq.r,tcol_all,tcol_all@_FillValue)
         tracer_region!0 = "time"
         tracer_region!1 = "lat"
         tracer_region!2 = "lon"
         tracer_region&time = time
         tracer_region&lat = tcol_all&lat
         tracer_region&lon = tcol_all&lon

       wgt_region := where(region_mask.eq.r,wgt,wgt@_FillValue)
       regsum(r,:)= wgt_areaave2(tracer_region,wgt_region,0)

     if (SAT_SMOOTH) then
     ; collect measured tcol as well
       meas_region = where(region_mask_extend.eq.r,tcol_meas,tcol_meas@_FillValue)
         copy_VarCoords(tracer_region,meas_region)
       meas_regsum(r,:)= wgt_areaave2(meas_region,wgt_region,0)
     else
     ; no need to collect
     end if


;********************************************
; MAP PLOT
;********************************************
  if (PLOT) then
    wks = gsn_open_wks(mapType,mapName)

    gsn_define_colormap(wks,"cmp_haxby")        ; change colour map
    ;-----------------------------------
    ; define resources to use for plotting
    ;-----------------------------------
    mapres = True
    mapres@gsnDraw		    = False	                ; don't draw it yet
    mapres@gsnFrame                 = False                     ; don't advance frame

    mapres@cnFillOn                  = True
    mapres@cnFillMode                = "CellFill"          ; fill as grid boxes not contours
    mapres@cnLineLabelsOn            = False               ; turn off countour labels
    mapres@cnLinesOn                 = False

    mapres@cnLevelSelectionMode      = "ManualLevels"      ; manually set the contour levels
      mapres@cnMinLevelValF          = 0.4e18
      mapres@cnMaxLevelValF          = 2.8e18
      mapres@cnLevelSpacingF         = 0.20e18        ; set the interval between contours

   ;mapres@lbLabelStrings             = region_levels 
   mapres@lbLabelFontHeightF         = 0.01
   mapres@lbLabelPosition            = "Bottom"
   mapres@lbLabelAlignment           = "BoxCenters"
   mapres@pmLabelBarWidthF           = 1.  
   mapres@lbTitleString              = "CO column within GFED regions"
   mapres@lbTitlePosition            = "Bottom"
   mapres@lbTitleFontHeightF         = 0.015
   ;mapres@lbBoxLinesOn               = False

    map = gsn_csm_contour_map_ce(wks,tracer_region(1,:,:),mapres)


  draw(map)
  frame(wks)

  end if    ; PLOT


     end do

       regsum@units = "molec/cm^2"
       regsum!0 = "region"
       regsum&region = region_names
       regsum!1 = "time"
       regsum&time = time

        if (SAT_SMOOTH) then
         copy_VarCoords(regsum,meas_regsum)
        end if

       printVarSummary(regsum)


;********************************************
; Write out to new file
;********************************************
if (NETCDF) then
      ;-------------------
      ; create file for each 
      ; CAM-chem species
      ;-------------------
     if (SAT_SMOOTH) then
      outfilename = runtype+"_smoothed_"+tracer+"_regional_"+ystart+".nc"
     else
      outfilename = runtype+"_"+tracer+"_regional_"+ystart+".nc"
     end if
      fout = addfile(outpath+outfilename, "c")
      print(outpath+outfilename)

      ;------------
      ; File 
      ; Attributes
      ;------------
      setfileoption(fout, "DefineMode",True)
      fAtt                      = True
        ;fAtt@molecular_weight   = mw
        fAtt@conventions        = "CF"
        fAtt@creation_date      = systemfunc ("date")
        fAtt@author             = "R. R. Buchholz"
          fAtt@history            ="CAM-chem output separated into regions"
          fAtt@title              = "Total column of "+ tracer+\
                                  " from CAM-chem, daily"
        fAtt@globalavg          = ystart+" to "+yend+" average global yearly total column of "+tracer+" (molec/cm^2): " + total_avg
        fAtt@average            = region_names

       fileattdef(fout, fAtt)
       setfileoption(fout, "DefineMode",False)

      ;------------
      ; Coordinate Variables
      ;------------
        dimNames = (/"time"/)  
	dim_Sizes = (/ -1  /) 
	dimUnlim = (/ True /)   
	filedimdef(fout,dimNames,dim_Sizes,dimUnlim)

      ;------------
      ; Variables
      ;------------
       ;--- date
         fout->date             = yyyymmdd

      do n = 0, dimsizes(region_names)-1
         bb_name = "total_column_"+n
       ;--- emissions
         fout->$bb_name$             = regsum(n, :)

        if (SAT_SMOOTH) then
          meas_name = "meas_column_"+n
          fout->$meas_name$             = meas_regsum(n, :)
        end if

      end do

    end if ;NetCDF

end do ; tracer loop

end

