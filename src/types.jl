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
    code::AT.STATUS
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
    handle::AT.HANDLE
    mono12packed::Bool
    Camera() = new(0,
                   Vector{Vector{UInt8}}(undef, 0),
                   Array{UInt8,2}(undef, 0, 0),
                   0, 0, _UNKNOWN_MODEL, AT.HANDLE_UNINITIALISED, false)
end

const AndorCamera = Camera

abstract type AbstractFeature end

struct CommandFeature <: AbstractFeature
    name::Vector{AT.WCHAR}
    CommandFeature(sym::Symbol) = new(AT.widestring(sym))
end

struct BooleanFeature <: AbstractFeature
    name::Vector{AT.WCHAR}
    BooleanFeature(sym::Symbol) = new(AT.widestring(sym))
end

struct EnumeratedFeature <: AbstractFeature
    name::Vector{AT.WCHAR}
    EnumeratedFeature(sym::Symbol) = new(AT.widestring(sym))
end

struct IntegerFeature <: AbstractFeature
    name::Vector{AT.WCHAR}
    IntegerFeature(sym::Symbol) = new(AT.widestring(sym))
end

struct FloatingPointFeature <: AbstractFeature
    name::Vector{AT.WCHAR}
    FloatingPointFeature(sym::Symbol) = new(AT.widestring(sym))
end

struct StringFeature <: AbstractFeature
    name::Vector{AT.WCHAR}
    StringFeature(sym::Symbol) = new(AT.widestring(sym))
end

struct BooleanOrEnumeratedFeature <: AbstractFeature
    name::Vector{AT.WCHAR}
    BooleanOrEnumeratedFeature(sym::Symbol) = new(AT.widestring(sym))
end
