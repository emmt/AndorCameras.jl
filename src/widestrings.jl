#
# widestrings.jl --
#
# Implement strings of wide-characters for Andor SDK.
#
#-------------------------------------------------------------------------------
#
# This file is part of "AndorCameras.jl" released under the MIT license.
#
# Copyright (C) 2017-2021, Éric Thiébaut.
#

module WideStrings

export
    @L_str,
    WideString,
    trunc!

using Base: @propagate_inbounds, containsnul, axes1, OneTo

"""
    wstr = WideString(src, len=length(src))

converts `src` into a wide-character string of length `len`.  Argument `src`
may be a string, a symbol, a vector of `Char`, or a vector of `Cwchar_t`.

Wide-character strings are immutable (read-only) vectors of characters of type
`Cwchar_t`.  They are NUL-terminated and do not contain other NUL characters
than the final NUL.  They are intended to be passed to functions in external
C-library expecting NUL-terminated strings of `wchar_t` characters.

An exception is thrown if `src` contains a NULL in its first `len` elements.
Call `trunc(WideString,src)` to build a wide-character string from `src` but
that may be truncated at the first NUL character.  If `buf` is an ordinary
vector of wide-character, re-allocation can be avoded by calling
`trunc!(WideString,buf)`.

A wide-character string `wstr` can be converted to an ordinary Julia string by:

    str = String(wstr)

See also: [`@L`], [`trunc!`].

"""
struct WideString <: AbstractVector{Cwchar_t}
    buf::Vector{Cwchar_t}
end

buffer(str::WideString) = str.buf
Base.length(str::WideString) = length(buffer(str)) - 1
Base.size(str::WideString) = (length(str),)
Base.axes1(str::WideString) = Base.OneTo(length(str))
Base.axes(str::WideString) = (Base.axes1(str),)
Base.IndexStyle(::Type{WideString}) = IndexLinear()
Base.cconvert(::Type{Cwstring}, str::WideString) = buffer(str)
Base.unsafe_convert(::Type{Ptr{Cwchar_t}}, str::WideString) =
    pointer(buffer(str))

function Base.show(io::IO, str::WideString)
    @inbounds for c in str
        print(io, Char(c))
    end
end

function Base.show(io::IO, ::MIME"text/plain", str::WideString)
    q = Cwchar_t('"')
    print(io, "L\"")
    @inbounds for c in str
        if c == q
            print(io, "\\\"")
        else
            print(io, Char(c))
        end
    end
    print(io, "\"")
end

@inline Base.getindex(str::WideString, i::Integer) = begin
    buf = buffer(str)
    @boundscheck ((1 ≤ i) & (i < length(buf))) || out_of_range_index(str, i)
    @inbounds buf[i]
end

Base.string(str::WideString) = String(str)

function Base.String(str::WideString)
    buf = Vector{Char}(undef, length(str))
    @inbounds @simd for i in eachindex(buf, str)
        buf[i] = Char(str[i])
    end
    return String(buf)
end

function Base.trunc(::Type{WideString},
                    src::Union{AbstractString,
                               AbstractVector{<:Union{Char,Cwchar_t}}})
    buf = Vector{Cwchar_t}(undef, length(src) + 1)
    len = 0
    @inbounds for c in src
        if c == nul(c)
            resize!(buf, len + 1)
            break
        end
        len += 1
        buf[len] = Cwchar_t(c)
    end
    buf[end] = nul(Cwchar_t)
    return WideString(buf)
end

"""
    trunc!(WideString, buf)

yields a wide-character string truncated at the first NUL found in array `buf`
and that uses `buf` (possibly resized and NUL-terminated) as its storing
buffer.  The caller shall not change `buf` after this call.

"""
function trunc!(::Type{WideString}, buf::Vector{Cwchar_t})
    len = length(buf)
    @inbounds for i in OneTo(len)
        c = buf[i]
        if c == nul(c)
            len = i - 1
            break
        end
    end
    length(buf) == len + 1 || resize!(buf, len + 1)
    buf[end] = nul(Cwchar_t)
    return WideString(buf)
end

nul(x::Union{Char,Cwchar_t}) = nul(typeof(x))
nul(::Type{Char}) = '\0'
nul(::Type{Cwchar_t}) = zero(Cwchar_t)

# Extend convert for building structures.
Base.convert(::Type{String}, x::WideString) = String(x)
Base.convert(::Type{WideString}, x::Union{AbstractString,Symbol}) =
    WideString(x)

WideString(str::WideString) = str

WideString(sym::Symbol) = WideString(string(sym))

# Compared to `transcode(Cwchar_t,str)`, `WideString(str)` adds a final NUL
# character and make sure `str` does not contain any NUL characters.
function WideString(src::Union{AbstractString,
                               AbstractVector{<:Union{Char,Cwchar_t}}})
    return unsafe_WideString(src, length(src))
end

function WideString(src::Union{AbstractString,
                               AbstractVector{<:Union{Char,Cwchar_t}}},
                    len::Integer)
    0 ≤ len ≤ length(src) || throw(ArgumentError("invalid length"))
    return unsafe_WideString(src, Int(len))
end

function unsafe_WideString(src, len::Int)
    buf = Vector{Cwchar_t}(undef, len + 1)
    j = firstindex(src)
    @inbounds for i in 1:len
        c = src[j]
        c == nul(c) &&
            throw(ArgumentError("argument must not contain NULs"))
        buf[i] = Cwchar_t(c)
        j = nextind(src, j)
    end
    buf[end] = nul(Cwchar_t)
    return WideString(buf)
end

"""
    L"text"

yields a wide-character string.

"""
macro L_str(str)
    :(WideString($str))
end

end # module
