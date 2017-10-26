#
# public.jl --
#
# Implement public interface of ScientificCameras.
#
#-------------------------------------------------------------------------------
#
# This file is part of "AndorCameras.jl" released under the MIT license.
#
# Copyright (C) 2017, Éric Thiébaut.
#

function open(::Type{T}, dev::Integer) where {T <: Camera}
    href = Ref{Handle}()
    cam = Camera()
    code = ccall((:AT_Open, _DLL), Cint, (Cint, Ptr{Handle}), dev, href)
    code == AT_SUCCESS || throw(AndorError(:AT_Open, code))
    finalizer(cam, _close)
    cam.state = 1
    cam.handle = href[]
    return cam
end

close(cam::Camera) = _close(cam, true)

function stop(cam::Camera)
    if cam.state != 2
        warn("not acquiring")
        return nothing
    end
    _stop(cam, true)
    _flush(cam, true)
    cam.state = 1
    return nothing
end

getfullwidth(cam::Camera) = cam[SensorWidth] :: Int

getfullheight(cam::Camera) = cam[SensorHeight] :: Int

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
    i = search(str, 'x')
    try
        return (parse(Int, str[1:i-1]), parse(Int, str[i+1:end]))
    end
    error("unknown binning ($str)")
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
    checkstate(cam, 1, true)
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
# camera) model so their exact defintion is not critical in practice.
const _ENCODINGS = Dict(
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

# FIXME: As part of the initialisation of the camera, we could create fast
#        tables via the index number of the supproted formats.
function supportedpixelformats(cam::Camera)
    U = Union{}
    for i in 1:maximum(cam, PixelEncoding)
        if isavailable(cam, PixelEncoding, i)
            str = repr(cam, PixelEncoding, i)
            U = Union{U, _ENCODINGS[str]}
        end
    end
    return U
end

function getpixelformat(cam::Camera)
    T = _ENCODINGS[repr(cam, PixelEncoding)]
    return (T, T)
end

function setpixelformat!(cam::Camera, ::Type{T}) where {T <: PixelFormat}
    checkstate(cam, 1, true)
    if T == getpixelformat(cam)[1]
        return T
    elseif T == Monochrome{8}
        try
            cam[PixelEncoding] = "Mono8"
            return T
        end
    elseif T == Monochrome{12}
        try
            cam[PixelEncoding] = "Mono12Packed"
            return T
        end
    elseif T == Monochrome{16}
        try
            cam[PixelEncoding] = "Mono16"
            return T
        end
        try
            cam[PixelEncoding] = "Mono12"
            return T
        end
    elseif T == Monochrome{22}
        try
            cam[PixelEncoding] = "Mono22PackedParallel"
            return T
        end
    elseif T == Monochrome{32}
        try
            cam[PixelEncoding] = "Mono32"
            return T
        end
        try
            cam[PixelEncoding] = "Mono22Parallel"
            return T
        end
    elseif T == RGB{8}
        try
            cam[PixelEncoding] = "RGB8Packed"
            return T
        end
    end
    error("unsupported pixel encoding")
end

setpixelformat!(cam::Camera, ::Type{T}, ::Type{T}) where {T <: PixelFormat} =
    setpixelformat!(cam, T)

function setpixelformat!(cam::Camera,
                         ::Type{C},
                         ::Type{B}) where {C <: PixelFormat, B <: PixelFormat}
    error("captured images must have the same pixel format as the camera")
end


getspeed(cam::Camera) =
    (cam[FrameRate], cam[ExposureTime])

function setspeed!(cam::Camera, fps::Float64, exp::Float64)
    if cam[FrameRate] > fps
        cam[FrameRate] = fps
    end
    if cam[ExposureTime] != exp
        cam[ExposureTime] != exp
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
    T = equivalentbitstype(getpixelformat(cam)[1])
    return (T == Void ? UInt8 : T)
end

# Extend method.
function read(cam::Camera, ::Type{T}, nimgs::Int) where {T}

    # Allocate buffers prepare acquisition.
    _prepareacquisition!(cam, 4, T, nimgs)

    # Set the camera to continuously acquires frames.
    cam[CycleMode] = "Continuous"

    # Timeout (in milliseconds).
    ms = round(Int, 1_500*(1/cam[FrameRate] + cam[ExposureTime]))

    # Start the acquisition.
    send(cam, AcquisitionStart)
    cam.state = 2

    # Acquire all images (using 1 sec. of additional delay for the first
    # one).
    for i in 1:nimgs
        _wait(cam, i, (i == 1 ? ms + 1_000 : ms))
    end

    # Stop the acquisition.
    send(cam, AcquisitionStop)
    cam.state = 1

    return cam.imgs
end

# Extend method.
function start(cam::Camera, ::Type{T}, nbufs::Int) where {T}

    # Allocate buffers prepare acquisition.
    _prepareacquisition!(cam, nbufs, T, 1)

    # Set the camera to continuously acquires frames.
    cam[CycleMode] = "Continuous"

    # Start the acquisition.
    send(cam, AcquisitionStart)
    cam.state = 2

    return bufs
end

# Extend method.
function wait(cam::Camera, sec::Float64 = 0.0)
    ms = (sec ≥ typemax(Float64) ? AT_INFINITE : round(Cuint, sec*1_000))
    _wait(cam, 1, ms)
end

# Extend method.
function release(cam::Camera)
    checkstate(cam, 2, true)
    return nothing
end

function _wait(cam::Camera, index::Int, ms::Integer)
    # Check arguments.
    checkstate(cam, 2, true)

    # Sleep in this thread until data is ready.
    refptr = Ref{Ptr{UInt8}}()
    refsiz = Ref{Cint}()
    code = ccall((:AT_WaitBuffer, _DLL), Cint,
                 (Handle, Ptr{Ptr{UInt8}}, Ptr{Cint}, Cuint),
                 cam.handle, refptr, refsiz, ms)
    if code != AT_SUCCESS
        if code == AT_ERR_TIMEDOUT
            throw(TimeoutError())
        else
            throw(AndorError(:AT_WaitBuffer, code))
        end
    end
    ptr = refptr[]
    framesize = Int(refsiz[])

    # Get the timestamp.
    local ticks::Float64
    if cam.clockfrequency > 0
        tickscnt = unsafe_load(Ptr{UInt64}( ptr + framesize - METADATA_SIZE))
        if ENDIAN_BOM == 0x01020304
            tickscnt = bswap(tickscnt)
        end
        ticks = tickscnt/cam.clockfrequency
    else
        ticks = time()
    end

    # Find buffer index.
    for i in 1:length(cam.bufs)
        if pointer(cam.bufs[i]) == ptr
            # Extract buffer data and requeue buffer.
            img = cam.imgs[index]
            buf = cam.bufs[i]
            if cam.mono12packed
                extractmono12packed!(img, buf, cam.bytesperline)
            else
                extract!(img, buf, cam.bytesperline)
            end
            code = ccall((:AT_QueueBuffer, _DLL), Cint,
                         (Cint, Ptr{UInt8}, Cint),
                         cam.handle, buf, framesize)
            if code != AT_SUCCESS
                # Stop acquisition and report error.
                _stop(cam, false)
                _flush(cam, false)
                cam.state = 1
                throw(AndorError(:AT_QueueBuffer, code))
            end
            return img, ticks
        end
    end
    error("bad buffer address")
end

function _prepareacquisition!(cam::Camera,
                              nbufs::Int,
                              ::Type{T},
                              nimgs::Int) where {T}
    # Check arguments.
    checkstate(cam, 1, true)
    if nbufs < 1
        error("bad number of frame buffers")
    end
    if nimgs < 1
        error("bad number of images")
    end

    # Make sure no buffers are currently in use.
    _flush(cam, true)

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
        cam.bufs = Array{Vector{UInt8}}(nbufs)
    end
    for i in 1:nbufs
        if ! isassigned(cam.bufs, i) || sizeof(cam.bufs[i]) != framesize
            cam.bufs[i] = Vector{UInt8}(framesize)
        end
        code = ccall((:AT_QueueBuffer, _DLL), Cint, (Cint, Ptr{UInt8}, Cint),
                     cam.handle, cam.bufs[i], framesize)
        if code != AT_SUCCESS
            _flush(cam, false)
            throw(AndorError(:AT_QueueBuffer, code))
        end
    end

    # Create images.
    width = (isimplemented(cam, AOIWidth) ? cam[AOIWidth]
             : cam[SensorWidth])
    height = (isimplemented(cam, AOIHeight) ? cam[AOIHeight]
              : cam[SensorHeight])
    stride = div(framesize - (cam.clockfrequency > 0 ? METADATA_SIZE : 0),
                 height)
    cam.imgs = [Array{T,2}(width, height) for i in 1:nimgs]
    cam.ticks = zeros(UInt64, nimgs)
    cam.bytesperline = stride
    cam.mono12packed = (repr(cam, PixelEncoding) == "Mono12Packed") # FIXME:
    if isimplemented(cam, AOIStride)
        cam.bytesperline = cam[AOIStride]
        if cam.bytesperline != stride
            warn("computed stride ($(stride) bytes) is not equal to ",
                 "AOIStride ($(cam.bytesperline) bytes)")
        end
    else
        cam.bytesperline = stride
    end

    return nothing
end
