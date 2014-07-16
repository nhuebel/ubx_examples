return block 
{
      name="random_walk_cblock",
      meta_data="cblock modifying the random_walk_iblock according to configured distribution",
      port_cache=true,

      types = {
	 { name="vector", class='struct' }, -- Enum will follow once implemented in C
	 { name="distribution", class='struct' },
      },

      configurations= {
	 { name="distribution", type_name="double", len=5 },
      },

      ports = {
	 { name="change", out_type_name="vector", out_data_len=1, doc="change of the value of the random walk" },
      },
      
      operations = { start=true, stop=true, step=true },

      cpp = true
}
