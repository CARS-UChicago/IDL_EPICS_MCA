;
; convert MED data to columns of energy and counts, summing all channels
;
pro med2ascii, file=file, output=output

if (n_elements(file) eq 0) then begin
    print, ' syntax:  med2ascii, file= file, output= output'
    print, ' '
    return
endif

ext     = '.asc'
outf    = file + ext
if (n_elements(output) ne 0) then outf = output

openw,  olun, outf, /get_lun
printf, olun , '; Data From ', file

openr, inx, file, /get_lun
str  = ' '
while not (eof(inx)) do begin
    readf, inx, str
    str  = strtrim(str,2)
    s   = strcompress(str)
    if (strmid(s,0,5) eq 'DATA:') then goto, loop_end
    if (strlen(s) le 60) then  printf, olun, '; ', s
endwhile
loop_end:
close, inx
free_lun, inx

m      = obj_new('MED')
m->read_file, file
counts = m->get_data(/align, /total)
energy = m->get_energy()


xx = size(counts)
npts =  xx[1]

printf, olun, ';----------------------------------------------------------'
printf, olun, ';    energy       counts'
for k=0,npts-1 do begin
    printf, olun, energy[k,0], counts[k]
endfor

print, 'wrote ', outf
close, olun
free_lun, olun
return
end
