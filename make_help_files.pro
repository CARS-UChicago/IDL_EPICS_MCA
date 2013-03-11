dest = '/home/epics/web_software/idl/'
mk_html_help, 'mca__define.pro', dest+'mca_class.html', $
    title = 'MCA Class'
mk_html_help, 'epics_mca__define.pro', dest+'epics_mca_class.html', $
    title = 'EPICS_MCA Class'
mk_html_help, 'med__define.pro', dest+'med_class.html', $
    title = 'Multi-element Detector (MED) Class'
mk_html_help, 'epics_med__define.pro', dest+'epics_med_class.html', $
    title = 'EPICS Multi-element Detector (EPICS_MED) Class'
mk_html_help, 'jcpds__define.pro', dest+'jcpds_class.html', $
    title = 'JCPDS Class'
mk_html_help, ['atomic_number.pro', $
               'atomic_symbol.pro', $
               'lookup_xrf_line.pro', $
               'lookup_gamma_line.pro', $
               'lookup_jcpds_line.pro', $
               'read_jcpds.pro', $
               'read_peaks.pro', $
               'write_peaks.pro', $
               'fit_background.pro', $
               'fit_peaks.pro', $
               'extract_spectra_scans.pro', $
               'read_spectrum.pro' ], dest+'mca_utility_routines.html', $
    title = 'MCA Utility Routines'


end
