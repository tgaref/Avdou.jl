module PatternsMod

export AND, OR, DIFF, Pattern, expand_pattern

using Glob

struct Pattern
    type::Symbol
    patterns::NTuple{N, String} where N
end

function AND(patterns...)
    Pattern(:and, patterns)
end

function OR(patterns...)
    Pattern(:or, patterns)
end

function DIFF(patterns...)
    Pattern(:diff, patterns)
end

function SIMPLE(pattern)
    Pattern(:simple, (pattern,))
end

function expand_pattern(p::Pattern, base::String)
    ps = map(p -> joinpath(base, p), p.patterns)
    if p.type == :and
        and_pattern(ps)
    elseif p.type == :or
        or_pattern(ps)
    elseif p.type == :diff
        diff_pattern(ps)
    elseif p.type == :simple
        glob(ps[1])
    else
        throw("Unrecognized type of Pattern")
    end
end

function and_pattern(patterns)
    intersect((Set(glob(p)) for p in patterns)...)
end

function or_pattern(patterns)
    union((Set(glob(p)) for p in patterns)...)
end


function diff_pattern(patterns)
    setdiff(Set(glob(patterns[1])), Set(glob(patterns[2])))
end

end # module
