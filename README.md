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
    { name="store_value", file="random_walk_iblock.blx", src_dir="src" },
    { name="modify_value", file="random_walk_cblock.blx", src_dir="src" },
  },

  modules = {
    { name="mod_random_walk_iblock", blocks={"store_value"} },
    { name="mod_random_walk_cblock", blocks={"modify_value"} },
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
      },

      ports = {
	 { name="change", out_type_name="struct var_array_values", out_data_len=1, in_type_name="struct var_array_values", in_data_len=1, doc="change of the value of the random walk" },
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

**The rest of this document is still under construction**

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



### Implement the blocks



### Build with CMAKE


Running the example
-------------------

### Create USC script



### Create launch script (optional)


```sh
~/projects/microblx$ gedit run.sh
#!/bin/bash
exec $UBX_ROOT/tools/ubx_launch -webif 8888 -c cpp_transfer.usc
```

### Launch the application!





