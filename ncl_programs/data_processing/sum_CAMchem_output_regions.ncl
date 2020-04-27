;=======================================================;
;  sum_CAMchem_output_regions.ncl
;=======================================================;
;
; Concepts illustrated:
;   - load CAM files
;   - calculate total column
;   - sum over regions
;   - write region sum timeseries to netCDF
;   
;   To run type:
;         ncl sum_CAMchem_output_regions.ncl
;
;   Requires:
;         concatenated otuput file
;                                  RRB 18 June, 2018
;=======================================================;
; load the libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------
  ystart = 2018
  yend = 2018
  reso = "0.9x1.25"

  machine = "cheyenne"         ; modeling1, modeling2, cheyenne


  tracers = (/"O3"/)
  sm_tracers = (/"o3"/)
  ;tracers = (/"CH3OH","CO","O3","PM25"/)
  ;tracers = (/"BIGALD", "BIGALK", "BIGENE", "C10H16", "C2H2", "C2H4", "C2H5OH", \
  ;            "C2H6", "C3H6", "C3H8", "CB1", "CB2", "CH2O", "CH3CHO", "CH3CN", \
  ;            "CH3COCH3", "CH3COCHO", "CH3COOH", "CH3OH", "CO", "CO2", "CRESOL", \
  ;            "GLYALD", "HCN", "HCOOH", "HYAC", "ISOP", "MACR", "MEK", "MVK", \
  ;            "NH3", "NO", "OC1", "OC2", "SO2", "TOLUENE"/)
  ; no MW data: XYLENE, BENZ

  ; -------------------------------
  ; begin a tracer loop
  ; -------------------------------
do t = 0, dimsizes(tracers)-1

  tracer = tracers(t)
  sm_tracer = sm_tracers(t)

  ; -------------------------------
  ; files and path setup
  ; -------------------------------
   ;runtype = "qfedBB"
   ;dir_in = "/glade/work/buchholz/CAM_chem_output/fire_uncert/"+runtype+"/"
   ;outpath = dir_in
   ;e_file_in = systemfunc ("ls "+dir_in + "*1deg_*2014.nc")

   runtype = "noanth"
   dir_in = "/glade/scratch/tasullivan/archive/noanth/atm/hist/"
   outpath = "/glade/work/buchholz/CAM_chem_output/tsp_fire_2018/"
   e_file_in = systemfunc ("ls "+dir_in + "*h1*2018*-10800.nc")

;/glade/scratch/tasullivan/archive/nofire
;/glade/scratch/tasullivan/archive/noanth
;/glade/scratch/tasullivan/archive/controlcomp
   print(e_file_in)


  ; -------------------------------
  ; toggles
  ; -------------------------------
   NETCDF = True

  ; -------------------------------
  ; MOZART molecular weights
  ; -------------------------------
  molwts = "/glade/u/home/buchholz/data/species_molwts.txt"
  ;molwts = "~/data/species_molwts.txt"

;--------------------------------------------
; end user input
;--------------------------------------------

;********************************************
; set up
  ; -------------------------------
  ; names of data structures
  ; "anthro", "bb", "ocean"
  ; -------------------------------
    tracer           = "O3"

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

   ; load molecular weights (g/mol) from a MOZART file,
   ; augmented with additional values for:
   ; CO2, OC and BC copied from OC1 and CB1
   mw_dummy  = asciiread(molwts,-1,"string")
   mw_dummy2 = mw_dummy(2:)
   mol_wts = new((/dimsizes(mw_dummy2),2/), string)
   do s = 0,dimsizes(mw_dummy2)-1
     mol_wts(s,:) = str_split(mw_dummy2(s)," ")
   end do

;********************************************
; load files and extract
    fin = addfiles(e_file_in, "r")
    ListSetType (fin, "cat") 
      tracer_in          = fin[:]->$tracer$
        time := tracer_in&time
        lat = tofloat(tracer_in&lat)
        lon = tofloat(tracer_in&lon)


      yyyymmdd := cd_calendar(time,-2)
       yyyymmdd!0 = "time"
       yyyymmdd&time = time
      yyyymmddhh := cd_calendar(time,-3)
       yyyymmddhh!0 = "time"
       yyyymmddhh&time = time
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

  ; -------------------------------
  ; pressure weighted average
  ; -------------------------------
   tcol_all  = dim_sum_n((tracer_in*xp_const*delta_p)/100,1)  ; dp Pa -> hPa
     tcol_all!0         = "time"
     tcol_all!1         = "lat"
     tcol_all!2         = "lon"
     tcol_all@long_name = "total column "+tracer
     tcol_all@units = "molec/cm^2"
     tcol_all&time      = tracer_in&time
     tcol_all&lat       = tracer_in&lat
     tcol_all&lon       = tracer_in&lon

printVarSummary(tcol_all)
print(tcol_all(0,0:10,0))
print(max(tcol_all(0,:,0)))
  ;********************************************
  ; Calculate averages
     ; weight by gridbox area
       ; prevent negative weights 
       ; (redundant because no emissions over artic and anatarctica)

       newlat = lat
       newlat(0)= 89.99999
       newlat(dimsizes(newlat)-1)= -89.99999   

     clat = cos(lat * rad)           ; cosine of latitude
     dlon = (lon(2) - lon(1))        ; assume dlon is constant
     dlat = (lat(2) - lat(1))        ; assume dlat is constant
     dx   = con * dlon * clat        ; dx (in metres) at each latitude
     dy   = con * dlat               ; dy (in metres) is constant
     dydx = dy * dx                  ; dydx(nlat)

     wgt  = new((/nlat, mlon/), float)
     wgt  = conform(wgt, dydx, 0)
      wgt!0 = "lat"
      wgt&lat = newlat
      wgt!1 = "lon"
      wgt&lon = lon

     ; AVERAGE over the region
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
  ; region_names = (/"Maritime SEA", "Australasia", \
  ;                  "Southern Africa", "South America",\
  ;                  "Siberia", "North America" /)
  ;                   minlat, maxlat, minlon, maxlon
  ; region_select = (/(/-10.,  10.,      90.,     160./),\ ;Maritime SEA
  ;                   (/-50., -10.,     110.,     180./),\ ;Australasia
  ;                   (/-40.,   5.,       0.,      60./),\ ;SAfrica
  ;                   (/-60.,   4., 360.-80., 360.-40./),\ ;SAmerica
  ;                   (/ 50.,  85.,      91.,     190./),\ ;Siberia
  ;                   (/ 25.,  70.,360.-170.,360.-53./) /) ;NAmerica

  ; region_names = (/"PNW", "CentralUSA", "EastUSA"/)

   ;                       minlat, maxlat, minlon, maxlon
  ; region_select = (/(/ 38.,     60.,     360.-130.,   360.-110./),\ ;PNW
  ;                   (/ 35.,     49.,     360.-110.,   360. -95./),\  ;Central Mountain USA
  ;                   (/ 32.5,    42.,     360. -95.,   360. -75./) /) ;East USA

   region_names = (/"Colorado", "PNW"/)
  ;                   minlat, maxlat, minlon, maxlon
   region_select = (/(/37.,    41.,    251.,    258./),\ ;Colorado
                     (/32.5,   60,     227.5,   251./)/) ;PNW

     ; -------------------------------
     ; sums
     ; -------------------------------
     regsum = new((/dimsizes(region_names), dimsizes(yyyymmdd)/), float)
     regsum_surf = new((/dimsizes(region_names), dimsizes(yyyymmdd)/), float)
     ; overwrite -89.999 and 89.999 so subset works correctly.
      wgt&lat = lat
     do r = 0, dimsizes(region_names)-1
       tracer_region := tcol_all(:,{region_select(r,0):region_select(r,1)},\
                                    {region_select(r,2):region_select(r,3)})
       tracer_surf:= tracer_in(:,55,{region_select(r,0):region_select(r,1)},\
                                    {region_select(r,2):region_select(r,3)})
       wgt_region := wgt({region_select(r,0):region_select(r,1)},\
                         {region_select(r,2):region_select(r,3)})
       regsum(r,:)= wgt_areaave2(tracer_region,wgt_region,0)
       regsum_surf(r,:)= wgt_areaave2(tracer_surf,wgt_region,0)
     end do

       regsum@units = "molec/cm^2"
       regsum!0 = "region"
       regsum&region = region_names
       regsum!1 = "time"
       regsum&time = time

       regsum_surf@units = "mol/mol"
       regsum_surf!0 = "region"
       regsum_surf&region = region_names
       regsum_surf!1 = "time"
       regsum_surf&time = time

       ;printVarSummary(regsum)


;********************************************
; Write out to new file
;********************************************
if (NETCDF) then
      ;-------------------
      ; create file for each 
      ; CAM-chem species
      ;-------------------
      outfilename = runtype+"_"+tracer+"_regional_"+ystart+".nc"
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
         fout->date             = yyyymmddhh

      do n = 0, dimsizes(region_names)-1
         bb_name = "total_column_"+n
         bb_name_surf = "surface_"+n
       ;--- emissions
         fout->$bb_name$             = regsum(n, :)
         fout->$bb_name_surf$        = regsum_surf(n, :)
      end do

    end if ;NetCDF

end do ; tracer loop

end

