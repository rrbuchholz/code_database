;***********************************************************************;
; Function : add_arrow                                                  ;
;                   wks: workstation object                             ;
;                plotid: plot object                                    ;
;                   xpts: 1-dimensional array of x points               ;
;                   ypts: 1-dimensional array of y points               ;
;               resources: optional resources                           ;
;                                                                       ;
; This function draws an arrow on a plot ("plotid" is returned from a   ;
; previous call to one of the gsn_* plotting functions). Syntax is      ; 
; based on gsn_add_polyline(). "xpts" and "ypts" are the x              ;
; and y locations of each point in the arrow line, in the same          ;
; data space as the data from "plotid". "resources" is an optional list ;
; of resources. This function returns the primitive object created.     ;
;                                                                       ;
; If you resize or move the plot, the arrow anfd line will stay with    ;
; the plot.                                                             ;
;                             Originally created by Arindam Chakraborty ;
;                                  <arch at caos.iisc.ernet.in>, May'10 ;
;                                                          rrb 20170707 ;
;***********************************************************************;
undef("add_arrow")
function add_arrow(wks:graphic,plotid:graphic,xpts[*]:numeric,\
                   ypts[*]:numeric,resources:logical)

begin

 getvalues plotid
  "trXMinF": x0
  "trXMaxF": x1
  "trYMinF": y0
  "trYMaxF": y1
 end getvalues

 arr = unique_string("middle")
 arr1 = unique_string("left")
 arr2 = unique_string("right") 

 plotid@$arr$ := gsn_add_polyline(wks,plotid,xpts,ypts,resources)

; determines how broad should the arrow be
 asp = 0.2

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
 fhead = 0.2
 ahead = sqrt((xp2n-xp1n)*(xp2n-xp1n) + (yp2n-yp1n)*(yp2n-yp1n))*fhead
 phi = atan(asp)

  resp = get_resources(resources)

 lambda1 = theta + phi
 xa1n = xp2n - ahead*cos(lambda1)
 ya1n = yp2n - ahead*sin(lambda1)
 xa1 = x0 + xa1n*(x1-x0)
 ya1 = y0 + ya1n*(y1-y0)

 xpts1 = (/xa1,xp2/)
 ypts1 = (/ya1,yp2/)
 plotid@$arr1$ := gsn_add_polyline(wks,plotid,xpts1,ypts1,resp)

 lambda2 = theta - phi
 xa2n = xp2n - ahead*cos(lambda2)
 ya2n = yp2n - ahead*sin(lambda2)
 xa2 = x0 + xa2n*(x1-x0)
 ya2 = y0 + ya2n*(y1-y0)
 xpts2 = (/xa2,xp2/)
 ypts2 = (/ya2,yp2/)
 plotid@$arr2$ := gsn_add_polyline(wks,plotid,xpts2,ypts2,resp)


 return (plotid)
end

