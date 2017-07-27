;=======================================================;
;  sum_CAMchem_emis.ncl
;=======================================================;
;
; Concepts illustrated:
;   - load CAM emission files
;   - global sum each year and print out
;   - write region sum timeseries to netCDF
;   
;   To run type:
;         ncl sum_CAMchem_emis.ncl
;
;   Requires:
;         emission file
;                                  RRB 16 October, 2015
;=======================================================;
; load the libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------
  ystart = 2014
  yend = 2016
  reso = "0.94x1.2"

  ;tracers = (/"CH3OH","CO"/)
  tracers = (/"BIGALD", "BIGALK", "BIGENE", "C10H16", "C2H2", "C2H4", "C2H5OH", \
              "C2H6", "C3H6", "C3H8", "CB1", "CB2", "CH2O", "CH3CHO", "CH3CN", \
              "CH3COCH3", "CH3COCHO", "CH3COOH", "CH3OH", "CO", "CO2", "CRESOL", \
              "GLYALD", "HCN", "HCOOH", "HYAC", "ISOP", "MACR", "MEK", "MVK", \
              "NH3", "NO", "OC1", "OC2", "SO2", "TOLUENE"/)
  ; BIGALD, BIGALK, BIGENE, C10H16, C2H4, C2H5OH, C2H6, C3H6, C3H8, CB1, CB2, CH2O, CH3CHO, CH3COCH3, CH3COCHO, CH3COOH, CH3OH, CO, CRESOL, GLYALD, HYAC, ISOP, MACR, MEK, MVK, NH3, NO, OC1, OC2, SO2, TOLUENE
  ; no MW data: XYLENE, BENZ

  ; -------------------------------
  ; begin a tracer loop
  ; -------------------------------
do t = 0, dimsizes(tracers)-1

  tracer = tracers(t)
  ; -------------------------------
  ; emission files
  ; -------------------------------
   indir = "/data14b/buchholz/qfed/cam_"+reso+"/allyears/"
   outpath = "/data14b/buchholz/qfed/cam_"+reso+"/region_sums/"
   e_file_in = "qfed.emis_"+tracer+"_"+reso+"_mol_"+ystart+"_"+yend+".nc"

  ; -------------------------------
  ; toggles
  ; -------------------------------
   NETCDF = True

  ; -------------------------------
  ; MOZART molecular weights
  ; -------------------------------
  ;molwts = "/glade/u/home/buchholz/data/species_molwts.txt"
  molwts = "~/data/species_molwts.txt"

;--------------------------------------------
; end user input
;--------------------------------------------

;********************************************
; set up
  ; -------------------------------
  ; names of data structures
  ; "anthro", "bb", "ocean"
  ; -------------------------------
  emiss           = "bb"

  ; -------------------------------
  ; constants
  ; -------------------------------
   NAv = 6.022e23                    ; Avogadro's number, molecules mole^-1
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
    fin = addfile(indir+e_file_in, "r")
      emiss_in         := fin->$emiss$
      time := emiss_in&time
      yyyymmdd := cd_calendar(time,-2)
       yyyymmdd!0 = "time"
       yyyymmdd&time = time
      date = cd_calendar(time,0)
      yyyy = tointeger(date(:,0))
      mm = tointeger(date(:,1))
      ttime = dimsizes(time)
      lat = emiss_in&lat
      nlat = dimsizes(lat)
      lon = emiss_in&lon
      mlon = dimsizes(lon)

  ;********************************************
  ; Calculate emission totals

    ; -------------------------------
    ; convert to CAM-Chem units
    ; molec. cm-2 s-1 to g per day per gridbox
    ; -------------------------------
     ; not in MW file: XYLENE, HCOOH, HCN, CO2, CH3CN, C2H2, BENZ
     if (tracer.eq."C2H2") then
       mw = 26.036
     else if (tracer.eq."CH3CN") then
       mw = 41.054
     else if (tracer.eq."CO2") then
       mw = 44.008
     else if (tracer.eq."HCN") then
       mw = 27.028
     else if (tracer.eq."HCOOH") then
       mw = 46.024
     else
       mw = tofloat(mol_wts(ind(mol_wts(:,0).eq.tracer),1))
     end if
     end if
     end if
     end if
     end if
     ; g cm-2 s-1
     tracer_emiss = (emiss_in/NAv)*mw          ; molec -> mol -> g
     ; g cm-2 d-1
     tracer_emiss = (tracer_emiss*86400)       ; s-1 -> d-1
     ; g m-2 d-1
     tracer_emiss = (tracer_emiss*100*100)     ; cm-2 -> m-2
      tracer_emiss!0 = "time"
      tracer_emiss&time = yyyymmdd
      tracer_emiss!1 = "lat"
      tracer_emiss&lat = lat
      tracer_emiss!2 = "lon"
      tracer_emiss&lon = lon

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

     globsum  = wgt_areasum2(tracer_emiss,wgt,0)/1e12   ; g -> Tg
       globsum@units = "Tg"
       globsum!0 = "time"
       globsum&time = yyyymmdd

     if (emiss.eq."anthro".or.\
         emiss.eq."ocean") then
       print("monthly emissions")
         if(isleapyear(yyyy(i))) then
           montharray(1)= 29
         else
           montharray(1) = 28
         end if
       do i = 0, dimsizes(yyyymmdd)-1
         globsum(i) = globsum(i) * montharray(mm(i)-1)
       end do
     end if

    ;------------------
    ; Year averages
    ;------------------
    year_array = ispan(ystart,yend,1)
    year_sum_array = new((/dimsizes(year_array)/), float)
    do i = 0, dimsizes(year_array)-1
      year_ind := ind(globsum&time.gt.year_array(i)*10000.and.\
                 globsum&time.lt.(year_array(i)+1)*10000)
      year_sum_array(i) = sum(globsum(year_ind))
    end do

    ; print("Year, emissions of "+tracer+" (Tg)")
    ; print(year_array+" "+year_sum_array)

    ;------------------
    ; Total average
    ;------------------
     total_avg = avg(year_sum_array)
     print(ystart+" to "+yend+", average yearly emissions of "+tracer+" (Tg): " + total_avg)


  ;********************************************
  ; Extract regional timeseries
   region_names = (/"Maritime SEA", "Australasia", \
                    "Southern Africa", "South America" /)
  ;             minlat, maxlat, minlon, maxlon
   region_select = (/(/-10,  10, 90, 160/),\     ;Maritime SEA
                     (/-50, -10, 110, 180/),\      ;Australasia
                     (/-40,   5,   0,  60/),\      ;SAfrica
                     (/-60,   4, 360-80, 360-40/)/)      ;SAmerica

     ; -------------------------------
     ; sums
     ; -------------------------------
     regsum = new((/dimsizes(region_names), dimsizes(yyyymmdd)/), float)
     ; overwrite -89.999 and 89.999 so subset works correctly.
      wgt&lat = lat
     do r = 0, dimsizes(region_names)-1
       emiss_region := tracer_emiss(:,{region_select(r,0):region_select(r,1)},\
                                    {region_select(r,2):region_select(r,3)})
       wgt_region := wgt({region_select(r,0):region_select(r,1)},\
                         {region_select(r,2):region_select(r,3)})
       regsum(r,:)= wgt_areasum2(emiss_region,wgt_region,0)/1e12   ; g -> Tg
     end do

       regsum@units = "Tg"
       regsum!0 = "region"
       regsum&region = region_names
       regsum!1 = "time"
       regsum&time = time

       ;printVarSummary(regsum)

;********************************************
; Write out to new file
;********************************************
if (NETCDF) then
      ;-------------------
      ; create file for each 
      ; CAM-chem species
      ;-------------------
      outfilename = "qfed.emis_"+tracer+"_"+reso+"_Tg_regional.nc"
      fout = addfile(outpath+outfilename, "c")

      ;------------
      ; File 
      ; Attributes
      ;------------
      setfileoption(fout, "DefineMode",True)
      fAtt                      = True
        fAtt@molecular_weight   = mw
        fAtt@conventions        = "CF"
        fAtt@history            = "CO2 is from QFED, Level3b v2.4 "+\
                                  "(qfed-2_4_r6) Gridded Emission Estimates, with "+\
                                  "FINN emission ratios applied"
        fAtt@author             = "R. R. Buchholz"
        fAtt@creation_date      = systemfunc ("date")
        fAtt@source             = "QFED: NASA/GSFC/GMAO GEOS-5 Aerosol Group; FINN: C. Wiedinmyer 2015"
        fAtt@title              = "Emissions of "+ tracer+\
                                  " from FINN emission ratios applied to QFED CO2, daily"
        fAtt@globalavg          = ystart+" to "+yend+" average global yearly emissions of "+tracer+" (Tg): " + total_avg
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
         bb_name = "bb_"+n
       ;--- emissions
         fout->$bb_name$             = regsum(n, :)
      end do

    end if ;NetCDF

end do ; tracer loop

end

