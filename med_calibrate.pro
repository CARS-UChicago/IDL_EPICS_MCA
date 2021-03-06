;
;   Calibrating the 13 Element MED :  NOT TESTED!!
;

pro med_calibrate, med=med_
;  .compile read_peaks
  PV = '13GE3:med:'

  collect_time = 40
  if (n_elements(med_)  ne 0)  then  PV = med_

  med = obj_new('EPICS_MED', PV)

  print, "  Calibrating the 16-element detector: ", PV
  print, "  You will need the Cd109 and Fe55 source"
  print, ""
  print, " Put in Cd109 source, and hit any key to continue (or 'a' to abort):"

  s = get_kbrd(1)
  s = strlowcase(s)
  if (s eq 'a') then return

  print, format='(1x,a,$)', $
    " Collecting Cd109 spectra  Please wait ... "

  help, med
  s   = caput(PV+'PresetReal', collect_time)
  s   = caput(PV+'EraseStart.VAL',   1)

  collecting = 1
  wait, collect_time
  while (collecting) do begin
      wait, 0.5
      s   = caget(PV+'Acquiring',  is_collecting)
      if (s eq 0) then collecting = is_collecting
  endwhile
  med->initial_calibration, lookup_xrf_line('Ag Ka')
  print, "done. Initial calibration with Ag is complete."

  print, " "
  print, " Add the Fe55 source, and hit any key to continue (or 'a' to abort):"

  s = get_kbrd(1)
  s = strlowcase(s)
  if (s eq 'a') then return

  print, format='(1x,a,$)', " Collecting Fe55 spectra.  Please wait ... "

  s   = caput(PV+'PresetReal', collect_time)
  s   = caput(PV+'EraseStart.VAL',   1)
  collecting = 1
  wait, collect_time
  while (collecting) do begin
      wait, 0.5
      s   = caget(PV+'Acquiring',  is_collecting)
      if (s eq 0) then collecting = is_collecting
  endwhile

  s0   = parse_peak('Mn Ka')
  s1   = parse_peak('Ag Ka')
  s2   = parse_peak('Ag Kb')
  s_peaks = [s0,s1,s2]

  print, format='(1x,a,$)', " doing final calibration ..."
  med->final_calibration, s_peaks
  print, "done."
  print, " "
  ask_count = 0
ask:
  print, " Would you like to copy all ROIS from a selected detector"
  print, format='(1x,a,$)',"to all other detectors (y/n):"

  s = get_kbrd(1)
  s = strlowcase(s)
  if (s eq 'n') then return
  if (s ne 'y') then begin
      ask_count = ask_count + 1
      if (ask_count gt 7)  then begin
          print, " That's it, I give up."
          return
      endif
      print, " please type  y or n."
      goto, ask
  endif

  read, s, prompt="Detector number to copy ROIS from:"
  n = fix(strtrim(s,2))
  med->copy_rois, n, /energy
  print, "done.   Calibration complete."
return
end
