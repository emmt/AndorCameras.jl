```julia
isimplemented(cam, key)
isreadable(cam, key)
iswritable(cam, key)
isreadonly(cam, key)
isimplemented(cam, key, idx)
isavailable(cam, key, idx)
cam[key]
cam[key] = val
minimum(cam, key)
maximum(cam, key)
send(cam, cmd)
repr(key)  -> string representation of feature `key`
repr(cam, key, idx) -> string representation of enumerated feature `key` at index `idx`
```


```julia
using AndorCameras
using AndorCameras.Constants
using AndorCameras.Features
```

## Usage for the end-user

### Open and close a camera

To open an Andor camera:

```julia
open(AndorCameras.Camera, dev)
```

with `dev` the device number (`0` is a simulated camera `SimCam` and `1`
correspond to the `System`).  To figure out how many Andor devices are
available:

```julia
AndorCameras.getnumberofdevices()
```

## Advanced usage

This section describes advanced use of the interface to Andor cameras
provided by the `AndorCameras` module.


### Features

Andor cameras have features whose value can be retrieved or set using the
array index syntax:

```julia
cam[key]
cam[key] = val
```

where `cam` is the camera instance, `key` is the considered feature and
`val` its value.  Here `key` can be `AndorCameras.PixelEncoding` or just
`PixelEncoding` if you have imported all defined features by:

```julia
using AndorCameras.Features
```

The names of the constants defining the existing features closely follow
the *Andor Software Development Kit* documentation.  This documentation
should be consulted to figure out the supported features and their meaning.

Julia `AndorCameras` module takes care of the different kind of features
depending on the type of their values: integer, floating-point, string,
boolean or enumerated.  Enumerated features can take integer or string
values, they are described [below](#enumerated-features).  There are also
[*command* features](#commands) which have no value but are used to send
commands to the camera.

You can query whether a specific feature is implemented,



### Enumerated features

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

the former always yields `1`.

It is possible to retrieve the string representation of the value an
enumerated feature:

```julia
repr(cam, key)
repr(cam, key, idx)
```

respectively yield the current value of the enumerated feature and the
value at a given index.

To query whether a given index is available or implemented for an
enumerated feature, call:

```julia
isavailable(cam, key, idx)
isimplemented(cam, key, idx)
```


### Commands

Command features are used to identify a specific command to send to the
camera.  These features have no values.  Assuming `cmd` is a command
feature, it can be applied to a camera, say `cam`, by:

```julia
send(cam, cmd)
```
