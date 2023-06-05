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

function add_drop()
	local entity_def = minetest.registered_entities["livingnether:razorback"]
	local new_drop = { name = "netherwars_core:nether_matter", chance = 1, min = 1, max = 1}
	table.insert(entity_def.drops, new_drop)
end

add_drop()
