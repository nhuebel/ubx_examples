/*
 * module function declaration for library hello header (autogenerated)
 */

#include "hello_module.h"

int mod_hello_mod_init(ubx_node_info_t* ni)
{
  int ret;
  ret=hello_mod_init(ni);
  if(ret!=0)
    goto out;

out:
   return ret;
}

void mod_hello_mod_cleanup(ubx_node_info_t* ni)
{
  hello_mod_cleanup(ni);
}

