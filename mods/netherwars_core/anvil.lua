local tmp = {}

minetest.register_entity("netherwars_core:anvil_item", {
	hp_max = 1,
	visual = "wielditem",
	visual_size = {x = .33, y = .33},
	collisionbox = {0, 0, 0, 0, 0, 0},
	physical = false,
	textures = {"air"},
	on_activate = function(self, staticdata)
		if tmp.nodename ~= nil and tmp.texture ~= nil then
			self.nodename = tmp.nodename
			tmp.nodename = nil
			self.texture = tmp.texture
			tmp.texture = nil
		else
			if staticdata ~= nil and staticdata ~= "" then
				local data = staticdata:split(";")
				if data and data[1] and data[2] then
					self.nodename = data[1]
					self.texture = data[2]
				end
			end
		end
		if self.texture ~= nil then
			self.object:set_properties({textures = {self.texture}})
		end
	end,
	get_staticdata = function(self)
		if self.nodename ~= nil and self.texture ~= nil then
			return self.nodename .. ";" .. self.texture
		end
		return ""
	end,
})

local update_item = function(pos, node)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if not inv:is_empty("input") then
		pos.y = pos.y + anvil.setting.item_displacement
		tmp.nodename = node.name
		tmp.texture = inv:get_stack("input", 1):get_name()
		local e = minetest.add_entity(pos, "netherwars_core:anvil_item")
		local yaw = math.pi * 2 - node.param2 * math.pi / 2
		e:set_rotation({x = -1.5708, y = yaw, z = 0}) 
	end
end

local remove_item = function(pos, node)
	local objs = minetest.get_objects_inside_radius({x = pos.x, y = pos.y + anvil.setting.item_displacement, z = pos.z}, .5)
	if objs then
		for _, obj in ipairs(objs) do
			if obj and obj:get_luaentity() and obj:get_luaentity().name == "netherwars_core:anvil_item" then
				obj:remove()
			end
		end
	end
end

local function try_update(
	item,
	puncher,
	progressive_var, 
	var_name
)
	local meta = item:get_meta()
	local wielded = puncher:get_wielded_item()
	local player_name = puncher:get_player_name()
	local leveling_def = netherwars.leveling_items[wielded:get_name()]
	local stats = item:get_definition().progressive_updates

	if meta:contains(progressive_var) then
		if leveling_def[var_name] ~= nil  then
			local current_level = meta:get_float(progressive_var)
			local update_factor = meta:get_float("progressive_update_factor")

			local level_upgrade = leveling_def[var_name] * update_factor

			local wielded_meta = wielded:get_meta()
			if wielded_meta:contains(progressive_var) then
				local wd = wielded_meta:get_float(progressive_var)
				local wuf = wielded_meta:get_float("progressive_update_factor")

				local mt = leveling_def.min_transfer

				local transferred_level = wd * (mt + (1.0 - mt) * wuf)
				level_upgrade = level_upgrade + transferred_level
			end

			local upgraded_level = current_level + level_upgrade

			meta:set_float(progressive_var, upgraded_level)

			local new_update_factor = update_factor * (1.0 - stats.upgrade_decay)
			meta:set_float("progressive_update_factor", new_update_factor)

			update_description(item)

			wielded:set_count(wielded:get_count() - 1)
			puncher:set_wielded_item(wielded)

			minetest.chat_send_player(player_name, 
				string.format("Upgrade was successful! New level: %.2f (+%.2f)",
					upgraded_level, level_upgrade
				)
			)
		end
	end
end



minetest.register_node("netherwars_core:nether_anvil", {
	drawtype = "nodebox",
	description = "Nether Anvil",
	tiles = {"netherwars_nether_anvil.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {cracky = 2},
	sounds = metal_sounds,
	-- the nodebox model comes from realtest
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.3, 0.5, -0.4, 0.3},
			{-0.35, -0.4, -0.25, 0.35, -0.3, 0.25},
			{-0.3, -0.3, -0.15, 0.3, -0.1, 0.15},
			{-0.35, -0.1, -0.2, 0.35, 0.1, 0.2},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.3, 0.5, -0.4, 0.3},
			{-0.35, -0.4, -0.25, 0.35, -0.3, 0.25},
			{-0.3, -0.3, -0.15, 0.3, -0.1, 0.15},
			{-0.35, -0.1, -0.2, 0.35, 0.1, 0.2},
		}
	},

	on_punch = function(pos, node, puncher)
		if not pos or not node or not puncher then
			return
		end

		local inventory = minetest.get_meta(pos):get_inventory()
		local item = inventory:get_stack("input", 1)

		if item == nil then
			return
		end

		local meta = item:get_meta()
		local wielded = puncher:get_wielded_item()
		local player_name = puncher:get_player_name()
		local leveling_def = netherwars.leveling_items[wielded:get_name()]

		if leveling_def ~= nil then
			try_update(item, puncher, "progressive_damage_level", "damage")
			try_update(item, puncher, "progressive_armor_level", "armor")
			inventory:set_stack("input", 1, item)
		end
	end,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("input", 1)
	end,

	after_place_node = function(pos, placer, itemstack)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Nether anvil")
	end,

	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		if not inv:is_empty("input") then
			return false
		end
		return true
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if listname ~= "input" then
			return 0
		end

		local node_meta = minetest.get_meta(pos)
		local stack_meta = stack:get_meta()

		if not stack_meta:contains("progressive_update_factor") then
			local player_name = player:get_player_name()
			minetest.chat_send_player(player_name, "This anvil is for upgradable equipment only.")
			return 0
		end

		if node_meta:get_inventory():room_for_item("input", stack) then
			return stack:get_count()
		end
		return 0
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if listname ~= "input" then
			return 0
		end
		return stack:get_count()
	end,

	on_rightclick = function(pos, node, clicker, itemstack)
		if not clicker or not itemstack then
			return
		end

		local meta = minetest.get_meta(pos)
		local name = clicker:get_player_name()

		if itemstack:get_count() == 0 then
			local inv = meta:get_inventory()
			if not inv:is_empty("input") then
				local return_stack = inv:get_stack("input", 1)
				inv:set_stack("input", 1, nil)
				local wield_index = clicker:get_wield_index()
				clicker:get_inventory():set_stack("main", wield_index, return_stack)
				meta:set_string("infotext", "Nether anvil")
				remove_item(pos, node)
				return return_stack
			end
		end

		local this_def = minetest.registered_nodes[node.name]
		if this_def.allow_metadata_inventory_put(pos, "input", 1, itemstack:peek_item(), clicker) > 0 then
			local s = itemstack:take_item()
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			inv:add_item("input", s)
			local meta_description = s:get_meta():get_string("description")
			if "" ~= meta_description then
				meta:set_string("infotext", "Nether anvil")
			end
			meta:set_int("informed", 0)
			update_item(pos, node)
		end

		return itemstack
	end,


	is_ground_content = false,
})

local m = "netherwars_core:netherium_ingot"
minetest.register_craft({
	output = "netherwars_core:nether_anvil",
	recipe = {
		{m, m, m},
		{"", m, ""},
		{m, m, m}
	},
})
