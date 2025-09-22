using Avdou

function setup(; site_dir = "", public_dir = "public", prefix = "")
    templates = load_templates("templates")
    ctx = Context()

    ctx["prefix"] = prefix
    ctx["today"] = today()
        
    copies = [
        Copy(SIMPLE("css/*"), identity),
        Copy(SIMPLE("content/static/*"), identity),
        Copy(SIMPLE("content/static/*/*"), identity),
        Copy(DIFF("content/teaching/*/*", "content/teaching/*/*.md"), identity),
        Copy(DIFF("content/activities/*/*", "content/activities/*/*.md"), identity) 
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
             nice_route),
        Rule(SIMPLE("content/activities/*/*.md"),
             [pandoc_md_to_html],
             [(templates["base.html"], ctx)],
             set_extension("html"))
    ]

    site = Site(site_dir, public_dir, copies, rules)
    build(site)
end

### Shortcodes

const my_shortcodes = ["calitem"]

function render(::Val{:calitem}, args)
    """\n~~~{=html}\n<div class=\"box calendar-entry\"><p> <div x-data=\"{ open: false }\">\n<a @click=\"open = ! open\">\n<strong>$(args[1])</strong>\n</a>\n<br><br>\n<div x-show=\"open\">\n~~~\n $(args[2])\n~~~{=html}\n</div>\n</div>\n</p></div>\n~~~\n"""
end

### Utilities
using Dates

function today()
    dt = Dates.today()
    month = monthname(dt)
    "$month $(day(dt)), $(year(dt))"
end



