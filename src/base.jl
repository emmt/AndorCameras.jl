#
# base.jl --
#
# Basic methods for Andor cameras.
#
#-------------------------------------------------------------------------------
#
# This file is part of "AndorCameras.jl" released under the MIT license.
#
# Copyright (C) 2017-2021, Éric Thiébaut.
#

# A bit of magic for ccall.
Base.cconvert(::Type{AT.Handle}, cam::Camera) = cam.handle
Base.cconvert(::Type{Cwstring}, key::AbstractFeature) =
    WideStrings.buffer(key.name)

getnumberofdevices() = Int(_NDEVS[])

const _NDEVS = Ref{Int}(0)

function __init__()
    check(AT.InitialiseLibrary())
    status, ndevs = AT.GetInt(AT.HANDLE_SYSTEM, L"DeviceCount")
    if isfailure(status)
        AT.FinaliseLibrary()
        error(status)
    end
    _NDEVS[] = ndevs
    nothing
end

"""
    checkstate(cam, state; throwerrors=false)

returns whether camera `cam` is in a specific state: 0 if it must be closed
(or not yet open), 1 if it must be open (but acquisition not running) or 2
if acquisition must be running.  If the state is not the expected one, an
error is thrown if `throwerrors` is true or a warning message printed
otherwise.

"""
function checkstate(cam::Camera, state::Integer; throwerrors::Bool = false)
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


"""
    isfailure(status)

yields whether `status` indicates a failure.  Argument `status` is the result
of a call to a function of the Andor SDK.

"""
isfailure(status::AT.Status) = (status.code != AT.SUCCESS)

"""
    issuccess(status)

yields whether `status` indicates a success.  Argument `status` is the result
of a call to a function of the Andor SDK.

"""
issuccess(status::AT.Status) = (status.code == AT.SUCCESS)

Base.error(status::AT.Status) = throw(AndorError(status.func, status.code))

check(status::AT.Status) = (status.code == AT.SUCCESS || error(status))

check(args::Tuple{AT.Status,Any}) =
    (@inbounds check(args[1]); @inbounds args[2])

check(args::Tuple{AT.Status,Any,Any}) =
    (@inbounds check(args[1]); @inbounds (args[2], args[3]))

check(args::Tuple{AT.Status,Vararg}) =
    (@inbounds check(args[1]); @inbounds args[2:end])

function _close(cam::Camera; throwerrors::Bool=false)
    if cam.state > 1
        # Stop acquisition, then flush buffers.
        status = _stop(cam)
        throwerrors && isfailure(status) && error(status)
        status = AT.Flush(cam)
        throwerrors && isfailure(status) && error(status)
        cam.state = 1
    end
    if cam.state > 0
        # Close handle.  Manage to avoid re-closing.
        status = AT.Close(cam)
        cam.handle = AT.HANDLE_UNINITIALISED
        cam.state = 0
        cam.model = _UNKNOWN_MODEL
        throwerrors && isfailure(status) && error(status)
    end
    nothing
end

# Execute AcquisitionStop command for camera that support it.
_stop(cam::Camera) :: AT.Status =
    (issimcam(cam) ? AT.Status(:AT_Command, AT.SUCCESS) :
     AT.Command(cam, AcquisitionStop))

"""
    AndorCameras.issimcam(cam) -> boolean

returns whether Andor camera `cam` is a simulated one, i.e. named "SimCam" in
the documentation of Andor SDK.

"""
issimcam(cam::Camera) = (cam.model == _SIM_CAM_MODEL)


# Methods for any feature type:

isimplemented(cam::Camera, key::AbstractFeature) =
    check(AT.IsImplemented(cam, key))

isreadable(cam::Camera, key::AbstractFeature) =
    check(AT.IsReadable(cam, key))

iswritable(cam::Camera, key::AbstractFeature) =
    check(AT.IsWritable(cam, key))

isreadonly(cam::Camera, key::AbstractFeature) =
    check(AT.IsReadOnly(cam, key))


# Integer features:

Base.setindex!(cam::Camera, val::Integer, key::IntegerFeature) =
    (check(AT.SetInt(cam, key, val)); return cam)

Base.getindex(cam::Camera, key::IntegerFeature) =
    Int(check(AT.GetInt(cam, key)))

Base.minimum(cam::Camera, key::IntegerFeature) =
    Int(check(AT.GetIntMin(cam, key)))

Base.maximum(cam::Camera, key::IntegerFeature) =
    Int(check(AT.GetIntMax(cam, key)))


# Floating-point features:

Base.getindex(cam::Camera, key::FloatingPointFeature) =
    Float64(check(AT.GetFloat(cam, key)))

Base.setindex!(cam::Camera, val::Real, key::FloatingPointFeature) =
    (check(AT.SetFloat(cam, key, val)); return cam)

Base.minimum(cam::Camera, key::FloatingPointFeature) =
    Float64(check(AT.GetFloatMin(cam, key, val)))

Base.maximum(cam::Camera, key::FloatingPointFeature) =
    Float64(check(AT.GetFloatMax(cam, key, val)))


# Boolean features:

Base.setindex!(cam::Camera, val::Bool, key::BooleanFeature) =
    (check(AT.SetBool(cam, key, val)); return cam)

Base.getindex(cam::Camera, key::BooleanFeature) =
    check(AT.GetBool(cam, key))


# String features:

function Base.getindex(cam::Camera, key::StringFeature) :: String
    len = check(AT.GetStringMaxLength(cam, key))
    len ≥ 1 || error("invalid string length for feature \"$(repr(key.name))\"")
    buf = Vector{Cwchar_t}(undef, len)
    check(AT.GetString(cam, key, buf))
    buf[len] = zero(eltype(buf))
    return String(trunc!(WideString, buf))
end

Base.setindex!(cam::Camera, val::AbstractString, key::StringFeature) =
    setindex!(cam, WideString(val), key)

Base.setindex!(cam::Camera, val::WideString, key::StringFeature) = begin
    check(AT.SetString(cam, key, val))
    return cam
end


# Enumerated features:

Base.getindex(cam::Camera, key::EnumeratedFeature) =
    check(AT.GetEnumIndex(cam, key)) + 1

Base.minimum(cam::Camera, key::EnumeratedFeature) = 1

Base.maximum(cam::Camera, key::EnumeratedFeature) =
    check(AT.GetEnumCount(cam, key))

isavailable(cam::Camera, key::EnumeratedFeature, index::Integer) =
    check(AT.IsEnumIndexAvailable(cam, key, index - 1))

isimplemented(cam::Camera, key::EnumeratedFeature, index::Integer) =
    check(AT.IsEnumIndexImplemented(cam, key, index - 1))

Base.repr(cam::Camera, key::EnumeratedFeature) =
    repr(cam, key, cam[key])

function Base.repr(cam::Camera, key::EnumeratedFeature, index::Integer)
    buf = Vector{Cwchar_t}(undef, 64)
    check(AT.GetEnumStringByIndex(cam, key, index - 1, buf))
    buf[end] = zero(eltype(buf))
    return trunc!(WideString, buf)
end

Base.setindex!(cam::Camera, val::AbstractString, key::EnumeratedFeature) =
    (check(AT.SetEnumString(cam, key, WideString(val))); return cam)

Base.setindex!(cam::Camera, val::Integer, key::EnumeratedFeature) =
    (check(AT.SetEnumIndex(cam, key, val - 1)); return cam)


# Extend basic methods:

Base.String(key::AbstractFeature) = String(key.name)
Base.string(key::AbstractFeature) = string(key.name)

Base.print(io::IO, m::MIME, key::AbstractFeature) =
    print(io, m, key.name)

Base.print(io::IO, key::AbstractFeature) =
    print(io, key.name)

Base.show(io::IO, key::T) where {T <: AbstractFeature} =
    print(io, T, "(", String(key.name), ")")

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
        fd = ccall(:open, Cint, (Cstring, Cint), dev, AT.O_WRONLY)
        if fd == -1
            code, mesg = syserrorinfo()
            error("can't open USB device '$dev' for writing: $mesg (errno=$code)")
        end
        try
            if ccall(:ioctl, Cint, (Cint, Culong, Cint),
                     fd, AT.USBDEVFS_RESET, 0) == -1
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
