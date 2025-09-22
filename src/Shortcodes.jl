module ShortcodesMod

export replace_shortcodes, render

function parse_latex_shortcode(input::AbstractString, start::Int=1)
    if input[start] != '\\'
        return nothing
    end

    pos = nextind(input, start)
    # parse name
    name_chars = Char[]
    while pos <= lastindex(input) && isletter(input[pos])
        push!(name_chars, input[pos])
        pos = nextind(input, pos)
    end
    if isempty(name_chars)
        return nothing
    end
    name = String(name_chars)

    args = String[]
    while pos <= lastindex(input) && input[pos] == '{'
        pos = nextind(input, pos)  # skip opening brace
        brace_level = 1
        arg_chars = Char[]
        while pos <= lastindex(input) && brace_level > 0
            c = input[pos]
            next_pos = nextind(input, pos)

            # escaped brace
            if c == '\\' && next_pos <= lastindex(input) && input[next_pos] in ['{','}']
                push!(arg_chars, c)
                push!(arg_chars, input[next_pos])
                pos = nextind(input, next_pos)   # ✅ FIXED
                continue
            elseif c == '{'
                brace_level += 1
            elseif c == '}'
                brace_level -= 1
                if brace_level == 0
                    pos = next_pos  # skip closing brace
                    break
                end
            end
            push!(arg_chars, c)
            pos = next_pos
        end

        if brace_level != 0
            error("Unmatched braces in shortcode $name")
        end
        push!(args, String(arg_chars))
    end

    return name, args, prevind(input, pos)
end


"""
    replace_shortcodes(input::AbstractString, render::Function, known_names=[])

Replace all LaTeX-style shortcodes in `input` using `render(Val(:name), args)`.
Unicode-safe.
"""
function replace_shortcodes(input::AbstractString, render::Function, known_names=String[])
    output = IOBuffer()
    pos = 1
    while pos <= lastindex(input)
        if input[pos] == '\\'
            parsed = parse_latex_shortcode(input, pos)
            if parsed !== nothing
                name, args, endpos = parsed
                if isempty(known_names) || name in known_names
                    print(output, render(Val(Symbol(name)), args))
                    pos = nextind(input, endpos)
                    continue
                end
            end
        end
        print(output, input[pos])
        pos = nextind(input, pos)
    end
    return String(take!(output))
end

end # module
