pro write_med_files, detector_pv, ndet, file=file

   ;;detector_pv = '13GE2:med:'
   ;;med = obj_new('EPICS_MED', '13IDC:med:', 13, bad=[3,7])

  print, detector_pv
  print, ndet

    m = obj_new('EPICS_MED',detector_pv, ndet)
    if (OBJ_VALID(m) eq 0) then return

    ; some pv's
    pv_ecw = detector_pv + 'EnableClientWait'
    pv_cw = detector_pv + 'ClientWait'
    pv_aqu = detector_pv + 'Acquiring'
    pv_fname = detector_pv + 'ClientWait.DESC'
    pv_pr    = detector_pv + 'PresetReal'
    pv_er    = detector_pv + 'ElapsedReal'

    t = casetmonitor(pv_aqu)
    t = cacheckmonitor(pv_aqu)

    print, "new one"

    ; Enable waiting for client
    t = caput(pv_ecw, 1)

    ; Set client wait flag to done
    t = caput(pv_cw, 0)

    ; get the filename
    if (n_elements(file) ne 0) then begin
        fname = file
        use_pv_fname = 0
    endif else begin
    ;    t = caget(pv_fname,fname)
        use_pv_fname = 1;
    endelse

    started = 0;

    while (1) do begin

        ; Exit if enable client wait is shut off
        ;t = caget(pv_ecw,status)
        ;if (status eq 0) then return

        ; Wait for client wait to go busy
        ; ie EraseStart was hit
        print, 'wait for client wait'
        started = 0

        while (1) do begin
            if(cacheckmonitor(pv_aqu) eq 1) then begin
                t= caget(pv_aqu,aqu_started)
                print, "aquisition = ",aqu_started
                if(aqu_started eq 0) then break
            endif
            wait, .01
            t = caget(pv_ecw,status)
            if (status eq 0) then return
        endwhile


        print, 'aquisition is apparently complete'


        ; make sure we're done counting...
        ; below was included as a double check, shouldnt really need this
        rt_flag = 0
        prrt = 0
        rt = -1
        while (rt_flag eq 0 ) do begin
            ;t = caget('13GE1:med:PresetReal',prrt)
            ;t = caget('13GE1:med:ElapsedReal',rt)
            t = caget(pv_pr,prrt)
            t = caget(pv_er,rt)
            print, 'prrt, rt', prrt, rt
            if (rt lt prrt) then rt_flag = 0 else rt_flag = 1
        endwhile


        ; Write file
        if (use_pv_fname eq 1) then t = caget(pv_fname,fname)
        if ((t ne 0) or (fname eq '')) then begin
           print, pv_fname + ' is null, filename not set'
           print, 'Pass filename to routine or use med_on in SPEC'
           return
        endif
        m -> write_file, fname
        print, 'Saved file: ', fname
        if (use_pv_fname eq 0) then  fname = increment_filename(fname)
        ;fname = increment_filename(fname)

        ; Reset the client wait flag to done
        ; the scan program can move to the next point and hit
        ; EraseStart again
        t = caget(pv_aqu, done)
        print,  'setting client wait to done: aqu = ', done

        t = caput(pv_cw, 0)        

    endwhile
end

;*****************************************************************************

