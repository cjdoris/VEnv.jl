module VEnv

import Python_jll

"""
    create(venv)

Create a Python Virtual Environment at the directory `venv`.
"""
function create(venv::AbstractString;
    system_site_packages::Bool=false,
    symlinks::Bool=false,
    copies::Bool=false,
    clear::Bool=true,
    upgrade::Bool=false,
    without_pip::Bool=false,
    prompt::Union{Nothing,AbstractString}=nothing,
    upgrade_deps::Bool=false,
)
    if !Python_jll.is_available()
        error("Python_jll is not available on your platform.")
    end
    venv = abspath(venv)
    args = String[]
    for (arg, val) in [
        "--system-site-packages" => system_site_packages,
        "--symlinks" => symlinks,
        "--copies" => copies,
        "--clear" => clear,
        "--upgrade" => upgrade,
        "--without-pip" => without_pip,
        "--upgrade-deps" => upgrade_deps,
    ]
        if val
            push!(args, arg)
        end
    end
    if prompt !== nothing
        push!(args, "--prompt", prompt)
    end
    cmd = `$(Python_jll.python()) -m venv $args $venv`
    @debug "Creating VEnv" cmd
    Base.run(cmd)
    return
end

function activate!(env::AbstractDict{<:AbstractString,<:AbstractString}, venv::AbstractString)
    venv = abspath(venv)
    path_list = [joinpath(venv, "bin")]
    append!(path_list, Python_jll.PATH_list)
    haskey(ENV, "PATH") && append!(path_list, split(ENV["PATH"], ":"))
    env["PATH"] = join(path_list, ":")
    libpath_list = String[]
    append!(libpath_list, Python_jll.LIBPATH_list)
    haskey(ENV, "LD_LIBRARY_PATH") && append!(libpath_list, split(ENV["LD_LIBRARY_PATH"], ":"))
    env["LD_LIBRARY_PATH"] = join(libpath_list, ":")
    env["VIRTUAL_ENV"] = venv
    delete!(env, "PYTHONHOME")
    return env
end

"""
    getenv(venv; inherit=true)

A dictionary of environment variables in which the given `venv` is activated.

If `inherit` is `true` (the default) then the current `ENV` is included.
"""
function getenv(venv::AbstractString; inherit::Bool=true)
    env = inherit ? copy(ENV) : Dict{String,String}()
    return activate!(env, venv)
end

"""
    addenv(cmd::Cmd, venv::AbstractString; inherit=true)

Add environment variables to `cmd` so that it will run in the virtual environment at `venv`.

If `inherit` is `true` then the current environment `ENV` is included too.

For example, the following prints out the version of Python in the venv at ./venv:
```
run(VEnv.addenv(`python --version`, "./venv"))
```

See also [`python`](@ref) and [`pip`](@ref).
"""
function addenv(cmd::Cmd, venv::AbstractString; inherit::Bool=true)
    env = getenv(venv; inherit)
    return Base.setenv(cmd, env)
end

"""
    run(cmd, venv; inherit=true)

Runs the command `cmd` in the virtual environment at `venv`.

Simply shorthand for `Base.run(VEnv.addenv(...))`.
"""
function run(cmd::Cmd, venv::AbstractString; inherit::Bool=true)
    return Base.run(addenv(cmd, venv; inherit))
end


"""
    create_once([f], venv, version; kw...)

Create a virtual environment if it has not already been created.

Calls `create(venv; kw...)` if the virtual environment at `venv` does not exist or if the
`version` has changed since the last time it was created.

You may optionally also specify a function `f(venv)` which is called when creating the
environment.
"""
function create_once(f::Function, venv::AbstractString, version::AbstractString; kw...)
    venv = abspath(venv)
    verfile = joinpath(venv, ".julia_venv_version")
    if isfile(verfile) && read(verfile, String) == version
        @debug "Virtual Environment already initialised" venv version
    else
        @debug "Creating Virtual Environment" venv version
        rm(verfile, force=true)
        create(venv; kw...)
        f(venv)
        write(verfile, version)
    end
end

function create_once(venv::AbstractString, id::AbstractString; kw...)
    return create_once(()->nothing, venv, id; kw...)
end

end
