/*
 * module function declaration for library mod_random_walk_iblock header (autogenerated)
 */
 
#include <ubx.h>

// Initialization and cleanup function declaration
int mod_random_walk_iblock_mod_init(ubx_node_info_t* ni);
void mod_random_walk_iblock_mod_cleanup(ubx_node_info_t* ni);


/* declare module init and cleanup functions, so that the ubx core can
 * find these when the module is loaded/unloaded.
 * Please edit your license in macro LICENSE_SPDX */
UBX_MODULE_INIT(mod_random_walk_iblock_mod_init)
UBX_MODULE_CLEANUP(mod_random_walk_iblock_mod_cleanup)
UBX_MODULE_LICENSE_SPDX(GPL-2.0+)

