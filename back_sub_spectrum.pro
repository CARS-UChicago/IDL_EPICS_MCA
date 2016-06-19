pro back_sub_spectrum, input, background, output, scale=scale
; This procedure creates a new spectrum file where
;   output = input - scale*background
  if (n_elements(scale) eq 0) then scale=1.0
  s = obj_new('mca')
  s->read_file, input
  b = obj_new('mca')
  b->read_file, background
  sd = s->get_data()
  bd = b->get_data()
  o = s->copy()
  od = sd - bd*scale
  o->set_data, od
  o->write_file, output
end