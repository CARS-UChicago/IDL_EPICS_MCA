function fit_background, input, $
                        threshold=threshold, $
                        smooth=smooth, $
                        degree=degree, $
                        tension=tension

    if (n_elements(threshold) eq 0) then threshold = [1000., .2, .2]
    if (n_elements(smooth) eq 0) then smooth=10
    if (n_elements(degree) eq 0) then degree=10
    if (n_elements(tension) eq 0) then tension=1.

    data = smooth(double(input), smooth)
    nchans = n_elements(data)
    ; The following needs to be double precision else spline gives arithmetic
    ; errors
    x = dindgen(nchans)  
    d1 = smooth(deriv(data), smooth)
    d2 = deriv(d1)

    bad0 = where(data gt threshold[0])
    bad1 = where(abs(d1) gt threshold[1])
    bad2 = where(-d2 gt threshold[2])

    bad = [bad0, bad1, bad2]
    bad = bad[sort(bad)]
    bad = bad[uniq(bad)]

    t = x
    t[bad]=-1.
    good = where(t ge 0.)

    x1 = x[good]/nchans  ; Scale X to range 0 to 1
    x2 = x/nchans
    y1 = data[good]
    big = max(y1)
    y1 = y1/big
    background = spline(x1, y1, x2, tension)
;    y2 = interpol(y1, x1, x2)
;    y2 = spl_init(x1, y1)
;    background = spl_interp(x1, y1, y2, x2)
;    spline_p, x1, y1, x2, background, interval=1./nchans
;    coeffs = poly_fit(x2, y2, degree)
;    background = poly(x2, coeffs)
    background = background*big
    background = background < data
    return, background
end


