;============================================
; plot_mopitt_lev2.ncl
;============================================
;
; Concepts Illustrated
;          - Reading v6, level 2, he5 files
;          - Extracting CO
;          - select for day values
;          - select for spatial region
;          - plot result
;
; To use type on the command line:
;          > ncl plot_mopitt_lev2.ncl
;                            RRB Oct 14, 2014
;============================================
; load the libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------
print("Start Time")
print(systemfunc("date"))
general = "/MOPITT/V7J/Archive/L2/201605/0515"
infile = general +"/MOP02J-20160515-L2V17.9.3.he5"
print(infile)
  ;------------
  ; toggles
  ;------------
  PLOT           = True

  if (PLOT) then
    pltdir       = "./"
    pltname      = "mopitt_l2_2D"
    plttype      = "x11"                     ; workstation type
        plttype@wkWidth = 1200
        plttype@wkHeight = 1200 
  end if
  
;--------------------------------------------
; end user input
;--------------------------------------------
;
;--------------------------------------------
; set up
;--------------------------------------------

     ;topboundary    = 65
     ;bottomboundary = 20
     ;rightboundary  = -60
     ;leftboundary   = -140

     topboundary    = 60
     bottomboundary = -60
     rightboundary  = 180
     leftboundary   = -180

    tcol_min        =1.60e18
    tcol_max        =3.1e18


;--------------------------------------------
; load file and extract
;--------------------------------------------
; names of data structures
; determined from an ncl_filedump
suff           = "_MOP02"
tracer         = "RetrievedCOTotalColumn"+suff
longitude      = "Longitude"+suff
latitude       = "Latitude"+suff
solarza        = "SolarZenithAngle"+suff

; read data
fin = addfile(infile, "r")
  tgas         = fin->$tracer$
  tcol         = tgas(:,0)
  tcol_err     = tgas(:,1)
  lon          = fin->$longitude$
  lat          = fin->$latitude$
  sza          = fin->$solarza$
  time         = fin->$"Time_MOP02"$
    ; Time is TAI 93
    time@units   = "seconds since 1993-01-01 00:00:0.0"

  ; calculate date
  av_time = avg(time)
    av_time@units   = "seconds since 1993-01-01 00:00:0.0"
  date = cd_calendar(av_time,2)

printVarSummary(tcol)

;--------------------------------------------
; select daytime retrievals
;--------------------------------------------
; For SZA < 80

;day_tcol = tcol(ind(sza.le.80))
;day_lat  = lat(ind(sza.le.80))
;day_lon  = lon(ind(sza.le.80))


day_tcol = tcol
day_lat  = lat
day_lon  = lon

;--------------------------------------------
; select spatial sub-section as per user section
;--------------------------------------------
region = ind(day_lat.le.topboundary.and.\
             day_lat.ge.bottomboundary.and.\
             day_lon.ge.leftboundary.and.\
             day_lon.le.rightboundary)

region_tcol = day_tcol(region)
region_lat  = day_lat(region)
region_lon  = day_lon(region)
;region_lon_360 = 360 + region_lon
region_lon_360 = region_lon

;--------------------------------------------
; Land/Sea masking
;--------------------------------------------
; data is 2D w/ 2D lat/lon coordinate variables (TLAT,TLON).
  a = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
  lsdata = a->LSMASK
  lsm = landsea_mask(lsdata,region_lat,region_lon_360)

  ; turn mask into 1D array
  maskvalues = new(dimsizes(region_tcol),float)
  do j = 0,dimsizes(maskvalues)-1
    ind_mask := ind(lsm&lat.eq.region_lat(j).and.lsm&lon.eq.region_lon_360(j))
    maskvalues(j) = lsm(ind_mask,ind_mask)
  end do

  ; mask the tcol data with missing values
  ;masked_tcol = mask(region_tcol,maskvalues.eq.0,False)   
  masked_tcol = region_tcol
printVarSummary(masked_tcol)
;--------------------------------------------
; define tcol colour levels
;--------------------------------------------
cmap = read_colormap_file("haxby_rrb")
colors = cmap(0:dimsizes(cmap(:,0))-1:2,:)
num_colors = dimsizes(colors(:,0))
levels = fspan(tcol_min,tcol_max,31)
nlevels = dimsizes(levels)
print(num_colors)

  ;masked_tcol = lonFlip(masked_tcol) 


;--------------------------------------------
; plot
;--------------------------------------------
if (PLOT) then
  print("start plotting")
  print(systemfunc("date"))
  wks = gsn_open_wks(plttype,pltname)        
  gsn_define_colormap(wks,"haxby_rrb")        ; change colour map
   
  res                  = True                      ; plot mods desired
    ;res@gsnDraw		    = False	           ; don't draw it yet
    res@gsnFrame            = False                ; don't advance frame
    res@gsnMaximize         = True
    res@mpFillOn            = True                ; don't use gray over land
    res@gsnRightString      = date
    res@gsnRightStringFontHeightF = 0.018
    res@gsnAddCyclic        =True

    res@tmXBLabelFontHeightF        =0.018
    res@tmYLLabelFontHeightF        =0.018
    res@tmXBTickSpacingF            = 30.
    res@tmYLTickSpacingF            = 20.

    res@mpMaxLatF           = topboundary
    res@mpMinLatF           = bottomboundary
    ;res@mpMaxLonF           = rightboundary
    ;res@mpMinLonF           = leftboundary
    res@mpMaxLonF           = 180
    res@mpMinLonF           = -180

  res@mpOutlineOn               = True              ; turn on outline
  res@mpOutlineBoundarySets     = "geophysicalandusstates"; turn on states
  res@mpDataBaseVersion         = "mediumres"             ; select database
  res@mpDataSetName             = "Earth..2"

  map1=gsn_csm_map(wks, res)

  getvalues map1                                                             
     "mpAreaNames" : area_names 
  end getvalues 
  res@mpOutlineSpecifiers = area_names(617:655) 

  ; draw background map

  draw(map1)

  ;------------
  ; add polymarkers
  ; coloured by tcol
  ;------------
  ;colour_arr = (/"purple","navy","blue","seagreen","green","yellow","orange","red","red"/)
  colour_arr = (/cmap(0,:),cmap(0,:),cmap(0,:),cmap(0,:),cmap(0,:),cmap(0,:),cmap(0,:),cmap(0,:),cmap(0,:)/)
  pmres = True
     pmres@gsMarkerIndex = 16
     pmres@gsMarkerSizeF = 0.003
     ;markerid = new(nlevels+1,graphic)

  ; group tcol indices into colour groups
  do i=0,nlevels
    if (i.eq.0) then
      ii := ind(masked_tcol.lt.levels(0))                                  ; bottom limit
    else if (i.eq.nlevels) then
      ii := ind(masked_tcol.ge.levels(nlevels-1))                          ; top limit
    else
      ii := ind(masked_tcol.ge.levels(i-1).and.region_tcol.lt.levels(i))   ; middle levels
    end if
    end if
    
    if (.not.any(ismissing(ii))) then
      pmres@gsMarkerColor = colors(i,:)
      ; add polymarkers for MOPITT level 2 pixels
      ;markerid(i) = gsn_add_polymarker(wks,map1,region_lon(ii),region_lat(ii),pmres)
      gsn_polymarker(wks,map1,region_lon(ii),region_lat(ii),pmres)
    end if
  end do


  ;------------
  ; add labelbarl
  ;------------
  lbres = True
     lbres@vpWidthF                  = 0.8
     lbres@vpHeightF                 = 0.1
     lbres@lbPerimOn                 = False
     lbres@lbOrientation             = "Horizontal"
     lbres@vpYF                      = 0.18                    ; y-location of label bar
     lbres@lbLabelAlignment          = "InteriorEdges"
     lbres@lbFillColors              = colors
     lbres@lbMonoFillPattern         = True
     lbres@lbLabelFontHeightF        = 0.020
     lbres@lbLabelStride             = 5

     lbres@lbTitleOn                 = True
     lbres@lbTitleString             = "MOPITT CO total column (10~S2~18   molec. cm~S2~-2  )"
     lbres@lbTitleFontHeightF        = 0.020
     lbres@lbTitlePosition           = "Bottom"

     lbres@lbLabelStrings            := levels/1e18

  labels = sprintf("%4.2e",levels)
  gsn_labelbar_ndc(wks, nlevels+1, labels, 0.1, 0.23, lbres)

  ;draw(map1)
  frame(wks)   ;keeps the image up when using X11
  print("end plotting")
  print(systemfunc("date"))
end if

end

