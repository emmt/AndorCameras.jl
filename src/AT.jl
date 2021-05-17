#
# AT.jl --
#
# Implement Julia interface to Andor SDK.
#
#-------------------------------------------------------------------------------
#
# This file is part of "AndorCameras.jl" released under the MIT license.
#
# Copyright (C) 2017-2021, Éric Thiébaut.
#

"""
    using AndorCameras.AT

makes all Andor cameras constants and low-level functions available (they are
all prefixed with `AT.`).

"""
module AT

import ..WideStrings

# Types.
struct Handle; val::Cint; end # wrap AT_H in <atcore.h>
const BOOL    = Cint          # AT_BOOL in <atcore.h>
const INT     = Int64         # AT_64 in <atcore.h>
const BYTE    = UInt8         # AT_U8 in <atcore.h>
const FLOAT   = Cdouble       # for {Set,Get}Float
const STRING  = Cwstring      # constant string of wide characters (not output buffer)

struct Status
    func::Symbol
    code::Cint
end

# Constants.
let filename = joinpath(@__DIR__,"..","deps","deps.jl")
    isfile(filename) || error(
        "Package `AndorCameras` not properly installed.  Run ",
        "`Pkg.build(\"AndorCameras\")` to create file \"", filename, "\".")
    filename
end |> include

"""
    @call(func, rtype, proto, args...)

yields code to call C function `func` in Andor SDK library assuming `rtype`
is the return type of the function, `proto` is a tuple of the argument types
and `args...` are the arguments.

The return type `rtype` must be `Cint` and the produced code is wrapped so
that an instance of `AT.Status` is returned with the status code and the
symbolic name of the called SDK function.

"""
macro call(func, rtype, args...)
    rtype == :Cint || error("return type must be `Cint`")
    qfunc = quoted(func)
    expr = Expr(:call, :ccall, Expr(:tuple, qfunc, :_DLL), rtype, args...)
    return quote
        Status($qfunc, $(esc(expr)))
    end
end
quoted(x::QuoteNode) = x
quoted(x::Symbol) = QuoteNode(x)
quoted(x::AbstractString) = quoted(Symbol(x))

boolean(x::Ref{BOOL}) = (x[] != FALSE)

InitialiseLibrary() = @call(:AT_InitialiseLibrary, Cint, ())

FinaliseLibrary() = @call(:AT_FinaliseLibrary, Cint, ())

Open(index) = begin
    result = Ref{Handle}()
    status = @call(:AT_Open, Cint, (Cint, Ref{Handle}), index, result)
    return status, result[]
end

Close(handle) = @call(:AT_Close, Cint, (Handle,), handle)

# FIXME: not yet interfaced:
# typedef int (AT_EXP_CONV *FeatureCallback)(AT_H Hndl, const AT_WC* Feature, void* Context);
# int AT_EXP_CONV AT_RegisterFeatureCallback(AT_H Hndl, const AT_WC* Feature,
#                                            FeatureCallback EvCallback, void* Context);
# int AT_EXP_CONV AT_UnregisterFeatureCallback(AT_H Hndl, const AT_WC* Feature,
#                                              FeatureCallback EvCallback, void* Context);

IsImplemented(handle, feature) = begin
    result = Ref{BOOL}(FALSE)
    status = @call(:AT_IsImplemented, Cint, (Handle, STRING, Ref{BOOL}),
                   handle, feature, result)
    return status, boolean(result)
end

IsReadable(handle, feature) = begin
    result = Ref{BOOL}(FALSE)
    status = @call(:AT_IsReadable, Cint, (Handle, STRING, Ref{BOOL}),
                   handle, feature, result)
    return status, boolean(result)
end

IsWritable(handle, feature) = begin
    result = Ref{BOOL}(FALSE)
    status = @call(:AT_IsWritable, Cint, (Handle, STRING, Ref{BOOL}),
                   handle, feature, result)
    return status, boolean(result)
end

IsReadOnly(handle, feature) = begin
    result = Ref{BOOL}(FALSE)
    status = @call(:AT_IsReadOnly, Cint, (Handle, STRING, Ref{BOOL}),
                   handle, feature, result)
    return status, boolean(result)
end

SetInt(handle, feature, value::Integer) =
    @call(:AT_SetInt, Cint, (Handle, STRING, INT),
          handle, feature, value)

GetInt(handle, feature) = begin
    result = Ref{INT}()
    status = @call(:AT_GetInt, Cint, (Handle, STRING, Ref{INT}),
                   handle, feature, result)
    return status, result[]
end

GetIntMin(handle, feature) = begin
    result = Ref{INT}()
    status = @call(:AT_GetIntMin, Cint, (Handle, STRING, Ref{INT}),
                   handle, feature, result)
    return status, result[]
end

GetIntMax(handle, feature) = begin
    result = Ref{INT}();
    status = @call(:AT_GetIntMax, Cint, (Handle, STRING, Ref{INT}),
                   handle, feature, result)
    return status, result[]
end

SetFloat(handle, feature, value::Real) =
    @call(:AT_SetFloat, Cint, (Handle, STRING, FLOAT),
          handle, feature, value)

GetFloat(handle, feature) = begin
    result = Ref{FLOAT}()
    status = @call(:AT_GetFloat, Cint, (Handle, STRING, Ref{FLOAT}),
                   handle, feature, result)
    return status, result[]
end

GetFloatMin(handle, feature) = begin
    result = Ref{FLOAT}();
    status = @call(:AT_GetFloatMin, Cint, (Handle, STRING, Ref{FLOAT}),
                   handle, feature, result)
    return status, result[]
end

GetFloatMax(handle, feature) = begin
    result = Ref{FLOAT}()
    status = @call(:AT_GetFloatMax, Cint, (Handle, STRING, Ref{FLOAT}),
                   handle, feature, result)
    return status, result[]
end

SetBool(handle, feature, value::Bool) =
    @call(:AT_SetBool, Cint, (Handle, STRING, BOOL),
          handle, feature, (value ? TRUE : FALSE))

GetBool(handle, feature) = begin
    result = Ref{BOOL}();
    status = @call(:AT_GetBool, Cint, (Handle, STRING, Ref{BOOL}),
                   handle, feature, result)
    return status, boolean(result)
end

SetEnumIndex(handle, feature, enum::Integer) =
    @call(:AT_SetEnumIndex, Cint, (Handle, STRING, Cint),
          handle, feature, enum)

SetEnumerated(handle, feature, enum::Integer) =
    @call(:AT_SetEnumerated, Cint, (Handle, STRING, Cint),
          handle, feature, enum)

SetEnumString(handle, feature, value) =
    @call(:AT_SetEnumString, Cint, (Handle, STRING, STRING),
          handle, feature, value)

SetEnumeratedString(handle, feature, value) =
    @call(:AT_SetEnumeratedString, Cint, (Handle, STRING, STRING),
          handle, feature, value)

GetEnumIndex(handle, feature) = begin
    result = Ref{Cint}();
    status = @call(:AT_GetEnumIndex, Cint, (Handle, STRING, Ref{Cint}),
                   handle, feature, result)
    return status, Int(result[])
end

GetEnumerated(handle, feature) = begin
    result = Ref{Cint}()
    status = @call(:AT_GetEnumerated, Cint, (Handle, STRING, Ref{Cint}),
                   handle, feature, result)
    return status, Int(result[])
end

GetEnumCount(handle, feature) = begin
    result = Ref{Cint}()
    status = @call(:AT_GetEnumCount, Cint, (Handle, STRING, Ref{Cint}),
                   handle, feature, result)
    return status, Int(result[])
end

GetEnumeratedCount(handle, feature) = begin
    result = Ref{Cint}()
    status = @call(:AT_GetEnumeratedCount, Cint,
                   (Handle, STRING, Ref{Cint}),
                   handle, feature, result)
    return status, Int(result[])
end

IsEnumIndexAvailable(handle, feature, enum::Integer) = begin
    result = Ref{BOOL}()
    status = @call(:AT_IsEnumIndexAvailable, Cint,
                   (Handle, STRING, Cint, Ref{BOOL}),
                   handle, feature, enum, result)
    return status, boolean(result)
end

IsEnumeratedIndexAvailable(handle, feature, enum::Integer) = begin
    result = Ref{BOOL}()
    status = @call(:AT_IsEnumeratedIndexAvailable, Cint,
                   (Handle, STRING, Cint, Ref{BOOL}),
                   handle, feature, enum, result)
    return status, boolean(result)
end

IsEnumIndexImplemented(handle, feature, enum::Integer) = begin
    result = Ref{BOOL}()
    status = @call(:AT_IsEnumIndexImplemented, Cint,
                   (Handle, STRING, Cint, Ref{BOOL}),
                   handle, feature, enum, result)
    return status, boolean(result)
end

IsEnumeratedIndexImplemented(handle, feature, enum::Integer) = begin
    result = Ref{BOOL}()
    status = @call(:AT_IsEnumeratedIndexImplemented, Cint,
                   (Handle, STRING, Cint, Ref{BOOL}),
                   handle, feature, enum, result)
    return status, boolean(result)
end

GetEnumStringByIndex(handle, feature, enum::Integer, buf::DenseVector{Cwchar_t}) =
    GetEnumStringByIndex(handle, feature, enum, pointer(buf), length(buf))

GetEnumStringByIndex(handle, feature, enum::Integer, ptr::Ptr{Cwchar_t}, len::Integer) =
    @call(:AT_GetEnumStringByIndex, Cint,
          (Handle, STRING, Cint, Ptr{Cwchar_t}, Cint),
          handle, feature, enum, ptr, len)

GetEnumeratedString(handle, feature, enum::Integer, buf::DenseVector{Cwchar_t}) =
    GetEnumeratedString(handle, feature, enum, pointer(buf), length(buf))

GetEnumeratedString(handle, feature, enum::Integer, ptr::Ptr{Cwchar_t}, len::Integer) =
    @call(:AT_GetEnumeratedString, Cint,
          (Handle, STRING, Cint, Ptr{Cwchar_t}, Cint),
          handle, feature, enum, ptr, len)

Command(handle, feature) =
    @call(:AT_Command, Cint, (Handle, STRING), handle, feature)

SetString(handle, feature, value) =
    @call(:AT_SetString, Cint, (Handle, STRING, STRING),
          handle, feature, value)

GetString(handle, feature, buf::DenseVector{Cwchar_t}) =
    GetString(handle, feature, pointer(buf), length(buf))

GetString(handle, feature, ptr::Ptr{Cwchar_t}, len::Integer) =
    @call(:AT_GetString, Cint, (Handle, STRING, Ptr{Cwchar_t}, Cint),
          handle, feature, ptr, len)

GetStringMaxLength(handle, feature) = begin
    result = Ref{Cint}()
    status = @call(:AT_GetStringMaxLength, Cint,
                   (Handle, STRING, Ref{Cint}),
                   handle, feature, result)
    return status, Int(result[])
end

QueueBuffer(handle, buf::DenseVector{BYTE}) =
    QueueBuffer(handle, pointer(buf), sizeof(buf))

QueueBuffer(handle, ptr::Ptr{BYTE}, siz::Integer) =
    @call(:AT_QueueBuffer, Cint, (Handle, Ptr{BYTE}, Cint),
          handle, ptr, siz)

WaitBuffer(handle, timeout::Integer) = begin
    refptr = Ref{Ptr{BYTE}}()
    refsiz = Ref{Cint}()
    status = @call(:AT_WaitBuffer, Cint,
                   (Handle, Ref{Ptr{BYTE}}, Ref{Cint}, Cuint),
                   handle, refptr, refsiz, timeout)
    return status, refptr[], Int(refsiz[])
end

Flush(handle) = @call(:AT_Flush, Cint, (Handle,), handle)

end
