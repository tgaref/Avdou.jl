module RulesMod

export Rule, Copy, Context, execute, set_extension, nice_route, pandoc_md_to_html, load_templates, expand_shortcodes

using ..DocumentMod: Document, load_document
using ..ContextMod
using ..PatternsMod
using ..ShortcodesMod: replace_shortcodes

using Glob, Pandoc, Mustache

struct Copy
    pattern::Pattern
    route::Function
end

struct Rule
    pattern::Pattern
    filters::Vector{Function}
    templates::Vector{Tuple{String, Context}}
    route::Function
end

Rule(; pattern, filters=[], templates=[], route="") = Rule(pattern, filters, templates, route)
Rule(dict) = Rule(dict[:pattern], dict[:filters], dict[:templates], dict[:route])

Copy(; pattern, route="") = Copy(pattern, route)
Copy(dict) = Copy(dict[:pattern], dict[:route])

function execute(copy::Copy, site_dir::String, public_dir::String)
    for file in filter(isfile, expand_pattern(copy.pattern, site_dir))
        path = joinpath(public_dir, copy.route(file))
        mkpath(dirname(path))
        cp(file, path; force = true)
    end
end
           
function execute(rule::Rule, site_dir::String, public_dir::String)
    for file in filter(isfile, expand_pattern(rule.pattern, site_dir))
         # create Document
        doc = load_document(file)

        # apply filters
        for f in rule.filters
            doc = f(doc)
        end

        # apply template
        content = doc.content
        for (t, ctx) in rule.templates
            context = doc.metadata
            for (k, v) in ctx
                context[k] = v
            end
            context["content"] = content
            content = Mustache.render(t, context)
        end
                
        # save to disc
        initial_path = joinpath(public_dir, file)
        path = rule.route(initial_path)
        mkpath(dirname(path))
        write(path, content) 
    end
end


####### routing helpers 
function set_extension(str)
    path -> begin
        (base, ext) = splitext(path)
        base * ".html"
    end
end

function nice_route(path)
    (base, _) = splitext(path)
    joinpath(base, "index.html")
end

###### filters
function pandoc_md_to_html(doc)
    content = run(Pandoc.Converter(
        input = doc.content,
        from  = "markdown+latex_macros+tex_math_dollars+tex_math_single_backslash+tex_math_double_backslash+raw_html+fenced_divs+markdown_in_html_blocks+smart",
        to    = "html",
        katex = true))
    Document(doc.path, content, doc.metadata)
end

function expand_shortcodes(shortcodes::Vector{String}, render)
    doc -> begin
        new_content = replace_shortcodes(doc.content, render, shortcodes)
        Document(doc.path, new_content, doc.metadata)
    end
end

using Gumbo, Cascadia

"""
    relativize_paths(html::String; base="")

Convert absolute paths in href/src to relative ones.
"""

###### load templates
function load_templates(dir::AbstractString)
    templates = Dict{String, String}()
    for t in readdir(dir)
        name = basename(t)
        templates[name] = read(joinpath(dir,t), String)
    end    
    templates
end

end # module
