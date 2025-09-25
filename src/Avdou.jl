module Avdou

include("macros.jl")
include("Shortcodes.jl")
include("Document.jl")
include("Patterns.jl")
include("Context.jl")
include("Rules.jl")


using .ContextMod: Context, Data, Mine
using .MarcosMod: @context, @rule, @templates, @rules, @copy, @copies, @site, @mine
using .DocumentMod: Document
using .PatternsMod: Pattern, AND, OR, DIFF, SIMPLE
using .RulesMod: Rule, Copy, set_extension, pandoc_md_to_html, load_templates, nice_route, expand_shortcodes



export @context, @rule, @templates, @rules, @copy, @copies, @site, @mine
export Site, Rule, Copy, execute, set_extension, pandoc_md_to_html, load_templates, nice_route
export Document, Data, Mine, Context
export Pattern, AND, OR, DIFF, SIMPLE
export build, serve, clean, serve_and_watch, expand_shortcodes

struct Site
    sitedir::String
    publicdir::String
    copies::Vector{Copy}
    rules::Vector{Rule}
end

Site(; sitedir = "", publicdir = "public", copies=[], rules=[]) = Site(sitedir, publicdir, copies, rules)
Site(dict) = Site(dict[:sitedir], dict[:publicdir], dict[:copies], dict[:rules])

using HTTP
using Sockets
using Dates

execute(rule::Rule, sitedir::String, publicdir::String) = RulesMod.execute(rule, sitedir, publicdir)
execute(copy::Copy, sitedir::String, publicdir::String) = RulesMod.execute(copy, sitedir, publicdir)
execute(mine::Mine, sitedir::String) = ContextMod.execute(mine, sitedir)

function build(site)
    for copy in site.copies
        RulesMod.execute(copy, site.sitedir, site.publicdir)
    end

    for rule in site.rules
        RulesMod.execute(rule, site.sitedir, site.publicdir)
    end
end

"""
    serve(root::AbstractString; host="127.0.0.1", port=8080)

Serve the static site located in `root` over HTTP.

# Arguments
- `root`: the folder containing the static files (e.g., "public")
- `host`: IP address to bind (default "127.0.0.1")
- `port`: port to listen on (default 8080)
"""

function serve(root::AbstractString="public"; host::AbstractString="127.0.0.1", port::Int=8080)
    println("Serving $root at http://$host:$port …")

    function handler(req::HTTP.Request)
        # Remove leading / from request path
        path = normpath(joinpath(root, req.target[2:end]))
        
        # If path is a directory, look for index.html
        if isdir(path)
            path = joinpath(path, "index.html")
        end

        try 
            if isfile(path)
                return HTTP.Response(200, read(path))
            else
                return HTTP.Response(404, "File not found: $(req.target)")
            end
        catch
            if e isa Base.IOError && occursin("EPIPE", sprint(showerror, e))
                # client disconnected, ignore
                return HTTP.Response(499, "Client closed request")
            else
                rethrow()
            end
        end
    end

    HTTP.serve(handler, host, port)
end

function clean(publicdir = "public")
    println("Removing files in $public_dir ...")
    for file in readdir(publicdir; join=true)
        rm(file; recursive=true)
    end
end



end # module Avdou
