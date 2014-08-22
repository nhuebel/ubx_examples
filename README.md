Tutorial: Create a simple composition in ubx
========================

This tutorial explains the coposition of a computational and an interaction block in the ubx framework. The composition has the behaviour of a random walk block. The computational block is creating a random value (distribution can be configured) and modifies the value stored in the interaction block. The interaction block is offering the current value of teh random walk to the outside.

This tutorial is partly based on https://github.com/maccradar/ubx/tree/master/cpp_transfer.

Issues:
--------
* no distinction of blocktype!
* do blocks have to provide init and cleanup functions?
* generate everything with metadata
* how to allocate size of data in init/configuration?

Prerequisites
-------------

### Install ubx dependencies: luajit, libluajit-5.1-dev, clang++, clang
```sh
~/projects/microblx$ sudo apt-get install luajit, libluajit-5.1-dev, clang
```
### Install ubx and follow instructions at http://ubxteam.github.io/quickstart/

```sh
~/projects/microblx$ git clone https://github.com/UbxTeam/microblx.git
~/projects/microblx$ cd microblx
```

### Install ubx cmake:

```sh
~/projects/microblx$ git clone https://github.com/haianos/microblx_cmake.git
```
### Set some environment variables and run the env.sh script (e.g. in your .bashrc):

```sh
export UBX_ROOT=~/projects/microblx
export UBX_MODULES=~/projects/microblx/install/lib/microblx
source $UBX_ROOT/env.sh
```

Generating a package
--------------------

### Create a folder for your package 
```sh
mkdir random_walk
cd random_walk
```

### Create a model description for the ubx package. The package contains a set of blocks and types, required in your application.

```sh
~/projects/microblx/random_walk$ gedit random_walk.pkg
return pkg
{
  name="random_walk",
  path="../",

  dependencies = {
-- no dependencies...
  },

  types = {
-- define the data type you want to share, e.g. a struct cpp_data
    { name="vector", dir="types" },
    { name="distribution", dir="types" },
    { name="value", dir="types" },
  },

  blocks = {
-- define the blocks of your package, e.g. a sender and a receiver block
    { name="store_value", file="random_walk_iblock.blx", src_dir="src" },
    { name="modify_value", file="random_walk_cblock.blx", src_dir="src" },
  },

  libraries = {
-- define the libraries. Preferably 1 library per block
    { name="random_walk_iblock", blocks={"store_value"} },
    { name="random_walk_cblock", blocks={"modify_value"} },
  },
}
```

### Create the block descriptions.

```sh
~/projects/microblx/random_walk$ gedit random_walk_cblock.blx
return block 
{
      name="random_walk_cblock",
      meta_data="cblock modifying the random_walk_iblock according to configured distribution",
      port_cache=true,

      types = {
	 { name="vector", class='struct' }, -- Enum will follow once implemented in C
	 { name="distribution", class='struct' },
      },

      configurations= {
	 { name="distribution", type_name="double", len=5 },
      },

      ports = {
	 { name="change", out_type_name="vector", out_data_len=1, doc="change of the value of the random walk" },
      },
      
      operations = { start=true, stop=true, step=true },

      cpp = true
}

~/projects/microblx/random_walk$ gedit random_walk_iblock.blx
return block 
{
      name="random_walk_iblock",
      meta_data="storing the value of the random walk",
      port_cache=true,

      types = {
	 { name="vector", class='struct' }, -- Enum will follow once implemented in C
	 { name="value", class='struct' }
      },

      configurations= {
	 { name="init_value", type_name="value", len=1 },
      },

      ports = {
	 { name="change", in_type_name="vector", in_data_len=1, doc="change of the stored value" },
	 { name="value", out_type_name="value", doc="current value of the random walk" },
      },
      
      operations = { start=true, stop=true, step=false },

      cpp = true
}
```

Note: the flag "cpp = true" is used to generate .cpp and .hpp files instead of .c and .h files.

### Copy the `templates` and `models` folder from the as well as the `ubx_genblock.lua` and `generate_pkg.lua` from `microblx_cmake` into your `random_walk` folder. This step is only necessary if you want to have your package outside of the microblx_cmake folder. 

### Generate the package!
```sh
~/projects/microblx/random_walk$ ./generate_pkg.lua -force -s random_walk.pkg
missing output directory (-d), using default from model
    generating ..//random_walk/src/random_walk_iblock.hpp
    generating ..//random_walk/src/random_walk_iblock.cpp
    generating ..//random_walk/src/random_walk_iblock.usc
    generating ..//random_walk/src/random_walk_cblock.hpp
    generating ..//random_walk/src/random_walk_cblock.cpp
    generating ..//random_walk/src/random_walk_cblock.usc
    export models in ..//random_walk/models
```

Note:
* The -s option tells the script that there is a package description file (here: random_walk.pkg) 
* If the -d option is omitted, the script will use the directory defined in the model.

Implement ubx types and blocks
------------------------------

In this step you have to fill in the generated stubs for your types and blocks.


### Implement the types

First, have a look at the types directory and the generated header files (one for each type you defined).
In our example, two files have been generated:

```sh
~/workspace/microblx_cmake$ cd ../cpp_transfer/types/
~/workspace/cpp_transfer/types$ ls
cpp_data.h  cpp_transfer_types.c
```
The cpp_data.h file defines the model implementation of the type you want to share between ubx blocks, while the cpp_transfer_types.c file defines ubx functions to register all the types in this directory. The former still requires some editing, while the latter should be fine in most cases.

```sh
~/workspace/cpp_transfer/types$ vim cpp_data.h 
/* generated type stub, extend this struct with real information */

struct cpp_data {
	/* This should be generated in the future */
        const char model[20]; // This should be a URL to the data model
	const char uid[10]; // This should be a unique id to identify this data type
	const char meta_model[20]; // This should be a URL to the meta model
	const char data[10]; // the actually data. In our example, just 10 random characters.
};
```

### Implement the blocks

In this very basic example, we will only edit the step function of the sender and receiver block and set the license at the top

```sh
UBX_MODULE_LICENSE_SPDX(BSD)

...

/* step */
void cpp_sender_step(ubx_block_t *b)
{
        struct cpp_sender_info *inf = (struct cpp_sender_info*) b->private_data;
	/* get cpp object here and convert it to c data array */
	struct cpp_data data;
	strcpy(data.model, "image array");
	strcpy(data.uid,"image");
	strcpy(data.meta_model,"c array");
	strcpy(data.data,"test_data");

	write_output(inf->ports.output, &data);
}
```

In the receiver block we also include iostream

```sh
#include <iostream>
using namespace std;

UBX_MODULE_LICENSE_SPDX(BSD)

...

/* step */
void cpp_receiver_step(ubx_block_t *b)
{
        struct cpp_receiver_info *inf = (struct cpp_receiver_info*) b->private_data;
	struct cpp_data dat;
	read_input(inf->ports.input, &dat);
	cout << "MODEL: " << dat.model << endl;
	cout << "UID: " << dat.uid << endl;
	cout << "META MODEL: " << dat.meta_model << endl;
	cout << "DATA: " << dat.data << endl;

}
```

Note: At the moment, there is still a problem with type registration and to avoid runtime errors remove in either cpp_sender.hpp or cpp_receiver.hpp the type definition:

From:

```sh
ubx_type_t types[] = {
        def_struct_type(struct cpp_data, &cpp_data_h),
        { NULL },
};
```

To:

```sh
ubx_type_t types[] = {};
```

### Build with CMAKE

Note: In ccmake, set the install path of your package libraries. E.g. ~/workspace/install

```sh
~/workspace/cpp_transfer$ mkdir build && cd build/
~/workspace/cpp_transfer/build$ cmake ../
~/workspace/cpp_transfer/build$ ccmake ../
~/workspace/cpp_transfer/build$ make
[ 25%] Built target gen_hexarr
[ 50%] Building CXX object CMakeFiles/cpp_receiver.dir/src/cpp_receiver.cpp.o
Linking CXX shared library cpp_receiver.so
[ 50%] Built target cpp_receiver
[ 75%] Building CXX object CMakeFiles/cpp_sender.dir/src/cpp_sender.cpp.o
Linking CXX shared library cpp_sender.so
[ 75%] Built target cpp_sender
Scanning dependencies of target cpp_transfer_types
[100%] Building C object CMakeFiles/cpp_transfer_types.dir/types/cpp_transfer_types.c.o
Linking C shared library cpp_transfer_types.so
[100%] Built target cpp_transfer_types
~/workspace/cpp_transfer/build$ make install
[ 25%] Built target gen_hexarr
[ 50%] Built target cpp_receiver
[ 75%] Built target cpp_sender
[100%] Built target cpp_transfer_types
Install the project...
-- Install configuration: ""
-- Installing: /home/jphilips/workspace/install/lib/microblx/types/cpp_transfer_types.so
-- Set runtime path of "/home/jphilips/workspace/install/lib/microblx/types/cpp_transfer_types.so" to "/home/jphilips/workspace/microblx/src"
-- Installing: /home/jphilips/workspace/install/include/microblx/types/cpp_data.h.hexarr
-- Installing: /home/jphilips/workspace/install/include/microblx/types/cpp_data.h
-- Installing: /home/jphilips/workspace/install/lib/microblx/blocks/cpp_sender.so
-- Set runtime path of "/home/jphilips/workspace/install/lib/microblx/blocks/cpp_sender.so" to "/home/jphilips/workspace/microblx/src"
-- Installing: /home/jphilips/workspace/install/share/microblx/cmake/cpp_sender-block.cmake
-- Installing: /home/jphilips/workspace/install/share/microblx/cmake/cpp_sender-block-noconfig.cmake
-- Installing: /home/jphilips/workspace/install/lib/microblx/blocks/cpp_receiver.so
-- Set runtime path of "/home/jphilips/workspace/install/lib/microblx/blocks/cpp_receiver.so" to "/home/jphilips/workspace/microblx/src"
-- Installing: /home/jphilips/workspace/install/share/microblx/cmake/cpp_receiver-block.cmake
-- Installing: /home/jphilips/workspace/install/share/microblx/cmake/cpp_receiver-block-noconfig.cmake
```

Running the example
-------------------

### Create USC script

First we need to create a script to load all the blocks and connect the correct ports

```sh
~/workspace/cpp_transfer$ vim cpp_transfer.usc
-- -*- mode: lua; -*-

return bd.system {
   imports = {
      "std_types/stdtypes/stdtypes.so",
      "std_blocks/ptrig/ptrig.so",
      "std_blocks/lfds_buffers/lfds_cyclic.so",
      "std_blocks/hexdump/hexdump.so",
      "blocks/cpp_sender.so",
      "blocks/cpp_receiver.so",
   },
   
   blocks = {
      {name="ptrig1", type="std_triggers/ptrig"},
      {name="fifo1", type="lfds_buffers/cyclic"},
      {name="cpp_sender1", type="cpp_sender"},
      {name="cpp_receiver1", type="cpp_receiver"},
   },
   
   connections = {
-- connect the cpp_sender block with the cpp_receiver block through a fifo block
      {src="cpp_sender1.output", tgt="fifo1"},
      {src="fifo1", tgt="cpp_receiver1.input"},
   },
   
   configurations = {
      { name="fifo1", config={type_name="struct cpp_data", buffer_len=1}},
      { name="ptrig1", config={period={sec=1,usec=0}, trig_blocks={{b="#cpp_sender1", num_steps=1, measure=0},
                                                                   {b="#cpp_receiver1", num_steps=1, measure=0}}}}
   },
}
```

### Create launch script (optional)

Next, we can define a launch script

```sh
~/workspace/cpp_transfer$ vim run.sh
#!/bin/bash
exec $UBX_ROOT/tools/ubx_launch -webif 8888 -c cpp_transfer.usc
```

### Launch the application!

Now, start ubx!

```sh
~/workspace/cpp_transfer$ ./run.sh
LuaJIT 2.0.2 -- Copyright (C) 2005-2013 Mike Pall. http://luajit.org/
Environment setup...
    UBX_ROOT: /home/jphilips/workspace/microblx
    UBX_MODULES: /home/jphilips/workspace/install/lib/microblx
importing 6 modules... 
    /home/jphilips/workspace/microblx/std_types/stdtypes/stdtypes.so
    /home/jphilips/workspace/microblx/std_blocks/ptrig/ptrig.so
    /home/jphilips/workspace/microblx/std_blocks/lfds_buffers/lfds_cyclic.so
    /home/jphilips/workspace/microblx/std_blocks/hexdump/hexdump.so
    /home/jphilips/workspace/install/lib/microblx/blocks/cpp_sender.so
    /home/jphilips/workspace/install/lib/microblx/blocks/cpp_receiver.so
importing modules completed
instantiating 4 blocks... 
    ptrig1 [std_triggers/ptrig]
    fifo1 [lfds_buffers/cyclic]
    cpp_sender1 [cpp_sender]
    cpp_receiver1 [cpp_receiver]
instantiating blocks completed
launching block diagram system in node node-20140414_111110
    preprocessing configs
    resolved block #cpp_sender1
    resolved block #cpp_receiver1
configuring 2 blocks... 
    fifo1 with {buffer_len=1,type_name="struct cpp_data"})
    ptrig1 with {trig_blocks={{b=cpp_sender1 (type=cblock, state=preinit, prototype=cpp_sender),num_steps=1,measure=0},{b=cpp_receiver1 (type=cblock, state=preinit, prototype=cpp_receiver),num_steps=1,measure=0}},period={usec=0,sec=1}})
ptrig_handle_config: ptrig1 config: period=1s:0us, policy=SCHED_OTHER, prio=0, stacksize=0 (0=default size)
configuring blocks completed
creating 2 connections... 
    cpp_sender1.output -> fifo1 (iblock)
    fifo1 (iblock) -> cpp_receiver1.input
creating connections completed
starting up webinterface block (port: 8888)
loaded request_handler()
JIT: ON CMOV SSE2 SSE3 SSE4.1 fold cse dce fwd dse narrow loop abc sink fuse
> 
```

- Browse to http://localhost:8888 to start the blocks...
- Init and start the cpp_receiver1 and cpp_sender1 block
- Init and start the ptrig1 block

If all is well, you should receive following output:
```sh
...
MODEL: image array
UID: image
META MODEL: c array
DATA: test_data
MODEL: image array
UID: image
META MODEL: c array
DATA: test_data
MODEL: image array
UID: image
META MODEL: c array
DATA: test_data
...
```


