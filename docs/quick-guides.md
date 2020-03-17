---
title: Quick install guide
theme: _config.yml
filename: quick-guides
---

# Quick Guides
ADPRES input is designed to be self-explanatory. It has 12 input cards, for example: `%mode`, `%geom`, `%xsec`, and so on. Some cards are mandatory for any problems. While some cards are conditional, depending on the problem being solved and some cards are optional. Comments are marked by `!`. For example, the following is the [IAEA3D input](https://github.com/imronuke/ADPRES/tree/master/smpl/static)

```
! IAEA3D input data
! NODE SIZE = 10 cm
! PARCS K-EFF  : 1.029096
! ADPRES K-EFF : 1.029082 (ERROR = 1.4 PCM)

! Mode card
%MODE
FORWARD

! Case card
%CASE
IAEA3D
10 CM NODE SIZE

! Cross-sections card
%XSEC
2  5    ! Number of groups and number of materials
! sigtr   siga   nu*sigf sigf   chi   sigs_g1  sigs_g2
0.222222  0.010  0.000  0.000    1.0   0.1922   0.020
0.833333  0.080  0.135  0.135    0.0   0.000    0.7533   ! MAT1 : Outer Fuel
0.222222  0.010  0.000  0.000    1.0   0.1922   0.020
0.833333  0.085  0.135  0.135    0.0   0.000    0.7483   ! MAT2 : Inner Fuel
0.222222  0.0100 0.000  0.000    1.0   0.1922   0.020
0.833333  0.1300 0.135  0.135    0.0   0.000    0.7033   ! MAT3 : Inner Fuel + Control Rod
0.166667  0.000  0.000  0.000    0.0   0.1267   0.040
1.111111  0.010  0.000  0.000    0.0   0.000    1.1011   ! MAT4 : Reflector
0.166667  0.000  0.000  0.000    0.0   0.000    0.040
1.111111  0.055  0.000  0.000    0.0   0.000    0.000    ! MAT5 : Reflector + Control Rod
%GEOM
9 9 19         !nx, ny, nz
10.0 8*20.0    !x-direction assembly size in cm
1  8*2         !x-direction assembly divided into 2 (10 cm each)
8*20.0 10.0    !y-direction assembly size in cm
8*2  1         !y-direction assembly divided into 2 (10 cm each)
19*20.0        !z-direction assembly  in cm
19*1           !z-direction nodal is not divided
4              !np number of planar type
1  13*2  4*3  4     !planar assignment (from bottom to top)
! Planar_type_1 (Bottom Reflector)
  4  4  4  4  4  4  4  4  4
  4  4  4  4  4  4  4  4  4
  4  4  4  4  4  4  4  4  4
  4  4  4  4  4  4  4  4  4
  4  4  4  4  4  4  4  4  0
  4  4  4  4  4  4  4  4  0
  4  4  4  4  4  4  4  0  0
  4  4  4  4  4  4  0  0  0
  4  4  4  4  0  0  0  0  0
! Planar_type_2 (Fuel)
  3  2  2  2  3  2  2  1  4
  2  2  2  2  2  2  2  1  4
  2  2  2  2  2  2  1  1  4
  2  2  2  2  2  2  1  4  4
  3  2  2  2  3  1  1  4  0
  2  2  2  2  1  1  4  4  0
  2  2  1  1  1  4  4  0  0
  1  1  1  4  4  4  0  0  0
  4  4  4  4  0  0  0  0  0
! Planar_type_3 (Fuel+Partial Control Rods)
  3  2  2  2  3  2  2  1  4
  2  2  2  2  2  2  2  1  4
  2  2  3  2  2  2  1  1  4
  2  2  2  2  2  2  1  4  4
  3  2  2  2  3  1  1  4  0
  2  2  2  2  1  1  4  4  0
  2  2  1  1  1  4  4  0  0
  1  1  1  4  4  4  0  0  0
  4  4  4  4  0  0  0  0  0
! Planar_type_4 (Top reflectors)
  5  4  4  4  5  4  4  4  4
  4  4  4  4  4  4  4  4  4
  4  4  5  4  4  4  4  4  4
  4  4  4  4  4  4  4  4  4
  5  4  4  4  5  4  4  4  0
  4  4  4  4  4  4  4  4  0
  4  4  4  4  4  4  4  0  0
  4  4  4  4  4  4  0  0  0
  4  4  4  4  0  0  0  0  0
! Boundary conditions (east), (west), (north), (south), (bottom), (top)
1 2 2 1 1 1
```