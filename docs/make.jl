using PythonVEnv
using Documenter

DocMeta.setdocmeta!(PythonVEnv, :DocTestSetup, :(using PythonVEnv); recursive=true)

makedocs(;
    modules=[PythonVEnv],
    authors="Christopher Doris <github.com/cjdoris> and contributors",
    repo="https://github.com/Christopher Rowley/PythonVEnv.jl/blob/{commit}{path}#{line}",
    sitename="PythonVEnv.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Christopher Rowley.github.io/PythonVEnv.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Christopher Rowley/PythonVEnv.jl",
    devbranch="main",
)
