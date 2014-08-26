#include "random_walk_iblock.h"

/* define a structure for holding the block local state. By assigning an
 * instance of this struct to the block private_data pointer (see init), this
 * information becomes accessible within the hook functions.
 */
struct random_walk_iblock_info
{
        /* add custom block local data here */
		struct var_array_values current_value;

        /* this is to have fast access to ports for reading and writing, without
         * needing a hash table lookup */
        struct random_walk_iblock_port_cache ports;
};

/* init */
int random_walk_iblock_init(ubx_block_t *b)
{
        int i,ret = -1;
        struct random_walk_iblock_info *inf;

        /* allocate memory for the block local state */
        if ((inf = (struct random_walk_iblock_info*)calloc(1, sizeof(struct random_walk_iblock_info)))==NULL) {
                ERR("random_walk_iblock: failed to alloc memory");
                ret=EOUTOFMEM;
                goto out;
        }
        inf = (struct random_walk_iblock_info*) b->private_data;

        //get initial values and array size from configuration
        struct var_array_values* init_values = (struct var_array_values*) ubx_config_get_data(b,"init_value");
        //inf->current_value = *(struct var_array_values*) ubx_config_get_data(b,"init_value");

        if (init_values->value_arr_len==0)
        {
        	init_values->value_arr_len=1;
        	ERR("random_walk_iblock: invalid length of array, setting length to %d",init_values->value_arr_len);
        }
        inf->current_value=*init_values;
        if ((inf->current_value.value_arr=malloc(init_values->value_arr_len*sizeof(float)))==NULL)
        {
        	ERR("random_walk_iblock: failed to allocate memory for data");
        	ret=EOUTOFMEM;
        	goto out_free_mem;
        }
        //initialize the array
        if (init_values->value_arr==NULL)
        {
            for (i=0;i<inf->current_value.value_arr_len;i++)
            {
            	inf->current_value.value_arr[i]=0;
            }
            WRN("random_walk_iblock: no pointer to initial values given, will initialize all values with 0");
        }else
        {
        	inf->current_value.value_arr=init_values->value_arr;
        }

        b->private_data=inf;
        update_port_cache(b, &inf->ports);
        ret=0;
out_free_mem:
		free(inf);
out:
        return ret;
}



/* cleanup */
void random_walk_iblock_cleanup(ubx_block_t *b)
{
	struct random_walk_iblock_info *inf;
	inf = (struct random_walk_iblock_info*) b->private_data;
	free(inf->current_value.value_arr);
	free(inf);
}



/* read */
int random_walk_iblock_read(ubx_block_t *i, ubx_data_t* msg)
{

}

/* write */
void random_walk_iblock_write(ubx_block_t *i, ubx_data_t* msg)
{

}
