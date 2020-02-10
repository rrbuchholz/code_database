;================================================;
;  tandnmap.ncl
;================================================;
;
; Concepts illustrated:
;   - Turning on map outlines
;   - Plotting coordinates on a map
;   - Filling landmass with colour
;                                r.r.b. 2016.04.13
; ================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

; ===================
; User input
; ===================

   sitefile="FIREX_ground_sites.csv"

  ; Plot definitions
  wks_type = "png"                          ; x11, png, ps or pdf
;    wks_type@wkOrientation = "landscape"


; ===================
; Decide on region to plot
; ===================

   WORLD       = False
   ASIA        = False
   EAST_ASIA   = False
   KOREA       = False
   USA         = True

if (WORLD) then
     topboundary           =  90           ; choose World
     bottomboundary        = -90
     rightboundary         = 180
     leftboundary          = -180
end if

if (ASIA) then
     topboundary           = 60            ; Choose Asia subregion
     bottomboundary        = 20
     leftboundary          = 75
     rightboundary         = 145
end if

if (EAST_ASIA) then
     topboundary           = 47            ; Choose Asia subregion
     bottomboundary        = 27
     leftboundary          = 110
     rightboundary         = 135
end if

if (KOREA) then
     topboundary           = 39
     bottomboundary        = 31.5
     leftboundary          = 123
     rightboundary         = 132.5
end if

if (USA) then
     topboundary           = 60.
     bottomboundary        = 20.
     leftboundary          = -128.
     rightboundary         = -75.
end if


; ===================
; Read in data from files
; ===================

  quote = "'"          ; will match one or more apostrophe

  ;-------------------------
  ; extract TCCON only sites
  ;-------------------------
  ;---Read the values in as 1D, since we don't know rows and columns yet.
  lines  = asciiread(sitefile,-1,"string")
  delim  = " "
  ncols  = dimsizes(str_split(lines(3),delim))
  nlines = dimsizes(lines)
  print("Columns:"+ncols+", Lines:"+nlines)

  ;---Reshape as 2D array, and convert to float for ppm/ppb/ppt.
  sites_str = readAsciiTable(sitefile, 1, "string", 2)
    site_names = str_get_field(sites_str(:,0), 1, quote)
  sites = readAsciiTable(sitefile, 2, "float", 2)
    site_lat  = sites(:,0)     ; latitude values
    site_lon  = sites(:,1)     ; longitude values

;printVarSummary(sites_str)
;print(sites)
;print(site_names)
;exit


; ===================
; Start the Graphics
; ===================

  wks  = gsn_open_wks(wks_type,"FIREX_ground_sites")     ; open a workstation
  gsn_define_colormap(wks,"wh-bl-gr-ye-re")         ; define a different colormap.
  ncl = NhlNewColor(wks,.9,.9,.9)                   ; add grey to continents

  mpres                           = True              ; plot mods
    mpres@gsnFrame                = False             ; do not advance frame
    mpres@gsnDraw                 = False
    ;mpres@mpFillColors            = (/-1,-1,ncl,-1/)  ; light grey to land masses
    mpres@mpFillOn = False
    ;mpres@mpOutlineOn         = False                     ; will draw highres map later
    mpres@gsnMaximize             = True 
    mpres@gsnMajorLatSpacing      = 20
    mpres@gsnMajorLonSpacing      = 20

    mpres@mpMaxLatF               =  topboundary
    mpres@mpMinLatF               =  bottomboundary 
    mpres@mpMaxLonF               =  rightboundary
    mpres@mpMinLonF               =  leftboundary


; ===================
; Create the map
; ===================

  map1 = gsn_csm_map(wks,mpres)

   ;----------------------------------------
   ; add countries and counties
   ;----------------------------------------
     ;country_shp_name    = "/glade/u/home/pfister/KORUS/KOR_adm1.shp"
     ;lnres                  = True
     ;  lnres@gsLineColor      = "gray60"
     ;  lnres@gsLineThicknessF = 1.0
     ; country_id = gsn_add_shapefile_polylines(wks,map1,country_shp_name,lnres)

     ; world_shp_name    = "/glade/u/home/pfister/KORUS/countries.shp"
     ;   lnres@gsLineThicknessF = 2.0
     ; world_id = gsn_add_shapefile_polylines(wks,map1,world_shp_name,lnres)

   ;----------------------------------------
   ; Site information
   ;----------------------------------------
   ; Add the stations as filled circles
   pmres                    = True
    pmres@gsMarkerIndex=7            ; choose triangle polymarker
    pmres@gsMarkerSizeF=10.          ; select size to avoid streaking
    pmres@gsMarkerThicknessF =4

   nsites = dimsizes(site_names)
   stat_loc = new(nsites, graphic)
   do i = 0, nsites-1
     if (site_names(i).eq."Seoul_SNU".or.\
         site_names(i).eq."Gosan, Jeju Island".or.\
         site_names(i).eq."Baengnyeong Island".or.\
         site_names(i).eq."Pusan Univ., Busan".or.\
         site_names(i).eq."Gangneung-Wonju Univ.".or.\
         site_names(i).eq."GIST, Gwangju".or.\
         site_names(i).eq."Fukue, Japan") then
       pmres@gsMarkerColor="red"        ; set polymarker color
       stat_loc(i) = gsn_add_polymarker(wks,map1, site_lon(i), site_lat(i),pmres)
     else
       pmres@gsMarkerColor="red"        ; set polymarker color
       stat_loc(i) = gsn_add_polymarker(wks,map1, site_lon(i), site_lat(i),pmres)
     end if
   end do

   ; Add the station names
   txres                  = True
     txres@txFontHeightF  = 0.013
     txres@txFont         = "helvetica-bold"

   text = new(nsites, graphic)
   do i = 0, nsites-1
     ;--------------------------
     ; Stations from CAM-Chem 
     ;--------------------------
     if (site_names(i).eq."Seoul_SNU") then
         txres@txJust         = "TopRight"
         txres@txFontColor    = "red"
         text(i) = gsn_add_text(wks,map1,site_names(i),site_lon(i),site_lat(i)-0.1,txres)
     else if (site_names(i).eq."Greenbelt, MD (TROPOZ)") then
         txres@txJust         = "BottomRight"
         txres@txFontColor    = "black"
        text(i) = gsn_add_text(wks,map1,site_names(i),site_lon(i)+0.5,site_lat(i)+0.5,txres)
     else if (site_names(i).eq."Boulder, CO (TOPAZ)".or.\
              site_names(i).eq."Hampton, VA (LMOL)") then
         txres@txJust         = "TopRight"
         txres@txFontColor    = "black"
        text(i) = gsn_add_text(wks,map1,site_names(i),site_lon(i)-0.5,site_lat(i)-0.5,txres)
     ;--------------------------
     ; Other stations
     ;--------------------------
     else if (site_names(i).eq."Kansas-City".or.\
              site_names(i).eq."Spokane".or.\
              site_names(i).eq."Salt-Lake-City") then
         txres@txJust         = "TopLeft"
         txres@txFontColor    = "black"
        text(i) = gsn_add_text(wks,map1,site_names(i),site_lon(i)+0.5,site_lat(i)+0.5,txres)
     else if (site_names(i).eq."Mount Bachelor, OR") then
         txres@txJust         = "TopCenter"
         txres@txFontColor    = "black"
        text(i) = gsn_add_text(wks,map1,site_names(i),site_lon(i)-0.5,site_lat(i)-0.3,txres)
     else if (site_names(i).eq."Huntsville, AL") then
         site_names(i)="Huntsville, AL (RO3QET)"
         txres@txJust         = "TopCenter"
         txres@txFontColor    = "black"
        text(i) = gsn_add_text(wks,map1,site_names(i),site_lon(i)+3.0,site_lat(i)-0.3,txres)
      else
        txres@txJust         = "TopLeft"
        txres@txFontColor    = "black"
        text(i) = gsn_add_text(wks,map1,site_names(i),site_lon(i)+0.5,site_lat(i),txres)
      end if
      end if
      end if
      end if
      end if
      end if

      ;if (site_names(i).eq."Kasuga, Japan") then
      ;  txres@txJust         = "BottomLeft"
      ;  text(i) = gsn_add_text(wks,map1,site_names(i),site_lon(i)+0.1,site_lat(i),txres)
      ;end if

   end do
       ;text = gsn_add_text(wks,map1,site_names,site_lon,site_lat,txres)
   ;----------------------------------------
   ; Add grid
   ;----------------------------------------
   ; 0.942408377x1.25 deg resolution run
   ; 192lat x 290lon
   gres = True
     gres@gsLineColor = "grey"

   lat_grid = new(192, graphic)
   do i = 0, 191
     ;CAM-chem
     lat_grid(i) = gsn_add_polyline(wks, map1,  (/leftboundary, rightboundary/), (/-90 + i*0.942408377 + 0.942408377/2, -90 + i*0.942408377 + 0.942408377/2 /), gres)
   end do

   lon_grid = new(290, graphic)
   do i = 0, 289
     ;CAM-chem
     lon_grid(i) = gsn_add_polyline(wks, map1, (/-180 + i*1.25 + 1.25/2, -180 +i*1.25 + 1.25/2 /), (/bottomboundary, topboundary/), gres)
   end do

   ;-----------------------------------
   ; Add in caption
   ;-----------------------------------
   ; drawNDCGrid(wks)
   ; add station
    txres                   = True                     ; polyline mods desired
     txres@txFontHeightF    = 0.014                    ; font smaller. default big
     txres@txJust           = "CenterLeft"             ; font smaller. default big
     txres@txPerimOn        = False

     pmres@gsMarkerColor="red"        ; set polymarker color
    gsn_polymarker_ndc(wks,0.125,0.08,pmres) ; draw polymarkers
    gsn_text_ndc(wks,"Surface sites in the FIREX-AQ domain",0.15,0.08,txres)
       pmres@gsMarkerColor="red"        ; set polymarker color



  draw(map1)
  frame(wks)


 end
