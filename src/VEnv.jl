module VEnv

import Python_jll, Pidfile

function select_python()
    if (exe = get(ENV, "JULIA_VENV_PYTHON", "")) != ""
        exe = Sys.which(exe)
        exe === nothing && error("JULIA_VENV_PYTHON=$(ENV["JULIA_VENV_PYTHON"]) does not exist")
        return (exe=exe, jll=false)
    elseif Python_jll.is_available()
        return (exe=Python_jll.python_path, jll=true)
    elseif (exe = Sys.which("python3")) !== nothing
        @warn "Using system python" exe
        return (exe=exe, jll=false)
    elseif (exe = Sys.which("python")) !== nothing
        @warn "Using System python" exe
        return (exe=exe, jll=false)
    else
        return nothing
    end
end

function meta_file(venv)
    return joinpath(abspath(venv), "julia_venv_meta")
end

function meta_read(venv)
    file = meta_file(venv)
    if isfile(file)
        meta = Dict{String,String}()
        open(file) do io
            for line in eachline(io)
                key, value = split(line, " = ", limit=2)
                @assert !haskey(meta, key)
                meta[key] = value
            end
        end
        return meta
    else
        return nothing
    end
end

function meta_write(venv, meta)
    file = meta_file(venv)
    open(file, "w") do io
        for (key, value) in meta
            println(io, key, " = ", value)
        end
    end
    return file
end

function meta_rm(venv)
    rm(meta_file(venv), force=true)
    return
end

function lock_file(venv)
    return joinpath(abspath(venv), "julia_venv_lock")
end

function lock_make(venv)
    file = lock_file(venv)
    lock = try
        Pidfile.mkpidlock(file; wait=false)
    catch
        @info "Waiting for lock to be freed" file
        Pidfile.mkpidlock(file; wait=true)
    end
    return lock
end

function lock_done(lock)
    close(lock)
    return
end

"""
    create([f], venv)

Create a Python Virtual Environment at the directory `venv`.

If `f` is given, then `f(venv)` is also called. It should be used to install packages into
the environment.

## Keyword Arguments
- `system_site_packages=false`
- `symlinks=false`
- `copies=false`
- `clear=true`: Remove any existing packages from the environment.
- `upgrade=false`
- `without_pip=false`
- `prompt=nothing`
- `upgrade_deps=false`
- `version=nothing`: If this is given, it must be a string identifying the version of the
    environment. If the environment has already been created and has the same version, then
    creating the environment is skipped.
- `force=false`: Do no skip creating the environment, even if the versions match.
"""
function create(f::Union{Function,Nothing}, venv::AbstractString;
    system_site_packages::Bool=false,
    symlinks::Bool=false,
    copies::Bool=false,
    clear::Bool=true,
    upgrade::Bool=false,
    without_pip::Bool=false,
    prompt::Union{Nothing,AbstractString}=nothing,
    upgrade_deps::Bool=false,
    version::Union{Nothing,AbstractString}=nothing,
    force::Bool=false,
)
    # check python
    python = select_python()
    if python === nothing
        error("Python is not installed on your system and is not supported by Python_jll.")
    end

    # check venv
    venv = abspath(venv)

    # lock
    lock = lock_make(venv)
    try
        # construct meta
        # TODO: use file locks instead of the "ready" key
        meta = Dict("exe" => python.exe)
        if python.jll
            meta["path"] = Python_jll.PATH[]
            meta["libpath"] = Python_jll.LIBPATH[]
        end
        if version !== nothing
            meta["version"] = version
        end

        # skip
        if version !== nothing && !force && meta_read(venv) == meta
            @debug "Virtual environment already exists" venv version
            return venv
        end

        # delete this now so we never skip unless the install completed
        meta_rm(venv)

        # create the venv
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
        cmd = python.jll ? Python_jll.python() : `$(python.exe)`
        cmd = `$cmd -m venv $args $venv`
        @debug "Creating virtual environment" cmd
        Base.run(cmd)
        meta_write(venv, meta)

        # run the hook
        if f !== nothing
            f(venv)
        end

    finally
        lock_done(lock)
    end

    return venv
end

function create(venv::AbstractString; kw...)
    return create(nothing, venv; kw...)
end

function activate!(env, venv)
    venv = abspath(venv)
    meta = meta_read(venv)
    if meta === nothing
        error("No such virtual environment: $venv")
    end
    # PATH
    path_list = [joinpath(venv, "bin")]
    if haskey(meta, "path")
        push!(path_list, meta["path"])
    end
    if haskey(ENV, "PATH")
        push!(path_list, ENV["PATH"])
    end
    env["PATH"] = join(path_list, ":")
    # LD_LIBRARY_PATH
    libpath_list = String[]
    if haskey(meta, "libpath")
        push!(libpath_list, meta["libpath"])
    end
    if haskey(ENV, "LD_LIBRARY_PATH")
        push!(libpath_list, ENV["LD_LIBRARY_PATH"])
    end
    if !isempty(libpath_list)
        env["LD_LIBRARY_PATH"] = join(libpath_list, ":")
    end
    env["VIRTUAL_ENV"] = venv
    delete!(env, "PYTHONHOME")
    return env
end

"""
    getenv(venv; inherit=true)

A dictionary of environment variables in which the given `venv` is activated.
"""
function getenv(venv::AbstractString; inherit::Bool=true)
    env = inherit ? copy(ENV) : Dict{String,String}()
    return activate!(env, venv)
end

"""
    addenv(cmd::Cmd, venv::AbstractString; inherit=true)

Add environment variables to `cmd` so that it will run in the virtual environment at `venv`.
"""
function addenv(cmd::Cmd, venv::AbstractString; inherit::Bool=true)
    env = getenv(venv; inherit)
    return Base.setenv(cmd, env)
end

"""
    run(cmd, venv; inherit=true)

Runs the command `cmd` in the virtual environment at `venv`.
"""
function run(cmd::Cmd, venv::AbstractString; inherit::Bool=true)
    return Base.run(addenv(cmd, venv; inherit))
end

end
