module MarcosMod

export @context, @rule, @templates, @rules, @copy, @copies, @mine

macro context(block)
    stmts = block.head == :block ? block.args : [block]

    pairs = Expr[]
    for stmt in stmts
        if stmt isa LineNumberNode
            continue
        elseif stmt.head == :(=)
            key = string(stmt.args[1])
            val = stmt.args[2]
            # Wrap the value in esc and a let for caller module
            push!(pairs, :( $key => Base.invokelatest(() -> $val) ))
        else
            error("@context only accepts assignments")
        end
    end

    # Build Dict in caller module
    return esc(:( Dict($(pairs...)) ))
end

macro rule(block)
    stmts = block.args
    pairs = Expr[]
    for stmt in stmts
        if stmt isa LineNumberNode
            continue
        elseif stmt.head == :(=)
            key = stmt.args[1]
            val = stmt.args[2]
            k = if key isa QuoteNode
                key 
            elseif key isa String
                :(Symbol($key))
            elseif key isa Symbol
                QuoteNode(key)
            else
                error("must give a symbol of a string")
            end
            # Wrap the value in esc and a let for caller module
            push!(pairs, :( $k => $val) )
        else
            error("@context only accepts assignments")
        end
    end
    # Build Dict in caller module
    return esc(:( Rule(Dict($(pairs...))) ))
end

macro templates(block)
    stmts = block.args
    pairs = []
    local dict
    for stmt in stmts
        if stmt isa LineNumberNode
            continue
        elseif stmt isa Symbol
            dict = stmt 
        else
            name = stmt.args[1]
            ctx = stmt.args[2]
            push!(pairs, :(($dict[$name], $ctx)))
        end
    end
    return esc(Expr(:vect, pairs... ))    
end

macro rules(block)
    stmts = block.args
    vals = []
    for stmt in stmts
        if stmt isa LineNumberNode
            continue
        else
            push!(vals, :( $stmt ) )
        end
    end
    return esc(Expr(:vect, vals...))
end

macro copy(block)
    stmts = block.args
    pairs = Expr[]
    for stmt in stmts
        if stmt isa LineNumberNode
            continue
        elseif stmt.head == :(=)
            key = stmt.args[1]
            val = stmt.args[2]
            k = if key isa QuoteNode
                key 
            elseif key isa String
                :(Symbol($key))
            elseif key isa Symbol
                QuoteNode(key)
            else
                error("must give a symbol of a string")
            end
            # Wrap the value in esc and a let for caller module
            push!(pairs, :( $k => $val) )
        else
            error("@context only accepts assignments")
        end
    end
    # Build Dict in caller module
    return esc(:( Copy(Dict($(pairs...))) ))
end

macro copies(block)
    stmts = block.args
    vals = []
    for stmt in stmts
        if stmt isa LineNumberNode
            continue
        else
            push!(vals, :( $stmt ) )
        end
    end
    return esc(Expr(:vect, vals...))
end

macro site(block)
    stmts = block.args
    pairs = Expr[]
    for stmt in stmts
        if stmt isa LineNumberNode
            continue
        elseif stmt.head == :(=)
            key = stmt.args[1]
            val = stmt.args[2]
            k = if key isa QuoteNode
                key 
            elseif key isa String
                :(Symbol($key))
            elseif key isa Symbol
                QuoteNode(key)
            else
                error("must give a symbol of a string")
            end
            # Wrap the value in esc and a let for caller module
            push!(pairs, :( $k => $val) )
        else
            error("@site only accepts assignments")
        end
    end
    # Build Dict in caller module
    return esc(:( Site(Dict($(pairs...))) ))
end

macro mine(block)
    stmts = block.args
    pairs = []
    local sitedir
    pairs = Expr[]
    for stmt in stmts
        if stmt isa LineNumberNode
            continue
        elseif stmt isa Symbol
            sitedir = stmt 
        else
            key = stmt.args[1]
            val = stmt.args[2]
            push!(pairs, :( $key => $val))
        end
    end
    return esc(:( execute(Mine(Dict($(pairs...))), $sitedir) ))
end

end
