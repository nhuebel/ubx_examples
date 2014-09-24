#!/usr/bin/env luajit

--
-- microblx generator
-- Copyright (C) 2014 Enea Scioni <enea.scioni@unife.it>
--
--

utils=require "utils"
ansicolors=require "ansicolors"
umf=require "umf"
ubx_genblock=require "ubx_genblock"
ubx_genlib=require"ubx_genlib"
cgen=require"ubx_genbin"

local ts = tostring

--- helper, print a bright red errormsg
function errmsg(...)
   print(ansicolors.bright(ansicolors.red(table.concat({...}, ' '))))
end

--- helper, print a yellow warning msg
function warnmsg(...)
   print(ansicolors.yellow(table.concat({...}, ' ')))
end

--- helper, print a green sucess msg
function succmsg(...)
   print(ansicolors.green(table.concat({...}, ' ')))
end

-- Load package model
dofile("models/package_model.lua")

function usage()
  print( [[
generate_pkg: generate the code template of a new package for microblx block, flavored CMake.

Usage: generate_pkg [OPTIONS] -s <>
  -s         package specification file_exists (mandatory)
  -check     check package specification, don't generate it
  -force     overload existing package or files (optional)
  -b         generate c-only binary files
  -bs        buildsystem selection [cmake|make] (optional, cmake default)
  -h         show this.
]])
end

-- utility functions
function get_source_path(tgt,pkg_model)
  for i,v in pairs(pkg_model.blocks) do
    if v.name == tgt then
      return pkg_model.path.."/"..v.src_dir
    end
  end
  return ""
end

-- Create folders layout from tab
-- @param outdir main output directory (string)
-- @param tdir (table) list of subfolder names
function create_pkg_folders(outdir,tdir)
  local function _gendir(t)
    utils.foreach(function(v,k)
        if not utils.file_exists(outdir.."/"..v) then
          if os.execute("mkdir -p "..outdir.."/"..v) ~= 0 then
            errormsg("creating dir "..outdir.."/"..v.." failed")
          end
        end
      end,t)
  end
  _gendir(tdir)
end

--
--- Generate a struct type stub
-- @param data
-- @param fd file to write to (optional, default: io.stdout)
function generate_struct_type(fd, typ)
   fd = fd or io.stdout
   local res, str = utils.preproc(
[[
/* generated type stub, extend this struct with real information */

struct $(type_name) {
        /* TODO: fill in body */
};
]], { table=table, type_name=typ.name } )

   if not res then error(str) end
   fd:write(str)
end


function generate_top(fd,bm)
  fd = fd or io.stdout
  local res, str = utils.preproc(
[[
CMAKE_MINIMUM_REQUIRED(VERSION 2.6)
PROJECT($(bm.name))

set(CMAKE_CXX_FLAGS "-Wall -Werror -fvisibility=hidden")
set(CMAKE_CXX_COMPILER clang++ )
set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake") ## temporary resources, for UBX

# Global
set(INSTALL_LIB_TYPES_DIR lib/ubx/types CACHE PATH "Installation directory for types libraries")
set(INSTALL_LIB_BLOCKS_DIR lib/ubx/blocks CACHE PATH "Installation directory for blocks libraries")
set(INSTALL_BIN_APPS_DIR bin CACHE PATH "Installation directory for bin")
set(INSTALL_INCLUDE_DIR include/ubx CACHE PATH "Installation directory for header files (types)")
set(INSTALL_CMAKE_DIR  share/ubx/cmake CACHE PATH  "Installation directory for CMake files") # default ${DEF_INSTALL_CMAKE_DIR}

# Make relative paths absolute
foreach(p LIB_TYPES LIB_BLOCKS BIN INCLUDE CMAKE)
  set(var INSTALL_${p}_DIR)
  if(NOT IS_ABSOLUTE "${${var}}")
    set(${var} "${CMAKE_INSTALL_PREFIX}/${${var}}")
  endif()
endforeach()

##
# Add uninstall target.
##
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake/cmake_uninstall.cmake"
    IMMEDIATE @ONLY)
    
add_custom_target(uninstall
    "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/cmake/cmake_uninstall.cmake"
)

##
# Generate config package
##
set(CONF_INCLUDE_DIRS "${INSTALL_INCLUDE_DIR}")
set(CONF_CMAKE_DIR "${INSTALL_CMAKE_DIR}")
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/$(bm.name:gsub("_","-"))-config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake/$(bm.name:gsub("_","-"))-config.cmake" @ONLY
)

]], {table=table, bm=bm, pname=bm.name:gsub("_","-") } )
  
  if not res then error(str) end
  fd:write(str)
end

function generate_dependencies(fd,bm)
  fd = fd or io.stdout
  for i,v in ipairs(bm.dependencies) do
  local res, str = utils.preproc(
[[
find_package($(bm.name))

]], {table=table, bm=v} )
  if not res then error(str) end
  fd:write(str)
  end  
end

function generate_find_ubx(fd)
  fd = fd or io.stdout
  local str = 
[[
set (UBX_ROOT $ENV{UBX_ROOT} )
if (NOT UBX_ROOT)
 message( FATAL_ERROR "UBX_ROOT is not defined. CMake install willl abort." )
endif()

find_package(Ubx REQUIRED)

]]
  fd:write(str)
end

function generate_types(dir,bm) -- refactor me in accordance with block gen
  for i,v in ipairs(bm.types) do
    new_type = io.open(dir.."/types/"..v.name..".h","w")
    generate_struct_type(new_type,v)
    new_type:close()
    end
end

function generate_decltypes(dir,pkg)  
  local declfile = io.open(dir.."/types/"..pkg.name.."_types.c","w")
  local res, str = utils.preproc(
[[
/* generated type file source library for $(pkg.name) */

#include <stdint.h>
#include <ubx.h>

@ for _,v in pairs(pkg.types) do
#include "$(v.name).h"
#include "$(v.name).h.hexarr"
@ end

/* declare types */
ubx_type_t types[] = {
@ for _,v in pairs(pkg.types) do
        def_struct_type(struct $(v.name), &$(v.name)_h),
@ end
        { NULL },
};

static int decltypes_init(ubx_node_info_t* ni)
{
        DBG(" ");
        ubx_type_t *tptr;
        for(tptr=types; tptr->name!=NULL; tptr++) {
                /* TODO check for errors */
                ubx_type_register(ni, tptr);
        }

        return 0;
}

static void decltypes_cleanup(ubx_node_info_t *ni)
{
        DBG(" ");
        const ubx_type_t *tptr;

        for(tptr=types; tptr->name!=NULL; tptr++)
                ubx_type_unregister(ni, tptr->name);
}

UBX_MODULE_INIT(decltypes_init)
UBX_MODULE_CLEANUP(decltypes_cleanup)
UBX_MODULE_LICENSE_SPDX(BSD-3-Clause)
]], {table=table, pairs=pairs, pkg=pkg} )
  if not res then error(str) end  
  declfile:write(str)
  declfile:close()
end

function generate_pkg(dir,pkg)
  local dirfolders={"cmake","models"}
  
  if pkg.types then dirfolders[#dirfolders+1] = "types" end
  if pkg.modules then dirfolders[#dirfolders+1] = "modules" end
  if pkg.binflag then dirfolders[#dirfolders+1] = "src_bin" end
  
  create_pkg_folders(dir,dirfolders)
end

function generate_cmake_config(dir,pkg)
  
  local cap_name = pkg.name:upper()
  local filename = pkg.name:gsub("_","-")
  local cmconfig = io.open(dir.."/cmake/"..filename.."-config.cmake.in","w")
  local res, str = utils.preproc(
[[
# - Config file for the $(pkg.name) package
# It defines the following variables
#  $(cap_name)_TYPES_INCLUDE_DIRS - include directories for $(pkg.name)_types
#  $(cap_name)_TYPES_LIBRARIES    - libraries to link against
 
# Compute paths
#get_filename_component($(cap_name)_TYPES_CMAKE_DIR "${$(cap_name)_TYPES_CMAKE_DIR}" PATH)
set($(cap_name)_INCLUDE_DIRS "@CONF_INCLUDE_DIRS@")
set($(cap_name)_TYPES_CMAKE_DIR "@CONF_CMAKE_DIR@")


# Our library dependencies (contains definitions for IMPORTED targets)
if(NOT TARGET $(pkg.name) AND NOT $(cap_name)_TYPES_BINARY_DIR)
  include("${$(cap_name)_TYPES_CMAKE_DIR}/$(filename)-types-targets.cmake")
endif()
 
# These are IMPORTED targets created by $(filename)-types-targets.cmake
set($(cap_name)_TYPES_LIBRARIES $(pkg.name))
]], {table=table, pairs=pairs, pkg=pkg, cap_name = cap_name, filename=filename} )
  if not res then error(str) end  
  cmconfig:write(str)
  cmconfig:close()
end

function copy_templates(dir)
   os.execute("cp templates/cmake_uninstall.cmake.in "..dir.."/cmake/cmake_uninstall.cmake.in")
   --os.execute("cp templates/config.cmake.in "..dir.."/cmake/cmake_uninstall.cmake.in")
   os.execute("cp templates/FindUbx.cmake "..dir.."/cmake/FindUbx.cmake")
end

function generate_add_headers(fd,pkg_model)
  fd = fd or io.stdout
  local res, str = utils.preproc(
[[
include_directories(
  ${UBX_INCLUDE_DIR}
)

]], {table=table, {} } )
  if not res then error(str) end  
  fd:write(str)
end

function add_types(fd,model)
  fd = fd or io.stdout

  local str = 
[[
set(GEN_HEXARR ${UBX_ROOT}/tools/file2carr.lua)

file(GLOB types
  ${CMAKE_CURRENT_SOURCE_DIR}/types/*.h
)


set(outfiles "")
foreach( _type ${types} )
  string(REPLACE ".h" ".h.hexarr" _outfile ${_type})
  add_custom_command(
  OUTPUT ${_outfile}
  COMMAND ${GEN_HEXARR}
  ARGS ${_type}  > ${_outfile}
  )
  list(APPEND outfiles ${_outfile})
endforeach(_type)
add_custom_target( gen_hexarr ALL DEPENDS ${outfiles} )

]]
--   if not res then error(str) end  
  fd:write(str)
-- Now add library
  local res, strlib = utils.preproc(
[[
add_library($(pkg.name)_types SHARED types/$(pkg.name)_types.c)
set_target_properties($(pkg.name)_types PROPERTIES PREFIX "") 
set_property(TARGET $(pkg.name)_types PROPERTY INSTALL_RPATH_USE_LINK_PATH TRUE)
target_link_libraries($(pkg.name)_types ${UBX_LIBRARIES})
add_dependencies($(pkg.name)_types gen_hexarr)

### Install libraries
set_target_properties($(pkg.name)_types PROPERTIES PUBLIC_HEADER "${outfiles};${types}" )

install(TARGETS $(pkg.name)_types 
  EXPORT $(filename)-types-targets
  LIBRARY DESTINATION "${INSTALL_LIB_TYPES_DIR}" COMPONENT $(pkg.name)_types
  PUBLIC_HEADER DESTINATION "${INSTALL_INCLUDE_DIR}/types" COMPONENT dev
)

# Install the $(pkg.name)_types-config.cmake 
install(FILES
  "${PROJECT_BINARY_DIR}/cmake/$(filename)-config.cmake"
  DESTINATION "${INSTALL_CMAKE_DIR}" COMPONENT dev)

# Install the export set for use with the install-tree
install(EXPORT $(filename)-types-targets DESTINATION
  "${INSTALL_CMAKE_DIR}" COMPONENT dev)
  
]], {table=table, pkg = model, filename=model.name:gsub("_","-")})
  if not res then error(strlib) end  
  fd:write(strlib)
end

function generate_add_bin(fd,pm,appname)
  appname = appname or pm.name.."-conly"
  fd = fd or io.stdout
  local res, str = utils.preproc(
[[
# Compile sources for plain c-only application
add_executable($(app) src_bin/$(pm.name)-code.c)
target_link_libraries($(app) ${UBX_LIBRARIES})
@ if pm.types then
add_dependencies($(app) gen_hexarr)
@end

# install $(pm.name)_capp
install(TARGETS $(app) DESTINATION ${INSTALL_BIN_APPS_DIR} EXPORT $(app)-app)
set_property(TARGET $(app) PROPERTY INSTALL_RPATH_USE_LINK_PATH TRUE)

]], {table=table, pm=pm, app=appname} )
  if not res then error(str) end  
  fd:write(str)
end

-- refactor me - separate CMAKE and source generation, external for loop
function generate_add_libraries(fd,src_list,libs,types)
  fd = fd or io.stdout
  local res, strlib = utils.preproc(
[[
# Compile library $(v.name)
add_library($(v.name) SHARED $(src_str)
)
set_target_properties($(v.name) PROPERTIES PREFIX "")
target_link_libraries($(v.name) ${UBX_LIBRARIES})
@ if types then
add_dependencies($(v.name) gen_hexarr)
@ end

# Install $(v.name)
install(TARGETS $(v.name) DESTINATION ${INSTALL_LIB_BLOCKS_DIR} EXPORT $(v.name)-block)
set_property(TARGET $(v.name) PROPERTY INSTALL_RPATH_USE_LINK_PATH TRUE)
install(EXPORT $(v.name)-block DESTINATION ${INSTALL_CMAKE_DIR})

]], {table=table, v=libs, src_str=src_list, types=types} )
  if not res then error(strlib) end  
  fd:write(strlib)
end

function generate_module(lm,outdir,fo)
  fo = fo or false
  -- Generate module sources
local codegen_tab = {
  { fun=ubx_genlib.generate_module_header, funargs={ lm.name }, file=lm.name.."_module.h", overwrite=fo},
  { fun=ubx_genlib.generate_module_source, funargs={ lm }, file=lm.name.."_module.c", overwrite=fo},
}
  
generate(codegen_tab, outdir.."/modules", fo)
--  mh = io.open(file_name.."_module.h","w")
--  ubx_genlib.generate_libmodule_source(mh,name,nil)
--  mh:close()
end
-- function generate_blx_libraries(fd,pkg_model,bres)
--     fd = fd or io.stdout
--     if pkg_model.libraries then
--       for i,v in ipairs(pkg_model.libraries) do
--         local src_str = ""
--         for j,a in pairs(v.blocks) do
--          if bres[a] then
--            src_str = src_str..bres[a].src_name.."\n"
--          end
--         end
--         local res, str = utils.preproc(
-- [[
-- # Compile library $(bm.v.name)
-- add_library($(bm.v.name) SHARED $(bm.src_str) $(bm.v.name)_module.c
-- )
-- set_target_properties($(bm.v.name) PROPERTIES PREFIX "")
-- target_link_libraries($(bm.v.name) ${UBX_LIBRARIES})
-- @ if bm.types then
--     add_dependencies($(bm.v.name) gen_hexarr)
-- @ end
-- 
-- # Install $(bm.v.name)
-- install(TARGETS $(bm.v.name) DESTINATION ${INSTALL_LIB_BLOCKS_DIR} EXPORT $(bm.v.name)-block)
-- set_property(TARGET $(bm.v.name) PROPERTY INSTALL_RPATH_USE_LINK_PATH TRUE)
-- install(EXPORT $(bm.v.name)-block DESTINATION ${INSTALL_CMAKE_DIR})
-- 
-- ]], {table=table, bm={v=v,src_str=src_str,types=pkg_model.types}} )
--         fd:write(str)
--       
-- --         -- Generate module sources
-- --         mh = io.open(v.name.."_module.h","w")
-- --         ubx_genlib.generate_libmodule_source(mh,v.name,nil)
-- --         mh:close()
-- --       end
--     end
-- end

-- --- Generate code according to the given code generation table.
-- -- For each entry in code_gen_table, open file and call fun passing
-- -- block_model as first and the file handle as second arg
-- -- @param cgt code generate table
-- -- @param outdir directory prefix
-- -- @param force_overwrite ignore overwrite flag on individual entries
function generate(cgt, outdir, force_overwrite)

   local function file_open(fn, overwrite)
      if not overwrite and utils.file_exists(fn) then return false end
      return assert(io.open(fn, "w"))
   end

   utils.foreach(function(e)
                    local file = outdir.."/"..e.file
                    local fd = file_open(file, e.overwrite or force_overwrite)
                    if fd then
                       print("    generating ".. file)
                       e.fun(fd, unpack(e.funargs))
                       fd:close()
                    else
                       print("    skipping existing "..file)
                    end
                 end, cgt)
end


function generate_blocks(outdir,force_overwrite,pm)
  local blocklog = {}
  for i,v in ipairs(pm.blocks) do 

    
    local suc, block_model = pcall(dofile, v.file)
    if not suc then
     print(block_model)
     errmsg("Failed to load block config file "..ts(v.file)..": file not found. Creation block "..v.name.." failed!")
     warnmsg("TIP: check the package model")
     return
    end

    if block_model:validate(false) > 0 then
     block_model:validate(true)
     errmsg("block "..v.name.." has not been validated! Creation failed")
     warnmsg("TIP: check the block model")
     return
    end
    local c_ext = '.c'
    local h_ext = '.h'
    
    if block_model.cpp then c_ext = '.cpp' end
    if block_model.cpp then h_ext = '.hpp' end
    
    local dir = outdir
    if v.src_dir~=nil then
      dir = outdir.."/"..v.src_dir
      if not utils.file_exists(dir) then
        if os.execute("mkdir -p "..dir) ~= 0 then
          print("creating dir "..dir.." failed")
          return
        end
      end
    end
    
    local codegen_tab = {
     { fun=ubx_genblock.generate_block_if, funargs={ block_model, outdir } , file=block_model.name..h_ext, overwrite=true },
     { fun=ubx_genblock.generate_block_body, funargs={ block_model }, file=block_model.name..c_ext, overwrite=false },
     { fun=ubx_genblock.generate_bd_system, funargs={ pm, block_model, dir }, file=block_model.name..".usc", overwrite=false },
    }
   generate(codegen_tab, dir, force_overwrite)
   blocklog[v.name] = {src_name=dir.."/"..block_model.name..c_ext}
  end
  return blocklog
end

---
-- Program enters here
-----------------------------------
local opttab=utils.proc_args(arg)

local block_model_file
local force_overwrite
local appname

if #arg==1 or opttab['-h'] then usage(); os.exit(1) end

-- load and check config file
if not (opttab['-s'] and opttab['-s'][1]) then
   errmsg("missing specification file option (-s)"); os.exit(1)
end

pkg_model_file=opttab['-s'][1]

local suc, pkg_model = pcall(dofile, pkg_model_file)

if not suc then
   print(pkg_model)
   errmsg("ubx_cmake failed to load pkg specification file ")
   os.exit(1)
end

if pkg_model:validate(false) > 0 then
   pkg_model:validate(true)
   os.exit(1)
end

-- only check, don't generate
if opttab['-check'] then
   succmsg("Specification Validated!")
   os.exit(1)
end

if opttab['-force'] then
   force_overwrite=true
end

if opttab['-b'] then
  pkg_model.binflag=true
  appname=opttab['-b'][1]
  if not appname then
    warnmsg("The c-only binary will be generated, with a default name")
  end
end

if opttab['-bs'] then
  warnmsg("Building System selection not implemented yet")
end

-- handle output directory (TODO write it better)
local outdir

if not (opttab['-d'] and opttab['-d'][1]) then
   warnmsg("missing output directory (-d), using default from model");
   if pkg_model.path ~= nil then
     outdir = pkg_model.path.."/"..pkg_model.name
   else
     errmsg("output directory not defined")
     os.exit(1)
   end
else
  outdir=opttab['-d'][1]
end


generate_pkg(outdir,pkg_model)

--- Generate files
-- TYPES
if pkg_model.types then
  generate_types(outdir,pkg_model)
  generate_decltypes(outdir,pkg_model)
end

copy_templates(outdir)
local bres = {}
if pkg_model.blocks then
  dofile("models/block_model.lua")
  bres = generate_blocks(outdir,force_overwrite,pkg_model)
  if not bres then os.exit(1) end
end


-- Generate CMakeLists
file=io.open(outdir.."/CMakeLists.txt","w")
generate_top(file,pkg_model)
generate_find_ubx(file)

if pkg.dependencies then
  generate_dependencies(file,pkg_model)
end

generate_add_headers(file,pkg_model)

if pkg_model.types then
  add_types(file,pkg_model)
end

generate_cmake_config(outdir,pkg_model)

if pkg_model.modules then
  
-- First add to CMakeLists.txt
  local cgen_tab = {}
  for i,v in ipairs(pkg_model.modules) do

    local src_str = ""
    for j,a in pairs(v.blocks) do
      if bres[a] then
        src_str = src_str..bres[a].src_name.."\n"
      end
    end
    src_str = src_str..outdir.."/modules/"..v.name.."_module.c"
    if pkg_model.types then
      generate_add_libraries(file,src_str,v,true)  
    else
      generate_add_libraries(file,src_str,v,false)
    end
    
    --Then, generate module files
    generate_module(v,outdir)
  end

  if pkg_model.binflag then
    generate( { {fun=cgen.generate_c_binary, funargs={ pkg_model },--funargs={  {{ name="transfer", blocks={"cpp_sender","cpp_receiver"} }} },
                  file=pkg_model.name.."-code.c", overwrite=false } },
                  outdir.."/src_bin", force_overwrite)
    generate_add_bin(file,pkg_model,appname)
  end
end

-- warnmsg(get_source_path("cpp_sender",pkg_model))


-- generate_blx_libraries(file,pkg_model,bres) --check existance inside
io.close(file)

-- Everything went fine! - Export models
modelspath = outdir.."/models"
print("    export models in "..modelspath)

os.execute("cp "..pkg_model_file.." "..modelspath.."/")
if pkg_model.blocks then
  for _,v in ipairs (pkg_model.blocks) do
    os.execute("cp "..v.file.." "..modelspath.."/")
  end
end