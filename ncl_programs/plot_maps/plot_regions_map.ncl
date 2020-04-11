;=======================================================;
;  plot_regions_map.ncl
;=======================================================;
;
; Concepts illustrated:
;   - plot a map with overlayed boxed showing selected regions
; 
;   To run type:
;         ncl 'plot_regions_map.ncl
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
  type = "fire"

  ; -------------------------------
  ; emission files
  ; -------------------------------

  years = "2000_2018"
  top_dir = "/data14b/buchholz/qfed/cam_0.9x1.25/from_co2/v2.5/"
  ;top_dir = "/glade/work/buchholz/emis/qfed2.5_2014_2017_1x1/"
  if (.not. isvar("efile_in")) then        ; is NRT=<boolean> from command line?
       efile_in = top_dir + "allyears/qfed.emis_"+tracer+"_0.9x1.25_mol_"+years+".nc"
  end if
  print("Processing: "+ efile_in)

  outpath = top_dir + "tagged/"
  outfilepre = "qfed.emis_"+tracer+"_0.9x1.25_mol_"+years
  ;------------
  ; toggles
  ;------------
  PLOTREGIONS    = True
     WITHKOPPEN  = False
     WITHCO      = False

;--------------------------------------------
; end user input
;--------------------------------------------

;********************************************
; set up
  ; -------------------------------
  ; plotting parameters
  ; -------------------------------
    ;  latmin                         = -80.               ; World
    ;  latmax                         = 80.
    ;  lonmin                         = -170.
    ;  lonmax                         = 185.
      ;centerlon                      = 0

    ;  latmin                         =-50               ; zoom to Indonesia
    ;  latmax                         = 30
    ;  lonmin                         = 70
    ;  lonmax                         = 190

    ;  latmin                         = -25.               ; NH
    ;  latmax                         = 80.
    ;  lonmin                         = 30.
    ;  lonmax                         = 360.
    ;  centerlon                      = 180

      latmin                         = 20.               ; USA
      latmax                         = 70.
      lonmin                         = -150.
      lonmax                         = -70.

    ;  latmin                         = 30.               ; Boreal Asia
    ;  latmax                         = 70.
    ;  lonmin                         = 80.
    ;  lonmax                         = 150.

  if (PLOTREGIONS) then
    mapType2 = "x11"
    mapName2 = tracer+"_regions"
  end if ;PLOT

  cr = "~C~"

  ; -------------------------------
  ; Define regions
  ; -------------------------------
   ;region_names = (/"Buchholz et al. MSEA", "Buchholz et al. N.Aus", "CONTRAIL avg","New MSEA"/)
   ;                   minlat, maxlat, minlon, maxlon
   ;region_select = (/(/-10.,  10.,        90.,     160./),\  ;MSEA
   ;                  (/-25., -10.,       110.,     180./),\  ;N Aus
   ;                  (/-25., -10.,       145.,     151.5/),\  ;CONTRAIL avg
   ;                  (/-10.,  10.,       141.5,     151.5/)/)  ;New MSEA

   ;region_names = (/"BBCanada", "BBSiberia", "Nino3.4", "DMI","DMI2", "TNA", "AO"/)

   ;                   minlat, maxlat, minlon, maxlon
   ;region_select = (/(/ 50.,  60.,     -125.,      -90./),\  ;BBCanada
   ;                  (/ 50.,  60.,       90.,      140./),\  ;Siberia
   ;                  (/ -5.,  5.,       -170.,     -120./),\ ;NINO3.4
   ;                  (/ -10.,  10.,      50.,      70./),\ ;DMI
   ;                  (/ -10.,  0.,       90.,      110./),\ ;DMI2
   ;                  (/ 5.,  25.,       -55.,      -15./), \ ;TNA
   ;                  (/ 70.,  70.25,     120.,    240./)/) ;AO

   ;region_names = (/"AnthChina", "AnthIndi", "AnthEuro", "AnthUSA",\
   ;                 "BBUSA", "BBCanada", "BBSiberia", "BBWRus",\
   ;                 "BBCAmerica", "BBSAmerica","BBSAmOcean",\
   ;                  "BBCAfrica", "BBSAfrica","BBSAfOcean", \
   ;                 "BBMSEA", "BBNWAu","BBEAu", "NH", "SH"/)

   ;                   minlat, maxlat, minlon, maxlon
   ;region_select = (/(/ 30.,  40.,      110.,      123./),\  ;AnthChina
   ;                  (/ 20.,  30.,       70.,       95./),\  ;AnthIndi
   ;                  (/ 45.,  55.,        0.,       15./),\  ;AnthEuro
   ;                  (/ 35.,  40.,      -95.,      -75./),\  ;AnthUSA
   ;                  (/ 38.,  50.,     -125.,     -105./),\  ;BBUSA
   ;                  (/ 50.,  60.,     -125.,      -90./),\  ;BBCanada
   ;                  (/ 50.,  60.,       90.,      140./),\  ;BBSiberia
   ;                  (/ 35.,  50.,       40.,       85./),\  ;BBWRus
   ;                  (/ 10.,  23.5,    -105.,      -70./),\  ;BBCAmerica
   ;                  (/-25.,  -5.,      -75.,      -50./),\  ;BBSAmerica
   ;                  (/-35., -15.,      -40.,      -25./),\  ;BBSAmericaOcean
   ;                  (/  5.,  15.,      -20.,       38./),\  ;BBCAfrica
   ;                  (/-20.,  -5.,       10.,       40./),\  ;BBSAfrica
   ;                  (/-15.,   0.,      -10.,       10./),\  ;BBSAfOcean
   ;                  (/-10.,   8.,        95.,     125./),\  ;BBMSEA
   ;                  (/-25., -10.,       115.,     140./),\  ;BBNWAu
   ;                  (/-45., -10.,       140.,     155./),\  ;BBEAu
   ;                  (/  0.,  60.,      -180.,     180./),\  ;NH
   ;                  (/-60.,   0.,      -180.,     180./) /) ;SH

   region_names = (/"PNW", "Central Mountain USA", "East USA"/)

   ;                   minlat, maxlat, minlon, maxlon
   region_select = (/(/ 38.,  60.,     -130.,     -110./),\ ;PNW
                     (/ 35.,  49.,     -110.,     -95./),\  ;Central Mountain USA
                     (/ 32.5,  42.,     -95.,     -75./) /) ;East USA


   ; Tagged simulations
   ;region_names = (/"AUST", "NZ", "EQAS", "SEAS","INDI", "NEAS", "SIBR", \
   ;                 "BOAS", "EURO", "AFME","CWAS1", "CWAS2", "NHAF",\
   ;                 "SHAF", "BONA", "TENA", "CEAM", "NHSA","AMAZ",\
   ;                 "SHSA", "NH", "SH"/)

   ;                   minlat, maxlat, minlon, maxlon
   ;region_select = (/(/-50., -10.,       110.,     160./),\  ;AUST
   ;                  (/-50., -30.,       160.,     181./),\  ;NZ
   ;                  (/-10.,   8.,        90.,     160./),\  ;EQAS
   ;                  (/  8.,  28.,        90.,     135./),\  ;SEAS
    ;                 (/  4.,  35.,        60.,      90./),\  ;INDI
    ;                 (/ 28.,  50.,        90.,     153./),\  ;NEAS
    ;                 (/ 50.,  80.,        90.,     190./),\  ;SIBR
    ;                 (/ 50.,  80.,        30.,      90./),\  ;BOAS
    ;                 (/ 30.,  75.,   360.-25.,      30./),\  ;EURO
     ;                (/  0.,  30.,        35.,      60./),\  ;AFME
     ;                (/ 30.,  50.,        30.,      60./),\  ;CWAS1
     ;                (/ 35.,  50.,        60.,      90./),\  ;CWAS2
     ;                (/  0.,  30.,   360.-18.,      35./),\  ;NHAF
     ;                (/ -36.,  0.,    360.-1.,      60./),\  ;SHAF
     ;                (/ 50.,  75.,  360.-170., 360.-53./),\  ;BONA
      ;               (/ 27.,  50.,  360.-140., 360.-53./),\  ;TENA
      ;               (/  9.,  27.,  360.-120., 360.-40./),\  ;CEAM
      ;               (/  0.,   9.,   360.-90., 360.-30./),\  ;NHSA
      ;               (/-23.5,  -0.,  360.-90., 360.-30./),\  ;AMAZ
      ;               (/-60.,  -23.5, 360.-90., 360.-30./),\  ;SHSA
       ;              (/  0.,  90.,      0.,      360./),\    ;NH
       ;              (/-90.,   0.,      0.,      360./) /)   ;SH;


   n_regions = dimsizes(region_select(:,0))

   ; -----------------------------------------------------
   ; collect region outlines for plotting later
     region_lon := region_select(:,0:1)
     region_lat := region_select(:,2:3)


  ;********************************************
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

    mapres@mpLimitMode               ="LatLon"            ; zoom to Australia
      mapres@mpMinLatF               = latmin
      mapres@mpMaxLatF               = latmax
      mapres@mpMinLonF               = lonmin
      mapres@mpMaxLonF               = lonmax
    ;  mapres@mpCenterLonF            = centerlon

    mapres@vpXF = 0.1
    mapres@vpYF = 0.8
    mapres@vpHeightF            = 0.4          ; set height of plot

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

   else if (WITHCO) then
   ; Load Data
     ;mopitt_file = "/net/mopfl/home/buchholz/MOPITT_subset/V8/averages/MOPITT_2002_2017.nc"
     mopitt_file = "/net/mopfl/home/buchholz/MOPITT_subset/V8/averages/200312_01to12.nc"
     ;mopitt_file ="/MOPITT/V8T/Archive/L3/200305/month/MOP03TM-200305-L3V95.6.1.he5"
     fin = addfile(mopitt_file, "r")             ; load
     data = fin->RetrievedCOTotalColumnDay      ; extract total column data (:,:)
     ;data = fin->APrioriCOTotalColumnDay_MOP03
       data!0 = "lon"
       data!1 = "lat"
     lon = fin->Longitude
     ;lon = fin->Longitude_MOP03
       lon@long_name = "longitude"
       lon@units = "degrees_east"
       lon!0 = "lon"
     lat = fin->Latitude
     ;lat = fin->Latitude_MOP03
       lat!0 = "lat"
       lat@long_name = "latitude"
       lat@units = "degrees_north"
       data&lon = lon
       data&lat = lat

     mopitt_sd_file = "/net/mopfl/home/buchholz/MOPITT_subset/V8/averages/MOPITT_2002_2017_sd.nc"
     fin2 = addfile(mopitt_sd_file, "r")             ; load
     data2 = fin2->RetrievedCOTotalColumnDay      ; extract total column data (:,:)
       data2!0 = "lon"
       data2!1 = "lat"
    
    rel_sd = data2/data
       rel_sd!0 = "lon"
       rel_sd&lon = lon
       rel_sd!1 = "lat"
       rel_sd&lat = lat

  ;data_flip = rel_sd(lat|:, lon|:)  
  data_flip = data(lat|:, lon|:)/1e18


   ; Base Plot
    gsn_define_colormap(wks2,"haxby_rrb")        ; change colour map
    mapres@cnFillOn                  = True
    mapres@cnLinesOn                 = False
    mapres@mpGeophysicalLineThicknessF = 3.5
    mapres@tmXBTickSpacingF            = 60.
    mapres@tmYLTickSpacingF            = 30.
    mapres@tmXBLabelFontHeightF        =0.020
    mapres@tmYLLabelFontHeightF        =0.020
    mapres@gsnStringFontHeightF        = 0.020
    mapres@mpOceanFillColor = "gray"
    mapres@mpLandFillColor = "gray" 
    mapres@tmBorderThicknessF = 6
    mapres@tmXBMajorThicknessF = 6
    mapres@tmXBMinorThicknessF = 6
    mapres@tmXBLabelFontThicknessF = 3
    mapres@tmYLLabelFontThicknessF = 3

    mapres@lbOrientation              = "vertical"
    ;mapres@gsnRightString             = "Coefficient of variation"             ; Label Bar title
    mapres@gsnRightString             = "~F34~4~F21~10~S2~18   molec. cm~S2~-2"
    mapres@gsnLeftString             = "MOPITT CO 2003"
    mapres@lbTitlePosition            = "Right"
    mapres@cnLevelSelectionMode       = "ExplicitLevels"
    ;mapres@pmLabelBarOrthogonalPosF   = 0.5           ; move whole thing down

    labels = fspan(1.0,3.3, 22)
    labels_strings = (/"1.0","1.1","1.2","1.3","1.4","1.5","1.6","1.7","1.8","1.9",\
                       "2.0","2.1","2.2","2.3","2.4","2.5","2.6","2.7","2.8","2.9", "3.0",\
                       "3.1"/);
    ;labels = fspan(0.05,0.25, 16)
    ;labels_strings = (/"0.04","0.05","0.06","0.07","0.08","0.09",\
    ;                   "0.1","0.11","0.12","0.13","0.14","0.15","0.16","0.17","0.18","0.19",\
    ;                   "0.2"/);
    mapres@cnLevels                  = labels
    mapres@lbLabelStrings            = labels_strings
    mapres@lbTitleString              = ""             ; Label Bar title

    map1 = gsn_csm_contour_map_ce(wks2,data_flip,mapres)

   else 
    map1 = gsn_csm_map(wks2,mapres)                          ; draw a blank map
   end if
   end if

    ;-------------------
    ; add names
    ;-------------------
    txres = True
      txres@txFontHeightF = 0.01                     ; font smaller. default big
      txres@txFontThicknessF = 10.
      txres@txFontColor = "black"
      txres@txBackgroundFillColor = "white"
      txres@txPerimSpaceF = 0.2

    do i=0,n_regions-1
      if (region_names(i).eq."SH".or.region_names(i).eq."NH") then 
         continue
      else if (region_names(i).eq."BBCAfrica") then 
        dum = gsn_add_text(wks2,map1,region_names(i),10,\
                           (region_select(i,0)+region_select(i,1))/2,txres)
      else if (region_names(i).eq."BBMSEA") then 
        dum = gsn_add_text(wks2,map1,region_names(i),(region_select(i,2)+region_select(i,3))/2,\
                           (region_select(i,0)+region_select(i,1))/2+5,txres)
      else if (region_names(i).eq."AnthChina".or.region_names(i).eq."AnthUSA") then 
        dum = gsn_add_text(wks2,map1,region_names(i),(region_select(i,2)+region_select(i,3))/2+24,\
                           (region_select(i,0)+region_select(i,1))/2,txres)
      else if (region_names(i).eq."AnthIndi".or.region_names(i).eq."AnthEuro".or.\
               region_names(i).eq."Buchholz et al. N.Aus") then 
        dum = gsn_add_text(wks2,map1,region_names(i),(region_select(i,2)+region_select(i,3))/2-25,\
                           (region_select(i,0)+region_select(i,1))/2,txres)
      else if (region_names(i).eq."CONTRAIL avg") then 
        dum = gsn_add_text(wks2,map1,region_names(i),(region_select(i,2)+region_select(i,3))/2,\
                           (region_select(i,0)+region_select(i,1))/2-10,txres)
      else if (region_names(i).eq."BBSAfOcean".or.region_names(i).eq."BBSAmOcean") then 
        dum = gsn_add_text(wks2,map1,region_names(i),region_select(i,2)+5,\
                           region_select(i,0)-5,txres)
      else if (region_names(i).eq."New MSEA") then 
      txres@txFontColor = "red"
        dum = gsn_add_text(wks2,map1,region_names(i),(region_select(i,2)+region_select(i,3))/2,\
                           (region_select(i,0)+region_select(i,1))/2+13,txres)
      else
        dum = gsn_add_text(wks2,map1,region_names(i),(region_select(i,2)+region_select(i,3))/2,\
                           (region_select(i,0)+region_select(i,1))/2,txres)
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if
    end do

      txres@txFontColor = "red"
     gsn_text_ndc(wks2,"Red = Land retrievals only",0.2,0.83,txres)
      txres@txFontColor = "blue"
     gsn_text_ndc(wks2,"Blue = Water retrievals only",0.2,0.85,txres)
      txres@txFontColor = "forestgreen"
     gsn_text_ndc(wks2,"Green = Land, water and mixed retrievals",0.2,0.87,txres)

   draw(map1)


    ;-------------------
    ; draw region boxes
    ;-------------------
    boxres = True
      boxres@gsLineThicknessF = 8

      do j=0,n_regions-1
       if (region_names(j).eq."CWAS1".or.region_names(j).eq."CWAS2") then 
         continue
       else if (region_names(j).eq."SH".or.region_names(j).eq."NH") then 
       boxres@gsLineColor      = "forestgreen"
       boxres@gsLineDashPattern  = 0  
         regions_lon := (/360-179,0/)
         regions_lon2 := (/0,180/)
         regions_lat := (/region_select(j,0),region_select(j,0)/)
         regions_lat2 := (/region_select(j,1),region_select(j,1)/)
         gsn_polyline(wks2,map1,regions_lon,regions_lat,boxres)
         gsn_polyline(wks2,map1,regions_lon2,regions_lat,boxres)
         gsn_polyline(wks2,map1,regions_lon,regions_lat2,boxres)
         gsn_polyline(wks2,map1,regions_lon2,regions_lat2,boxres)
       else if (region_names(j).eq."AnthChina".or.\
                region_names(j).eq."AnthEuro".or.\
                region_names(j).eq."AnthUSA".or.\
                region_names(j).eq."AnthIndi") then 
       boxres@gsLineColor      = "red"
       boxres@gsLineDashPattern  = 0  
         regions_lon := (/region_select(j,2), region_select(j,2), \
                          region_select(j,3) , region_select(j,3), \
                          region_select(j,2)/)
         regions_lat := (/region_select(j,0), region_select(j,1), \
                          region_select(j,1) , region_select(j,0), \
                          region_select(j,0)/)
         gsn_polyline(wks2,map1,regions_lon,regions_lat,boxres)
       else if (region_names(j).eq."CONTRAIL avg") then
         boxres@gsLineColor      = "black"
         boxres@gsLineDashPattern  = 0
         regions_lon := (/region_select(j,2), region_select(j,2), \
                          region_select(j,3) , region_select(j,3), \
                          region_select(j,2)/)
         regions_lat := (/region_select(j,0), region_select(j,1), \
                          region_select(j,1) , region_select(j,0), \
                          region_select(j,0)/)
         gsn_polyline(wks2,map1,regions_lon,regions_lat,boxres)

       else if (region_names(j).eq."BBSAmOcean".or.\
                region_names(j).eq."BBSAfOcean") then
       boxres@gsLineColor      = "blue"
         regions_lon := (/region_select(j,2), region_select(j,2), \
                          region_select(j,3) , region_select(j,3), \
                          region_select(j,2)/)
         regions_lat := (/region_select(j,0), region_select(j,1), \
                          region_select(j,1) , region_select(j,0), \
                          region_select(j,0)/)
         gsn_polyline(wks2,map1,regions_lon,regions_lat,boxres)
       else if (region_names(j).eq."Nino3.4".or.region_names(j).eq."TNA".or.\
                region_names(j).eq."DMI".or.region_names(j).eq."DMI2".or.\
                region_names(j).eq."AO") then
       boxres@gsLineColor      = "white"
         regions_lon := (/region_select(j,2), region_select(j,2), \
                          region_select(j,3) , region_select(j,3), \
                          region_select(j,2)/)
         regions_lat := (/region_select(j,0), region_select(j,1), \
                          region_select(j,1) , region_select(j,0), \
                          region_select(j,0)/)
         gsn_polyline(wks2,map1,regions_lon,regions_lat,boxres)
       else
       boxres@gsLineColor      = "forestgreen"
       boxres@gsLineDashPattern  = 0 
         regions_lon := (/region_select(j,2), region_select(j,2), \
                          region_select(j,3) , region_select(j,3), \
                          region_select(j,2)/)
         regions_lat := (/region_select(j,0), region_select(j,1), \
                          region_select(j,1) , region_select(j,0), \
                          region_select(j,0)/)
         gsn_polyline(wks2,map1,regions_lon,regions_lat,boxres)
       end if
       end if
       end if
       end if
       end if
       end if
      end do

    frame(wks2)
   end if ; PLOTREGIONS

end

