armor:register_armor("netherwars_armor:helmet_netherwarrior", {
	description = "Nether Warrior Helmet",
	inventory_image = "test.png",
	groups = {armor_head=1, armor_heal=0, armor_use=2000, flammable=1},
	armor_groups = {fleshy=10},
	progressive_armor_level = 50,
	damage_groups = {cracky=3, snappy=2, choppy=3, crumbly=2, level=1},
})

minetest.register_craft({
	output = "netherwars_armor:helmet_netherwarrior",
	recipe = {
		{"netherwars_armor:helmet_netherwarrior"}
	}
})

minetest.register_on_craft(
	function(itemstack, player, old_craft_grid, craft_inv)
		local def = itemstack:get_definition()
		if def.progressive_armor_level == nil then
			return
		end

		local meta = itemstack:get_meta()
		meta:set_int("progressive_armor_level", def.progressive_armor_level)
		meta:set_string("description", string.format(
			"%s\nLevel: %d", 
			def.description,
			meta:get_int("progressive_armor_level")
		))
	end
)