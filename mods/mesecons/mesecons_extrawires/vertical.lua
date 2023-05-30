mesecon.vertical_autoconnect = function(pos)
	local node = minetest.get_node(pos)
	if minetest.get_item_group(node.name,"vertical_mesecon") == 0 then return end
	local uppos = vector.add(pos,vector.new(0,1,0))
	local dnpos = vector.add(pos,vector.new(0,-1,0))
	local upnode = minetest.get_node(uppos)
	local dnnode = minetest.get_node(dnpos)
	local shouldbe = "mesecons_extrawires:vertical_bottom"
	if minetest.get_item_group(dnnode.name,"vertical_mesecon") > 0 then
		if minetest.get_item_group(upnode.name,"vertical_mesecon") > 0 then
			shouldbe = "mesecons_extrawires:vertical_middle"
		else
			shouldbe = "mesecons_extrawires:vertical_top"
		end
	end
	if node.name == "mesecons_extrawires:vertical_tap_off" or node.name == "mesecons_extrawires:vertical_tap_on" then shouldbe = "mesecons_extrawires:vertical_tap" end
	local upname_base = string.sub(upnode.name,-3,-1) == "_on" and string.sub(upnode.name,1,-4) or string.sub(upnode.name,1,-5)
	local dnname_base = string.sub(dnnode.name,-3,-1) == "_on" and string.sub(dnnode.name,1,-4) or string.sub(dnnode.name,1,-5)
	if shouldbe ~= string.sub(node.name,1,string.len(shouldbe)) or upname_base == "mesecons_extrawires:vertical_bottom" or dnname_base == "mesecons_extrawires:vertical_top" then
		node.name = shouldbe.."_off"
		minetest.set_node(pos,node)
		mesecon.on_placenode(pos,node)
		mesecon.vertical_autoconnect(uppos)
		mesecon.vertical_autoconnect(dnpos)
	end
end

mesecon.vertical_remove = function(pos)
	local uppos = vector.add(pos,vector.new(0,1,0))
	local dnpos = vector.add(pos,vector.new(0,-1,0))
	mesecon.vertical_autoconnect(uppos)
	mesecon.vertical_autoconnect(dnpos)
end

local tap_rules = {
	{x =  1,y =  0,z =  0},
	{x = -1,y =  0,z =  0},
	{x =  0,y =  0,z =  1},
	{x =  0,y =  0,z = -1},
	{x =  0,y =  1,z =  0},
	{x =  0,y = -1,z =  0},
}

local top_rules = {
	{x =  1,y =  0,z =  0},
	{x = -1,y =  0,z =  0},
	{x =  0,y =  0,z =  1},
	{x =  0,y =  0,z = -1},
	{x =  0,y = -1,z =  0},
}

local middle_rules = {
	{x =  0,y =  1,z =  0},
	{x =  0,y = -1,z =  0},
}

local bottom_rules = {
	{x =  1,y =  0,z =  0},
	{x = -1,y =  0,z =  0},
	{x =  0,y =  0,z =  1},
	{x =  0,y =  0,z = -1},
	{x =  0,y =  1,z =  0},
	{x =  0,y =  2,z =  0},
}

mesecon.register_node("mesecons_extrawires:vertical_tap",
	{
		description = "Vertical Mesecon Intermediate Connection",
		paramtype = "light",
		is_ground_content = false,
		drawtype = "nodebox",
		drop = "mesecons_extrawires:vertical_tap_off",
		node_box = {
			type = "fixed",
			fixed = {
					{-0.5,-0.5,-0.5,0.5,-0.4375,0.5},
					{-0.05,-0.4375,-0.05,0.05,0.5,0.05},
				},
		},
		collision_box = {
			type = "fixed",
			fixed = {
					{-0.5,-0.5,-0.5,0.5,-0.4375,0.5},
				},
		},
		after_place_node = mesecon.vertical_autoconnect,
		after_destruct = mesecon.vertical_remove,
	},
	{
		tiles = {"mesecons_wire_off.png"},
		groups = {dig_immediate = 3,vertical_mesecon = 1,},
		mesecons = {conductor = {
			state = mesecon.state.off,
			onstate = "mesecons_extrawires:vertical_tap_on",
			rules = tap_rules,
		}}
	},{
		tiles = {"mesecons_wire_on.png"},
		groups = {dig_immediate = 3,vertical_mesecon = 1,not_in_creative_inventory = 1,},
		mesecons = {conductor = {
			state = mesecon.state.on,
			offstate = "mesecons_extrawires:vertical_tap_off",
			rules = tap_rules,
		}}
	}
)

mesecon.register_node("mesecons_extrawires:vertical_top",
	{
		description = "Vertical Mesecon (top - you hacker you!)",
		paramtype = "light",
		groups = {dig_immediate = 3,vertical_mesecon = 1,not_in_creative_inventory = 1,},
		is_ground_content = false,
		drawtype = "nodebox",
		drop = "mesecons_extrawires:vertical_bottom_off",
		node_box = {
			type = "fixed",
			fixed = {
					{-0.5,-0.5,-0.5,0.5,-0.4375,0.5},
				},
		},
		after_place_node = mesecon.vertical_autoconnect,
		after_destruct = mesecon.vertical_remove,
	},
	{
		tiles = {"mesecons_wire_off.png"},
		mesecons = {conductor = {
			state = mesecon.state.off,
			onstate = "mesecons_extrawires:vertical_top_on",
			rules = top_rules,
		}}
	},{
		tiles = {"mesecons_wire_on.png"},
		mesecons = {conductor = {
			state = mesecon.state.on,
			offstate = "mesecons_extrawires:vertical_top_off",
			rules = top_rules,
		}}
	}
)

mesecon.register_node("mesecons_extrawires:vertical_middle",
	{
		description = "Vertical Mesecon (middle - you hacker you!)",
		paramtype = "light",
		groups = {dig_immediate = 3,vertical_mesecon = 1,not_in_creative_inventory = 1,},
		is_ground_content = false,
		walkable = false,
		drawtype = "nodebox",
		drop = "mesecons_extrawires:vertical_bottom_off",
		node_box = {
			type = "fixed",
			fixed = {
					{-0.05,-0.5,-0.05,0.05,0.5,0.05},
				},
		},
		after_place_node = mesecon.vertical_autoconnect,
		after_destruct = mesecon.vertical_remove,
	},
	{
		tiles = {"mesecons_wire_off.png"},
		mesecons = {conductor = {
			state = mesecon.state.off,
			onstate = "mesecons_extrawires:vertical_middle_on",
			rules = middle_rules,
		}}
	},{
		tiles = {"mesecons_wire_on.png"},
		mesecons = {conductor = {
			state = mesecon.state.on,
			offstate = "mesecons_extrawires:vertical_middle_off",
			rules = middle_rules,
		}}
	}
)

mesecon.register_node("mesecons_extrawires:vertical_bottom",
	{
		description = "Vertical Mesecon",
		paramtype = "light",
		is_ground_content = false,
		drawtype = "nodebox",
		drop = "mesecons_extrawires:vertical_bottom_off",
		node_box = {
			type = "fixed",
			fixed = {
					{-0.5,-0.5,-0.5,0.5,-0.4375,0.5},
					{-0.05,-0.4375,-0.05,0.05,0.5,0.05},
				},
		},
		collision_box = {
			type = "fixed",
			fixed = {
					{-0.5,-0.5,-0.5,0.5,-0.4375,0.5},
				},
		},
		after_place_node = mesecon.vertical_autoconnect,
		after_destruct = mesecon.vertical_remove,
	},
	{
		tiles = {"mesecons_wire_off.png"},
		groups = {dig_immediate = 3,vertical_mesecon = 1,},
		mesecons = {conductor = {
			state = mesecon.state.off,
			onstate = "mesecons_extrawires:vertical_bottom_on",
			rules = bottom_rules,
		}}
	},{
		tiles = {"mesecons_wire_on.png"},
		groups = {dig_immediate = 3,vertical_mesecon = 1,not_in_creative_inventory = 1,},
		mesecons = {conductor = {
			state = mesecon.state.on,
			offstate = "mesecons_extrawires:vertical_bottom_off",
			rules = bottom_rules,
		}}
	}
)

minetest.register_alias("mesecons_extrawires:vertical_off","mesecons_extrawires:vertical_middle_off")
minetest.register_alias("mesecons_extrawires:vertical_on","mesecons_extrawires:vertical_middle_on")

minetest.register_craft({
	output = "mesecons_extrawires:vertical_bottom_off 3",
	recipe = {
		{"group:mesecon_conductor_craftable"},
		{"group:mesecon_conductor_craftable"},
		{"group:mesecon_conductor_craftable"},
	}
})

minetest.register_craft({
	output = "mesecons:wire_00000000_off",
	recipe = {{"mesecons_extrawires:vertical_bottom_off"}}
})

minetest.register_craft({
	output = "mesecons_extrawires:vertical_tap_off 5",
	recipe = {
		{"","mesecons_extrawires:vertical_bottom_off",""},
		{"group:mesecon_conductor_craftable","mesecons_extrawires:vertical_bottom_off","group:mesecon_conductor_craftable"},
		{"","mesecons_extrawires:vertical_bottom_off",""},
	}
})
