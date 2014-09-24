--
-- microblx block binary executable generator
-- Copyright (C) 2014 Enea Scioni <enea.scioni@unife.it>
--
--

local utils = require "utils"
local ubx_env = require "ubx_env"

local M = {}

function generate_c_binary(fd,pm)
  fd = fd or io.stdout
  local rootpath = os.getenv("UBX_ROOT")
  local modulespath = os.getenv("UBX_MODULES")
  if not rootpath or not modulespath then
    error("UBX_ROOT and UBX_MODULES are required to generate a c-binary source")
  end
  
  local res, str = utils.preproc(
[[
/* Standalone C-only system (no scripting layer).
 *   This source is autogenerate, but yet incomplete.
 *  Please add manually system implementations.
 */

#include <ubx.h>

#define WEBIF_PORT      "8888"

int main(int argc, char **argv)
{
        int len, ret=EXIT_FAILURE;
        ubx_node_info_t ni;
        ubx_block_t *webif;
@ for _,v in pairs(pm.modules) do
@   for x,b in pairs(v.blocks) do
        ubx_block_t *$(b);
@   end
@ end
        ubx_data_t *d;

        /* initalize the node */
        ubx_node_init(&ni, "c-only");

        /* FIRST, LOAD ALL MODULES */
        /* load the standard types */
        if(ubx_module_load(&ni, "$(root)/std_types/stdtypes/stdtypes.so") != 0)
                goto out;
                
@ if pm.types then
          /* load $(pm.name) types */
        if(ubx_module_load(&ni, "$(modules)/types/$(pm.name)_types.so") != 0)
                goto out;
@ end

        /* load the web-interface block */
        if(ubx_module_load(&ni, "$(root)/std_blocks/webif/webif.so") != 0)
                goto out;
                
@ for _,v in pairs(pm.modules) do
        /* load library $(v.name)*/
        if(ubx_module_load(&ni, "$(modules)/blocks/$(v.name).so") != 0)
                goto out;

@ end
        /* create a webserver block */
        if((webif = ubx_block_create(&ni, "webif/webif", "webif1"))==NULL)
                goto out;

@ for _,v in pairs(pm.modules) do
@   for x,b in pairs(v.blocks) do
        /* create block $(b)*/
        if(($(b) = ubx_block_create(&ni, "$(b)", "$(b)_1"))==NULL)
                goto out;
                
@   end
@ end

        /* Configure port of webserver block
         * this gets the ubx_data_t pointer */
        d = ubx_config_get_data(webif, "port");
        len = strlen(WEBIF_PORT)+1;

        /* resize the char array as necessary and copy the port string */
        ubx_data_resize(d, len);
        strncpy(d->data, WEBIF_PORT, len);
        
        /* INIT and START blocks */
        /*   web interface           */
        if(ubx_block_init(webif) != 0) {
                ERR("failed to init webif");
                goto out;
        }

        if(ubx_block_start(webif) != 0) {
                ERR("failed to start webif");
                goto out;
        }

        printf("webif block lauched on port %s\n", WEBIF_PORT);
        
@ for _,v in pairs(pm.modules) do
@   for x,b in pairs(v.blocks) do
        /*  $(b) block init and start     */
        if(ubx_block_init($(b)) != 0) {
                ERR("failed to init $(b)");
                goto out;
        }

        if(ubx_block_start($(b)) != 0) {
                ERR("failed to start $(b)");
                goto out;
        }
        
        printf("$(b) block lauched\n");
        
  @  end
@ end

        printf("Everything is up and running! hit enter to quit\n");
        getchar();

        ret=EXIT_SUCCESS;
 out:
        /* this cleans up all blocks and unloads all modules */
        ubx_node_cleanup(&ni);
        exit(ret);
}
]], {table=table, pairs=pairs, pm=pm, root=rootpath, modules=modulespath})

  if not res then error(str) end
  fd:write(str)
end


-- Generate a c-only application starting from an usc file
-- @param fd  source file to be filled in (default, io.stdout)
-- @param sys bd.system blockdiagram model (from usc file)
-- @param name name application
function sys2c(fd,sys,name,webif)
    fd = fd or io.stdout
    name = name or "ubx_app"
    
    -- paranoid mode (check if block model is loaded)
    local block_spec
    if not block_spec then
      dofile("models/block_model.lua")
    end
    
    -- Get configs types
    local function _get_config(blx)
      local config = {}
      local mfile = ubx_env.fetch_block_model(blx)
      local suc, m = pcall(dofile,mfile)
      if not suc then return config end
      if m:validate(false) > 0 then return config end
      if m.configurations then
        utils.foreach(function(v,k)
            config[v.name] = v.type_name
          end,m.configurations)
      end
      
      return config
    end
    
    -- Solving libs path
    local function _findlibs(imports)
      local libs = {}
      utils.foreach(function(v,k)
         if utils.file_exists(v) then
           libs[#libs+1] = v
         elseif utils.file_exists(ubx_env.get_ubx_root()..v) then
           libs[#libs+1] = ubx_env.get_ubx_root()..v
         elseif utils.file_exists(ubx_env.get_ubx_modules()..v) then
           libs[#libs+1] = ubx_env.get_ubx_modules()..v
         end
      end,imports)
      
      return libs
    end
    
    local function _revert_blx_table(t)
      local blx = {}
      utils.foreach(function(v,k) blx[v.name]=k end,t)
      return blx
    end
    
    
    local function _setconfig(blx,configs,blocks,configlist)

          
    local function _stuff(bname,index,varname,typename,configs)
        local res, str = "",""
        
        if type(typename)=='string' then
          res, str = utils.preproc(
[[
  
  d = ubx_config_get_data($(bname)_$(index),"$(varname)");
  ubx_data_resize(d,strlen("$(typename)")+1);
  strncpy(d->data,"$(typename)",strlen("$(typename)")+1);
]], {table=table,bname=bname,index=index,varname=varname,typename=typename } )
        elseif type(typename)=='number' then
          res, str = utils.preproc(
[[
  
  d = ubx_config_get_data($(bname)_$(index),"$(varname)");
  ubx_data_resize(d,data_size(d));
@ local dtype = cglist[bname][varname]
  *($(dtype)*)(d->data) = ($(dtype))($(typename));
]], {table=table,bname=bname,index=index,varname=varname,typename=typename,cglist=configs} )
        elseif type(typename)=='table' then
          
          local dtype = configs[bname]
          local dstype = dtype[varname]
         
          local function _retval(val)
            if type(val)=='string' and val:sub(1,1) then
              return val:sub(2,#val).."_"..blx[val:sub(2,#val)]
            else
              return tostring(val)
            end
          end
          
          local function _recs(t)
            local l = {}
              utils.foreach(function(v,k) l[#l+1] = "."..tostring(k).."=".._retval(v)
              end,t)
            return l
          end
          
          local lf = {}
          for i,v in pairs(typename) do 
            if type(v)=='table' then
              lf[#lf+1] = "{ "..table.concat(_recs(v),", ").."},"
            else 
              lf[#lf+1] = "{ "..table.concat(_recs(typename),", ").."};"
              break
            end
          end

          res, str = utils.preproc(
[[
  
  d = ubx_config_get_data($(bname)_$(index),"$(varname)");
@ local size= #typename
@ if size == 0 then
  *($(strname)*)(d->data) = ($(strname)) $(lf[1])
@ else
  ubx_data_resize(d,$(size));
    memcpy(d->data,
    ($(strname) []){
@ for i,v in pairs(lf) do
      $(v)
@ end
      { NULL },
    },    
    sizeof($(strname))*$(size)
  );
@ end

]], {table=table,pairs=pairs,bname=bname,index=index,varname=varname,typename=typename,strname=dstype,lf=lf} )
        end
        
      if not res then error(str) end
        return str
    end
      
      local res, str = utils.preproc(
[[
@ for i,v in pairs(configs) do
@   local index = blx[v.name] 
  /* configuration of $(v.name)_$(index)  */
@   for j,k in pairs(v.config) do
@     local bla = stuff(v.name,index,j,k,cglist)
      $(bla)
@   end
@ end
]], {table=table, pairs=pairs, blx=blx,configs=configs,type=type,blocks=blocks,cglist=configlist,stuff=_stuff,ts=tostring} )

    if not res then error(str) end
--       print(str)
      return str
   end
    
   local function _setheaders(conftab,confblx)
     local headers = ""
     
     -- this is fine, but for dev reasons I need to fetch from env, and check existance
     for i,v in pairs(conftab) do
       for a,b in pairs(v.config) do
         local q,w = unpack(utils.split(confblx[v.name][a],"% "))
         if q == "struct" and w then
           headers = headers.."#include <types/"..w..".h>\n"
         end
       end
     end
     return headers
   end
   
    local libs = _findlibs(sys.imports)
    local blx  = _revert_blx_table(sys.blocks)
    
    local configlist = {}
    utils.foreach(function(v,k) configlist[v.name]=_get_config(v.type) end, sys.blocks )

    
    --testing

    local configstr = _setconfig(blx,sys.configurations,sys.blocks,configlist)
    local headerstr = _setheaders(sys.configurations,configlist)
    
    local res, str = utils.preproc(
[[
/* Standalone C-only system (no scripting layer).
 *   This source has been autogenerated
 *     from a usc system description.
 *    Autogenerated with generate_capp tool.
 */

#include <ubx.h>

/* Additional header files for types */
$(headerstr)

@if webif then
#define WEBIF_PORT      "8888"
@ end
@ local ie = #blx+1
int main(int argc, char **argv)
{
  int len, ret=EXIT_FAILURE;
  ubx_node_info_t ni;
//   char* tmp_char;
  /* initalize the node */
  ubx_node_init(&ni, "$(name)");
@if webif then
  ubx_block_t *webif;
@ end
    ubx_data_t *d;
@for i,v in pairs(blx) do
  ubx_block_t *$(i)_$(v);
@end

  /* Load Modules */
@ for _,v in pairs(libs) do
  if(ubx_module_load(&ni, "$(v)") != 0)
    goto out;
  
@ end

@ if webif then
  /* load the web-interface block */
@ local r = root()
  if(ubx_module_load(&ni, "$(r)std_blocks/webif/webif.so") != 0)
    goto out;
    
@ end
  printf("All modules have been loaded!\n");
  
  /* Create blocks */
@for i,v in pairs(blocks) do
@  local index = blx[v.name]  
  /* create $(v.name) block, instance of $(v.type) */
  if(($(v.name)_$(index) = ubx_block_create(&ni, "$(v.type)", "$(v.name)_$(index)"))==NULL)
    goto out;
    
@ end
@ if webif then  
  /* create a webserver block */
  if((webif = ubx_block_create(&ni, "webif/webif", "webif1"))==NULL)
    goto out;
@ end
  
  printf("All modules have been created!\n");
  
  /* Configure blocks */
  $(configstr)

@ if webif then  
  /* Configure port of webserver block
  * this gets the ubx_data_t pointer */
  d = ubx_config_get_data(webif, "port");
  len = strlen(WEBIF_PORT)+1;
    
  /* resize the char array as necessary and copy the port string */
  ubx_data_resize(d, len);
  strncpy(d->data, WEBIF_PORT, len);
@ end        
  
@ if cnlist then
  /* Connect blocks            */
@for i,v in pairs(cnlist) do
@  local bnamesrc,pnamesrc = unpack(split(v.src, "%."))
@  local bnametgt,pnametgt = unpack(split(v.tgt, "%."))
@  local index_tgt = blx[bnametgt] 
@  local index_src = blx[bnamesrc]
@  if pnamesrc==nil then
  ubx_port_connect_in(ubx_port_get($(bnametgt)_$(index_tgt),"$(pnametgt)" ), $(bnamesrc)_$(index_src) ); 
@  elseif pnametgt==nil then
  ubx_port_connect_out(ubx_port_get($(bnamesrc)_$(index_src),"$(pnamesrc)" ), $(bnametgt)_$(index_tgt) );
@  else
  {
    ubx_block_t* ib=ubx_block_create(&ni, "lfds_buffers/cyclic", "ib_$(ie)");
    d = ubx_config_get_data(ib,"buffer_len");
    ubx_data_resize(d,data_size(d));
    *(uint32_t*)(d->data) = (uint32_t)(1);
    d = ubx_config_get_data(ib,"type_name");
    ubx_data_resize(d,strlen("struct cpp_data")+1);
    strncpy(d->data,"struct cpp_data",strlen("struct cpp_data")+1);
    ubx_ports_connect_uni( ubx_port_get($(bnamesrc)_$(index_src),"$(pnamesrc)" ),
      ubx_port_get($(bnametgt)_$(index_tgt),"$(pnametgt)" ),ib);
    ubx_block_init(ib);
    ubx_block_start(ib);
@  ie = ie+1
  }
@ end
@end
@end

  /* INIT and START the BLOCKS */
@for i,v in pairs(blx) do
  if(ubx_block_init($(i)_$(v)) != 0) {
    ERR("failed to init $(i)_$(v)");
    goto out;
  }
@ end  
  printf("All blocks have been initialized!\n");

@for i,v in pairs(blx) do
  if(ubx_block_start($(i)_$(v)) != 0) {
    ERR("failed to start $(i)_$(v)");
    goto out;
  }
@ end
  printf("All blocks have been started!\n");
  
@if webif then  
  /*        web interface       */
  if(ubx_block_init(webif) != 0) {
    ERR("failed to init webif");
    goto out;
  }

  if(ubx_block_start(webif) != 0) {
    ERR("failed to start webif");
    goto out;
  }
  printf("webif block lauched on port %s\n", WEBIF_PORT);
@end
    
  printf("Everything is up and running! hit enter to quit\n");
  getchar();

  ret=EXIT_SUCCESS;
out:
  /* this cleans up all blocks and unloads all modules */
  ubx_node_cleanup(&ni);
  exit(ret);  
}

]] , {table=table, pairs=pairs, name=name, libs=libs, blocks=sys.blocks, blx=blx, cglist=configlist,
    cnlist=sys.connections, type=type, configs=sys.configurations, webif=webif, split=utils.split, configstr=configstr,
    headerstr=headerstr,
    unpack=unpack, root=ubx_env.get_ubx_root})
    
  if not res then error(str) end
  fd:write(str)
end

-- exports
M.generate_c_binary = generate_c_binary
M.sys2c = sys2c

return M