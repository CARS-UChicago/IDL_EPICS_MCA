function read_jcpds, file

    openr, lun, file, /get_lun
    header1 = ''
    header2 = ''
    temp1 = fltarr(5)
    temp2 = fltarr(5)
    data = fltarr(5, 100)
    readf, lun, header1
    readf, lun, temp1
    readf, lun, header2

    i=0
    while (not eof(lun)) do begin
        readf, lun, temp2
        data(*,i)=temp2
        i=i+1
    endwhile
    free_lun, lun
    data=data(*,0:i-1)

    ; The symmetry codes are as follows:
    ;   1 -- cubic
    ;   2 -- hexagonal
    result = { $
        file:    file, $
        header:  header1, $
        sym:     long(temp1[0]), $
        a0:      temp1[1], $
        k0:      temp1[2], $
        k0p:     temp1[3], $
        c0a0:    temp1[4], $
        v0:      temp1[1], $
        d:       reform(data[0,*]), $
        inten:   reform(data[1,*]), $
        h:       reform(long(data[2,*])), $
        k:       reform(long(data[3,*])), $
        l:       reform(long(data[4,*]))  $
    }
    if result.sym eq 1 then result.v0 = result.a0^3
    if result.sym eq 2 then result.v0 = $
                sqrt(3.) * result.a0^3 * result.c0a0 / 2.0
    return, result
end


