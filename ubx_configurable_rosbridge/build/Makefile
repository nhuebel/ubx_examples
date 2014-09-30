CC=gcc
CPP=clang++

LIBUBX_CFLAGS=-Wall -Werror -g -ggdb
LIBUBX_CFLAGS_SHARED=-g -ggdb -shared

CFLAGS=-Wall -Werror -g -ggdb -fvisibility=hidden
CFLAGS_SHARED=-g -ggdb -shared

MAKE=make -s

%.h.hexarr: %.h
	../../tools/file2carr.lua $<

	
#ROOT_DIR=$(CURDIR)/..
ROOT_DIR=$(CURDIR)
INCLUDE_DIR=$(UBX_ROOT)/src
CMAKE_SOURCE_DIR = /home/nhuebel/projects/microblx/ubx_examples/ubx_configurable_rosbridge/src
CMAKE_BINARY_DIR =/home/nhuebel/projects/microblx/ubx_examples/ubx_configurable_rosbridge/build

coordinator.so: $(CMAKE_SOURCE_DIR)/coordinator.c $(INCLUDE_DIR)/ubx.h
	${CC} -ldl -I$(INCLUDE_DIR) $(CFLAGS) $^ -o $@ $(INCLUDE_DIR)/libubx.so

clean:
	rm -f coordinator *.o *~ core
