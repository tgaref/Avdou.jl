module ContextMod

export Context, Data, Mine, execute

using Glob

using ..PatternsMod: Pattern, expand_pattern
using ..DocumentMod: Document, load_document

Context = Dict{String, Any}
Data = Dict{String, Context}

struct Mine
    pattern::Pattern
    miners::Vector{Function}
end

Mine(; pattern, miners=[]) = Mine(pattern, miners)
Mine(dict) = Mine(dict[:pattern], dict[:miners])

function execute(mine::Mine, sitedir::String)
    data = Data()
    for file in filter(isfile, expand_pattern(mine.pattern, sitedir))
        # create Document
        doc = load_document(file)
        
        # apply miners
        for f in mine.miners
            data[file] = f(doc)
        end
    end
    data
end

end # module
