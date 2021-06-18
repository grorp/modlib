-- Lua version check
if _VERSION then
	if _VERSION < "Lua 5" then
		error("Outdated Lua version! modlib requires Lua 5 or greater.")
	end
	if _VERSION > "Lua 5.1" then
		-- not throwing error("Too new Lua version! modlib requires Lua 5.1 or smaller.") anymore
		unpack = unpack or table.unpack -- unpack was moved to table.unpack in Lua 5.2
		loadstring = load
		function setfenv(fn, env)
			local i = 1
			while true do
				local name = debug.getupvalue(fn, i)
				if name == "_ENV" then
					debug.setupvalue(fn, i, env)
					break
				elseif not name then
					break
				end
			end
			return fn
		end
		function getfenv(fn)
			local i = 1
			local name, val
			repeat
				name, val = debug.getupvalue(fn, i)
				if name == "_ENV" then
					return val
				end
				i = i + 1
			until not name
		end
	end
end

local modules = {}
for _, file in pairs{
	"schema",
	"file",
	"func",
	"math",
	"table",
	"text",
	"vector",
	"quaternion",
	"trie",
	"kdtree",
	"heap",
	"ranked_set",
	"binary",
	"b3d",
	"bluon",
	"persistence",
	"debug"
} do
	modules[file] = file
end
if minetest then
	for _, file in pairs{
		"minetest",
		"log",
		"player",
		-- deprecated
		"conf"
	} do
		modules[file] = file
	end
end
-- aliases
modules.string = "text"
modules.number = "math"

local parent_dir
if not minetest then
	local init_path = arg and arg[0]
	parent_dir = init_path and init_path:match"^.[/\\]" or ""
end

-- only used if Minetest is available
local function get_resource(modname, resource, ...)
	if not resource then
		resource = modname
		modname = minetest.get_current_modname()
	end
	return table.concat({minetest.get_modpath(modname), resource, ...}, modlib.dir_delim)
end

local rawget, rawset = rawget, rawset
modlib = setmetatable({
	-- TODO bump on release
	version = 70,
	modname = minetest and minetest.get_current_modname(),
	-- TODO
	dir_delim = rawget(_G, "DIR_DELIM") or "/",
	_RG = setmetatable({}, {
		__index = function(_, index)
			return rawget(_G, index)
		end,
		__newindex = function(_, index, value)
			return rawset(_G, index, value)
		end
	}),
	assertdump = minetest and function(v, value)
		if not v then
			error(dump(value), 2)
		end
	end
}, {
	__index = function(self, module_name_or_alias)
		local module_name = modules[module_name_or_alias]
		if not module_name then
			-- module not available, return nil
			return
		end
		local environment
		if module_name ~= module_name_or_alias then
			-- alias handling
			environment = self[module_name]
		else
			environment = dofile(minetest
				and get_resource(self.modname, module_name .. ".lua")
				or (parent_dir .. module_name .. ".lua"))
		end
		self[module_name_or_alias] = environment
		return environment
	end
})

modlib.mod = minetest and dofile(get_resource(modlib.modname, "mod.lua"))

if minetest then
	modlib.conf.build_setting_tree()
	modlib.mod.get_resource = get_resource
end

_ml = modlib

--[[
--modlib.mod.include"test.lua"
]]

-- TODO verify localizations suffice
return modlib