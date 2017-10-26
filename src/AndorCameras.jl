#
# AndorCameras.jl --
#
# Julia interface to Andor cameras.
#
#-------------------------------------------------------------------------------
#
# This file is part of "AndorCameras.jl" released under the MIT license.
#
# Copyright (C) 2017, Éric Thiébaut.
#

module AndorCameras

importall ScientificCameras
import ScientificCameras: TimeoutError, ScientificCamera, ROI
using ScientificCameras.PixelFormats

export
    AndorError

# Re-export the public interface of the ScientificCameras module.
ScientificCameras.@exportpublicinterface

include("constants.jl")
using .Constants
include("types.jl")
include("errors.jl")
include("strings.jl")
include("base.jl")
include("features.jl")
using .Features
include("public.jl")

end # module AndorCameras
