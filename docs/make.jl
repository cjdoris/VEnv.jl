using VEnv
using Documenter

DocMeta.setdocmeta!(VEnv, :DocTestSetup, :(using VEnv); recursive=true)

makedocs(;
    modules=[VEnv],
    authors="Christopher Doris <github.com/cjdoris> and contributors",
    repo="https://github.com/cjdoris/VEnv.jl/blob/{commit}{path}#{line}",
    sitename="VEnv.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://cjdoris.github.io/VEnv.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/cjdoris/VEnv.jl",
    devbranch="main",
)
