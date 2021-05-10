using Libdl

let
    # Make sure to use a slash for directory separator.
    path_separator_re = Sys.iswindows() ? r"[/\\]+" : r"/+"
    to_path(str::AbstractString) = replace(str, path_separator_re => "/")

    AT_DIR = to_path(get(ENV, "AT_DIR",
                         (Sys.iswindows() ? "C:/Program Files/AndorSDK3" :
                          "/usr/local/andor")))
    hdrname = "atcore.h"
    incdir = ""
    if haskey(ENV, "AT_INCDIR")
        dir = to_path(ENV["AT_INCDIR"])
        if !isfile(dir*"/"*hdrname)
            error("\nDirectory specified by environment variable ",
                  "\"AT_INCDIR\" (\"$dir\") does not contain file Andor SDK ",
                  "header file \"$hdrname\".\n",
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

    libname = (Sys.iswindows() ? "atcore."*Libdl.dlext :
               "libatcore."*Libdl.dlext)
    libdir = ""
    if haskey(ENV, "AT_LIBDIR")
        dir = to_path(ENV["AT_LIBDIR"])
        if !isfile(dir*"/"*libname)
            error("\nDirectory specified by environment variable ",
                  "\"AT_LIBDIR\" (\"$dir\") does not contain file Andor SDK ",
                  "library file \"$libname\".\n",
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
                  "Define environment variable \"AT_LIBDIR\" with the ",
                  "directory containing this file and rebuild.")
        end
    end
    dll = libdir*"/"*libname

    # FIXME: Building all require old usb.h to be available.
    #target = (Sys.islinux() ? "all" : "deps.jl")
    target = "deps.jl"

    print(stderr, "\nI will run the following command:\n",
            "    make $target AT_INCDIR=\"$incdir\" ",
            "AT_LIBDIR=\"$libdir\" AT_DLL=\"$dll\"\n\n")
    run(`make $target AT_INCDIR="$incdir" AT_LIBDIR="$libdir" AT_DLL="$dll"`)
end
