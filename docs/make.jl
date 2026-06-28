using Documenter
using UniversalNumbers

makedocs(
    sitename = "UniversalNumbers.jl",
    modules  = [UniversalNumbers],
    format   = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical  = "https://jamesquinlan.github.io/UniversalNumbers.jl/stable/",
        edit_link  = "main",
        assets     = String[],
    ),
    pages = [
        "Home"              => "index.md",
        "Number Systems"    => "number-systems.md",
        "API Reference"     => "api.md",
        "Building"          => "building.md",
    ],
    warnonly = true,   # tolerate missing docstrings until they are added
)

deploydocs(
    repo        = "github.com/jamesquinlan/UniversalNumbers.jl",
    devbranch   = "main",
    push_preview = true,
)
