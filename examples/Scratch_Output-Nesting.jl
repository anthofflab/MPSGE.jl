using MPSGE

# This is built from TwobeTwoOutputNest.gms that I build from TwobyTwo MPSGE toy model
m = Model()
endow = add!(m, Parameter(:endow, value = 1.))
esub_x = add!(m, Parameter(:esub_x, value=1.))
esub_y = add!(m, Parameter(:esub_y, value=1.5))
esub_u = add!(m, Parameter(:esub_u, value=1.))
otax = add!(m, Parameter(:otax, value=0.))
itax = add!(m, Parameter(:itax, value=0.))

X = add!(m, Sector(:X))
Y = add!(m, Sector(:Y))
U = add!(m, Sector(:U))
XP = add!(m, Sector(:XP)) # Turn PX into split to Domestic and Export
FR = add!(m, Sector(:FR)) # Foreign production
XU = add!(m, Sector(:XU)) # Utility of ROW


PX = add!(m, Commodity(:PX))
PY = add!(m, Commodity(:PY))
PU = add!(m, Commodity(:PU))
PL = add!(m, Commodity(:PL))
PK = add!(m, Commodity(:PK))
PF = add!(m, Commodity(:PF))
PXD = add!(m, Commodity(:PXD)) # Value of Domestic X
PXX = add!(m, Commodity(:PXX)) # Value of Exported X
PKX = add!(m, Commodity(:PKX)) # Foreign Kapital
PROWU = add!(m, Commodity(:PRWOU)) # Value of Foreign Utility

RA = add!(m, Consumer(:RA, benchmark=200.))
ROW = add!(m, Consumer(:ROW, benchmark=20.)) 

add!(m, Production(XP, 1, 1, [Output(PXD, 20), Output(PXX, 20.)], [Input(PX, 40)]))
add!(m, Production(FR, 0, 1, [Output(PF, 20)], [Input(PKX, 20)]))
add!(m, Production(X, 0, :(1. *$esub_x), [Output(PX, 80.,[Tax(:(1. *$otax), RA)]), Output(PY, 20)], [Input(PL, 40, [Tax(:(1. * $itax), RA)]), Input(PK, 60, [Tax(:(1. * $itax), RA)])]))
add!(m, Production(Y, 0, :(1. *$esub_y), [Output(PY, 80., [Tax(:(1. *$otax), RA)]), Output(PX, 20)], [Input(PL, 60), Input(PK, 40)]))
add!(m, Production(U, 0, :(1. *$esub_u), [Output(PU, 200)], [Input(PX, 60), Input(PY, 100), Input(PXD, 20), Input(PF,20)]))
add!(m, Production(XU, 0, 1, [Output(PROWU, 20)], [Input(PXX, 20)]))


add!(m, DemandFunction(RA, 1., [Demand(PU,200)], [Endowment(PL, :(100 *$endow)), Endowment(PK, 100)]))
add!(m, DemandFunction(ROW, 1., [Demand(PROWU,20)], [Endowment(PKX, 20)]))

solve!(m, cumulative_iteration_limit = 0)

set_value(endow, 1.1)
set_value(RA, 210.)
set_fixed!(RA, true)
solve!(m)

set_fixed!(RA, false)
set_fixed!(PX, true)
solve!(m)

set_fixed!(PX, false)
set_fixed!(PL, true)
solve!(m)

set_value(itax, 0.1)
solve!(m)

set_value(itax, 0.)
set_value(otax, 0.1)
solve!(m)
