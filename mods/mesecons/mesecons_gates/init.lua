local selection_box = {
	type = "fixed",
	fixed = { -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 }
}

local nodebox = {
	type = "fixed",
	fixed = {
		{ -8/16, -8/16, -8/16, 8/16, -7/16, 8/16 }, -- bottom slab
		{ -6/16, -7/16, -6/16, 6/16, -6/16, 6/16 }
	},
}

local function gate_rotate_rules(node, rules)
	for rotations = 0, node.param2 - 1 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

local function gate_get_output_rules(node)
	return gate_rotate_rules(node, {{x=1, y=0, z=0}})
end

local function gate_get_input_rules_oneinput(node)
	return gate_rotate_rules(node, {{x=-1, y=0, z=0}})
end

local function gate_get_input_rules_twoinputs(node)
	return gate_rotate_rules(node, {{x=0, y=0, z=1, name="input1"},
		{x=0, y=0, z=-1, name="input2"}})
end

local function set_gate(pos, node, state)
	local gate = minetest.registered_nodes[node.name]

	if mesecon.do_overheat(pos) then
		minetest.remove_node(pos)
		mesecon.receptor_off(pos, gate_get_output_rules(node))
		minetest.add_item(pos, gate.drop)
	elseif state then
		minetest.swap_node(pos, {name = gate.onstate, param2=node.param2})
		mesecon.receptor_on(pos, gate_get_output_rules(node))
	else
		minetest.swap_node(pos, {name = gate.offstate, param2=node.param2})
		mesecon.receptor_off(pos, gate_get_output_rules(node))
	end
end

local function update_gate(pos, node, link, newstate)
	local gate = minetest.registered_nodes[node.name]

	if gate.inputnumber == 1 then
		set_gate(pos, node, gate.assess(newstate == "on"))
	elseif gate.inputnumber == 2 then
		local meta = minetest.get_meta(pos)
		meta:set_int(link.name, newstate == "on" and 1 or 0)

		local val1 = meta:get_int("input1") == 1
		local val2 = meta:get_int("input2") == 1
		set_gate(pos, node, gate.assess(val1, val2))
	end
end

local function register_gate(name, inputnumber, assess, recipe, description)
	local get_inputrules = inputnumber == 2 and gate_get_input_rules_twoinputs or
		gate_get_input_rules_oneinput
	description = "Logic Gate: "..name

	local basename = "mesecons_gates:"..name
	mesecon.register_node(basename, {
		description = description,
		inventory_image = "jeija_gate_off.png^jeija_gate_"..name..".png",
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		drawtype = "nodebox",
		drop = basename.."_off",
		selection_box = selection_box,
		node_box = nodebox,
		walkable = true,
		sounds = default.node_sound_stone_defaults(),
		assess = assess,
		onstate = basename.."_on",
		offstate = basename.."_off",
		inputnumber = inputnumber,
		after_dig_node = mesecon.do_cooldown,
	},{
		tiles = {
			"jeija_microcontroller_bottom.png^".."jeija_gate_off.png^"..
			"jeija_gate_output_off.png^".."jeija_gate_"..name..".png",
			"jeija_microcontroller_bottom.png^".."jeija_gate_output_off.png^"..
			"[transformFY",
			"jeija_gate_side.png^".."jeija_gate_side_output_off.png",
			"jeija_gate_side.png",
			"jeija_gate_side.png",
			"jeija_gate_side.png"
		},
		groups = {dig_immediate = 2, overheat = 1},
		mesecons = { receptor = {
			state = "off",
			rules = gate_get_output_rules
		}, effector = {
			rules = get_inputrules,
			action_change = update_gate
		}}
	},{
		tiles = {
			"jeija_microcontroller_bottom.png^".."jeija_gate_on.png^"..
			"jeija_gate_output_on.png^".."jeija_gate_"..name..".png",
			"jeija_microcontroller_bottom.png^".."jeija_gate_output_on.png^"..
			"[transformFY",
			"jeija_gate_side.png^".."jeija_gate_side_output_on.png",
			"jeija_gate_side.png",
			"jeija_gate_side.png",
			"jeija_gate_side.png"
		},
		groups = {dig_immediate = 2, not_in_creative_inventory = 1, overheat = 1},
		mesecons = { receptor = {
			state = "on",
			rules = gate_get_output_rules
		}, effector = {
			rules = get_inputrules,
			action_change = update_gate
		}}
	})

	minetest.register_craft({output = basename.."_off", recipe = recipe})
end

register_gate("diode", 1, function (input) return input end,
	{{"mesecons:mesecon", "mesecons_torch:mesecon_torch_on", "mesecons_torch:mesecon_torch_on"}},
	"Diode")

register_gate("not", 1, function (input) return not input end,
	{{"mesecons:mesecon", "mesecons_torch:mesecon_torch_on", "mesecons:mesecon"}},
	"NOT Gate")

register_gate("and", 2, function (val1, val2) return val1 and val2 end,
	{{"mesecons:mesecon", "", ""},
	 {"", "mesecons_materials:silicon", "mesecons:mesecon"},
	 {"mesecons:mesecon", "", ""}},
	"AND Gate")

register_gate("nand", 2, function (val1, val2) return not (val1 and val2) end,
	{{"mesecons:mesecon", "", ""},
	 {"", "mesecons_materials:silicon", "mesecons_torch:mesecon_torch_on"},
	 {"mesecons:mesecon", "", ""}},
	"NAND Gate")

register_gate("xor", 2, function (val1, val2) return (val1 or val2) and not (val1 and val2) end,
	{{"mesecons:mesecon", "", ""},
	 {"", "mesecons_materials:silicon", "mesecons_materials:silicon"},
	 {"mesecons:mesecon", "", ""}},
	"XOR Gate")

register_gate("nor", 2, function (val1, val2) return not (val1 or val2) end,
	{{"mesecons:mesecon", "", ""},
	 {"", "mesecons:mesecon", "mesecons_torch:mesecon_torch_on"},
	 {"mesecons:mesecon", "", ""}},
	"NOR Gate")

register_gate("or", 2, function (val1, val2) return (val1 or val2) end,
	{{"mesecons:mesecon", "", ""},
	 {"", "mesecons:mesecon", "mesecons:mesecon"},
	 {"mesecons:mesecon", "", ""}},
	"OR Gate")

local pulsetime = { 0.1, 0.3, 0.5, 1.0 } --Same as the delayer

local function pulsegate_on(pos,node)
	local basename = "mesecons_gates:pulse_"
	if string.sub(node.name,1,#basename) ~= basename or string.sub(node.name,-2,-1) == "on" then
		--Gate no longer exists or is already on
		return
	end
	local delay = tonumber(string.sub(node.name,#basename+1,#basename+1))
	node.name = basename..delay.."_on"
	minetest.swap_node(pos,node)
	mesecon.receptor_on(pos,gate_get_output_rules(node))
	if delay and pulsetime[delay] then minetest.get_node_timer(pos):start(pulsetime[delay]) end
end

local function pulsegate_off(pos)
	local node = minetest.get_node(pos)
	local basename = "mesecons_gates:pulse_"
	if string.sub(node.name,1,#basename) ~= basename or string.sub(node.name,-3,-1) == "off" then
		--Gate no longer exists or is already off
		return
	end
	local delay = string.sub(node.name,#basename+1,#basename+1)
	node.name = basename..delay.."_off"
	minetest.swap_node(pos,node)
	mesecon.receptor_off(pos,gate_get_output_rules(node))
end

for i=1,4,1 do
	mesecon.register_node("mesecons_gates:pulse_"..i, {
		description = "Logic Gate: Pulse",
		inventory_image = "jeija_gate_off.png^jeija_gate_pulse.png",
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		drawtype = "nodebox",
		drop = "mesecons_gates:pulse_1_off",
		selection_box = selection_box,
		node_box = nodebox,
		walkable = true,
		sounds = default.node_sound_stone_defaults(),
		onstate = "mesecons_gates:pulse_"..i.."_on",
		offstate = "mesecons_gates:pulse_"..i.."_off",
		after_dig_node = mesecon.do_cooldown,
	},{
		tiles = {
			"jeija_microcontroller_bottom.png^".."jeija_gate_off.png^"..
			"jeija_gate_output_off.png^".."jeija_gate_pulse.png^".."mesecons_gates_pulse_setting_"..i..".png",
			"jeija_microcontroller_bottom.png^".."jeija_gate_output_off.png^"..
			"[transformFY",
			"jeija_gate_side.png^".."jeija_gate_side_output_off.png",
			"jeija_gate_side.png",
			"jeija_gate_side.png",
			"jeija_gate_side.png"
		},
		on_punch = function(pos, node, puncher)
			if minetest.is_protected(pos, puncher and puncher:get_player_name() or "") then
				return
			end
			minetest.swap_node(pos, {
				name = "mesecons_gates:pulse_"..tostring(i % 4 + 1).."_off",
				param2 = node.param2
			})
		end,
		groups = i == 1 and {dig_immediate = 2} or {dig_immediate = 2,not_in_creative_inventory = 1},
		mesecons = { receptor = {
			state = "off",
			rules = gate_get_output_rules
		}, effector = {
			rules = gate_get_input_rules_oneinput,
			action_on = pulsegate_on,
		}}
	},{
		tiles = {
			"jeija_microcontroller_bottom.png^".."jeija_gate_on.png^"..
			"jeija_gate_output_on.png^".."jeija_gate_pulse.png^".."mesecons_gates_pulse_setting_"..i..".png",
			"jeija_microcontroller_bottom.png^".."jeija_gate_output_on.png^"..
			"[transformFY",
			"jeija_gate_side.png^".."jeija_gate_side_output_on.png",
			"jeija_gate_side.png",
			"jeija_gate_side.png",
			"jeija_gate_side.png"
		},
		on_timer = pulsegate_off,
		groups = {dig_immediate = 2, not_in_creative_inventory = 1},
		mesecons = { receptor = {
			state = "on",
			rules = gate_get_output_rules
		}}
	})
end

minetest.register_craft({
	output = "mesecons_gates:pulse_1_off",
	recipe = {
		{"group:mesecon_conductor_craftable","",""},
		{"mesecons_materials:silicon","mesecons_materials:silicon","group:mesecon_conductor_craftable"},
		{"group:mesecon_conductor_craftable","",""},
	},
})
