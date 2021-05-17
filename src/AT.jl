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

export
    @L_str

let filename = joinpath(@__DIR__,"..","deps","deps.jl")
    isfile(filename) || error(
        "Package `AndorCameras` not properly installed.  Run ",
        "`Pkg.build(\"AndorCameras\")` to create file \"", filename, "\".")
    filename
end |> include

struct Status
    func::Symbol
    code::STATUS
end

"""
    @call(func, rtype, proto, args...)

yields code to call C function `func` in Andor SDK library assuming `rtype`
is the return type of the function, `proto` is a tuple of the argument types
and `args...` are the arguments.

The return type `rtype` must be `STATUS` and the produced code is wrapped so
that an instance of `AT.Status` is returned with the status code and the
symbolic name of the called SDK function.

"""
macro call(func, rtype, args...)
    rtype == :STATUS || error("return type must be STATUS")
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

InitialiseLibrary() = @call(:AT_InitialiseLibrary, STATUS, ())

FinaliseLibrary() = @call(:AT_FinaliseLibrary, STATUS, ())

Open(index) = begin
    result = Ref{HANDLE}()
    status = @call(:AT_Open, STATUS, (INDEX, Ref{HANDLE}), index, result)
    return status, result[]
end

Close(handle) = @call(:AT_Close, STATUS, (HANDLE,), handle)

# FIXME: not yet interfaced:
# typedef int (AT_EXP_CONV *FeatureCallback)(AT_H Hndl, const AT_WC* Feature, void* Context);
# int AT_EXP_CONV AT_RegisterFeatureCallback(AT_H Hndl, const AT_WC* Feature,
#                                            FeatureCallback EvCallback, void* Context);
# int AT_EXP_CONV AT_UnregisterFeatureCallback(AT_H Hndl, const AT_WC* Feature,
#                                              FeatureCallback EvCallback, void* Context);

IsImplemented(handle, feature) = begin
    result = Ref{BOOL}(FALSE)
    status = @call(:AT_IsImplemented, STATUS, (HANDLE, FEATURE, Ref{BOOL}),
                   handle, feature, result)
    return status, boolean(result)
end

IsReadable(handle, feature) = begin
    result = Ref{BOOL}(FALSE)
    status = @call(:AT_IsReadable, STATUS, (HANDLE, FEATURE, Ref{BOOL}),
                   handle, feature, result)
    return status, boolean(result)
end

IsWritable(handle, feature) = begin
    result = Ref{BOOL}(FALSE)
    status = @call(:AT_IsWritable, STATUS, (HANDLE, FEATURE, Ref{BOOL}),
                   handle, feature, result)
    return status, boolean(result)
end

IsReadOnly(handle, feature) = begin
    result = Ref{BOOL}(FALSE)
    status = @call(:AT_IsReadOnly, STATUS, (HANDLE, FEATURE, Ref{BOOL}),
                   handle, feature, result)
    return status, boolean(result)
end

SetInt(handle, feature, value::Integer) =
    @call(:AT_SetInt, STATUS, (HANDLE, FEATURE, INT),
          handle, feature, value)

GetInt(handle, feature) = begin
    result = Ref{INT}()
    status = @call(:AT_GetInt, STATUS, (HANDLE, FEATURE, Ref{INT}),
                   handle, feature, result)
    return status, result[]
end

GetIntMin(handle, feature) = begin
    result = Ref{INT}()
    status = @call(:AT_GetIntMin, STATUS, (HANDLE, FEATURE, Ref{INT}),
                   handle, feature, result)
    return status, result[]
end

GetIntMax(handle, feature) = begin
    result = Ref{INT}();
    status = @call(:AT_GetIntMax, STATUS, (HANDLE, FEATURE, Ref{INT}),
                   handle, feature, result)
    return status, result[]
end

SetFloat(handle, feature, value::Real) =
    @call(:AT_SetFloat, STATUS, (HANDLE, FEATURE, FLOAT),
          handle, feature, value)

GetFloat(handle, feature) = begin
    result = Ref{FLOAT}()
    status = @call(:AT_GetFloat, STATUS, (HANDLE, FEATURE, Ref{FLOAT}),
                   handle, feature, result)
    return status, result[]
end

GetFloatMin(handle, feature) = begin
    result = Ref{FLOAT}();
    status = @call(:AT_GetFloatMin, STATUS, (HANDLE, FEATURE, Ref{FLOAT}),
                   handle, feature, result)
    return status, result[]
end

GetFloatMax(handle, feature) = begin
    result = Ref{FLOAT}()
    status = @call(:AT_GetFloatMax, STATUS, (HANDLE, FEATURE, Ref{FLOAT}),
                   handle, feature, result)
    return status, result[]
end

SetBool(handle, feature, value::Bool) =
    @call(:AT_SetBool, STATUS, (HANDLE, FEATURE, BOOL),
          handle, feature, (value ? TRUE : FALSE))

GetBool(handle, feature) = begin
    result = Ref{BOOL}();
    status = @call(:AT_GetBool, STATUS, (HANDLE, FEATURE, Ref{BOOL}),
                   handle, feature, result)
    return status, boolean(result)
end

SetEnumIndex(handle, feature, enum::Integer) =
    @call(:AT_SetEnumIndex, STATUS, (HANDLE, FEATURE, ENUM),
          handle, feature, enum)

SetEnumerated(handle, feature, enum::Integer) =
    @call(:AT_SetEnumerated, STATUS, (HANDLE, FEATURE, ENUM),
          handle, feature, enum)

SetEnumString(handle, feature, value) =
    @call(:AT_SetEnumString, STATUS, (HANDLE, FEATURE, Ptr{WCHAR}),
          handle, feature, value)

SetEnumeratedString(handle, feature, value) =
    @call(:AT_SetEnumeratedString, STATUS, (HANDLE, FEATURE, Ptr{WCHAR}),
          handle, feature, value)

GetEnumIndex(handle, feature) = begin
    result = Ref{ENUM}();
    status = @call(:AT_GetEnumIndex, STATUS, (HANDLE, FEATURE, Ref{ENUM}),
                   handle, feature, result)
    return status, Int(result[])
end

GetEnumerated(handle, feature) = begin
    result = Ref{ENUM}()
    status = @call(:AT_GetEnumerated, STATUS, (HANDLE, FEATURE, Ref{ENUM}),
                   handle, feature, result)
    return status, Int(result[])
end

GetEnumCount(handle, feature) = begin
    result = Ref{LENGTH}()
    status = @call(:AT_GetEnumCount, STATUS, (HANDLE, FEATURE, Ref{LENGTH}),
                   handle, feature, result)
    return status, Int(result[])
end

GetEnumeratedCount(handle, feature) = begin
    result = Ref{LENGTH}()
    status = @call(:AT_GetEnumeratedCount, STATUS,
                   (HANDLE, FEATURE, Ref{LENGTH}),
                   handle, feature, result)
    return status, Int(result[])
end

IsEnumIndexAvailable(handle, feature, enum::Integer) = begin
    result = Ref{BOOL}()
    status = @call(:AT_IsEnumIndexAvailable, STATUS,
                   (HANDLE, FEATURE, ENUM, Ref{BOOL}),
                   handle, feature, enum, result)
    return status, boolean(result)
end

IsEnumeratedIndexAvailable(handle, feature, enum::Integer) = begin
    result = Ref{BOOL}()
    status = @call(:AT_IsEnumeratedIndexAvailable, STATUS,
                   (HANDLE, FEATURE, ENUM, Ref{BOOL}),
                   handle, feature, enum, result)
    return status, boolean(result)
end

IsEnumIndexImplemented(handle, feature, enum::Integer) = begin
    result = Ref{BOOL}()
    status = @call(:AT_IsEnumIndexImplemented, STATUS,
                   (HANDLE, FEATURE, ENUM, Ref{BOOL}),
                   handle, feature, enum, result)
    return status, boolean(result)
end

IsEnumeratedIndexImplemented(handle, feature, enum::Integer) = begin
    result = Ref{BOOL}()
    status = @call(:AT_IsEnumeratedIndexImplemented, STATUS,
                   (HANDLE, FEATURE, ENUM, Ref{BOOL}),
                   handle, feature, enum, result)
    return status, boolean(result)
end

GetEnumStringByIndex(handle, feature, enum::Integer, buf::DenseVector{WCHAR}) =
    GetEnumStringByIndex(handle, feature, enum, pointer(buf), length(buf))

GetEnumStringByIndex(handle, feature, enum::Integer, ptr::Ptr{WCHAR}, len::Integer) =
    @call(:AT_GetEnumStringByIndex, STATUS,
          (HANDLE, FEATURE, ENUM, Ptr{WCHAR}, LENGTH),
          handle, feature, enum, ptr, len)

GetEnumeratedString(handle, feature, enum::Integer, buf::DenseVector{WCHAR}) =
    GetEnumeratedString(handle, feature, enum, pointer(buf), length(buf))

GetEnumeratedString(handle, feature, enum::Integer, ptr::Ptr{WCHAR}, len::Integer) =
    @call(:AT_GetEnumeratedString, STATUS,
          (HANDLE, FEATURE, ENUM, Ptr{WCHAR}, LENGTH),
          handle, feature, enum, ptr, len)

Command(handle, feature) =
    @call(:AT_Command, STATUS, (HANDLE, FEATURE), handle, feature)

SetString(handle, feature, value) =
    @call(:AT_SetString, STATUS, (HANDLE, FEATURE, Ptr{WCHAR}),
          handle, feature, value)

GetString(handle, feature, buf::DenseVector{WCHAR}) =
    GetString(handle, feature, pointer(buf), length(buf))

GetString(handle, feature, ptr::Ptr{WCHAR}, len::Integer) =
    @call(:AT_GetString, STATUS, (HANDLE, FEATURE, Ptr{WCHAR}, LENGTH),
          handle, feature, ptr, len)

GetStringMaxLength(handle, feature) = begin
    result = Ref{LENGTH}()
    status = @call(:AT_GetStringMaxLength, STATUS,
                   (HANDLE, FEATURE, Ref{LENGTH}),
                   handle, feature, result)
    return status, Int(result[])
end

QueueBuffer(handle, buf::DenseVector{BYTE}) =
    QueueBuffer(handle, pointer(buf), sizeof(buf))

QueueBuffer(handle, ptr::Ptr{BYTE}, siz::Integer) =
    @call(:AT_QueueBuffer, STATUS, (HANDLE, Ptr{BYTE}, LENGTH),
          handle, ptr, siz)

WaitBuffer(handle, timeout::Integer) = begin
    refptr = Ref{Ptr{BYTE}}()
    refsiz = Ref{LENGTH}()
    status = @call(:AT_WaitBuffer, STATUS,
                   (HANDLE, Ref{Ptr{BYTE}}, Ref{LENGTH}, MSEC),
                   handle, refptr, refsiz, timeout)
    return status, refptr[], Int(refsiz[])
end

Flush(handle) = @call(:AT_Flush, STATUS, (HANDLE,), handle)

"""
    widestring(str, len = strlen(str))

yields a vector of wide characters (`Cwchar_t`) with the contents of the string
`str` and properly zero-terminated.  This buffer is independent from the input
string and its contents can be overwritten.  An error is thrown if `str`
contains any embedded NULL characters (which would cause the string to be
silently truncated if the C routine treats NULL as the terminator).

An alternative (without the checking of embedded NULL characters) is:

    push!(transcode(Cwchar_t, str), convert(Cwchar_t, 0))

This method is used to implement the `@L_str` macro which converts a
literal string into a wide character string.  For instance:

    L"EventSelector"

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
    L"text"

yields an array of wide characters.

"""
macro L_str(str)
    :(widestring($str))
end

end
