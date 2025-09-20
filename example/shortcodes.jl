module MyShortcodes

export my_shortcodes, render

const my_shortcodes = ["calitem"]

function render(::Val{:calitem}, dict, content)
    """\n~~~{=html}\n<div class=\"box calendar-entry\"><p> <div x-data=\"{ open: false }\">\n<a @click=\"open = ! open\">\n<strong>$(dict["date"])</strong>\n</a>\n<br><br>\n<div x-show=\"open\">\n~~~\n $content\n~~~{=html}\n</div>\n</div>\n</p></div>\n~~~\n"""
end



end # module

