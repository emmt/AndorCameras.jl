#
# base.jl --
#
# Basic methods for Andor cameras.
#
#-------------------------------------------------------------------------------
#
# This file is part of "AndorCameras.jl" released under the MIT license.
#
# Copyright (C) 2017, Éric Thiébaut.
#

getnumberofdevices() = Int(_devicecount[])

const _devicecount = Ref{Int64}()
function __init__()
    code = ccall((:AT_InitialiseLibrary, _DLL), Cint, ())
    code == AT_SUCCESS || throw(AndorError(:AT_InitialiseLibrary, code))
    code = ccall((:AT_GetInt, _DLL), Cint, (Handle, Ptr{WideChar}, Ptr{Int64}),
                 AT_HANDLE_SYSTEM, L"DeviceCount", _devicecount)
    if code != AT_SUCCESS
        ccall((:AT_FinaliseLibrary, _DLL), Cint, ())
        throw(AndorError(:AT_GetInt, code))
    end
end

"""
    checkstate(cam, state, throwerrors=false)

returns whether camera `cam` is in a specific state: 0 if it must be closed
(or not yet open), 1 if it must be open (but acquisition not running) or 2
if acquisition must be running.  If the state is not the expected one, an
error is thrown if `throwerrors` is true or a warning message printed
otherwise.

"""
function checkstate(cam::Camera, state::Integer, throwerrors::Bool = false)
    if cam.state == state
        return true
    else
        local msg::String
        if state == 1 && cam.state == 0
            msg = "camera not open"
        elseif (state == 0 || state == 1) && cam.state == 2
            msg = "acquisition is running"
        elseif state == 2 && (cam.state == 0 || cam.state == 1)
            msg = "acquisition not started"
        elseif state == 0 && (cam.state == 1 || cam.state == 2)
            msg = "camera not closed"
        else
            msg = "corrupted camera instance"
        end
        if throwerrors
            error(msg)
        else
            warn(msg)
        end
        return false
    end
end

function _close(cam::Camera, throwerrors::Bool = false)
    if cam.state > 1
        # Stop acquisition.
        _stop(cam, throwerrors)
        _flush(cam, throwerrors)
        cam.state = 1
    end
    if cam.state > 0
        # Release handle.
        code = ccall((:AT_Close, _DLL), Cint, (Handle,), cam.handle)
        if code != AT_SUCCESS && throwerrors
            throw(AndorError(:AT_Close, code))
        end
        cam.handle = -1
        cam.state = 0
    end
    nothing
end

function _command(cam::Camera, cmd::CommandFeature, throwerrors::Bool = false)
    code = ccall((:AT_Command, _DLL), Cint, (Handle, Ptr{WideChar}),
                 cam.handle, cmd.name)
    if code != AT_SUCCESS && throwerrors
        throw(AndorError(:AT_Command, code))
    end
    nothing
end

_stop(cam::Camera, throwerrors::Bool = false) =
    _command(cam, AcquisitionStop, throwerrors)


"""
    _flush(cam, throwerrors=false) -> code

flushes out any remaining buffers that have been queued using the
`_queuebuffer` function.  If this function is not called after an
acquisition is complete then the remaining buffers will be used the next
time an acquisition is started.

"""
function _flush(cam::Camera, throwerrors::Bool = false)
    code = ccall((:AT_Flush, _DLL), Cint, (Handle,), cam.handle)
    if code != AT_SUCCESS && throwerrors
        throw(AndorError(:AT_Flush, code))
    end
    return code
end

# Execute a command:

Base.send(cam::Camera, cmd::CommandFeature) =
    _command(cam, cmd, true)


# Methods for any feature type:

function isimplemented(cam::Camera, key::AbstractFeature)
    ref = Ref{Cint}()
    code = ccall((:AT_IsImplemented, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Ptr{Cint}),
                 cam.handle, key.name, ref)
    code == AT_SUCCESS || throw(AndorError(:AT_IsImplemented, code))
    return (ref[] == AT_TRUE)
end

function Base.isreadable(cam::Camera, key::AbstractFeature)
    ref = Ref{Cint}()
    code = ccall((:AT_IsReadable, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Ptr{Cint}),
                 cam.handle, key.name, ref)
    code == AT_SUCCESS || throw(AndorError(:AT_IsReadable, code))
    return (ref[] == AT_TRUE)
end

function Base.iswritable(cam::Camera, key::AbstractFeature)
    ref = Ref{Cint}()
    code = ccall((:AT_IsWritable, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Ptr{Cint}),
                 cam.handle, key.name, ref)
    code == AT_SUCCESS || throw(AndorError(:AT_IsWritable, code))
    return (ref[] == AT_TRUE)
end

function Base.isreadonly(cam::Camera, key::AbstractFeature)
    ref = Ref{Cint}()
    code = ccall((:AT_IsReadOnly, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Ptr{Cint}),
                 cam.handle, key.name, ref)
    code == AT_SUCCESS || throw(AndorError(:AT_IsReadOnly, code))
    return (ref[] == AT_TRUE)
end


# Integer features:

function Base.getindex(cam::Camera, key::IntegerFeature)
    ref = Ref{Int64}()
    code = ccall((:AT_GetInt, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Ptr{Int64}),
                 cam.handle, key.name, ref)
    code == AT_SUCCESS || throw(AndorError(:AT_GetInt, code))
    return Int(ref[])
end

Base.setindex!(cam::Camera, val::Integer, key::IntegerFeature) =
    setindex!(cam, convert(Int64, val), key)

function Base.setindex!(cam::Camera, val::Int64, key::IntegerFeature)
    code = ccall((:AT_SetInt, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Int64),
                 cam.handle, key.name, val)
    code == AT_SUCCESS || throw(AndorError(:AT_SetInt, code))
    return nothing
end

function Base.minimum(cam::Camera, key::IntegerFeature)
    ref = Ref{Int64}()
    code = ccall((:AT_GetIntMin, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Ptr{Int64}),
                 cam.handle, key.name, ref)
    code == AT_SUCCESS || throw(AndorError(:AT_GetIntMin, code))
    return Int(ref[])
end

function Base.maximum(cam::Camera, key::IntegerFeature)
    ref = Ref{Int64}()
    code = ccall((:AT_GetIntMax, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Ptr{Int64}),
                 cam.handle, key.name, ref)
    code == AT_SUCCESS || throw(AndorError(:AT_GetIntMax, code))
    return Int(ref[])
end


# Floating-point features:

function Base.getindex(cam::Camera, key::FloatingPointFeature)
    ref = Ref{Cdouble}()
    code = ccall((:AT_GetFloat, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Ptr{Cdouble}),
                 cam.handle, key.name, ref)
    code == AT_SUCCESS || throw(AndorError(:AT_GetFloat, code))
    return ref[]
end

Base.setindex!(cam::Camera, val::Real, key::FloatingPointFeature) =
    setindex!(cam, convert(Cdouble, val), key)

function Base.setindex!(cam::Camera, val::Cdouble,
                        key::FloatingPointFeature)
    code = ccall((:AT_SetFloat, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Cdouble),
                 cam.handle, key.name, val)
    code == AT_SUCCESS || throw(AndorError(:AT_SetFloat, code))
    return nothing
end

function Base.minimum(cam::Camera, key::FloatingPointFeature)
    ref = Ref{Cdouble}()
    code = ccall((:AT_GetFloatMin, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Ptr{Cdouble}),
                 cam.handle, key.name, ref)
    code == AT_SUCCESS || throw(AndorError(:AT_GetFloatMin, code))
    return ref[]
end

function Base.maximum(cam::Camera, key::FloatingPointFeature)
    ref = Ref{Cdouble}()
    code = ccall((:AT_GetFloatMax, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Ptr{Cdouble}),
                 cam.handle, key.name, ref)
    code == AT_SUCCESS || throw(AndorError(:AT_GetFloatMax, code))
    return ref[]
end


# Boolean features:

function Base.getindex(cam::Camera, key::BooleanFeature)
    ref = Ref{Cint}()
    code = ccall((:AT_GetBool, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Ptr{Cint}),
                 cam.handle, key.name, ref)
    code == AT_SUCCESS || throw(AndorError(:AT_GetBool, code))
    return (ref[] == AT_TRUE)
end

function Base.setindex!(cam::Camera, val::Bool, key::BooleanFeature)
    code = ccall((:AT_SetBool, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Cint),
                 cam.handle, key.name, (val ? AT_TRUE : AT_FALSE))
    code == AT_SUCCESS || throw(AndorError(:AT_SetBool, code))
    return nothing
end


# String features:

function Base.getindex(cam::Camera, key::StringFeature)
    ref = Ref{Cint}()
    code = ccall((:AT_GetStringMaxLength, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Ptr{Cint}),
                 cam.handle, key.name, ref)
    code == AT_SUCCESS || throw(AndorError(:AT_GetStringMaxLength, code))
    num = Int(ref[])
    if num < 1
        error("invalid string length for feature \"$(repr(key.name))\"")
    end
    buf = Array{WideChar}(num)
    code = ccall((:AT_GetString, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Ptr{WideChar}, Cint),
                 cam.handle, key.name, buf, num)
    code == AT_SUCCESS || throw(AndorError(:AT_GetString, code))
    # FIXME: not needed buf[end] = zero(WideChar)
    return widestringtostring(buf)
end

Base.setindex!(cam::Camera, val::AbstractString, key::StringFeature) =
    setindex!(cam, widestring(val), key)

function Base.setindex!(cam::Camera, val::Vector{WideChar},
                        key::StringFeature)
    if length(val) < 1 || val[end] != zero(WideChar)
        error("invalid wide string value")
    end
    code = ccall((:AT_SetString, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Ptr{WideChar}),
                 cam.handle, key.name, val)
    code == AT_SUCCESS || throw(AndorError(:AT_SetString, code))
    return nothing
end


# Enumerated features:

function Base.getindex(cam::Camera, key::EnumeratedFeature)
    ref = Ref{Cint}()
    code = ccall((:AT_GetEnumIndex, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Ptr{Cint}),
                 cam.handle, key.name, ref)
    code == AT_SUCCESS || throw(AndorError(:AT_GetEnumIndex, code))
    return Int(ref[]) + 1
end

Base.minimum(cam::Camera, key::EnumeratedFeature) = 1

function Base.maximum(cam::Camera, key::EnumeratedFeature)
    ref = Ref{Cint}()
    code = ccall((:AT_GetEnumCount, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Ptr{Cint}),
                 cam.handle, key.name, ref)
    code == AT_SUCCESS || throw(AndorError(:AT_GetEnumCount, code))
    return Int(ref[])
end

function isavailable(cam::Camera, key::EnumeratedFeature, index::Integer)
    ref = Ref{Cint}()
    code = ccall((:AT_IsEnumIndexAvailable, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Cint, Ptr{Cint}),
                 cam.handle, key.name, index - 1, ref)
    code == AT_SUCCESS || throw(AndorError(:AT_IsEnumIndexAvailable, code))
    return (ref[] == AT_TRUE)
end

function isimplemented(cam::Camera, key::EnumeratedFeature, index::Integer)
    ref = Ref{Cint}()
    code = ccall((:AT_IsEnumIndexImplemented, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Cint, Ptr{Cint}),
                 cam.handle, key.name, index - 1, ref)
    code == AT_SUCCESS || throw(AndorError(:AT_IsEnumIndexImplemented, code))
    return (ref[] == AT_TRUE)
end

Base.repr(cam::Camera, key::EnumeratedFeature) =
    repr(cam, key, cam[key])

function Base.repr(cam::Camera, key::EnumeratedFeature, index::Integer)
    num = 64
    buf = Array{WideChar}(num)
    code = ccall((:AT_GetEnumStringByIndex, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Cint, Ptr{WideChar}, Cint),
                 cam.handle, key.name, index - 1, buf, num)
    code == AT_SUCCESS || throw(AndorError(:AT_GetEnumStringByIndex, code))
    buf[num] = zero(WideChar)
    return widestringtostring(buf)
end

Base.setindex!(cam::Camera, val::AbstractString, key::EnumeratedFeature) =
    setindex!(cam, widestring(val), key)

function Base.setindex!(cam::Camera, val::Vector{WideChar},
                        key::EnumeratedFeature)
    if length(val) < 1 || val[end] != zero(WideChar)
        error("invalid wide string value")
    end
    code = ccall((:AT_SetEnumString, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Ptr{WideChar}),
                 cam.handle, key.name, val)
    code == AT_SUCCESS || throw(AndorError(:AT_SetEnumString, code))
    return nothing
end

function Base.setindex!(cam::Camera, val::Integer, key::EnumeratedFeature)
    code = ccall((:AT_SetEnumIndex, _DLL), Cint,
                 (Handle, Ptr{WideChar}, Cint),
                 cam.handle, key.name, val + 1)
    code == AT_SUCCESS || throw(AndorError(:AT_SetEnumIndex, code))
    return nothing
end


# Extend basic methods:

Base.print(io::IO, key::AbstractFeature) =
    print(io, widestringtostring(key.name))

Base.repr(key::AbstractFeature) = widestringtostring(key.name)

Base.show(io::IO, key::T) where {T <: AbstractFeature} =
    print(io, T, "(", widestringtostring(key.name), ")")


# Extract images from buffers.

"""
    extract!(dst, buf, bytesperline) -> dst

stores in `dst` the contents of `buf` reinterpreted as values of same type
as the elements of `dst`.  Argument `bytesperline` is the number of bytes
per line stored in `buf`.  The destination `dst` is returned.

See also: [`extractpacked12!`](@ref)

"""
function extract!(dst::Array{T,2},
                  buf::Vector{UInt8},
                  bytesperline::Int) where {T}
    width, height = size(dst)
    stride, extra = divrem(bytesperline, sizeof(T))
    if extra != 0
        error("number of bytes per line must be a multiple of $(sizeof(T))")
    end
    if bytesperline < width*sizeof(T)
        error("number of bytes per line is too small")
    end
    if sizeof(buf) < bytesperline*height
        error("buffer is too small")
    end
    src = reinterpret(T, buf)
    @inbounds for y in 1:height
        offset = (y - 1)*stride
        @simd for x in 1:width
            dst[x,y] = src[offset + x]
        end
    end
    return dst
end

@inline function extractlowpacked(::Type{T},
                                  b0::UInt8, b1::UInt8) where {T <: Unsigned}
    ((convert(T, b0) << 4) | convert(T, b1 & 0x0F))
end
@inline function extracthighpacked(::Type{T},
                                   b1::UInt8, b2::UInt8) where {T <: Unsigned}
    ((convert(T, b2) << 4) | convert(T, b1 >> 4))
end

"""
    extractmono12packed!(dst, buf, bytesperline) -> dst

stores in `dst` the contents of `buf` interpreted as packed 12-bit unsigned
integers.  Argument `bytesperline` is the number of bytes per line stored
in `buf`.  The destination `dst` is returned.

See also: [`extract!`](@ref)

"""
function extractmono12packed!(dst::Array{T,2},
                              buf::Vector{UInt8},
                              bytesperline::Int) where {T <: Unsigned}
    width, height = size(dst)
    if bytesperline < 3*(width >> 1) + 2*(width & 1)
        error("number of bytes per line is too small")
    end
    if sizeof(buf) < bytesperline*height
        error("buffer is too small")
    end
    range = 1:2:(width & ~1)
    @inbounds for y in 1:height
        i = 1 + (y - 1)*bytesperline
        @simd for x in range
            b0, b1, b2 = buf[i], buf[i+1], buf[i+2]
            dst[x,y] = extractlowpacked(T, b0, b1)
            dst[x+1,y] = extracthighpacked(T, b1, b2)
            i += 3
        end
        if isodd(width)
            b0, b1 = buf[i], buf[i+1]
            dst[width,y] = extractlowpacked(T, b0, b1)
        end
    end
    return dst
end
