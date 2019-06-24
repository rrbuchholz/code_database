;=======================================================;
;  read_in_species.ncl
;=======================================================;
;
; Concepts illustrated:
;   - developed for the FIREX 2019 campaign
;   - open CAM-chem output
;   - read in species
;   - return data array
;
;   Files needed:
;         -CAM-chem output in netCDF format
;
;   Called in as:
;          tracer_array = read_in_species(filename,tracername)
; 
;                                  RRB June 24, 2019
;=======================================================;

undef("read_in_species")

function read_in_species(fileIN:string, tracerIN:string)
;============================================
; Purpose: read in species
; 
; Arguments:
;    fileIN: path to file to read, or a list of files
;
;    tracerIN: tracer name to read in
;              current options:"CO", "CO01", "CO02", "CO03","CO04","CO05","CO06",
;                              "ISOP_etc", "O3", "NOx", "BC", "OC", "SOA", "SO4", "PAN",  "AEROD_v",
;                              "CO_var", "DUST_ODV"
;
; Return Value:
;    valOUT: tracer array
;
;============================================
local valCOLLECT, tracer, tracername, tracer_dummy, tracer_dummy1, tracer_dummy2, tracer_dummy3, date


begin

  ; check input
  if (.not.(fileexists(fileIN(0)))) then
    print("read_in_species: Input file does not exist: " + fileIN)
    return
  end if

  ; -------------------------------
  ; CAM-chem file
  ; -------------------------------
  filename = fileIN
  tracer = tracerIN

  ; check input
  if (ismissing(tracer)) then
    print("read_in_species: Tracer name was not given.")
    return
  end if

  ;if (tracerIN.ne.) then
  ;  print("read_in_species: Tracer name not in verified list")
  ;  return
  ;end if


;--------------------------------------------
; set-up
;--------------------------------------------
 if (tracer.eq."CO01") then
   tracername = "CO: S.Korea - anthro"
 else if (tracer.eq."CO02") then
   tracername = "CO: Japan - anthro"
 else if (tracer.eq."CO03") then
   tracername = "CO: NE China  - anthro"
 else if (tracer.eq."CO04") then
   tracername = "CO: N. China  - anthro"
 else if (tracer.eq."CO05") then
   tracername = "CO: S. China - anthro"
 else if (tracer.eq."CO06") then
   tracername = "CO: S. Asia  - anthro"
 else if (tracer.eq."CO07") then
   tracername = "CO: N. Asia -fires"
 else if (tracer.eq."CO08") then
   tracername = "CO: Central Asia - fires"
 else if (tracer.eq."CO09") then
   tracername = "CO: S. Asia - fires" 
 else if (tracer.eq."ISOP_etc") then
   tracername = "ISOP + MACR + MVK"
 else if (tracer.eq."AEROD_v") then
   tracername = "AOD"
 else if (tracer.eq."DUST_ODV") then
   tracername = "Dust optical depth"
 else
   tracername = tracer
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

   
;*******************************************
;--------------------------------------------
; load file and extract
;--------------------------------------------

  ; -------------------------------
  ; CAM-chem load
  ; -------------------------------
    fin = addfiles(filename, "r")         ; read in
    ListSetType (fin, "cat")               ; concatenate

  ; -------------------------------
  ; CAM-chem collect and convert
  ; -------------------------------
      if (tracer.eq."ISOP_etc") then
        tracer_dummy1 = fin[:]->ISOP          ; mol/mol
        tracer_dummy2 = fin[:]->MACR          ; mol/mol
        tracer_dummy3 = fin[:]->MVK           ; mol/mol
        tracer_dummy = tracer_dummy1 +tracer_dummy2 + tracer_dummy3
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "ISOP + MACR + MVK concentration"
      else if (tracer.eq."NOx") then
        tracer_dummy1 = fin[:]->NO2          ; mol/mol
        tracer_dummy2 = fin[:]->NO          ; mol/mol
        tracer_dummy = tracer_dummy1 +tracer_dummy2
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "NO + NO2 concentration"
      else if (tracer.eq."BC") then
        tracer_dummy1 = fin[:]->CB1          ; kg/kg
        tracer_dummy2 = fin[:]->CB2          ; kg/kg
        tracer_dummy = tracer_dummy1 +tracer_dummy2
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "BC concentration"
      else if (tracer.eq."OC") then
        tracer_dummy1 = fin[:]->OC1          ; kg/kg
        tracer_dummy2 = fin[:]->OC2          ; kg/kg
        tracer_dummy = tracer_dummy1 +tracer_dummy2
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "OC concentration"
      else if (tracer.eq."SOA") then
        tracer_dummy1 = fin[:]->SOAB          ; kg/kg
        tracer_dummy2 = fin[:]->SOAI          ; kg/kg
        tracer_dummy3 = fin[:]->SOAM          ; kg/kg
        tracer_dummy4 = fin[:]->SOAT          ; kg/kg
        tracer_dummy5 = fin[:]->SOAX          ; kg/kg
        tracer_dummy = tracer_dummy1+tracer_dummy2+tracer_dummy3+tracer_dummy4+tracer_dummy5
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "SOA concentration"
      else if (tracer.eq."DUST_ODV") then
        tracer_dummy1 = fin[:]->ODV_DST01          ; kg/kg
        tracer_dummy2 = fin[:]->ODV_DST02          ; kg/kg
        tracer_dummy3 = fin[:]->ODV_DST03          ; kg/kg
        tracer_dummy4 = fin[:]->ODV_DST04          ; kg/kg
        tracer_dummy = tracer_dummy1+tracer_dummy2+tracer_dummy3+tracer_dummy4
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "Dust ODV"
      else 
        tracer_dummy = fin[:]->$tracer$         ; mol/mol or kg/kg
      end if
      end if
      end if	
      end if
      end if
      end if

     ; Collect into one array for output
     if (tracer.eq."BC".or.tracer.eq."OC".or.\
         tracer.eq."SO4".or.tracer.eq."SOA") then
       valCOLLECT = tracer_dummy              ; kg/kg
         copy_VarCoords(tracer_dummy,valCOLLECT)
         copy_VarAtts(tracer_dummy,valCOLLECT)
     else if (tracer.eq."AEROD_v".or.\
              tracer.eq."DUST_ODV".or.\
              tracer.eq."CO_var") then
       valCOLLECT = tracer_dummy
     else
       valCOLLECT = tracer_dummy/1e-9         ; mol/mol -> ppb
         copy_VarCoords(tracer_dummy,valCOLLECT)
         copy_VarAtts(tracer_dummy,valCOLLECT)
         valCOLLECT@units = "ppb"
     end if
     end if

     valCOLLECT@tracername = tracername
     valCOLLECT&lev@units = "hybrid_sigma_pressure"

  valOUT = valCOLLECT
  return(valOUT)


end

