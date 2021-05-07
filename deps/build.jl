using Libdl

let AT_DIR = get(ENV, "AT_DIR", (Sys.iswindows() ? "C:/Program Files/AndorSDK3" :
                                 "/usr/local/andor"))
    hdrname = "atcore.h"
    incdir = ""
    if haskey(ENV, "AT_INCDIR")
        dir = ENV["AT_INCDIR"]
        if !isfile(joinpath(dir, hdrname))
            error("\nDirectory specified by environment variable \"AT_INCDIR\" ",
                  "(\"$dir\") does not contain file Andor SDK header file ",
                  "\"$hdrname\".\n",
                  "Fix the definition of \"AT_INCDIR\" and rebuild.")
        end
        incdir = normpath(dir)
    else
        for dir in (joinpath(AT_DIR, "include"), AT_DIR)
            if isdir(dir) && isfile(joinpath(dir, hdrname))
                incdir = normpath(dir)
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
        dir = normpath(ENV["AT_LIBDIR"])
        if !isfile(joinpath(dir, libname))
            error("\nDirectory specified by environment variable \"AT_LIBDIR\" ",
                  "(\"$dir\") does not contain file Andor SDK library file ",
                  "\"$libname\".\n",
                  "Fix the definition of \"AT_LIBDIR\" and rebuild.")
        end
        libdir = normpath(dir)
    else
        for dir in (joinpath(AT_DIR, "lib"), AT_DIR)
            if isdir(dir) && isfile(joinpath(dir, libname))
                libdir = normpath(dir)
                break
            end
        end
        if libdir == ""
            error("\nAndor SDK library file \"$libname\" not found.\n",
                  "Define environment variable \"AT_LIBDIR\" with the ",
                  "directory containing this file and rebuild.")
        end
    end
    dll = joinpath(libdir, libname)

    # FIXME: Building all require old usb.h to be available.
    #target = (Sys.islinux() ? "all" : "deps.jl")
    target = "deps.jl"

    print(stderr, "\nI will run the following command:\n",
            "    make $target AT_INCDIR=\"$incdir\" ",
            "AT_LIBDIR=\"$libdir\" AT_DLL=\"$dll\"\n\n")
    run(`make $target AT_INCDIR="$incdir" AT_LIBDIR="$libdir" AT_DLL="$dll"`)
end
