;=======================================================;
;  check_emiss.ncl
;=======================================================;
;
; Concepts illustrated:
;   - Load CAM-chem emission file
;   - Chem emissions present for a date
;                                  RRB November 28, 2017
;=======================================================;

begin
;--------------------------------------------
; user input
;--------------------------------------------
   if (.not. isvar("year")) then      ; is year=<value> from command line?
       year = 2018
    end if
   if (.not. isvar("YYYYMMDD")) then      ; is year=<value> from command line?
       YYYYMMDD = 20180101
    end if

  ratio_species = "co2"
  outres = "0.9x1.25"
  outpath = "/net/modeling1/data14b/buchholz/qfed/cam_"+outres+"/from_"+ratio_species+"/nrt/"
  emis_files = systemfunc ("ls "+outpath+"*"+year+".nc")

;--------------------------------------------
; end user input
;--------------------------------------------

;********************************************
; set up
  ; -------------------------------
  ; names of QFED data structures
  ; determined from an ncl_filedump
  ; -------------------------------
  fire_tracer        = "bb"
  fire_time          = "date"


;********************************************
; load files and extract
  check_array = new(dimsizes(emis_files), float)

  do tracer = 0,dimsizes(emis_files)-1
    fin := addfile(emis_files(tracer), "r")            ; read in
      bb_value = fin->$fire_tracer$
      datecompare = fin->$fire_time$

    ind_compare = ind(datecompare.eq.YYYYMMDD)         ; check current date
    emis_date = bb_value(ind_compare,:,:)

    if (any(emis_date.ne.0)) then                      ; determine if values present
       check_array(tracer) = 1
    else
       check_array(tracer) = 0
    end if
  end do

   val_check = sum(check_array)

    if (val_check.eq.dimsizes(emis_files)) then                      ; determine if values present
       proc_val = True
    else if (val_check.gt.0.and.val_check.lt.dimsizes(emis_files)) then 
       proc_val = "Warning"
    else
       proc_val = False
    end if
    end if

   print(proc_val)


end

