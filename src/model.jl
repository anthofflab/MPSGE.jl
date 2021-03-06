struct ParameterRef
    model
    index::Int
end

struct SectorRef
    model
    index::Int
    subindex::Any
    subindex_names::Any
end

struct CommodityRef
    model
    index::Int
    subindex::Any
    subindex_names::Any
end

struct ConsumerRef
    model
    index::Int
end

mutable struct Parameter
    name::Symbol
    value::Float64
end

struct Sector
    name::Symbol
    indices::Any
    benchmark::Float64
    description::String

    function Sector(name::Symbol; description::AbstractString="", benchmark::Float64=1., indices=nothing)
        return new(name, indices, benchmark, description)
    end
end

abstract type Commodity end;

mutable struct ScalarCommodity <: Commodity
    name::Symbol
    benchmark::Float64
    description::String
    fixed::Bool

    function ScalarCommodity(name::Symbol; description::AbstractString="", benchmark::Float64=1., fixed=false)
        return new(name, benchmark, description, fixed)
    end
end

mutable struct IndexedCommodity <: Commodity
    name::Symbol
    indices::Any
    benchmark::DenseAxisArray
    description::String
    fixed::DenseAxisArray

    function IndexedCommodity(name::Symbol, indices; description::AbstractString="", benchmark::Float64=1., fixed=false)
        return new(name, indices, DenseAxisArray(fill(benchmark, length.(indices)...), indices...), description, DenseAxisArray(fill(fixed, length.(indices)...), indices...))
    end
end

function Commodity(name; indices=nothing, kwargs...)
    return indices===nothing ? ScalarCommodity(name; kwargs...) : IndexedCommodity(name, indices; kwargs...)
end

struct Consumer
    name::Symbol
    benchmark::Float64
    description::String

    function Consumer(name::Symbol; description::AbstractString="", benchmark::Float64=1.)
        return new(name, benchmark, description)
    end
end

mutable struct Input
    commodity::CommodityRef
    quantity::Union{Float64,Expr}
    production_function::Any

    function Input(commodity::CommodityRef, quantity::Union{Float64,Expr})
        return new(commodity, quantity, nothing)
    end
end

mutable struct Output
    commodity::CommodityRef
    quantity::Union{Float64,Expr}
    production_function::Any

    function Output(commodity::CommodityRef, quantity::Union{Float64,Expr})
        return new(commodity, quantity, nothing)
    end
end

struct Production
    sector::SectorRef
    elasticity::Union{Float64,Expr}
    outputs::Vector{Output}
    inputs::Vector{Input}

    function Production(sector::SectorRef, elasticity::Union{Float64,Expr}, outputs::Vector{Output}, inputs::Vector{Input})
        x = new(sector, elasticity, outputs, inputs)

        for output in outputs
            output.production_function = x
        end
        
        for input in inputs
            input.production_function = x
        end

        return x
    end
end

struct Endowment
    commodity::CommodityRef
    quantity::Union{Float64,Expr}
end

mutable struct Demand
    commodity::CommodityRef
    quantity::Union{Float64,Expr}
    demand_function::Any

    function Demand(commodity::CommodityRef, quantity::Union{Float64,Expr})
        return new(commodity, quantity, nothing)
    end
end

struct DemandFunction
    consumer::ConsumerRef
    demands::Vector{Demand}
    endowments::Vector{Endowment}

    function DemandFunction(consumer::ConsumerRef, demands::Vector{Demand}, endowments::Vector{Endowment})
        x = new(consumer, demands, endowments)

        for demand in demands
            demand.demand_function = x
        end
        
        return x
    end
end

mutable struct Model
    _parameters::Vector{Parameter}
    _sectors::Vector{Sector}
    _commodities::Vector{Commodity}
    _consumers::Vector{Consumer}

    _productions::Vector{Production}
    _demands::Vector{DemandFunction}

    _jump_model::Union{Nothing,JuMP.Model}
    _status

    _nlexpressions::Vector{Any}

    function Model()
        return new(
            Parameter[],
            Sector[],
            Commodity[],
            Consumer[],
            Production[],
            DemandFunction[],
            nothing,
            nothing,
            []
        )
    end
end


function Base.show(io::IO, m::Model)
    println(io, "MPSGE model with $(length(m._sectors)) sectors, $(length(m._commodities)) commodities and $(length(m._consumers)) consumers.")

    if length(m._sectors) > 0
        print(io, "  Sectors: ")
        print(io, join(["$(s.name) (bm=$(s.benchmark))" for s in m._sectors], ", "))
        println(io)
    end

    if length(m._commodities) > 0
        print(io, "  Commodities: ")
        print(io, join(["$(c.name) (bm=$(c.benchmark))" for c in m._commodities], ", "))
        println(io)
    end

    if length(m._consumers) > 0
        print(io, "  Consumers: ")
        print(io, join(["$(c.name) (bm=$(c.benchmark))" for c in m._consumers], ", "))
        println(io)
    end

    if m._jump_model!==nothing
        if m._status==:Solved
            println(io, "Solution:")

            for n in JuMP.all_variables(m._jump_model)
                println(io, "  $n:\t$(Complementarity.result_value(n))")
            end        
        else
            println(io, "Did not solve with error: $(m._status).")
        end
    end
end

function get_name(sector::SectorRef, include_subindex=false)
    if sector.subindex===nothing || include_subindex==false
        return sector.model._sectors[sector.index].name
    else
        return Symbol("$(sector.model._sectors[sector.index].name )[$(sector.subindex_names)]")
    end
end

function get_name(commodity::CommodityRef, include_subindex=false)
    if commodity.subindex===nothing || include_subindex==false
        return commodity.model._commodities[commodity.index].name
    else
        return Symbol("$(commodity.model._commodities[commodity.index].name )[$(commodity.subindex_names)]")
    end
end

function get_name(consumer::ConsumerRef)
    return consumer.model._consumers[consumer.index].name
end

function get_full(s::SectorRef)
    return s.model._sectors[s.index]
end

function get_full(c::CommodityRef)
    return c.model._commodities[c.index]
end

# Outer constructors

function Input(commodity::CommodityRef, quantity::Number)
    return Input(commodity, convert(Float64, quantity))
end

function Output(commodity::CommodityRef, quantity::Number)
    return Output(commodity, convert(Float64, quantity))
end

function Production(sector::SectorRef, elasticity::Union{Number,Expr}, outputs::Vector{Output}, inputs::Vector{Input})

    if isa(elasticity,Number)
        elasticity = convert(Float64, elasticity)
    end

    return Production(sector, elasticity, outputs, inputs)
end

function Endowment(commodity::CommodityRef, quantity::Number)
    return Endowment(commodity, convert(Float64, quantity))
end

function Demand(commodity::CommodityRef, quantity::Number)
    return Demand(commodity, convert(Float64, quantity))
end

function add!(m::Model, s::Sector)
    m._jump_model = nothing
    push!(m._sectors, s)
    if s.indices===nothing
        return SectorRef(m, length(m._sectors), nothing, nothing)
    else
        temp_array = Array{SectorRef}(undef, length.(s.indices)...)

        for i in CartesianIndices(temp_array)
            temp_array[i] = SectorRef(m, length(m._sectors), i, string(s.indices[1][i]))
        end
        return JuMP.Containers.DenseAxisArray(temp_array, s.indices...)
    end
end

function add!(m::Model, c::ScalarCommodity)
    m._jump_model = nothing
    push!(m._commodities, c)
    return CommodityRef(m, length(m._commodities), nothing, nothing)
end

function add!(m::Model, c::IndexedCommodity)
    m._jump_model = nothing
    push!(m._commodities, c)

    temp_array = Array{CommodityRef}(undef, length.(c.indices)...)

    for i in CartesianIndices(temp_array)
        # TODO Fix the [1] thing here to properly work with n-dimensional data
        temp_array[i] = CommodityRef(m, length(m._commodities), i, string(c.indices[1][i]))
    end
    return JuMP.Containers.DenseAxisArray(temp_array, c.indices...)
end

function add!(m::Model, c::Consumer)
    m._jump_model = nothing
    push!(m._consumers, c)
    return ConsumerRef(m, length(m._consumers))
end

function add!(m::Model, p::Production)
    m._jump_model = nothing
    push!(m._productions, p)
    return m
end

function add!(m::Model, c::DemandFunction)
    m._jump_model = nothing
    push!(m._demands, c)
    return m
end

function add!(m::Model, p::Parameter)
    m._jump_model = nothing
    push!(m._parameters, p)
    return ParameterRef(m, length(m._parameters))
end

function JuMP.value(m::Model, name::Symbol)
    Complementarity.result_value(m._jump_model[name])
end

function solve!(m::Model; solver::Symbol=:PATH, kwargs...)
    if m._jump_model===nothing
        m._jump_model = build(m)
    end

    set_all_start_values(m)
    set_all_parameters(m)
    set_all_bounds(m)

    m._status = Complementarity.solveMCP(m._jump_model; solver=solver, kwargs...)

    return m
end

function JuMP.set_value(p::ParameterRef, new_value::Float64)
    p.model._parameters[p.index].value = new_value
end

function set_fixed!(commodity::CommodityRef, new_value::Bool)    
    c = commodity.model._commodities[commodity.index]
    if c isa ScalarCommodity
        c.fixed = new_value
    else
        c.fixed[commodity.subindex] = new_value
    end
    return nothing
end
