$TITLE Model M2-4S: Closed 2x2 Economy -- Monopoly markups

$ONTEXT

Below is an adaption of the Markusen M2-4s model, adapted to remove the need for
non-1 prices.

Suppose that we believe that our benchmark data was generated by a
monopoly producer in sector X, who sets an optimal markup given by
the inverse Marshallian elasticity of demand.  If SIGMA is elasticity
of substitution between X and Y, and SHAREX is the share of
expenditure on good X, then the Marshallian elasticity (defined as a
positive number) is given by

                e  = SIGMA - (SIGMA -1) SHAREX

The monopoly markup on marginal cost, MK, is the inverse of this, i.e. 

                              MK = 1/e.

In the data shown below, the formula 

                           PX (1 - MK) = MC

where MC is marginal cost, tells us that the markup is 0.20.  
We can observe from the data that SHAREX= 0.5.  

Working backwards, this calibrates to an elasticity of substitution
SIGMA = 9.0.  This is used below.  Similarly, if units are chosen such
that the prices of L and K are one, the price of X must be 1.25, and
the quantity of X produced must be 80.

As an aside, we note that for most data, the monopoly markup formula,
and an arbitrary elasticity of substitution are generally mutually
inconsistent.

                Production Sectors          Consumers

   Markets   |    X       Y        W    |       CONS
   ------------------------------------------------------
        PX   |  100             -100    |
        PY   |          100     -100    |
        PW   |                   200    |       -200
        PL   |  -30     -60             |         90
        PK   |  -50     -40             |         90
      PROFIT |  -20                     |         20
   ------------------------------------------------------

$offtext

SCALAR  SIGMA   Elasticity of substitution (calibrated) /9/;

$ONTEXT

$MODEL:M2_4S

$SECTORS:
        X       ! Activity level for sector X
        Y       ! Activity level for sector Y
        W       ! Activity level for sector W (Hicksian welfare index)

$COMMODITIES:
        PX      ! Price index for commodity X
        PY      ! Price index for commodity Y
        PL      ! Price index for primary factor L (net of tax)
        PK      ! Price index for primary factor K
        PW      ! Price index for welfare (expenditure function)

$CONSUMERS:
        CONS    ! Representative agent.

$AUXILIARY:
        SHAREX  ! Value share of good X
        MARKUP  ! X sector markup on marginal cost
 
$PROD:X  s:1
        O:PX    Q: 80    A:CONS  N:MARKUP
        I:PL    Q: 14
        I:PK    Q: 50

$PROD:Y  s:1
        O:PY    Q:100
        I:PL    Q:60
        I:PK    Q:40

$PROD:W s:9
        O:PW    Q:180
        I:PX    Q:80        !P:1.25
        I:PY    Q:100

$DEMAND:CONS
        D:PW     Q:200
        E:PL     Q: 74
        E:PK     Q: 90

$REPORT:
        v:SXX  O:PX  PROD:X
        v:DLX    I:PL      PROD:X
        v:DKX    I:PK      PROD:X
        v:SYY    O:PY      PROD:Y
        v:DLY    I:PL      PROD:Y
        v:DKY    I:PK      PROD:Y
        v:SWW    O:PW      PROD:W
        v:DXW    I:PX      PROD:W
        v:DYW    I:PY      PROD:W
        v:CWCONS    D:PW      DEMAND:CONS
        v:CWI    W:CONS

*       Define the value share of X in final demand:

$CONSTRAINT:SHAREX
        SHAREX =E= 100*PX*X / (100*PX*X + 100*PY*Y) ;

$CONSTRAINT:MARKUP
        MARKUP =E= 1 / (SIGMA - (SIGMA-1) * SHAREX);

$OFFTEXT
$SYSINCLUDE mpsgeset M2_4S

Parameter eq Description;
*       Benchmark replication:

SHAREX.L =  .5;
MARKUP.L =  0.2;

M2_4S.ITERLIM = 0;

$INCLUDE M2_4S.GEN
SOLVE M2_4S USING MCP;
abort$(abs(M2_4S.objval) gt 1e-7) "*** twobytwo does not calibrate ! ***";
eq("X","benchmark") = X.L;
eq("Y","benchmark") = Y.L;
eq("W","benchmark") = W.L;
eq("PX","benchmark") = PX.L;
eq("PY","benchmark") = PY.L;
eq("PW","benchmark") = PW.L;
eq("PL","benchmark") = PL.L;
eq("PK","benchmark") = PK.L;
eq("SHAREX","benchmark") = SHAREX.L;
eq("MARKUP","benchmark") = MARKUP.L;
eq("SXX","benchmark")= SXX.L/X.L;
eq("SYY","benchmark") = SYY.L/Y.l;
eq("SWW","benchmark") = SWW.L/W.L;
eq("DLX","benchmark") = DLX.L/X.L;
eq("DKX","benchmark") = DKX.L/X.L;
eq("DLY","benchmark") = DLY.L/Y.L;
eq("DKY","benchmark") = DKY.L/Y.L;
eq("DXW","benchmark") = DXW.L/W.L;
eq("DYW","benchmark") = DYW.L/W.L;

eq("CONS","benchmark")=CONS.L;
eq("CWCONS","benchmark") = CWCONS.L;
eq("CWI","benchmark") = CWI.L;

M2_4S.ITERLIM = 1000;

*       Evaluate the potential gains from first-best (marginal
*       cost) pricing:

SHAREX.L =  0.5;  
MARKUP.FX = 0;

$INCLUDE M2_4S.GEN
SOLVE M2_4S USING MCP;

eq("X","S.5,M.FX=0") = X.L;
eq("Y","S.5,M.FX=0") = Y.L;
eq("W","S.5,M.FX=0") = W.L;
eq("PX","S.5,M.FX=0") = PX.L;
eq("PY","S.5,M.FX=0") = PY.L;
eq("PW","S.5,M.FX=0") = PW.L;
eq("PL","S.5,M.FX=0") = PL.L;
eq("PK","S.5,M.FX=0") = PK.L;
eq("SHAREX","S.5,M.FX=0") = SHAREX.L;
eq("MARKUP","S.5,M.FX=0") = MARKUP.L;
eq("SXX","S.5,M.FX=0")= SXX.L/X.L;
eq("SYY","S.5,M.FX=0") = SYY.L/Y.l;
eq("SWW","S.5,M.FX=0") = SWW.L/W.L;
eq("DKX","S.5,M.FX=0") = DKX.L/X.L;
eq("DLX","S.5,M.FX=0") = DLX.L/X.L;
eq("DLY","S.5,M.FX=0") = DLY.L/Y.L;
eq("DKY","S.5,M.FX=0") = DKY.L/Y.L;
eq("DXW","S.5,M.FX=0") = DXW.L/W.L;
eq("DYW","S.5,M.FX=0") = DYW.L/W.L;

eq("CONS","S.5,M.FX=0")=CONS.L;
eq("CWCONS","S.5,M.FX=0") = CWCONS.L;
eq("CWI","S.5,M.FX=0") = CWI.L;

SHAREX.FX =  0.2;
MARKUP.LO =-inf;
MARKUP.UP=inf;  
MARKUP.L = 0.5;

$INCLUDE M2_4S.GEN
SOLVE M2_4S USING MCP;

eq("X","S.FX.2,M.5") = X.L;
eq("Y","S.FX.2,M.5") = Y.L;
eq("W","S.FX.2,M.5") = W.L;
eq("PX","S.FX.2,M.5") = PX.L;
eq("PY","S.FX.2,M.5") = PY.L;
eq("PW","S.FX.2,M.5") = PW.L;
eq("PL","S.FX.2,M.5") = PL.L;
eq("PK","S.FX.2,M.5") = PK.L;
eq("SHAREX","S.FX.2,M.5") = SHAREX.L;
eq("MARKUP","S.FX.2,M.5") = MARKUP.L;
eq("SXX","S.FX.2,M.5")= SXX.L/X.L;
eq("SYY","S.FX.2,M.5") = SYY.L/Y.l;
eq("SWW","S.FX.2,M.5") = SWW.L/W.L;
eq("DKX","S.FX.2,M.5") = DKX.L/X.L;
eq("DLX","S.FX.2,M.5") = DLX.L/X.L;
eq("DLY","S.FX.2,M.5") = DLY.L/Y.L;
eq("DKY","S.FX.2,M.5") = DKY.L/Y.L;
eq("DXW","S.FX.2,M.5") = DXW.L/W.L;
eq("DYW","S.FX.2,M.5") = DYW.L/W.L;

eq("CONS","S.FX.2,M.5")=CONS.L;
eq("CWCONS","S.FX.2,M.5") = CWCONS.L;
eq("CWI","S.FX.2,M.5") = CWI.L;

option decimals=7;
display eq;

execute_unload "M2_4S.gdx" eq

*=== Write to variable levels to Excel file from GDX 
*=== If we do not specify a sheet, data is placed in first sheet
execute 'gdxxrw.exe M2_4S.gdx o=MPSGEresults.xlsx par=eq rng=two_by_two_AuxinOutput!'
execute 'gdxxrw.exe M2_4S.gdx o=C:\Users\Eli\.julia\dev\MPSGE\test\MPSGEresults.xlsx par=eq rng=two_by_two_AuxinOutput!'