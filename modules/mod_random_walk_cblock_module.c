/*
 * module function declaration for library mod_random_walk_cblock header (autogenerated)
 */

#include "mod_random_walk_cblock_module.h"

int mod_random_walk_cblock_mod_init(ubx_node_info_t* ni)
{
  int ret;
  ret=random_walk_cblock_mod_init(ni);
  if(ret!=0)
    goto out;

out:
   return ret;
}

void mod_random_walk_cblock_mod_cleanup(ubx_node_info_t* ni)
{
  random_walk_cblock_mod_cleanup(ni);
}

