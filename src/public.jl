#
# public.jl --
#
# Implement public interface of ScientificCameras.
#
#-------------------------------------------------------------------------------
#
# This file is part of "AndorCameras.jl" released under the MIT license.
#
# Copyright (C) 2017-2021, Éric Thiébaut.
#

function open(::Type{Camera}, dev::Integer)
    handle = check(AT.Open(dev))
    cam = Camera()
    cam.state = 1
    cam.model = _UNKNOWN_MODEL
    cam.handle = handle
    if isimplemented(cam, CameraModel)
        model = cam[CameraModel]
        if model == "SIMCAM CMOS"
            cam.model = _SIM_CAM_MODEL
        elseif model == "ZYLA-4.2P-USB3"
            cam.model = _ZYLA_USB_MODEL
        end
    end
    return finalizer(_close, cam)
end

close(cam::Camera) = _close(cam; throwerrors=true)

function stop(cam::Camera)
    if cam.state != 2
        @warn "not acquiring"
        return nothing
    end
    check(_stop(cam))
    check(AT.Flush(cam))
    cam.state = 1
    return nothing
end

abort(cam::Camera) = stop(cam)

getfullwidth(cam::Camera) = Int(cam[SensorWidth])

getfullheight(cam::Camera) = Int(cam[SensorHeight])

#getroistride(cam::Camera) =
#    (isimplemented(cam, AOIStride) ? cam[AOIStride] :
#     div(getroiwidth(cam)*getbitsperpixel(cam) + 7, 8)) :: Int

getbitsperpixel(cam::Camera) = round(Int, 8*cam[BytesPerPixel])

function getbinning(cam::Camera) :: Tuple{Int,Int}
    if isimplemented(cam, AOIHBin) && isimplemented(cam, AOIVBin)
        return (cam[AOIHBin], cam[AOIVBin])
    elseif isimplemented(cam, AOIBinning)
        return parsebinning(repr(cam, AOIBinning))
    else
        return (1, 1)
    end
end

function parsebinning(str::AbstractString) :: Tuple{Int,Int}
    @noinline failure(str::AbstractString) =
        error("unknown binning ($str)")
    i = something(findfirst(isequal('x'), str), -1)
    if i > 0
        try
            return (parse(Int, str[1:i-1]), parse(Int, str[i+1:end]))
        catch
            nothing
        end
    end
    failure(str)
end

function getroi(cam::Camera)
    xsub, ysub = getbinning(cam)
    width = (isimplemented(cam, AOIWidth) ? cam[AOIWidth]
             : div(cam[SensorWidth], xsub))
    height = (isimplemented(cam, AOIHeight) ? cam[AOIHeight]
             : div(cam[SensorHeight], ysub))
    xoff = (isimplemented(cam, AOILeft) ? cam[AOILeft] - 1 : 0)
    yoff = (isimplemented(cam, AOITop)  ? cam[AOITop]  - 1 : 0)
    return ROI(xsub, ysub, xoff, yoff, width, height)
end

function setroi!(cam::Camera, roi::ROI)
    # Check parameters.
    checkstate(cam, 1, throwerrors=true)
    fullwidth = getfullwidth(cam)
    fullheight = getfullheight(cam)
    checkroi(roi, fullwidth, fullheight)

    # The ROI features must be configured in the order listed below as
    # features towards the top of the list will override the values below
    # them if the values are incompatible.
    #
    #  - `AOIHBin`, `AOIVBin` or `AOIBinning`
    #  - `AOIWidth` is in macro-pixel units
    #  - `AOILeft` is in pixel units
    #  - `AOIHeight` is in macro-pixel units
    #  - `VerticallyCenterAOI`
    #  - `AOITop` is in pixel units
    #
    if isimplemented(cam, AOIHBin) && isimplemented(cam, AOIVBin)
        if cam[AOIHBin] != roi.xsub
            cam[AOIHBin] = roi.xsub
        end
        if cam[AOIVBin] != roi.ysub
            cam[AOIVBin] = roi.ysub
        end
    elseif isimplemented(cam, AOIBinning)
        (xsub, ysub) = parsebinning(repr(cam, AOIBinning))
        if roi.xsub != xsub || roi.ysub != ysub
            str = @sprintf("%dx%d", roi.xsub, roi.ysub)
            cam[AOIBinning] = str
        end
    elseif roi.xsub != 1 || roi.ysub != 1
        error("pixel binning is not supported")
    end
    if isimplemented(cam, AOIWidth)
        if cam[AOIWidth] != roi.width
            cam[AOIWidth] = roi.width
        end
    elseif roi.xoff + roi.width*roi.xsub != fullwidth
        error("setting horizontal size of ROI is not supported")
    end
    if isimplemented(cam, AOILeft)
        left = roi.xoff + 1
        if cam[AOILeft] != left
            cam[AOILeft] = left
        end
    elseif roi.xoff != 0
        error("setting horizontal offset of ROI is not supported")
    end

    if isimplemented(cam, AOIHeight)
        if cam[AOIHeight] != roi.height
            cam[AOIHeight] = roi.height
        end
    elseif roi.yoff + roi.height*roi.ysub != fullheight
        error("setting vertical size of ROI is not supported")
    end
    if isimplemented(cam, VerticallyCenterAOI)
        cam[VerticallyCenterAOI] = false
    end
    if isimplemented(cam, AOITop)
        top = roi.yoff + 1
        if cam[AOITop] != top
            cam[AOITop] = top
        end
    elseif roi.yoff != 0
        error("setting vertical offset of ROI is not supported")
    end
    return nothing
end

# "Packed" encodings mean that the pixel values are packed on consecutive
# bytes.  Some exotic encodings only exists for the "SimCam" (simulated
# camera) model so their exact definition is not critical in practice.
const _PIXEL_ENCODING_TYPES = Dict{String,DataType}(
    "Mono8" => Monochrome{8},  # SimCam only
    "Mono12" => Monochrome{16}, # 16 bits but only 12 are significant
    "Mono16" => Monochrome{16},
    "Mono32" => Monochrome{32},
    "Mono12Packed" => Monochrome{12},
    "RGB8Packed" => RGB{8}, # SimCam only
    "Mono12Coded" => Monochrome{16}, # probably inexact but SimCam only
    "Mono12CodedPacked" => Monochrome{12}, # probably inexact but SimCam only
    "Mono22Parallel"  => Monochrome{32}, # probably inexact but SimCam only
    "Mono22PackedParallel" => Monochrome{22}) # probably inexact but SimCam only

const _PIXEL_ENCODING_NAMES = Dict{DataType,String}()
for (key, val) in _PIXEL_ENCODING_TYPES
    _PIXEL_ENCODING_NAMES[val] = key
end

# FIXME: As part of the initialisation of the camera, we could create fast
#        tables via the index number of the supproted formats.
function supportedpixelformats(cam::Camera)
    U = Union{}
    for i in 1:maximum(cam, PixelEncoding)
        if isimplemented(cam, PixelEncoding, i)
            str = repr(cam, PixelEncoding, i)
            U = Union{U, _PIXEL_ENCODING_TYPES[str]}
        end
    end
    return U
end

getpixelformat(cam::Camera) =
    get(_PIXEL_ENCODING_TYPES, repr(cam, PixelEncoding), Nothing)

function setpixelformat!(cam::Camera, ::Type{T}) where {T<:PixelFormat}
    checkstate(cam, 1, throwerrors=true)
    if T == getpixelformat(cam)
        return T
    elseif haskey(_PIXEL_ENCODING_NAMES, T)
        cam[PixelEncoding] = _PIXEL_ENCODING_NAMES[T]
        return T
    end
    error("unsupported pixel encoding")
end

getspeed(cam::Camera) =
    (cam[FrameRate], cam[ExposureTime])

function setspeed!(cam::Camera, fps::Float64, exp::Float64)
    # First reduce frame rate (if fps is smaller than actual value), then set
    # exposure time, then augment frame rate (if fps is larger than actual
    # value).  This strategy is to avoid havin incompatible settings at any
    # time.
    if cam[FrameRate] > fps
        cam[FrameRate] = fps
    end
    if cam[ExposureTime] != exp
        cam[ExposureTime] = exp
    end
    if cam[FrameRate] < fps
        cam[FrameRate] = fps
    end
    return nothing
end

getgain(cam::Camera) = 1.0

setgain!(cam::Camera, gain::Float64) =
    gain == 1.0 || error("invalid gain factor")

getbias(cam::Camera) = 0.0

setbias!(cam::Camera, bias::Float64) =
    bias == 0.0 || error("invalid bias level")

getgamma(cam::Camera) = 1.0

setgamma!(cam::Camera, gamma::Float64) =
    gamma == 1.0 || error("invalid gamma factor")

# Size of metadata fields.
const LENGTH_FIELD_SIZE = 4
const CID_FIELD_SIZE = 4
const TIMESTAMP_FIELD_SIZE = 8

# Size of metadata with a timestamp.
const METADATA_SIZE = (LENGTH_FIELD_SIZE + CID_FIELD_SIZE
                       + TIMESTAMP_FIELD_SIZE)

# Extend method.
function getcapturebitstype(cam::Camera)
    T = equivalentbitstype(getpixelformat(cam))
    return (T == Nothing ? UInt8 : T)
end

# Check timeout and convert it in milliseconds.
function timeout2ms(sec::Real)
    sec > 0 || throw(ArgumentError("invalid timeout"))
    msec = sec*1_000
    return (msec > typemax(AT.INFINITE) ? AT.INFINITE :
            round(typeof(AT.INFINITE), msec))
end

@noinline _warntimeout(cnt::Integer) =
    @warn "Acquisition timeout after $cnt image(s)"

# Extend method.
function read(cam::Camera, ::Type{T}, num::Int;
              nbufs::Integer = 4,
              skip::Integer = 0,
              timeout::Real = defaulttimeout(cam),
              truncate::Bool = false,
              ignoretimeouts::Bool = false,
              quiet::Bool = false) where {T}

    # Check timeout and convert it in milliseconds.
    ms = timeout2ms(timeout)

    # Allocate vector of images.
    imgs = Vector{Array{T,2}}(undef, num)

    # Start the acquisition.
    start(cam, T, nbufs)

    # Acquire all images.
    cnt = 0
    while cnt < num
        try
            _wait(cam, ms, skip > 0, quiet)
            if skip > zero(skip)
                skip -= one(skip)
            else
                cnt += 1
                imgs[cnt] = copy(cam.lastimg)
            end
        catch err
            solved = false
            if isa(err, TimeoutError)
                if ignoretimeouts
                    # Pretend the problem has been solved.
                    solved = true
                elseif truncate
                    # Truncate the image sequence.
                    num = cnt
                    resize!(imgs, num)
                    solved = true
                end
                if solved
                    # The error has been solved, print a warning unless quiet
                    # is true.
                    quiet || _warntimeout(cnt)
                end
            end
            if !solved
                # The error has not been solved, abort the acquisition and
                # rethrow the exception.
                abort(cam)
                rethrow(err)
            end
        end
    end

    # Stop the acquisition and return the sequence of images.
    abort(cam)
    return imgs
end

function read(cam::Camera, ::Type{T};
              skip::Integer = 0,
              nbufs::Integer = 1,
              timeout::Real = defaulttimeout(cam),
              ignoretimeouts::Bool = false,
              quiet::Bool = false) where {T}

    # Check timeout and convert it in milliseconds.
    ms = timeout2ms(timeout)

    # Start the acquisition.
    start(cam, T, nbufs)

    # Acquire a single image.
    cnt = 0
    while cnt < 1
        try
            _wait(cam, ms, skip > 0, quiet)
            if skip > zero(skip)
                skip -= one(skip)
            else
                cnt += 1
            end
        catch err
            if isa(err, TimeoutError) && ignoretimeouts
                # Print a warning unless quiet is true.
                quiet || _warntimeout(cnt)
            else
                # Abort the acquisition and rethrow the exception.
                abort(cam)
                rethrow(err)
            end
        end
    end

    # Stop the acquisition and return the image.
    abort(cam)
    return cam.lastimg
end

# Extend method.
function start(cam::Camera, ::Type{T}, nbufs::Int) where {T}

    # Check arguments.
    checkstate(cam, 1, throwerrors=true)
    nbufs ≥ 1 || throw(ArgumentError("invalid number of acquisition buffers"))

    # Make sure no buffers are currently in use.
    check(AT.Flush(cam))

    # Turn on metadata (this must be done before getting the frame size).
    if (isimplemented(cam, MetadataEnable) &&
        isimplemented(cam, MetadataTimestamp) &&
        isimplemented(cam, TimestampClockFrequency))
        cam[MetadataEnable] = true
        cam[MetadataTimestamp] = true
        cam.clockfrequency = cam[TimestampClockFrequency]
    else
        cam.clockfrequency = 0
    end

    # Get size of buffers.
    framesize = cam[ImageSizeBytes]

    # Create queue of frame buffers.
    if length(cam.bufs) != nbufs
        resize!(cam.bufs, nbufs)
    end
    for i in 1:nbufs
        if ! isassigned(cam.bufs, i) || sizeof(cam.bufs[i]) != framesize
            cam.bufs[i] = Vector{UInt8}(undef, framesize)
        end
        status = AT.QueueBuffer(cam, cam.bufs[i])
        if isfailure(status)
            AT.Flush(cam)
            error(status)
        end
    end

    # Allocate array to store last image.
    width = (isimplemented(cam, AOIWidth) ? cam[AOIWidth]
             : cam[SensorWidth])
    height = (isimplemented(cam, AOIHeight) ? cam[AOIHeight]
              : cam[SensorHeight])
    stride = div(framesize - (cam.clockfrequency > 0 ? METADATA_SIZE : 0),
                 height)
    cam.lastimg = Array{T,2}(undef, width, height)
    cam.mono12packed = (repr(cam, PixelEncoding) == "Mono12Packed") # FIXME:
    if isimplemented(cam, AOIStride)
        cam.bytesperline = cam[AOIStride]
        if cam.bytesperline != stride
            @warn("computed stride ($(stride) bytes) is not equal to "*
                  "AOIStride ($(cam.bytesperline) bytes)")
        end
    else
        cam.bytesperline = stride
    end

    # Set the camera to continuously acquires frames.
    cam[CycleMode] = "Continuous"
    cam[TriggerMode] = "Internal"

    # Start the acquisition.
    check(AT.Command(cam, AcquisitionStart))
    cam.state = 2
    return nothing
end

# Extend method.
function wait(cam::Camera, sec::Float64 = 0.0)
    ticks = _wait(cam, timeout2ms(sec), false)
    return cam.lastimg, ticks
end

# Extend method.
function release(cam::Camera)
    checkstate(cam, 2, throwerrors=true)
    return nothing
end

function _wait(cam::Camera, ms::Integer, skip::Bool=false, quiet::Bool=false)
    # Check arguments.
    checkstate(cam, 2, throwerrors=true)

    # Sleep in this thread until data is ready.  Note that the timeout argument
    # is pretended to be `Cint` because `AT.INFINITE` is `-1` whereas it is
    # `Cuint`.  This limits the maximum allowed timeout to about 24.9 days
    # which should be sufficient!
    status, bufptr, bufsiz = AT.WaitBuffer(cam, ms)
    if isfailure(status)
        if status.code != AT.ERR_TIMEDOUT
            error(status)
        end
        if cam.model == _ZYLA_USB_MODEL
            # Reset USB connection.
            dev = find_zyla()
            if dev == ""
                quiet || @warn "Timeout! USB connection not found..."
            else
                reset_usb(dev)
                AT.Command(cam, AcquisitionStop)  # FIXME:
                AT.Command(cam, AcquisitionStart) # FIXME:
                quiet || @warn "Timeout! USB connection has been reset..."
            end
        end
        throw(TimeoutError())
    end

    # Get the timestamp.
    local ticks::Float64 # to enforce type stability
    if cam.clockfrequency > 0
        tickscnt = unsafe_load(Ptr{UInt64}(bufptr + bufsiz - METADATA_SIZE))
        if ENDIAN_BOM == 0x01020304
            tickscnt = bswap(tickscnt)
        end
        ticks = tickscnt/cam.clockfrequency
    else
        ticks = time()
    end

    # Find buffer index.
    for buf in cam.bufs
        if pointer(buf) == bufptr
            # Extract buffer data and requeue buffer.
            if ! skip
                if cam.mono12packed
                    extractmono12packed!(cam.lastimg, buf, cam.bytesperline)
                else
                    extract!(cam.lastimg, buf, cam.bytesperline)
                end
            end
            status = AT.QueueBuffer(cam, bufptr, bufsiz)
            if isfailure(status)
                # Stop acquisition and report error.
                _stop(cam)
                AT.Flush(cam)
                cam.state = 1
                error(status)
            end
            return ticks
        end
    end
    error("bad buffer address")
end
