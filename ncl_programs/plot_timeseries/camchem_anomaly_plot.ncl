;=======================================================;
;  camchem_anomaly_plot.ncl
;=======================================================;
;
; Concepts illustrated:
;   - open extracted CAM-chem files for regions/stations
;   - read in variable
;   - calculate and plot month average anomalies
;
; Tagged tracer definitions
;
;CO01           Methane oxidation produced CO (0.86 * CO from reaction of OH with CH4, Shindell 2006)
;
;CO02           Biogenic emissions of CO from MEGAN (global)
;
;CO03           Biomass burning CO in Australasia
;CO04           Biomass burning CO in Southeast Asia
;CO05           Biomass burning CO in Northeast Asia
;CO06           Biomass burning CO in Siberia
;CO07           Biomass burning CO in India
;CO08           Biomass burning CO in West Russia
;CO09           Biomass burning CO in Southern Africa
;CO10           Biomass burning CO in Northern Africa and Middle East
;CO11           Biomass burning CO in Europe
;CO12           Biomass burning CO in South America
;CO13           Biomass burning CO in Central America
;CO14           Biomass burning CO in North America
;CO15           Biomass burning CO in Southern Hemisphere
;CO16           Biomass burning CO in Northern Hemisphere
;
;CO17           Anthropogenic CO in Australasia
;CO18           Anthropogenic CO in Southeast Asia
;CO19           Anthropogenic CO in Northeast Asia
;CO20           Anthropogenic CO in Siberia
;CO21           Anthropogenic CO in India
;CO22           Anthropogenic CO in West Russia
;CO23           Anthropogenic CO in Southern Africa
;CO24           Anthropogenic CO in Northern Africa and Middle East
;CO25           Anthropogenic CO in Europe
;CO26           Anthropogenic CO in South America
;CO27           Anthropogenic CO in Central America
;CO28           Anthropogenic CO in North America
;CO29           Anthropogenic CO in Southern Hemisphere
;CO30           Anthropogenic CO in Northern Hemisphere
;
;
;
;   Files needed:
;         -CAM-chem tagged total column output in netCDF format
;
;   To run type:
;         ncl  camchem_anomaly_plot.ncl
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
  ;------------
  ; define location
  ;------------
  location = "Indonesia"
  location_name = "Maritime SEA"
  emissions = "constant"

  ; -------------------------------
  ; CAM-chem files
  ; -------------------------------
   if (emissions.eq."variable") then
     folder = "/glade/p/work/buchholz/data_processing/CAM-chem/CAMchem_extracted/"
   else if (emissions.eq."constant") then
     folder = "/glade/p/work/buchholz/data_processing/CAM-chem/constE/"
  ;folder = "/glade/u/home/buchholz/NCL_programs/CAMchem_constE_extracted/"
   end if
   end if

  files_dummy = systemfunc ("ls "+folder+location+"CAM_Chem_avg*.nc")
  filenames = files_dummy

  ;------------
  ; toggles
  ;------------
  PLOT         = True
    plttype      = "png"           ; pdf or png if want to save
     plttype@wkWidth = 1200
     plttype@wkHeight = 1200 
     year_s = 2001
     year_e = 2015

  CSV       = False
  outname = "CAM_chem_"+location+"_anomaly.csv"

;--------------------------------------------
; end user input
;--------------------------------------------
;
;--------------------------------------------
; set up
;--------------------------------------------
  ; -------------------------------
  ; OUTPUT RELATED SETUP
  ; -------------------------------
  if (PLOT) then
    pltdir       = "./"
    pltname      = "CAMchem_anomaly_"+emissions+"_emissions_"+ location
  end if

;--------------------------------------------
; load file and extract
;--------------------------------------------
  ; -------------------------------
  ; CAM-chem load common variables
  ; -------------------------------
  ; names of data structures
  ; determined from a ncl_filedump
    fin = addfiles(filenames, "r")           ; read in
    ListSetType (fin, "cat")                 ; concatenate
      time           = fin[:]->time
        yyyymmdd     = cd_calendar(time,2)
        yrfrac       = cd_calendar(time, 4)
        model_date   = cd_calendar(time,0)
        years        = model_date(:,0)
        months       = model_date(:,1)

  ; -------------------------------
  ; loop over extracting tracers
  ; -------------------------------
  tracer = (/"CO", "CO01", "CO02", "CO03", "CO04", "CO05", "CO06", "CO07", "CO08", "CO09", "CO10",\
            "CO11", "CO12", "CO13", "CO14", "CO15", "CO16", "CO17", "CO18", "CO19", "CO20",\
            "CO21", "CO22", "CO23", "CO24", "CO25", "CO26", "CO27", "CO28", "CO29", "CO30"/)

  ; set-up tcol collection array
    tcol_arr   = new((/dimsizes(time),dimsizes(tracer)/), float)

  do i = 0, dimsizes(tracer)-1
     varname = tracer(i)+"_TotalColumn"
     tcol     := fin[:]->$varname$
     tcol_arr(:,i) = tcol
  end do

;--------------------------------------------
; perform calculations
;--------------------------------------------
  ; -------------------------------
  ; CLIMATOLOGICAL MONTH AVERAGES 
  ; and STANDARD DEVIATION
  ; ------------------------------- 
    climate_co   = new((/12,dimsizes(tracer)/), float)
    climate_co_sd = new((/12,dimsizes(tracer)/), float)

  do i=0,11
     ; get indices of array related to specific month
     month_ind := ind(months.eq.(i+1))
     co_to_avg := tcol_arr(month_ind,:)

     climate_co(i,:) = dim_avg_n(co_to_avg,0)
     climate_co_sd(i,:) = dim_stddev_n(co_to_avg,0)
  end do ;i=0,11

  ; repeat climate values over total time period
  startyear = years(0)
  endyear = years(dimsizes(years)-1)
  climate_time = yyyymm_time(toint(startyear), toint(endyear), "integer")
   climate_co_ext    = new((/dimsizes(climate_time),dimsizes(tracer)/), float)
   climate_co_sd_ext = new((/dimsizes(climate_time),dimsizes(tracer)/), float)

  do y = 0, (dimsizes(climate_time)-1)/12
    do m=0,11
     climate_co_ext(y*12+m,:) = climate_co(m,:)
     climate_co_sd_ext(y*12+m,:) = climate_co_sd(m,:)
    end do
  end do

  ; -------------------------------
  ; MONTH AVERAGES and ANOMALIES
  ; -------------------------------
    month_co_avg_a  = new(dimsizes(climate_co_ext), float)
    month_anomaly_a = new(dimsizes(climate_co_ext), float)

  do y = toint(startyear), toint(endyear)
    do m=0,11
      ind_yearmonth := ind(years.eq.y.and.months.eq.(m+1))
      index_month = (y-toint(startyear))*12+m
      if (dimsizes(ind_yearmonth).eq.1) then
        month_co_avg_a(index_month,:)=tcol_arr(ind_yearmonth,:)
        month_anomaly_a(index_month,:)= tcol_arr(ind_yearmonth,:)-climate_co(m,:)
      else 
        month_co_avg_a(index_month,:)=dim_avg_n(tcol_arr(ind_yearmonth,:),0)
        month_anomaly_a(index_month,:)= dim_avg_n(tcol_arr(ind_yearmonth,:),0)-climate_co(m,:)
      end if
    end do
  end do

month_avg_yfrac = yyyymm_to_yyyyfrac(climate_time,0)


methox_anomaly = month_anomaly_a(:,1)
biog_anomaly = month_anomaly_a(:,2)
anth_anomaly = dim_sum_n(month_anomaly_a(:,29:30),1)
  anth_aus = month_anomaly_a(:,17)
  anth_SAm = month_anomaly_a(:,26)
  anth_SAf = month_anomaly_a(:,23)
  anth_Indo = month_anomaly_a(:,18)
  other_anth = anth_anomaly-(anth_aus+anth_SAm+anth_SAf+anth_Indo)
  anth_India = month_anomaly_a(:,21)
  anth_NEA = month_anomaly_a(:,19)
bb_anomaly = dim_sum_n(month_anomaly_a(:,15:16),1)
  bb_aus = month_anomaly_a(:,3)
  bb_SAm = month_anomaly_a(:,12)
  bb_SAf = month_anomaly_a(:,9)
  bb_Indo = month_anomaly_a(:,4)
  other_bb = bb_anomaly-(bb_aus+bb_SAm+bb_SAf+bb_Indo)

methox_co = month_co_avg_a(:,1)
biog_co = month_co_avg_a(:,2)
anth_co = dim_sum_n(month_co_avg_a(:,29:30),1)
bb_co = dim_sum_n(month_co_avg_a(:,15:16),1)
residual_co = month_co_avg_a(:,0)-bb_co-anth_co-biog_co-methox_co

;print(dim_sum_n(month_co_avg_a(:,15:16),1))

residual = month_anomaly_a(:,0)-bb_anomaly-anth_anomaly-biog_anomaly-methox_anomaly
all_tags = bb_anomaly+anth_anomaly+biog_anomaly+methox_anomaly+residual


;--------------------------------------------
; calculate percentages
;--------------------------------------------
yyyy  = climate_time/100
mm = climate_time - yyyy*100
ind_SOND = ind(mm.eq.9.or.mm.eq.10.or.mm.eq.11.or.mm.eq.12)
month_anomaly=month_anomaly_a(:,0)
;print(yyyy(0:20))
;print(mm(0:20))
;print(mm(ind_SOND))

methox_poa = (methox_anomaly/month_anomaly)*100
biog_poa = (biog_anomaly/month_anomaly)*100
anth_poa = (anth_anomaly/month_anomaly)*100
  anth_aus_poa = (anth_aus/month_anomaly)*100
  anth_transported_poa = ((anth_SAf+anth_SAm)/month_anomaly)*100
  anth_Indo_poa = (anth_Indo/month_anomaly)*100
  anth_other_poa = (other_anth/month_anomaly)*100
  ;anth_India_poa = (anth_India/month_anomaly)*100
  ;anth_NEA_poa = (anth_NEA/month_anomaly)*100
bb_poa = (bb_anomaly/month_anomaly)*100
  bb_aus_poa = (bb_aus/month_anomaly)*100
  bb_transported_poa = ((bb_SAf+bb_SAm)/month_anomaly)*100
  bb_Indo_poa = (bb_Indo/month_anomaly)*100
  bb_other_poa = (other_bb/month_anomaly)*100
residual_poa = (residual/month_anomaly)*100

print("**********************") 
print("BB         : "+avg(bb_poa)) 
print("  Aus BB   : "+avg(bb_aus_poa))
print("  Transp BB: "+avg(bb_transported_poa)) 
print("  MSEA BB  : "+avg(bb_Indo_poa)) 
print("  Other BB : "+avg(bb_other_poa)) 
 
print("Anth       : "+avg(anth_poa)) 
print("  Aus Anth : "+avg(anth_aus_poa))
print("  Tra. Anth: "+avg(anth_transported_poa)) 
print("  MSEA Anth: "+avg(anth_Indo_poa)) 
print(" Other Anth: "+avg(anth_other_poa)) 
;print(" India Anth: "+avg(anth_India_poa)) 
;print("  NEA Anth : "+avg(anth_NEA_poa)) 
print("Biogenic   : "+avg(biog_poa)) 
print("Methane Ox : "+avg(methox_poa)) 
print("VOC ox     : "+avg(residual_poa)) 


;--------------------------------------------
; plot
;--------------------------------------------
if (PLOT) then

  ; set the total average to be plot
  n=0
  plottime := month_avg_yfrac

  wks = gsn_open_wks(plttype,pltname)        
  gsn_define_colormap(wks,"BlAqGrYeOrRe")  
   
  res                       = True                      ; plot mods desired
    res@xyMarkLineMode      = "Markers"
    res@xyMarker            = 17
    res@xyMarkerColor       = "grey34"
    res@xyMarkerSizeF       = 0.08
    res@gsnDraw		    = False	                ; don't draw it yet
    res@gsnFrame            = False                     ; don't advance frame

    res@trYMinF             = -0.2e18
    res@trYMaxF             = 1.75e18
    res@trXMinF             = year_s-0.1
    res@trXMaxF             = year_e

    res@tmYLMajorOutwardLengthF = 0.0               ; draw tickmarks inward
    res@tmYLMinorOutwardLengthF = 0.0               ; draw minor ticsk inward
    res@tmXBMajorOutwardLengthF = 0.0               
    res@tmXBMinorOutwardLengthF = 0.0    

    res@tmXBLabelFontHeightF  = 0.030
    res@tmYLLabelFontHeightF  = 0.030
    res@tiYAxisFontHeightF    = 0.038
    res@tiXAxisFontHeightF    = 0.038          

    res@vpWidthF             = 0.9
    res@vpHeightF            = 0.25          ; set height of plot

    res@tiMainString        = ""
    res@tiYAxisString       = "CO Column"
    res@gsnRightString      = "~F34~4~F21~10~S2~18   molec. cm~S2~-2"
    res@gsnStringFontHeightF = 0.028
   
  base_res = True
  base_res = res
  
  ; -------------------------------
  ; timeseries - weekly averages and climatology
  ; -------------------------------
    ;res@xyMarkLineMode      = "MarkLines"
    res@xyMarkLineMode      = "Lines"
    res@xyLineThicknessF    = 0.25
    res@xyLineColor         = "grey34"
    res@pmLegendDisplayMode      = "Never"        ; turn on legend

    res@tmYLMode            = "Explicit"
      res@tmYLValues          = fspan(0e18,3.5e18,8)
      res@tmYLLabels          = fspan(0e18,3.5e18,8)/1e18
      res@tmYLMinorValues     = fspan(0e18,3.5e18,15)

  ; All CO
  plot1 = gsn_csm_xy(wks,plottime,month_co_avg_a(:,n),res)

    res@xyMarkLineMode      = "Lines"
    res@xyLineThicknessF    = 8.
    res@xyDashPattern       = (/1/) 
    res@xyLineColor         = "black"

  ; Climatological seasonal cycle
  plot2 = gsn_csm_xy(wks,plottime,climate_co_ext(:,0),res)

   data1      = new((/6,dimsizes(plottime)/),float)
   data1(0,:) = plottime*0
   data1(1,:) = methox_co
   data1(2,:) = methox_co+biog_co
   data1(3,:) = methox_co+biog_co + anth_co 
   data1(4,:) = methox_co+biog_co + residual_co  + anth_co
   data1(5,:) = methox_co+biog_co + residual_co  + anth_co + bb_co

    above_colors = (/"blue","forestgreen","red","gray60","orange"/)
    below_colors = (/"blue","forestgreen","red","gray60","orange"/)
    res@xyLineColors       = (/"blue","forestgreen","red","gray60","orange","black"/)
    res@xyLineThicknessF   = 8
    res@xyDashPatterns     = (/0,0,0,0,0,1/) 
    res@gsnXYAboveFillColors = above_colors
    res@gsnXYBelowFillColors = below_colors

    res@pmLegendDisplayMode      = "Always"        ; turn on legend
      res@lgPerimOn                = False           ; Turn off perimeter
      res@pmLegendWidthF           = 0.3            ; Change width and
      res@pmLegendHeightF          = 0.25             ; height of legend
      res@lgLabelFontHeightF       = 0.024
      res@lbJustification          = "TopLeft"
      res@pmLegendOrthogonalPosF = 1.2
      res@pmLegendParallelPosF   = 0.475
    res@xyExplicitLegendLabels   = (/"methane ox", "biogenic", "anthropogenic", "VOC oxidation",    \
                                     "biomass burning","total"/)
  plot1a = gsn_csm_xy(wks,plottime,data1,res)
  ;overlay(plot1a, plot2)
  overlay(plot1, plot1a)

  ; -------------------------------
  ; Anomaly plot MOPITT
  ; -------------------------------
    res@gsnRightString      = ""
    res@tiYAxisString       = "Anomaly"
    res@tmYLTickSpacingF    = 0.2e18

    res@tmXBBorderOn        = True
    res@tmXBLabelsOn        = True
    res@tmXBMode              = "Explicit"
      res@tmXBValues           = tofloat(ispan(year_s,year_e,3))
      res@tmXBLabels           = tofloat(ispan(year_s,year_e,3))
      res@tmXBMinorValues      = tofloat(ispan(year_s,year_e,1))
    res@tiXAxisString          = "Year"
    res@vpHeightF           = 0.15          ; set height of plot

    res@tmYLMode             = "Explicit"
      res@trYMinF             := -0.28e18
      res@trYMaxF             := 0.20e18
      res@tmYLValues          := (/-0.15e18, 0.0, 0.15e18/)
      res@tmYLLabels          := (/-0.15, 0, 0.15/)
      res@tmYLMinorValues     := (/-0.05e18, 0.05e18/)

   data2      = new((/6,dimsizes(plottime)/),float)
   data2(0,:) = plottime*0
   data2(1,:) = residual
   data2(2,:) = residual+methox_anomaly
   data2(3,:) = residual+methox_anomaly+anth_anomaly
   data2(4,:) = residual+anth_anomaly+methox_anomaly+biog_anomaly
   data2(5,:) = residual+anth_anomaly+methox_anomaly+biog_anomaly+bb_anomaly

    above_colors = (/"gray45","blue","red","forestgreen","orange"/)
    below_colors = (/"gray45","blue","red","forestgreen","orange"/)
    res@xyLineColors         = (/"gray45","blue","red","forestgreen","orange","orange"/)
    res@gsnXYAboveFillColors = above_colors
    res@gsnXYBelowFillColors = below_colors

    res@xyLineThicknessF         = 0.25
    res@pmLegendDisplayMode      = "Never"        ; turn on legend
    res@xyExplicitLegendLabels   = (/"VOC oxidation",  "anthropogenic", "methane ox", "biogenic",\
                                     "biomass burning","total"/)

  plot4 = gsn_csm_xy(wks,plottime,data2,res)

  ;-----------------------------------
  ; Add in text
  ;-----------------------------------
   ;drawNDCGrid(wks)
   ; add station
    txres                   = True                     ; polyline mods desired
     txres@txFontHeightF    = 0.024                    ; font smaller. default big
     txres@txJust           = "CenterLeft"             ; font smaller. default big
     txres@txPerimOn        = True
     txres@txPerimThicknessF= 2.0
   gsn_text_ndc(wks,location_name,0.197,0.84,txres)

  ; -------------------------------
  ; panel the plots
  ; -------------------------------
  res1                     = True
    res1@gsnAttachBorderOn   = False
    res1@tiYAxisFontHeightF  = 0.028
  res2                     = True
    res2@gsnMaximize         = True
    res2@gsnAttachPlotsXAxis = True
    res2@tiXAxisFontHeightF  = 0.028
    res2@tiYAxisFontHeightF  = 0.028

  ; plot1 will be the base plot.
  amid = gsn_attach_plots(plot1,plot4,res1,res2)
  draw(plot1)    ; All three plots will be drawn.
  frame(wks)
  ;draw(plot4)    ; All three plots will be drawn.
  ;frame(wks)

end if ; PLOT

;--------------------------------------------
; Write out to a ASCII file
;--------------------------------------------
if (CSV) then

;---Create dummy mixed data to write to CSV file
  field_strings = (/"time","anomaly","CO"/)
  dq = str_get_dq()                ; double quote character
  field_strings = dq + field_strings + dq        ; Pre/append quotes to field names
  header = [/str_join(field_strings,",")/]       ; Header is field names separated
                                                 ;   by commas.

print(climate_time)

  alist  = [/climate_time,month_anomaly_a(:,n),month_co_avg_a(:,n)/]   ; List of variables to write.
;; Note: if you don't want spaces in CSV file, use the following format string.
 format = "%d,%g,%g"

  system("rm -rf " + outname)               ; Remove file in case it exists.

  write_table(outname, "w", header, "%s")   ; Write header to CSV file.
  write_table(outname, "a", alist, format)  ; Write mixed data to CSV file.


;---Echo the new file to the screen so you can see it.
  print("====== Contents of '" + outname + "' ======")
  system("cat " + outname)
  print("========================================")




end if ;CSV


end

