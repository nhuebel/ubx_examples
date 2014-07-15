umf=require "umf"

---
--- cmake ubx package meta-model
---
AnySpec=umf.AnySpec
NumberSpec=umf.NumberSpec
BoolSpec=umf.BoolSpec
StringSpec=umf.StringSpec
TableSpec=umf.TableSpec
ObjectSpec=umf.ObjectSpec
EnumSpec=umf.EnumSpec


pkg=umf.class("pkg")

dependencies_spec=TableSpec
{
  name="dependencies",
  array = {
    TableSpec {
      name="dependency",
      dict={ name=StringSpec{}, type=StringSpec{}, required=BoolSpec{} },
      sealed='both',
      optional={'required'},
    },
  },
  sealed='both',      
}

type_files_spec=TableSpec
{
  name="types",
  array = {
    TableSpec {
      name="type",
      dict={ name=StringSpec{}, dir=StringSpec{} },
      sealed='both',
      optional={'dir'},
    },
  },
  sealed='both',
}


block_files_spec=TableSpec
{
  name="blocks",
  array = {
    TableSpec {
      name="block",
      dict={ name=StringSpec{}, file=StringSpec{}, src_dir=StringSpec{} },
      sealed='both',
      optional={'src_dir'},
    },
  },
  sealed='both',
}

libraries_spec=TableSpec
{
  name="libraries",
  array = {
    TableSpec {
      name="library",
      dict = {name=StringSpec{}, blocks=TableSpec{ array={StringSpec{}} } },
      sealed='both',
      }
    },
  sealed='both',
}

pkg_spec = ObjectSpec {
  name="pkg",
  type=pkg,
  sealed='both',
  dict=
  {
    name=StringSpec{},
    path=StringSpec{},
    dependencies=dependencies_spec,
    types=type_files_spec,
    blocks=block_files_spec,
    libraries=libraries_spec,
  },
  optional ={'types','blocks','path','libraries'},
}
    
--- Validate a pkg model.
function pkg:validate(verbose)
   return umf.check(self, pkg_spec, verbose)
end