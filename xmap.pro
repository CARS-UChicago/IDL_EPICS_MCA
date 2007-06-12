;   MED
;
;   Simple Graphical User Interface to Multi-Element-Detector
;   M Newville  2001-08-Nov
;
;
;
pro xmap_event, event
; event handler for med
Widget_Control, event.top, get_uval = p
Widget_Control, event.id,  get_uval = uval
ErrorNo = 0
Catch, ErrorNo
if (ErrorNo ne 0) then begin
    Catch, /CANCEL
    ErrA = ['Error!', 'Number' + strtrim(!error, 2), !Err_String]
    a = Dialog_Message(ErrA, /ERROR)
    return
endif

; timer runs at 0.5 sec when acquiring, so as to update the
; 'elapsed time' field, and at 15 sec otherwise.
if (tag_names(event, /structure_name) eq 'WIDGET_TIMER') then begin
    status = 0
    xt1    = (*p).ctime
    xt2    = 0
    s      = caget((*p).det + 'ElapsedReal',xt1)
    s      = caget((*p).det + 'mca1.ERTM',  xt2)
    (*p).ctime = xt2
    stime  = strtrim(string(xt2,format='(f7.2)'),2)

    s    = caget((*p).det + 'Acquiring', status)
    stat = 'Ready'
    (*p).update_time = 2.0
    if ((status gt 0) or ((*p).acq_count lt 2)) then begin
        stat = 'Acquiring'
        (*p).update_time = 0.25
    endif
    (*p).acq_count = (*p).acq_count + 1

    Widget_Control, (*p).form.status,   set_value = stat
    Widget_Control, (*p).form.time_rbv, set_value = stime
    check_time  =  1

 endif else begin
     ; print, 'med_event uval: ', uval
     (*p).update_time = 2.0
     check_time = 1
     if (strmid(uval,0,4) eq 'elem') then begin
         elem = strmid(uval,4)
         uval = 'elem'
     endif else if (strmid(uval,0,7) eq 'serase_') then begin
         sel = strmid(uval,7)
         uval = 'serase'
     endif
     case uval of
         'exit':  begin
             Widget_Control, event.top, /destroy
         end
         'elem': begin
             dx = (*p).det + 'mca' + strtrim(elem,2)
             (*p).elem = fix(elem)
             s  = 'Loading Element ' + elem
             Widget_Control, (*p).form.status,   set_value = s
             Widget_Control, (*p).form.time_rbv, set_value = ' '
             if (obj_valid((*p).med_disp)) then  (*p).med_disp->open_detector, dx
             (*p).update_time = 2.0
             ; Widget_Control, (*p).form.elem,     set_value = elem
         end
         'start': begin
             if ((*p).erase_on_start eq 1) then begin
                 s = caput((*p).det + 'EraseStart', 1)
             endif else begin
                 s = caput((*p).det + 'StartAll', 1)
             endelse
             (*p).acq_count   = 1
             (*p).update_time = 0.25
         end
         'continuous': begin
             s = caput((*p).det + 'PresetReal', 0.00)
             check_time = 0
             if ((*p).erase_on_start eq 1) then begin
                 s = caput((*p).det + 'EraseStart', 1)
             endif else begin
                 s = caput((*p).det + 'StartAll', 1)
             endelse
             (*p).acq_count   = 1
             (*p).update_time = 0.25
         end
         'stop': begin
             s = caput((*p).det + 'StopAll', 1)
         end
         'erase': begin
             s = caput((*p).det + 'EraseAll', 1)
         end
         'time_ent': begin
             Widget_Control, (*p).form.time_ent, get_value=v
             (*p).presetreal = a2f(v)
             s = caput((*p).det + 'PresetReal', a2f(v))
             check_time = 0
         end
         'copy_rois': begin
             s = 'Copying ROIs from ' + strtrim(string((*p).elem),2)
             Widget_Control, (*p).form.status,   set_value = s
             Widget_Control, (*p).form.time_rbv, set_value = ' '

             xm = obj_new('EPICS_MED', (*p).det)
             xm->copy_rois, (*p).elem, /energy
; MN 05/31/03  GE1 seems to need two copy_rois to work right...
;             if ((*p).det eq '13GE1:med:') then begin
;                  print, ' using copy_rois kludge for GE1'
;                  (*p).med->copy_rois,  (*p).elem
;              endif else begin
;                  print, ' using copy_rois kludge for GE2'
;                  (*p).med->copy_rois,  (*p).elem, /energy
;              endelse
;              (*p).med->copy_rois,  (*p).elem, /energy
             obj_destroy, xm
             Widget_Control, (*p).form.status,   set_value = 'Ready'
         end
         'new_mca': begin
             (*p).med_disp = obj_new('mca_display')
             dmca  = (*p).det + 'mca' + strtrim(string((*p).elem),2)
             (*p).med_disp->open_detector, dmca
         end

         'save': begin
             tfile = (*p).file
             file = dialog_pickfile(filter='*.xrf', $
                                    get_path=path, $
                                    /write, file = tfile)
             if (strlen(file) ne 0) then begin
                 cd, path
                 (*p).file = file
                 Widget_Control, (*p).form.status,   set_value = 'Saving Spectra'
                 Widget_Control, (*p).form.time_rbv, set_value = ' '
                 (*p).med->write_file, file

                 Widget_Control, (*p).form.status,   set_value = 'Ready'
             endif
         end
         'serase': begin
             yorn =  [ [' * No ', '   No '] , [ '   Yes', ' * Yes'] ]
             isel = 0
             if (sel eq 'y') then isel = 1
             (*p).erase_on_start = isel
             Widget_Control, (*p).form.serase_y, set_value=yorn[isel,1]
             Widget_Control, (*p).form.serase_n, set_value=yorn[isel,0]
         end
         else: begin
             print, ' unknown event : ', uval
         end
     endcase

 endelse

 Widget_Control, (*p).form.timer,   time= (*p).update_time
 ; print, ' update ', (*p).update_time
 ; recheck preset real time and update display
 if (check_time eq 1) then begin ; and ((*p).acq_count) mod 3)) then begin
    check_time = 1
    Widget_Control, (*p).form.time_ent, get_value = v
    ; t1 = a2f(v)
    old = (*p).presetreal
    s  = caget((*p).det + 'PresetReal', pr)
    ; presetreal changed somewhere else:
    if (abs(pr-old) ge 1.e-2) then begin
        (*p).presetreal = pr
        te = strtrim(string(pr,format='(g7.3)'),2)
        Widget_Control, (*p).form.time_ent, set_value = te
    endif
endif


return
end


pro xmap, detector=detector, use=use, env_file=env_file, no_gcd=no_gcd, ndet=ndet
;
; GUI control of Multi-Element-Detector
;

det      = 'dxpXMAP:'
ndetectors = 4
elem     = 1
status   = 'Ready'
time_ent = '1.00'
time_rbv = '0.00'
tfile    = 'test.xrf'
time_mon = det + 'ElapsedReal'

if (keyword_set(use) ne 0 ) then begin
   use_det = strlowcase(use)
   if (use_det eq 'ge1') then det = '13GE1:med:'
   if (use_det eq 'ge2') then det = '13GE2:med:'
   if (use_det eq 'xmap') then det = 'dxpXMAP:'
endif

if (keyword_set(ndet) ne 0)     then ndetectors = ndet
if (keyword_set(detector) ne 0) then det = detector
if (n_elements(env_file)  eq 0) then begin
  env_file = '//cars5/Data/xas_user/config/13idc_med_environment.dat'
  env_file = '//cars5/Data/xas_user/config/xmap_med_environment.dat'
endif

print, ' env file ' , env_file
gcd


med_disp= obj_new()
med     = obj_new()

x = casetmonitor(time_mon)
; caSetTimeout, 0.003
; caSetRetryCount, 500
preset = 0.
x   = caget(det + 'PresetReal', preset)
time_ent = strtrim(string(preset,format='(f7.2)'),2)

form    = {pos:0L, time_rbv:0L, elem:0L, $
           serase_y:0L , serase_n:0L,  $
           time_ent:0L,timer:0L, status:0L}
info    = {med_disp:med_disp, med:med, form:form, $
           erase_on_start:1, file:tfile, $
           det:det, elem:elem, acq_count:1,  update_time:1.0, $
           time_mon:time_mon, ctime:0.0, presetreal:0.0, $
           time_ent:time_ent,time_rbv:time_rbv}

; menus
main   = Widget_Base(title = '4 Element Vortex(XMAP) Control', /col, app_mbar = mbar)
menu   = Widget_Button(mbar, value= 'File')
x      = Widget_Button(menu, value= 'Save Spectra', uval= 'save')
x      = widget_button(menu, value= 'New MCA Display', uvalue='new_mca')
x      = Widget_Button(menu, value= 'Exit',     uval= 'exit', /sep)

menu   = Widget_Button(mbar, value= 'Options')
mx     = widget_button(menu, value= 'Start Will Erase ... ', /menu)

info.form.serase_y = widget_button(mx, value = ' * Yes ', uvalue='serase_y')
info.form.serase_n = widget_button(mx, value = '   No  ', uvalue='serase_n')

; main page
info.form.timer = widget_base(main)
mx  = info.form.timer
frm = Widget_Base(mx, /row)
lfr = Widget_Base(frm,  /column,/frame)
rfr = Widget_Base(frm,  /column,/frame)

; Right Hand Side for control buttons
f   = Widget_Base(rfr, /row)
x   = Widget_Label(f,  value = 'Acquire Time: ')
info.form.time_ent = CW_Field(f,   title = '', $
                              xsize = 9, uval = 'time_ent', $
                              value = strtrim(info.time_ent,2), $
                              /return_events, /floating)
x   = Widget_Label(f,  value = 's')
f   = Widget_Base(rfr, /col)
bsiz= 50
uf  = Widget_Base(f, /row)
x   = Widget_Button(uf, value = 'Start',    uval='start', xsize=bsiz)
x   = Widget_Button(uf, value = 'Stop',     uval='stop',  xsize=bsiz)
x   = Widget_Button(uf, value = 'Erase',    uval='erase', xsize=bsiz)

uf  = Widget_Base(f, /row)
x   = Widget_Button(uf, value = 'Continuous Collection', uval='continuous')

f   = Widget_Base(rfr, /row)
x   = Widget_Button(f, value = 'Copy ROIS',    uval='copy_rois')
x   = Widget_Button(f, value = 'Save Spectra', uval='save')


;
; uf  = Widget_Base(rfr, /row, /frame)
; x   = Widget_Label(uf, value = 'Viewing Element: ')
; info.form.elem = Widget_Label(uf, value = strtrim(string(info.elem),2),xsize=25)

uf   = Widget_Base(rfr, /row, /frame)
info.form.status   = Widget_Label(uf, value = 'Initializing...', xsize=130)

info.form.time_rbv = Widget_Label(uf,value=strtrim(info.time_rbv,2),$
                                  xsize=35)

;
; Left Hand Side shows Detector Element Layout
;
uf  = Widget_Base(lfr, /row)
x   = Widget_Label(uf, value = 'Detector Elements')
f   = Widget_Base(lfr, /row)
tf  = Widget_Base(f, /col)
bsiz= 50
os0 = bsiz*1.2
os1 = bsiz*0.5
os2 = bsiz*2.0
x   = Widget_Button(tf, value = '1 ',  uval='elem1',xsize=bsiz,ysize=bsiz)
x   = Widget_Button(tf, value = '2 ',  uval='elem2',xsize=bsiz,ysize=bsiz)

tf  = Widget_Base(f,/col)
x   = Widget_Button(tf, value = ' 3 ',  uval='elem3',xsize=bsiz,ysize=bsiz)
x   = Widget_Button(tf, value = ' 4 ',  uval='elem4',xsize=bsiz,ysize=bsiz)

; render widgets, load info structure into main
p    = ptr_new(info,/no_copy)
Widget_Control,  main, set_uval=p
Widget_Control,  main, /realize
xmanager, 'xmap', main, /no_block

; Finally, load real versions of the mca_display and EPICS_MED objects
; This will take some time, so we start with 'Initializing ...' in the
; status message

Widget_Control, (*p).form.time_rbv, set_value  = ' '

(*p).med_disp = obj_new('mca_display')

dmca  = (*p).det + 'mca' + strtrim(string((*p).elem),2)
(*p).med_disp->open_detector, dmca
; (*p).med = obj_new('EPICS_MED', det)
(*p).med = obj_new('EPICS_MED', det, ndetectors, environment_file=env_file)


; when objects are really created, report 'Ready'.
;
Widget_Control, (*p).form.status,   set_value = 'Ready'

;
return
end
