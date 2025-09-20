module ShortcodesMod

export replace_shortcodes, render

using CombinedParsers

# Parser for key=value arguments: "arg = \"value\""
letter = CharIn('a':'z', 'A':'Z')
digit  = CharIn('0':'9')
identifier = map(Repeat(letter, min=1)) do w join(w) end
quoted_string = map(Sequence(CharIn('"'), Repeat(CharIn(c -> c != '"')), CharIn('"'))) do (_, s, _) join(s) end
key_value = map(Sequence(identifier, Repeat(CharIn(' ')), CharIn('='), Repeat(CharIn(' ')), quoted_string)) do x
    (x[1], x[5])
end

args_parser = map(Repeat(key_value, whitespace_maybe)) do v
        Dict(map(t -> t[1], v))
end

function replace_shortcodes(input::String, render::Function, shortcodes::Vector{String})
    output = IOBuffer()
    pos = firstindex(input)

    while pos <= lastindex(input)
        # find the earliest next shortcode
        next_start = nothing
        next_name  = ""
        for name in shortcodes
            idx = findfirst("[$name", input[pos:end])
            if idx !== nothing
                abs_idx = pos + idx.start - 1
                if next_start === nothing || abs_idx < next_start
                    next_start = abs_idx
                    next_name  = name
                end
            end
        end

        if next_start === nothing
            # no more shortcodes
            print(output, input[pos:end])
            break
        else
            # copy text before the shortcode
            if next_start > pos
                print(output, input[pos:next_start-1])
            end

            # find end of opening tag
            sub_open = input[next_start:end]
            open_end_rel = findfirst(']', sub_open)
            if open_end_rel === nothing
                error("Malformed opening tag for $next_name")
            end
            open_end = next_start + open_end_rel - 1

            # extract and parse arguments
            open_content = strip(input[next_start+length("[$next_name"):open_end-1])
            args = Dict{String,String}()
            for kv in eachmatch(r"(\w+)\s*=\s*\"([^\"]*)\"", open_content)
                args[kv.captures[1]] = kv.captures[2]
            end

            # find closing tag
            close_tag = "[/$next_name]"
            sub_after = input[open_end+1:end]
            rel_close = findfirst(close_tag, sub_after)
            if rel_close === nothing
                error("Closing tag not found for $next_name")
            end
            # absolute positions in input
            close_start = open_end + rel_close.start
            close_end   = open_end + rel_close.stop

            # extract content
            content = input[open_end+1 : close_start-1]

            # render and append
            print(output, render(Val(Symbol(next_name)), args, content))

            # advance pos past closing tag
            pos = close_end + 1
        end
    end

    return String(take!(output))
end

end # module
