pro plot_mca_fft, mca, _extra=extra
    t = caget(mca + '.VAL', data)
    t = caget(mca + '.DWEL', dwell)
    nchans = n_elements(data)
    nchans = nchans/2
    p = abs(fft(data, -1))
    p = p[0:nchans-1]
    freq = findgen(nchans)/(nchans-1)/dwell/2.
    plot, freq, p, _extra=extra
end