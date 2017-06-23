;============================================
; ultrafine_mopitt.ncl
;============================================
;
; Concepts Illustrated
;          - Interpolate one vertical grid to 
;            another at higher resolution
;          - currently set up to an ultrafune 
;            grid of 10 levels per MOPITT level
;          - average ultrafine interpolated 
;            values over converted levels
;          - Created to convert FTS profiles 
;            to MOPITT grid
;          - only works with 1D profiles
;
; To use call within another ncl program:
;          
;                            RRB Sep 22, 2015
;============================================


undef("ultrafine_mopitt")

function ultrafine_mopitt(valIN[*]:numeric, pressIN[*]:numeric, mopitt_parray:numeric, sublevs:numeric)
;============================================
; Purpose: regrid to higher resolution vertical grid
; 
; Arguments:
;    valIN: The values associated with the pressIN grid.
;
;    pressIN: The native pressure array of the values
;             to be interpolated to a higher resolution grid.
;
;    mopitt_parray: MOPITT pressure levels (10 level reporting edges).
;
;    sublevs: Number of levels per MOPITT level.
;
; Return Value:
;    valOUT: Interpolated values associated with the MOPITT
;            ultrafine grid
;
;============================================
local mopitt_p, mopitt_logp, uf_grid, uf_press, valINTERP, valAVG

begin

  ; check input
  if (dimsizes(valIN).ne.dimsizes(pressIN)) then
    print("ultrafine_mopitt: The input pressure and variables have different dimensions.")
    return
  end if

  ; make grid with max pressure of mopitt surface pressure, min pressure 74
  ; in discrete steps of 10 levels per MOPITT level
  mopitt_p = new((/dimsizes(mopitt_parray)+1/),float)
    mopitt_p(0:9) = mopitt_parray
    mopitt_p(dimsizes(mopitt_p)-1) = 74.
  mopitt_logp = log(mopitt_p)

  ; set up ultrafine grid
  ; levels must be equally spaced in logp coords
  uf_grid = new((/(dimsizes(mopitt_logp)-1)*sublevs/),float)
    do i= 0, dimsizes(mopitt_logp)-3
      if ismissing(mopitt_logp(i)) then
        uf_grid(i*sublevs:i*sublevs+sublevs) = uf_grid@_FillValue
      else
        uf_grid(i*sublevs:i*sublevs+sublevs) = tofloat(fspan(mopitt_logp(i),mopitt_logp(i+1),sublevs+1))
      end if
    end do
    do i= dimsizes(mopitt_logp)-2, dimsizes(mopitt_logp)-2
      uf_grid(i*sublevs:i*sublevs+(sublevs-1)) = tofloat(fspan(mopitt_logp(i),mopitt_logp(i+1),sublevs))
    end do
  uf_grid@units             = "logP"
  uf_press = exp(uf_grid)
  uf_press@units             = "hPa"


 ; Interpolation (using logP) of FTS onto fine grid
 ; include extrapolation to lower levels
 ;                                              != 1 means log interp.
 ;                                              negative means extrapolation
  valINTERP = int2p_n_Wrap(pressIN,valIN,uf_press,-2,0)
  valINTERP!0                 = "level"
  valINTERP&level             = uf_press

  ; correct for where interpolation doesn't account for missing values in the pressure array
  valINTERP = where(ismissing(uf_press),valINTERP@_FillValue,valINTERP)

  valAVG := new((/dimsizes(mopitt_parray)/),float)
  do i= 0,dimsizes(valAVG)-1
    valAVG(i)=sum(valINTERP(i*sublevs:i*sublevs+(sublevs-1)))/sublevs
  end do

  valAVG!0                 = "level"
  valAVG&level             = mopitt_parray

  valOUT = valAVG
  ;valOUT = valINTERP
  return(valOUT)

end


