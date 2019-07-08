;=======================================================;
;  read_in_species.ncl
;=======================================================;
;   - updated to FIREX species
;                               R Schwantes 28 June 2019 
; ------------------------------------------------------;
; Concepts illustrated:
;   - developed for the FIREX 2019 campaign
;   - open model output
;   - read in species
;   - return data array
;
;   Files needed:
;         -model output in netCDF format
;
;   Called in as:
;          tracer_array = read_in_species(filename,tracername)
; 
;                                  RRB June 24, 2019
;=======================================================;

undef("read_in_species")

function read_in_species(fileIN:string, tracerIN:string, lat_bound_0:numeric, lat_bound_1:numeric, \
                       lon_bound_0:numeric, lon_bound_1:numeric, lev_limit_0:numeric)
;============================================
; Purpose: read in species
; 
; Arguments:
;    fileIN: path to file to read, or a list of files
;
;    tracerIN: tracer name to read in
;              current options:"CO", "CO01", "CO02", "COnotNA", "BC", "POM", "PM25",
;                              "ISOP", "O3", "O3S", "NOx", "SOA", "SO4", "AODVISdn", "DUST"
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
  ; model file
  ; -------------------------------
  filename := fileIN
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
if (tracer.eq."ISOP") then
   tracername = "Isoprene"
 else if (tracer.eq."O3S") then
   tracername = "Strat O~B~3~N~"
 else if (tracer.eq."CO01") then
   tracername = "CO-fires"
 else if (tracer.eq."CO02") then
   tracername = "CO-anthro-N Amer"
 else if (tracer.eq."COnotNA") then
   tracername = "CO-anthro-not N Amer"
 else if (tracer.eq."BC") then
   tracername = "BC Aerosol"
 else if (tracer.eq."POM") then
   tracername = "POM Aerosol"
 else if (tracer.eq."SOA") then
   tracername = "SOA Aerosol"
 else if (tracer.eq."SO4") then
   tracername = "Sulfate Aerosol"
 else if (tracer.eq."DUST") then
   tracername = "Dust Aerosol"
 else if (tracer.eq."PM25") then
   tracername = "PM~B~2.5~N~"
 else if (tracer.eq."AODVISdn") then
   tracername = "AOD 550 nm"
 else if (tracer.eq."O3") then
   tracername = "O~B~3~N~"
 else if (tracer.eq."NOx") then
   tracername = "NO~B~x~N~"
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
 end if
 end if

   
;*******************************************
;--------------------------------------------
; load file and extract
;--------------------------------------------

  ; -------------------------------
  ; model load
  ; -------------------------------
    fin = addfiles(filename, "r")         ; read in
    ListSetType (fin, "cat")               ; concatenate

  ; -------------------------------
  ; model collect and convert
  ; -------------------------------
      if (tracer.eq."NOx") then
        tracer_dummy1 = fin[:]->NO2(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})        ; mol/mol
        tracer_dummy2 = fin[:]->NO(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})          ; mol/mol
        tracer_dummy = tracer_dummy1 +tracer_dummy2
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "NO + NO2 concentration"
      else if (tracer.eq."BC") then
        tracer_dummy1 = fin[:]->bc_a1(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})          ; kg/kg
        tracer_dummy2 = fin[:]->bc_a4(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})          ; kg/kg
        tracer_dummy = tracer_dummy1 +tracer_dummy2
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "bc_a1 + bc_4 concentration"
      else if (tracer.eq."POM") then
        tracer_dummy1 = fin[:]->pom_a1(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})          ; kg/kg
        tracer_dummy2 = fin[:]->pom_a4(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})          ; kg/kg
        tracer_dummy = tracer_dummy1 +tracer_dummy2
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "pom_a1+pom_a4 concentration"
      else if (tracer.eq."SOA") then
        tracer_dummy1 = fin[:]->soa1_a1(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})          ; kg/kg
        tracer_dummy2 = fin[:]->soa1_a2(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})          ; kg/kg
        tracer_dummy3 = fin[:]->soa2_a1(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})          ; kg/kg
        tracer_dummy4 = fin[:]->soa2_a2(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})          ; kg/kg
        tracer_dummy5 = fin[:]->soa3_a1(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})          ; kg/kg
        tracer_dummy6 = fin[:]->soa3_a2(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})          ; kg/kg
        tracer_dummy7 = fin[:]->soa4_a1(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})          ; kg/kg
        tracer_dummy8 = fin[:]->soa4_a2(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})          ; kg/kg
        tracer_dummy9 = fin[:]->soa5_a1(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})          ; kg/kg
        tracer_dummy10 = fin[:]->soa5_a2(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})         ; kg/kg
        tracer_dummy = tracer_dummy1+tracer_dummy2+tracer_dummy3+tracer_dummy4+tracer_dummy5 \
                       + tracer_dummy6+tracer_dummy7+tracer_dummy8+tracer_dummy9+tracer_dummy10
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "soa(1-5)_a1 + soa(1-5)_a2 concentration"
      else if (tracer.eq."SO4") then
        tracer_dummy1 = fin[:]->so4_a1(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})          ; kg/kg
        tracer_dummy2 = fin[:]->so4_a2(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})          ; kg/kg
        tracer_dummy3 = fin[:]->so4_a3(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})          ; kg/kg
        tracer_dummy = tracer_dummy1 +tracer_dummy2 +tracer_dummy3
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "SO4 concentration"

       else if (tracer.eq."DUST") then
        tracer_dummy1 = fin[:]->dst_a1(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})          ; kg/kg
        tracer_dummy2 = fin[:]->dst_a2(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})          ; kg/kg
        tracer_dummy3 = fin[:]->dst_a3(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})          ; kg/kg
        tracer_dummy = tracer_dummy1 +tracer_dummy2 +tracer_dummy3
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "DUST concentration"
       else if (tracer.eq."AODVISdn") then
         tracer_dummy = fin[:]->$tracer$(:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})         ; mol/mol or kg/kg
         tracer_dummy@units = ""
       else if (tracer.eq."COnotNA") then
        tracer_dummy1 = fin[:]->CO03(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})
        tracer_dummy2 = fin[:]->CO04(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})
        tracer_dummy3 = fin[:]->CO05(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})
        tracer_dummy4 = fin[:]->CO06(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})
        tracer_dummy5 = fin[:]->CO07(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})
        tracer_dummy6 = fin[:]->CO08(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})
        tracer_dummy7 = fin[:]->CO09(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})
        tracer_dummy = tracer_dummy1+tracer_dummy2+tracer_dummy3+tracer_dummy4+tracer_dummy5 \
                       + tracer_dummy6+tracer_dummy7
          copy_VarCoords(tracer_dummy1,tracer_dummy)
          copy_VarAtts(tracer_dummy1,tracer_dummy)
          tracer_dummy@long_name = "CO anthro all except N America"
      else
        tracer_dummy = fin[:]->$tracer$(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})         ; mol/mol or kg/kg
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if


     ; Collect into one array and convert units for output
     if (tracer_dummy@units.eq."kg/kg") then
      temp_k     = fin[:]->T(:,lev_limit_0:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})                  ;K 
      P0pa       = fin[0]->P0                 ;Pa
      Psurf      = fin[:]->PS(:,{lat_bound_0:lat_bound_1},{lon_bound_0:lon_bound_1})                 ;Pa
      hyam       = fin[0]->hyam(lev_limit_0:)
      hybm       = fin[0]->hybm(lev_limit_0:)
     press_pa = pres_hybrid_ccm(Psurf,P0pa,hyam,hybm)

     valCOLLECT = tracer_dummy*press_pa/temp_k/287.05535*1.e+09 ; kg/kg -> ug/m3
         copy_VarCoords(tracer_dummy,valCOLLECT)
         copy_VarAtts(tracer_dummy,valCOLLECT)
         valCOLLECT@units = "~F33~m~F21~g/m~S~3~N~"
	 
     else if (tracer_dummy@units.eq."mol/mol") then
         valCOLLECT = tracer_dummy*1.e9         ; mol/mol -> ppb
         copy_VarCoords(tracer_dummy,valCOLLECT)
         copy_VarAtts(tracer_dummy,valCOLLECT)
	 valCOLLECT@units = "ppb"

     else if (tracer_dummy@units.eq."kg/m3") then  ; PM25
         valCOLLECT = tracer_dummy*1.e9         ; kg/m3 -> ug/m3
         copy_VarCoords(tracer_dummy,valCOLLECT)
         copy_VarAtts(tracer_dummy,valCOLLECT)
         valCOLLECT@units = "~F33~m~F21~g/m~S~3~N~"
    
     else
     valCOLLECT = tracer_dummy              
         copy_VarCoords(tracer_dummy,valCOLLECT)
         copy_VarAtts(tracer_dummy,valCOLLECT)
     end if
     end if
     end if


     valCOLLECT@tracername = tracername
     if (tracer.eq."AODVISdn") then
       ;Do not add level units for species that do not have lev
     else
       ;Add level units
       valCOLLECT&lev@units = "hybrid_sigma_pressure"
     end if


  valOUT = valCOLLECT
  return(valOUT)


end

