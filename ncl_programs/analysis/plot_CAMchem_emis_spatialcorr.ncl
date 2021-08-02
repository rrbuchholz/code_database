;=======================================================;
;  plot_CAMchem_spatialcorr.ncl
;=======================================================;
;
; Concepts illustrated:
;   - open CAM-chem
;   - read in variable
;   - select tracers
;   - perform spatial ratio
;
;   Files needed:
;         -CAM-chem tagged output in netCDF
;
;   To run type:
;         ncl  plot_CAMchem_tags 
;                                  RRB May 11, 2016
;=======================================================;
; load the libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------

  ; -------------------------------
  ; CAM-chem files
  ; -------------------------------

  infolder = "/glade/scratch/buchholz/archive/CAMchem_fmerra_e15/"
  ;file_prefix = "h0/fmerra.e15alpha.FSDSSOA.2deg.longrun.cam.h0."
  file_prefix = "meg/fmerra.e15alpha.FSDSSOA.2deg.longrun.clm2.h0."
  all_files := systemfunc ("ls "+infolder+file_prefix+"*.nc")

  ;infolder = "/glade/work/buchholz/emis/qfed2.4_finn_2000_2014_2x2/"
  ;all_files := infolder + "qfed.emis_CO_1.9x2.5_mol_2000_2014.nc"
  ;all_files2 := infolder + "qfed.emis_CH2O_1.9x2.5_mol_2000_2014.nc"

  daterange = "2005"
  tracername = "HCHO"

  ; -------------------------------
  ; CAM-chem file
  ; -------------------------------
  filenames = all_files

  ;------------
  ; plot definitions
  ;------------
    PLOT_MAP   = True
    plttype      = "x11"           ; pdf or png if want to save
    pltname      = "HCHO_CO"+daterange
    titlestring  = "Temporal correlations 2000-2014"
    left_string  = "2000 - 2014"

;--------------------------------------------
; end user input
;--------------------------------------------


;--------------------------------------------
; load file and extract
;--------------------------------------------

    ;tracer_array = (/"CO", "O3"/)
    ;tracer_array = (/"SFCO", "SFISOP"/)
    ;mw_array = (/28.01, 68.12/)
    ;plotlabel = "ISOP:CO"

    ;tracer_array = (/"SFCO", "SFCH2O"/)
    tracer_array = (/"MEG_carbon_monoxide", "MEG_formaldehyde"/)
    ;tracer_array = (/"bb", "bb"/)
    mw_array = (/28.01, 30.031/)
    mw_array = (/1, 1/)
    plotlabel = "HCHO:CO"

    ;tracer_array = (/"SFISOP", "SFCH2O"/)
    ;mw_array = (/68.12, 30.031/)
    ;plotlabel = "HCHO:ISOP"

  ; -------------------------------
  ; CAM-chem load
  ; -------------------------------
  ; names of data structures
  ; determined from a ncl_filedump
    fin = addfiles(filenames, "r")           ; read in
    ListSetType (fin, "cat")                 ; concatenate
print(fin)
      tracer1        = (fin[:]->$tracer_array(0)$)
      tracer2        = (fin[:]->$tracer_array(1)$)

    ;fin2 = addfiles(all_files2, "r")           ; read in
    ;ListSetType (fin, "cat")                 ; concatenate
    ;  tracer2        = (fin2[:]->$tracer_array(1)$)

     ; date           = fin[:]->$"date"$
      time           = fin[:]->$"time"$
      time_convert   = cd_calendar(time,0)
      month          = time_convert(:,1)
      lat            = tracer1&lat
      lon            = tracer1&lon

printVarSummary(tracer1)
;print(lat)
;print(lon)
;exit


djf_index = ind(month.eq.12.or.\
                month.eq.1.or.\
                month.eq.2)

mam_index = ind(month.eq.3.or.\
                month.eq.4.or.\
                month.eq.5)

jja_index = ind(month.eq.6.or.\
                month.eq.7.or.\
                month.eq.8)

son_index = ind(month.eq.9.or.\
                month.eq.10.or.\
                month.eq.11)

  ; -------------------------------
  ; compile seasonal tracer fields
  ; -------------------------------
  tracer1_djf = dim_avg_n(tracer1(djf_index,:,:),0)/mw_array(0)
    copy_VarCoords(tracer1(0,:,:),tracer1_djf)
    copy_VarAtts(tracer1(0,:,:),tracer1_djf)
    ;tracer1_djf@units = "mol/cm2/s"
    tracer1_djf@seas = "DJF"

  tracer2_djf = dim_avg_n(tracer2(djf_index,:,:),0)/mw_array(1)
    copy_VarCoords(tracer2(0,:,:),tracer2_djf)
    copy_VarAtts(tracer2(0,:,:),tracer2_djf)
    ;tracer2_djf@units = "mol/cm2/s"
    tracer2_djf@seas = "DJF"


  tracer1_mam = dim_avg_n(tracer1(mam_index,:,:),0)/mw_array(0)
    copy_VarCoords(tracer1(0,:,:),tracer1_mam)
    copy_VarAtts(tracer1(0,:,:),tracer1_mam)
    ;tracer1_mam@units = "mol/cm2/s"
    tracer1_mam@seas = "MAM"

  tracer2_mam = dim_avg_n(tracer2(mam_index,:,:),0)/mw_array(1)
    copy_VarCoords(tracer2(0,:,:),tracer2_mam)
    copy_VarAtts(tracer2(0,:,:),tracer2_mam)
    ;tracer2_mam@units = "mol/cm2/s"
    tracer2_mam@seas = "MAM"


  tracer1_jja = dim_avg_n(tracer1(jja_index,:,:),0)/mw_array(0)
    copy_VarCoords(tracer1(0,:,:),tracer1_jja)
    copy_VarAtts(tracer1(0,:,:),tracer1_jja)
    ;tracer1_jja@units = "mol/cm2/s"
    tracer1_jja@seas = "JJA"

  tracer2_jja = dim_avg_n(tracer2(jja_index,:,:),0)/mw_array(1)
    copy_VarCoords(tracer2(0,:,:),tracer2_jja)
    copy_VarAtts(tracer2(0,:,:),tracer2_jja)
    ;tracer2_jja@units = "mol/cm2/s"
    tracer2_jja@seas = "JJA"


  tracer1_son = dim_avg_n(tracer1(son_index,:,:),0)/mw_array(0)
    copy_VarCoords(tracer1(0,:,:),tracer1_son)
    copy_VarAtts(tracer1(0,:,:),tracer1_son)
    ;tracer1_son@units = "mol/cm2/s"
    tracer1_son@seas = "SON"

  tracer2_son = dim_avg_n(tracer2(son_index,:,:),0)/mw_array(1)
    copy_VarCoords(tracer2(0,:,:),tracer2_son)
    copy_VarAtts(tracer2(0,:,:),tracer2_son)
    ;tracer2_son@units = "mol/cm2/s"
    tracer2_son@seas = "SON"


;--------------------------------------------
; perform calculations
;--------------------------------------------

  ; -------------------------------
  ; correlations
  ; -------------------------------
  ccr_djf = escorc_n(tracer2(djf_index,:,:),tracer1(djf_index,:,:),0,0) 
    copy_VarCoords(tracer1(0,:,:),ccr_djf)
    ccr_djf@units = "Pearson's R"
    ccr_djf@seas = "DJF"
printVarSummary(ccr_djf)

  ccr_mam = escorc_n(tracer2(mam_index,:,:),tracer1(mam_index,:,:),0,0) 
    copy_VarCoords(tracer1(0,:,:),ccr_mam)
    ccr_mam@units = "Pearson's R"
    ccr_mam@seas = "MAM"

  ccr_jja = escorc_n(tracer2(jja_index,:,:),tracer1(jja_index,:,:),0,0) 
    copy_VarCoords(tracer1(0,:,:),ccr_jja)
    ccr_jja@units = "Pearson's R"
    ccr_jja@seas = "JJA"

  ccr_son = escorc_n(tracer2(son_index,:,:),tracer1(son_index,:,:),0,0) 
    copy_VarCoords(tracer1(0,:,:),ccr_son)
    ccr_son@units = "Pearson's R"
    ccr_son@seas = "SON"

  ; -------------------------------
  ; linear regression
  ; -------------------------------
  lin_djf = new((/dimsizes(lat),dimsizes(lon)/), float) 
  do i=0,dimsizes(lat)-1
    do j=0,dimsizes(lon)-1
      y:=tracer2(djf_index,i,j)
      x:=tracer1(djf_index,i,j)
      lin_djf(i,j) = regCoef(x,y)
    end do
  end do

    copy_VarCoords(tracer1(0,:,:),lin_djf)
    lin_djf@units = "Emission Ratio"
    lin_djf@seas = "DJF"

  lin_mam = new((/dimsizes(lat),dimsizes(lon)/), float)
  do i=0,dimsizes(lat)-1
    do j=0,dimsizes(lon)-1
      y:=tracer2(mam_index,i,j)
      x:=tracer1(mam_index,i,j)
      lin_mam(i,j) = regCoef(x,y)
    end do
  end do

    copy_VarCoords(tracer1(0,:,:),lin_mam)
    lin_mam@units = "Emission Ratio"
    lin_mam@seas = "MAM"

  lin_jja = new((/dimsizes(lat),dimsizes(lon)/), float)
  do i=0,dimsizes(lat)-1
    do j=0,dimsizes(lon)-1
      y:=tracer2(jja_index,i,j)
      x:=tracer1(jja_index,i,j)
      lin_jja(i,j) = regCoef(x,y)
    end do
  end do

    copy_VarCoords(tracer1(0,:,:),lin_jja)
    lin_jja@units = "Emission Ratio"
    lin_jja@seas = "JJA"

  lin_son = new((/dimsizes(lat),dimsizes(lon)/), float)
  do i=0,dimsizes(lat)-1
    do j=0,dimsizes(lon)-1
      y:=tracer2(son_index,i,j)
      x:=tracer1(son_index,i,j)
      lin_son(i,j) = regCoef(x,y)
    end do
  end do

    copy_VarCoords(tracer1(0,:,:),lin_son)
    lin_son@units = "Emission Ratio"
    lin_son@seas = "SON"


;--------------------------------------------
; plot
;--------------------------------------------
if (PLOT_MAP) then
    plots_vmr = new((/4/), graphic)
    plots_R = new((/4/), graphic)
    plots_EhR = new((/4/), graphic)

    wks = gsn_open_wks(plttype,pltname)        

   ;-----------------------
   ; Set resources for plotting
   ;----------------------- 
    res                       = True                      ; plot mods desired
      res@gsnDraw             = False	                  ; don't draw it yet
      res@gsnFrame            = False                     ; don't advance frame
      res@mpOutlineOn         = True
      res@mpGeophysicalLineThicknessF = 1.5
      res@gsnMaximize         = True  
      res@gsnAddCyclic        = True                     ; don't leave gap at meridian
      res@lbLabelBarOn        = False
      res@cnInfoLabelOn       = False           ; turn off cn info label
      res@cnLineLabelsOn       = False        ; Turn on contour line labels

      res@mpMonoFillColor     = True
      res@mpFillColor         = "Gray"

      res@tiMainString      = ""

      res@tiMainFontHeightF   = 0.022
      res@gsnLeftString       = "Years "+ left_string               ; add the gsn titles
      res@gsnRightStringFontHeightF = 0.020

      res@cnFillOn             = True
      res@cnLinesOn            = False
     ; res@lbLabelBarOn         = False

     ; res@cnLevelSelectionMode ="ExplicitLevels"
     ; res@cnLevels             = (/-1,-0.95,-0.9,-0.8,-0.75,-0.7,-0.6,\
     ;                             -0.5,-0.4,-0.3,-0.2,0,\
     ;                             0.2,0.3,0.4,0.5,0.6,\
     ;                             0.7,0.75,0.8,0.9,0.95, 1/)

      ; limit plotting region USA
      ;res@mpLimitMode         ="LatLon"
      ;  res@mpMinLatF         = 0
      ;  res@mpMaxLatF         = 60
      ;  res@mpMinLonF         = -150
      ;  res@mpMaxLonF         = -30

      ; limit plotting region Aus
      ;res@mpLimitMode         ="LatLon"
      ;  res@mpMinLatF         = -60
      ;  res@mpMaxLatF         = -10
      ;  res@mpMinLonF         = 110
      ;  res@mpMaxLonF         = 180


   ;-----------------------
   ; Plot tracer fields
   ;-----------------------
      res@cnFillPalette = "BlAqGrYeOrReVi200" 
      ;res@cnLevelSelectionMode = "ExplicitLevels" ; set explicit contour levels
      ; maxVal=220
      ; clevs=ispan(40,maxVal,10)
      ; res@gsnRightString  = tracer1_jja@seas +" CO " +tracer1_jja@units
      ;levels = clevs 
      ; maxVal=18
      ; clevs=ispan(1,maxVal,1)
      ; res@gsnRightString  = tracer2_jja@seas +" HCHO " +tracer2_jja@units
      ; levels = clevs*log(exp(clevs))/maxVal 


     ;res@cnLevels = sprintf("%6.2g", levels) ; set levels 
       res@gsnRightString  = tracer2_djf@seas +" "+tracername+" " +tracer2_djf@units
     plots_vmr(0)=gsn_csm_contour_map_ce(wks,tracer2_djf(:,:),res)  ; plot contours
       res@gsnRightString  = tracer2_mam@seas +" "+tracername+" " +tracer2_mam@units
     plots_vmr(1)=gsn_csm_contour_map_ce(wks,tracer2_mam(:,:),res)  ; plot contours
       res@gsnRightString  = tracer2_jja@seas +" "+tracername+" " +tracer2_jja@units
     plots_vmr(2)=gsn_csm_contour_map_ce(wks,tracer2_jja(:,:),res)  ; plot contours
       res@gsnRightString  = tracer2_son@seas +" "+tracername+" " +tracer2_son@units
     plots_vmr(3)=gsn_csm_contour_map_ce(wks,tracer2_son(:,:),res)  ; plot contours

   ;-----------------------
   ; Plot the correlation coefficients
   ;-----------------------
      res@cnFillPalette = "BlueWhiteOrangeRed" 
      res@cnLevelSelectionMode ="ManualLevels"
      res@cnMinLevelValF       = -1.
      res@cnMaxLevelValF       = 1.
      res@cnLevelSpacingF      = 0.1

    res@gsnRightString  = ccr_djf@seas +" "+plotlabel+" " +ccr_djf@units
     plots_R(0)=gsn_csm_contour_map_ce(wks,ccr_djf(:,:),res)  ; plot contours
    res@gsnRightString  = ccr_mam@seas +" "+plotlabel+" " +ccr_mam@units
     plots_R(1)=gsn_csm_contour_map_ce(wks,ccr_mam(:,:),res)  ; plot contours
    res@gsnRightString  = ccr_jja@seas +" "+plotlabel+" " +ccr_jja@units
     plots_R(2)=gsn_csm_contour_map_ce(wks,ccr_jja(:,:),res)  ; plot contours
    res@gsnRightString  = ccr_son@seas +" "+plotlabel+" " +ccr_son@units
     plots_R(3)=gsn_csm_contour_map_ce(wks,ccr_son(:,:),res)  ; plot contours

   ;-----------------------
   ; Plot the enhancement ratio
   ;-----------------------
  cmap = read_colormap_file("GHRSST_anomaly")
  colour_arr := (/cmap(4,:),cmap(5,:),cmap(6,:),cmap(7,:),cmap(8,:),\
                 cmap(21,:),cmap(18,:), cmap(13,:),cmap(14,:),cmap(16,:),cmap(17,:),\
                 cmap(24,:),cmap(25,:), cmap(26,:),cmap(27,:),cmap(28,:),cmap(29,:),\
                 cmap(30,:),cmap(31,:),cmap(32,:),cmap(33,:),cmap(34,:),cmap(35,:),\
                  cmap(36,:),cmap(37,:),cmap(38,:),cmap(39,:),cmap(40,:)/)
      res@cnFillPalette := "BlAqGrYeOrReVi200"

      res@cnLevelSelectionMode ="ManualLevels"
      res@cnMinLevelValF       = -0.015
      res@cnMaxLevelValF       = 0.045
      res@cnLevelSpacingF      = 0.0015

      ;res@cnLevelSelectionMode ="ManualLevels"
      ;res@cnMinLevelValF       = -0.25
      ;res@cnMaxLevelValF       = 1.5
      ;res@cnLevelSpacingF      = 0.05

    res@cnFillOpacityF         = 0.7

    ; mask by R
    lin_djf = where(abs(ccr_djf).lt.0.4, lin_djf@_FillValue, lin_djf)
    lin_mam = where(abs(ccr_mam).lt.0.4, lin_mam@_FillValue, lin_mam)
    lin_jja = where(abs(ccr_jja).lt.0.4, lin_jja@_FillValue, lin_jja)
    lin_son = where(abs(ccr_son).lt.0.4, lin_son@_FillValue, lin_son)

    res@gsnRightString  = lin_djf@seas +" "+plotlabel+" " +lin_djf@units
     plots_EhR(0)=gsn_csm_contour_map_ce(wks,lin_djf(:,:),res)  ; plot contours
    res@gsnRightString  = lin_mam@seas +" "+plotlabel+" " +lin_mam@units
     plots_EhR(1)=gsn_csm_contour_map_ce(wks,lin_mam(:,:),res)  ; plot contours
    res@gsnRightString  = lin_jja@seas +" "+plotlabel+" " +lin_jja@units
     plots_EhR(2)=gsn_csm_contour_map_ce(wks,lin_jja(:,:),res)  ; plot contours
    res@gsnRightString  = lin_son@seas +" "+plotlabel+" " +lin_son@units
     plots_EhR(3)=gsn_csm_contour_map_ce(wks,lin_son(:,:),res)  ; plot contours

  ; -------------------------------
  ; Panel plot the curtains
  ; -------------------------------
  panel_res                       = True

  ;panel_res@txPosYF               = 0.98
  ;panel_res@txPosXF               = 0.54
  ;panel_res@gsnPanelScalePlotIndex = 5
  panel_res@gsnPanelLabelBar = True
  ;panel_res@lbLabelFontHeightF =0.01
  ;panel_res@gsnPanelYF = (/0.89,0.89,0.61,0.61,0.32,0.32/)      ; Adjust bottommost plots.
  ;panel_res@gsnPanelTop = 0.95
  ;panel_res@gsnPanelBottom = 0.015
  ;panel_res@pmLabelBarOrthogonalPosF =-0.005
   ;panel_res@gsnPanelDebug =True
 
  panel_res@txString              = "Surface Emissions"
 gsn_panel(wks,plots_vmr,(/2,2/),panel_res)    ; will draw the plots 
  panel_res@txString              = titlestring
 gsn_panel(wks,plots_R,(/2,2/),panel_res)    ; will draw the plots
  panel_res@txString              = "Emission Ratios"
 gsn_panel(wks,plots_EhR,(/2,2/),panel_res)    ; will draw the plots


  ;draw(plots_R(0))
  ;frame(wks)

end if  ;PLOT_MAP


end

