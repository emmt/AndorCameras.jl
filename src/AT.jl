#
# AT.jl --
#
# Implement Julia interface to Andor SDK.
#
#-------------------------------------------------------------------------------
#
# This file is part of "AndorCameras.jl" released under the MIT license.
#
# Copyright (C) 2017-2019, Éric Thiébaut.
#

"""
```julia
using AndorCameras.AT
```

makes all Andor cameras constants and low-level functions available (they are
all prefixed with `AT.`).

"""
module AT

export
    @L_str

isfile(joinpath(@__DIR__,"..","deps","deps.jl")) ||
    error("Tcl not properly installed.  Please run `Pkg.build(\"Tcl\")` to create file \"",joinpath(@__DIR__,"..","deps","deps.jl"),"\"")

include("../deps/deps.jl")

struct Status
    func::Symbol
    code::STATUS
end

"""
```julia
@_call(func, rtype, proto, args...)
```

yields code to call C function `func` in Andor SDK library assuming `rtype`
is the return type of the function, `proto` is a tuple of the argument types
and `args...` are the arguments.

The return type `rtype` must be `STATUS` and the produced code is wrapped so
that an instance of `AT.Status` is returned with the status code and the
symbolic name of the called SDK function.

"""
macro _call(func, rtype, args...)
    rtype == :STATUS || error("return type must be STATUS")
    qfunc = _quoted(func)
    expr = Expr(:call, :ccall, Expr(:tuple, qfunc, :_DLL), rtype, args...)
    return quote
        Status($qfunc, $(esc(expr)))
    end
end
_quoted(x::QuoteNode) = x
_quoted(x::Symbol) = QuoteNode(x)
_quoted(x::AbstractString) = _quoted(Symbol(x))

InitialiseLibrary() = @_call(:AT_InitialiseLibrary, STATUS, ())

FinaliseLibrary() = @_call(:AT_FinaliseLibrary, STATUS, ())

Open(index) =
    (ref = Ref{HANDLE}();
     (@_call(:AT_Open, STATUS, (INDEX, Ref{HANDLE}),
             index, ref), ref[]))

Close(handle) = @_call(:AT_Close, STATUS, (HANDLE,), handle)

# FIXME: not yet interfaced:
# typedef int (AT_EXP_CONV *FeatureCallback)(AT_H Hndl, const AT_WC* Feature, void* Context);
# int AT_EXP_CONV AT_RegisterFeatureCallback(AT_H Hndl, const AT_WC* Feature,
#                                            FeatureCallback EvCallback, void* Context);
# int AT_EXP_CONV AT_UnregisterFeatureCallback(AT_H Hndl, const AT_WC* Feature,
#                                              FeatureCallback EvCallback, void* Context);

IsImplemented(handle, feature) =
    (ref = Ref{BOOL}(FALSE);
     (@_call(:AT_IsImplemented, STATUS, (HANDLE, FEATURE, Ref{BOOL}),
             handle, feature, ref), ref[] != FALSE))

IsReadable(handle, feature) =
    (ref = Ref{BOOL}(FALSE);
     (@_call(:AT_IsReadable, STATUS, (HANDLE, FEATURE, Ref{BOOL}),
             handle, feature, ref), ref[] != FALSE))

IsWritable(handle, feature) =
    (ref = Ref{BOOL}(FALSE);
     (@_call(:AT_IsWritable, STATUS, (HANDLE, FEATURE, Ref{BOOL}),
             handle, feature, ref), ref[] != FALSE))

IsReadOnly(handle, feature) =
    (ref = Ref{BOOL}(FALSE);
     (@_call(:AT_IsReadOnly, STATUS, (HANDLE, FEATURE, Ref{BOOL}),
             handle, feature, ref), ref[] != FALSE))

SetInt(handle, feature, value::Integer) =
    @_call(:AT_SetInt, STATUS, (HANDLE, FEATURE, INT),
           handle, feature, value)

GetInt(handle, feature) =
    (ref = Ref{INT}();
     (@_call(:AT_GetInt, STATUS, (HANDLE, FEATURE, Ref{INT}),
             handle, feature, ref), ref[]))

GetIntMin(handle, feature) =
    (ref = Ref{INT}();
     (@_call(:AT_GetIntMin, STATUS, (HANDLE, FEATURE, Ref{INT}),
             handle, feature, ref), ref[]))

GetIntMax(handle, feature) =
    (ref = Ref{INT}();
     (@_call(:AT_GetIntMax, STATUS, (HANDLE, FEATURE, Ref{INT}),
             handle, feature, ref), ref[]))

SetFloat(handle, feature, value::Real) =
    @_call(:AT_SetFloat, STATUS, (HANDLE, FEATURE, FLOAT),
           handle, feature, value)

GetFloat(handle, feature) =
    (ref = Ref{FLOAT}();
     (@_call(:AT_GetFloat, STATUS, (HANDLE, FEATURE, Ref{FLOAT}),
             handle, feature, ref), ref[]))

GetFloatMin(handle, feature) =
    (ref = Ref{FLOAT}();
     (@_call(:AT_GetFloatMin, STATUS, (HANDLE, FEATURE, Ref{FLOAT}),
             handle, feature, ref), ref[]))

GetFloatMax(handle, feature) =
    (ref = Ref{FLOAT}();
     (@_call(:AT_GetFloatMax, STATUS, (HANDLE, FEATURE, Ref{FLOAT}),
             handle, feature, ref), ref[]))

SetBool(handle, feature, value::Bool) =
    @_call(:AT_SetBool, STATUS, (HANDLE, FEATURE, BOOL),
           handle, feature, (value ? TRUE : FALSE))

GetBool(handle, feature) =
    (ref = Ref{BOOL}();
     (@_call(:AT_GetBool, STATUS, (HANDLE, FEATURE, Ref{BOOL}),
             handle, feature, ref), ref[] != FALSE))

SetEnumIndex(handle, feature, enum::Integer) =
    @_call(:AT_SetEnumIndex, STATUS, (HANDLE, FEATURE, ENUM),
           handle, feature, enum)

SetEnumerated(handle, feature, enum::Integer) =
    @_call(:AT_SetEnumerated, STATUS, (HANDLE, FEATURE, ENUM),
           handle, feature, enum)

SetEnumString(handle, feature, value) =
    @_call(:AT_SetEnumString, STATUS, (HANDLE, FEATURE, Ptr{WCHAR}),
           handle, feature, value)

SetEnumeratedString(handle, feature, value) =
    @_call(:AT_SetEnumeratedString, STATUS, (HANDLE, FEATURE, Ptr{WCHAR}),
           handle, feature, value)


GetEnumIndex(handle, feature) =
    (ref = Ref{ENUM}();
     (@_call(:AT_GetEnumIndex, STATUS, (HANDLE, FEATURE, Ref{ENUM}),
             handle, feature, ref), Int(ref[])))

GetEnumerated(handle, feature) =
    (ref = Ref{ENUM}();
     (@_call(:AT_GetEnumerated, STATUS, (HANDLE, FEATURE, Ref{ENUM}),
             handle, feature, ref), Int(ref[])))

GetEnumCount(handle, feature) =
    (ref = Ref{LENGTH}();
     (@_call(:AT_GetEnumCount, STATUS, (HANDLE, FEATURE, Ref{LENGTH}),
             handle, feature, ref), Int(ref[])))

GetEnumeratedCount(handle, feature) =
    (ref = Ref{LENGTH}();
     (@_call(:AT_GetEnumeratedCount, STATUS, (HANDLE, FEATURE, Ref{LENGTH}),
             handle, feature, ref), Int(ref[])))

IsEnumIndexAvailable(handle, feature, enum::Integer) =
    (ref = Ref{BOOL}();
     (@_call(:AT_IsEnumIndexAvailable, STATUS,
             (HANDLE, FEATURE, ENUM, Ref{BOOL}),
             handle, feature, enum, ref), ref[] != FALSE))

IsEnumeratedIndexAvailable(handle, feature, enum::Integer) =
    (ref = Ref{BOOL}();
     (@_call(:AT_IsEnumeratedIndexAvailable, STATUS,
             (HANDLE, FEATURE, ENUM, Ref{BOOL}),
             handle, feature, enum, ref), ref[] != FALSE))

IsEnumIndexImplemented(handle, feature, enum::Integer) =
    (ref = Ref{BOOL}();
     (@_call(:AT_IsEnumIndexImplemented, STATUS,
             (HANDLE, FEATURE, ENUM, Ref{BOOL}),
             handle, feature, enum, ref), ref[] != FALSE))

IsEnumeratedIndexImplemented(handle, feature, enum::Integer) =
    (ref = Ref{BOOL}();
     (@_call(:AT_IsEnumeratedIndexImplemented, STATUS,
             (HANDLE, FEATURE, ENUM, Ref{BOOL}),
             handle, feature, enum, ref), ref[] != FALSE))

GetEnumStringByIndex(handle, feature, enum::Integer, buf::DenseVector{WCHAR}) =
    GetEnumStringByIndex(handle, feature, enum, pointer(buf), length(buf))

GetEnumStringByIndex(handle, feature, enum::Integer, ptr::Ptr{WCHAR}, len::Integer) =
    @_call(:AT_GetEnumStringByIndex, STATUS,
           (HANDLE, FEATURE, ENUM, Ptr{WCHAR}, LENGTH),
           handle, feature, enum, ptr, len)

GetEnumeratedString(handle, feature, enum::Integer, buf::DenseVector{WCHAR}) =
    GetEnumeratedString(handle, feature, enum, pointer(buf), length(buf))

GetEnumeratedString(handle, feature, enum::Integer, ptr::Ptr{WCHAR}, len::Integer) =
    @_call(:AT_GetEnumeratedString, STATUS,
           (HANDLE, FEATURE, ENUM, Ptr{WCHAR}, LENGTH),
           handle, feature, enum, ptr, len)

Command(handle, feature) =
    @_call(:AT_Command, STATUS, (HANDLE, FEATURE), handle, feature)

SetString(handle, feature, value) =
    @_call(:AT_SetString, STATUS, (HANDLE, FEATURE, Ptr{WCHAR}),
           handle, feature, value)

GetString(handle, feature, buf::DenseVector{WCHAR}) =
    GetString(handle, feature, pointer(buf), length(buf))

GetString(handle, feature, ptr::Ptr{WCHAR}, len::Integer) =
    @_call(:AT_GetString, STATUS, (HANDLE, FEATURE, Ptr{WCHAR}, LENGTH),
           handle, feature, ptr, len)

GetStringMaxLength(handle, feature) =
    (ref = Ref{LENGTH}();
     (@_call(:AT_GetStringMaxLength, STATUS, (HANDLE, FEATURE, Ref{LENGTH}),
             handle, feature, ref), Int(ref[])))

QueueBuffer(handle, buf::DenseVector{BYTE}) =
    QueueBuffer(handle, pointer(buf), sizeof(buf))

QueueBuffer(handle, ptr::Ptr{BYTE}, siz::Integer) =
    @_call(:AT_QueueBuffer, STATUS, (HANDLE, Ptr{BYTE}, LENGTH),
           handle, ptr, siz)

WaitBuffer(handle, timeout::Integer) =
    (refptr = Ref{Ptr{BYTE}}();
     refsiz = Ref{LENGTH}();
     (@_call(:AT_WaitBuffer, STATUS, (HANDLE, Ref{Ptr{BYTE}}, Ref{LENGTH}, MSEC),
             handle, refptr, refsiz, timeout), refptr[], Int(refsiz[])))

Flush(handle) =
    @_call(:AT_Flush, STATUS, (HANDLE,), handle)


"""
```julia
widestring(str, len = strlen(str))
```

yields a vector of wide characters (`Cwchar_t`) with the contents of the string
`str` and properly zero-terminated.  This buffer is independent from the input
string and its contents can be overwritten.  An error is thrown if `str`
contains any embedded NULL characters (which would cause the string to be
silently truncated if the C routine treats NULL as the terminator).

An alternative (without the checking of embedded NULL characters) is:

```julia
push!(transcode(Cwchar_t, str), convert(Cwchar_t, 0))
```

This method is used to implement the `@L_str` macro which converts a
literal string into a wide character string.  For instance:

```julia
L"EventSelector"
```

"""
function widestring(str::AbstractString,
                    len::Integer = length(str)) :: Array{WCHAR}
    buf = Array{WCHAR}(undef, len + 1)
    i = 0
    @inbounds for c in str
        if i ≥ len
            break
        end
        c != '\0' || error("strings must not have embedded NULL characters")
        i += 1
        buf[i] = c
    end
    @inbounds while i ≤ len
        i += 1
        buf[i] = zero(WCHAR)
    end
    return buf
end

widestring(sym::Symbol) = widestring(string(sym))

function widestringtostring(arr::Array{WCHAR}) :: String
    len = length(arr)
    @inbounds while len > 0 && arr[len] == zero(WCHAR)
        len -= 1
    end
    buf = Vector{Char}(undef, len)
    @inbounds for i in 1:len
        c = arr[i]
        c != zero(WCHAR) || error("strings must not have embedded NULL characters")
        buf[i] = c
    end
    return String(buf)
end

"""

```julia
L"text"
```

yields an array of wide characters.

"""
macro L_str(str)
    :(widestring($str))
end

end
