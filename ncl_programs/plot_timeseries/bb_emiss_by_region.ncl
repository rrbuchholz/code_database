;================================================;
;  bb_emiss_by_region.ncl
;================================================;
;
;--------------------------------------------------
; This NCL code plots timeseries of BB emissions
; that have already been extracted for a region.
; 
; Currently hardwired to work with four regions.
;
;--- To use type:
;---             bb_emiss_by_region.ncl
;
;                                       rrb 20170417
;--------------------------------------------------
; ================================================;

begin

; =========================================
; USER DEFINED
; =========================================
  tracer = "CO"
  reso = "0.94x1.2"
  
  PLOT = True
    plottype = "x11"
      ;plottype@wkWidth  = 1200
      ;plottype@wkHeight = 1200
      ;plottype@wkPaperWidthF  = 7.0 ;for pdf
      ;plottype@wkPaperHeightF = 20  ;for pdf
    ;plotname = "test"


; =========================================
; SET UP
; =========================================
  ; -------------------------------
  ; emission files
  ; -------------------------------
   indir = "/data14b/buchholz/qfed/cam_"+reso+"/region_sums/"
   e_file_in = "qfed.emis_"+tracer+"_"+reso+"_Tg_regional.nc"

  ; -------------------------------
  ; data names (from ncl_filedump)
  ; -------------------------------
   emiss1           = "bb_0"
   emiss2           = "bb_1"
   emiss3           = "bb_2"
   emiss4           = "bb_3"

; ----------------------------------------
; Load data 1
; ----------------------------------------
    fin = addfile(indir+e_file_in, "r")
      emiss_in1         := fin->$emiss1$
      emiss_in2         := fin->$emiss2$
      emiss_in3         := fin->$emiss3$
      emiss_in4         := fin->$emiss4$

      time = emiss_in1&time
      yfrac = tofloat(cd_calendar(time,4))


; =========================================
; PLOT the timeseries
; =========================================
if (PLOT) then

 wks   = gsn_open_wks ("x11","xy")               ; send graphics to PNG file

 res                  = True                     ; plot mods desired
   res@gsnDraw          = False
   res@gsnFrame         = False

  plot1  = gsn_csm_xy(wks,yfrac,emiss_in1,res) ; create plot
  plot2  = gsn_csm_xy(wks,yfrac,emiss_in2,res) ; create plot
  plot3  = gsn_csm_xy(wks,yfrac,emiss_in3,res) ; create plot
  plot4  = gsn_csm_xy(wks,yfrac,emiss_in4,res) ; create plot

  panel_res                       = True
      panel_res@txString              = "BB emissions for "+ tracer
      panel_res@gsnPanelFigureStrings = (/emiss_in1@region, emiss_in2@region, emiss_in3@region, emiss_in4@region/)

    gsn_panel(wks,(/plot1,plot2,plot3,plot4/),(/2,2/),panel_res)


end if

end
