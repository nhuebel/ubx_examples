/*
 * random_walk_iblock microblx function block (autogenerated, don't edit)
 */

#include <ubx.h>

/* includes types and type metadata */
#include "../types/var_array_values.h"
#include "../types/var_array_values.h.hexarr"


/* block meta information */
char random_walk_iblock_meta[] =
        " { doc='',"
        "   real-time=true,"
        "}";

/* declaration of block configuration */
ubx_config_t random_walk_iblock_config[] = {
        { .name="init_value", .type_name = "struct var_array_values", .doc="" },
        { NULL },
};

/* declaration port block ports */
ubx_port_t random_walk_iblock_ports[] = {
        { .name="new_value", .in_type_name="struct var_array_values", .in_data_len=1, .doc="update of the stored value"  },
        { .name="stored_value", .out_type_name="struct var_array_values", .out_data_len=1, .doc="current value of the random walk"  },
        { NULL },
};

/* declare a struct port_cache */
struct random_walk_iblock_port_cache {
        ubx_port_t* new_value;
        ubx_port_t* stored_value;
};

/* declare a helper function to update the port cache this is necessary
 * because the port ptrs can change if ports are dynamically added or
 * removed. This function should hence be called after all
 * initialization is done, i.e. typically in 'start'
 */
static void update_port_cache(ubx_block_t *b, struct random_walk_iblock_port_cache *pc)
{
        pc->new_value = ubx_port_get(b, "new_value");
        pc->stored_value = ubx_port_get(b, "stored_value");
}

/* block operation forward declarations */
int random_walk_iblock_init(ubx_block_t *b);
void random_walk_iblock_cleanup(ubx_block_t *b);
int random_walk_iblock_read(ubx_block_t *b, ubx_data_t* msg);
void random_walk_iblock_write(ubx_block_t *b, ubx_data_t* msg);
void get_data_pointer(ubx_block_t *b, ubx_data_t* msg);

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
        .read = random_walk_iblock_read,
        .getdata = get_data_pointer,
};


/* random_walk_iblock module init and cleanup functions */
int random_walk_iblock_mod_init(ubx_node_info_t* ni)
{
        DBG(" ");
        int ret = -1;

        if(ubx_block_register(ni, &random_walk_iblock_block) != 0)
                goto out;

        ret=0;
out:
        return ret;
}

void random_walk_iblock_mod_cleanup(ubx_node_info_t *ni)
{
        DBG(" ");
        ubx_block_unregister(ni, "random_walk_iblock");
}

