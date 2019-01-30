;=======================================================;
;  tag_emissions.ncl
;=======================================================;
;
; Concepts illustrated:
;   - load CAM emission files
;   - create zero emission everywhere except desired regions
;   - output new file as netCDF
; 
;       Acronym     Description
;     -----------------------------
;       AUST         Australasia
;       NZ           New Zealand
;       EQAS         Indonesia and Equatorial Asia
;       SEAS         Southeast Asia
;       INDI         India
;       NEAS         Northeast Asia
;       SIBR         Siberia
;       BOAS         West Russia and Boreal Asia
;       EURO         Europe
;       AFME         Northern Africa and Middle East
;       CWAS         Central-West Asia
;       NHAF         Northern Hemisphere Africa
;       SHAF         Southern Hemisphere Africa
;       BONA         Boreal North America
;       TENA         Temperate North America
;       CEAM         Central America
;       NHSA         Northern Hemisphere South America
;       AMAZ         Amazon
;       SHSA         Southern Hemisphere South America
;       SH           Southern Hemisphere
;       NH           Northern Hemisphere
;   
;   To run type:
;         ncl 'efile_in="<path_to_file>"' tag_emissions.ncl
;
;   Requires:
;         input emission file
;                                  RRB March 17, 2015
;                            RRB major edits 20180831
;=======================================================;
; load the libraries

begin

;--------------------------------------------
; user input
;--------------------------------------------
  tracer = "CO"
  type = "fire" ; anthro, fire, ocean

  ; -------------------------------
  ; emission files
  ; -------------------------------

  years = "2002_2017"
  base_dir = "/data14b/buchholz/"
  ;top_dir = base_dir + "qfed/cam_0.9x1.25/from_co2/v2.5/"
  top_dir = base_dir + "cmip6/cam_0.9x1.25/"
  ;top_dir = "/glade/work/buchholz/emis/qfed2.5_2014_2017_1x1/"
  if (.not. isvar("efile_in")) then        ; from command line?
       efile_in = top_dir + "allyears/qfed.emis_"+tracer+"_0.9x1.25_mol_"+years+".nc"
  end if
  print("Processing: "+ efile_in)

  outpath = base_dir + "tagged/"
  outfilepre = "finn.emis_"+tracer+"_0.9x1.25_mol_"+years
  ;------------
  ; toggles
  ;------------
  PLOT           = False
  PLOTREGIONS    = False
     WITHKOPPEN  = False
  netCDF         = True                       ; for netCDF output

;--------------------------------------------
; end user input
;--------------------------------------------

;********************************************
; set up
  ; -------------------------------
  ; names of data structures
  ; -------------------------------
  if (type.eq."fire") then 
    ;emiss           = "bb"
    emiss           = "fire"
  else if (type.eq."anthro") then 
    emiss           = "emiss_anthro"
  else if (type.eq."ocean") then 
    emiss            = "ocean"
  end if
  end if
  end if

  ; -------------------------------
  ; plotting parameters
  ; -------------------------------
  if (PLOT) then
    mapType = "x11"
    mapName = tracer+"_region"
  end if ;PLOT

  if (PLOTREGIONS) then
    mapType2 = "x11"
    mapName2 = tracer+"_regions"
  end if ;PLOT

  cr = "~C~"

  ; -------------------------------
  ; Define regions
  ; -------------------------------
   region_names = (/"AUST", "NZ", "EQAS", "SEAS","INDI", "NEAS", "SIBR", \
                    "BOAS", "EURO", "AFME","CWAS1", "CWAS2", "NHAF",\
                    "SHAF", "BONA", "TENA", "CEAM", "NHSA","AMAZ",\
                    "SHSA", "NH", "SH"/)

   ;                   minlat, maxlat, minlon, maxlon
   region_select = (/(/-50., -10.,       110.,     160./),\  ;AUST
                     (/-50., -30.,       160.,     181./),\  ;NZ
                     (/-10.,   8.,        90.,     160./),\  ;EQAS
                     (/  8.,  28.,        90.,     135./),\  ;SEAS
                     (/  4.,  35.,        60.,      90./),\  ;INDI
                     (/ 28.,  50.,        90.,     153./),\  ;NEAS
                     (/ 50.,  80.,        90.,     190./),\  ;SIBR
                     (/ 50.,  80.,        30.,      90./),\  ;BOAS
                     (/ 30.,  75.,   360.-25.,      30./),\  ;EURO
                     (/  0.,  30.,        35.,      60./),\  ;AFME
                     (/ 30.,  50.,        30.,      60./),\  ;CWAS1
                     (/ 35.,  50.,        60.,      90./),\  ;CWAS2
                     (/  0.,  30.,   360.-18.,      35./),\  ;NHAF
                     (/ -36.,  0.,    360.-1.,      60./),\  ;SHAF
                     (/ 50.,  75.,  360.-170., 360.-53./),\  ;BONA
                     (/ 27.,  50.,  360.-140., 360.-53./),\  ;TENA
                     (/  9.,  27.,  360.-120., 360.-40./),\  ;CEAM
                     (/  0.,   9.,   360.-90., 360.-30./),\  ;NHSA
                     (/-23.5,  -0.,  360.-90., 360.-30./),\  ;AMAZ
                     (/-60.,  -23.5, 360.-90., 360.-30./),\  ;SHSA
                     (/  0.,  90.,      0.,      360./),\    ;NH
                     (/-90.,   0.,      0.,      360./) /)   ;SH


   ;region_names := (/"KORE", "JAPN", "BONA","TENA", "AMAZ", "AUST", \
   ;                 "SEAS", "INDI", "CEAS","CEAM", "NEAS", "BOAS", \
   ;                 "EURO", "EQAS", "NHAF","SHAF", "NH", "SH"/)
   ; Ben's DEFS           minlat, maxlat, minlon, maxlon
   ;region_select := (/(/33.5, 38.,      125.,     129./),\  ;KORE
   ;                  (/ 30.,  44.,      130.,     146./),\  ;JAPN
   ;                  \;(/ 18.,  50.,       95.,     135.5/),\ ;EastAsia ;
   ;                  \;(/ 20.,  70.,      192.,     300./),\  ;NAM
   ;                  \;(/ 23.,  50.,      192.,     300./),\  ;CONUS
   ;                  \;(/ 50.,  70.,      192.,     300./),\  ;Canada
   ;                  (/ 50.,  75.,      192.,     310./),\  ;BONA
   ;                  (/ 27.,  50.,      192.,     310./),\  ;TENA
   ;                  (/-25.,   8.5,     275.,     325./),\  ;AMAZ
   ;                  (/-45.,  -9.,      110,      160./),\  ;AUST
   ;                  (/  7.,  28.,       91.,     135.5/),\ ;SEAS
   ;                  (/  7.,  32.,       60.,      90./),\  ;INDI
   ;                  (/ 29.,  49.,       91.,     135.5/),\ ;CEAS
   ;                  (/  9.,  27.,      240.,     310./),\  ;CEAM
   ;                  (/ 39.,  49.,       91.,     129.5/),\ ;NEAS
   ;                  (/ 50.,  75.,       40.,     190./),\  ;BOAS
   ;                  (/ 30.,  75.,      335.,      40./),\  ;EURO
   ;                  \;(/-10.,   8.,       95.,     120./),\  ;Indonesia
   ;                  (/-10.,  6.,       95.,     160./),\  ;EQAS
   ;                  \;(/-45., -10.,      110.,     162./),\  ;Australasia
   ;                  \;(/-35.,  30.,      335.,      50./),\  ;Africa
   ;                  (/  0.,  30.,      335.,      50./),\  ;NHAF
   ;                  (/-35.,   0.,      335.,      50./),\  ;SHAF
   ;                  \;(/-22.,   8.5,     275.,     325./),\  ;Amazon
   ;                  (/  0.,  90.,       0.,      360./),\    ;NH
   ;                  (/-90.,   0.,       0.,      360./) /)   ;SH


   n_regions = dimsizes(region_select(:,0))


;********************************************
; load files, extract and tag
;********************************************
    fin = addfile(efile_in, "r")
      emiss_in         = fin->$emiss$

  ; separate into regions
  ; loop through regions
  do ireg = 0,n_regions-1
      region = region_names(ireg)
      latmin = region_select(ireg,0)
      latmax = region_select(ireg,1)
      lonmin = region_select(ireg,2)
      lonmax = region_select(ireg,3)

     emiss_region := emiss_in

   ; -----------------------------------------------------
   ; determine indices for outside regions and set to zero
   if (region.eq."NH") then
     ; Latitudes outside region
     ind_lat_region_2 := ind(emiss_in&lat.lt.latmin)
     ; overwrite outside region with zeros
     emiss_region(:,ind_lat_region_2,:) = 0

   else if (region.eq."SH") then
     ; Latitudes outside region
     ind_lat_region_1 := ind(emiss_in&lat.ge.latmax)
     ; overwrite outside region with zeros
     emiss_region(:,ind_lat_region_1,:) = 0
   else if (region.eq."CWAS1") then ; combine 2 regions
      region = "CWAS"
      latmin2 = region_select(ireg+1,0)
      latmax2 = region_select(ireg+1,1)
      lonmin2 = region_select(ireg+1,2)
      lonmax2 = region_select(ireg+1,3)
     ; Latitudes outside region 1 and 2
     ind_lat_region_1 := ind(emiss_in&lat.ge.latmax)
     ind_lat_region_2 := ind(emiss_in&lat.lt.latmin)
     ind_lat_region_3 := ind(emiss_in&lat.lt.latmin2)
     ; Longitudes outside region 1 and 2
     ind_lon_region_1 := ind(emiss_in&lon.lt.lonmin)
     ind_lon_region_2 := ind(emiss_in&lon.ge.lonmax2)
     ind_lon_region_3 := ind(emiss_in&lon.ge.lonmin2.and.emiss_in&lon.le.lonmax2)

     emiss_region(:,ind_lat_region_1,:) = 0
     emiss_region(:,ind_lat_region_2,:) = 0
     emiss_region(:,:,ind_lon_region_1) = 0
     emiss_region(:,:,ind_lon_region_2) = 0
     emiss_region(:,ind_lat_region_3,ind_lon_region_3) = 0  ; remove small square
   else if (region.eq."CWAS2") then 
      ; do nothing
      continue
   else
     ; Latitudes outside region
     ind_lat_region_1 := ind(emiss_in&lat.ge.latmax)
     ind_lat_region_2 := ind(emiss_in&lat.lt.latmin)
     ; Longitudes outside region
     ind_lon_region_1 := ind(emiss_in&lon.lt.lonmin)
     ind_lon_region_2 := ind(emiss_in&lon.ge.lonmax)
     ; issues spanning 360 if not in 360-lon format
     if (region.eq."NHAF".or.\
         region.eq."SHAF".or.\
         region.eq."EURO") then
       ind_lon_region_1 := ind(emiss_in&lon.lt.lonmin.and.emiss_in&lon.ge.lonmax)
       ind_lon_region_2 := ind(emiss_in&lon.ge.lonmax.and.emiss_in&lon.lt.lonmin)
     end if

     ; overwrite outside region with zeros
     emiss_region(:,ind_lat_region_1,:) = 0
     emiss_region(:,ind_lat_region_2,:) = 0
     emiss_region(:,:,ind_lon_region_1) = 0
     emiss_region(:,:,ind_lon_region_2) = 0
   end if
   end if
   end if
   end if

   ; -----------------------------------------------------
   ; collect region outlines for plotting later
     region_lon := region_select(:,0:1)
     region_lat := region_select(:,2:3)


  ;********************************************
  ; Write out to an netCDF file
  if (netCDF) then
    ;-------------------
    ; create file for each region
    ;-------------------
      outfilename = outfilepre+"_"+region+".nc"
      ; copy file to new file
      system("cp "+efile_in+" "+outpath+outfilename)
      ; open the new file to overwrite
      fout = addfile(outpath+outfilename, "w")

      ;------------
      ; File 
      ; Attributes
      ;------------
     ; will have same file attributes as original emission file
     ; overwrite the title and date
        fout@creation_date      = systemfunc ("date")
        fout@title              = "Emissions of "+ tracer+" over "+region+\
                                  " from FINN emission ratios applied to QFED CO2, daily"

       setfileoption(fout, "DefineMode",False)

      ;------------
      ; Variables
      ;------------
      emiss_out := emiss_region
        copy_VarAtts(emiss_in,emiss_out)
        copy_VarCoords(emiss_in,emiss_out)
        emiss_out@long_name = tracer+" "+type+" emissions over "+region
        emiss_out@vmax      = max(emiss_out)
        emiss_out@vmin      = min(emiss_out)
      printVarSummary(emiss_out)

       ;--- overwrite emissions
         fout->$emiss$          = emiss_out

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
    mapres@gsnLeftString             = region              ; change left 
    mapres@gsnFrame                  = False               ; do not advance frame
    mapres@gsnDraw		     = False	           ; don't draw it yet
    ;-------------------
    ; do the plotting
    ;-------------------
    ;map1 = gsn_csm_map(wks,mapres)                          ; draw a blank map

    ;-------------------
    ; draw emissions
    ;-------------------
    mapres@cnFillOn                  = True
    mapres@cnFillMode                = "CellFill"          ; fill as grid boxes not contours
    mapres@cnLineLabelsOn            = False               ; turn off countour labels
    mapres@cnLinesOn                 = False


    mapres@cnLevelSelectionMode      = "ManualLevels"      ; manually set the contour levels
      ;mapres@cnMinLevelValF          = -5e10                ; set the minimum contour level
      ;mapres@cnMaxLevelValF          = 5e10                ; set the maximum contour level
      ;mapres@cnLevelSpacingF         = 5e09                ; set the interval between contours
      mapres@cnMinLevelValF          = -5e11                ; set the minimum contour level
      mapres@cnMaxLevelValF          = 5e11                ; set the maximum contour level
      mapres@cnLevelSpacingF         = 5e10                ; set the interval between contours

    map2 = gsn_csm_contour_map_ce(wks,emiss_region(0,:,:),mapres)


    ;-------------------
    ; draw region boxes
    ;-------------------
    boxres = True
      boxres@gsLineColor      = "black"
      boxres@gsLineThicknessF = 5

   ;                                   longitude                            latitudes  
    temp = gsn_add_polyline(wks,map2,(/lonmin, lonmin, lonmax , lonmax, lonmin/),(/latmin, latmax, latmax , latmin, latmin/),boxres)


    draw(map2)
    frame(wks)

    end if    ; PLOT
  end do ; LOOP THROUGH REGIONS


  ;-------------------
  ; MAP PLOT
  ;-------------------
  if (PLOTREGIONS) then
    wks2 = gsn_open_wks(mapType2,mapName2)
    ;-------------------
    ; define resources 
    ; to use for plotting
    ;-------------------
    mapres = True
    mapres@tiMainString              = ""                 ; changing main large title
    mapres@gsnLeftString             = ""                 ; change left 
    mapres@gsnFrame                  = False              ; do not advance frame
    mapres@gsnDraw		     = False	          ; don't draw it yet
    mapres@mpCenterLonF              =10

    ;-------------------
    ; do the plotting
    ;-------------------

   if (WITHKOPPEN) then

    koppen_class = (/"Af", "Am", "As", "Aw", "BWh", "BWk", "BSh", "BSk", "Csa", "Csb", "Csc", \
                     "Cwa", "Cwb", "Cwc", "Cfa", "Cfb", "Cfc", "Dsa", "Dsb", "Dsc", "Dsd", "Dwa",\
                     "Dwb", "Dwc", "Dwd", "Dfa", "Dfb", "Dfc", "Dfd", "ET", "EF"/)

    koppen_colors = (/"blue", "dodgerblue1", "steelblue2", "lightskyblue", "red2", "pink1", "orange", "lightgoldenrod2",\
                      "yellow", "yellow3", "yellow4","seagreen1", "seagreen3", "forestgreen", "darkolivegreen1",\
                      "green", "limegreen", "maroon1", "maroon3", "maroon4", "mediumorchid", "mediumpurple",\
                      "royalblue", "darkslateblue", "navy", "cyan", "lightblue2", \
                      "darkslategray4", "darkslategray", "gray", "dimgray"/)

    koppen_levels = (/0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30/)

    ; ----------------------------------------
    ; Load data 1
    ; ----------------------------------------
    ;---Read the values in as 1D, since we don't know rows and columns yet.
      lines  = asciiread("/gpfs/u/home/buchholz/data/koppen_30year_1901-2010.tsv",-1,"string")
      delim  = "	"        ; tab delimeted file
      ncols  = dimsizes(str_split(lines(0),delim))
      nlines = dimsizes(lines)-1         ; header

    ;---Reshape as 2D array, and convert to float for ppm/ppb.
      fields = new((/nlines,ncols/),string)
       do nf=0,ncols-1                    ;Remember that fields start at 1, not 0.
         fields(:,nf) = str_get_field(lines(1:),nf+1,delim)
       end do
       lon_koppen = tofloat(fields(:,0))
       lat_koppen = tofloat(fields(:,1))
       type_koppen = fields(:,dimsizes(fields(0,:))-1)
       numeric_koppen = new(dimsizes(type_koppen), float)
       do t=0,dimsizes(koppen_class)-1
         print(koppen_class(t)+"="+t)
         numeric_koppen = where(type_koppen.eq.koppen_class(t),t,numeric_koppen)
       end do
  ;print("************************************************")     
  ;print("Min "+min(lon_koppen)+", to Max "+max(lon_koppen))
  ;print("Min "+min(lat_koppen)+", to Max "+max(lat_koppen))

   newlon  = fspan(-179.75,179.75, 720)
     newlon@units      = "degrees_east"
     newlon@long_name  = "longitude"
     newlon!0          = "lon"
     newlon&lon        = newlon
   newlat  = fspan(-89.75,89.75, 360)
     newlat@units      = "degrees_north"
     newlat@long_name  = "latitude"
     newlat!0          = "lat"
     newlat&lat        = newlat

    gridded_koppen = new((/dimsizes(newlat),dimsizes(newlon)/), float)
     gridded_koppen!0          = "lat"
     gridded_koppen&lat        = newlat
     gridded_koppen!1          = "lon"
     gridded_koppen&lon        = newlon


    do n=0,dimsizes(numeric_koppen)-1
    ;do n=0,500
      gridded_koppen({lat_koppen(n)},{lon_koppen(n)})=(/numeric_koppen(n)/)
    end do

    mapres@cnFillOn                  = True
    mapres@cnFillMode                = "CellFill"          ; fill as grid boxes not contours
    mapres@cnLineLabelsOn            = False               ; turn off countour labels
    mapres@cnLinesOn                 = False
    mapres@cnLevelSelectionMode      = "Explicit"      ; manually set the contour levels
      mapres@cnLevels                = koppen_levels   ; set the contour levels
      mapres@cnFillColors            = koppen_colors
      mapres@cnLevelSpacingF         = 1         ; set the interval between contours
   mapres@lbLabelStrings             = koppen_class 
   mapres@lbLabelFontHeightF         = 0.01
   mapres@lbLabelPosition            = "Bottom"
   mapres@lbLabelAlignment           = "BoxCenters"
   mapres@pmLabelBarWidthF           = 1.  
   mapres@lbTitleString              = "Koeppen Land Class"
   mapres@lbTitlePosition            = "Bottom"
   mapres@lbTitleFontHeightF         = 0.015
   mapres@lbBoxLinesOn               = False

    map1 = gsn_csm_contour_map_ce(wks2,gridded_koppen,mapres)


   else 
    map1 = gsn_csm_map(wks2,mapres)                          ; draw a blank map
   end if


    txres = True
      txres@txFontHeightF = 0.01                     ; font smaller. default big
      txres@txFontThicknessF = 10.
      txres@txFontColor = "black"
      txres@txBackgroundFillColor = "white"
      txres@txPerimSpaceF = 0.2

    do i=0,n_regions-3
      if (region_names(i).eq."SHAF".or.region_names(i).eq."NHAF"\
          .or.region_names(i).eq."EURO") then 
        dum = gsn_add_text(wks2,map1,region_names(i),10,\
                         (region_select(i,0)+region_select(i,1))/2,txres)
      else if (region_names(i).eq."CWAS1") then 
        dum = gsn_add_text(wks2,map1,"CWAS",region_select(i,3),\
                         (region_select(i,0)+region_select(i,1))/2+2,txres)
      else if (region_names(i).eq."CWAS2") then 
        ; do nothing
        continue
      else 
        dum = gsn_add_text(wks2,map1,region_names(i),(region_select(i,2)+region_select(i,3))/2,\
                           (region_select(i,0)+region_select(i,1))/2,txres)
      end if
      end if
      end if
    end do

     draw(map1)

    ;-------------------
    ; draw region boxes
    ;-------------------
    boxres = True
      boxres@gsLineColor      = "black"
      boxres@gsLineThicknessF = 5

      do j=0,n_regions-3
       if (region_names(j).eq."CWAS1".or.region_names(j).eq."CWAS2") then 
         continue
       else
         regions_lon := (/region_select(j,2), region_select(j,2), \
                          region_select(j,3) , region_select(j,3), \
                          region_select(j,2)/)
         regions_lat := (/region_select(j,0), region_select(j,1), \
                          region_select(j,1) , region_select(j,0), \
                          region_select(j,0)/)
         gsn_polyline(wks2,map1,regions_lon,regions_lat,boxres)
       end if
      end do


    frame(wks2)
   end if ; PLOTREGIONS

end

