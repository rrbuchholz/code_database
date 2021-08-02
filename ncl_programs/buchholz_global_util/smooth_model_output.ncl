;============================================
; smooth_model_output.ncl
;============================================
;
; Concepts Illustrated
;          - Use satellite averaging kernels and
;            a priori to smooth model output
;
; To use call within another ncl program:
;        smoothed_column = smooth_model_output(data_array,satellite_ak,satellite_ap)
;          
;                            RRB Feb 26, 2020
;============================================

undef("smooth_model_output")

function smooth_model_output(valIN[*][*][*]:numeric)
;============================================
; Purpose: regrid to higher resolution vertical grid
; 
; Arguments:
;    valIN: The model values. Needs lat, lon, lev coordinate variables.
;
;    satAK: The satellite averaging kernel.
;
;    satAP: Satellite a priori.
;
;
; Return Value:
;    valOUT: Model output smoothed to measurement space
;
;============================================
local mopitt_p, mopitt_logp, uf_grid, uf_press, valINTERP, valAVG

begin

printVarSummary(valIN)
printVarSummary(satAK)
printVarSummary(satAP)
printVarSummary(satPSURF)
exit

; horizontal regrid

; vertical regrid

; apply AK


  valOUT = valSMOOTH
  return(valOUT)

end
