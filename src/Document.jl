module DocumentMod

export Metadata, Document, load_document

using YAML

Metadata = Dict{String, Any}

struct Document
    path::String
    content::Union{Nothing, String}
    metadata::Metadata
end


function load_document(path::AbstractString)
    md = read(path, String)

    # Check if it starts with YAML front matter
    if startswith(md, "---")
        # Split on the first occurrence of "---" after the first line
        parts = split(md, r"(?m)^---\s*$", limit=3)
        # parts[1] is empty because split starts at the first ---
        # parts[2] is the YAML header, parts[3] is the body
        header = parts[2]
        body   = join(parts[3:end], "---")  # in case "---" appears in body

        meta = YAML.load(header)  # returns a Dict
        return Document(path, body, meta)
    else
        # No YAML header
        return Document(path, md, Dict())
    end
end

end # module
