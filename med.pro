;   MED
;
;   Simple Graphical User Interface to Multi-Element-Detector
;   M Newville  2001-08-Nov
;
;
;
pro med_event, event
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
    ctime  = 0
    s    = caget((*p).det + 'ElapsedReal', ctime)
    s    = caget((*p).det + 'Acquiring', status)
    wtime= 15.0
    stat = 'Ready'
    if ((status gt 0) or ((*p).acq_count lt 3)) then begin
        wtime = 0.5
        stat  = 'Acquiring'
    endif
    (*p).acq_count = (*p).acq_count + 1
    stime = strtrim(string(ctime,format='(f8.2)'),2)
    Widget_Control, (*p).form.status,   set_value = stat
    Widget_Control, (*p).form.time_rbv, set_value = stime
    Widget_Control, (*p).form.timer,    time= wtime
endif else begin
    ; print, 'med_event uval: ', uval
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
            (*p).med_disp->open_detector, dx
            Widget_Control, (*p).form.status,   set_value = 'Ready'
            Widget_Control, (*p).form.elem,     set_value = elem
        end
        'start': begin
            if ((*p).erase_on_start eq 1) then begin
                s = caput((*p).det + 'EraseStart', 1)
            endif else begin
                s = caput((*p).det + 'StartAll', 1)
            endelse
            widget_control, (*p).form.timer,     time = 0.50
            (*p).acq_count = 1
        end
        'stop': begin
            s = caput((*p).det + 'StopAll', 1)
        end
        'erase': begin
            s = caput((*p).det + 'EraseAll', 1)
        end
        'time_ent': begin
            Widget_Control, (*p).form.time_ent, get_value=v
            s = caput((*p).det + 'PresetReal', a2f(v))
        end
        'copy_rois': begin
            s = 'Copying ROIs from ' + strtrim(string((*p).elem),2)
            Widget_Control, (*p).form.status,   set_value = s
            Widget_Control, (*p).form.time_rbv, set_value = ' '
            (*p).med->copy_rois,  (*p).elem, /energy
            Widget_Control, (*p).form.status,   set_value = 'Ready'
        end
        'save': begin
            tfile = (*p).file
            file = dialog_pickfile(filter='*.xrf', $
                                   get_path=path, $
                                   /write, file = tfile)
            if (strlen(file) ne 0) then begin
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
return
end


pro med, detector=detector
;
; GUI control of Multi-Element-Detector
;
det      = '13GE1:med:'
elem     = 7
status   = 'Ready'
time_ent = '1.00'
time_rbv = '0.00'
tfile    = 'test.xrf'

if (keyword_set(detector) ne 0 ) then det = detector
med_disp= obj_new()
med     = obj_new()
form    = {pos:0L, time_rbv:0L, elem:0L, $
           serase_y:0L , serase_n:0L, $
           time_ent:0L,timer:0L, status:0L}
info    = {med_disp:med_disp, med:med, form:form, $
           erase_on_start:1, file:tfile, $
           det:det, elem:elem, acq_count:1, $
           time_ent:time_ent,time_rbv:time_rbv}

; menus
main   = Widget_Base(title = 'MED Control', /col, app_mbar = mbar)
menu   = Widget_Button(mbar, value= 'File')
x      = Widget_Button(menu, value= 'Save ...', uval= 'save')
x      = Widget_Button(menu, value= 'Exit',     uval= 'exit', /sep)
menu   = Widget_Button(mbar, value= 'Options')
mx     = widget_button(menu, value = 'Start Will Erase ... ', /menu)
info.form.serase_y = widget_button(mx, value = ' * Yes ', uvalue='serase_y')
info.form.serase_n = widget_button(mx, value = '   No  ', uvalue='serase_n')


; main page
frm = Widget_Base(main, /row)
lfr = Widget_Base(frm,  /column,/frame)
rfr = Widget_Base(frm,  /column,/frame)

; Right Hand Side for control buttons
f   = Widget_Base(rfr, /row)
x   = Widget_Label(f,  value = 'Acquire Time: ')
info.form.time_ent = CW_Field(f,   title = '', $
                              xsize = 7, uval = 'time_ent', $
                              value = strtrim(info.time_ent,2), $
                              /return_events, /floating)
x   = Widget_Label(f,  value = 's')
f   = Widget_Base(rfr, /col)
bsiz= 50
uf  = Widget_Base(f, /row)
x   = Widget_Button(uf, value = 'Start',    uval='start', xsize=bsiz)
x   = Widget_Button(uf, value = 'Stop',     uval='stop',  xsize=bsiz)
x   = Widget_Button(uf, value = 'Erase',    uval='erase', xsize=bsiz)


f   = Widget_Base(rfr, /row)
x   = Widget_Button(f, value = 'Copy ROIS',    uval='copy_rois')
x   = Widget_Button(f, value = 'Save Spectra', uval='save')

info.form.timer = f

;
uf  = Widget_Base(rfr, /row, /frame)
x   = Widget_Label(uf, value = 'Viewing Element: ')
info.form.elem = Widget_Label(uf, value = strtrim(string(info.elem),2),xsize=25)

uf   = Widget_Base(rfr, /row, /frame)
info.form.status   = Widget_Label(uf, value = 'Initializing...', xsize=130)

info.form.time_rbv = Widget_Label(uf,value=strtrim(info.time_rbv,2),$
                                  xsize=35)

;
; Left Hand Side shows Detector Element Layout
;
uf  = Widget_Base(lfr, /row)
x   = Widget_Label(uf, value = 'Elements')
f   = Widget_Base(lfr, /row)
tf  = Widget_Base(f, /col)
bsiz= 30
os0 = bsiz*1.2
os1 = bsiz*0.5
os2 = bsiz*2.0
x   = Widget_Label(tf, value = ' ', ysize=os0)
x   = Widget_Button(tf, value = '14 ',  uval='elem14',xsize=bsiz,ysize=bsiz)
x   = Widget_Button(tf, value = '15 ',  uval='elem15',xsize=bsiz,ysize=bsiz)


tf  = Widget_Base(f,/col)
x   = Widget_Label(tf, value = ' ', ysize=os1)
x   = Widget_Button(tf, value = ' 1 ',  uval='elem1',xsize=bsiz,ysize=bsiz)
x   = Widget_Button(tf, value = ' 2 ',  uval='elem2',xsize=bsiz,ysize=bsiz)
x   = Widget_Button(tf, value = ' 3 ',  uval='elem3',xsize=bsiz,ysize=bsiz)
x   = Widget_Button(tf, value = ' 4 ',  uval='elem4',xsize=bsiz,ysize=bsiz)


tf  = Widget_Base(f,/col)
x   = Widget_Button(tf, value = ' 5 ',  uval='elem5',xsize=bsiz,ysize=bsiz)
x   = Widget_Button(tf, value = ' 6 ',  uval='elem6',xsize=bsiz,ysize=bsiz)
x   = Widget_Button(tf, value = ' 7 ',  uval='elem7',xsize=bsiz,ysize=bsiz)
x   = Widget_Button(tf, value = ' 8 ',  uval='elem8',xsize=bsiz,ysize=bsiz)
x   = Widget_Button(tf, value = ' 9 ',  uval='elem9',xsize=bsiz,ysize=bsiz)

tf  = Widget_Base(f,/col)
x   = Widget_Label(tf, value = ' ', ysize=os1)
x   = Widget_Button(tf, value = '10 ',  uval='elem10',xsize=bsiz,ysize=bsiz)
x   = Widget_Button(tf, value = '11 ',  uval='elem11',xsize=bsiz,ysize=bsiz)
x   = Widget_Button(tf, value = '12 ',  uval='elem12',xsize=bsiz,ysize=bsiz)
x   = Widget_Button(tf, value = '13 ',  uval='elem13',xsize=bsiz,ysize=bsiz)

tf  = Widget_Base(f,/col)
x   = Widget_Label(tf, value = ' ', ysize=os2)
x   = Widget_Button(tf, value = '16 ',  uval='elem16',xsize=bsiz,ysize=bsiz)
x   = Widget_Label(tf, value = ' ', ysize=os1)


; render widgets, load info structure into main
p    = ptr_new(info,/no_copy)
Widget_Control,  main, set_uval=p
Widget_Control,  main, /realize
xmanager, 'med', main, /no_block

; Finally, load real versions of the mca_display and EPICS_MED objects
; This will take some time, so we start with 'Initializing ...' in the
; status message

Widget_Control, (*p).form.time_rbv, set_value  = ' '

(*p).med_disp = obj_new('mca_display')

dmca  = (*p).det + 'mca' + strtrim(string((*p).elem),2)
(*p).med_disp->open_detector, dmca
(*p).med = obj_new('EPICS_MED', det)

x   = caput(det + 'PresetReal', a2f(time_ent))
;
; when objects are really created, report 'Ready'.
;
Widget_Control, (*p).form.status,   set_value = 'Ready'

;
return
end
