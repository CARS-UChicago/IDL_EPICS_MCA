function bm3, p, v0, k0, k0p
;
;Given the 0 pressure volume, bulk modulus, 
;pressure derivative of the bulk modulus, and a pressure,
;this function returns the volume at pressure
;(for cubic or hexagonal system) by iteratively solving the third order
;Birch-Murnaghan equation. The program does this by starting
; at 0 pressure and stepping up at dp pressure intervals until
; the desired pressure is reached.
;
dp = 0.1
f=0.0
ptest = 0.0
c1 = 3.0*k0
c2 = 9.0*k0*(4.0-k0p)
while(ptest le p) do begin
ftest=10.0
while(ftest ge 0.0001) do begin
    y = (1.0 + 2.0*f)^2.5
    xx = (1.0 + 2.0*f)^1.5
    p1 = y*(c1*f-0.5*c2*f*f)
    dpdf = 5.0*xx*(c1*f - 0.5*c2*f*f)+y*(c1-c2*f)
    df = (ptest - p1)/dpdf
    ftest=abs(df)
    f=f+df
endwhile
ptest=ptest+dp
endwhile
xx = (1.0 + 2.0*f)^1.5
v = v0/xx
return, v
end

