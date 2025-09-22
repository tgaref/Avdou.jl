module MarcosMod

export @context

macro context(block)
    # Capture the module where the macro is called
    caller_mod = __module__

    stmts = block.head == :block ? block.args : [block]

    pairs = Expr[]
    for stmt in stmts
        if stmt isa LineNumberNode
            continue
        elseif stmt.head == :(=)
            key = string(stmt.args[1])
            val = stmt.args[2]
            # Wrap the value in esc and a let for caller module
#            push!(pairs, :( $key => Base.invokelatest(() -> $val) ))
            push!(pairs, :( $key => $val ))
        else
            error("@context only accepts assignments")
        end
    end

    # Build Dict in caller module
    return esc(:( Dict($(pairs...)) ))
end

end
