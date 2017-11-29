;=======================================================;
;  redistribute_emiss.ncl
;=======================================================;
;
; Concepts illustrated:
;   - load CAM emission files
;   - split OC or BC into 2 files:
;           OC1 50%, OC2 50%
;           CB1 80%, CB2 20%
;   
;   To run type:
;         ncl redistribute_emiss.ncl
;
;   Requires:
;         emission file
;                                  RRB March 17, 2015
;=======================================================;
; load the libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------
    if (.not. isvar("year")) then      ; is year=<YYYY> from command line?
       year = 2017
    end if

    if (.not. isvar("tracer")) then    ; is tracer=<name> from command line?
       tracer = "BC"
    end if

    if (.not. isvar("NRT")) then    ; is NRT=<boolean> from command line?
         NRT = False
    end if

    if (.not. isvar("outres")) then    ; is outres=<name> from command line?
         outres = "0.94x1.2"
    end if

    if (.not. isvar("emiss_type")) then  ; is emiss_type=<name> from command line?
         emiss_type = "from_co2"         ; from_co, from_co2, regridded
    end if


  ; -------------------------------
  ; emission files
  ; -------------------------------
  top_dir = "/net/modeling1/data14b/buchholz/"
  emis_dir = top_dir+ "qfed/cam_"+outres+"/"+emiss_type+"/"

  if (NRT) then
    e_file_in = emis_dir+"nrt/qfed.emis_"+tracer+"_"+outres+"_mol_"+year+".nc"
    outpath = emis_dir+"nrt/"
  else
    e_file_in = emis_dir+year+"/qfed.emis_"+tracer+"_"+outres+"_mol_"+year+".nc"
    outpath = emis_dir+year+"/"
  end if

  ;------------
  ; toggles
  ;------------
  PLOT           = False
  netCDF         = True                       ; for netCDF output

;--------------------------------------------
; end user input
;--------------------------------------------

;********************************************
; set up
  ; -------------------------------
  ; names of data structures
  ; -------------------------------
  fire_emiss           = "bb"

  ; -------------------------------
  ; plotting parameters
  ; -------------------------------
  if (PLOT) then
    mapType = "x11"
    mapName = tracer+"_diff"
  end if ;PLOT

  cr = "~C~"

;********************************************
; load files and extract
    fin = addfile(e_file_in, "r")
      emiss_in         = fin->$fire_emiss$

;********************************************
; split into two files

  if (tracer.eq."OC") then
    emiss_split_1 = 0.5 * emiss_in
    emiss_split_2 = 0.5 * emiss_in
    new_names = (/"OC1","OC2"/)
  else if (tracer.eq."BC") then
    emiss_split_1 = 0.8 * emiss_in
    emiss_split_2 = 0.2 * emiss_in
    new_names = (/"CB1","CB2"/)
  end if
  end if

  new_emiss = (/emiss_split_1, emiss_split_2/)
      printVarSummary(emiss_in)

  ; sanity check
  ;check_split = emiss_split_1+emiss_split_1
  ;emiss_diff = emiss_in - check_split
  ;print(max(emiss_diff))

;********************************************
; Write out to an netCDF file
  if (netCDF) then
    do i = 0,dimsizes(new_names)-1
    ;-------------------
    ; create file for each 
    ; split CAM-chem species
    ;-------------------
      outfilename = "qfed.emis_"+new_names(i)+"_"+outres+"_mol_"+year+".nc"
      ; copy file to new file
      system("cp "+e_file_in+" "+outpath+outfilename)
      ; open the new file to overwrite
      fout = addfile(outpath+outfilename, "w")

      ;------------
      ; File 
      ; Attributes
      ;------------
     ; should have same file attributes as original emission file
     ; overwrite the title and date
        fout@creation_date      = systemfunc ("date")
        fout@title              = "Emissions of "+ new_names(i)+\
                                  " from FINN emission ratios applied to QFED CO2, daily"

       setfileoption(fout, "DefineMode",False)

      ;------------
      ; Variables
      ;------------
      bb_emissions := new_emiss(i,:,:,:)
        copy_VarAtts(emiss_in,bb_emissions)
        copy_VarCoords(emiss_in,bb_emissions)
        bb_emissions@long_name = new_names(i)+" QFED/FINN fire emissions"
        bb_emissions@vmax      := tofloat(max(bb_emissions))
        bb_emissions@vmin      := tofloat(min(bb_emissions))
      printVarSummary(bb_emissions)

       ;--- emissions
         fout->bb               = bb_emissions
    end do
  end if ;NetCDF


  ;********************************************
  ;-------------------
  ; MAP PLOT
  ;-------------------
  if (PLOT) then
    plot_ind = 0
    wks = gsn_open_wks(mapType,mapName)
    gsn_define_colormap(wks,"BlueWhiteOrangeRed")        ; change colour map
    ;-------------------
    ; define resources 
    ; to use for plotting
    ;-------------------
    mapres = True
    mapres@tiMainString              = ""                  ; changing main large title
    mapres@gsnLeftString             = ""                  ; change left 
  ;  mapres@gsnRightString            = emiss_diff@units    ; change right title
    mapres@gsnFrame                  = False               ; do not advance frame
    mapres@gsnDraw		     = False	           ; don't draw it yet

    mapres@cnFillOn                  = True
    mapres@cnFillMode                = "CellFill"          ; fill as grid boxes not contours
    mapres@cnLineLabelsOn            = False               ; turn off countour labels
    mapres@cnLinesOn                 = False
    mapres@lbLabelBarOn              = False               ; turn off individual colorbars


    mapres@cnLevelSelectionMode      = "ManualLevels"      ; manually set the contour levels
      mapres@cnMinLevelValF          = -5e10                ; set the minimum contour level
      mapres@cnMaxLevelValF          = 5e10                ; set the maximum contour level
      mapres@cnLevelSpacingF         = 5e09                ; set the interval between contours

    ;-------------------
    ; do the plotting
    ;-------------------
    panel_res                       = True
      panel_res@txString            = "CAM-chem "+ tracer +" scaled, "+ \
                                      cd_calendar(emiss_in&time(plot_ind),1)
      panel_res@gsnPanelLabelBar    = True                ; add common colorbar

      panel_res@gsnPanelFigureStrings = (/"Original","Scaled"/)
    map1 = gsn_csm_contour_map_ce(wks,emiss_in(plot_ind,:,:),mapres)

    map2 = gsn_csm_contour_map_ce(wks,bb_emissions(plot_ind,:,:),mapres)

   ;   mapres@gsnLeftString            = "global average difference = "+\
   ;                                      sprintf("%2.2f",PercDiff(plot_ind))+"%"   ; change left title
   ; map3 = gsn_csm_contour_map_ce(wks,emiss_diff(plot_ind,:,:),mapres)

    gsn_panel(wks,(/map1,map2/),(/2,1/),panel_res)


  end if    ; PLOT


end

