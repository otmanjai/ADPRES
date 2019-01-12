MODULE th

IMPLICIT NONE

SAVE

! REAL :: kv   ! Water kinematic viscosity
! REAL :: Pr  !Prandtl Number
! REAL :: tcon  ! Thermal conductivity (W/mK)

CONTAINS

SUBROUTINE th_iter(ind)

  !
  ! Purpose:
  !    To do thermal-hydrailics iteration
  !

  USE sdata, ONLY: nnod, ftem, mtem, cden, bcon, bpos, npow, pow, ppow,  &
                   zdel, node_nf, ix, iy, iz, th_err, node_nf, ix, iy, iz, th_niter
  USE nodal, ONLY: nodal_coup4, outer4th, PowDis
  USE InpOutp, ONLY: XS_updt, ounit

  IMPLICIT NONE

  INTEGER, INTENT(IN), OPTIONAL :: ind    ! if iteration reaching th_iter and ind = 0 then STOP
  REAL, DIMENSION(nnod) :: pline
  REAL, DIMENSION(nnod) :: otem
  INTEGER :: n, niter

  th_err = 1.
  niter = 0
  DO
      niter = niter + 1

      ! Save old moderator temp
      otem = ftem

      ! Update XS
      CALL XS_updt(bcon, ftem, mtem, cden, bpos)

      ! Update nodal couplings
      CALL nodal_coup4()

      ! Perform outer inner iteration
      CALL outer4th(20)

      ! Calculate power density
      CALL PowDis(npow)

      ! Calculate linear power density for each nodes (W/cm)
      DO n = 1, nnod
          pline(n) = npow(n) * pow * ppow * 0.01 &
                   / (node_nf(ix(n),iy(n)) * zdel(iz(n)))     ! Linear power density (W/cm)
      END DO

      ! Update fuel, moderator temp. and coolant density
      CALL th_upd(pline)

      th_err = MAXVAL(ABS(ftem - otem))
      IF ((th_err < 0.01) .OR. (niter == th_niter)) EXIT
  END DO

  IF (PRESENT(ind)) THEN
    IF ((niter == th_niter) .AND. (ind == 0)) THEN
       WRITE(ounit,*) '  MAXIMUM TH ITERATION REACHED.'
       WRITE(ounit,*) '  CALCULATION MIGHT BE NOT CONVERGED OR CHANGE ITERATION CONTROL'
       STOP
    END IF
  END IF



END SUBROUTINE th_iter


SUBROUTINE par_ave_f(par, ave)
!
! Purpose:
!    To calculate average fuel temp (only for active core)
!

USE sdata, ONLY: vdel, nnod, ng, nuf

IMPLICIT NONE

REAL, DIMENSION(:), INTENT(IN) :: par
REAL, INTENT(OUT) :: ave
REAL :: dum, dum2
INTEGER :: n

dum = 0.; dum2 = 0.
DO n = 1, nnod
   IF (nuf(n,ng) > 0.) THEN
      dum = dum + par(n) * vdel(n)
      dum2 = dum2 + vdel(n)
   END IF
END DO

ave = dum / dum2

END SUBROUTINE par_ave_f


SUBROUTINE par_ave(par, ave)
!
! Purpose:
!    To calculate average moderator temp (only for radially active core)
!

USE sdata, ONLY: vdel, nnod

IMPLICIT NONE

REAL, DIMENSION(:), INTENT(IN) :: par
REAL, INTENT(OUT) :: ave
REAL :: dum, dum2
INTEGER :: n

dum = 0.; dum2 = 0.
DO n = 1, nnod
   dum = dum + par(n) * vdel(n)
   dum2 = dum2 + vdel(n)
END DO

ave = dum / dum2

END SUBROUTINE par_ave


SUBROUTINE par_max(par, pmax)
!
! Purpose:
!    To calculate maximum fuel tem, coolant tem, and density
!

USE sdata, ONLY: nnod

IMPLICIT NONE

REAL, DIMENSION(:), INTENT(IN) :: par
REAL, INTENT(OUT) :: pmax
INTEGER :: n

pmax = 0.
DO n = 1, nnod
   IF (par(n) > pmax) pmax = par(n)
END DO

END SUBROUTINE par_max


SUBROUTINE getent(t,ent)
!
! Purpose:
!    To get enthalpy for given coolant temp. from steam table
!

USE sdata, ONLY: stab, ntem
USE InpOutp, ONLY : ounit

IMPLICIT NONE

REAL, INTENT(IN) :: t
REAL, INTENT(OUT) :: ent
REAL :: t1, ent1
REAL :: t2, ent2
INTEGER :: i

IF ((t < 473.15) .OR. (t > 617.91)) THEN
    WRITE(ounit,*) '  Coolant temp. : ', t
    WRITE(ounit,*) '  ERROR : MODERATOR TEMP. IS OUT OF THE RANGE OF DATA IN THE STEAM TABLE'
    WRITE(ounit,*) '  CHECK INPUT MASS FLOW RATE OR POWER'
    STOP
END IF

t2 = stab(1,1); ent2 = stab(1,3)
DO i = 2, ntem
    t1 = t2
    ent1 = ent2
    t2 = stab(i,1); ent2 = stab(i,3)
    IF ((t >= t1) .AND. (t <= t2)) THEN
        ent = ent1 + (t - t1) / (t2 - t1) * (ent2 - ent1)
        EXIT
    END IF
END DO


END SUBROUTINE getent


SUBROUTINE gettd(ent,t,rho,prx,kvx,tcx)
!
! Purpose:
!    To get enthalpy for given coolant temp. from steam table
!

USE sdata, ONLY: stab, ntem
USE InpOutp, ONLY : ounit

IMPLICIT NONE

REAL, INTENT(IN) :: ent
REAL, INTENT(OUT) :: t, rho, prx, kvx, tcx
REAL :: t1, rho1, ent1, kv1, pr1, tc1
REAL :: t2, rho2, ent2, kv2, pr2, tc2
REAL :: ratx

INTEGER :: i

IF ((ent < 858341.5) .OR. (ent > 1624307.1)) THEN
    WRITE(ounit,*) '  Enthalpy. : ', ent
    WRITE(ounit,*) '  ERROR : ENTHALPY IS OUT OF THE RANGE OF DATA IN THE STEAM TABLE'
    WRITE(ounit,*) '  CHECK INPUT MASS FLOW RATE OR POWER'
    STOP
END IF

t2 = stab(1,1); rho2 = stab(1,2); ent2 = stab(1,3)
pr2 = stab(1,4); kv2 = stab(1,5); tc2 = stab(1,6)
DO i = 2, ntem
    t1 = t2
    ent1 = ent2
    rho1 = rho2
    pr1 = pr2
    kv1 = kv2
    tc1 = tc2
    t2 = stab(i,1); rho2 = stab(i,2); ent2 = stab(i,3)
    pr2 = stab(i,4); kv2 = stab(i,5); tc2 = stab(i,6)
    IF ((ent >= ent1) .AND. (ent <= ent2)) THEN
        ratx = (ent - ent1) / (ent2 - ent1)
        t   = t1   + ratx * (t2 - t1)
        rho = rho1 + ratx * (rho2 - rho1)
        prx = pr1  + ratx * (pr2 - pr1)
        kvx = kv1  + ratx * (kv2 - kv1)
        tcx = tc1 + ratx * (tc2 - tc1)
        EXIT
    END IF
END DO


END SUBROUTINE gettd


REAL FUNCTION getkc(t)
!
! Purpose:
!    To calculate thermal conductivity of cladding
!

IMPLICIT NONE

REAL, INTENT(IN) :: t

getkc = 7.51 + 2.09E-2*t - 1.45E-5*t**2 + 7.67E-9*t**3

END FUNCTION getkc


REAL FUNCTION getkf(t)
!
! Purpose:
!    To calculate thermal conductivity of fuel
!

IMPLICIT NONE

REAL, INTENT(IN) :: t

getkf = 1.05 + 2150. / (t - 73.15)

END FUNCTION getkf


REAL FUNCTION getcpc(t)
!
! Purpose:
!    To calculate specific heat capacity of cladding
!

IMPLICIT NONE

REAL, INTENT(IN) :: t

getcpc = 252.54 + 0.11474*t

END FUNCTION getcpc


REAL FUNCTION getcpf(t)
!
! Purpose:
!    To calculate specific heat capacity of fuel
!

IMPLICIT NONE

REAL, INTENT(IN) :: t

getcpf = 162.3 + 0.3038*t - 2.391e-4*t**2 + 6.404e-8*t**3

END FUNCTION getcpf


SUBROUTINE TridiaSolve(a,b,c,d,x)
!
! Purpose:
!    To solve tridiagonal matrix
!

IMPLICIT NONE

REAL, DIMENSION(:), INTENT(INOUT) :: a, b, c, d
REAL, DIMENSION(:), INTENT(OUT) :: x

INTEGER :: i, n

n = SIZE(d)

! Gauss Elimination
c(1) = c(1)/b(1)
d(1) = d(1)/b(1)
DO i = 2, n
    c(i) = c(i) / (b(i) - a(i) * c(i-1))
    d(i) = (d(i) - a(i) * d(i-1)) / (b(i) - a(i) * c(i-1))
END DO

! Back Substitution
x(n) = d(n)
DO i = n-1, 1, -1
    x(i) = d(i) - c(i) * x(i+1)
END DO

END SUBROUTINE TridiaSolve



REAL FUNCTION geths(xden, tc, kv, Pr)
!
! Purpose:
!    To calculate heat transfer coef.
!

USE sdata, ONLY: dh, farea, cflow

IMPLICIT NONE

REAL, INTENT(IN) :: xden  ! coolant densisty
REAL, INTENT(IN) :: tc  ! coolant thermal conductivity
REAL, INTENT(IN) :: kv  ! kinematic viscosity
REAL, INTENT(IN) :: Pr  ! Prandtl Number

REAL :: cvelo, Nu, Re

cvelo = cflow / (farea * xden * 1000.)        ! Calculate flow velocity (m/s)
Re = cvelo * dh / (kv * 1e-6)                 ! Calculate Reynolds Number
Nu = 0.023*(Pr**0.4)*(Re**0.8)                ! Calculate Nusselt Number
geths = (tc / dh) * Nu                        ! Calculate heat transfer coefficient


END FUNCTION geths



SUBROUTINE th_trans(xpline, h)

!
! Purpose:
!    To perform fuel pin thermal transient
!

USE sdata, ONLY: mtem, cden, ftem, tin, xyz, cflow, nyy, nzz, cf, ent, heatf, nnod, &
                 ystag, tfm, nt, rpos, rdel, rf, rg, rc, farea, dia, pi, zdel, ystag

IMPLICIT NONE

REAL, DIMENSION(:), INTENT(IN) :: xpline    ! Linear Power Density (W/cm)
REAL, INTENT(IN) :: h                       ! Time step

INTEGER :: i, j, k, n
REAL, DIMENSION(nt+1) :: a, b, c, d
REAL :: hs, hg = 1.e4, kt           ! coolant heat transfer coef., gap heat transfer coef, and thermal conductivity
REAL :: alpha = 0.7
REAL :: xa, xc, tem
REAL :: fdens = 10.412e3            ! UO2 density (kg/m3)
REAL :: cdens = 6.6e3               ! Cladding density (kg/m3)
REAL :: cp                          ! Specific heat capacity
REAL :: eta
REAL :: mdens, vol                  ! Coolant density and channel volume
REAL, DIMENSION(nnod) :: entp        ! previous enthalpy

REAL :: pdens      ! power densisty  (W/m3)
REAL :: enti       ! Coolant inlet enthalpy
REAL :: cpline     ! Coolant Linear power densisty (W/m)
REAL :: Pr, kv, tcon ! Coolant Prandtl Number, Kinematic viscosity, and thermal conductivity

CALL getent(tin, enti)
entp = ent

DO k = 1, nzz
    DO j = 1, nyy
        DO i = ystag(j)%smin, ystag(j)%smax

            mdens = cden(xyz(i,j,k)) * 1000.                                    ! Coolant density (kg/m3)
            cpline = heatf(xyz(i,j,k)) * pi * dia  &
                  + cf * xpline(xyz(i,j,k)) * 100.                              ! Coolant Linear power densisty (W/m)
            vol   = farea * zdel(k) * 0.01
            IF (k == 1) THEN                                                    ! Calculate coolant enthalpy
                eta = enti + entp(xyz(i,j,k))
                ent(xyz(i,j,k)) = (cpline * zdel(k) * 0.01 * h &
                                + (cflow * h - 0.5 * mdens * vol) * enti &
                                + 0.5 * mdens * vol * eta) &
                                / (0.5 * mdens * vol + cflow * h)
                CALL gettd(0.5 * (enti + ent(xyz(i,j,k))), mtem(xyz(i,j,k)), &
                          cden(xyz(i,j,k)), Pr, kv, tcon)                             ! Get corresponding temp and density
            ELSE
                eta = entp(xyz(i,j,k-1)) + entp(xyz(i,j,k))
                ent(xyz(i,j,k)) = (cpline * zdel(k) * 0.01 * h &
                                + (cflow * h - 0.5 * mdens * vol) * ent(xyz(i,j,k-1)) &
                                + 0.5 * mdens * vol * eta) &
                                / (0.5 * mdens * vol + cflow * h)
                CALL gettd(0.5 * (ent(xyz(i,j,k-1)) + ent(xyz(i,j,k))), &
                           mtem(xyz(i,j,k)), cden(xyz(i,j,k)), Pr, kv, tcon)          ! Get corresponding temp and density
            END IF


            hs = geths(cden(xyz(i,j,k)), Pr, kv, tcon)                                               ! Calculate heat transfer coef
            pdens = (1. - cf) * 100. * xpline(xyz(i,j,k)) / (pi * rf**2)                ! Fuel pin Power Density (W/m3)

            ! Calculate tridiagonal matrix: a, b, c and source: d
            ! For nt=1 [FUEL CENTERLINE]
            tem = 0.5 * (tfm(xyz(i,j,k),1) + tfm(xyz(i,j,k),2))                        ! Average temp. to get thermal conductivity
            kt = getkf(tem)                                                            ! Get thermal conductivity
            cp = getcpf(tfm(xyz(i,j,k),1))                                                           ! Get specific heat capacity
            eta = fdens * cp * rpos(1)**2 / (2. * h)
            xc  = kt * rpos(1) / rdel(1)
            b(1) =  xc + eta
            c(1) = -xc
            d(1) = pdens * 0.5 * rpos(1)**2 + eta * tfm(xyz(i,j,k),1)

            DO n = 2, nt-2
                tem = 0.5 * (tfm(xyz(i,j,k),n) + tfm(xyz(i,j,k),n+1))
                kt = getkf(tem)
                cp = getcpf(tfm(xyz(i,j,k),n))
                eta = fdens * cp * (rpos(n)**2 - rpos(n-1)**2) / (2. * h)
                xa = xc
                xc = kt * rpos(n) / rdel(n)
                a(n) = -xa
                b(n) =  xa + xc + eta
                c(n) = -xc
                d(n) = pdens * 0.5 * (rpos(n)**2 - rpos(n-1)**2) &
                     + eta * tfm(xyz(i,j,k),n)
            END DO

            ! For nt-1 [FUEL-GAP INTERFACE]
            cp = getcpf(tfm(xyz(i,j,k),nt-1))
            eta = fdens * cp * (rf**2 - rpos(nt-2)**2) / (2. * h)
            xa = xc
            xc = rg * hg
            a(nt-1) = -xa
            b(nt-1) =  xa + xc + eta
            c(nt-1) = -xc
            d(nt-1) = pdens * 0.5 * (rf**2 - rpos(nt-2)**2) &
                    + eta * tfm(xyz(i,j,k),nt-1)

            ! For nt [GAP-CLADDING INTERFACE]
            tem = 0.5 * (tfm(xyz(i,j,k),nt) + tfm(xyz(i,j,k),nt+1))
            kt = getkc(tem)      ! For cladding
            cp = getcpc(tfm(xyz(i,j,k),nt))
            eta = cdens * cp * (rpos(nt)**2 - rg**2) / (2. * h)
            xa = xc
            xc = kt * rpos(nt) / rdel(nt)
            a(nt) = -xa
            b(nt) =  xa + xc + eta
            c(nt) = -xc
            d(nt) = eta * tfm(xyz(i,j,k),nt)

            ! For nt+1  [CLADDING-COOLANT INTERFACE]
            cp = getcpc(tfm(xyz(i,j,k),nt+1))
            eta = cdens * cp * (rc**2 - rpos(nt)**2) / (2. * h)
            xa = xc
            xc = rc * hs
            a(nt+1) = -xa
            b(nt+1) =  xa + xc + eta
            d(nt+1) = rc * hs * mtem(xyz(i,j,k)) &
                    + eta * tfm(xyz(i,j,k),nt+1)

            ! Solve tridiagonal matrix
            CALL TridiaSolve(a, b, c, d, tfm(xyz(i,j,k), :))

            ! Get lumped fuel temp
            ftem(xyz(i,j,k)) = (1.-alpha) * tfm(xyz(i,j,k), 1) &
                             + alpha * tfm(xyz(i,j,k), nt-1)

            ! Calculate heat flux
            heatf(xyz(i,j,k)) = hs * (tfm(xyz(i,j,k), nt+1) - mtem(xyz(i,j,k)))

        END DO
    END DO
END DO

END SUBROUTINE th_trans




SUBROUTINE th_upd(xpline)

!
! Purpose:
!    To update thermal parameters
!

USE sdata, ONLY: mtem, cden, ftem, tin, xyz, cflow, nyy, nzz, cf, ent, heatf, &
                 ystag, tfm, nt, rpos, rdel, rf, rg, rc, pi, zdel, dia, ystag

IMPLICIT NONE

REAL, DIMENSION(:), INTENT(IN) :: xpline    ! Linear Power Density (W/cm)

INTEGER :: i, j, k, n
REAL, DIMENSION(nt+1) :: a, b, c, d
REAL :: hs, Hg = 1.e4, kt
REAL :: alp = 0.7
REAL :: xa, xc, tem
REAL :: pdens      ! power densisty  (W/m3)
REAL :: enti       ! Coolant inlet enthalpy
REAL :: cpline     ! Coolant Linear power densisty (W/m)
REAL :: Pr, kv, tcon ! Coolant Prandtl Number, Kinematic viscosity, and thermal conductivity

CALL getent(tin, enti)

DO k = 1, nzz
    DO j = 1, nyy
        DO i = ystag(j)%smin, ystag(j)%smax

            cpline = heatf(xyz(i,j,k)) * pi * dia  &
                   + cf * xpline(xyz(i,j,k)) * 100.                             ! Coolant Linear power densisty (W/m)

            IF (k == 1) THEN                                                    ! Calculate coolant enthalpy and
                ent(xyz(i,j,k)) = enti + cpline * zdel(k) * 0.01 / cflow        ! corresponding temp and density
                CALL gettd(0.5 * (enti + ent(xyz(i,j,k))), &
                           mtem(xyz(i,j,k)), cden(xyz(i,j,k)), Pr, kv, tcon)      ! Get corresponding temp and density
            ELSE
                ent(xyz(i,j,k)) = ent(xyz(i,j,k-1)) &
                                + cpline * zdel(k) * 0.01 / cflow
                CALL gettd(0.5 * (ent(xyz(i,j,k-1)) + ent(xyz(i,j,k))), &
                          mtem(xyz(i,j,k)), cden(xyz(i,j,k)), Pr, kv, tcon)       ! Get corresponding temp and density
            END IF

            hs = geths(cden(xyz(i,j,k)), Pr, kv, tcon)
            pdens = (1. - cf) * 100. * xpline(xyz(i,j,k)) / (pi * rf**2)        ! Fuel pin Power Density (W/m3)

            ! Calculate tridiagonal matrix: a, b, c and source: d
            tem = 0.5 * (tfm(xyz(i,j,k),1) + tfm(xyz(i,j,k),2))                 ! Average temp. to get thermal conductivity
            kt = getkf(tem)                                                     ! Get thermal conductivity
            xc  = kt * rpos(1) / rdel(1)
            b(1) =  xc
            c(1) = -xc
            d(1) = pdens * 0.5 * rpos(1)**2

            DO n = 2, nt-2
                tem = 0.5 * (tfm(xyz(i,j,k),n) + tfm(xyz(i,j,k),n+1))
                kt = getkf(tem)
                xa = xc
                xc = kt * rpos(n) / rdel(n)
                a(n) = -xa
                b(n) =  xa + xc
                c(n) = -xc
                d(n) = pdens * 0.5 * (rpos(n)**2 - rpos(n-1)**2)
            END DO

            ! For nt-1 [FUEL-GAP INTERFACE]
            xa = xc
            xc = rg * Hg
            a(nt-1) = -xa
            b(nt-1) =  xa + xc
            c(nt-1) = -xc
            d(nt-1) = pdens * 0.5 * (rf**2 - rpos(nt-2)**2)

            ! For nt [GAP-CLADDING INTERFACE]
            tem = 0.5 * (tfm(xyz(i,j,k),nt) + tfm(xyz(i,j,k),nt+1))
            kt = getkc(tem)      ! For cladding
            xa = xc
            xc = kt * rpos(nt) / rdel(nt)
            a(nt) = -xa
            b(nt) =  xa + xc
            c(nt) = -xc
            d(nt) = 0.

            ! For nt+1  [CLADDING-COOLANT INTERFACE]
            xa = xc
            a(nt+1) = -xa
            b(nt+1) =  xa + hs * rc
            d(nt+1) = rc * hs * mtem(xyz(i,j,k))

            ! Solve tridiagonal matrix
            CALL TridiaSolve(a, b, c, d, tfm(xyz(i,j,k), :))

            ! Get lumped fuel temp
            ftem(xyz(i,j,k)) = (1.-alp) * tfm(xyz(i,j,k), 1) + alp * tfm(xyz(i,j,k), nt-1)

            ! Calculate heat flux
            heatf(xyz(i,j,k)) = hs * (tfm(xyz(i,j,k), nt+1) - mtem(xyz(i,j,k)))


        END DO
    END DO


!STOP
END DO


END SUBROUTINE th_upd



SUBROUTINE cbsearch()

!
! Purpose:
!    To search critical boron concentration
!

USE sdata, ONLY: Ke, rbcon, ftem, mtem, cden, bpos, nnod, f0, fer, ser, &
                 aprad, apaxi, afrad, npow
USE InpOutp, ONLY: ounit, XS_updt, AsmFlux, AsmPow, AxiPow
USE nodal, ONLY: nodal_coup4, outer4, powdis

IMPLICIT NONE

REAL  :: bc1, bc2, bcon     ! Boron Concentration
REAL :: ke1, ke2
INTEGER :: n

! File Output
WRITE(ounit,*)
WRITE(ounit,*)
WRITE(ounit,*) ' ==============================================' &
            // '=================================================='
WRITE(ounit,*) &
               '                       CRITICAL BORON CONCENTRATION SEARCH'
WRITE(ounit,*) ' ==============================================' &
            // '=================================================='
WRITE(ounit,*)
WRITE(ounit,*) '  Itr  Boron Concentration          K-EFF    FLUX REL. ERROR' &
               //'   FISS. SOURCE REL. ERROR    DOPPLER ERROR'
WRITE(ounit,*) ' -----------------------------------------------------------' &
              // '-------------------------------------------'

! Terminal Output
WRITE(*,*)
WRITE(*,*)
WRITE(*,*) ' ==============================================' &
            // '=========='
WRITE(*,*) &
               '           CRITICAL BORON CONCENTRATION SEARCH'
WRITE(*,*) ' ==============================================' &
            // '=========='
WRITE(*,*)
WRITE(*,*) '  Itr  Boron Concentration          K-EFF    '
WRITE(*,*) ' --------------------------------------------------------'


bcon = rbcon
CALL XS_updt(bcon, ftem, mtem, cden, bpos)
CALL nodal_coup4()
CALL outer4(0)
bc1 = bcon
ke1 = Ke

WRITE(ounit,'(I5, F15.2, F23.5, ES16.5, ES21.5, ES22.5)') 1, bc1, Ke1, ser, fer
WRITE(*,'(I5, F15.2, F23.5)') 1, bc1, Ke1

bcon = bcon + (Ke - 1.) * bcon   ! Guess next critical boron concentration
CALL XS_updt(bcon, ftem, mtem, cden, bpos)
CALL nodal_coup4()
CALL outer4(0)
bc2 = bcon
ke2 = Ke

WRITE(ounit,'(I5, F15.2, F23.5, ES16.5, ES21.5, ES22.5)') 2, bc2, Ke2, ser, fer
WRITE(*,'(I5, F15.2, F23.5)') 2, bc2, Ke2

n = 3
DO
  bcon = bc2 + (1.0 - ke2) / (ke1 - ke2) * (bc1 - bc2)
  CALL XS_updt(bcon, ftem, mtem, cden, bpos)
  CALL nodal_coup4()
  CALL outer4(0)
  bc1 = bc2
  bc2 = bcon
  ke1 = ke2
  ke2 = ke
  WRITE(ounit,'(I5, F15.2, F23.5, ES16.5, ES21.5, ES22.5)') n, bcon, Ke, ser, fer
  WRITE(*,'(I5, F15.2, F23.5)') n, bcon, Ke
    IF ((ABS(Ke - 1.0) < 1.e-5) .AND. (ser < 1.e-5) .AND. (fer < 1.e-5)) EXIT
    n = n + 1
    IF (bcon > 3000.) THEN
        WRITE(ounit,*) '  CRITICAL BORON CONCENTRATION EXCEEDS THE LIMIT(3000 ppm)'
        WRITE(ounit,*) '  ADPRES IS STOPPING'
        WRITE(*,*) '  CRITICAL BORON CONCENTRATION EXCEEDS THE LIMIT(3000 ppm)'
        STOP
    END IF
    IF (bcon < 0.) THEN
        WRITE(ounit,*) '  CRITICAL BORON CONCENTRATION IS NOT FOUND (LESS THAN ZERO)'
        WRITE(ounit,*) '  ADPRES IS STOPPING'
        WRITE(*,*) '  CRITICAL BORON CONCENTRATION IS NOT FOUND (LESS THAN ZERO)'
        STOP
    END IF
    IF (n == 10) THEN
        WRITE(ounit,*) '  MAXIMUM ITERATION FOR CRITICAL BORON SEARCH IS REACHING MAXIMUM'
        WRITE(ounit,*) '  ADPRES IS STOPPING'
        WRITE(*,*) '  MAXIMUM ITERATION FOR CRITICAL BORON SEARCH IS REACHING MAXIMUM'
        STOP
    END IF
END DO

ALLOCATE(npow(nnod))
IF (aprad == 1 .OR. apaxi == 1) THEN
    CALL PowDis(npow)
END IF

IF (aprad == 1) CALL AsmPow(npow)

IF (apaxi == 1) CALL AxiPow(npow)

IF (afrad == 1) CALL AsmFlux(f0, 1.e0)

END SUBROUTINE cbsearch


SUBROUTINE cbsearcht()

!
! Purpose:
!    To search critical boron concentration with thermal feedback
!

USE sdata, ONLY: Ke, ftem, mtem, bcon, rbcon, npow, nnod, &
                 f0, ser, fer, tfm, aprad, apaxi, afrad, npow, th_err
USE InpOutp, ONLY: ounit, XS_updt, AsmFlux, AsmPow, AxiPow, getfq
USE nodal, ONLY: powdis, nodal_coup4, outer4

IMPLICIT NONE

REAL  :: bc1, bc2    ! Boron Concentration
REAL :: ke1, ke2
INTEGER :: n
REAL :: tf, tm, mtm, mtf

! File Output
WRITE(ounit,*)
WRITE(ounit,*)
WRITE(ounit,*) ' ==============================================' &
            // '=================================================='
WRITE(ounit,*) &
               '                       CRITICAL BORON CONCENTRATION SEARCH'
WRITE(ounit,*) ' ==============================================' &
            // '=================================================='
WRITE(ounit,*)
WRITE(ounit,*) '  Itr  Boron Concentration          K-EFF    FLUX REL. ERROR' &
               //'   FISS. SOURCE REL. ERROR    DOPPLER ERROR'
WRITE(ounit,*) ' -----------------------------------------------------------' &
              // '-------------------------------------------'

! Terminal Output
WRITE(*,*)
WRITE(*,*)
WRITE(*,*) ' ==============================================' &
            // '=========='
WRITE(*,*) &
               '           CRITICAL BORON CONCENTRATION SEARCH'
WRITE(*,*) ' ==============================================' &
            // '=========='
WRITE(*,*)
WRITE(*,*) '  Itr  Boron Concentration          K-EFF    '
WRITE(*,*) ' --------------------------------------------------------'


ALLOCATE(npow(nnod))

bcon = rbcon
CALL th_iter()  ! Start thermal hydarulic iteration with current paramters
bc1 = bcon
ke1 = Ke

WRITE(ounit,'(I5, F15.2, F23.5, ES16.5, ES21.5, ES22.5)') 1, bc1, Ke1, ser, fer, th_err
WRITE(*,'(I5, F15.2, F23.5)') 1, bc1, Ke1

bcon = bcon + (Ke - 1.) * bcon   ! Guess next critical boron concentration
CALL th_iter()                 ! Perform second thermal hydarulic iteration with updated parameters
bc2 = bcon
ke2 = Ke

WRITE(ounit,'(I5, F15.2, F23.5, ES16.5, ES21.5, ES22.5)') 2, bc2, Ke2, ser, fer, th_err
WRITE(*,'(I5, F15.2, F23.5)') 2, bc2, Ke2

n = 3
DO
    bcon = bc2 + (1.0 - ke2) / (ke1 - ke2) * (bc1 - bc2)
    CALL th_iter()
    bc1 = bc2
    bc2 = bcon
    ke1 = ke2
    ke2 = ke
    WRITE(ounit,'(I5, F15.2, F23.5, ES16.5, ES21.5, ES22.5)') n, bcon, Ke, ser, fer, th_err
    WRITE(*,'(I5, F15.2, F23.5)') n, bcon, Ke
    IF ((ABS(Ke - 1.0) < 1.e-5) .AND. (ser < 1.e-5) .AND. (fer < 1.e-5)) EXIT
    n = n + 1
    IF (bcon > 3000.) THEN
        WRITE(ounit,*) '  CRITICAL BORON CONCENTRATION EXCEEDS THE LIMIT(3000 ppm)'
        WRITE(ounit,*) '  ADPRES IS STOPPING'
        WRITE(*,*) '  CRITICAL BORON CONCENTRATION EXCEEDS THE LIMIT(3000 ppm)'
        STOP
    END IF
    IF (bcon < 0.) THEN
        WRITE(ounit,*) '  CRITICAL BORON CONCENTRATION IS NOT FOUND (LESS THAN ZERO)'
        WRITE(ounit,*) '  ADPRES IS STOPPING'
        WRITE(*,*) '  CRITICAL BORON CONCENTRATION IS NOT FOUND (LESS THAN ZERO)'
        STOP
    END IF
    IF (n == 10) THEN
        WRITE(ounit,*) '  MAXIMUM ITERATION FOR CRITICAL BORON SEARCH IS REACHING MAXIMUM'
        WRITE(ounit,*) '  ADPRES IS STOPPING'
        WRITE(*,*) '  MAXIMUM ITERATION FOR CRITICAL BORON SEARCH IS REACHING MAXIMUM'
        STOP
    END IF
END DO

IF (aprad == 1 .OR. apaxi == 1) THEN
    CALL PowDis(npow)
END IF

IF (aprad == 1) CALL AsmPow(npow)

IF (apaxi == 1) CALL AxiPow(npow)

IF (afrad == 1) CALL AsmFlux(f0, 1.e0)

CALL par_ave_f(ftem, tf)
CALL par_ave(mtem, tm)

CALL par_max(tfm(:,1), mtf)
CALL par_max(mtem, mtm)
CALL getfq(npow)

! Write Output
WRITE(ounit,*)
WRITE(ounit, 5001) tf, tf-273.15
WRITE(ounit, 5002)  mtf, mtf-273.15
WRITE(ounit, 5003) tm, tm-273.15
WRITE(ounit, 5004) mtm, mtm-273.15

5001 FORMAT(2X, 'AVERAGE DOPPLER TEMPERATURE     : ', F7.1, ' K (', F7.1, ' C)')
5002 FORMAT(2X, 'MAX FUEL CENTERLINE TEMPERATURE : ', F7.1, ' K (', F7.1, ' C)')
5003 FORMAT(2X, 'AVERAGE MODERATOR TEMPERATURE   : ', F7.1, ' K (', F7.1, ' C)')
5004 FORMAT(2X, 'MAXIMUM MODERATOR TEMPERATURE   : ', F7.1, ' K (', F7.1, ' C)')


END SUBROUTINE cbsearcht


END MODULE th
