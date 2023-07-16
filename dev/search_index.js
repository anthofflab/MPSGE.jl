var documenterSearchIndex = {"docs":
[{"location":"reference/#Reference-Guide","page":"Reference","title":"Reference Guide","text":"","category":"section"},{"location":"reference/","page":"Reference","title":"Reference","text":"Model\nadd!\nParameter\nSector\nInput\nOutput\nset_value\nset_fixed!","category":"page"},{"location":"reference/#MPSGE.Model","page":"Reference","title":"MPSGE.Model","text":"Model()     The struct that stores all the elements of the model.\n\nExample\n\njulia> foo = Model()\n\n\n\n\n\n","category":"type"},{"location":"reference/#MPSGE.add!","page":"Reference","title":"MPSGE.add!","text":"add!(m,bar)\nFunction that adds an element to the model with a name assignment\nm::Model is always the first Argument\n\n# Options\nParameter::ScalarParameter, ::IndexedParameter\nCommodity::ScalarCommodity, ::IndexedCommodity\nSector::ScalarSector,       ::IndexedSector\nConsumer::ScalarConsumer,   ::IndexedConsumer\nAux::ScalarAux,             ::IndexedAux\n\nExample\n\njulia> S = add!(m, Sector())\n\nProduction::Production\nDemand::DemandFunction\nAuxConstraint::AuxConstraint\n\nExample\n\njulia> add!(m, Production()) \n\n\n\n\n\n","category":"function"},{"location":"reference/#MPSGE.Parameter","page":"Reference","title":"MPSGE.Parameter","text":"Parameter(:symbol; indices, value::Float64=1., string)\nStruct that holds the name, indices if IndexedParameter, value, and optional description of a parameter within the model.\n\nOptions\n\nParameter::ScalarParameter, IndexedParameter\n\nExample\n\njulia> P = add!(Parameter(model, :P, value=1., description=\"Elasticity\"))\njulia> sectors = [:s1, :s2]\njulia> P = add!(Parameter(model, :P, indices=(,sectors), value=1., description=\"Elasticity parameters for X Sector \"))\n\n\n\n\n\n","category":"type"},{"location":"reference/#MPSGE.Sector","page":"Reference","title":"MPSGE.Sector","text":"Sector(:symbol; indices, value::Float64=1., string)\nStruct that holds the name, (indices if IndexedSector), value, and optional description of a sector within the model.\n\nOptions\n\nSector::ScalarSector, IndexedSector\n\nExample\n\njulia> S = add!(Sector(model, :S, value=1., description=\"Sector S\"))\njulia> sectors = [:s1, :s2]\njulia> P = add!(Sector(model, :S, indices=(,sectors), value=1., description=\"S[:s1] and S[:s2] Sectors\"))\n\n\n\n\n\n","category":"type"},{"location":"reference/#MPSGE.Input","page":"Reference","title":"MPSGE.Input","text":"Input(inputname::Symbol, value::Float64; taxes=taxes::Vector{Tax}, price=price::Union{Float64,Expr}=1.)     The struct that stores all the elements of an Input.\n\nOptions\n\n    Taxes and price are optional, keyword must be used.\n\nExample\n\njulia> Input(:PL, 50, taxes=[Tax(1., RA)], price=1.2)\n\n\n\n\n\n","category":"type"},{"location":"reference/#MPSGE.Output","page":"Reference","title":"MPSGE.Output","text":"Output(outputname::Symbol, value::Float64; taxes=taxes::Vector{Tax}, price=price::Union{Float64,Expr}=1.)     The struct that stores all the elements of an Input.\n\nOptions\n\n    Taxes and price are optional, keyword must be used.\n\nExample\n\njulia> Output(:PU, 50, taxes=[Tax(0.1, CONS)], price=.9)\n\n\n\n\n\n","category":"type"},{"location":"reference/#JuMP.set_value","page":"Reference","title":"JuMP.set_value","text":"set_value(P, value::Float64)\nFunction that allows users to set a specific value for a variable, updating the benchmark field.\n\nOptions\n\nParameter::ScalarParameter, ::IndexedParameter\nCommodity::ScalarCommodity, ::IndexedCommodity\nSector::ScalarSector,       ::IndexedSector\nConsumer::ScalarConsumer,   ::IndexedConsumer\nAux::ScalarAux,             ::IndexedAux\n\nExample\n\njulia> set_value(var, 1.3)\n\n\n\n\n\n","category":"function"},{"location":"reference/#MPSGE.set_fixed!","page":"Reference","title":"MPSGE.set_fixed!","text":"set_fixed!(P, true::Boolean)\nFunction that allows users to fix a value for a variable, the benchmark, the value from set_value, or the previous value.\n\nOptions\n\nParameter::ScalarParameter, ::IndexedParameter\nCommodity::ScalarCommodity, ::IndexedCommodity\nSector::ScalarSector,       ::IndexedSector\nConsumer::ScalarConsumer,   ::IndexedConsumer\nAux::ScalarAux,             ::IndexedAux\n\nExample\n\njulia> set_fixed!(var, false)\n\n\n\n\n\n","category":"function"},{"location":"#MPSGE.jl","page":"Home","title":"MPSGE.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"MPSGE.jl is a Julia evolution of the GAMS MPSGE subsystem.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The Documentation for MPSGE should be useful to reference, especially for background, theory, and for some understanding of features while the MPSGE.jl documentation is still being written.","category":"page"},{"location":"","page":"Home","title":"Home","text":"As we're still in development, tagging can lag a bit.  To load the most current version of main (which may be ahead of the tagged registered version), ","category":"page"},{"location":"","page":"Home","title":"Home","text":"run \"add MPSGE#main\" in the package handler (\"]\" in VS code), or Pkg.add(\"MPSGE#main\"), which will establish the current version of the main branch as the package.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The documentation here will probably grow in fits and starts. Please give us feedback as we go, and let us know what would be especially helpful.","category":"page"},{"location":"tutorial/#Add-the-MPSGE-package","page":"Tutorial","title":"Add the MPSGE package","text":"","category":"section"},{"location":"tutorial/#Activate-the-package-with","page":"Tutorial","title":"Activate the package with","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"using MPSGE","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Start by naming the model using any Julia-legal variable name, without spaces etc. The Julia style guide suggests lower case for variable names.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"m = Model()","category":"page"},{"location":"tutorial/#Store-the-model-elements-ready-for-build-by-adding-them","page":"Tutorial","title":"Store the model elements ready for build by adding them","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"note: Note\nScalars and arrays can be used to provide values, inlcuding for model parameters like elasticities, but can not be changed within the model in counterfactuals, so any value that needs to be updated should be added as a model Parameter.\nTo access model Parameters in model functions, at this point they must be part of expressions, so for referencing the value of elast, it must be within an evaluated expression :(1 * elast).\nThe model can be built in any order, so long as all elements referred to have been previously defined. For that reason a standard structure is: load the data, scalars, indexes; add model parameters, sectors, commodities, auxiliary variables, and consumers; add production and demand functions, and auxilliary constraint equations.","category":"page"},{"location":"tutorial/#Add-data","page":"Tutorial","title":"Add data","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Use DenseAxisArrays for any data that's indexed, including a table. Use 'missing' to hold any spaces (see example 5). For a simple scalar model, it's straightforward just to use the values when defining the elements, but we'll include a DenseAxisArray for illustration.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"MPSGE.JuMP.Containers\nsampleindex = [:x]\ndata = DenseAxisArray(Float64[100], sampleindex)","category":"page"},{"location":"tutorial/#Add-Parameters","page":"Tutorial","title":"Add Parameters","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"note: Note\nThere is a 'functional' and macro version for all model definition elements. The macro versions may lag while the package is still in development.\nWe show both here - they are equivalent.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"sub_elas_x = add!(m, Parameter(:sub_elas_x, value=1.5, description=\"Substitution elasticity between labor and kapital in sector X\"))\n\n# Without the optional description\nsub_elas_y = add!(m, Parameter(:sub_elas_y, value=2.))\n\n# The macro version\n@parameter(m, sub_elas_u, 0.5)\n@parameter(m, transf_elas_y, 0., description=\"Transformation Elasticity for sector Y, irrelevant because there's only 1 output\")","category":"page"},{"location":"tutorial/#Add-Commodities,-default-benchmark-price1","page":"Tutorial","title":"Add Commodities, default benchmark price=1","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"PX = add!(m, Commodity(:PX))\nPY = add!(m, Commodity(:PY), benchmark=1.)\nPU = add!(m, Commodity(:PU, description=\"The Utility Commodity\"))\n@commodity(m, PU)\n@commodity(m, PL)\n@commodity(m, PK)","category":"page"},{"location":"tutorial/#Add-Sectors","page":"Tutorial","title":"Add Sectors","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"@sector(m, X)\nY = add!(m, Sector(:Y))\n@sector(m, U, description=\"Sector U\")","category":"page"},{"location":"tutorial/#Add-Consumer(s)","page":"Tutorial","title":"Add Consumer(s)","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Here the benchmark value is important. This value will be the sum of endowments any taxes transferred to the consumer in the benchmark callibration of the model.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"@consumer(m, RA, benchmark = 150., description=\"Representative Agent\")","category":"page"},{"location":"tutorial/#Add-Production-Functions","page":"Tutorial","title":"Add Production Functions","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"note: Note\nOutputs and Inputs are within [] Arrays, even if single.  Outputs must always be first.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"add!(m, Production(X,:($transf_elas_x*1.), :($sub_elas_x*1.), [Output(PX, data[:x])], [Input(PL, 50), Input(PK, 50)]))\n@production(m, Y, :($transf_elas_y*1.), :($sub_elas_y*1.), [Output(PY, 50)], [Input(PL, 20), Input(PK, 30)])\n@production(m, U, 0, :($sub_elas_u*1.), [Output(PU, 150)], [Input(PX, 100), Input(PY, 50)])","category":"page"},{"location":"tutorial/#Add-Demand-Functions","page":"Tutorial","title":"Add Demand Functions","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"@demand(m, RA, 1., [Demand(PU, 150)], [Endowment(PL, :(70 * $endow)), Endowment(PK, 80.)])","category":"page"},{"location":"tutorial/#Check-the-benchmark-solution","page":"Tutorial","title":"Check the benchmark solution","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"After the model is established and saved under the model name, it is standard to check that the model is mathematically balanced in the benchmark by solving with 0 iterations.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"solve!(m, cumulative_iteration_limit=0)","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"If the model solves with zero iterations, we know that the model and data are balanced and callibrated in the benchmark.      If not, you will get an error  Did not solve with error: CumulativeMinorIterationLimit.\\       The Major Iteration Log from PATH will display the variable(s), preceded by \"F_\" (label) with the largest marginal value, that is the variables that have the residual/solved value or inormthat is larger than the tolerance set, which can be useful for troubleshooting.\\       You can also run solve!(m) without the iteration limit and examine the values for all variables for more clues as to where the benchmark may be unbalanced.","category":"page"},{"location":"tutorial/#See-the-underlying-model-equations","page":"Tutorial","title":"See the underlying model equations","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"You can print the equations and their associated variables.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"algebraic_version(m)","category":"page"},{"location":"tutorial/#Run-Counterfactuals","page":"Tutorial","title":"Run Counterfactuals","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Once the benchmark is established, update variable values and/or parameters, fix or unfix variables etc. and see the solution as in the simulated counterfactual scenario.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"# increase labor endowment by 10%\nset_value(endow, 1.1)\n# Set the consumer RA as the numeraire\nset_fixed!(RA, true)\nsolve!(m)","category":"page"}]
}
