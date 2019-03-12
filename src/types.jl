#
# types.jl --
#
# Definitions of types.
#
#-------------------------------------------------------------------------------
#
# This file is part of "AndorCameras.jl" released under the MIT license.
#
# Copyright (C) 2017-2019, Éric Thiébaut.
#

"""

`AndorError` is an exception sub-type to report errors occuring in calls to the
Sofware Develement Kit (SDK) of Andor cameras.

"""
struct AndorError <: Exception
    func::Symbol
    code::AT_STATUS
    AndorError(func::Symbol, code::Integer) = new(func, code)
    AndorError(func::AbstractString, code::Integer) = new(Symbol(func), code)
end

"""

`AndorCameraModel` is used to wrap a constant identifier to quickly identify a
specific camera model.

"""
struct AndorCameraModel
    id::Int
end
Base.:(==)(a::AndorCameraModel, b::AndorCameraModel) = a.id == b.id
const _UNKNOWN_MODEL  = AndorCameraModel(0)
const _SIM_CAM_MODEL  = AndorCameraModel(1)
const _ZYLA_MODEL     = AndorCameraModel(2)
const _ZYLA_USB_MODEL = AndorCameraModel(3)

# Camera structure.
mutable struct Camera <: ScientificCamera
    state::Int
    bufs::Vector{Vector{UInt8}}        # buffers for the frame grabber
    lastimg::Array{T,2} where {T}      # last image
    bytesperline::Int
    clockfrequency::Int
    model::AndorCameraModel
    handle::AT_HANDLE
    mono12packed::Bool
    Camera() = new(0,
                   Vector{Vector{UInt8}}(undef, 0),
                   Array{UInt8,2}(undef, 0, 0),
                   0, 0, _UNKNOWN_MODEL, AT_HANDLE_UNINITIALISED, false)
end

const AndorCamera = Camera

# A bit of magic for ccall.
Base.cconvert(::Type{AT_HANDLE}, cam::Camera) = cam.handle

abstract type AbstractFeature end

struct CommandFeature <: AbstractFeature
    name::Vector{AT_CHAR}
    CommandFeature(sym::Symbol) = new(widestring(sym))
end

struct BooleanFeature <: AbstractFeature
    name::Vector{AT_CHAR}
    BooleanFeature(sym::Symbol) = new(widestring(sym))
end

struct EnumeratedFeature <: AbstractFeature
    name::Vector{AT_CHAR}
    EnumeratedFeature(sym::Symbol) = new(widestring(sym))
end

struct IntegerFeature <: AbstractFeature
    name::Vector{AT_CHAR}
    IntegerFeature(sym::Symbol) = new(widestring(sym))
end

struct FloatingPointFeature <: AbstractFeature
    name::Vector{AT_CHAR}
    FloatingPointFeature(sym::Symbol) = new(widestring(sym))
end

struct StringFeature <: AbstractFeature
    name::Vector{AT_CHAR}
    StringFeature(sym::Symbol) = new(widestring(sym))
end

struct BooleanOrEnumeratedFeature <: AbstractFeature
    name::Vector{AT_CHAR}
    BooleanOrEnumeratedFeature(sym::Symbol) = new(widestring(sym))
end
