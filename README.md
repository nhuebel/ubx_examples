=======
ubx_random_walk
===============

This repository contains a random walk implementation for the microblx framework.


Prerequisites
-------------
Have microblx set up properly. More information can be found [here](http://ubxteam.github.io/quickstart/).


Generating a package
--------------------

### Get the code
```sh
git clone https://github.com/nhuebel/ubx_random_walk.git
```

### Create a model description for the ubx package. The package contains a set of blocks and types, required in your application.

```sh
~/projects/microblx/random_walk$ gedit random_walk.pkg
return pkg
{
  name="random_walk",
  path="../",

  types = {
    { name="distribution_name", dir="types" },
    { name="var_array_values", dir="types" },
  },

  blocks = {
    { name="random_walk_iblock", file="random_walk_iblock.blx", src_dir="src" },
    { name="random_walk_cblock", file="random_walk_cblock.blx", src_dir="src" },
  },

  modules = {
    { name="mod_random_walk_iblock", blocks={"random_walk_iblock"} },
    { name="mod_random_walk_cblock", blocks={"random_walk_cblock"} },
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
	 { name="var_array_values", class='struct' }, -- Enum will follow once implemented in C
	 { name="distribution_name", class='struct' },
      },

      configurations= {
	 { name="distribution", type_name="struct distribution_name", len=1 },
	 { name="datacopy", type_name="short", len=1 },
      },

      ports = {
	 { name="new_value", out_type_name="struct var_array_values", out_data_len=1, in_type_name="struct var_array_values", in_data_len=1, doc="change of the value of the random walk" },
      },
      
      operations = { start=true, stop=true, step=true },

      cpp = false
}

~/projects/microblx/random_walk$ gedit random_walk_iblock.blx
return iblock 
{
      name="random_walk_iblock",
      meta_data="storing the value of the random walk",
      port_cache=true,

      types = {
	 { name="var_array_values", class='struct' },
      },

      configurations= {
	 { name="init_value", type_name="struct var_array_values", len=1 },
      },

      ports = {
	 { name="new_value", in_type_name="struct var_array_values", in_data_len=1, doc="update of the stored value" },
	 { name="stored_value", out_type_name="struct var_array_values", doc="current value of the random walk" },
      },
      
      operations = { read=true, write=true },

      cpp = false
}
```

### Generate the package!
```sh
$ ./generate_pkg.lua -s random_walk.pkg
missing output directory (-d), using default from model
    generating ..//random_walk/src/random_walk_iblock.h
    generating ..//random_walk/src/random_walk_iblock.c
    generating ..//random_walk/src/random_walk_iblock.usc
    generating ..//random_walk/src/random_walk_cblock.h
    generating ..//random_walk/src/random_walk_cblock.c
    generating ..//random_walk/src/random_walk_cblock.usc
    generating ..//random_walk/modules/mod_random_walk_iblock_module.h
    generating ..//random_walk/modules/mod_random_walk_iblock_module.c
    generating ..//random_walk/modules/mod_random_walk_cblock_module.h
    generating ..//random_walk/modules/mod_random_walk_cblock_module.c
    export models in ..//random_walk/models
```

Implement ubx types and blocks
------------------------------

In this step you have to fill in the generated stubs for your types and blocks.


### Implement the types
```sh
~/projects/microblx/random_walk/types$ gedit distribution_name.h
/* generated type stub, extend this struct with real information */

struct distribution_name {

    char model[20]; // This should be a URL to the data model
    char uid[20]; // This should be a unique id to identify this data type
    char meta_model[20]; // This should be a URL to the meta model
    char dirstr_name[20]; // the actually data. In our example, the name of the distribution
    int seed; //seed for the random number generator
    float max_step_size; // max step size that the random_walk is allowed to do
};

~/projects/microblx/random_walk/types$ gedit var_array_values.h
/* generated type stub, extend this struct with real information */

struct var_array_values {
    char model[20]; // This should be a URL to the data model
    char uid[20]; // This should be a unique id to identify this data type
    char meta_model[20]; // This should be a URL to the meta model
    unsigned int value_arr_len; // the length of the array containing the values
    float *value_arr; // pointer to the actual data
};
```

### Implement the blocks
In `random_walk_cblock.h` add `#include <stdlib.h>` to be able to use the pseudo random number generator. Also add the missing read and write function from/to the port and/or the getdata function: see files on github

In `random_walk_cblock.c` edit the following: see files on github

In `random_walk_iblock.c` fill in the `init` and `cleanup` function and add the `read`, `write`, and `get_data_pointer` functions that are currently not autogenerated. See files on github.

In `random_walk_iblock.h` edit the block data as follows (change type, add read+write):
```sh
/* put everything together */
ubx_block_t random_walk_iblock_block = {
        .name = "random_walk_iblock",
        .type = BLOCK_TYPE_INTERACTION,
        .meta_data = random_walk_iblock_meta,
        .configs = random_walk_iblock_config,
        .ports = random_walk_iblock_ports,

        /* ops */
        .init = random_walk_iblock_init,
        .cleanup = random_walk_iblock_cleanup,
        .write = random_walk_iblock_write,
        .read= random_walk_iblock_read,
        .getdata = get_data_pointer,
};
```
and add the read and write functions to the block operation declarations:
```sh
/* block operation forward declarations */
int random_walk_iblock_init(ubx_block_t *b);
void random_walk_iblock_cleanup(ubx_block_t *b);
int random_walk_iblock_read(ubx_block_t *b, ubx_data_t* msg);
void random_walk_iblock_write(ubx_block_t *b, ubx_data_t* msg);
void get_data_pointer(ubx_block_t *b, ubx_data_t* msg);
```

### Build with CMAKE
```sh
$ mkdir build && cd build/
$ cmake .. -DCMAKE_INSTALL_PREFIX=/home/nhuebel/projects/microblx/microblx/install/
$ make
```
Check your install path with `ccmake` to see cmake settings if something goes wrong. Installation path is the path to your microblx/install/... folder.

Running the example
-------------------

### Create USC script
```sh
~/projects/microblx$ gedit random_walk.usc
init_value_arr=
{model="random_walk",uid="rw_iblock1",meta_model="dummy_ont",value_arr_len=5,value_arr=ffi.new("float[3]",{1,2,3})} 

return bd.system {
   imports = {
      "std_types/stdtypes/stdtypes.so",
      "std_blocks/ptrig/ptrig.so",
      "types/random_walk_types.so",
      "blocks/mod_random_walk_cblock.so",
      "blocks/mod_random_walk_iblock.so",
      "std_blocks/lfds_buffers/lfds_cyclic.so",
   },
   
   blocks = {
      {name="ptrig1", type="std_triggers/ptrig"},
      {name="rw_iblock1", type="random_walk_iblock"},
      {name="rw_cblock1", type="random_walk_cblock"},
   },
   
   connections = {
      --{src="rw_cblock1.new_value", tgt="rw_cblock1.new_value"},
      {src="rw_cblock1.new_value", tgt="rw_iblock1"},
      {src="rw_iblock1", tgt="rw_cblock1.new_value"},
   },
   
   configurations = {
      { name="rw_cblock1", config={distribution={model="random_walk",uid="rw_cblock1",meta_model="dummy_ont",dirstr_name="test",seed=0,max_step_size=0.1}},
      								datacopy={0}},
      { name="rw_iblock1", config={init_value=init_value_arr}},
      { name="ptrig1", config={ period={sec=1,usec=0}, 
                                trig_blocks={ {b="#rw_cblock1", num_steps=1, measure=0} } } }
   },
}
```

### Create launch script (optional)
```sh
~/projects/microblx$ gedit run_random_walk.sh
#!/bin/bash
exec $UBX_ROOT/tools/ubx_launch -webif 8888 -c random_walk.usc
```

### Launch the application!





