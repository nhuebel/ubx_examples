/* For now the coordinator is just a main file for calling all other components in the right order. */

#include "ubx.h"
#include <stdlib.h>
#include "/home/nhuebel/projects/microblx/microblx/std_blocks/ptrig/types/ptrig_period.h"
#include "/home/nhuebel/projects/microblx/microblx/std_blocks/ptrig/types/ptrig_config.h"
///TODO: Find way of getting those struct definitions at runtime

#define WEBIF_PORT	"8888"
#define KYEL  "\x1B[33m"
#define KNRM  "\x1B[0m"

int main (int argc, char *argv[], char *envp[])
{
	int len, ret=EXIT_FAILURE;
	ubx_node_info_t ni;
	ubx_block_t *webif,*h1,*h2,*h3, *ptrig;
	ubx_data_t *d;
	const char const *UBX_ROOT = getenv("UBX_ROOT");
	const char const *UBX_MODULES = getenv("UBX_MODULES");
	char tempstr[200];
	int *dummy;

	/* initalize the node */
	ubx_node_init(&ni, "configurable_rosbridge");

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
	/* Load types */
	printf(KYEL "Loading type modules \n" KNRM);

	/* load the standard types */
	strcpy(tempstr,UBX_ROOT);
	if(ubx_module_load(&ni, strcat(tempstr,"/std_types/stdtypes/stdtypes.so")) != 0)
		goto out;
	printf("importing module: %s \n", tempstr);
	///TODO: Separate the datatypes out of the ptrig block
//	/* load the ptrig types */
//	strcpy(tempstr,UBX_ROOT);
//	if(ubx_module_load(&ni, strcat(tempstr,"/std_blocks/ptrig/types/ptrig_types.so")) != 0)
//		goto out;
//	printf("importing module: %s \n", tempstr);

	printf(" \n");

	/*****************************************************************/
	/* Load blocks */
	printf(KYEL "Loading block modules \n" KNRM);

	/* load the web-interface block */
	strcpy(tempstr,UBX_ROOT);
	if(ubx_module_load(&ni, strcat(tempstr,"/std_blocks/webif/webif.so")) != 0)
		goto out;
	printf("importing module: %s \n", tempstr);

	/* load the hello_world block */
	strcpy(tempstr,UBX_MODULES);
	if(ubx_module_load(&ni, strcat(tempstr,"/blocks/hello.so")) != 0)
		goto out;
	printf("importing module: %s \n", tempstr);

	/* load the ptrig block */
	strcpy(tempstr,UBX_ROOT);
	if(ubx_module_load(&ni, strcat(tempstr,"/std_blocks/ptrig/ptrig.so")) != 0)
		goto out;
	printf("importing module: %s \n", tempstr);

	printf(" \n");

	/*****************************************************************/
	/* Instantiate blocks */
	printf(KYEL "Instantiating blocks \n" KNRM);

	/* create a webserver block */
	strcpy(tempstr,"webif1");
	if((webif = ubx_block_create(&ni,"webif/webif", tempstr))==NULL)
		goto out;
	printf("instantiating block: %s \n", tempstr);

	/* create three hello world blocks */
	strcpy(tempstr,"hello1");
	if((h1 = ubx_block_create(&ni,"hello", tempstr))==NULL)
		goto out;
	printf("instantiating block: %s \n", tempstr);
	strcpy(tempstr,"hello2");
	if((h2 = ubx_block_create(&ni,"hello", tempstr))==NULL)
		goto out;
	printf("instantiating block: %s \n", tempstr);
	strcpy(tempstr,"hello3");
	if((h3 = ubx_block_create(&ni,"hello", tempstr))==NULL)
		goto out;
	printf("instantiating block: %s \n", tempstr);

	/* create a ptrig block */
	strcpy(tempstr,"ptrig1");
	if((ptrig = ubx_block_create(&ni,"std_triggers/ptrig", tempstr))==NULL)
		goto out;
	printf("instantiating block: %s \n", tempstr);

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



	/* Configure number of hello1 block
	 * this gets the ubx_data_t pointer */
	d = ubx_config_get_data(h1, "number");
	free(d->data);
	dummy = calloc(1,sizeof(int));
	*dummy = 1;
	d->data=dummy;
	printf("configured block %s with configuration data %s \n",h1->name, "number");

	/* Configure number of hello2 block */
	d = ubx_config_get_data(h2, "number");
	free(d->data);
	dummy = calloc(1,sizeof(int));
	*dummy = 2;
	d->data=dummy;
	printf("configured block %s with configuration data %s \n",h2->name, "number");
	/* Configure number of hello3 block */
	d = ubx_config_get_data(h3, "number");
	free(d->data);
	dummy = calloc(1,sizeof(int));
	*dummy = 3;
	d->data=dummy;
	printf("configured block %s with configuration data %s \n",h3->name, "number");

	/* Configure the list of blocks to trigger for the ptrig block */
	struct ptrig_period *ptrig_per;
	ptrig_per = calloc(1,sizeof(ptrig_per));
	ptrig_per->sec = 1;
	ptrig_per->usec = 0;
	d = ubx_config_get_data(ptrig, "period");
	free(d->data);
	d->data = ptrig_per;

	struct ptrig_config *ptrig_conf1;
	ptrig_conf1 = calloc(1,sizeof(struct ptrig_config));
	ptrig_conf1->b = h1;
	ptrig_conf1->measure = 0;
	ptrig_conf1->num_steps = 2;

	struct ptrig_config *ptrig_conf2;
	ptrig_conf2 = calloc(1,sizeof(struct ptrig_config));
	ptrig_conf2->b = h2;
	ptrig_conf2->measure = 0;
	ptrig_conf2->num_steps = 1;

	struct ptrig_config ptrig_conf3;
	ptrig_conf3.b = h3;
	ptrig_conf3.measure = 0;
	ptrig_conf3.num_steps =1;

	///TODO: change this to pass the pointers (to avoid vars going out of scope)
	struct ptrig_config ptrig_conf[] =  {*ptrig_conf1, *ptrig_conf2, ptrig_conf3};

	d = ubx_config_get_data(ptrig, "trig_blocks");
	free(d->data);
	d->data = ptrig_conf;
	d->len = 3;
	printf("configured block %s",ptrig->name);


	/* Configure port of webserver block
	 * this gets the ubx_data_t pointer */
	d = ubx_config_get_data(webif, "port");
	len = strlen(WEBIF_PORT)+1;
	/* resize the char array as necessary and copy the port string */
	ubx_data_resize(d, len);
	strncpy(d->data, WEBIF_PORT, len);

	printf(" \n");

	/*****************************************************************/
	/* connect ports */
	printf(KYEL "Connecting blocks \n" KNRM);

	printf(" \n");


	printf("hit enter to start the blocks \n");
	getchar();

	/*****************************************************************/
	/* init and starting blocks */
///TODO: get list of blocks and init/start them by iterating through the list
	printf(KYEL "Initializing and starting blocks \n" KNRM);

	/* init and start the block */
	if(ubx_block_init(h1) != 0) {
		ERR("failed to init %s",h1->name);
		goto out;
	}
	printf("initialized block %s \n",h1->name);
	if(ubx_block_init(h2) != 0) {
		ERR("failed to init %s",h2->name);
		goto out;
	}
	printf("initialized block %s \n",h2->name);
	if(ubx_block_init(h3) != 0) {
		ERR("failed to init %s",h2->name);
		goto out;
	}
	printf("initialized block %s \n",h2->name);
	if(ubx_block_init(webif) != 0) {
		ERR("failed to init webif");
		goto out;
	}
	printf("initialized block %s \n",webif->name);
	if(ubx_block_init(ptrig) != 0) {
		ERR("failed to init %s",ptrig->name);
		goto out;
	}
	printf("initialized block %s \n",ptrig->name);

	if(ubx_block_start(h1) != 0) {
		ERR("failed to start %s",h1->name);
		goto out;
	}
	printf("started block %s \n",h1->name);
	if(ubx_block_start(h2) != 0) {
		ERR("failed to start %s",h2->name);
		goto out;
	}
	printf("started block %s \n",h2->name);
	if(ubx_block_start(h3) != 0) {
		ERR("failed to start %s",h3->name);
		goto out;
	}
	printf("started block %s \n",h3->name);
	if(ubx_block_start(ptrig) != 0) {
		ERR("failed to start %s",ptrig->name);
		goto out;
	}
	printf("started block %s \n",ptrig->name);
	if(ubx_block_start(webif) != 0) {
		ERR("failed to start %s",webif->name);
		goto out;
	}

	printf("webif block lauched on port %s \n", WEBIF_PORT);
	printf("hit enter to quit \n");
	getchar();

	ret=EXIT_SUCCESS;
 out:
	/* this cleans up all blocks and unloads all modules */
	ubx_node_cleanup(&ni);
	exit(ret);
}
