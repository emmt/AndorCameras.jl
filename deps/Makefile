#
# Makefile --
#
# Rules to extract constants from the Andor cameras SDK.
#
#-------------------------------------------------------------------------------
#
# This file is part of `AndorCameras.jl` released under the MIT license.
#
# Copyright (C) 2017, Éric Thiébaut.
#

srcdir = .

# Macros for compiling with Andor SDK
AT_DIR = /usr/local
AT_LIBDIR = $(AT_DIR)/lib
AT_INCDIR = $(AT_DIR)/include/andor

AT_DEFS =  -I$(AT_INCDIR)
AT_DLL = $(AT_LIBDIR)/libatcore.so
AT_LIBS = -L$(AT_LIBDIR) -latcore

PIC_FLAGS = -fPIC
CC = gcc
CPPFLAGS = -I.
CFLAGS = -O2 -Wall
LDFLAGS =

default: all

clean:
	rm -f *~ *.o gencode

all: $(srcdir)/../src/constants.jl

$(srcdir)/../src/constants.jl: gencode gencode.sh
	rm -f "$@"
	./gencode.sh "$@"
	chmod a-w "$@"

gencode: gencode.c Makefile
	$(CC) $(CPPFLAGS) $(AT_DEFS) $(CFLAGS) \
	    -DAT_DLL=\"$(AT_DLL)\" $< -o $@
