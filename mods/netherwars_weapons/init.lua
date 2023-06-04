minetest.register_tool("netherwars_weapons:sword_netherwarrior", {
	description = "Nether Warrior Sword",
	inventory_image = "netherwars_warrior_sword.png",
	tool_capabilities = {
		full_punch_interval = 0.7,
		max_drop_level=1,
		groupcaps={
			snappy={times={[1]=1.5, [2]=0.6, [3]=0.2}, uses=45, maxlevel=3},
		},
		damage_groups = {fleshy=6},
	},
	progressive_damage_level = 100,
	sound = {breaks = "default_tool_breaks"},
	groups = {sword = 1}
})

minetest.register_craft({
	output = "netherwars_weapons:sword_netherwarrior",
	recipe = {
		{"netherwars_weapons:sword_netherwarrior"}
	}
})

minetest.register_on_craft(
	function(itemstack, player, old_craft_grid, craft_inv)
		local def = itemstack:get_definition()
		if def.progressive_damage_level ~= nil then
			local meta = itemstack:get_meta()
			meta:set_int("progressive_damage_level", def.progressive_damage_level)
			meta:set_string("description", string.format(
				"%s\nDamage level: %d", 
				def.description,
				meta:get_int("progressive_damage_level")
			))
		end
	end
)
