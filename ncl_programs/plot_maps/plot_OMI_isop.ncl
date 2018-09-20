;=======================================================;
;  plot_OMI_isop.ncl
;=======================================================;
;
; Concepts illustrated:
;   - load OMI isoprene emission files
;   - plot map
;   - plot difference between avg and specific year
;   
;   To run type:
;         ncl plot_OMI_isop.ncl
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
  tracer = "ISOP"
  year = 2014
  repository = "OMI"

  ; -------------------------------
  ; emission files
  ; -------------------------------
  in_folder = "/IASI/home/hmw/BIOGENIC_CO/ISOPRENE/"

  e_files = systemfunc ("ls "+in_folder+"/*.nc")
print(e_files)

  ;------------
  ; toggles
  ;------------
  PLOT           = True
  TIMEPLOT       = False
  MONTHAVG       = True

  region_name =  "Australia"
      latmin                         = -45               ; zoom to Australia
      latmax                         = -10
      lonmin                         = 100
      lonmax                         = 160

    ;  latmin                         = 10               ; zoom to North America
    ;  latmax                         = 70
    ;  lonmin                         = 220
    ;  lonmax                         = 300

    ;  latmin                         = -40               ; zoom to Amazon
    ;  latmax                         = 10
    ;  lonmin                         = 270
    ;  lonmax                         = 330

    ;  latmin                         = -80               ; World
    ;  latmax                         = 80
    ;  lonmin                         = -170
    ;  lonmax                         = 185

;--------------------------------------------
; end user input
;--------------------------------------------

;********************************************
; set up
  ; -------------------------------
  ; names of fire emission structure
  ; -------------------------------
  emiss           = "EMworldC5H8"

  ; -------------------------------
  ; constants
  ; -------------------------------
   NAv = 6.022e23                    ; Avogadro's number, molecules mole^-1
   re   = 6.37122e06                 ; Earth radius (in metres)
   rad  = 4.0 * atan(1.0) / 180.0    ; Convert degrees to radians (pi radians per 180 deg)
   con  = re * rad                   ; constant for determining arc length 

  ; -------------------------------
  ; plotting parameters
  ; -------------------------------
  if (PLOT) then
    mapType = "png"
      mapType@wkWidth  = 1800
      mapType@wkHeight = 1800
    mapName = tracer+"_"+repository
  end if ;PLOT

  cr = "~C~"

;********************************************
; load files and extract
    fin = addfiles(e_files, "r")
        ListSetType (fin, "cat")      ; concatenate
    emiss_in          = fin[:]->$emiss$
    file1_time := emiss_in&time
    yyyymm = cd_calendar(file1_time,1)
    yfrac = cd_calendar(file1_time,4)
    dimE = dimsizes(file1_time)

    jan_arr = emiss_in(0:dimE-1:12,:,:)
    jan_avg = dim_avg_n(emiss_in,0)
      jan_avg!0 = "lat"
      jan_avg&lat = emiss_in&lat
      jan_avg!1 = "lon"
      jan_avg&lon = emiss_in&lon
    select = ind(yyyymm.eq.201001)
    diff_jan =  emiss_in(select,:,:) - jan_avg
      copy_VarMeta(jan_avg, diff_jan)

 
  ;********************************************
  ;-------------------
  ; MAP PLOT
  ;-------------------
  if (PLOT) then
    wks = gsn_open_wks(mapType,mapName)
    ;gsn_define_colormap(wks,"WhiteYellowOrangeRed")        ; change colour map
    ;gsn_define_colormap(wks,"MPL_Greys")        ; change colour map
    gsn_define_colormap(wks,"hotcolr_18lev")        ; change colour map
    ;-------------------
    ; define resources 
    ; to use for plotting
    ;-------------------
    mapres = True
    mapres@tiMainString              = ""                  ; changing main large title
    mapres@gsnLeftString             = ""                  ; change left 
  ;  mapres@gsnRightString            = emiss_diff@units    ; change right title
    mapres@gsnRightString            = "January 2010 isoprene emissions - 2005-2014 January average"                   ; change right title
    mapres@gsnMaximize               = True                   ; change right title
    mapres@gsnFrame                  = False               ; do not advance frame
    mapres@gsnDraw		     = False	           ; don't draw it yet
    mapres@mpGeophysicalLineThicknessF = 10

    mapres@gsnLeftStringFontHeightF  = 0.018
    mapres@gsnRightStringFontHeightF  = 0.018
    mapres@tmXBLabelFontHeightF        =0.018
    mapres@tmYLLabelFontHeightF        =0.018

    mapres@cnFillOn                  = True
    mapres@cnFillMode                = "CellFill"          ; fill as grid boxes not contours
    mapres@cnLineLabelsOn            = False               ; turn off countour labels
    mapres@cnLinesOn                 = False
    mapres@lbLabelBarOn              = True               ; turn off individual colorbars
    mapres@lbTitleString             = "kg"             ; Label Bar title
    mapres@lbOrientation             = "Vertical"     ; Label bar location
    mapres@lbTitleFontHeightF        = 0.018
    mapres@lbLabelFontHeightF        = 0.018

  mapres@tmXBBorderOn      = False
  mapres@tmXBOn            = False
  mapres@tmXTBorderOn      = False
  mapres@tmXTOn            = False
  mapres@tmYLBorderOn      = False
  mapres@tmYLOn            = False
  mapres@tmYRBorderOn      = False
  mapres@tmYROn            = False

    mapres@mpLimitMode               ="LatLon"            ; zoom to Australia
      mapres@mpMinLatF               = latmin
      mapres@mpMaxLatF               = latmax
      mapres@mpMinLonF               = lonmin
      mapres@mpMaxLonF               = lonmax
      ;mapres@mpCenterLonF            = 160

    mapres@cnLevelSelectionMode      = "ManualLevels"      ; manually set the contour levels
      mapres@cnMinLevelValF          = -0.6e07                ; set the minimum contour level
      mapres@cnMaxLevelValF          = 0.6e7                ; set the maximum contour level
      mapres@cnLevelSpacingF         = 0.5e06                ; set the interval between contours


    ;-------------------
    ; do the plotting
    ;-------------------
    panel_res                       = True
      panel_res@txString            = "CAM-chem "+ tracer +" emissions"
      panel_res@gsnPanelLabelBar    = True                ; add common colorbar

      ;mapres@gsnLeftString            = repository+" "+year+" "+tracer; change left title
    ;map1 = gsn_csm_contour_map_ce(wks,jan_avg,mapres)
    map1 = gsn_csm_contour_map_ce(wks,diff_jan,mapres)

    draw(map1)
    frame(wks)


  end if    ; PLOT



end

