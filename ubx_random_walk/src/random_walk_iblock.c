#include "random_walk_iblock.h"

/* define a structure for holding the block local state. By assigning an
 * instance of this struct to the block private_data pointer (see init), this
 * information becomes accessible within the hook functions.
 */
struct random_walk_iblock_info {
	/* add custom block local data here */
	ubx_type_t* type;
	struct var_array_values current_value;

	/* this is to have fast access to ports for reading and writing, without
	 * needing a hash table lookup */
	struct random_walk_iblock_port_cache ports;
};

/* init */
int random_walk_iblock_init(ubx_block_t *b) {
	int i, len, ret = -1;
	struct random_walk_iblock_info *inf;

	/* allocate memory for the block local state */
	if ((b->private_data = (struct random_walk_iblock_info*) calloc(1,
			sizeof(struct random_walk_iblock_info))) == NULL) {
		ERR("failed to alloc memory");
		ret = EOUTOFMEM;
		goto out;
	}
	inf = (struct random_walk_iblock_info*) b->private_data;

	//get initial values and array size from configuration
	//if arr_len is bigger than init array, the additional fields will be filled with 0 (due to calloc)
	struct var_array_values* init_values =
			(struct var_array_values*) ubx_config_get_data_ptr(b, "init_value",
					&len);
//        for(i=0;i<init_values->value_arr_len;i++)
//		{
//			MSG("arr val %d: %f",i,init_values->value_arr[i]);
//		}
	///TODO: should we work on the memory of the config values instead? Pro: Accessible for configurator (plus memory alloc above can be removed), orig. config data should be owned by configurator
	//inf->current_value=*init_values;
	memcpy(&(inf->current_value), init_values, sizeof(struct var_array_values));

	/* allocate memory for the value array */
	if (init_values->value_arr_len == 0) {
		init_values->value_arr_len = 1;
		ERR("invalid length of array, setting length to %d",
				init_values->value_arr_len);
	}
	if ((inf->current_value.value_arr = (float*) calloc(1,
			init_values->value_arr_len * sizeof(float))) == NULL) {
		ERR("failed to alloc memory");
		ret = EOUTOFMEM;
		goto out_free_mem;
	}
	memcpy(inf->current_value.value_arr,init_values->value_arr,init_values->value_arr_len * sizeof(float));
	inf->type = ubx_type_get(b->ni, "struct var_array_values");
//	for(i=0;i<init_values->value_arr_len;i++)
//	{
//		MSG("arr val %d: %f",i,inf->current_value.value_arr[i]);
//	}

	update_port_cache(b, &inf->ports);
	ret = 0;
	goto out;
out_free_mem:
	free(inf);
out:
	return ret;
}

/* cleanup */
void random_walk_iblock_cleanup(ubx_block_t *b) {
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
 * @return 0 if failed and 1 if successful (for compatibility with other read functions)
 */
int random_walk_iblock_read(ubx_block_t *b, ubx_data_t* msg) {
	int ret = 0;
	struct random_walk_iblock_info *inf;
	inf = (struct random_walk_iblock_info*) b->private_data;

	if (inf->type != msg->type) {
		ERR("port %s expects data of type %s but has received data of type %s",	inf->ports.new_value->name, inf->ports.new_value->in_type_name, msg->type->name);
		goto out;
	}

	if ((memcpy(msg->data, &(inf->current_value), sizeof(inf->current_value)))
			== NULL) {
		ERR("Error when reading data from port %s", inf->ports.new_value->name);
		goto out;
	}
	///TODO: bad architecture, think of a better way: allocate memory for the data array -> make sure to free it at end of step function before data var goes out of scope
	struct var_array_values *dummy = (struct var_array_values*) msg->data;
	if (( dummy->value_arr= calloc(1,inf->current_value.value_arr_len*sizeof(float))) == NULL) {
		ERR("failed to alloc memory");
		ret = EOUTOFMEM;
		goto out_free_mem;
	}
	if ((memcpy(dummy->value_arr, inf->current_value.value_arr, inf->current_value.value_arr_len*sizeof(float))) == NULL) {
			ERR("Error when reading data from port %s", inf->ports.new_value->name);
			goto out_free_mem;
	}

	ret = 1;
	goto out;
out_free_mem:
	free(msg->data);
out:
	return ret;
}

/* write */
void random_walk_iblock_write(ubx_block_t *b, ubx_data_t* msg) {
	struct random_walk_iblock_info *inf;
	inf = (struct random_walk_iblock_info*) b->private_data;

	if (inf->type != msg->type) {
		ERR("port %s expects data of type %s but has received data of type %s",
				inf->ports.new_value->name, inf->ports.new_value->in_type_name,
				msg->type->name);
		return;
	}
	if (msg->len != 1) {
		ERR("Expected msg of length 1, but received len %lu", msg->len);
		return;
	}
	// copy the struct to the iblock
	float *tmp = inf->current_value.value_arr; //keep the location of the private data to restore pointer to it after following memcpy
	if ((memcpy(&(inf->current_value), msg->data, sizeof(inf->current_value))) == NULL) {
		ERR("Error when writing data to port %s", inf->ports.new_value->name);
		return;
	}
	inf->current_value.value_arr = tmp;
	// copy the data array to the iblock
	struct var_array_values *dummy = (struct var_array_values*) msg->data;
	if ((memcpy(inf->current_value.value_arr, dummy->value_arr, dummy->value_arr_len*sizeof(float))) == NULL) {
		ERR("Error when writing data to port %s", inf->ports.new_value->name);
		return;
	}
}

/* get the pointer to the data */
void get_data_pointer(ubx_block_t *b, ubx_data_t* msg) {
	struct random_walk_iblock_info *inf;
	inf = (struct random_walk_iblock_info*) b->private_data;

	if (inf->type != msg->type) {
		ERR("port %s expects data of type %s but has received data of type %s",	inf->ports.new_value->name, inf->ports.new_value->in_type_name, msg->type->name);
		return;
	}
	msg->data = &(inf->current_value);
	return;
}
