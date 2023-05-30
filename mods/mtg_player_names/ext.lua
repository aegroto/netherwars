local nodecore=...
-- LUALOCALS < ---------------------------------------------------------
local ItemStack, PcgRandom, ipairs, math, minetest, nodecore, pairs,
      string, tonumber, tostring, type, unpack, vector
    = ItemStack, PcgRandom, ipairs, math, minetest, nodecore, pairs,
      string, tonumber, tostring, type, unpack, vector
local math_abs, math_cos, math_floor, math_log, math_pi, math_pow,
      math_random, math_sin, math_sqrt, string_format, string_gsub,
      string_lower
    = math.abs, math.cos, math.floor, math.log, math.pi, math.pow,
      math.random, math.sin, math.sqrt, string.format, string.gsub,
      string.lower
-- LUALOCALS > ---------------------------------------------------------

function nodecore.player_visible(player)
	if type(player) == "string" then player = minetest.get_player_by_name(player) end
	if not player then return end
	local props = player:get_properties()
	local vs = props and props.visual_size
	return vs and vs.x > 0 and vs.y > 0
end

nodecore.light_sun = 15
nodecore.light_sky = math_floor(0.5 + nodecore.light_sun)
--[[
function nodecore.get_node_light(pos)
	local artificial = minetest.get_node_light(pos, 0)
	if not artificial then return end
	local natural = math_floor(0.5 + minetest.get_node_light(pos, 0.5))
	return artificial > natural and artificial or natural
end
]]
nodecore.get_node_light=minetest.get_node_light

--- hud_set ---

local huds = {}

local myprops = {
	label = true,
	ttl = true,
	quick = true
}

local function copytbl(t)
	local u = {}
	for k, v in pairs(t) do u[k] = type(v) == "table" and copytbl(v) or v end
	return u
end

local function differ(a, b)
	if type(a) == "table" and type(b) == "table" then
		for k, v in pairs(a) do
			if differ(b[k], v) then return true end
		end
		for k, v in pairs(b) do
			if differ(a[k], v) then return true end
		end
		return
	end
	return a ~= b
end

local function updatehud(player, entry, phuds, dtime)
	if entry.ttl then
		if entry.ttl <= 0 then
			if entry.id then player:hud_remove(entry.id) end
			phuds[entry.label] = nil
			return
		end
		entry.ttl = entry.ttl - dtime
	end
	if entry.id then
		for k, v in pairs(entry.new) do
			if (not myprops[k]) and differ(v, entry.old[k]) then
				player:hud_change(entry.id, k, v)
				entry.old[k] = v
			end
		end
	else
		entry.id = player:hud_add(entry.new)
		entry.old = copytbl(entry.new)
	end
end

local function hud_params(player, def)
	if not (def and def.label) then return error("missing HUD label") end

	local pname
	if type(player) == "string" then
		pname = player
		player = minetest.get_player_by_name(pname)
	else
		pname = player:get_player_name()
	end
	if not player then return error("missing player") end

	return player, pname, def
end
local function hud_set(player, def)
	local pname
	player, pname, def = hud_params(player, def)

	local phuds = huds[pname]
	if not phuds then
		phuds = {}
		huds[pname] = phuds
	end
	local entry = phuds[def.label]
	if not entry then
		entry = {}
		phuds[def.label] = entry
	end
	entry.new = {}
	for k, v in pairs(def) do (myprops[k] and entry or entry.new)[k] = v end
	if def.quick then return updatehud(player, entry, phuds, 0) end
end
nodecore.hud_set = hud_set

function nodecore.hud_set_multiline(player, def, trans)
	local pname
	player, pname, def = hud_params(player, def)

	local lines = {}
	def.text = def.text or ""
	for str in string_gmatch(def.text, "[^\r\n]+") do
		lines[#lines + 1] = trans and trans(str) or str
	end
	for i = 1, #lines do
		lines[i] = string_rep(" \n", i - 1) .. lines[i]
		.. string_rep("\n ", #lines - i)
	end

	for i = 1, #lines do
		local t = copytbl(def)
		t.text = lines[i]
		t.label = def.label .. ":" .. i
		hud_set(player, t)
	end

	local phuds = huds[pname]
	if not phuds then
		phuds = {}
		huds[pname] = phuds
	end
	local i = #lines + 1
	while phuds[def.label .. ":" .. i] do
		hud_set(player, {
				label = def.label .. ":" .. i,
				ttl = 0,
				quick = def.quick
			})
		i = i + 1
	end
end

minetest.after(0, function()
		minetest.register_globalstep(function(dtime)
				for _, player in pairs(minetest.get_connected_players()) do
					local pname = player:get_player_name()
					local phuds = huds[pname]
					if phuds then
						for _, entry in pairs(phuds) do
							updatehud(player, entry, phuds, dtime)
						end
					end
				end
			end)
	end)

minetest.register_on_leaveplayer(function(player)
		huds[player:get_player_name()] = nil
	end)

------
