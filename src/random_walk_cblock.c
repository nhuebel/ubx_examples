#include "random_walk_cblock.h"

/* define a structure for holding the block local state. By assigning an
 * instance of this struct to the block private_data pointer (see init), this
 * information becomes accessible within the hook functions.
 */
struct random_walk_cblock_info
{
        /* add custom block local data here */
		struct distribution_name distribution_data;

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
        struct random_walk_cblock_info *inf = (struct random_walk_cblock_info*) b->private_data;

        //get and store configuration data
//        unsigned int clen;
//        struct distribution_name* distribution_data= (struct distribution_name*) ubx_config_get_data_ptr(b, "distribution", &clen);
        struct distribution_name* distribution_data=(struct distribution_name*)ubx_config_get_data(b,"distribution");
        inf->distribution_data = *distribution_data;

        //initialize random number generator with seed
        srand(inf->distribution_data.seed);

        ///TODO: read length of the value-port and allocate memory

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
		int rand_val;
        struct random_walk_cblock_info *inf = (struct random_walk_cblock_info*) b->private_data;

        //read value from port
        struct var_array_values dat;
        read_new_value(inf->ports.new_value,&dat);
        //do 'random' stuff
        int i;
        for (i=0;i<dat.value_arr_len;i++)
        {
        	//creates a random value between +-max_step_size
        	dat.value_arr[i]+=2*inf->distribution_data.max_step_size*((float)rand()/(float)RAND_MAX-0,5);
        }
        DBG(dat);
        ///TODO: implement different distributions
        //write value to port
        write_new_value(inf->ports.new_value,&dat);
}

