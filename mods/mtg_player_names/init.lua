-- LUALOCALS < ---------------------------------------------------------
local math, minetest, pairs, tonumber
    = math, minetest, pairs, tonumber
local math_sqrt
    = math.sqrt
-- LUALOCALS > ---------------------------------------------------------

local nodecore={}

local modname = minetest.get_current_modname()

local ext=loadfile(minetest.get_modpath(modname).."/ext.lua")
ext(nodecore)

-- Maximum distance at which custom nametags are visible.
local distance = tonumber(minetest.settings:get(modname .. "_distance")) or 16

------------------------------------------------------------------------
-- PLAYER JOIN/LEAVE

-- On player joining, disable the built-in nametag by setting its
-- text to whitespace and color to transparent.
minetest.register_on_joinplayer(function(player)--"join hide nametag", 
		player:set_nametag_attributes({
				text = " ",
				color = {a = 0, r = 0, g = 0, b = 0}
			})
	end)

------------------------------------------------------------------------
-- GLOBAL TICK HUD MANAGEMENT

local function fluidmedium(pos)
	local node = minetest.get_node(pos)
	local def = minetest.registered_items[node.name]
	if not def then return node.name end
	if def.sunlight_propagates then return "CLEAR" end
	return def.liquid_alternative_source or node.name
end

-- Determine if player 1 can see player 2's face, including
-- checks for distance, line-of-sight, and facing direction.
local function canseeface(p1, p2)
	if p1:get_hp() <= 0 or p2:get_hp() <= 0 then return end
	if p1:get_attach() or p2:get_attach() then return end
	if not nodecore.player_visible(p2) then return end

	-- Players must be within max distance of one another,
	-- determined by light level, but not too close.
	local o1 = p1:get_pos()
	local o2 = p2:get_pos()
	local e1 = p1:get_properties().eye_height or 1.625
	local e2 = p2:get_properties().eye_height or 1.625
	local dx = o1.x - o2.x
	local dy = o1.y - o2.y
	local dz = o1.z - o2.z
	local dsqr = (dx * dx + dy * dy + dz * dz)
	if dsqr < 1 then return end
	local ll = nodecore.get_node_light({x = o2.x, y = o2.y + e2, z = o2.z})
	if not ll then return end
	local ld = (ll / nodecore.light_sun * distance)
	if dsqr > (ld * ld) then return end

	-- Make sure players' eyes are inside the same fluid.
	o1.y = o1.y + e1
	o2.y = o2.y + e2
	local f1 = fluidmedium(o1)
	local f2 = fluidmedium(o2)
	if f1 ~= f2 then return end

	-- Check for line of sight from approximate eye level
	-- of one player to the other.
	for pt in minetest.raycast(o1, o2, true, true) do
		if pt.type == "node" then
			if fluidmedium(pt.under) ~= f1 then return end
		elseif pt.type == "object" then
			if pt.ref ~= p1 and pt.ref ~= p2 then return end
		else
			return
		end
	end

	-- Players must be facing each other; cannot identify another
	-- player's face when their back is turned. Note that
	-- minetest models don't show pitch, so ignore the y component.

	-- Compute normalized 2d vector from one player to another.
	local d = dx * dx + dz * dz
	if d == 0 then return end
	d = math_sqrt(d)
	dx = dx / d
	dz = dz / d

	-- Compute normalized 2d facing direction vector for target player.
	local l2 = p2:get_look_dir()
	d = l2.x * l2.x + l2.z * l2.z
	if d == 0 then return end
	d = math_sqrt(d)
	l2.x = l2.x / d
	l2.z = l2.z / d

	-- Compare directions via dot product.
	if (dx * l2.x + dz * l2.z) <= 0.5 then return end

	return true
end

-- On each global step, check all player visibility, and create/remove/update
-- each player's HUDs accordingly.
minetest.register_globalstep(function() --"player names", 
		local conn = minetest.get_connected_players()
		for _, p1 in pairs(conn) do
			for _, p2 in pairs(conn) do
				if p2 ~= p1 then
					local n2 = p2:get_player_name()
					if canseeface(p1, p2) then
						local p = p2:get_pos()
						p.y = p.y + 1.25
						nodecore.hud_set(p1, {
								label = "pname:" .. n2,
								hud_elem_type = "waypoint",
								world_pos = p,
								name = n2,
								text = "",
								precision = 0,
								number = 0xffffff,
								quick = true
							})
					else
						nodecore.hud_set(p1, {
								label = "pname:" .. n2,
								ttl = 0,
								quick = true
							})
					end
				end
			end
		end
	end)

minetest.register_on_leaveplayer(function(player)--"leave clear names", 
		local pname = player:get_player_name()
		for _, peer in pairs(minetest.get_connected_players()) do
			nodecore.hud_set(peer, {
					label = "pname:" .. pname,
					ttl = 0,
					quick = true
				})
		end
	end)
