/*
 * gendeps.c --
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
#ifdef __linux__
# include <fcntl.h>
# include <errno.h>
# include <sys/ioctl.h>
# include <linux/usbdevice_fs.h>
#endif

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
#define DEF_AT_CONST(name, format)  printf("const " #name format "\n", JOIN(AT_,name))

#define _JOIN(a,b) a##b
#define JOIN(a,b) _JOIN(a,b)

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
  puts("#");
  puts("# deps.jl --");
  puts("#");
  puts("# Definitions of types and constants for interfacing Andor cameras in Julia.");
  puts("#");
  puts("# *DO NOT EDIT* as this file is automatically generated for your machine.");
  puts("#");
  puts("#------------------------------------------------------------------------------");
  puts("#");
  puts("# This file is part of \"AndorCameras.jl\" released under the MIT license.");
  puts("#");
  puts("# Copyright (C) 2017-2019, Éric Thiébaut.");
  puts("#");
  printf("\n");
  printf("# Path to the dynamic library.\n");
  printf("const _DLL = \"%s\"\n", AT_DLL);
  printf("\n");
  printf("# Types.\n");
  printf("const STATUS  = Cint     # for returned status\n");
  printf("const HANDLE  = Cint     # AT_H in <atcore.h>\n");
  printf("const INDEX   = Cint     # for camera index\n");
  printf("const ENUM    = Cint     # for enumeration\n");
  printf("const BOOL    = Cint\n");
  printf("const INT     = Int64    # AT_64 in <atcore.h>\n");
  printf("const FLOAT   = Cdouble\n");
  printf("const BYTE    = UInt8    # AT_U8 in <atcore.h>\n");
  printf("const WCHAR   = Cwchar_t # AT_WC in <atcore.h>\n");
  printf("const STRING  = Cwstring\n");
#if 0
  printf("const FEATURE = Cwstring\n");
#else
  printf("const FEATURE = Ptr{WCHAR}\n");
#endif
  printf("const LENGTH  = Cint     # for string length\n");
  printf("const MSEC    = Cuint    # for timeout in milliseconds\n");
  printf("\n");
  printf("# Constants.\n");
#ifdef AT_INFINITE
  DEF_AT_CONST(INFINITE, " = MSEC(0x%X)");
#endif
#ifdef AT_TRUE
  DEF_AT_CONST(TRUE, " = BOOL(%d)");
#endif
#ifdef AT_FALSE
  DEF_AT_CONST(FALSE, " = BOOL(%d)");
#endif
#ifdef AT_HANDLE_UNINITIALISED
  DEF_AT_CONST(HANDLE_UNINITIALISED, " = HANDLE(%d)");
#endif
#ifdef AT_HANDLE_SYSTEM
  DEF_AT_CONST(HANDLE_SYSTEM, " = HANDLE(%d)");
#endif
#ifdef __linux__
  DEF_CONST(USBDEVFS_RESET, " = %u # ioctl() request to reset USB device");
  DEF_CONST(O_WRONLY, " = %u");
#endif
  printf("\n");
  printf("# Status codes.\n");
#ifdef AT_SUCCESS
  DEF_AT_CONST(SUCCESS, " = STATUS(%d)");
#endif
#ifdef AT_CALLBACK_SUCCESS
  DEF_AT_CONST(CALLBACK_SUCCESS, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NOTINITIALISED
  DEF_AT_CONST(ERR_NOTINITIALISED, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NOTIMPLEMENTED
  DEF_AT_CONST(ERR_NOTIMPLEMENTED, " = STATUS(%d)");
#endif
#ifdef AT_ERR_READONLY
  DEF_AT_CONST(ERR_READONLY, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NOTREADABLE
  DEF_AT_CONST(ERR_NOTREADABLE, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NOTWRITABLE
  DEF_AT_CONST(ERR_NOTWRITABLE, " = STATUS(%d)");
#endif
#ifdef AT_ERR_OUTOFRANGE
  DEF_AT_CONST(ERR_OUTOFRANGE, " = STATUS(%d)");
#endif
#ifdef AT_ERR_INDEXNOTAVAILABLE
  DEF_AT_CONST(ERR_INDEXNOTAVAILABLE, " = STATUS(%d)");
#endif
#ifdef AT_ERR_INDEXNOTIMPLEMENTED
  DEF_AT_CONST(ERR_INDEXNOTIMPLEMENTED, " = STATUS(%d)");
#endif
#ifdef AT_ERR_EXCEEDEDMAXSTRINGLENGTH
  DEF_AT_CONST(ERR_EXCEEDEDMAXSTRINGLENGTH, " = STATUS(%d)");
#endif
#ifdef AT_ERR_CONNECTION
  DEF_AT_CONST(ERR_CONNECTION, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NODATA
  DEF_AT_CONST(ERR_NODATA, " = STATUS(%d)");
#endif
#ifdef AT_ERR_INVALIDHANDLE
  DEF_AT_CONST(ERR_INVALIDHANDLE, " = STATUS(%d)");
#endif
#ifdef AT_ERR_TIMEDOUT
  DEF_AT_CONST(ERR_TIMEDOUT, " = STATUS(%d)");
#endif
#ifdef AT_ERR_BUFFERFULL
  DEF_AT_CONST(ERR_BUFFERFULL, " = STATUS(%d)");
#endif
#ifdef AT_ERR_INVALIDSIZE
  DEF_AT_CONST(ERR_INVALIDSIZE, " = STATUS(%d)");
#endif
#ifdef AT_ERR_INVALIDALIGNMENT
  DEF_AT_CONST(ERR_INVALIDALIGNMENT, " = STATUS(%d)");
#endif
#ifdef AT_ERR_COMM
  DEF_AT_CONST(ERR_COMM, " = STATUS(%d)");
#endif
#ifdef AT_ERR_STRINGNOTAVAILABLE
  DEF_AT_CONST(ERR_STRINGNOTAVAILABLE, " = STATUS(%d)");
#endif
#ifdef AT_ERR_STRINGNOTIMPLEMENTED
  DEF_AT_CONST(ERR_STRINGNOTIMPLEMENTED, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_FEATURE
  DEF_AT_CONST(ERR_NULL_FEATURE, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_HANDLE
  DEF_AT_CONST(ERR_NULL_HANDLE, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_IMPLEMENTED_VAR
  DEF_AT_CONST(ERR_NULL_IMPLEMENTED_VAR, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_READABLE_VAR
  DEF_AT_CONST(ERR_NULL_READABLE_VAR, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_READONLY_VAR
  DEF_AT_CONST(ERR_NULL_READONLY_VAR, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_WRITABLE_VAR
  DEF_AT_CONST(ERR_NULL_WRITABLE_VAR, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_MINVALUE
  DEF_AT_CONST(ERR_NULL_MINVALUE, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_MAXVALUE
  DEF_AT_CONST(ERR_NULL_MAXVALUE, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_VALUE
  DEF_AT_CONST(ERR_NULL_VALUE, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_STRING
  DEF_AT_CONST(ERR_NULL_STRING, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_COUNT_VAR
  DEF_AT_CONST(ERR_NULL_COUNT_VAR, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_ISAVAILABLE_VAR
  DEF_AT_CONST(ERR_NULL_ISAVAILABLE_VAR, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_MAXSTRINGLENGTH
  DEF_AT_CONST(ERR_NULL_MAXSTRINGLENGTH, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_EVCALLBACK
  DEF_AT_CONST(ERR_NULL_EVCALLBACK, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_QUEUE_PTR
  DEF_AT_CONST(ERR_NULL_QUEUE_PTR, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_WAIT_PTR
  DEF_AT_CONST(ERR_NULL_WAIT_PTR, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NULL_PTRSIZE
  DEF_AT_CONST(ERR_NULL_PTRSIZE, " = STATUS(%d)");
#endif
#ifdef AT_ERR_NOMEMORY
  DEF_AT_CONST(ERR_NOMEMORY, " = STATUS(%d)");
#endif
#ifdef AT_ERR_DEVICEINUSE
  DEF_AT_CONST(ERR_DEVICEINUSE, " = STATUS(%d)");
#endif
#ifdef AT_ERR_DEVICENOTFOUND
  DEF_AT_CONST(ERR_DEVICENOTFOUND, " = STATUS(%d)");
#endif
#ifdef AT_ERR_HARDWARE_OVERFLOW
  DEF_AT_CONST(ERR_HARDWARE_OVERFLOW, " = STATUS(%d)");
#endif

  return 0;
}
