;=======================================================;
;  sum_CAMchem_emis.ncl
;=======================================================;
;
; Concepts illustrated:
;   - load CAM emission files
;   - sum each year and print out
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
  tracer = "CO"
  ystart = 2001
  yend = 2014

;qfed.emis_BENZ_1.9x2.5_mol_2000_2014.nc      
;qfed.emis_BIGALD_1.9x2.5_mol_2000_2014.nc    
;qfed.emis_BIGALK_1.9x2.5_mol_2000_2014.nc    qfed.emis_CRESOL_1.9x2.5_mol_2000_2014.nc
;qfed.emis_BIGENE_1.9x2.5_mol_2000_2014.nc    qfed.emis_GLYALD_1.9x2.5_mol_2000_2014.nc
;qfed.emis_C10H16_1.9x2.5_mol_2000_2014.nc    qfed.emis_HCN_1.9x2.5_mol_2000_2014.nc
;qfed.emis_C2H2_1.9x2.5_mol_2000_2014.nc      qfed.emis_HCOOH_1.9x2.5_mol_2000_2014.nc
;qfed.emis_C2H4_1.9x2.5_mol_2000_2014.nc      qfed.emis_HYAC_1.9x2.5_mol_2000_2014.nc
;qfed.emis_C2H5OH_1.9x2.5_mol_2000_2014.nc        
;qfed.emis_C3H6_1.9x2.5_mol_2000_2014.nc      
;qfed.emis_C3H8_1.9x2.5_mol_2000_2014.nc           
;qfed.emis_CH3CHO_1.9x2.5_mol_2000_2014.nc   
;qfed.emis_CH3CN_1.9x2.5_mol_2000_2014.nc     
;qfed.emis_CH3COCH3_1.9x2.5_mol_2000_2014.nc  
;qfed.emis_CH3COCHO_1.9x2.5_mol_2000_2014.nc  qfed.emis_TOLUENE_1.9x2.5_mol_2000_2014.nc
;qfed.emis_CH3COOH_1.9x2.5_mol_2000_2014.nc   qfed.emis_XYLENE_1.9x2.5_mol_2000_2014.nc


  ; -------------------------------
  ; emission files
  ; -------------------------------
;  e_file_in = "/glade/p/work/buchholz/emis/qfed_finn_2000_2014/qfed.emis_"+tracer+"_1.9x2.5_mol_2000_2014.nc"
; location = "SAfrica"
;  e_file_in = "/glade/p/work/buchholz/emis/tagged_qfed_finn/qfed.emis_"+\
;                 tracer+"_"+location+"_1.9x2.5_mol_2000_2014.nc"
 ; e_file_in = "/glade/p/work/buchholz/emis/rcp85_2000_2014/tagged_emis/rcp85_2000-2014_"+\
 ;              tracer+"_"+location+"_noBiogBB_1.9x2.5_mol_c20150313.nc"
  e_file_in = "/glade/p/work/emmons/emis/rcp85_2000_2014/rcp85_2000-2014_"+\
                tracer+"_noBiogBB_1.9x2.5_mol_c20150313.nc"
  ; -------------------------------
  ; MOZART molecular weights
  ; -------------------------------
  molwts = "/glade/u/home/buchholz/data/species_molwts.txt"

;--------------------------------------------
; end user input
;--------------------------------------------

;********************************************
; set up
  ; -------------------------------
  ; names of data structures
  ; -------------------------------
;  emiss           = "bb"
; emiss = "anthro"
 emiss = "ocean"

  ; -------------------------------
  ; constants
  ; -------------------------------
   NAv = 6.022e23                    ; Avogadro's number, molecules mole^-1
   re   = 6.37122e06                 ; Earth radius
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
    fin = addfile(e_file_in, "r")
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
     tracer_emiss = (tracer_emiss*100*100)

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
       do i = 0, dimsizes(yyyymmdd)-1
         if(isleapyear(yyyy(i))) then
           montharray(1)= 29
         else
           montharray(1) = 28
         end if
         globsum(i) = globsum(i) * montharray(mm(i)-1)
       end do
     end if


    year_array = ispan(ystart,yend,1)
    year_avg_array = new((/dimsizes(year_array)/), float)
    do i = 0, dimsizes(year_array)-1
      year_ind := ind(globsum&time.gt.year_array(i)*10000.and.\
                 globsum&time.lt.(year_array(i)+1)*10000)
print(dimsizes(year_ind))
      year_avg_array(i) = sum(globsum(year_ind))
    end do

     print("Year, emissions of "+tracer+" (Tg)")
     print(year_array+" "+year_avg_array)

end

