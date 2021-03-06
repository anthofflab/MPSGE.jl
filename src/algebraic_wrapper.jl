struct AlgebraicWrapper
    _source
end

function algebraic_version(m::Model)
    if m._jump_model===nothing
        return AlgebraicWrapper(build(m))
    else
        return AlgebraicWrapper(m._jump_model)
    end
end

function constraint_values(m::Model)
    for j=1:length(m._nlexpressions)
        var_values = []
        println("Constraint $j: ", value(m._nlexpressions[j],i->begin
            val = MPSGE.Complementarity.result_value(i)
            push!(var_values, "  $i = $val")
            return val
        end))            

        for s in var_values
            println(s)
        end
    end
end

function Base.show(io::IO, m::AlgebraicWrapper)
    println(io, "Mixed complementarity problem with $(length(m._source.ext[:MCP])) constraints:")
    constraint_strings = [JuMP.nl_expr_string(m._source, JuMP.REPLMode, m._source.nlp_data.nlexpr[c.F.index]) for c in m._source.ext[:MCP]]
    
    column1_width = maximum(textwidth.(constraint_strings))

    for (constraint_string, c) in zip(constraint_strings, m._source.ext[:MCP])

        print(io, "  ")

        print(io, rpad(constraint_string, column1_width))

        print(io, "  ┴  ")

        if !isinf(c.lb) && c.lb==c.ub
            print(io, c.var_name, " = $(c.ub)")
        else
            print(io, isinf(c.lb) ? "" : "$(c.lb) < ", c.var_name, isinf(c.ub) ? "" : " < $(c.ub)")
        end

        println(io)
    end
end

function Base.show(io::IO, ::MIME"text/latex", m::AlgebraicWrapper)
    println(io, raw"$$ \begin{alignat*}{3}\\")
    for c in m._source.ext[:MCP]

        print(io, "& ")

        println(io, JuMP.nl_expr_string(m._source, JuMP.IJuliaMode, m._source.nlp_data.nlexpr[c.F.index]))

        print(io, raw"\quad && \perp \quad && ")

        if !isinf(c.lb) && c.lb==c.ub
            print(io, c.var_name, " = $(c.ub)")
        else
            print(io, isinf(c.lb) ? "" : "$(c.lb) <", c.var_name, isinf(c.ub) ? "" : " < $(c.ub)")
        end

        print(io, "\\\\")
    end
    println(io, raw"\end{alignat*}")
    println(io, raw" $$")
end
