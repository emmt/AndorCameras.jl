#
# strings.jl --
#
# Wide-character string functions.
#
#-------------------------------------------------------------------------------
#
# This file is part of "AndorCameras.jl" released under the MIT license.
#
# Copyright (C) 2017, Éric Thiébaut.
#

"""
    widestring(str, len = strlen(str))

yields a vector of wide characters (`Cwchar_t`) with the contents of the
string `str` and properly zero-terminated.  This buffer is independent from
the input string and its contents can be overwritten.  An error is thrown
if `str` contains any embedded NUL characters (which would cause the string
to be silently truncated if the C routine treats NUL as the terminator).

An alternative (without the checking of embedded NUL characters) is:

    push!(transcode(Cwchar_t, str), convert(Cwchar_t, 0))

This method is used to implement the `@L_str` macro which converts a
literal string into a wide character string.  For instance:

    L"EventSelector"

"""
function widestring(str::AbstractString,
                 len::Integer = length(str)) :: Array{WideChar}
    buf = Array{WideChar}(len + 1)
    i = 0
    @inbounds for c in str
        if i ≥ len
            break
        end
        c != '\0' || error("string must not have embedded NUL characters")
        i += 1
        buf[i] = c
    end
    @inbounds while i ≤ len
        i += 1
        buf[i] = zero(WideChar)
    end
    return buf
end

widestring(sym::Symbol) = widestring(string(sym))

function widestringtostring(C::Array{WideChar}) :: String
    buf = Array{Char}(0)
    @inbounds for c in C
        if c == zero(WideChar)
            break
        end
        push!(buf, convert(Char, c))
    end
    return String(buf)
end

macro L_str(str)
    :(widestring($str))
end
