using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))  # activate the project root

include("../src/Avdou.jl")
include("shortcodes.jl")
using .Avdou: Site, Rule, Copy, Document, execute, set_extension, pandoc_md_to_html, nice_route
using .Avdou: Context, load_templates, AND, OR, DIFF, SIMPLE, build, serve, expand_shortcodes
using .MyShortcodes: my_shortcodes, render

function test()
    rule = Rule("*.md", [pandoc_md_to_html], [], set_extension("html"))
    execute(rule, "", "public")
end

function setup(; site_dir = "", public_dir = "public")
    templates = load_templates("templates")
    ctx = Context()
        
    copies = [
        Copy(SIMPLE("css/*"), identity)
    ]
    
    rules = [
        Rule(DIFF("content/*.md", "content/index.md"),
             [pandoc_md_to_html],
             [(templates["section.html"], ctx), (templates["base.html"], ctx)],
             nice_route),

        Rule(SIMPLE("content/index.md"), 
             [pandoc_md_to_html],
             [(templates["index.html"], ctx), (templates["base.html"], ctx)],
             path -> joinpath(public_dir, "index.html")),

        Rule(SIMPLE("content/teaching/*/*.md"),
             [expand_shortcodes(my_shortcodes, render), pandoc_md_to_html],
             [(templates["course.html"], ctx), (templates["base.html"], ctx)],
             nice_route)         
    ]

    site = Site(site_dir, public_dir, copies, rules)
    build(site)
end


    


