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


**The rest of this document is still under construction**

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





