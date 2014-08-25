/* generated type stub, extend this struct with real information */

struct var_array_values {
    char model[20]; // This should be a URL to the data model
    char uid[20]; // This should be a unique id to identify this data type
    char meta_model[20]; // This should be a URL to the meta model
    int value_arr_len; // the length of the array containing the values
    float *value_arr; // pointer to the actual data
};
