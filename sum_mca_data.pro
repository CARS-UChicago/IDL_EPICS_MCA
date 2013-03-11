pro sum_mca_data, specName = specName, npts = npts, first_subDir = first_subDir, $
            last_subDir = last_subDir

;This procedure sums the mca data for muti yeild pass. It then writes new mca files
;using the name of the first mca file in a new sub directory with the name:
;"first_subDir-last_subDir"

if (keyword_set(specName) eq 0 ) then begin
    print, 'Enter SPEC filename'
    return
    endif

;SPEC file name used during the yeild scan
;specName = '30554d_oct05.spc'
;Number of points in the yeild scan
;npts = 150
;Sub directory of the first pass
;first_subDir = 16
;Sub directory of the last pass
;last_subDir = 22

mca = obj_new('mca')

;The number of passes
nPasses = last_subDir - first_subDir +1
FOR j = 0, npts DO BEGIN ;Loop on the number of points in each yeild scan

    ;Creat the extention string for each scan point "angle"
    extention = string(j, format = '(i3.3)')

    ;Init the array used to sum the spectrums
    sumData = 0
    ;Init the elapsed time sum used so that dead time is calculated correctly
    sumElapsed_live = 0
    sumElapsed_real = 0

    print, 'Input files'
    FOR i=0,nPasses - 1 DO BEGIN ;Loop on the number of pass

       ;Creat the sub directory string
        subDir = string(first_subDir + i, format = '(i3.3)')

       ;Build the file name for the spectrum - assumes IDL is in dir above the subDir
        filename = subDir + '\' + specName + '_'+ subDir + '.' + extention
       print, filename

       ;Read the file
        mca->read_file, filename

       ;Get the data
        data = mca->get_data()

       ;Sum the data
        sumData = sumData + data

       ;Get the elapsed time for each spectrum
        elapsed=mca->get_elapsed()
        ;sum the live and real time
        sumElapsed_live = sumElapsed_real + elapsed.live_time
        sumElapsed_real = sumElapsed_real + elapsed.real_time



    ENDFOR

    ;Set the mca data to the sum
    mca->set_data, sumData
    ;plot, sumData

    ;Pass the sum of real and live to elapsed structure
    elapsed.live_time = sumElapsed_live
    elapsed.real_time = sumElapsed_real

    ;Set the mca elapsed time to the sum
    mca->set_elapsed, elapsed

    ;Build the file name to write the sum data
    subDirRange = string(first_subDir, format = '(i2.2)') + '-' + string(last_subDir, format = '(i2.2)')
    ;Make a sub directory to put the sum data into
    file_mkdir, subDirRange

    ;For this to work with Tom's yeild program we need to write the intergration data using a
    ;file name in a standard format where the spec scan number is in the file name. To solve this
    ;we will use the file names of the first pass.
    subDir = string(first_subDir, format = '(i3.3)')

    filename = subDirRange + '\' + specName + '_' + subDir + '.' + extention

    print, 'Output file'
    print, filename

    ;Write the sum data to the directory IDL is running in
    mca->write_file, filename

ENDFOR

END


