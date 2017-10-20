#
# errors.jl --
#
# Management of errors.
#
#-------------------------------------------------------------------------------
#
# This file is part of "AndorCameras.jl" released under the MIT license.
#
# Copyright (C) 2017, Éric Thiébaut.
#

Base.showerror(io::IO, e::AndorError) =
    print(io, "Error in ", e.func, ": ", geterrormessage(e.code), " [",
          geterrorsymbol(e.code), "]")

const _ERR_REASONS = Dict(
    AT_SUCCESS                      => "Function call has been successful",
    AT_ERR_NOTINITIALISED           => "Function called with an uninitialized handle",
    AT_ERR_NOTIMPLEMENTED           => "Feature has not been implemented for the chosen camera",
    AT_ERR_READONLY                 => "Feature is read only",
    AT_ERR_NOTREADABLE              => "Feature is currently not readable",
    AT_ERR_NOTWRITABLE              => "Feature is currently not writable/executable",
    AT_ERR_OUTOFRANGE               => "Value/index is outside the valid range",
    AT_ERR_INDEXNOTAVAILABLE        => "Index is currently not available",
    AT_ERR_INDEXNOTIMPLEMENTED      => "Index is not implemented for the chosen camera",
    AT_ERR_EXCEEDEDMAXSTRINGLENGTH  => "String value provided exceeds the maximum allowed length",
    AT_ERR_CONNECTION               => "Error connecting to or disconnecting from hardware",
    AT_ERR_NODATA                   => "No Internal Event or Internal Error",
    AT_ERR_INVALIDHANDLE            => "Invalid device handle passed to function ",
    AT_ERR_TIMEDOUT                 => "The function timed out while waiting for data arrive in output queue",
    AT_ERR_BUFFERFULL               => "The input queue has reached its capacity",
    AT_ERR_INVALIDSIZE              => "The size of a queued buffer did not match the frame size",
    AT_ERR_INVALIDALIGNMENT         => "A queued buffer was not aligned on an 8-byte boundary",
    AT_ERR_COMM                     => "An error has occurred while communicating with hardware",
    AT_ERR_STRINGNOTAVAILABLE       => "Index/string is not available",
    AT_ERR_STRINGNOTIMPLEMENTED     => "Index/string is not implemented for the chosen camera",
    AT_ERR_NULL_FEATURE             => "NULL feature name passed to function",
    AT_ERR_NULL_HANDLE              => "Null device handle passed to function",
    AT_ERR_NULL_IMPLEMENTED_VAR     => "Feature not implemented",
    AT_ERR_NULL_READABLE_VAR        => "Readable not set",
    AT_ERR_NULL_WRITABLE_VAR        => "Writable not set",
    AT_ERR_NULL_MINVALUE            => "NULL min value",
    AT_ERR_NULL_MAXVALUE            => "NULL max value",
    AT_ERR_NULL_VALUE               => "NULL value returned from function",
    AT_ERR_NULL_STRING              => "NULL string returned from function",
    AT_ERR_NULL_COUNT_VAR           => "NULL feature count",
    AT_ERR_NULL_ISAVAILABLE_VAR     => "Available not set",
    AT_ERR_NULL_MAXSTRINGLENGTH     => "Max string length is NULL",
    AT_ERR_NULL_EVCALLBACK          => "Event callback parameter is NULL",
    AT_ERR_NULL_QUEUE_PTR           => "Pointer to queue is NULL",
    AT_ERR_NULL_WAIT_PTR            => "Wait pointer is NULL",
    AT_ERR_NULL_PTRSIZE             => "Pointer size is NULL",
    AT_ERR_NOMEMORY                 => "No memory has been allocated for the current action",
    AT_ERR_DEVICEINUSE              => "Function failed to connect to a device because it is already being used",
    AT_ERR_HARDWARE_OVERFLOW        => "The software was not able to retrieve data from the card or camera fast enough to avoid the internal hardware buffer bursting")

geterrormessage(code::Integer) =
    get(_ERR_REASONS, code, "Unknown error code")

const _ERR_SYMBOLS = Dict(
    AT_SUCCESS                      => :AT_SUCCESS,
    AT_ERR_NOTINITIALISED           => :AT_ERR_NOTINITIALISED,
    AT_ERR_NOTIMPLEMENTED           => :AT_ERR_NOTIMPLEMENTED,
    AT_ERR_READONLY                 => :AT_ERR_READONLY,
    AT_ERR_NOTREADABLE              => :AT_ERR_NOTREADABLE,
    AT_ERR_NOTWRITABLE              => :AT_ERR_NOTWRITABLE,
    AT_ERR_OUTOFRANGE               => :AT_ERR_OUTOFRANGE,
    AT_ERR_INDEXNOTAVAILABLE        => :AT_ERR_INDEXNOTAVAILABLE,
    AT_ERR_INDEXNOTIMPLEMENTED      => :AT_ERR_INDEXNOTIMPLEMENTED,
    AT_ERR_EXCEEDEDMAXSTRINGLENGTH  => :AT_ERR_EXCEEDEDMAXSTRINGLENGTH,
    AT_ERR_CONNECTION               => :AT_ERR_CONNECTION,
    AT_ERR_NODATA                   => :AT_ERR_NODATA,
    AT_ERR_INVALIDHANDLE            => :AT_ERR_INVALIDHANDLE,
    AT_ERR_TIMEDOUT                 => :AT_ERR_TIMEDOUT,
    AT_ERR_BUFFERFULL               => :AT_ERR_BUFFERFULL,
    AT_ERR_INVALIDSIZE              => :AT_ERR_INVALIDSIZE,
    AT_ERR_INVALIDALIGNMENT         => :AT_ERR_INVALIDALIGNMENT,
    AT_ERR_COMM                     => :AT_ERR_COMM,
    AT_ERR_STRINGNOTAVAILABLE       => :AT_ERR_STRINGNOTAVAILABLE,
    AT_ERR_STRINGNOTIMPLEMENTED     => :AT_ERR_STRINGNOTIMPLEMENTED,
    AT_ERR_NULL_FEATURE             => :AT_ERR_NULL_FEATURE,
    AT_ERR_NULL_HANDLE              => :AT_ERR_NULL_HANDLE,
    AT_ERR_NULL_IMPLEMENTED_VAR     => :AT_ERR_NULL_IMPLEMENTED_VAR,
    AT_ERR_NULL_READABLE_VAR        => :AT_ERR_NULL_READABLE_VAR,
    AT_ERR_NULL_WRITABLE_VAR        => :AT_ERR_NULL_WRITABLE_VAR,
    AT_ERR_NULL_MINVALUE            => :AT_ERR_NULL_MINVALUE,
    AT_ERR_NULL_MAXVALUE            => :AT_ERR_NULL_MAXVALUE,
    AT_ERR_NULL_VALUE               => :AT_ERR_NULL_VALUE,
    AT_ERR_NULL_STRING              => :AT_ERR_NULL_STRING,
    AT_ERR_NULL_COUNT_VAR           => :AT_ERR_NULL_COUNT_VAR,
    AT_ERR_NULL_ISAVAILABLE_VAR     => :AT_ERR_NULL_ISAVAILABLE_VAR,
    AT_ERR_NULL_MAXSTRINGLENGTH     => :AT_ERR_NULL_MAXSTRINGLENGTH,
    AT_ERR_NULL_EVCALLBACK          => :AT_ERR_NULL_EVCALLBACK,
    AT_ERR_NULL_QUEUE_PTR           => :AT_ERR_NULL_QUEUE_PTR,
    AT_ERR_NULL_WAIT_PTR            => :AT_ERR_NULL_WAIT_PTR,
    AT_ERR_NULL_PTRSIZE             => :AT_ERR_NULL_PTRSIZE,
    AT_ERR_NOMEMORY                 => :AT_ERR_NOMEMORY,
    AT_ERR_DEVICEINUSE              => :AT_ERR_DEVICEINUSE,
    AT_ERR_HARDWARE_OVERFLOW        => :AT_ERR_HARDWARE_OVERFLOW)

geterrorsymbol(code::Integer) =
    get(_ERR_SYMBOLS, code, :AT_ERR_UNKNOWN)
