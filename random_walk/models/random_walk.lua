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
    { name="store_value", file="random_walk_iblock.lua", src_dir="src" },
    { name="modify_value", file="random_walk_cblock.lua", src_dir="src" },
  },

  libraries = {
-- define the libraries. Preferably 1 library per block
    { name="random_walk_iblock", blocks={"store_value"} },
    { name="random_walk_cblock", blocks={"modify_value"} },
  },
}
