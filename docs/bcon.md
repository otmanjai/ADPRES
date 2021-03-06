---
title: %BCON
theme: _config.yml
filename: bcon
---

# %BCON Card

This card is used to input boron concentration parameters. `%BCON` and `%CBCS` shall not present together.

| `%BCON` | Variable | Description | Remarks |
| --- | --- | --- | --- |
| LINE 1 | BCON | Core boron concentration in ppm | Used as guess if `%THER` card active |
| LINE 2 | RBCON | Reference boron concentration in ppm from which the interpolation is done | Dummy if `%XTAB` card present |
| LINE 3 | CISGTR(g) | Macroscopic Cross Section changes due to changes of boron concentration in ppm  | Repeat LINE 2 NG times. And again repeat this input segment NMAT times. **This line is not necessary if `%XTAB` card present** |
|   | CSIGA(g) |
|   | CNUF(g) |
|   | CSIGF(g) |
|   | CSIGS(g,1:NG) |
| LINE 4 | POPT | Print option if users want to print this card | Optional |

Example:
```
! BORON CONCENTRATION
%BCON
560.53  1200.2  ! Boron concentration ref. in ppm
! CX change per unit ppm change of Boron concentration
!  sigtr          siga         nu*sigf    kappa*sigf  sigs_g1   sigs_g2
 6.11833E-08  1.87731E-07   0.00000E+00   0.00000E+00  0.0   7.91457E-10
 5.17535E-06  1.02635E-05   0.00000E+00   0.00000E+00  0.0   0.00000E+00    !COMP 1
 0.00000E+00  0.00000E+00   0.00000E+00   0.00000E+00  0.0   0.00000E+00
 7.76184E-04  8.44695E-05   0.00000E+00   0.00000E+00  0.0   0.00000E+00    !COMP 2
 0.00000E+00  0.00000E+00   0.00000E+00   0.00000E+00  0.0   0.00000E+00
 7.76184E-04  8.44695E-05   0.00000E+00   0.00000E+00  0.0   0.00000E+00    !COMP 3
 3.47809E-08  1.28505E-07  -1.12099E-09  -1.76188E-20  0.0  -1.08590E-07
-9.76510E-06  7.08807E-06  -2.43045E-06  -3.19085E-17  0.0   0.00000E+00    !COMP 4
 3.53826E-08  1.26709E-07  -1.67880E-09  -2.49965E-20  0.0  -1.06951E-07
-8.50169E-06  6.82311E-06  -2.72445E-06  -3.57680E-17  0.0   0.00000E+00    !COMP 5
 3.59838E-08  1.24986E-07  -2.21038E-09  -3.20225E-20  0.0  -1.05374E-07
-7.46251E-06  6.59798E-06  -2.95883E-06  -3.88451E-17  0.0   0.00000E+00    !COMP 6
 3.37806E-08  1.19869E-07  -1.71323E-09  -2.49965E-20  0.0  -1.00873E-07
-6.73744E-06  6.29310E-06  -2.55359E-06  -3.35223E-17  0.0   0.00000E+00    !COMP 7
 3.32495E-08  1.17585E-07  -1.72421E-09  -2.54896E-20  0.0  -9.88578E-08
-6.19725E-06  6.11904E-06  -2.48880E-06  -3.26704E-17  0.0   0.00000E+00    !COMP 8
 3.27201E-08  1.15319E-07  -1.73502E-09  -2.56049E-20  0.0  -9.68489E-08
-5.68220E-06  5.94711E-06  -2.42240E-06  -3.17976E-17  0.0   0.00000E+00    !COMP 9
 3.43859E-08  1.18186E-07  -2.24335E-09  -3.20225E-20  0.0  -9.93312E-08
-5.86898E-06  6.08443E-06  -2.77657E-06  -3.64509E-17  0.0   0.00000E+00    !COMP 10
 3.38559E-08  1.15917E-07  -2.25369E-09  -3.24873E-20  0.0  -9.73291E-08
-5.38345E-06  5.91697E-06  -2.70780E-06  -3.55476E-17  0.0   0.00000E+00    !COMP 11
1
```
