pro vortex, detector=detector,env_file=env_file

det  = '13XRM:mca1' 
if (keyword_set(detector) ne 0)  then det = detector
if (n_elements(env_file)  eq 0) then begin
  env_file = '//cars5/Data/xas_user/config/13idc_med_environment.dat'
endif

p = obj_new('epics_mca',det, environment_file=env_file)

gcd
print, ' This is vortex::  env file ' , env_file

display = obj_new('mca_display')
display->open_detector, det
end
