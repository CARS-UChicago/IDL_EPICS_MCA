function med_obj, detector=detector
  det = '13GE1:med:'
  if (keyword_set(detector) ne 0 )  then  det = detector
  m = obj_new('EPICS_MED', det)
  return, m
end
