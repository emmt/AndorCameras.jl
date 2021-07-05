# A Julia interface to Andor cameras

This [Julia](http://julialang.org/) package implements an
[interface](https://github.com/emmt/ScientificCameras.jl) to some
[Andor cameras](http://www.andor.com/scientific-cameras) via the Andor Software
Development Kit (SDK).  As of version 3.13 of the SDK, the *Neo*, *Zyla*,
*Apogee* and *iStar-SCMOS* Andor cameras should be supported.  The
`AndorCameras` package has been tested on under Linux on the *Zyla* (USB-3
connected) camera, I am interested in feedback about other models.

This document describes:

* the [standard interface](#standard-interface) which implements all the
  methods specified by the
  [`ScientificCameras`](https://github.com/emmt/ScientificCameras.jl)
  interface;

* the [advanced interface](#advanced-interface) which provides access to all
  Andor cameras *features* and commands;

* the [installation](#installation) of the
  [`AndorCameras`](https://github.com/emmt/AndorCameras.jl) package.


## Standard interface

To use the `AndorCameras` package, just write:

```julia
using AndorCameras
```

which provides all the methods specified by the
[`ScientificCameras`](https://github.com/emmt/ScientificCameras.jl) interface.
This interface is fully documented
[here](https://github.com/emmt/ScientificCameras.jl) and summarized below.

You may also want to:

```julia
using AndorCameras.Features
```

to use the [advanced interface](#advanced-usage).


### Open and close a camera

To open an Andor camera:

```julia
cam = open(AndorCameras.Camera, dev)
```

with `dev` the device number (`0` is the first device).  To figure out how many
Andor devices are available:

```julia
AndorCameras.getnumberofdevices()
```

To disconnect a camera from the hardware:

```julia
close(cam)
```

Note that this is automatically done when the camera instance is claimed by the
garbage collector.


### Configure a camera

#### Region of interest

A region of interest (ROI) may be selected by:

```julia
setroi!(cam, [[xsub, ysub,] xoff, yoff,] width, height)
```

where `xsub` and `ysub` are the dimensions of the macro-pixels (in pixels and
both assumed to be `1` if not specified), `xoff` and `yoff` are the offsets of
the ROI relative to the sensor (in pixels and both assumed to be `0` if not
specified), `width` and `height` are the dimensions of the ROI (in
macro-pixels).

*Macro-pixels* are blocks of `xsub` by `ysub` pixels when rebinning the pixels
of the sensor.

In the Andor SDK documentation, the rebinning [features](#features) are
`AOIHBin` and `AOIVBin`, the offsets (plus one) are `AOILeft` and `AOITop` and
the dimensions of the ROI are `AOIWidth` and `AOIHeight`.

To query the current ROI call:

```julia
roi = getroi(cam)
```

and to reset the ROI to use the full sensor with no rebinning, call:

```julia
resetroi!(cam)
```

The full dimensions (in pixels) of the sensor are retrieved by:

```julia
fullwidth = getfullwidth(cam)
fullheight = getfullheight(cam)
```

or by:

```julia
fullwidth, fullheight = getfullsize(cam)
```


#### Frame rate and exposure time

The `setspeed!` method let you choose the frame rate (`fps` in Hz) and the
exposure time (`exp` in seconds) for the captured images:

```julia
setspeed!(cam, fps, exp)
```

To retrieve the actual values of these parameters:

```julia
fps, exp = getspeed(cam)
```


### Acquire a sequence of images

To acquire a single image (with the current settings):

```julia
img = read(cam)
```

which yield an image in the form of a 2D Julia array.  To acquire a sequence of
`n` images:

```julia
imgs = read(cam, n)
```

which yields a vector of images: `imgs[1]`, `imgs[2]`, ..., `imgs[n]`.  The
returned images are Julia 2D arrays of same dimensions as the selected region
of interest (ROI) and whose element type is derived from the pixel format of
the camera as given by:

```julia
getcapturebitstype(cam)
```

You may specify another element type, say `T`, for the acquired images:

```julia
img = read(cam, T)
```

or

```julia
imgs = read(cam, T, n)
```

but there may be restrictions.

The `read` methods have the following keywords:

* Use keyword `skip` to specify a number of images to skip.

* Use keyword `timeout` to specify the maximum amount of time (in seconds) to
  wait for acquisition to complete.  If acquisition takes longer than this
  time, a `ScientificCameras.TimeoutError` is thrown unless keyword `truncate`
  is `true` (see below).  The default timeout is computed from the acquisition
  rate and the total number of images.

* When reading a sequence of images, keyword `truncate` may be set `true` to
  print a warning and return a truncated sequence instead of throwing an
  exception in case of timeout.

* Keyword `quiet` can be set `true` to suppress the printing of warning
  messages (see above).


### Continuous acquisition of images

Continuous acquisition (and processing) of images is typically done by:

```julia
start(cam, nbufs) # start continuous acquisition with `nbufs` cyclic buffers
while ! finished()
    img, ticks = wait(cam, sec) # wait for next image, not longer than `sec` seconds
    ... # process the image
    release(cam) # release the processed image
end
stop(cam)  # stop acquisition
```

where it is assumed that `finished()` returns `true` when to stop and `false`
otherwise.  Above, `img` is a 2D Julia array with the last captured image and
`ticks` is the corresponding timestamp in seconds.  Releasing the captured
image with `release(cam)` when it has been processed is intended to recycle the
image buffer for another acquisition.  When the returned image is independent
from the corresponding capture buffer, `release(cam)` does nothing.  It is
nevertheless good practice to call this method when the captured image is no
longer needed because the code is more likely to work with no changes with
another camera.

You may specify another element type, say `T`, for the captured images:

```julia
start(cam, T, nbufs)
```


## Advanced interface

This section describes advanced use of the interface to Andor cameras provided
by the `AndorCameras` module.  This may be useful to perform specific
configuration or actions not covered by the general interface.  Dealing with
all the [*features*](#features) of Andor cameras is greatly simplified by the
provided Julia interface.


### Constants

The constants defined in `atcore.h` are available in Julia, for instance
`AndorCameras.AT_SUCCESS`.  All constants are prefixed with `AT_` and may be
imported by:

```julia
using AndorCameras.Constants
```

so that you just have to write `AT_SUCCESS` instead of
`AndorCameras.AT_SUCCESS`.


### Features

Andor cameras have *features* whose value can be retrieved or set using the
array index syntax:

```julia
cam[key]
cam[key] = val
```

where `cam` is the camera instance, `key` is the considered feature and `val`
its value.  Here `key` can be something like `AndorCameras.SensorWidth` or
just `SensorWidth` if you have imported all defined features by:

```julia
using AndorCameras.Features
```

For instance:

```julia
using AndorCameras.Features
sensorwidth = cam[SensorWidth]
sensorheight = cam[SensorHeight]
```

yields the full dimensions of the sensor of camera `cam`.

The names of the constants defining the existing features closely follow the
*Andor Software Development Kit* documentation.  This documentation should be
consulted to figure out the supported features and their meaning.  If specific
features are missing, it is easy to [define new ones](#define-new-features).

Julia `AndorCameras` module takes care of the different kind of features
depending on the type of their values: integer, floating-point, string,
boolean or enumerated.  Enumerated features can take integer or string
values, they are described [below](#enumerated-features).  There are also
[*command* features](#commands) which have no value but are used to send
commands to the camera.

To query whether a specific feature is implemented, or whether it is readable,
writable or read-only, do one of:

```julia
isimplemented(cam, key)
isreadable(cam, key)
iswritable(cam, key)
isreadonly(cam, key)
```

Integer and floating-point features may have restrictions on the allowed range
of values.  The minimum and maximum allowed values can be retrieved by:

```julia
minimum(cam, key)
maximum(cam, key)
```


#### String representation

A string representation of feature `key` is obtained by:

```julia
repr(key)
```


#### Enumerated features

An enumerated feature can only have a limited number of predefined values.
These values can be set by an integer index or by their name.  Assuming
`cam` is the camera instance:

```julia
cam[key] = idx
```

or:

```julia
cam[key] = str
```

with `key` the enumerated feature, *e.g.* `PixelEncoding`, `idx` and `str`
the index and the name of the chosen value.  The following expression:

```julia
cam[key]
```

yields the current index of the enumerated feature.  Note that enumeration
indices start at `1` (as do indices in Julia).  The minimum and maximum
indices are respectively given by:

```julia
minimum(cam, key)
maximum(cam, key)
```

the former always yields `1` for an enumerated feature.

To retrieve the string representation of the value an enumerated feature, do
one of:

```julia
repr(cam, key)
repr(cam, key, idx)
```

which respectively yield the string representation of the current value of the
enumerated feature and of the value at a given index.

To query whether a given index is available or implemented for an enumerated
feature, call respectively:

```julia
isavailable(cam, key, idx)
isimplemented(cam, key, idx)
```


#### Commands

Command features (*e.g.* `AcquisitionStart`) are used to identify a specific
command to send to the camera.  These features have no values.  To send the
commmand `cmd` to the camera `cam`, you just have to:

```julia
send(cam, cmd)
```


#### Define new features

If specific features are not predefined by the `AndorCameras` package, you may
define them at run-time provided their name and type is known.  For instance:

```julia
boolkey = AndorCameras.BooleanFeature("SomeBooleanFeature")
intkey = AndorCameras.IntegerFeature("SomeIntegerFeature")
enumkey = AndorCameras.EnumeratedFeature("SomeEnumeratedFeature")
fltkey = AndorCameras.FloatingPointFeature("SomeFloatingPointFeature")
strkey = AndorCameras.StringFeature("SomeStringFeature")
```

would define 5 features of 5 different types given their names.  These features
can be used as any others.  For instance:

```julia
cam[boolkey] = false
```

If performance and readability are not an issue, a feature may be defined on
the fly.  For instance:

```julia
cam[AndorCameras.BooleanFeature("SomeBooleanFeature")] = false
```


## Installation

The easiest way to install `AndorCameras` is via the Julia registry
[`EmmtRegistry`](https://github.com/emmt/EmmtRegistry):

```julia
using Pkg
pkg"registry add https://github.com/emmt/EmmtRegistry"
pkg"add AndorCameras"
pkg"build AndorCameras"
```

The build process assumes that [Andor Software Development Kit
(SDK)](http://www.andor.com/scientific-software/software-development-kit) has
been installed in the usual directory `/usr/local/andor` for Linux or
`C:/Program Files/AndorSDK3` for Windows (read the end of this section if you
have installed the SDK elsewhere).

If Andor SDK is not installed in the usual directory, you can define the
`AT_DIR`, `AT_INCDIR` and/or `AT_LIBDIR` environment variables before building
`AndorCameras`.  These variables are used as follows:

* `AT_DIR` is the directory where the Andor SDK has been installed.  If this
  environment variable is not defined, it is assumed to be `/usr/local/andor`
  for Linux or `C:/Program Files/AndorSDK3` for Windows.

* `AT_INCDIR` is the directory containing the Andor SDK header file `atcore.h`.
  If this environment variable is not defined, the header file is searched in
  directories `$AT_DIR/include` and `$AT_DIR` (in that order).

* `AT_LIBDIR` is the directory containing the Andor SDK library (`libatcore.so`
  on Linux, `atcore.dll` on Windows).  If this environment variable is not
  defined, the library is searched in directories `$AT_DIR/lib` and `$AT_DIR`
  (in that order).

For instance id Andor SDK has been installed in `/opt/andor`, you can define
the `AT_DIR` environment variable in Julia by:

```julia
ENV["AT_DIR"] = "/opt/andor"
```

before building `AndorCamera`:

```julia
using Pkg
pkg"build AndorCameras"
```
