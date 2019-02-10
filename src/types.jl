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

# Custom exception to report errors.
struct AndorError <: Exception
    func::Symbol
    code::Cint
end

const WideChar = Cwchar_t
const Handle = Cint

# Camera structure.
mutable struct Camera <: ScientificCamera
    state::Int
    bufs::Vector{Vector{UInt8}}        # buffers for the frame grabber
    lastimg::Array{T,2} where {T}      # last image
    bytesperline::Int
    clockfrequency::Int
    mono12packed::Bool
    handle::Handle
    Camera() = new(0,
                   Vector{Vector{UInt8}}(undef, 0),
                   Array{UInt8,2}(undef, 0, 0),
                   0, 0, false, -1)
end

abstract type AbstractFeature end

struct CommandFeature <: AbstractFeature
    name::Vector{WideChar}
    CommandFeature(sym::Symbol) = new(widestring(sym))
end

struct BooleanFeature <: AbstractFeature
    name::Vector{WideChar}
    BooleanFeature(sym::Symbol) = new(widestring(sym))
end

struct EnumeratedFeature <: AbstractFeature
    name::Vector{WideChar}
    EnumeratedFeature(sym::Symbol) = new(widestring(sym))
end

struct IntegerFeature <: AbstractFeature
    name::Vector{WideChar}
    IntegerFeature(sym::Symbol) = new(widestring(sym))
end

struct FloatingPointFeature <: AbstractFeature
    name::Vector{WideChar}
    FloatingPointFeature(sym::Symbol) = new(widestring(sym))
end

struct StringFeature <: AbstractFeature
    name::Vector{WideChar}
    StringFeature(sym::Symbol) = new(widestring(sym))
end

struct BooleanOrEnumeratedFeature <: AbstractFeature
    name::Vector{WideChar}
    BooleanOrEnumeratedFeature(sym::Symbol) = new(widestring(sym))
end
