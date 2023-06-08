netherwars = {}

minetest.register_craftitem("netherwars_core:nether_matter", {
	description = "Nether Matter",
	inventory_image = "netherwars_nether_matter.png",
	groups = {craftitem = 1},
})

minetest.register_craftitem("netherwars_core:netherium_ingot", {
	description = "Netherium Ingot",
	inventory_image = "netherwars_netherium_ingot.png",
	groups = {craftitem = 1},
})

technic.register_alloy_recipe({
	input = {"moreores:mithril_ingot", "netherwars_core:nether_matter 9"},
	output = "netherwars_core:netherium_ingot",
	time = 100
})

local function add_drop(entity_name, new_drop)
	local entity_def = minetest.registered_entities[entity_name]
	table.insert(entity_def.drops, new_drop)
end

add_drop("livingnether:razorback", { name = "netherwars_core:nether_matter", chance = 3, min = 1, max = 2 })
add_drop("livingnether:lavawalker", { name = "netherwars_core:nether_matter", chance = 2, min = 1, max = 2 })
add_drop("livingnether:cyst", { name = "netherwars_core:nether_matter", chance = 8, min = 1, max = 2 })
add_drop("livingnether:flyingrod", { name = "netherwars_core:nether_matter", chance = 5, min = 1, max = 2 })
add_drop("livingnether:noodlemaster", { name = "netherwars_core:nether_matter", chance = 5, min = 1, max = 2 })
add_drop("livingnether:sokaarcher", { name = "netherwars_core:nether_matter", chance = 5, min = 1, max = 2 })
add_drop("livingnether:sokameele", { name = "netherwars_core:nether_matter", chance = 5, min = 1, max = 2 })
add_drop("livingnether:tardigrade", { name = "netherwars_core:nether_matter", chance = 7, min = 1, max = 2 })
add_drop("livingnether:whip", { name = "netherwars_core:nether_matter", chance = 8, min = 1, max = 2 })

function update_description(itemstack) 
	local def = itemstack:get_definition()
	local meta = itemstack:get_meta()

	local description = def.description

	if meta:contains("progressive_damage_level") then
		description = description .. "\nDamage level: " .. meta:get_float("progressive_damage_level")
	end

	
	if meta:contains("progressive_armor_level") then
		description = description .. "\nArmor level: " .. meta:get_float("progressive_armor_level")
	end

	if meta:contains("progressive_update_factor") then
		description = description .. "\nUpdate factor: " .. meta:get_float("progressive_update_factor")
	end

	meta:set_string("description", description)
end

minetest.register_on_craft(
	function(itemstack, player, old_craft_grid, craft_inv)
		local def = itemstack:get_definition()
		local progressive_updates = def.progressive_updates
		if progressive_updates == nil then
			return
		end

		local meta = itemstack:get_meta()

		if progressive_updates["damage"] ~= nil then
			meta:set_float("progressive_damage_level", 1.0)
		end

		if progressive_updates["armor"] ~= nil then
			meta:set_float("progressive_armor_level", 0.0)
		end

		meta:set_float("progressive_update_factor", 1.0)
		update_description(itemstack)
	end
)

local path = minetest.get_modpath(minetest.get_current_modname()) .. "/"

dofile(path .. "updates.lua")
dofile(path .. "anvil.lua")
