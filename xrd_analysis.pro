pro xrd_analysis
;
; program to read out *.chi files and subtract
; background for analysis
;
device, decomposed=0
file = dialog_pickfile(/read, filter='*.chi',path='T:\dac_user\frames\data\2001\may01\gl\n2')
openr, lun, file, /get
title=''
readf, lun, title
header=''
readf,lun, header
readf,lun, header
readf, lun, npts
xdata = fltarr(npts)
ydata = fltarr(npts)
for i = 0, npts-1 do begin
 readf, lun, xtemp, ytemp
 xdata(i) = xtemp
 ydata(i) = ytemp
endfor
plot, xdata, ydata, title=title, $
      xtitle='Twotheta', ytitle='Intensity', $
      background=255, color=0

limits = dialog_message(/question, 'Do you want to change limits ?')
if limits eq 'Yes' then begin
 message = dialog_message(/info, 'Use LMB twice to define limits')
 cursor, x, y, /down
 xmin = x
 cursor, x, y, /down
 xmax = x
 plot, xdata, ydata, title=title, $
      xtitle='Twotheta', ytitle='Intensity', $
      background=255, color=0, xrange = [xmin, xmax], $
      xstyle=1
endif
bkgd = dialog_message(/question, 'Do you want to subtract bkgd ?')
if bkgd eq 'Yes' then begin
 message = dialog_message(/info, 'Use LMB to select and RMB to quit')
endif

end