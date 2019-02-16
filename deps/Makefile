#
# Makefile --
#
# Rules to extract constants from the Andor cameras SDK.
#
#-------------------------------------------------------------------------------
#
# This file is part of `AndorCameras.jl` released under the MIT license.
#
# Copyright (C) 2017-2019, Éric Thiébaut.
#

srcdir = .

# Macros for compiling with Andor SDK
AT_DIR = /usr/local/andor
AT_LIBDIR = $(AT_DIR)/lib
AT_INCDIR = $(AT_DIR)/include

AT_DEFS =  -I$(AT_INCDIR)
AT_DLL = $(AT_DIR)/lib/libatcore.so
AT_LIBS = -L$(AT_LIBDIR) -latcore

USB_DEFS =
USB_LIBS = -lusb

PIC_FLAGS = -fPIC
CC = gcc
CPPFLAGS = -I.
CFLAGS = -O2 -Wall
LDFLAGS =

default: deps.jl

clean:
	rm -f *~ *.o genconst genconst.out

all: deps.jl reset-zyla

deps.jl: genconst.out gendeps.sh
	rm -f "$@"
	./gendeps.sh genconst.out "$@"
	chmod a-w "$@"

reset-zyla: $(srcdir)/reset-zyla.c
	$(CC) $(CPPFLAGS) $(USB_DEFS) $(CFLAGS) $< -o $@  $(USB_LIBS)

genconst.out: genconst
	./genconst >genconst.out

genconst: genconst.c Makefile
	$(CC) $(CPPFLAGS) $(AT_DEFS) $(CFLAGS) \
	    -DAT_DLL=\"$(AT_DLL)\" $< -o $@
