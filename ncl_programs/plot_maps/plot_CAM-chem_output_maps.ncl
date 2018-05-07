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
  tracer = "O3"

  ; -------------------------------
  ; file location
  ; -------------------------------
  in_folder = "/glade2/work/buchholz/CAM_chem_output/anth_v_noanth/"

  camfile_1 = systemfunc ("ls "+in_folder+"/anth/*ANN*.nc")

  camfile_2 = systemfunc ("ls "+in_folder+"/noanth/*ANN*.nc")

  camfile_3 = systemfunc ("ls "+in_folder+"/diff/*ANN*.nc")


  ;------------
  ; toggles
  ;------------
  PLOT           = True


  region_name =  "World"
    ; latmin                         = -45               ; zoom to Australia
    ;  latmax                         = -10
    ;  lonmin                         = 100
    ;  lonmax                         = 160

    ; latmin                         = 20               ; zoom to North America
    ;  latmax                         = 60
    ;  lonmin                         = 220
    ;  lonmax                         = 300

    ;  latmin                         = -40               ; zoom to Amazon
    ;  latmax                         = 10
    ;  lonmin                         = 270
    ;  lonmax                         = 330

      latmin                         = -90               ; zoom to World
      latmax                         = 90
      lonmin                         = 0
      lonmax                         = 360


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
    mapName = tracer+"_diff"
    mapType@wkWidth = 800
    mapType@wkHeight = 1000 
  end if ;PLOT


  cr = "~C~"

;********************************************
; load files and extract
  fin = addfiles(camfile_1, "r")
   tracer_fields_1  = fin[:]->$tracer$

  fin2 = addfiles(camfile_2, "r")
   tracer_fields_2  = fin2[:]->$tracer$

  fin3 = addfiles(camfile_3, "r")
   tracer_fields_3  = fin3[:]->$tracer$
glob_avg = dim_avg_n(tracer_fields_1(:,:,{0:70},{220:300}), (/2,3/))
glob_avg_array = conform_dims(dimsizes(tracer_fields_1),glob_avg,(/0,1/))
  test = (tracer_fields_1-tracer_fields_2)/glob_avg_array
  ;lonFlip(test)
  copy_VarAtts(tracer_fields_1, test)
  copy_VarCoords(tracer_fields_1, test)

printVarSummary(tracer_fields_1)
printVarSummary(test)

  ;********************************************
  ;-------------------
  ; MAP PLOT
  ;-------------------
  if (PLOT) then
    wks = gsn_open_wks(mapType,mapName)
    gsn_define_colormap(wks,"BlAqGrYeOrRe")        ; change colour map
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
    mapres@gsnMaximize               = True  


    mapres@gsnLeftStringFontHeightF  = 0.015
    mapres@gsnRightStringFontHeightF  = 0.015

    mapres@cnFillOn                  = True
    mapres@cnFillMode                = "CellFill"          ; fill as grid boxes not contours
    mapres@cnLineLabelsOn            = False               ; turn off countour labels
    mapres@cnLinesOn                 = False
    mapres@lbLabelBarOn              = True               ; turn off individual colorbars

    mapres@mpLimitMode               ="LatLon"            ; zoom to Australia
      mapres@mpMinLatF               = latmin
      mapres@mpMaxLatF               = latmax
      mapres@mpMinLonF               = lonmin
      mapres@mpMaxLonF               = lonmax

    mapres@cnLevelSelectionMode      = "ManualLevels"      ; manually set the contour levels
      mapres@cnMinLevelValF          = 0e-08                ; set the minimum contour level
      mapres@cnMaxLevelValF          = 4e-08                ; set the maximum contour level
      mapres@cnLevelSpacingF         = 2e-09                ; set the interval between contours

      ;mapres@cnMinLevelValF          = 0                 ; set the minimum contour level
      ;mapres@cnMaxLevelValF          = 1e13                ; set the maximum contour level
      ;mapres@cnLevelSpacingF         = 5e11                ; set the interval between contours


    ;-------------------
    ; do the plotting
    ;-------------------
    panel_res                       = True
      panel_res@txString            = "CAM-chem "+ tracer
      panel_res@gsnPanelLabelBar    = False                ; add common colorbar
     ; panel_res@gsnFrame          = False             ; don't advance frame yet
     ; panel_res@gsnDraw           = False             ; draw later, in maximize mode

      mapres@cnFillPalette       = "BlAqGrYeOrRe"
    map1 = gsn_csm_contour_map_ce(wks,tracer_fields_1(0,55,:,:),mapres)
    map2 = gsn_csm_contour_map_ce(wks,tracer_fields_2(0,55,:,:),mapres)


     mapres@cnFillPalette       = "BlueDarkRed18"
     mapres@cnMinLevelValF          = -1.              ; set the minimum contour level
     mapres@cnMaxLevelValF          = 1.               ; set the maximum contour level
     mapres@cnLevelSpacingF         = 0.1                ; set the interval between contours
    map3 = gsn_csm_contour_map_ce(wks,test(0,55,:,:),mapres)


    gsn_panel(wks,(/map1,map2,map3/),(/3,1/),panel_res)
    ;draw(map3)
    ;frame(wks)

  end if    ; PLOT



end

