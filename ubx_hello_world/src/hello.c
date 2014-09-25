#include "hello.h"

/* define a structure for holding the block local state. By assigning an
 * instance of this struct to the block private_data pointer (see init), this
 * information becomes accessible within the hook functions.
 */
struct hello_info
{
        /* add custom block local data here */
		int number;

        /* this is to have fast access to ports for reading and writing, without
         * needing a hash table lookup */
        struct hello_port_cache ports;
};

/* init */
int hello_init(ubx_block_t *b)
{
        int ret = -1;
        struct hello_info *inf;

        /* allocate memory for the block local state */
        if ((inf = (struct hello_info*)calloc(1, sizeof(struct hello_info)))==NULL) {
                ERR("hello: failed to alloc memory");
                ret=EOUTOFMEM;
                goto out;
        }
        unsigned int clen;
        inf->number = *(int*) ubx_config_get_data_ptr(b, "number", &clen);

        b->private_data=inf;
        update_port_cache(b, &inf->ports);
        ret=0;
out:
        return ret;
}

/* start */
int hello_start(ubx_block_t *b)
{
        /* struct hello_info *inf = (struct hello_info*) b->private_data; */
        int ret = 0;
        return ret;
}

/* stop */
void hello_stop(ubx_block_t *b)
{
        /* struct hello_info *inf = (struct hello_info*) b->private_data; */
}

/* cleanup */
void hello_cleanup(ubx_block_t *b)
{
        free(b->private_data);
}

/* step */
void hello_step(ubx_block_t *b)
{

        struct hello_info *inf = (struct hello_info*) b->private_data;
        MSG("Hello world! I am block number %d.",inf->number);

}

