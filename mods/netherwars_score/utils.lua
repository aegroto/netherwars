minetest.register_tool("netherwars_score:god_sword", {
	description = "God Sword",
	inventory_image = "god_sword.png",
	tool_capabilities = {
		full_punch_interval = 0.7,
		max_drop_level=1,
		groupcaps={
			snappy={times={[1]=1.5, [2]=0.6, [3]=0.2}, uses=45, maxlevel=3},
		},
		damage_groups = {fleshy=1000},
	},
	sound = {breaks = "default_tool_breaks"},
	groups = {sword = 1}
})

