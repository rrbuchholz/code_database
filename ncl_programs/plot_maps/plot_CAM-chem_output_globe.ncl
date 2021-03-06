;=======================================================;
;  plot_CAM-chem_output_maps.ncl.ncl
;=======================================================;
;
; Concepts illustrated:
;   - load CAM output files from automated diagnostic
;   
;   To run type:
;         ncl plot_CAM-chem_output_maps.ncl.ncl
;
;   Requires:
;         two emission files
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
  tracer = "CO"
  region = "Globe"
  timeslice = "August 2012-2018, QFED"

  ; Plot definitions
    units = "ppb"
    ;maxlev = 280.0
    ;minlev = 40.0
    ;lev_spacing = 10.0

    ;maxlev = 2.5
    ;minlev = 0.1
    ;lev_spacing = 0.1

    ;maxlev = 0.8
    ;minlev = -0.8
    ;lev_spacing = 0.04

    maxlev = 50.
    minlev = -50.
    lev_spacing = 2.5

   STATIONS = False

  ; -------------------------------
  ; file location
  ; -------------------------------
  ;in_folder = "/glade/scratch/buchholz/archive/fmerra.2.0.FCSD.1deg.chey200406.cmip.qfedBB_32L/atm/hist/"

  ;camfile_1 = systemfunc ("ls "+in_folder+"fmerra.2.0.FCSD.1deg.chey200406.cmip.qfedBB_32L.cam.h1.2014-08-15-00000.nc")
  ;camfile_1 = systemfunc ("ls "+in_folder+"fmerra.2.0.FCSD.1deg.chey200406.cmip.qfedBB_32L.cam.h0.2014-08.nc")

   ;dir_in = "/glade/scratch/tasullivan/archive/controlcomp/atm/hist/"
   ;dir2_in = "/glade/scratch/tasullivan/archive/nofire/atm/hist/"
   ;outpath = "/glade/work/buchholz/CAM_chem_output/maskfire_2018/"
   ;camfile_1 = systemfunc ("ls "+dir_in + "*h0*2018-08*.nc")
   ;camfile_2 = systemfunc ("ls "+dir2_in + "*h0*2018-08*.nc")

  ;dir_in = "/glade/scratch/buchholz/archive/fmerra.2.1003.FCSD.f09.qfedcmip.56L.001/atm/hist/"
  ;dir2_in = "/glade/scratch/buchholz/archive/fmerra.2.0.FCSD.1deg.chey200406.cmip.qfedBB_32L/atm/hist/"
   ;outpath = "/glade/work/buchholz/CAM_chem_output/maskfire_2018/"
   ;camfile_1 = systemfunc ("ls "+dir_in + "*h0*2014-08*.nc")
   ;camfile_2 = systemfunc ("ls "+dir2_in + "*h0*2014-08*.nc")

   ;dir_in ="/glade/scratch/shawnh/GEOS5_frcst_data_Beta/20200510/model_files/finn/"
   ;dir2_in = "/glade/scratch/shawnh/GEOS5_frcst_data_Beta/20200510/model_files/qfed/"
   ;outpath = "/glade/work/buchholz/CAM_chem_output/"
   ;camfile_1 = systemfunc ("ls "+dir_in + "*h3*2020-05-*.nc")
   ;camfile_2 = systemfunc ("ls "+dir2_in + "*h3*2020-05-*.nc")

   dir_in ="/glade/work/buchholz/CAM_chem_output/longrun_analysis/"
   outpath = "/glade/work/buchholz/CAM_chem_output/"
   camfile_1 = systemfunc ("ls "+dir_in + "CAMchem_Aug_qfed_avg_2002_2011.nc")
   camfile_2 = systemfunc ("ls "+dir_in + "CAMchem_Aug_qfed_avg_2012_2018.nc")
  


  ;------------
  ; toggles
  ;------------
  PLOT           = True


;--------------------------------------------
; end user input
;--------------------------------------------

;********************************************
; set up
   NAv = 6.022e23                    ; Avogadro's number, molecules mole^-1
  ; -------------------------------
  ; plotting parameters
  ; -------------------------------
  if (PLOT) then
    mapType = "x11"
    mapName = "~/"+tracer+"_"+region+"_"+timeslice
    mapType@wkWidth = 1200
    mapType@wkHeight = 1200 
  end if ;PLOT


  cr = "~C~"

;********************************************
;-------------------
; load files and extract
;-------------------

  if (units.eq."ppt") then
    divisor = 1e-12
  else if (units.eq."ppb".or.units.eq."ug/m3") then
    divisor = 1e-09
  else if (units.eq."kg/m2/sec") then
    divisor = 1
  else if (units.eq."aod".or.units.eq."K".or.units.eq."W/m2"\
           .or.units.eq."/s".or.units.eq."fraction") then
    divisor = 1
  end if
  end if
  end if
  end if
  fin = addfiles(camfile_1, "r")
  fin2 = addfiles(camfile_2, "r")
   if (tracer.eq."ISOPNITA") then
     tracer_fields_1_a  = fin[:]->$tracer$
     tracer_fields_1_b  = fin[:]->ISOPNITB
     tracer_fields_1 = tracer_fields_1_a + tracer_fields_1_b
     copy_VarMeta(tracer_fields_1_a,tracer_fields_1)
     tracer_fields_1= tracer_fields_1/divisor
   else
     tracer_fields_1  = fin[:]->$tracer$
     tracer_fields_1= tracer_fields_1/divisor
     tracer_fields_2  = fin2[:]->$tracer$
     tracer_fields_2= tracer_fields_2/divisor
   end if


;diff = (/tracer_fields_1-tracer_fields_2/)
diff = (/tracer_fields_2-tracer_fields_1/)
copy_VarMeta(tracer_fields_1,diff)

printVarSummary(tracer_fields_1)


;********************************************
  ;-------------------
  ; MAP PLOT
  ;-------------------
  if (PLOT) then
    wks = gsn_open_wks(mapType,mapName)
    ;gsn_define_colormap(wks,"BlAqGrYeOrRe")        ; change colour map
    gsn_define_colormap(wks,"GMT_haxby")        ; change colour map
    ;gsn_define_colormap(wks,"BlueWhiteOrangeRed")        ; change colour map
    ;-------------------
    ; define resources 
    ; to use for plotting
    ;-------------------
    mapres = True
    mapres@tiMainString              = ""                  ; changing main large title
    mapres@gsnFrame                  = False               ; do not advance frame
    mapres@gsnDraw		     = False	           ; don't draw it yet
    mapres@gsnMaximize               = True  

    mapres@gsnLeftStringFontHeightF  = 0.016
    mapres@gsnRightStringFontHeightF = 0.016

    mapres@mpProjection      = "Orthographic"       ; choose projection
    mapres@mpCenterLonF      = -90.             ; choose center lon
    mapres@mpCenterLatF      = 40.               ; choose center lat

    ;mapres@mpGridAndLimbOn        = True               ; turn on grid lines
    ;mapres@mpGridLatSpacingF       = 1.25
    ;mapres@mpGridLonSpacingF       = 0.925
    ;mapres@mpGridMaskMode         = "MaskNotOcean"     ; don't draw over land or
                                                  ; inland water bodies
    mapres@mpGridLineColor = "gray25"

    mapres@cnFillOn                  = True
    ;cmap = read_colormap_file("GMT_haxby")
    ;cmap = read_colormap_file("MPL_viridis")
    ;cmap = read_colormap_file("cmp_haxby")
    cmap = read_colormap_file("BlWhRe")
    ;cmap = read_colormap_file("BlueWhiteOrangeRed")
    ncolors = toint(dimsizes(cmap)-1)
    print(ncolors)

    mapres@cnFillColors      = cmap(9:ncolors(0):2,:)
    ;mapres@cnFillColors      = cmap(4:,:)
    ;mapres@cnFillColors      = cmap
    ;mapres@cnFillMode                = "CellFill"          ; fill as grid boxes not contours
    mapres@cnLineLabelsOn            = False               ; turn off countour labels
    mapres@cnLinesOn                 = False
    mapres@lbLabelBarOn              = True               ; turn off individual colorbars
    mapres@lbTitleString             = tracer+" ("+units+")"
    mapres@lbTitleFontHeightF        =0.012

    ;mapres@mpLimitMode               ="LatLon"            ; zoom to Australia
    ;  mapres@mpMinLatF               = latmin
    ;  mapres@mpMaxLatF               = latmax
    ;  mapres@mpMinLonF               = lonmin
    ;  mapres@mpMaxLonF               = lonmax
    ;  mapres@mpCenterLonF            = loncenter


    mapres@cnLevelSelectionMode      = "ManualLevels"      ; manually set the contour levels
      mapres@cnMinLevelValF          = minlev                  ; set the minimum contour level
      mapres@cnMaxLevelValF          = maxlev              ; set the maximum contour level
      mapres@cnLevelSpacingF         = lev_spacing         ; set the interval between contours

    ;-------------------
    ; do the plotting
    ;-------------------
    panel_res                       = True
      panel_res@gsnMaximize               = True  
      panel_res@txString            = ""
      panel_res@gsnPanelLabelBar    = False                ; add common colorbar
      mapres@gsnRightString        = ""
      mapres@tiMainString     = "CAM-chem surface "+ tracer + ", " +timeslice
      mapres@gsnLeftString     = ""
      ;mapres@gsnLeftString     = "CAM-chem surface ISOPNITA+B with Anthropogenic emissions " +timeslice

      mapres@cnFillPalette       = "BlAqGrYeOrRe"
    if (tracer.eq."MEG_ISOP".or.tracer.eq."AEROD_v"\
     .or.tracer.eq."AODVIS".or.tracer.eq."AODVISdn"\
     .or.tracer.eq."AODDUST".or.tracer.eq."FSNS"\
     .or.tracer.eq."FSDS".or.tracer.eq."FLDS"\
     .or.tracer.eq."CLDTOT") then
      map1 = gsn_csm_contour_map_ce(wks,tracer_fields_1(0,:,:),mapres)
    else
      ;map1 = gsn_csm_contour_map_ce(wks,tracer_fields_2(0,55,:,:),mapres)
      map1 = gsn_csm_contour_map_ce(wks,diff(0,50,:,:),mapres)
    end if


    draw(map1)
    frame(wks)

  end if    ; PLOT



end

