pro mca

; If the environment variable IDL_USERDIR is defined then cd to that directory.
; This allows the mca display program under the IDL Virtual Machine to cd to that directory
; Otherwise it is left in the directory containing mca.sav

path = getenv('IDL_USERDIR')
if strtrim(path,2) ne '' then begin
  print, 'Changing directory to ', path
  cd, path
endif

t = obj_new('mca_display')
end
