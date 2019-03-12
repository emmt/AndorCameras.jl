#
# base.jl --
#
# Basic methods for Andor cameras.
#
#-------------------------------------------------------------------------------
#
# This file is part of "AndorCameras.jl" released under the MIT license.
#
# Copyright (C) 2017-2019, Éric Thiébaut.
#

getnumberofdevices() = Int(_devicecount[])

const _devicecount = Ref{AT_INT}()

function __init__()
    code = ccall((:AT_InitialiseLibrary, _DLL), AT_STATUS, ())
    _checkstatus(:AT_InitialiseLibrary, code)
    code = ccall((:AT_GetInt, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, Ref{AT_INT}),
                 AT_HANDLE_SYSTEM, L"DeviceCount", _devicecount)
    if code != AT_SUCCESS
        ccall((:AT_FinaliseLibrary, _DLL), AT_STATUS, ())
        throw(AndorError(:AT_GetInt, code))
    end
end

"""
```julia
checkstate(cam, state, throwerrors=false)
```

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
        elseif state == 1 && cam.state == 2
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
            @warn msg
        end
        return false
    end
end

_checkstatus(func::Union{Symbol,AbstractString}, code::Integer) =
    code == AT_SUCCESS || throw(AndorError(func, code))

function _close(cam::Camera, throwerrors::Bool = false)
    if cam.state > 1
        # Stop acquisition, then flush buffers.
        _stop(cam, throwerrors)
        _flush(cam, throwerrors)
        cam.state = 1
    end
    if cam.state > 0
        # Close handle.  Manage to avoid re-closing.
        code = ccall((:AT_Close, _DLL), AT_STATUS, (AT_HANDLE,), cam)
        cam.handle = AT_HANDLE_UNINITIALISED
        cam.state = 0
        throwerrors && code != AT_SUCCESS && throw(AndorError(:AT_Close, code))
    end
    cam.model = _UNKNOWN_MODEL
    nothing
end

function _command(cam::Camera, cmd::CommandFeature, throwerrors::Bool = false)
    code = ccall((:AT_Command, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE),
                 cam, cmd.name)
    if code != AT_SUCCESS
        throwerrors && throw(AndorError(:AT_Command, code))
        @warn "Call to AT_Command(handle, L\"$cmd\") failed with code $code"
    end
    nothing
end

_stop(cam::Camera, throwerrors::Bool = false) =
    issimcam(cam) || _command(cam, AcquisitionStop, throwerrors)

"""

```julia
AndorCameras.issimcam(cam) -> boolean
```

returns whether Andor camera `cam` is a simulated one, i.e. named "SimCam" in
the documentation of Andor SDK.

"""
issimcam(cam::Camera) = (cam.model == _SIM_CAM_MODEL)

"""

```julia
_queuebuffer(cam, buf, throwerrors=false) -> code
```

or

```julia
_queuebuffer(cam, ptr, siz, throwerrors=false) -> code
```

configure the area of memory into which acquired images will be stored for
Andor camera `cam`.  The buffer to queue can be specified as a vector `buf` of
bytes (`AT_BYTE`) or as a pointer `ptr` and a number of bytes `siz`.  If
`throwerrors` is true, an `AndorError` exception is automatically thrown in
case of error; otherwise, any other returned value than `AT_SUCCESS` indicates
an error.

This method may be called multiple times to set up storage for consecutive
images in a series.  The order in which buffers are queued is the order in
which they will be used on a first in, first out (FIFO) basis.  The size of
each queued buffer should be equal to the size of an individual image in number
of bytes (as given by the value of attribute `ImageSizeBytes`).  This method
may be called before the acquisition starts, after the acquisition starts or a
combination of the two.  Any queued buffers queued should not be modified or
deallocated until they are either returned from the `AT_WaitBuffer` function,
or the `_flush` method is called.

"""
function _queuebuffer(cam::Camera,
                      buf::DenseArray{AT_BYTE},
                      throwerrors::Bool = false)
    return _queuebuffer(cam, pointer(buf), sizeof(buf), throwerrors)
end

function _queuebuffer(cam::Camera,
                      buf::Ptr{AT_BYTE},
                      siz::Integer,
                      throwerrors::Bool = false)
    code = ccall((:AT_QueueBuffer, _DLL), AT_STATUS,
                 (AT_HANDLE, Ptr{AT_BYTE}, AT_LENGTH),
                 cam, buf, siz)
    throwerrors && code != AT_SUCCESS &&
        throw(AndorError(:AT_QueueBuffer, code))
    return code
end

"""

```julia
_flush(cam, throwerrors=false) -> code
```

flushes out any remaining buffers that have been queued using the
`_queuebuffer` function.  If this function is not called after an acquisition
is complete then the remaining buffers will be used the next time an
acquisition is started.  This function should always be called after the
"AcquisitionStop" command has been sent.

If `throwerrors` is true, an `AndorError` exception is automatically thrown in
case of error; otherwise, any other returned value than `AT_SUCCESS` indicates
an error.

"""
function _flush(cam::Camera, throwerrors::Bool = false)
    code = ccall((:AT_Flush, _DLL), AT_STATUS, (AT_HANDLE,), cam)
    throwerrors && code != AT_SUCCESS && throw(AndorError(:AT_Flush, code))
    return code
end


# Execute a command:

send(cam::Camera, cmd::CommandFeature) =
    _command(cam, cmd, true)


# Methods for any feature type:

function isimplemented(cam::Camera, key::AbstractFeature)
    ref = Ref{AT_BOOL}()
    code = ccall((:AT_IsImplemented, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, Ref{AT_BOOL}),
                 cam, key.name, ref)
    _checkstatus(:AT_IsImplemented, code)
    return (ref[] != AT_FALSE)
end

for (jfun, cfun) in ((:isreadable, "AT_IsReadable"),
                     (:iswritable, "AT_IsWritable"),
                     (:isreadonly, "AT_IsReadOnly"))
    @eval function Base.$jfun(cam::Camera, key::AbstractFeature)
        ref = Ref{AT_BOOL}()
        code = ccall(($cfun, _DLL), AT_STATUS,
                     (AT_HANDLE, AT_FEATURE, Ref{AT_BOOL}),
                     cam, key.name, ref)
        _checkstatus($cfun, code)
        return (ref[] != AT_FALSE)
    end
end

# Integer features:

function Base.getindex(cam::Camera, key::IntegerFeature) :: Int
    ref = Ref{AT_INT}()
    code = ccall((:AT_GetInt, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, Ref{AT_INT}),
                 cam, key.name, ref)
    _checkstatus(:AT_GetInt, code)
    return Int(ref[])
end

function Base.setindex!(cam::Camera, val::Integer, key::IntegerFeature)
    code = ccall((:AT_SetInt, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, AT_INT),
                 cam, key.name, val)
    _checkstatus(:AT_SetInt, code)
    return val
end

function Base.minimum(cam::Camera, key::IntegerFeature) :: Int
    ref = Ref{AT_INT}()
    code = ccall((:AT_GetIntMin, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, Ref{AT_INT}),
                 cam, key.name, ref)
    _checkstatus(:AT_GetIntMin, code)
    return Int(ref[])
end

function Base.maximum(cam::Camera, key::IntegerFeature) :: Int
    ref = Ref{AT_INT}()
    code = ccall((:AT_GetIntMax, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, Ref{AT_INT}),
                 cam, key.name, ref)
    _checkstatus(:AT_GetIntMax, code)
    return Int(ref[])
end


# Floating-point features:

function Base.getindex(cam::Camera, key::FloatingPointFeature) :: Float64
    ref = Ref{AT_FLOAT}()
    code = ccall((:AT_GetFloat, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, Ref{AT_FLOAT}),
                 cam, key.name, ref)
    _checkstatus(:AT_GetFloat, code)
    return Float64(ref[])
end

function Base.setindex!(cam::Camera, val::Real,
                        key::FloatingPointFeature)
    code = ccall((:AT_SetFloat, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, AT_FLOAT),
                 cam, key.name, val)
    _checkstatus(:AT_SetFloat, code)
    return val
end

function Base.minimum(cam::Camera, key::FloatingPointFeature) :: Float64
    ref = Ref{AT_FLOAT}()
    code = ccall((:AT_GetFloatMin, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, Ref{AT_FLOAT}),
                 cam, key.name, ref)
    _checkstatus(:AT_GetFloatMin, code)
    return Float64(ref[])
end

function Base.maximum(cam::Camera, key::FloatingPointFeature) :: Float64
    ref = Ref{AT_FLOAT}()
    code = ccall((:AT_GetFloatMax, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, Ref{AT_FLOAT}),
                 cam, key.name, ref)
    _checkstatus(:AT_GetFloatMax, code)
    return Float64(ref[])
end


# Boolean features:

function Base.getindex(cam::Camera, key::BooleanFeature) :: Bool
    ref = Ref{AT_BOOL}()
    code = ccall((:AT_GetBool, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, Ptr{AT_BOOL}),
                 cam, key.name, ref)
    _checkstatus(:AT_GetBool, code)
    return (ref[] != AT_FALSE)
end

function Base.setindex!(cam::Camera, val::Bool, key::BooleanFeature)
    code = ccall((:AT_SetBool, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, AT_BOOL),
                 cam, key.name, (val ? AT_TRUE : AT_FALSE))
    _checkstatus(:AT_SetBool, code)
    return val
end


# String features:

function Base.getindex(cam::Camera, key::StringFeature) :: String
    ref = Ref{AT_LENGTH}()
    code = ccall((:AT_GetStringMaxLength, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, Ref{AT_LENGTH}),
                 cam, key.name, ref)
    _checkstatus(:AT_GetStringMaxLength, code)
    num = Int(ref[])
    if num < 1
        error("invalid string length for feature \"$(repr(key.name))\"")
    end
    buf = Vector{AT_CHAR}(undef, num)
    code = ccall((:AT_GetString, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, Ptr{AT_CHAR}, AT_LENGTH),
                 cam, key.name, buf, num)
    _checkstatus(:AT_GetString, code)
    buf[num] = zero(AT_CHAR)
    return widestringtostring(buf)
end

function Base.setindex!(cam::Camera, val::AbstractString,
                        key::StringFeature)
    code = ccall((:AT_SetString, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, Ptr{AT_CHAR}),
                 cam, key.name, widestring(val))
    _checkstatus(:AT_SetString, code)
    return val
end


# Enumerated features:

function Base.getindex(cam::Camera, key::EnumeratedFeature) :: Int
    ref = Ref{AT_ENUM}()
    code = ccall((:AT_GetEnumIndex, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, Ref{AT_ENUM}),
                 cam, key.name, ref)
    _checkstatus(:AT_GetEnumIndex, code)
    return Int(ref[]) + 1
end

Base.minimum(cam::Camera, key::EnumeratedFeature) = 1

function Base.maximum(cam::Camera, key::EnumeratedFeature) :: Int
    ref = Ref{AT_LENGTH}()
    code = ccall((:AT_GetEnumCount, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, Ref{AT_LENGTH}),
                 cam, key.name, ref)
    _checkstatus(:AT_GetEnumCount, code)
    return Int(ref[])
end

for (jfun, cfun) in ((:isavailable,   "AT_IsEnumIndexAvailable"),
                     (:isimplemented, "AT_IsEnumIndexImplemented"))
    @eval function $jfun(cam::Camera,
                         key::EnumeratedFeature,
                         index::Integer) :: Bool
    ref = Ref{AT_BOOL}()
    code = ccall(($cfun, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, AT_ENUM, Ref{AT_BOOL}),
                 cam, key.name, index - 1, ref)
        _checkstatus($cfun, code)
        return (ref[] == AT_TRUE)
    end
end

Base.repr(cam::Camera, key::EnumeratedFeature) =
    repr(cam, key, cam[key])

function Base.repr(cam::Camera, key::EnumeratedFeature, index::Integer)
    num = 64
    buf = Vector{AT_CHAR}(undef, num)
    code = ccall((:AT_GetEnumStringByIndex, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, AT_ENUM, Ptr{AT_CHAR}, AT_LENGTH),
                 cam, key.name, index - 1, buf, num)
    _checkstatus(:AT_GetEnumStringByIndex, code)
    buf[num] = zero(AT_CHAR)
    return widestringtostring(buf)
end

function Base.setindex!(cam::Camera, val::AbstractString,
                        key::EnumeratedFeature)
    code = ccall((:AT_SetEnumString, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, Ptr{AT_CHAR}),
                 cam, key.name, widestring(val))
    _checkstatus(:AT_SetEnumString, code)
    return val
end

function Base.setindex!(cam::Camera, val::Integer, key::EnumeratedFeature)
    code = ccall((:AT_SetEnumIndex, _DLL), AT_STATUS,
                 (AT_HANDLE, AT_FEATURE, AT_ENUM),
                 cam, key.name, val - 1)
    _checkstatus(:AT_SetEnumIndex, code)
    return val
end


# Extend basic methods:

Base.print(io::IO, key::AbstractFeature) =
    print(io, widestringtostring(key.name))

Base.repr(key::AbstractFeature) = widestringtostring(key.name)

Base.show(io::IO, key::T) where {T <: AbstractFeature} =
    print(io, T, "(", widestringtostring(key.name), ")")

function Base.show(io::IO, cam::T) where {T <: Camera}
    print(io, T, ":")
    count = typemax(Int)
    function prt(args...)
        local pfx::String
        if count < 3
            count += 1
            pfx = " "
        else
            count = 1
            pfx = "\n    "
        end
        print(io, pfx, args...)
    end
    if isimplemented(cam, CameraFamily)
        prt("family: \"", cam[CameraFamily], "\",")
    end
    if isimplemented(cam, CameraModel)
        prt("model: \"", cam[CameraModel], "\",")
    end
    if isimplemented(cam, CameraName)
        prt("name: \"", cam[CameraName], "\",")
    end
    if isimplemented(cam, CameraPresent)
        prt("present: ", cam[CameraPresent], ",")
    end
    if isimplemented(cam, SensorTemperature)
        prt("temperature: ", @sprintf("%.1f°C,", cam[SensorTemperature]))
    end
    if isimplemented(cam, CycleMode)
        prt("cycle mode: \"", repr(cam, CycleMode), "\",")
    end
    if isimplemented(cam, CameraAcquiring)
        prt("acquiring: ", cam[CameraAcquiring], ",")
    end
    if isimplemented(cam, PixelEncoding)
        prt("pixel encoding: \"", repr(cam, PixelEncoding), "\",")
    end
    if isimplemented(cam, BytesPerPixel)
        prt("bits per pixel: ", round(Int, 8*cam[BytesPerPixel]), ",")
    end
    if isimplemented(cam, SensorWidth) && isimplemented(cam, SensorHeight)
        prt("sensor size: ", cam[SensorWidth], "×", cam[SensorHeight], ",")
    end
    if isimplemented(cam, FrameRate)
        prt("frames per second: ", @sprintf("%g", cam[FrameRate]), ",")
    end
    if isimplemented(cam, ExposureTime)
        prt("exposure time: ", @sprintf("%g", cam[ExposureTime]), " s,")
    end
    roi = getroi(cam)
    prt("macro-pixel: ", roi.xsub, "×", roi.ysub, ",")
    prt("ROI offsets: (", roi.xoff, ",", roi.yoff, "),")
    prt("image size: ", roi.width, "×", roi.height, "\n")
end

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

function extract!(dst::Array{T,2},
                  ptr::Ptr{UInt8}, siz::Integer,
                  bytesperline::Int) where {T}
    return extract!(dst, unsafe_wrap(Array, ptr, siz; own=false),
                    bytesperline)
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

"""
   syserrorinfo(code=Libc.errno())

yields the error message associated with `code`.

"""
syserrorinfo(code::Integer = Libc.errno()) =
    (Int(code), Libc.strerror(code))

"""
   reset_usb(dev)

resets USB device `dev`.

"""
reset_usb
@static if Sys.islinux()
    function reset_usb(dev::AbstractString)
        fd = ccall(:open, Cint, (Cstring, Cint), dev, O_WRONLY)
        if fd == -1
            code, mesg = syserrorinfo()
            error("can't open USB device '$dev' for writing: $mesg (errno=$code)")
        end
        try
            if ccall(:ioctl, Cint, (Cint, Culong, Cint),
                     fd, USBDEVFS_RESET, 0) == -1
                code, mesg = syserrorinfo()
                error("can't reset USB device '$dev': $mesg (errno=$code)")
            end
        finally
            if ccall(:close, Cint, (Cint,), fd) == -1
                code, mesg = syserrorinfo()
                @warn "failed to close USB device '$dev': $mesg (errno=$code)"
            end
        end
        nothing
    end
else
    function reset_usb(dev::AbstractString)
        @warn "don't know how to reset USB device '$dev' for your machine"
        nothing
    end
end

"""
    find_zyla()

yields the name of the USB device to which the Andor Zyla camera is connected.
An empty string is returned if no connected Andor Zyla cameras is found.

"""
find_zyla() = open(_find_zyla_proc, "r") do io; readline(io); end
const _find_zyla_path = joinpath(@__DIR__, "..", "deps", "find-zyla")
const _find_zyla_proc = `$_find_zyla_path`

"""
    reset_zyla(;quiet=false)

resets the USB device to which the Andor Zyla camera is connected.  If keyword
`quiet` is true, no warning is printed if no connected Andor Zyla cameras is
found.

"""
function reset_zyla(;quiet::Bool=false)
    dev = find_zyla()
    if dev != ""
        reset_usb(dev)
    elseif !quiet
        @warn "No Andor Zyla cameras found on USB bus."
    end
end

"""
    read_zyla(cam, T=getcapturebitstype(cam);
              reset=0, maxresets=10, ...)

reads one image from the Ando Zyla camera `cam`.

If 1st bit of keyword `reset` is set, then the USB device to which the Andor
Zyla camera is attached is reset prior to trying to read an image.  If 2nd bit
of of keyword `reset` is set, then the USB device is reset if a timeout
exception occurs while reading the camera and a new attempt to read an image is
performed.  Keyword `maxresets` specifies the maximum number of resets.

"""
function read_zyla(cam::Camera, ::Type{T} = getcapturebitstype(cam);
                   reset::Integer = 0,
                   maxresets::Integer = 10,
                   kwds...) where {T}
    nresets = 0
    if (reset & 1) != 0 && nresets < maxresets
        reset_zyla()
        nresets += 1
    end
    while true
        try
            return read(cam, T; kwds...)
        catch err
            if (reset & 2) != 0 && nresets < maxresets && isa(err, TimeoutError)
                reset_zyla()
                nresets += 1
            else
                rethrow(err)
            end
        end
    end
end
