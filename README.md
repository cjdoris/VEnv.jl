# VEnv.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://cjdoris.github.io/VEnv.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://cjdoris.github.io/VEnv.jl/dev/)
[![Build Status](https://github.com/cjdoris/VEnv.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/cjdoris/VEnv.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/cjdoris/VEnv.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/cjdoris/VEnv.jl)
[![Coverage](https://coveralls.io/repos/github/cjdoris/VEnv.jl/badge.svg?branch=main)](https://coveralls.io/github/cjdoris/VEnv.jl?branch=main)
[![PkgEval](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/P/VEnv.svg)](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/report.html)

Create and use Python virtual environments.

## Install

From the Julia REPL, press `]` to enter the package manager, then run
```
pkg> add https://github.com/cjdoris/VEnv.jl
```

## Examples

### Basic Usage

The following script creates a temporary directory containing a virtual environment,
installs [`cowsay`](https://pypi.org/project/cowsay/) into it, then calls it to print a
message to the terminal.

```julia
using VEnv
venv = mktempdir()
VEnv.create(venv)
VEnv.run(`pip install cowsay`, venv);
VEnv.run(`python -m cowsay --character tux 'Hello, world!'`, venv);
```
```text
  _____________
| Hello, world! |
  =============
                  \
                   \
                    \
                     .--.
                    |o_o |
                    |:_/ |
                   //   \ \
                  (|     | )
                 /'\_   _/`\
                 \___)=(___/
```

### Usage In Packages

Here is a minimal example of a package providing an interface to the Python
[`cowsay`](https://pypi.org/project/cowsay/) package.

The `_venv()` function returns the path to a virtual environment with the `cowsay` package
installed.

The virtual environment is installed into a scratch space using
[`Scratch.jl`](https://github.com/JuliaPackaging/Scratch.jl). This is a Julia-managed
directory which will be automatically deleted when the package itself is deleted.

It uses `create_once` to create the virtual environment. Unlike `create`, it will only
create the environment if it does not exist yet, or if the `version` has changed. This means
that subsequent calls to `_venv()` are very fast.

The body of the `do` block is also called when the environment is created. Use this to
install packages into the environment. Increment the `version` whenever the `create_once`
call changes to ensure the environment is recreated - for example when changing the packages
installed (or the versions of packages).

The `cowsay()` function is an example of how to use the virtual environment. In this case,
we use `VEnv.run` to run the `cowsay` command in the environment.

```julia
using VEnv, Scratch

function _venv()
    venv = Scratch.@get_scratch!("venv")
    version = "1"
    VEnv.create_once(venv, version) do venv
        VEnv.run(`pip install cowsay`, venv)
    end
    return venv
end

function cowsay(message; character="cow")
    VEnv.run(`python -m cowsay --character $character $message`, _venv())
end
```
