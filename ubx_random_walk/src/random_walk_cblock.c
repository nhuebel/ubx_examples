#include "random_walk_cblock.h"

/* define a structure for holding the block local state. By assigning an
 * instance of this struct to the block private_data pointer (see init), this
 * information becomes accessible within the hook functions.
 */
struct random_walk_cblock_info
{
        /* add custom block local data here */
		struct distribution_name distribution_data;
		short datacpy;

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
        unsigned int clen;
        inf->datacpy = *(short*) ubx_config_get_data_ptr(b, "datacopy", &clen);

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
        unsigned int clen;
        struct distribution_name* distribution_data= (struct distribution_name*) ubx_config_get_data_ptr(b, "distribution", &clen);
//        struct distribution_name* distribution_data=(struct distribution_name*)ubx_config_get_data(b,"distribution");
        inf->distribution_data = *distribution_data;

        //initialize random number generator with seed
        srand(inf->distribution_data.seed);
        DBG("received distribution - name: '%s'; seed: %d",distribution_data->dirstr_name,distribution_data->seed);

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
		int i;
		uint32_t ret=0;
        struct random_walk_cblock_info *inf = (struct random_walk_cblock_info*) b->private_data;

        if (inf->datacpy)
        {
        	MSG("connection using memcpy");
			//read value from port
			ubx_port_t* in_port = ubx_port_get(b,"new_value");
			struct var_array_values data;
			if((ret = read_port(in_port,"struct var_array_values",&data))!=1){
				ERR("error when trying to read port %s",in_port->name);
				return;
			}
	//        for(i=0;i<data.value_arr_len;i++){
	//        	MSG("value_arr[%d] = %f",i,data.value_arr[i]);
	//        }

			//do 'random' stuff
			create_random_values(&(inf->distribution_data),&data);

			//write data to port
			ubx_port_t* out_port = ubx_port_get(b,"new_value");
			write_port(out_port,"struct var_array_values",&data);

			//free the data that was assigned during the read_port call
			free(data.value_arr);
        }else
        {
        	MSG("connection using pointer");
        	//get pointer to data
        	ubx_block_t **iaptr;
        	ubx_port_t* port = ubx_port_get(b,"new_value");
        	///TODO: which checks are necessary?
        	if(port==NULL) { ERR("port is NULL"); return; }
        	ubx_node_info_t* ni = b->ni;
        	assert(ni!=NULL);
        	ubx_type_t *tcheck;
        	if((tcheck= ubx_type_get(ni, "struct var_array_values"))==NULL) { ERR("type %s is not known","struct var_array_values"); return; }

            ubx_data_t val;
            val.type = port->out_type;
        	val.len = 1;

        	__get_data_ptr(port,&val);
        	struct var_array_values *data = (struct var_array_values*) val.data;
//			for(i=0;i<data->value_arr_len;i++){
//				MSG("value_arr[%d] = %f",i,data->value_arr[i]);
//			}
			create_random_values(&(inf->distribution_data),data);

        }
}

void create_random_values(struct distribution_name *distr, struct var_array_values *data){
	///TODO: implement different distributions
	int i;
	for (i=0;i<data->value_arr_len;i++)
	{
		//creates a random value between +-max_step_size
		data->value_arr[i]+=2*distr->max_step_size*((float)rand()/(float)RAND_MAX-0.5);
		MSG("new value if %d th element: %f",i,data->value_arr[i]);
	}
}
