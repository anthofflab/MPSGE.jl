using MPSGE
using MPSGE.JuMP.Containers
# A replication of the 123 Model, from https://www.gams.com/34/docs/UG_MPSGE_Intro.html#UG_MPSGE_Intro_Appendix_model123
m = Model()

@parameter(m, px0,  0.989321903257947)  # Reference price of exports
@parameter(m, d0,  218.308)  # Reference domestic supply
@parameter(m, x0,  106.386)  # Reference exports
@parameter(m, kd0,  -143.862)  # Reference net capital earnings
@parameter(m, ly0,  -163.32)  # Reference net labor earnings
@parameter(m, rr0,  0.910768653292739)  # Reference price of capital
@parameter(m, pl0,  0.978330884153808)  # Reference wage
@parameter(m, tk,  0.0892313467072611)  # Capital tax rate
@parameter(m, tl,  0.0216691158461915)  # Labor tax rate
@parameter(m, ta,  0.0774247980795498)  # Excise and sales tax rate
@parameter(m, tx,  0.0106780967420525)  # Tax on exports
@parameter(m, a0,  413.653)  # Aggregate supply (gross of tax)
@parameter(m, g0,  35.583)  # Government demand,
@parameter(m, dtax,  -38.136)  # Direct tax net transfers
@parameter(m, m0,  144.701)  # Imports
@parameter(m, l0,  -122.49)  # Leisure demand
@parameter(m, c0,  291.694)  # Household consumption,
@parameter(m, i0,  86.376)  # Aggregate investment
@parameter(m, tm,  0.128658405954347)  # Import tariff rate
@parameter(m, pm0,  1.12865840595435)  # Reference price of imports
@parameter(m, pwm,  1.)  # World price of imports /1/
@parameter(m, pwx,  1.)  # World price of exports /1/
@parameter(m, bopdef,  38.315)  # Balance of payments deficit
@parameter(m, etadx,  4.)  # Elasticity of transformation (D versus X) /4/,
@parameter(m, sigmadm,  4.)  # Elasticity of substitution (D versus M) /4/,
@parameter(m, esubkl,  1.)  # Elasticity of substitution (K versus L) /1/,
@parameter(m, sigma,  0.4)  # Elasticity of substitution (C versus LS) /0.4/

# @parameter(m, d0, 218.308 )  # Reference domestic supply
# @parameter(m, x0, 106.386 )  # Reference exports
# @parameter(m, kd0, -143.862 )  # Reference net capital earnings
# @parameter(m, ly0, -163.320 )  # Reference net labor earnings
# @parameter(m, tk, -12.837/-143.862)  # Capital tax rate
# @parameter(m, tl, -3.539/-163.320)  # Labor tax rate
# @parameter(m, ta, 32.027/413.653 )  # Excise and sales tax rate
# @parameter(m, tx, 1.136/106.386)  # Tax on exports
# @parameter(m, px0, 1 - get_value(tx))  # Reference price of exports
# @parameter(m, rr0, 1 + get_value(tk))  # Reference price of capital
# @parameter(m, pl0, 1 + get_value(tl))  # Reference wage

# @parameter(m, a0, 413.653)  # Aggregate supply (gross of tax)
# @parameter(m, g0, 35.583)  # Government demand,
# @parameter(m, m0, 144.701)  # Imports
# @parameter(m, l0, 0.75*get_value(ly0))  # Leisure demand
# @parameter(m, i0, 86.376)  # Aggregate investment
# @parameter(m, c0, get_value(a0) - get_value(i0) - get_value(g0))  # Household consumption,
# @parameter(m, tm, 18.617/144.701 )  # Import tariff rate
# @parameter(m, pm0, 1 + get_value(tm) )  # Reference price of imports
# @parameter(m, pwm, 1.)  # World price of imports /1/
# @parameter(m, pwx, 1.)  # World price of exports /1/
# @parameter(m, bopdef, 38.315)  # Balance of payments deficit
# @parameter(m, dtax, get_value(g0) - get_value(bopdef) - get_value(tm)*get_value(m0) - get_value(ta)*get_value(a0) - get_value(tl)*get_value(ly0) - get_value(tk)*get_value(kd0) - get_value(tx)*get_value(x0))  # Direct tax net transfers

# @parameter(m, etadx, 4. )  # Elasticity of transformation (D versus X) /4/,
# @parameter(m, sigmadm, 4. )  # Elasticity of substitution (D versus M) /4/,
# @parameter(m, esubkl, 1. )  # Elasticity of substitution (K versus L) /1/,
# @parameter(m, sigma,  0.4)  # Elasticity of substitution (C versus LS) /0.4/

@sector(m, Y)  # Production
@sector(m, A)  # Armington
@sector(m, M)  # Imports
@sector(m, X)  # Export

@commodity(m, PD, benchmark=1.) # Domestic Price Index
@commodity(m, PX, benchmark=get_value(px0)) # Export Price Index
@commodity(m, PM) # Import Price Index
@commodity(m, PA) # Armington Price Index
@commodity(m, PL, benchmark=get_value(pl0)) # Wage Rate Index
@commodity(m, RK, benchmark=get_value(rr0)) # Rental (of Kapital) Price Index
@commodity(m, PFX) # Foreign Exchange

@consumer(m, HH)
@consumer(m, GOVT)

# TAU_LS = add!(m, Aux(:TAU_LS)) # Lumpsum Replacement tax
TAU_TL = add!(m, Aux(:TAU_TL)) # Labor tax replacement
# UR     = add!(m, Aux(:UR)) # Unemployment rate

@production(m, Y, :($etadx*1.), :($esubkl*1.), [Output(PD, get_value(d0)), Output(PX, get_value(x0), [Tax(:(1*$tx), GOVT)])],[Input(RK, get_value(kd0), [Tax(:(1*$tk), GOVT)]), Input(PL, get_value(ly0), [Tax(:($tl+$TAU_TL), GOVT)])])
# Need the N Auxiliary Variable here... TAU_TL should be the endogenous tax on labor...

@production(m, A, 0, :($sigmadm*1.), [Output(PA, get_value(a0), [Tax(:(1*$ta), GOVT)])],[Input(PD, get_value(d0)), Input(PM, get_value(m0), [Tax(:(1*$pm0), GOVT)])])
@production(m, M, 0, 1, [Output(PM, get_value(m0))], [Input(PFX, get_value(pwm)*get_value(m0))])
@production(m, X, 0, 1, [Output(PFX, get_value(pwx)*get_value(x0))], [Input(PX, get_value(x0))])

@demand(m, GOVT, 1., [Demand(PA, 1.)], [Endowment(PA, get_value(g0)), Endowment(PA, get_value(dtax)), Endowment(PFX, get_value(bopdef))])
# Need the R Auxiliary variable here...
@demand(m, HH, :($sigma*1.), [Demand(PL, get_value(l0)), Demand(PA, get_value(c0))], [Endowment(PL, get_value(ly0)+10), Endowment(PA, -get_value(i0)), Endowment(RK, get_value(kd0)), Endowment(PA, -get_value(dtax))])
# Need the Auxialiary variable here in Endowment(PL, -get_value(ly0+l0.)*UR)  ?? Is it *UR, are aux variables in Endowments always multiplied by the quantities?
# Need the Auxialiary variable here in Endowment(PA, -get_value(-g0)*TAU_LS)  ?? Is it *TAU_LS, are aux variables in Endowments always multiplied by the quantities?
# UR     = add!(m, AuxConstraint(UR, :($PL==$PA))) # why do we not have symbol as input here? This is the name of the constraint, but it is associated with the auxiliary variable. Is this by design?
# TAU_LS = add!(m, AuxConstraint(TAU_LS, :($GOVT==$PA*35.583))) # why do we not have symbol as input here? This is the name of the constraint, but it is associated with the auxiliary variable. Is this by design?
# $PA*get_value(g0) didn't work
TAU_TL = add!(m, AuxConstraint(TAU_TL, :($GOVT==($PA*35.583)))) # why do we not have symbol as input here? This is the name of the constraint, but it is associated with the auxiliary variable. Is this by design?

solve!(m, cumulative_iteraction_limit=0)
# solve!(m)