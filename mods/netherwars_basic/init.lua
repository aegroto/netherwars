minetest.register_tool("netherwars_basic:axe_leaves", {
	description = "Leaves Axe",
	inventory_image = "netherwars_basic_tool_leavesaxe.png",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=0,
		groupcaps={
			choppy = {times={[2]=3.00, [3]=1.60}, uses=3, maxlevel=1},
		},
	},
	sound = {breaks = "default_tool_breaks"},
	groups = {axe = 1, flammable = 2}
})

minetest.register_chatcommand("sapling", {
	func=function(name)
		player = minetest.get_player_by_name(name)
		player:get_inventory():add_item("main", "default:sapling")
		player:get_inventory():add_item("main", "default:dirt")
	end
})

minetest.register_craft({
	output = "default:stick",
	recipe = {
		{"default:leaves"}
	}
})

minetest.register_craft({
	output = "netherwars_basic:axe_leaves",
	recipe = {
		{"default:leaves", "default:leaves"},
		{"default:leaves", "group:stick"},
		{"", "group:stick"}
	}
})