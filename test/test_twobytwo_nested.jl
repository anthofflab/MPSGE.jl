@testitem "TWOBYTWO Input Nest (functional version)" begin
    using XLSX, MPSGE.JuMP.Containers

    m = Model()
    # Here parameter values are doubled and input data halved from MPSGE version       
    inputcoeff = add!(m, Parameter(:inputcoeff, value=2.))
    endow = add!(m, Parameter(:endow, value=2.))
    elascoeff = add!(m, Parameter(:elascoeff, value=2.))
    outputmult = add!(m, Parameter(:outputmult, value=2.))

    # X = add!(m, Sector(:X))
    # Y = add!(m, Sector(:Y))
    U = add!(m, Sector(:U))

    # PX = add!(m, Commodity(:PX))
    # PY = add!(m, Commodity(:PY))
    PU = add!(m, Commodity(:PU))
    PL = add!(m, Commodity(:PL))
    PK = add!(m, Commodity(:PK))

    RA = add!(m, Consumer(:RA, benchmark=150.))

    # add!(m, Production(X, 0, 1, [Output(PX, 100)], [Input(PL, :(25 * $inputcoeff)), Input(PK, 50)]))
    # add!(m, Production(Y, 0, :(0.5 * $elascoeff), [Output(PY, 50)], [Input(PL, 20), Input(PK, 30)]))
    # add!(m, 
    #     Production(
    #         U,
    #         0,
    #         1,
    #         [
    #             Output(PU, :(75 * $outputmult))
    #         ],
    #         [
    #             Input(PX, 100),
    #             Input(PY, 50)
    #         ]
    #     )
    # )

    add!(m, 
        Production(
            U,
            0,
            1,
            [
                Output(PU, :(75 * $outputmult))
            ],
            [
                Input(
                    Nest(
                        :X,
                        1.,
                        100.,
                        [
                            Input(PL, :(25 * $inputcoeff)),
                            Input(PK, 50)
                        ]
                    ),
                100),
                Input(
                    Nest(
                        :Y,
                        :(0.5 * $elascoeff),
                        50.,
                        [
                            Input(PL, 20),
                            Input(PK, 30)
                        ]
                    ),
                    50
                )
            ]
        )
    )

    add!(m, DemandFunction(RA, 1., [Demand(PU,150)], [Endowment(PL, :(35 * $endow)), Endowment(PK, 80)]))

    avm = algebraic_version(m)
    @test typeof(avm) == MPSGE.AlgebraicWrapper

    solve!(m)

    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["TwoxTwoScalar"][:]  # Generated from TwoByTwo_Scalar_Algeb-MPSGE.gms
    two_by_two_scalar_results = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])

    @test value(m, Symbol("U→X")) ≈ two_by_two_scalar_results["X.L","benchmark"]#    1.0
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("U→Y")]) ≈ two_by_two_scalar_results["Y.L","benchmark"]#    1.0
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","benchmark"]#    1.0
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","benchmark"]#    150.0
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU→X")]) ≈ two_by_two_scalar_results["PX.L","benchmark"]#    1.0
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU→Y")]) ≈ two_by_two_scalar_results["PY.L","benchmark"]#    1.0
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","benchmark"]#    1.0
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","benchmark"]#    1.0
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","benchmark"]#    1.0
#Implicit variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†U→X")]) ≈ two_by_two_scalar_results["LX.L","benchmark"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†U→Y")]) ≈ two_by_two_scalar_results["LY.L","benchmark"]#    20.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†U→X")]) ≈ two_by_two_scalar_results["KX.L","benchmark"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†U→Y")]) ≈ two_by_two_scalar_results["KY.L","benchmark"]#    30.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU→X†U")]) ≈ two_by_two_scalar_results["DX.L","benchmark"]#    100.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU→Y†U")]) ≈ two_by_two_scalar_results["DY.L","benchmark"]#    50.

    avm2 = algebraic_version(m)
    @test typeof(avm2) == MPSGE.AlgebraicWrapper

    # For now just run these functions, we might add tests for the results
    # at a later point
    repr(MIME("text/plain"), m)
    repr(MIME("text/plain"), avm2)
    repr(MIME("text/latex"), avm2)
  
    set_fixed!(get_nested_commodity(U, :X), true)
    set_value(endow, 2.2)
    solve!(m)

    @test value(m, Symbol("U→X")) ≈ two_by_two_scalar_results["X.L","PX=1"]#    1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("U→Y")]) ≈ two_by_two_scalar_results["Y.L","PX=1"]
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","PX=1"]#    1.04548206
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","PX=1"]#    157.321327225523
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU→X")]) ≈ two_by_two_scalar_results["PX.L","PX=1"]#    1.0000000000
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU→Y")]) ≈ two_by_two_scalar_results["PY.L","PX=1"]#    1.00957658
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","PX=1"]#    1.00318206
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","PX=1"]#    0.95346259
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","PX=1"]#    1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†U→X")]) ≈ two_by_two_scalar_results["LX.L","PX=1"]#    52.4404424085075
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†U→Y")]) ≈ two_by_two_scalar_results["LY.L","PX=1"]#    21.1770570584356
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†U→X")]) ≈ two_by_two_scalar_results["KX.L","PX=1"]#    47.6731294622795
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†U→Y")]) ≈ two_by_two_scalar_results["KY.L","PX=1"]#    28.877805079685
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU→X†U")]) ≈ two_by_two_scalar_results["DX.L","PX=1"]#    100.318205802571
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU→Y†U")]) ≈ two_by_two_scalar_results["DY.L","PX=1"]#    49.6833066029729

    set_fixed!(get_nested_commodity(U, :X), false)
    set_fixed!(PL, true)
    solve!(m)

    @test value(m, Symbol("U→X")) ≈ two_by_two_scalar_results["X.L","PX=1"]#    1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("U→Y")]) ≈ two_by_two_scalar_results["Y.L","PL=1"]#    1.038860118
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","PL=1"]#    1.04548206
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","PL=1"]#    165
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU→X")]) ≈ two_by_two_scalar_results["PX.L","PL=1"]#    1.048808848
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU→Y")]) ≈ two_by_two_scalar_results["PY.L","PL=1"]#    1.058852853
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","PL=1"]#    1.052146219
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","PL=1"]#    1.0
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","PL=1"]#    1.1
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†U→X")]) ≈ two_by_two_scalar_results["LX.L","PL=1"]#    52.4404424085075
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†U→Y")]) ≈ two_by_two_scalar_results["LY.L","PL=1"]#    21.1770570584356
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†U→X")]) ≈ two_by_two_scalar_results["KX.L","PL=1"]#    47.6731294622795
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†U→Y")]) ≈ two_by_two_scalar_results["KY.L","PL=1"]#    28.877805079685
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU→X†U")]) ≈ two_by_two_scalar_results["DX.L","PL=1"]#    100.318205802571
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU→Y†U")]) ≈ two_by_two_scalar_results["DY.L","PL=1"]#    49.6833066029729

end

@testitem "TWOBYTWO Output Nest (functional version)" begin
using XLSX, MPSGE.JuMP.Containers

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

RA = add!(m, Consumer(:RA, benchmark=220.))
ROW = add!(m, Consumer(:ROW, benchmark=20.)) 

add!(m, Production(XP, 1, 1, [Output(PXD, 20), Output(PXX, 20.)], [Input(PX, 40)]))
add!(m, Production(X, 0, :(1. *$esub_x), [Output(PX, 80.,[Tax(:(1. *$otax), RA)]), Output(PY, 20.)], [Input(PL, 40, [Tax(:(1. * $itax), RA)]), Input(PK, 60, [Tax(:(1. * $itax), RA)])]))
# add!(m, Production(XP, 1., 1., [Output(PXD, 20.), Output(PXX, 20.)], [Input(Nest(:X, 1., 40., [Input(PL, 40., [Tax(:(1. * $itax),RA)]), Input(PK, 60., [Tax(:(1. * $itax), RA)])]), 40.)]))
add!(m, Production(FR, 0, 1, [Output(PF, 20)], [Input(PKX, 20)]))


add!(m, Production(Y, 0, :(1. *$esub_y), [Output(PY, 80., [Tax(:(1. *$otax), RA)]), Output(PX, 40)], [Input(PL, 80), Input(PK, 40)]))
add!(m, Production(U, 0, :(1. *$esub_u), [Output(PU, 220)], [Input(PX, 80), Input(PY, 100), Input(PXD, 20), Input(PF,20)]))
add!(m, Production(XU, 0, 1, [Output(PROWU, 20)], [Input(PXX, 20)]))


add!(m, DemandFunction(RA, 1., [Demand(PU,220)], [Endowment(PL, :(120 *$endow)), Endowment(PK, 100)]))
add!(m, DemandFunction(ROW, 1., [Demand(PROWU,20)], [Endowment(PKX, 20)]))
solve!(m, cumulative_iteration_limit = 0)

gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
a_table = gams_results["TwoxTwo-ScalarOutNest"][:]  # Generated from TwoByTwo_Scalar_OutputNest.gms
two_by_two_scalar_results = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])

@test value(m, Symbol("X")) ≈ two_by_two_scalar_results["X.L","benchmark"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("Y")]) ≈ two_by_two_scalar_results["Y.L","benchmark"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","benchmark"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("XP")]) ≈ two_by_two_scalar_results["XP.L","benchmark"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("FR")]) ≈ two_by_two_scalar_results["FR.L","benchmark"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("XU")]) ≈ two_by_two_scalar_results["XU.L","benchmark"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX")]) ≈ two_by_two_scalar_results["PX.L","benchmark"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY")]) ≈ two_by_two_scalar_results["PY.L","benchmark"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","benchmark"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","benchmark"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","benchmark"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF")]) ≈ two_by_two_scalar_results["PF.L","benchmark"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXD")]) ≈ two_by_two_scalar_results["PXD.L","benchmark"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXX")]) ≈ two_by_two_scalar_results["PXX.L","benchmark"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PKX")]) ≈ two_by_two_scalar_results["PKX.L","benchmark"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","benchmark"]#    200.0
@test MPSGE.Complementarity.result_value(m._jump_model[:ROW]) ≈ two_by_two_scalar_results["ROW.L","benchmark"]#    200.0

#Implicit variables
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","benchmark"]#    40.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","benchmark"]#    60.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","benchmark"]#    60.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","benchmark"]#    40.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","benchmark"]#    100.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","benchmark"]#    50.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","benchmark"]	#	100


set_value(endow, 1.1)
set_value(RA, 232.)
set_fixed!(RA, true)
solve!(m)

@test value(m, Symbol("X")) ≈ two_by_two_scalar_results["X.L","end=1.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("Y")]) ≈ two_by_two_scalar_results["Y.L","end=1.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","end=1.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("XP")]) ≈ two_by_two_scalar_results["XP.L","end=1.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("FR")]) ≈ two_by_two_scalar_results["FR.L","end=1.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("XU")]) ≈ two_by_two_scalar_results["XU.L","end=1.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX")]) ≈ two_by_two_scalar_results["PX.L","end=1.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY")]) ≈ two_by_two_scalar_results["PY.L","end=1.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","end=1.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","end=1.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","end=1.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF")]) ≈ two_by_two_scalar_results["PF.L","end=1.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXD")]) ≈ two_by_two_scalar_results["PXD.L","end=1.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXX")]) ≈ two_by_two_scalar_results["PXX.L","end=1.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PKX")]) ≈ two_by_two_scalar_results["PKX.L","end=1.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","end=1.1"]#    200.0
@test MPSGE.Complementarity.result_value(m._jump_model[:ROW]) ≈ two_by_two_scalar_results["ROW.L","end=1.1"]#    200.0

#Implicit variables
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","end=1.1"]#    40.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","end=1.1"]#    60.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","end=1.1"]#    60.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","end=1.1"]#    40.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","end=1.1"]#    100.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","end=1.1"]#    50.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","end=1.1"]	#	100

set_fixed!(RA, false)
set_fixed!(PX, true)
solve!(m)

@test value(m, Symbol("X")) ≈ two_by_two_scalar_results["X.L","PX=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("Y")]) ≈ two_by_two_scalar_results["Y.L","PX=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","PX=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("XP")]) ≈ two_by_two_scalar_results["XP.L","PX=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("FR")]) ≈ two_by_two_scalar_results["FR.L","PX=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("XU")]) ≈ two_by_two_scalar_results["XU.L","PX=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX")]) ≈ two_by_two_scalar_results["PX.L","PX=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY")]) ≈ two_by_two_scalar_results["PY.L","PX=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","PX=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","PX=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","PX=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF")]) ≈ two_by_two_scalar_results["PF.L","PX=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXD")]) ≈ two_by_two_scalar_results["PXD.L","PX=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXX")]) ≈ two_by_two_scalar_results["PXX.L","PX=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PKX")]) ≈ two_by_two_scalar_results["PKX.L","PX=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","PX=1"]#    200.0
@test MPSGE.Complementarity.result_value(m._jump_model[:ROW]) ≈ two_by_two_scalar_results["ROW.L","PX=1"]#    200.0

#Implicit variables
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","PX=1"]#    40.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","PX=1"]#    60.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","PX=1"]#    60.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","PX=1"]#    40.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","PX=1"]#    100.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","PX=1"]#    50.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","PX=1"]	#	100

set_fixed!(PX, false)
set_fixed!(PL, true)
solve!(m)

@test value(m, Symbol("X")) ≈ two_by_two_scalar_results["X.L","PL=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("Y")]) ≈ two_by_two_scalar_results["Y.L","PL=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","PL=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("XP")]) ≈ two_by_two_scalar_results["XP.L","PL=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("FR")]) ≈ two_by_two_scalar_results["FR.L","PL=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("XU")]) ≈ two_by_two_scalar_results["XU.L","PL=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX")]) ≈ two_by_two_scalar_results["PX.L","PL=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY")]) ≈ two_by_two_scalar_results["PY.L","PL=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","PL=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","PL=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","PL=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF")]) ≈ two_by_two_scalar_results["PF.L","PL=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXD")]) ≈ two_by_two_scalar_results["PXD.L","PL=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXX")]) ≈ two_by_two_scalar_results["PXX.L","PL=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PKX")]) ≈ two_by_two_scalar_results["PKX.L","PL=1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","PL=1"]#    200.0
@test MPSGE.Complementarity.result_value(m._jump_model[:ROW]) ≈ two_by_two_scalar_results["ROW.L","PL=1"]#    200.0

#Implicit variables
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","PL=1"]#    40.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","PL=1"]#    60.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","PL=1"]#    60.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","PL=1"]#    40.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","PL=1"]#    100.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","PL=1"]#    50.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","PL=1"]	#	100

set_value(itax, 0.1)
solve!(m)

@test value(m, Symbol("X")) ≈ two_by_two_scalar_results["X.L","Itax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("Y")]) ≈ two_by_two_scalar_results["Y.L","Itax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","Itax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("XP")]) ≈ two_by_two_scalar_results["XP.L","Itax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("FR")]) ≈ two_by_two_scalar_results["FR.L","Itax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("XU")]) ≈ two_by_two_scalar_results["XU.L","Itax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX")]) ≈ two_by_two_scalar_results["PX.L","Itax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY")]) ≈ two_by_two_scalar_results["PY.L","Itax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","Itax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","Itax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","Itax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF")]) ≈ two_by_two_scalar_results["PF.L","Itax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXD")]) ≈ two_by_two_scalar_results["PXD.L","Itax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXX")]) ≈ two_by_two_scalar_results["PXX.L","Itax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PKX")]) ≈ two_by_two_scalar_results["PKX.L","Itax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","Itax=0.1"]#    200.0
@test MPSGE.Complementarity.result_value(m._jump_model[:ROW]) ≈ two_by_two_scalar_results["ROW.L","Itax=0.1"]#    200.0

#Implicit variables
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","Itax=0.1"]#    40.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","Itax=0.1"]#    60.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","Itax=0.1"]#    60.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","Itax=0.1"]#    40.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","Itax=0.1"]#    100.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","Itax=0.1"]#    50.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","Itax=0.1"]	#	100

set_value(itax, 0.)
set_value(otax, 0.1)
solve!(m)

@test value(m, Symbol("X")) ≈ two_by_two_scalar_results["X.L","Otax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("Y")]) ≈ two_by_two_scalar_results["Y.L","Otax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","Otax=0.1"]#    1.0

@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("XP")]) ≈ two_by_two_scalar_results["XP.L","Otax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("FR")]) ≈ two_by_two_scalar_results["FR.L","Otax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("XU")]) ≈ two_by_two_scalar_results["XU.L","Otax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX")]) ≈ two_by_two_scalar_results["PX.L","Otax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY")]) ≈ two_by_two_scalar_results["PY.L","Otax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","Otax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","Otax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","Otax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF")]) ≈ two_by_two_scalar_results["PF.L","Otax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXD")]) ≈ two_by_two_scalar_results["PXD.L","Otax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXX")]) ≈ two_by_two_scalar_results["PXX.L","Otax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PKX")]) ≈ two_by_two_scalar_results["PKX.L","Otax=0.1"]#    1.0
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","Otax=0.1"]#    200.0
@test MPSGE.Complementarity.result_value(m._jump_model[:ROW]) ≈ two_by_two_scalar_results["ROW.L","Otax=0.1"]#    200.0

#Implicit variables
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","Otax=0.1"]#    40.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","Otax=0.1"]#    60.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","Otax=0.1"]#    60.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","Otax=0.1"]#    40.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","Otax=0.1"]#    100.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","Otax=0.1"]#    50.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","benchmark"]	#	100

end
