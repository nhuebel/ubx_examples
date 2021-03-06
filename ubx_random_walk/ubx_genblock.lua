--
-- microblx block generator
-- Copyright (C) 2014 Enea Scioni <enea.scioni@unife.it>
-- Copyright (C) 2013 Markus Klotzbuecher <markus.klotzbuecher@mech.kuleuven.be>
--

local utils = require "utils"

local M = {}

--- Generate type read/write helpers
-- @param block_model
-- @return string
local function generate_rd_wr_helpers(bm)
   -- extract a suitable name from the type
   local function find_name(n)
      local nm = string.match(n, "%s*struct%s+([%w_]+)")
      if nm then return nm end
      return utils.trim(n)
   end

   -- remove duplicates
   local function filter_dupes(lst)
      local res = {}
      local track = {}
      for _,v in ipairs(lst) do
         if not track[v] then res[#res+1] = v; track[v]=true; end
      end
      return res
   end

   local res = {}
   for _,p in ipairs(bm.ports or {}) do
      if p.in_type_name then
         if not p.in_data_len or p.in_data_len == 1 then
            res[#res+1] = utils.expand("def_read_fun(read_$name, $type_name)",
                                       { name=find_name(p.name), type_name=p.in_type_name })
         else -- in_data_len > 1
            res[#res+1] = utils.expand("def_read_arr_fun(read_$name_$len, $type_name, $len)",
                                       { name=find_name(p.name), type_name=p.in_type_name, len=p.in_data_len })
         end
      elseif p.out_type_name then
         if not p.out_data_len or p.out_data_len == 1 then
            res[#res+1] = utils.expand("def_write_fun(write_$name, $type_name)",
                                       { name=find_name(p.name), type_name=p.out_type_name })
         else -- ou_data_len > 1
            res[#res+1] = utils.expand("def_write_arr_fun(write_$name_$len, $type_name, $len)",
                                       { name=find_name(p.name), type_name=p.out_type_name, len=p.out_data_len })
         end
      end
   end

   return table.concat(filter_dupes(res), "\n")
end

--- Generate an entry in a port declaration.
-- Moved out due to improve readability of the conditional
-- @param t type entry
-- @return designated C initializer string
local function gen_port_decl(t)
   t.in_data_len = t.in_data_len or 1
   t.out_data_len = t.out_data_len or 1
   t.doc = t.doc or ''

   if t.in_type_name and t.out_type_name then
      return utils.expand('{ .name="$name", .out_type_name="$out_type_name", .out_data_len=$out_data_len, .in_type_name="$in_type_name", .in_data_len=$in_data_len, .doc="$doc" },', t)
   elseif t.in_type_name then
      return utils.expand('{ .name="$name", .in_type_name="$in_type_name", .in_data_len=$in_data_len, .doc="$doc"  },', t)
   elseif t.out_type_name then
      return utils.expand('{ .name="$name", .out_type_name="$out_type_name", .out_data_len=$out_data_len, .doc="$doc"  },', t)
   end
end

-- local function generate_headers(bm)
--   local headers_str = ""
--   for _,t in ipairs(bm.types or {})
--   if utils.file_exists(t.name..".h") and utils.file_exists(t.name..".h.hexarr")
--     utils.preproc(
-- [[
-- #include "types/$(t.name).h"
-- #include "types/$(t.name).h.hexarr"
-- ]], {table=table,
--     headers_str = headers_str + 
--   end
--   
--   return headers_str
-- end
--- Generate the interface of an ubx block.
-- @param bm block model
-- @param fd open file to write to (optional, default: io.stdout)
-- @param outdir main output folder
function generate_block_if(fd, bm, outdir)
   fd = fd or io.stdout
   local res, str = utils.preproc(
[[
/*
 * $(bm.name) microblx function block (autogenerated, don't edit)
 */

#include <ubx.h>

/* includes types and type metadata */
@ for _,t in ipairs(bm.types or {}) do
@ if utils.file_exists(t.name..".h") then --and utils.file_exists(t.name..".h.hexarr") then
#include "$(t.name).h"
#include "$(t.name).h.hexarr"
@ elseif utils.file_exists(outdir.."/types/"..t.name..".h") then --and utils.file_exists("../types/"..t.name..".h.hexarr") then
#include "../types/$(t.name).h"
#include "../types/$(t.name).h.hexarr"
@ else
#include <$(t.name).h>
#include <$(t.name).h.hexarr>
@ end
@ end


/* block meta information */
char $(bm.name)_meta[] =
        " { doc='',"
        "   real-time=true,"
        "}";

/* declaration of block configuration */
ubx_config_t $(bm.name)_config[] = {
@ for _,c in ipairs(bm.configurations or {}) do
@       c.doc=c.doc or ""
        { .name="$(c.name)", .type_name = "$(c.type_name)", .doc="$(c.doc)" },
@ end
        { NULL },
};

/* declaration port block ports */
ubx_port_t $(bm.name)_ports[] = {
@ for _,p in ipairs(bm.ports or {}) do
        $(gen_port_decl(p))
@ end
        { NULL },
};

/* declare a struct port_cache */
struct $(bm.name)_port_cache {
@ for _,t in ipairs(bm.ports or {}) do
        ubx_port_t* $(t.name);
@ end
};

/* declare a helper function to update the port cache this is necessary
 * because the port ptrs can change if ports are dynamically added or
 * removed. This function should hence be called after all
 * initialization is done, i.e. typically in 'start'
 */
static void update_port_cache(ubx_block_t *b, struct $(bm.name)_port_cache *pc)
{
@ for _,t in ipairs(bm.ports or {}) do
        pc->$(t.name) = ubx_port_get(b, "$(t.name)");
@ end
}


/* for each port type, declare convenience functions to read/write from ports */
$(generate_rd_wr_helpers(bm))

/* block operation forward declarations */
int $(bm.name)_init(ubx_block_t *b);
@ if bm.operations.start then
int $(bm.name)_start(ubx_block_t *b);
@ end
@ if bm.operations.stop then
void $(bm.name)_stop(ubx_block_t *b);
@ end
void $(bm.name)_cleanup(ubx_block_t *b);
@ if bm.operations.step then
void $(bm.name)_step(ubx_block_t *b);
@ end


/* put everything together */
ubx_block_t $(bm.name)_block = {
        .name = "$(bm.name)",
        .type = BLOCK_TYPE_COMPUTATION,
        .meta_data = $(bm.name)_meta,
        .configs = $(bm.name)_config,
        .ports = $(bm.name)_ports,

        /* ops */
        .init = $(bm.name)_init,
@ if bm.operations.start then
        .start = $(bm.name)_start,
@ end
@ if bm.operations.stop then
        .stop = $(bm.name)_stop,
@ end
        .cleanup = $(bm.name)_cleanup,
@ if bm.operations.step then
        .step = $(bm.name)_step,
@ end
};


/* $(bm.name) module init and cleanup functions */
int $(bm.name)_mod_init(ubx_node_info_t* ni)
{
        DBG(" ");
        int ret = -1;

        if(ubx_block_register(ni, &$(bm.name)_block) != 0)
                goto out;

        ret=0;
out:
        return ret;
}

void $(bm.name)_mod_cleanup(ubx_node_info_t *ni)
{
        DBG(" ");
        ubx_block_unregister(ni, "$(bm.name)");
}

]], { gen_port_decl=gen_port_decl, ipairs=ipairs, table=table, utils=utils, outdir=outdir,
      bm=bm, generate_rd_wr_helpers=generate_rd_wr_helpers } )

   if not res then error(str) end
   fd:write(str)
end


--- Generate the interface of an ubx block.
-- @param bm block model
-- @param fd open file to write to (optional, default: io.stdout)
function generate_block_body(fd, bm)
   fd = fd or io.stdout
   local res, str = utils.preproc(
[[

@ if bm.cpp then
#include "$(bm.name).hpp"
@ else
#include "$(bm.name).h"
@ end

/* define a structure for holding the block local state. By assigning an
 * instance of this struct to the block private_data pointer (see init), this
 * information becomes accessible within the hook functions.
 */
struct $(bm.name)_info
{
        /* add custom block local data here */

@ if bm.port_cache then
        /* this is to have fast access to ports for reading and writing, without
         * needing a hash table lookup */
        struct $(bm.name)_port_cache ports;
@ end
};

/* init */
int $(bm.name)_init(ubx_block_t *b)
{
        int ret = -1;
        struct $(bm.name)_info *inf;

        /* allocate memory for the block local state */
        if ((inf = (struct $(bm.name)_info*)calloc(1, sizeof(struct $(bm.name)_info)))==NULL) {
                ERR("$(bm.name): failed to alloc memory");
                ret=EOUTOFMEM;
                goto out;
        }
        b->private_data=inf;
        update_port_cache(b, &inf->ports);
        ret=0;
out:
        return ret;
}

@ if bm.operations.start then
/* start */
int $(bm.name)_start(ubx_block_t *b)
{
        /* struct $(bm.name)_info *inf = (struct $(bm.name)_info*) b->private_data; */
        int ret = 0;
        return ret;
}
@ end

@ if bm.operations.stop then
/* stop */
void $(bm.name)_stop(ubx_block_t *b)
{
        /* struct $(bm.name)_info *inf = (struct $(bm.name)_info*) b->private_data; */
}
@ end

/* cleanup */
void $(bm.name)_cleanup(ubx_block_t *b)
{
        free(b->private_data);
}

@ if bm.operations.step then
/* step */
void $(bm.name)_step(ubx_block_t *b)
{
        /*
        struct $(bm.name)_info *inf = (struct $(bm.name)_info*) b->private_data;
        */
}
@ end

]], { table=table, bm=bm } )

   if not res then error(str) end
   fd:write(str)
end

--- Generate a simple blockdiagram interface of an ubx block.
-- @param bm block model
-- @param fd open file to write to (optional, default: io.stdout)
function generate_bd_system(fd, pm, bm, outdir)
   fd = fd or io.stdout
   local res, str = utils.preproc(
[[
-- a minimal blockdiagram to start the block

return bd.system
{
   imports = {
      "std_types/stdtypes/stdtypes.so",
      "std_blocks/ptrig/ptrig.so",
      "std_blocks/lfds_buffers/lfds_cyclic.so",
      "std_blocks/logging/file_logger.so",
@  for i,v in pairs(pm.modules) do
@    for _,k in pairs(v.blocks) do
@      if k == bm.name then
      "blocks/$(v.name).so",
@         break
@      end
@    end
@  end
   },

   blocks = {
      { name="$(bm.name)_1", type="$(bm.name)" },
   },
}

]], { table=table, pairs=pairs, pm=pm, bm=bm, outdir=outdir } )

   if not res then error(str) end
   fd:write(str)
end

-- exports
M.generate_bd_system = generate_bd_system
M.generate_block_body = generate_block_body
M.generate_block_if = generate_block_if

return M