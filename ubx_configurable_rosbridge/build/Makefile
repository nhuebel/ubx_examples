CC=gcc
CPP=clang++

LIBUBX_CFLAGS=-Wall -Werror -g -ggdb
LIBUBX_CFLAGS_SHARED=-g -ggdb -shared

CFLAGS=-Wall -Werror -g -ggdb -fvisibility=hidden
CFLAGS_SHARED=-g -ggdb -shared

MAKE=make -s

%.h.hexarr: %.h
	../../tools/file2carr.lua $<
	
UBX_INCLUDE_DIR=$(UBX_ROOT)/src
CMAKE_SOURCE_DIR = ../src
CMAKE_BINARY_DIR =$(CURDIR)
# define any directories containing header 
INCLUDES = -I$(UBX_ROOT)/std_types/stdtypes  -I$(UBX_ROOT)/std_blocks -I${UBX_INCLUDE_DIR}

coordinator.so: $(CMAKE_SOURCE_DIR)/coordinator.c $(UBX_INCLUDE_DIR)/ubx.h
	${CC} -ldl ${INCLUDES} $(CFLAGS) $^ -o $@ $(UBX_INCLUDE_DIR)/libubx.so

clean:
	rm -f *.o *~
