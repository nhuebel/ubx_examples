return block 
{
      name="random_walk_iblock",
      meta_data="storing the value of the random walk",
      port_cache=true,

      types = {
	 { name="vector", class='struct' }, -- Enum will follow once implemented in C
	 { name="value", class='struct' }
      },

      configurations= {
	 { name="init_value", type_name="value", len=1 },
      },

      ports = {
	 { name="change", in_type_name="vector", in_data_len=1, doc="cahnge of the stored value" },
	 { name="value", out_type_name="value", doc="current value of the random walk" },
      },
      
      operations = { start=true, stop=true, step=false },

      cpp = true
}
