minetest.register_tool("netherwars_weapons:sword_netherwarrior", {
	description = "Nether Warrior Sword",
	inventory_image = "netherwars_warrior_sword.png",
	tool_capabilities = {
		full_punch_interval = 1.2,
		max_drop_level=1,
		groupcaps={
			snappy={times={[1]=1.5, [2]=0.6, [3]=0.2}, uses=45, maxlevel=3},
		},
		damage_groups = {fleshy=6},
	},
	progressive_updates = { 
		damage = 1.0,
		upgrade_decay = 0.01
	},
	sound = {breaks = "default_tool_breaks"},
	groups = {sword = 1}
})

minetest.register_craft({
	output = "netherwars_weapons:sword_netherwarrior",
	recipe = {
		{"netherwars_core:netherium_ingot"},
		{"netherwars_core:netherium_ingot"},
		{"default:obsidian_shard"}
	}
})


