#include "random_walk_iblock.h"

/* define a structure for holding the block local state. By assigning an
 * instance of this struct to the block private_data pointer (see init), this
 * information becomes accessible within the hook functions.
 */
struct random_walk_iblock_info
{
        /* add custom block local data here */
		ubx_type_t* type;
		struct var_array_values current_value;

        /* this is to have fast access to ports for reading and writing, without
         * needing a hash table lookup */
        struct random_walk_iblock_port_cache ports;
};

/* init */
int random_walk_iblock_init(ubx_block_t *b)
{
        int i,len,ret = -1;
        struct random_walk_iblock_info *inf;

        /* allocate memory for the block local state */
        if ((b->private_data = (struct random_walk_iblock_info*)calloc(1, sizeof(struct random_walk_iblock_info)))==NULL) {
                ERR("failed to alloc memory");
                ret=EOUTOFMEM;
                goto out;
        }
        inf = (struct random_walk_iblock_info*) b->private_data;

        //get initial values and array size from configuration
        //if arr_len is bigger than init array, the additional fields will be filled with 0 (due to calloc)
        struct var_array_values* init_values= (struct var_array_values*) ubx_config_get_data_ptr(b,"init_value",&len);
        //inf->current_value = *(struct var_array_values*) ubx_config_get_data(b,"init_value");
        if (init_values->value_arr_len==0)
        {
        	init_values->value_arr_len=1;
        	ERR("invalid length of array, setting length to %d",init_values->value_arr_len);
        }
        /* allocate memory for the value array */
        if ((inf->current_value.value_arr = (float*)calloc(1, init_values->value_arr_len*sizeof(float)))==NULL) {
                ERR("failed to alloc memory");
                ret=EOUTOFMEM;
                goto out;
        }
        inf->current_value=*init_values;
        inf->type = ubx_type_get(b->ni,"struct var_array_values");
        for(i=0;i<init_values->value_arr_len;i++)
        {
        	MSG("arr val %d: %f",i,inf->current_value.value_arr[i]);
        }

        update_port_cache(b, &inf->ports);
        ret=0;
        goto out;
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

/**
 * Read function exposed by the iblock.
 *
 * @param b ubx_block_t pointer to the iblock
 * @param msg pointer to the message to which the data of the iblock will be copied
 *
 * @return 0 if failed and 1 if not failed (for compatibility with other read functions)
 */
int random_walk_iblock_read(ubx_block_t *b, ubx_data_t* msg)
{
	int ret=0;
	struct random_walk_iblock_info *inf;
	inf = (struct random_walk_iblock_info*) b->private_data;

	if(inf->type!=msg->type){
		ERR("port %s expects data of type %s but has received data of type %s",inf->ports.new_value->name,inf->ports.new_value->in_type_name,msg->type->name);
		goto out;
	}

	if((memcpy(msg->data,&(inf->current_value),sizeof(inf->current_value)))==NULL){
		ERR("Error when copying data from port %s",inf->ports.new_value->name);
		goto out;
	}
	ret=1;
out:
	return ret;
}

/* write */
void random_walk_iblock_write(ubx_block_t *b, ubx_data_t* msg)
{

}
