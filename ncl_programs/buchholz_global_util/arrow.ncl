load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

function arrow(wks,plt,xpts,ypts,res)
; draws an arrow on a plot. calling syntax is same as in gsn_add_polyline()
; Arindam Chakraborty <arch at caos.iisc.ernet.in>, May'10.

begin

 getvalues plt
  "trXMinF": x0
  "trXMaxF": x1
  "trYMinF": y0
  "trYMaxF": y1
 end getvalues

 plt@arr = gsn_add_polyline(wks,plt,xpts,ypts,res)

; determines how broad should the arrow be
 asp = 0.4

 xp1 = xpts(0)
 xp2 = xpts(1)
 yp1 = ypts(0)
 yp2 = ypts(1)

 xp1n = (xp1 - x0)/(x1-x0)
 xp2n = (xp2 - x0)/(x1-x0)
 yp1n = (yp1 - y0)/(y1-y0)
 yp2n = (yp2 - y0)/(y1-y0)

 pi = acos(-1.0)
 rad2deg = 180.0/pi

 theta = atan2((yp2n-yp1n),(xp2n-xp1n))

 if(theta.lt.0 .and. yp2.gt.yp1)then
  theta = pi + theta
 else
  if(theta.gt.0 .and. yp2.lt.yp1)then
   theta = pi + theta
  end if
 end if

; length of the line of arrowhead as a fraction of the length of the given line
 fhead = 0.3
 ahead = sqrt((xp2n-xp1n)*(xp2n-xp1n) + (yp2n-yp1n)*(yp2n-yp1n))*fhead
 phi = atan(asp)

 resp = True

 lambda1 = theta + phi
 xa1n = xp2n - ahead*cos(lambda1)
 ya1n = yp2n - ahead*sin(lambda1)
 xa1 = x0 + xa1n*(x1-x0)
 ya1 = y0 + ya1n*(y1-y0)

 xpts1 = (/xa1,xp2/)
 ypts1 = (/ya1,yp2/)
 plt@arr1 = gsn_add_polyline(wks,plt,xpts1,ypts1,resp)

 lambda2 = theta - phi
 xa2n = xp2n - ahead*cos(lambda2)
 ya2n = yp2n - ahead*sin(lambda2)
 xa2 = x0 + xa2n*(x1-x0)
 ya2 = y0 + ya2n*(y1-y0)
 xpts2 = (/xa2,xp2/)
 ypts2 = (/ya2,yp2/)
 plt@arr2 = gsn_add_polyline(wks,plt,xpts2,ypts2,resp)

 return (plt)
end


begin

 th = ispan(0,360,1)
 y = sin(th*3.1415/180)*10

 wks = gsn_open_wks("X11","arr")

 res = True
 res@gsnDraw = False
 res@gsnFrame = False
 plt = gsn_csm_xy(wks,th,y,res)

 xpts = (/300,10/)
 ypts = (/2.0,-4/)

 resp = True
 arr = arrow(wks,plt,xpts,ypts,resp)
; arr = gsn_add_polyline(wks,plt,xpts,ypts,resp)

 draw(plt)
 frame(wks)
end
