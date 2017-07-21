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
  res = "0.94x1.2"

  tracer = "CO"
  ; BIGALD, BIGALK, BIGENE, C10H16, C2H4, C2H5OH, C2H6, C3H6, C3H8, CB1, CB2, CH2O, CH3CHO, CH3COCH3, CH3COCHO, CH3COOH, CH3OH, CO, CRESOL, GLYALD, HYAC, ISOP, MACR, MEK, MVK, NH3, NO, OC1, OC2, SO2, TOLUENE
  ; not in MW file: XYLENE, HCOOH, HCN, CO2, CH3CN, C2H2, BENZ

; location = "SAfrica"

  ; -------------------------------
  ; emission files
  ; -------------------------------
   indir = "/data14b/buchholz/qfed/cam_0.94x1.2/allyears/"
   outir = "/data14b/buchholz/qfed/cam_0.94x1.2/region_sums/"
   e_file_in = "qfed.emis_"+tracer+"_0.94x1.2_mol_"+ystart+"_"+yend+".nc"

  ; -------------------------------
  ; toggles
  ; -------------------------------
   NETCDF = False

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
      emiss_in         = fin->$emiss$
      time = emiss_in&time
      yyyymmdd = cd_calendar(time,-2)
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
     mw = tofloat(mol_wts(ind(mol_wts(:,0).eq.tracer),1))
     ; g cm-2 s-1
     tracer_emiss = (emiss_in/NAv)*mw          ; molec -> mol -> g
     ; g cm-2 d-1
     tracer_emiss = (tracer_emiss*86400)       ; s-1 -> d-1
     ; g m-2 d-1
     tracer_emiss = (tracer_emiss*100*100)     ; cm-2 -> m-2

     ; weight by gridbox area
       ; prevent negative weights 
       ; (redundant because no emissions over artic and anatarctica)
       lat(0)= 89.99999
       lat(dimsizes(lat)-1)= -89.99999   

     clat = cos(lat * rad)           ; cosine of latitude
     dlon = (lon(2) - lon(1))        ; assume dlon is constant
     dlat = (lat(2) - lat(1))        ; assume dlat is constant
     dx   = con * dlon * clat        ; dx (in metres) at each latitude
     dy   = con * dlat               ; dy (in metres) is constant
     dydx = dy * dx                  ; dydx(nlat)

     wgt  = new((/nlat, mlon/), float)
     wgt  = conform(wgt, dydx, 0)

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
    year_avg_array = new((/dimsizes(year_array)/), float)
    do i = 0, dimsizes(year_array)-1
      year_ind := ind(globsum&time.gt.year_array(i)*10000.and.\
                 globsum&time.lt.(year_array(i)+1)*10000)
      year_avg_array(i) = sum(globsum(year_ind))
    end do

     print("Year, emissions of "+tracer+" (Tg)")
     print(year_array+" "+year_avg_array)

    ;------------------
    ; Total average
    ;------------------
     total_avg = avg(year_avg_array)
     print(ystart+" to "+yend+", emissions of "+tracer+" (Tg):" + total_avg)

;********************************************
; Write out to new file
;********************************************
if (NETCDF) then

end if

end

