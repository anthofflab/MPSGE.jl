@testset "TWOBYTWO (functional version)" begin
    m = Model()
    # Here parameter values are doubled and input data halved from MPSGE version       
    inputcoeff = add!(m, Parameter(:inputcoeff, value=2.))
    endow = add!(m, Parameter(:endow, value=2.))
    elascoeff = add!(m, Parameter(:elascoeff, value=2.))
    outputmult = add!(m, Parameter(:outputmult, value=2.))

    X = add!(m, Sector(:X))
    Y = add!(m, Sector(:Y))
    U = add!(m, Sector(:U))

    PX = add!(m, Commodity(:PX))
    PY = add!(m, Commodity(:PY))
    PU = add!(m, Commodity(:PU))
    PL = add!(m, Commodity(:PL))
    PK = add!(m, Commodity(:PK))

    RA = add!(m, Consumer(:RA, benchmark=150.))

    add!(m, Production(X, 0, 1, [Output(PX, 100)], [Input(PL, :(25 * $inputcoeff)), Input(PK, 50)]))
    add!(m, Production(Y, 0, :(0.5 * $elascoeff), [Output(PY, 50)], [Input(PL, 20), Input(PK, 30)]))
    add!(m, Production(U, 0, 1, [Output(PU, :(75 * $outputmult))], [Input(PX, 100), Input(PY, 50)]))

    add!(m, DemandFunction(RA, [Demand(PU,150)], [Endowment(PL, :(35 * $endow)), Endowment(PK, 80)]))

    avm = algebraic_version(m)
    @test typeof(avm) == MPSGE.AlgebraicWrapper

    solve!(m)

    gams_results = XLSX.readxlsx("MPSGEresults.xlsx")
    a_table = gams_results["TwoxTwoScalar"][:]
    two_by_two_scalar_results = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])

    @test value(m, :X) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","benchmark"]
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ 150.

    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ 1.

    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ 50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 20.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ 50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ 30.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ 100.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ 50.

    avm2 = algebraic_version(m)
    @test typeof(avm2) == MPSGE.AlgebraicWrapper

    # For now just run these functions, we might add tests for the results
    # at a later point
    repr(MIME("text/plain"), m)
    repr(MIME("text/plain"), avm2)
    repr(MIME("text/latex"), avm2)

    set_fixed!(PX, true)
    set_value(endow, 2.2)
    solve!(m)

    @test value(m, :X) ≈ 1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","PX=1"]
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ 1.04548206
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ 157.321327225523
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 1.0000000000
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ 1.00957658
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ 1.00318206
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 0.95346259
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ 1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ 52.4404424085075
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 21.1770570584356
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ 47.6731294622795
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ 28.877805079685
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ 100.318205802571
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ 49.6833066029729
end