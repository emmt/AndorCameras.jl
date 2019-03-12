#
# AndorCameras.jl --
#
# Julia interface to Andor cameras.
#
#-------------------------------------------------------------------------------
#
# This file is part of "AndorCameras.jl" released under the MIT license.
#
# Copyright (C) 2017-2019, Éric Thiébaut.
#

__precompile__(true)

module AndorCameras

export
    AndorCamera,
    AndorError

# Import `ScientificCameras` methods in such a way that they can be extended in
# this module and re-export them to make things easier for the end-user.
# FIXME: See https://github.com/NTimmons/ImportAll.jl
using ScientificCameras, ScientificCameras.PixelFormats
for sym in names(ScientificCameras)
    if sym != :ScientificCameras
        @eval begin
            import ScientificCameras: $sym
            export $sym
        end
    end
end
import ScientificCameras: TimeoutError, ScientificCamera, ROI

using Printf

include("AT.jl")
using .AT
include("types.jl")
include("errors.jl")
include("base.jl")
include("features.jl")
using .Features
include("public.jl")

end # module AndorCameras
