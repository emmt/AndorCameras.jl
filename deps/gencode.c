/*
 * gencode.c --
 *
 * Generate definitions of types and constants for interfacing Andor (SDK)
 * with Julia.
 *
 *------------------------------------------------------------------------------
 *
 * This file is part of "AndorCameras.jl" released under the MIT license.
 *
 * Copyright (C) 2017, Éric Thiébaut.
 */

#include <stdio.h>
#include <stdint.h>
#include <wchar.h>
#include <atcore.h>

#if 0
/* Define a constant. */
static void _define(const char* type, const char* name,
                    int value, const char* comment)
{
  if (comment == NULL || comment[0] == '\0') {
    printf("const %s = %s(0x%08X)\n", name, type, value);
  } else {
    printf("const %s = %s(0x%08X) # %s\n", name, type, value, comment);
  }
}
#endif

/* Will use the following macro to allow for macro argument expansion. */
#define define(typ, cst, com) _define(typ, #cst, cst, com)

#define alias_uint(nam, typ)  printf("const %s = UInt%d # %s\n",          \
                                     nam, (int)sizeof(typ)*8, #typ)

#define alias_enum(nam, typ)  printf("const %s = Cint # %s\n", nam, #typ)

/* Determine the offset of a field in a structure. */
#define OFFSET_OF(type, field) ((char*)&((type*)0)->field - (char*)0)

/* Determine whether an integer type is signed. */
#define IS_SIGNED(type)        ((type)(~(type)0) < (type)0)

/* Set all the bits of an L-value. */
#define SET_ALL_BITS(lval) lval = 0; lval = ~lval

/* Define a Julia constant. */
#define DEF_CONST(name, format)  printf("const " #name format "\n", name)

/* Define a Julia alias for a C integer, given an L-value of the corresponding
 * type. */
#define DEF_TYPEOF_LVALUE(name, lval)           \
  do {                                          \
    SET_ALL_BITS(lval);                         \
    printf("const _typeof_%s = %sInt%u\n",      \
           name, (lval < 0 ? "" : "U"),         \
           (unsigned)(8*sizeof(lval)));         \
                                                \
  } while (0)

/* Define a Julia alias for a C integer, given its type (`space` is used for
 * alignment). */
#define DEF_TYPEOF_TYPE(type, space)            \
  do {                                          \
    type lval;                                  \
    SET_ALL_BITS(lval);                         \
    printf("const _typeof_%s%s = %sInt%u\n",    \
           #type, space, (lval < 0 ? "" : "U"), \
           (unsigned)(8*sizeof(lval)));         \
                                                \
  } while (0)

/* Define a Julia constant with the offset (in bytes) of a field of a
 * C-structure. */
#define DEF_OFFSETOF(ident, type, field)                \
  printf("const _offsetof_" ident " = %3ld\n", \
          (long)OFFSET_OF(type, field))

/* Define a Julia constant with the size of a given C-type. */
#define DEF_SIZEOF_TYPE(name, type)             \
  printf("const _sizeof_%s = %3lu\n",           \
         name, (unsigned long)sizeof(type))

int main(int argc, char* argv[])
{
  printf("const _DLL = \"%s\"\n", AT_DLL);
  printf("const AT_STATUS  = Cint     # for returned status\n");
  printf("const AT_HANDLE  = Cint     # AT_H in <atcore.h>\n");
  printf("const AT_INDEX   = Cint     # for camera index\n");
  printf("const AT_ENUM    = Cint     # for enumeration\n");
  printf("const AT_BOOL    = Cint\n");
  printf("const AT_INT     = Int64    # AT_64 in <atcore.h>\n");
  printf("const AT_FLOAT   = Cdouble\n");
  printf("const AT_BYTE    = UInt8    # AT_U8 in <atcore.h>\n");
  printf("const AT_CHAR    = Cwchar_t # AT_WC in <atcore.h>\n");
  printf("const AT_STRING  = Cwstring\n");
  printf("const AT_FEATURE = Cwstring\n");
  printf("const AT_LENGTH  = Cint     # for string length\n");
  printf("const AT_MSEC    = Cuint    # for timeout in milliseconds\n");
#ifdef AT_INFINITE
  DEF_CONST(AT_INFINITE, " = AT_MSEC(0x%X)");
#endif
#ifdef AT_TRUE
  DEF_CONST(AT_TRUE, " = AT_BOOL(%d)");
#endif
#ifdef AT_FALSE
  DEF_CONST(AT_FALSE, " = AT_BOOL(%d)");
#endif
#ifdef AT_SUCCESS
  DEF_CONST(AT_SUCCESS, " = AT_STATUS(%d)");
#endif
#ifdef AT_CALLBACK_SUCCESS
  DEF_CONST(AT_CALLBACK_SUCCESS, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NOTINITIALISED
  DEF_CONST(AT_ERR_NOTINITIALISED, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NOTIMPLEMENTED
  DEF_CONST(AT_ERR_NOTIMPLEMENTED, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_READONLY
  DEF_CONST(AT_ERR_READONLY, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NOTREADABLE
  DEF_CONST(AT_ERR_NOTREADABLE, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NOTWRITABLE
  DEF_CONST(AT_ERR_NOTWRITABLE, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_OUTOFRANGE
  DEF_CONST(AT_ERR_OUTOFRANGE, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_INDEXNOTAVAILABLE
  DEF_CONST(AT_ERR_INDEXNOTAVAILABLE, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_INDEXNOTIMPLEMENTED
  DEF_CONST(AT_ERR_INDEXNOTIMPLEMENTED, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_EXCEEDEDMAXSTRINGLENGTH
  DEF_CONST(AT_ERR_EXCEEDEDMAXSTRINGLENGTH, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_CONNECTION
  DEF_CONST(AT_ERR_CONNECTION, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NODATA
  DEF_CONST(AT_ERR_NODATA, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_INVALIDHANDLE
  DEF_CONST(AT_ERR_INVALIDHANDLE, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_TIMEDOUT
  DEF_CONST(AT_ERR_TIMEDOUT, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_BUFFERFULL
  DEF_CONST(AT_ERR_BUFFERFULL, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_INVALIDSIZE
  DEF_CONST(AT_ERR_INVALIDSIZE, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_INVALIDALIGNMENT
  DEF_CONST(AT_ERR_INVALIDALIGNMENT, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_COMM
  DEF_CONST(AT_ERR_COMM, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_STRINGNOTAVAILABLE
  DEF_CONST(AT_ERR_STRINGNOTAVAILABLE, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_STRINGNOTIMPLEMENTED
  DEF_CONST(AT_ERR_STRINGNOTIMPLEMENTED, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_FEATURE
  DEF_CONST(AT_ERR_NULL_FEATURE, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_HANDLE
  DEF_CONST(AT_ERR_NULL_HANDLE, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_IMPLEMENTED_VAR
  DEF_CONST(AT_ERR_NULL_IMPLEMENTED_VAR, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_READABLE_VAR
  DEF_CONST(AT_ERR_NULL_READABLE_VAR, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_READONLY_VAR
  DEF_CONST(AT_ERR_NULL_READONLY_VAR, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_WRITABLE_VAR
  DEF_CONST(AT_ERR_NULL_WRITABLE_VAR, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_MINVALUE
  DEF_CONST(AT_ERR_NULL_MINVALUE, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_MAXVALUE
  DEF_CONST(AT_ERR_NULL_MAXVALUE, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_VALUE
  DEF_CONST(AT_ERR_NULL_VALUE, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_STRING
  DEF_CONST(AT_ERR_NULL_STRING, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_COUNT_VAR
  DEF_CONST(AT_ERR_NULL_COUNT_VAR, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_ISAVAILABLE_VAR
  DEF_CONST(AT_ERR_NULL_ISAVAILABLE_VAR, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_MAXSTRINGLENGTH
  DEF_CONST(AT_ERR_NULL_MAXSTRINGLENGTH, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_EVCALLBACK
  DEF_CONST(AT_ERR_NULL_EVCALLBACK, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_QUEUE_PTR
  DEF_CONST(AT_ERR_NULL_QUEUE_PTR, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_WAIT_PTR
  DEF_CONST(AT_ERR_NULL_WAIT_PTR, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_PTRSIZE
  DEF_CONST(AT_ERR_NULL_PTRSIZE, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_NOMEMORY
  DEF_CONST(AT_ERR_NOMEMORY, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_DEVICEINUSE
  DEF_CONST(AT_ERR_DEVICEINUSE, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_DEVICENOTFOUND
  DEF_CONST(AT_ERR_DEVICENOTFOUND, " = AT_STATUS(%d)");
#endif
#ifdef AT_ERR_HARDWARE_OVERFLOW
  DEF_CONST(AT_ERR_HARDWARE_OVERFLOW, " = AT_STATUS(%d)");
#endif
#ifdef AT_HANDLE_UNINITIALISED
  DEF_CONST(AT_HANDLE_UNINITIALISED, " = AT_HANDLE(%d)");
#endif
#ifdef AT_HANDLE_SYSTEM
  DEF_CONST(AT_HANDLE_SYSTEM, " = AT_HANDLE(%d)");
#endif

  return 0;
}
