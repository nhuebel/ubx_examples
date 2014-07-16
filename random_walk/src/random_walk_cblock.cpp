#include "random_walk_cblock.hpp"

/* edit and uncomment this:
 * UBX_MODULE_LICENSE_SPDX(GPL-2.0+)
 */

/* define a structure for holding the block local state. By assigning an
 * instance of this struct to the block private_data pointer (see init), this
 * information becomes accessible within the hook functions.
 */
struct random_walk_cblock_info
{
        /* add custom block local data here */

        /* this is to have fast access to ports for reading and writing, without
         * needing a hash table lookup */
        struct random_walk_cblock_port_cache ports;
};

/* init */
int random_walk_cblock_init(ubx_block_t *b)
{
        int ret = -1;
        struct random_walk_cblock_info *inf;

        /* allocate memory for the block local state */
        if ((inf = (struct random_walk_cblock_info*)calloc(1, sizeof(struct random_walk_cblock_info)))==NULL) {
                ERR("random_walk_cblock: failed to alloc memory");
                ret=EOUTOFMEM;
                goto out;
        }
        b->private_data=inf;
        update_port_cache(b, &inf->ports);
        ret=0;
out:
        return ret;
}

/* start */
int random_walk_cblock_start(ubx_block_t *b)
{
        /* struct random_walk_cblock_info *inf = (struct random_walk_cblock_info*) b->private_data; */
        int ret = 0;
        return ret;
}

/* stop */
void random_walk_cblock_stop(ubx_block_t *b)
{
        /* struct random_walk_cblock_info *inf = (struct random_walk_cblock_info*) b->private_data; */
}

/* cleanup */
void random_walk_cblock_cleanup(ubx_block_t *b)
{
        free(b->private_data);
}

/* step */
void random_walk_cblock_step(ubx_block_t *b)
{
        /*
        struct random_walk_cblock_info *inf = (struct random_walk_cblock_info*) b->private_data;
        */
}

