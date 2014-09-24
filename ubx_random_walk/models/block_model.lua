umf=require "umf"

---
--- ubx block meta-model
---
AnySpec=umf.AnySpec
NumberSpec=umf.NumberSpec
BoolSpec=umf.BoolSpec
StringSpec=umf.StringSpec
TableSpec=umf.TableSpec
ObjectSpec=umf.ObjectSpec
EnumSpec=umf.EnumSpec

block=umf.class("block")
iblock=umf.class("iblock")

-- types
types_spec=TableSpec{
   name="types",
   array = {
      TableSpec {
         name="type",
         dict={ name=StringSpec{}, class=EnumSpec{ "struct" }, doc=StringSpec{} },
         sealed='both',
         optional={ 'doc' },
      },
   },
   sealed='both'
}

-- configurations
configurations_spec=TableSpec{
   name="configurations",
   array = {
      TableSpec {
         name="configuration",
         dict={ name=StringSpec{}, type_name=StringSpec{}, len=NumberSpec{min=1}, doc=StringSpec{} },
         sealed='both',
         optional={ 'len', 'doc' },
      },
   },
   sealed='both'
}

-- configurations
ports_spec=TableSpec{
   name="ports",
   array = {
      TableSpec {
         name="port",
         dict={
            name=StringSpec{},
            in_type_name=StringSpec{},
            in_data_len=NumberSpec{ min=1 },
            out_type_name=StringSpec{},
            out_data_len=NumberSpec{ min=1 },
            doc=StringSpec{}
         },
         sealed='both',
         optional={ 'in_type_name', 'in_data_len', 'out_type_name', 'out_data_len', 'doc' }
      },
   },
   sealed='both'
}

block_spec = ObjectSpec {
   name="block",
   type=block,
   sealed="both",
   dict={
      name=StringSpec{},
      meta_data=StringSpec{},
      cpp=BoolSpec{},
      port_cache=BoolSpec{},
      types=types_spec,
      configurations=configurations_spec,
      ports=ports_spec,
      operations=TableSpec{
         name='operations',
         dict={
            start=BoolSpec{},
            stop=BoolSpec{},
            step=BoolSpec{},
         },
         sealed='both',
         optional={ "start", "stop", "step" },
      },
   },
   optional={ 'meta_data', 'cpp', 'types', 'configurations', 'ports' },
}

iblock_spec = ObjectSpec {
   name="iblock",
   type=iblock,
   sealed="both",
   dict={
      name=StringSpec{},
      meta_data=StringSpec{},
      cpp=BoolSpec{},
      port_cache=BoolSpec{},
      types=types_spec,
      configurations=configurations_spec,
      ports=ports_spec,
      operations=TableSpec{
         name='operations',
         dict={
            read=BoolSpec{},
            write=BoolSpec{},
         },
         sealed='both',
         optional={ "read", "write" },
      },
   },
   optional={ 'meta_data', 'cpp', 'types', 'configurations', 'ports' },
}
            
--- Validate a block model.
function block:validate(verbose)
   return umf.check(self, block_spec, verbose)
end

--- Validate a iblock model.
function iblock:validate(verbose)
  return umf.check(self, iblock_spec, verbose)
end
