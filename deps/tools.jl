#
# tools.jl --
#
# Tools for installing `AndorCameras` package: `parse_header` is a simple
# parser to fetch definitions from Andor SDK header file <atcore.h> and
# `make_deps` is called to generate "deps.jl".
#
module AndorInstallTools

using Libdl

# List of expected macros (except error code):
const MACROS = Dict(
    "INFINITE" => "Cuint",
    "TRUE" => "BOOL",
    "FALSE" => "BOOL",
    "HANDLE_UNINITIALISED" => "HANDLE",
    "HANDLE_SYSTEM" => "HANDLE",
    "SUCCESS" => "Cint",
    "CALLBACK_SUCCESS" => "Cint",
)

function parse_header(filename::String)
    code = ["# Constants.",]
    tail = String[]
    open(filename, "r") do io
        linenumber = 0
        while !eof(io)
            line = readline(io; keep=false)
            linenumber += 1
            m = match(r"^ *# *define +AT_([^ ]+) *([^ ]+) *$", line)
            m === nothing && continue
            name, value = m.captures
            if haskey(MACROS, name)
                type = MACROS[name]
            elseif startswith(name, "ERR_")
                type = "Cint"
            else
                continue
            end
            if tryparse(Int, value) === nothing
                println(stderr, "Warning: parsed value \"$value\" ",
                        "cannot be converted to an integer constant ",
                        "($filename, line $linenumber)")
                continue
            end
            push!((type == "Cint" ? tail : code),
                  "const $name = $(type)($value)")
        end
    end
    push!(code, "", "# Status codes.")
    append!(code, tail)
end

# Make sure to use a slash for directory separator.
const PATH_SEPARATOR_RE = Sys.iswindows() ? r"[/\\]+" : r"/+"
fix_path(str::AbstractString) = replace(str, PATH_SEPARATOR_RE => "/")

function make_deps(target::String;
                   header::String = "",
                   library::String = "",
                   compile::Bool =  Sys.islinux())
    AT_DIR = fix_path(get(ENV, "AT_DIR",
                          (Sys.iswindows() ? "C:/Program Files/AndorSDK3" :
                           "/usr/local/andor")))

    # Find Andor SDK header <atcore.h>
    if header != ""
        header = fix_path(header)
        incdir = fix_path(dirname(header))
    else
        incdir = ""
        hdrname = "atcore.h"
        if haskey(ENV, "AT_INCDIR")
            dir = fix_path(ENV["AT_INCDIR"])
            if !isfile(dir*"/"*hdrname)
                error("\nDirectory specified by environment variable ",
                      "\"AT_INCDIR\" (\"$dir\") does not contain file ",
                      "Andor SDK header file \"$hdrname\".\n",
                      "Fix the definition of \"AT_INCDIR\" and rebuild.")
            end
            incdir = dir
        else
            for dir in (AT_DIR*"/include", AT_DIR)
                if isdir(dir) && isfile(dir*"/"*hdrname)
                    incdir = dir
                    break
                end
            end
            if incdir == ""
                error("\nAndor SDK header file \"$hdrname\" not found.\n",
                      "Define environment variable \"AT_INCDIR\" with the ",
                      "directory containing this file and rebuild.")
            end
        end
        header = incdir*"/"*hdrname
    end

    # Find Andor SDK library.
    if library != ""
        library = fix_path(library)
        incdir = fix_path(dirname(library))
    else
        libdir = ""
        libname = (Sys.iswindows() ? "atcore."*Libdl.dlext :
                   "libatcore."*Libdl.dlext)
        libdir = ""
        if haskey(ENV, "AT_LIBDIR")
            dir = fix_path(ENV["AT_LIBDIR"])
            if !isfile(dir*"/"*libname)
                error("\nDirectory specified by environment variable ",
                      "\"AT_LIBDIR\" (\"$dir\") does not contain file ",
                      "Andor SDK library file \"$libname\".\n",
                      "Fix the definition of \"AT_LIBDIR\" and rebuild.")
            end
            libdir = dir
        else
            for dir in (AT_DIR*"/lib", AT_DIR)
                if isdir(dir) && isfile(dir*"/"*libname)
                    libdir = dir
                    break
                end
            end
            if libdir == ""
                error("\nAndor SDK library file \"$libname\" not found.\n",
                      "Define environment variable \"AT_LIBDIR\" with ",
                      "the directory containing this file and rebuild.")
            end
        end
        library = libdir*"/"*libname
    end

    if compile
        # FIXME: Building all require old usb.h to be available.
        #target = (Sys.islinux() ? "all" : "deps.jl")
        print(stderr, "\nI will run the following command:\n",
              "    make TARGET=$(repr(target)) AT_INCDIR=$(repr(incdir)) ",
              "AT_LIBDIR=$(repr(libdir)) AT_DLL=$(repr(library))\n\n")
        run(`make TARGET=$(repr(target)) AT_INCDIR=$(repr(incdir)) AT_LIBDIR=$(repr(libdir)) AT_DLL=$(repr(library))`)
    else
        code = parse_header(header)
        open(target, "w") do io
            println(io, "#")
            println(io, "# deps.jl --")
            println(io, "#")
            println(io, "# Definitions of types and constants for interfacing Andor cameras in Julia.")
            println(io, "#")
            println(io, "# *DO NOT EDIT* as this file has been automatically generated.")
            println(io, "#")
            println(io)
            println(io, "# Path to the dynamic library.")
            println(io, "const _DLL = $(repr(library))")
            println(io)
            foreach(line -> println(io, line), code)
        end
    end
end

end # module
