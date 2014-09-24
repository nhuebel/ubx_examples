/* generated type stub, extend this struct with real information */

struct distribution_name {

    char model[20]; // This should be a URL to the data model
    char uid[20]; // This should be a unique id to identify this data type
    char meta_model[20]; // This should be a URL to the meta model
    char dirstr_name[20]; // the actually data. In our example, the name of the distribution
    int seed; //seed for the random number generator
    float max_step_size; // max step size that the random_walk is allowed to do
};
