/* For now the coordinator is just a main file for calling all other components in the right order. */

#include <ubx.h>
#include <stdlib.h>
#include <ptrig/types/ptrig_period.h>
#include <ptrig/types/ptrig_config.h>
///TODO: Find way of getting those struct definitions at runtime

#define WEBIF_PORT	"8888"
#define KYEL  "\x1B[33m"
#define KNRM  "\x1B[0m"

typedef enum {ROOT,MODULE} base_folder_t;

struct typemodule {
	base_folder_t folder;
	char path[100];
};
struct typemodules {
	struct typemodule *type;
	int len;
};
struct conf_data {
	ubx_data_t *data;
	char name[50];
};
struct block_info {
	ubx_block_t *block;
	char name[50];
	char type[50];
	struct conf_data *conf_data;
	int num_conf;
};
struct composition {
	int len;
	struct block_info *blocks;
};
///TODO: Only specify composition and then get all infos from knowledge base based on that

int main (int argc, char *argv[], char *envp[])
{
	int i,j, ret=EXIT_FAILURE;
	ubx_node_info_t ni;
	//ubx_block_t *webif,*h1,*h2,*h3, *ptrig;
	ubx_data_t *d;
	const char const *UBX_ROOT = getenv("UBX_ROOT");
	const char const *UBX_MODULES = getenv("UBX_MODULES");
	char tempstr[200];
	int *dummy;
	struct typemodules type_mods, block_mods;
	struct composition comp;

	/* initalize the node */
	ubx_node_init(&ni,"configurable_rosbridge");

	/*****************************************************************/
	/* define all used types and blocks */

	type_mods.len = 1;
	type_mods.type = malloc(type_mods.len*sizeof(struct typemodule));

	//random walk types
	type_mods.type[0].folder=MODULE;
	strcpy(type_mods.type[0].path,"/types/ubx_random_walk_types.so");

	block_mods.len = 2;
	block_mods.type = malloc(block_mods.len*sizeof(struct typemodule));

	//webif block
	block_mods.type[0].folder=ROOT;
	strcpy(block_mods.type[0].path,"/std_blocks/webif/webif.so");

	//hello world block
	block_mods.type[1].folder=MODULE;
	strcpy(block_mods.type[1].path,"/blocks/hello.so");

	comp.len = 4;
	comp.blocks = malloc(comp.len*sizeof(struct block_info));

	strcpy(comp.blocks[0].type,"webif/webif");
	comp.blocks[0].block = malloc(sizeof(ubx_block_t));
	strcpy(comp.blocks[0].name,"webif1");

	strcpy(comp.blocks[1].type,"hello");
	comp.blocks[1].block = malloc(sizeof(ubx_block_t));
	strcpy(comp.blocks[1].name,"hello1");

	strcpy(comp.blocks[2].type,"hello");
	comp.blocks[2].block = malloc(sizeof(ubx_block_t));
	strcpy(comp.blocks[2].name,"hello2");

	strcpy(comp.blocks[3].type,"hello");
	comp.blocks[3].block = malloc(sizeof(ubx_block_t));
	strcpy(comp.blocks[3].name,"hello3");

	/*****************************************************************/
	/* Creating block configs */

	///TODO: Do config creation properly with type, name, etc.

	// blocks[0] omitted since no config for webif
	comp.blocks[0].num_conf=0;

	//hello1
	comp.blocks[1].num_conf=1;
	dummy = calloc(1,sizeof(int));
	*dummy = 1;
	comp.blocks[1].conf_data = malloc(comp.blocks[1].num_conf*sizeof(struct conf_data));
	comp.blocks[1].conf_data->data = malloc(sizeof(ubx_data_t));
	strcpy(comp.blocks[1].conf_data->name,"number");
	comp.blocks[1].conf_data->data->len=1;
	comp.blocks[1].conf_data->data->data=dummy;

	//hello2
	comp.blocks[2].num_conf=1;
	dummy = calloc(1,sizeof(int));
	*dummy = 2;
	comp.blocks[2].conf_data = malloc(comp.blocks[2].num_conf*sizeof(struct conf_data));
	comp.blocks[2].conf_data->data = malloc(sizeof(ubx_data_t));
	strcpy(comp.blocks[2].conf_data->name,"number");
	comp.blocks[2].conf_data->data->len=1;
	comp.blocks[2].conf_data->data->data=dummy;

	//hello3
	comp.blocks[3].num_conf=1;
	dummy = calloc(1,sizeof(int));
	*dummy = 3;
	comp.blocks[3].conf_data = malloc(comp.blocks[3].num_conf*sizeof(struct conf_data));
	comp.blocks[3].conf_data->data = malloc(sizeof(ubx_data_t));
	strcpy(comp.blocks[3].conf_data->name,"number");
	comp.blocks[3].conf_data->data->len=1;
	comp.blocks[3].conf_data->data->data=dummy;

	/*****************************************************************/
	/* setting up environment */
	printf(KYEL "Setting up environment \n" KNRM);

	if (UBX_ROOT==NULL){
		ERR("UBX_ROOT not set. Please add it to your bashrc. See microblx installation instructions for help.");
		return ret;
	}
	// check length of string
	if (strlen(UBX_ROOT)>=100){
		ERR("UBX_ROOT too long. Danger of overflowing buffer.");
		return ret;
	}
	printf("UBX_ROOT: %s \n",UBX_ROOT);

	if (UBX_MODULES==NULL){
		ERR("UBX_MODULES not set. Please add it to your bashrc. See microblx installation instructions for help.");
		return ret;
	}
	// check length of string
	if (strlen(UBX_MODULES)>=100){
		ERR("UBX_MODULES too long. Danger of overflowing buffer.");
		return ret;
	}
	printf("UBX_MODULES: %s \n",UBX_MODULES);

	printf(" \n");

	/*****************************************************************/
	/* loading default libraries */
	printf(KYEL "Loading default modules \n" KNRM);

	//std_types
	strcpy(tempstr,UBX_ROOT);
	strcat(tempstr,"/std_types/stdtypes/stdtypes.so");
	if(ubx_module_load(&ni, tempstr) != 0){
		ERR("failed to load %s",tempstr);
		goto out;
	}
	printf("importing module: %s \n", tempstr);

	// ptrig
	strcpy(tempstr,UBX_ROOT);
	strcat(tempstr,"/std_blocks/ptrig/ptrig.so");
	if(ubx_module_load(&ni, tempstr) != 0){
		ERR("failed to load %s",tempstr);
		goto out;
	}
	printf("importing scheduler module: %s \n", tempstr);

	if((ni.scheduler = ubx_block_create(&ni,"std_triggers/ptrig", "ptrig1"))==NULL)
		goto out;
	printf("instantiating scheduler: %s \n", ni.scheduler->name);

	///TODO: Add composer here after refactoring

	printf(" \n");

	/*****************************************************************/
	/* Load types */
	printf(KYEL "Loading type modules \n" KNRM);

	/* set paths */
	for (i=0;i<type_mods.len;i++){
		//set base folder
		if (type_mods.type[i].folder==ROOT){
			strcpy(tempstr,UBX_ROOT);
			//MSG("%s",tempstr);
		}
		else if (type_mods.type[i].folder==MODULE){
			strcpy(tempstr,UBX_MODULES);
			//MSG("%s",tempstr);
		}else{
			ERR("Unknown base folder");
			goto out;
		}
		strcat(tempstr,type_mods.type[i].path);
		//load type module
		if(ubx_module_load(&ni, tempstr) != 0){
			ERR("failed to load %s",tempstr);
			goto out;
		}
		printf("importing module: %s \n", tempstr);
	}

	printf(" \n");

	/*****************************************************************/
	/* Load blocks */
	printf(KYEL "Loading block modules \n" KNRM);

	/* set paths */
	for (i=0;i<block_mods.len;i++){
		//set base folder
		if (block_mods.type[i].folder==ROOT){
			strcpy(tempstr,UBX_ROOT);
			//MSG("%s",tempstr);
		}
		else if (block_mods.type[i].folder==MODULE){
			strcpy(tempstr,UBX_MODULES);
			//MSG("%s",tempstr);
		}else{
			ERR("Unknown base folder");
			goto out;
		}
		strcat(tempstr,block_mods.type[i].path);
		//load block module
		if(ubx_module_load(&ni, tempstr) != 0)
				goto out;
		printf("importing module: %s \n", tempstr);
	}

	printf(" \n");

	/*****************************************************************/
	/* Instantiate blocks */
	printf(KYEL "Instantiating blocks \n" KNRM);

	for (i=0;i<comp.len;i++){
		if((comp.blocks[i].block = ubx_block_create(&ni,comp.blocks[i].type, comp.blocks[i].name))==NULL)
			goto out;
		printf("instantiating block: %s \n", comp.blocks[i].name);
	}

	printf(" \n");

	/*****************************************************************/
	/* Configure blocks */
	printf(KYEL "Configuring blocks \n" KNRM);
///TODO: instead of having a handle for each node, get the list from node and check if configuration is necessary
//	ubx_config_t *conf;
//		for (conf=ptrig->configs;conf->name!=NULL;coperiodnf++){
//			//MSG("ptr: %p",conf);
//			MSG("name: %s", conf->name);
//		}

	for (i=0;i<comp.len;i++){
		for (j=0;j<comp.blocks[i].num_conf;j++){
			d = ubx_config_get_data(comp.blocks[i].block,comp.blocks[i].conf_data[j].name);
			free(d->data);
			d->data=comp.blocks[i].conf_data[j].data->data;
			printf("configured block %s with configuration data %s \n",comp.blocks[i].block->name, comp.blocks[i].conf_data[j].name);
		}
	}


//	/* Configure port of webserver block
//	 * this gets the ubx_data_t pointer */
//	d = ubx_config_get_data(webif, "port");
//	len = strlen(WEBIF_PORT)+1;
//	/* resize the char array as necessary and copy the port string */
//	ubx_data_resize(d, len);
//	strncpy(d->data, WEBIF_PORT, len);

	printf(" \n");

	/*****************************************************************/
	/* connect ports */
	printf(KYEL "Connecting blocks \n" KNRM);

	printf(" \n");

	/*****************************************************************/
	/* configure+init scheduler */
	printf(KYEL "Configuring and initializing scheduler \n" KNRM);

	/* Configure the list of blocks to trigger for the ptrig block */
	struct ptrig_period *ptrig_per;
	ptrig_per = calloc(1,sizeof(ptrig_per));
	ptrig_per->sec = 1;
	ptrig_per->usec = 0;
	d = ubx_config_get_data(ni.scheduler, "period");
	free(d->data);
	d->data = ptrig_per;

	// omit comp.blocks[0] because that's the webif block
	struct ptrig_config *ptrig_conf1;
	ptrig_conf1 = calloc(1,sizeof(struct ptrig_config));
	ptrig_conf1->b = comp.blocks[1].block;
	ptrig_conf1->measure = 0;
	ptrig_conf1->num_steps = 2;

	struct ptrig_config *ptrig_conf2;
	ptrig_conf2 = calloc(1,sizeof(struct ptrig_config));
	ptrig_conf2->b = comp.blocks[2].block;
	ptrig_conf2->measure = 0;
	ptrig_conf2->num_steps = 1;

	struct ptrig_config ptrig_conf3;
	ptrig_conf3.b = comp.blocks[3].block;
	ptrig_conf3.measure = 0;
	ptrig_conf3.num_steps =1;

	///TODO: change this to pass the pointers
	struct ptrig_config ptrig_conf[] =  {*ptrig_conf1, *ptrig_conf2, ptrig_conf3};

	d = ubx_config_get_data(ni.scheduler, "trig_blocks");
	free(d->data);
	d->data = ptrig_conf;
	d->len = 3;
	printf("configured scheduler %s \n",ni.scheduler->name);

	if(ubx_block_init(ni.scheduler) != 0) {
		ERR("failed to init scheduler %s",ni.scheduler->name);
		goto out;
	}
	printf("initialized scheduler %s \n",ni.scheduler->name);

	printf(" \n");

	/*****************************************************************/
	/* init and start blocks */
	printf(KYEL "Initializing and starting blocks \n" KNRM);

	for (i=0;i<comp.len;i++){
		if(ubx_block_init(comp.blocks[i].block) != 0) {
			ERR("failed to init %s",comp.blocks[i].block->name);
			goto out;
		}
		printf("initialized block %s \n",comp.blocks[i].block->name);
	}

	for (i=0;i<comp.len;i++){
		if(ubx_block_start(comp.blocks[i].block) != 0) {
			ERR("failed to start %s",comp.blocks[i].block->name);
			goto out;
		}
		printf("started block %s \n",comp.blocks[i].block->name);
	}

	/*****************************************************************/
	/* wait for key to start blocks */
	printf("hit enter to start the blocks \n");
	getchar();

	/*****************************************************************/
	/* start scheduler */
	printf("starting scheduler \n");
	if(ubx_block_start(ni.scheduler) != 0) {
		ERR("failed to start %s",ni.scheduler->name);
		goto out;
	}

	printf("hit enter to quit \n");
	getchar();

	ret=EXIT_SUCCESS;
 out:
	/* this cleans up all blocks and unloads all modules */
	ubx_node_cleanup(&ni);
	exit(ret);
}
