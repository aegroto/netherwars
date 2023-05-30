--------------------------------------------------------
-- Minetest :: Pride Flags Mod (pride_flags)
--
-- See README.txt for licensing and other information.
-- Copyright (c) 2022, Leslie E. Krause and Wuzzy
--------------------------------------------------------

pride_flags = {}

local wind_noise = PerlinNoise( 204, 1, 0, 500 )
-- Check whether the new `get_2d` Perlin function is available,
-- otherwise use `get2d`. Needed to suppress deprecation
-- warning in newer Minetest versions.
local old_get2d = true
if wind_noise.get_2d then
	old_get2d = false
end
local active_flags = { }

local pi = math.pi
local rad_180 = pi
local rad_90 = pi / 2

-- This flag is used as the default or fallback in case of error/missing data
local DEFAULT_FLAG = "rainbow"

-- Flag list for the old number-based storing of flags, used up to
-- 8fd4f9661e123bc84c0499c4809537e8aeb24c3b.
-- DO NOT CHANGE THIS LIST!
local legacy_flag_list = {
	"rainbow", "lesbian", "bisexual", "transgender", "genderqueer", "nonbinary", "pansexual", "asexual",
	"vincian", "polysexual", "omnisexual", "graysexual", "demisexual", "homoromantic", "biromantic",
	"polyromantic", "panromantic", "omniromantic", "aromantic", "grayromantic", "demiromantic",
	"androgyne", "demigender", "maverique", "neutrois", "multigender", "polygender", "pangender", "agender",
	"genderfluid", "intersex", "polyamorous", "queer", "demigirl", "demiboy", "bigender", "trigender",
}
local flag_list = {
	-- broader community
	"rainbow", -- rainbow flag / LGBTQ+ Pride flag / Gay Pride flag
	"progress", -- Progress Pride
	-- orientations (general)
	"lesbian", "vincian",
	-- sexual orientations
	"bisexual", "pansexual", "polysexual", "omnisexual",  -- m-spec
	"asexual", "graysexual", "demisexual", -- a-spec
	-- romantic orientations
	"homoromantic",
	"biromantic", "polyromantic", "panromantic", "omniromantic", -- m-spec
	"aromantic", "grayromantic", "demiromantic", -- a-spec
	-- gender-related
	---- umbrella terms
	"transgender", "genderqueer", "nonbinary",
	---- identities that refer to 0 or multiple genders
	"multigender", "polygender", "pangender",
	"agender", "bigender", "trigender",
	---- identities that refer to a specific gender
	"demigender", "demigirl", "demiboy",
	"androgyne", "maverique", "neutrois",
	---- genderfluid
	"genderfluid",
	-- sex-related
	"intersex",
	-- relationship
	"polyamorous",
	-- queer
	"queer",}

local next_flag, prev_flag
local update_next_prev_flag_lists = function()
	next_flag = {}
	prev_flag = {}
	for f=1, #flag_list do
		local name1 = flag_list[f]
		local name0, name2
		if f < #flag_list then
			name2 = flag_list[f+1]
		else
			name2 = flag_list[1]
		end
		if f == 1 then
			name0 = flag_list[#flag_list]
		else
			name0 = flag_list[f-1]
		end
		next_flag[name1] = name2
		prev_flag[name1] = name0
	end
end
update_next_prev_flag_lists()

local flag_exists = function(flag_name)
	return next_flag[ flag_name] ~= nil
end
local get_next_flag = function(current_flag_name)
	if not current_flag_name or not flag_exists( current_flag_name ) then
		return DEFAULT_FLAG
	else
		return next_flag[current_flag_name]
	end
end
local get_prev_flag = function(current_flag_name)
	if not current_flag_name or not flag_exists( current_flag_name ) then
		return DEFAULT_FLAG
	else
		return prev_flag[current_flag_name]
	end
end

local S
if minetest.get_translator then
	S = minetest.get_translator("pride_flags")
else
	S = function(s) return s end
end

-- Delete entity if there is no flag mast node
local delete_if_orphan = function( self )
	local pos = self.object:get_pos( )
	local node = minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z})
	if node.name ~= "pride_flags:upper_mast" and node.name ~= "ignore" then
		minetest.log("action", "[pride_flags] Orphan flag entity removed at "..minetest.pos_to_string(pos, 1))
		self.object:remove( )
		return true
	end
	return false
end

minetest.register_entity( "pride_flags:wavingflag", {
	initial_properties = {
		physical = false,
		visual = "mesh",
		visual_size = { x = 8.5, y = 8.5 },
		collisionbox = { 0, 0, 0, 0, 0, 0 },
		backface_culling = false,
		pointable = false,
		mesh = "pride_flags_wavingflag.b3d",
		textures = { "prideflag_rainbow.png" },
		use_texture_alpha = false,
	},

	on_activate = function ( self, staticdata, dtime )
		if delete_if_orphan( self) then
			return
		end
		-- Init stuff
		self:reset_animation( true )
		self.object:set_armor_groups( { immortal = 1 } )

		if staticdata ~= "" then
			local data = minetest.deserialize( staticdata )
			if data.flag_name then
				self.flag_name = data.flag_name
			else
				-- Convert legacy flag number to flag name
				local flag_idx = data.flag_idx
				self.flag_name = legacy_flag_list[ flag_idx ]
				if not self.flag_name then
					self.flag_name = DEFAULT_FLAG
				end
			end
			self.node_idx = data.node_idx

			if not self.flag_name or not self.node_idx then
				self.object:remove( )
				return
			end

			self:reset_texture( self.flag_name )

			active_flags[ self.node_idx ] = self.object
		else
			self.flag_name = DEFAULT_FLAG
		end

		-- Delete entity if there is already one for this pos
		local objs = minetest.get_objects_inside_radius( self.object:get_pos(), 0.5 )
		for o=1, #objs do
			local obj = objs[o]
			local lua = obj:get_luaentity( )
			if lua and self ~= lua and lua.name == "pride_flags:wavingflag" then
				if lua.node_idx == self.node_idx then
					self.object:remove( )
					return
				end
			end
		end
	end,

	on_deactivate = function ( self )
		if self.sound_id then
			minetest.sound_stop( self.sound_id )
		end
	end,

	on_step = function ( self, dtime )
		self.anim_timer = self.anim_timer - dtime

		if self.anim_timer <= 0 then
			if delete_if_orphan( self) then
				return
			end
			self:reset_animation( )
		end
	end,

	reset_animation = function ( self, initial )
		local pos = self.object:get_pos( )
		local cur_wind = pride_flags.get_wind( pos )
		minetest.log("verbose", "[pride_flags] Current wind at "..minetest.pos_to_string(pos, 1)..": " .. cur_wind)
		local anim_speed
		local wave_sound

		if cur_wind < 10 then
			anim_speed = 10	-- 2 cycle
			wave_sound = "pride_flags_flagwave1"
		elseif cur_wind < 20 then
			anim_speed = 20  -- 4 cycles
			wave_sound = "pride_flags_flagwave1"
		elseif cur_wind < 40 then
			anim_speed = 40  -- 8 cycles
			wave_sound = "pride_flags_flagwave2"
		else
			anim_speed = 80  -- 16 cycles
			wave_sound = "pride_flags_flagwave3"
		end
		-- slightly anim_speed change to desyncronize flag waving
		anim_speed = anim_speed + math.random(0, 200) * 0.01

		if self.object then
			if initial or (not self.object.set_animation_frame_speed) then
				self.object:set_animation( { x = 1, y = 575 }, anim_speed, 0, true )
			else
				self.object:set_animation_frame_speed(anim_speed)
			end
		end
		if not self.sound_id then
			self.sound_id = minetest.sound_play( wave_sound, { object = self.object, gain = 1.0, loop = true } )
		end

		self.anim_timer = 115 + math.random(-10, 10) -- time to reset animation
	end,

	reset_texture = function ( self, flag_name, nextprev )
		if nextprev == 1 then
			self.flag_name = get_next_flag(self.flag_name)
		elseif nextprev == -1 then
			self.flag_name = get_prev_flag(self.flag_name)
		else
			self.flag_name = flag_name
		end

		local texture = string.format( "prideflag_%s.png", self.flag_name )
		self.object:set_properties( { textures = { texture } } )
		return self.flag_name
	end,

	get_staticdata = function ( self )
		return minetest.serialize( {
			node_idx = self.node_idx,
			flag_name = self.flag_name,
		} )
	end,
} )

local metal_sounds
if minetest.get_modpath("default") ~= nil then
	if default.node_sound_metal_defaults then
		metal_sounds = default.node_sound_metal_defaults()
	end
end

minetest.register_node( "pride_flags:lower_mast", {
        description = S("Flag Pole"),
        drawtype = "mesh",
        paramtype = "light",
        mesh = "pride_flags_mast_lower.obj",
        paramtype2 = "facedir",
        tiles = { "pride_flags_baremetal.png", "pride_flags_baremetal.png" },
        wield_image = "pride_flags_pole_bottom_inv.png",
        inventory_image = "pride_flags_pole_bottom_inv.png",
        groups = { cracky = 2 },
        sounds = metal_sounds,
	is_ground_content = false,

        selection_box = {
                type = "fixed",
                fixed = { { -3/32, -1/2, -3/32, 3/32, 1/2, 3/32 } },
        },
        collision_box = {
                type = "fixed",
                fixed = { { -3/32, -1/2, -3/32, 3/32, 1/2, 3/32 } },
        },

	on_rotate = function(pos, node, user, mode, new_param2)
		if mode == screwdriver.ROTATE_AXIS then
			return false
		end
	end,
} )

local function get_flag_pos( pos, param2 )
	local facedir_to_pos = {
		[0] = { x = 0, y = 0.6, z = -0.1 },
		[1] = { x = -0.1, y = 0.6, z = 0 },
		[2] = { x = 0, y = 0.6, z = 0.1 },
		[3] = { x = 0.1, y = 0.6, z = 0 },
	}
	return vector.add( pos, vector.multiply( facedir_to_pos[ param2 ], 1 ) )
end

local function rotate_flag_by_param2( flag, param2 )
	local facedir_to_yaw = {
		[0] = rad_90,
		[1] = 0,
		[2] = -rad_90,
		[3] = rad_180,
	}
	local baseyaw = facedir_to_yaw[ param2 ]
	if not baseyaw then
		minetest.log("warning", "[pride_flags] Unsupported flag pole node param2: "..tostring(param2))
		return
	end
	flag:set_yaw( baseyaw - rad_180 )
end

local function spawn_flag( pos )
	local node_idx = minetest.hash_node_position( pos )
	local param2 = minetest.get_node( pos ).param2

	local flag_pos = get_flag_pos( pos, param2 )
	local obj = minetest.add_entity( flag_pos, "pride_flags:wavingflag" )
	if not obj or not obj:get_luaentity( ) then
		return
	end

	obj:get_luaentity( ).node_idx = node_idx
	rotate_flag_by_param2( obj, param2 )

	active_flags[ node_idx ] = obj
	return obj
end

local function spawn_flag_and_set_texture( pos )
	local flag = spawn_flag( pos )
	if flag and flag:get_luaentity() then
		local meta = minetest.get_meta( pos )
		local flag_name = meta:get_string("flag_name")
		if flag_name == "" then
			-- Convert legacy flag number to flag name
			local flag_idx = meta:get_int("flag_idx")
			flag_name = legacy_flag_list[flag_idx]
			if not flag_name then
				flag_name = DEFAULT_FLAG
			end
			meta:set_string("flag_idx", "")
			meta:set_string("flag_name", flag_name)
		end
		flag:get_luaentity():reset_texture( flag_name )
	end
	return flag
end

local function cycle_flag( pos, player, cycle_backwards )
	local pname = player:get_player_name( )
	if minetest.is_protected( pos, pname ) and not
			minetest.check_player_privs( pname, "protection_bypass") then
		minetest.record_protection_violation( pos, pname )
		return
	end

	local node_idx = minetest.hash_node_position( pos )

	local aflag = active_flags[ node_idx ]
	local flag
	if aflag then
		flag = aflag:get_luaentity( )
	end
	if flag then
		local flag_name
		if cycle_backwards then
			flag_name = flag:reset_texture( nil, -1 )
		else
			flag_name = flag:reset_texture( nil, 1 )
		end
		local meta = minetest.get_meta( pos )
		meta:set_string("flag_name", flag_name)
	else
		spawn_flag_and_set_texture( pos )
	end
end

minetest.register_node( "pride_flags:upper_mast", {
	description = S("Flag Pole with Flag"),
	drawtype = "mesh",
	paramtype = "light",
	mesh = "pride_flags_mast_upper.obj",
	paramtype2 = "facedir",
	tiles = { "pride_flags_baremetal.png", "pride_flags_baremetal.png" },
	wield_image = "pride_flags_pole_top_inv.png",
	inventory_image = "pride_flags_pole_top_inv.png",
	groups = { cracky = 2 },
	sounds = metal_sounds,
	is_ground_content = false,

        selection_box = {
                type = "fixed",
                fixed = { { -3/32, -1/2, -3/32, 3/32, 27/16, 3/32 } },
        },
        collision_box = {
                type = "fixed",
                fixed = { { -3/32, -1/2, -3/32, 3/32, 1/2, 3/32 } },
        },

	on_rightclick = function ( pos, node, player )
		cycle_flag( pos, player )
	end,

	on_punch = function ( pos, node, player )
		cycle_flag( pos, player, -1 )
	end,

	node_placement_prediction = "",

	on_place = function( itemstack, placer, pointed_thing )
		if not pointed_thing.type == "node" then
			return itemstack
		end

		local node = minetest.get_node(pointed_thing.under)
		local pdef = minetest.registered_nodes[node.name]
		if pdef and pdef.on_rightclick and
				not placer:get_player_control().sneak then
			return pdef.on_rightclick(pointed_thing.under,
					node, placer, itemstack, pointed_thing)
		end

		local pos
		if pdef and pdef.buildable_to then
			pos = pointed_thing.under
		else
			pos = pointed_thing.above
			node = minetest.get_node(pos)
			pdef = minetest.registered_nodes[node.name]
			if not pdef or not pdef.buildable_to then
				return itemstack
			end
		end

		local above1 = {x = pos.x, y = pos.y + 1, z = pos.z}
		local above2 = {x = pos.x, y = pos.y + 2, z = pos.z}
		local anode1 = minetest.get_node_or_nil(above1)
		local anode2 = minetest.get_node_or_nil(above2)
		local adef1 = anode1 and minetest.registered_nodes[anode1.name]
		local adef2 = anode2 and minetest.registered_nodes[anode2.name]

		-- Don't build if upper nodes are blocked, unless it's a hidden node
		if not adef1 or (not adef1.buildable_to and anode1.name ~= "pride_flags:upper_mast_hidden_1") then
			return itemstack
		end
		if not adef2 or (not adef2.buildable_to and anode2.name ~= "pride_flags:upper_mast_hidden_2") then
			return itemstack
		end

		local pn = placer:get_player_name()
		if minetest.is_protected(pos, pn) then
			minetest.record_protection_violation(pos, pn)
			return itemstack
		elseif minetest.is_protected(above1, pn) then
			minetest.record_protection_violation(above1, pn)
			return itemstack
		elseif minetest.is_protected(above2, pn) then
			minetest.record_protection_violation(above2, pn)
			return itemstack
		end

		local yaw = placer:get_look_horizontal( )
		local dir = minetest.yaw_to_dir( yaw )
		local param2 = (minetest.dir_to_facedir( dir ) + 3) % 4
		minetest.set_node(pos, {name = "pride_flags:upper_mast", param2 = param2 })
		minetest.set_node(above1, {name = "pride_flags:upper_mast_hidden_1"})
		minetest.set_node(above2, {name = "pride_flags:upper_mast_hidden_2"})

		if not (minetest.is_creative_enabled(pn)) then
			itemstack:take_item()
		end

		local def = minetest.registered_nodes["pride_flags:upper_mast"]
		if def and def.sounds then
			minetest.sound_play(def.sounds.place, {pos = pos}, true)
		end

		return itemstack
	end,

	on_construct = function ( pos )
		local flag = spawn_flag ( pos )
		if flag and flag:get_luaentity() then
			local meta = minetest.get_meta( pos )
			meta:set_string("flag_name", flag:get_luaentity().flag_name)
		end
	end,

	on_destruct = function ( pos )
		local node_idx = minetest.hash_node_position( pos )
		if active_flags[ node_idx ] then
			active_flags[ node_idx ]:remove( )
		end
	end,

	after_destruct = function( pos )
		local above1 = {x=pos.x, y=pos.y+1, z=pos.z}
		local above2 = {x=pos.x, y=pos.y+2, z=pos.z}
		if minetest.get_node( above1 ).name == "pride_flags:upper_mast_hidden_1" then
			minetest.remove_node( above1 )
		end
		if minetest.get_node( above2 ).name == "pride_flags:upper_mast_hidden_2" then
			minetest.remove_node( above2 )
		end
	end,

	on_rotate = function(pos, node, user, mode, new_param2)
		if mode == screwdriver.ROTATE_AXIS then
			return false
		end
		local node_idx = minetest.hash_node_position( pos )
		local aflag = active_flags[ node_idx ]
		if aflag then
			local lua = aflag:get_luaentity( )
			if not lua then
				aflag = spawn_flag_and_set_texture( pos )
				if aflag then
					lua = aflag:get_luaentity()
					if not lua then
						 return
					 end
				 end
			end
			local flag_pos_idx = lua.node_idx
			local flag_pos = minetest.get_position_from_hash( flag_pos_idx )
			flag_pos = get_flag_pos( flag_pos, new_param2 )
			rotate_flag_by_param2( aflag, new_param2 )
			aflag:set_pos( flag_pos )
		end
	end,
} )

minetest.register_lbm({
	name = "pride_flags:respawn_flags",
	label = "Respawn flags",
	nodenames = {"pride_flags:upper_mast"},
	run_at_every_load = true,
	action = function(pos, node)
		local node_idx = minetest.hash_node_position( pos )
		local aflag = active_flags[ node_idx ]
		if aflag then
			return
		end
		spawn_flag_and_set_texture( pos )
	end
})

minetest.register_lbm({
	name = "pride_flags:update_node_meta",
	label = "Update mast node meta",
	nodenames = {"pride_flags:upper_mast"},
	run_at_every_load = false,
	action = function(pos, node)
		local meta = minetest.get_meta( pos )
		local flag_idx = meta:get_int("flag_idx")
		if flag_idx ~= 0 then
			local flag_name = legacy_flag_list[ flag_idx ]
			if not flag_name then
				flag_name = DEFAULT_FLAG
			end
			meta:set_string("flag_idx", "")
			meta:set_string("flag_name", flag_name)
		end
	end
})

if minetest.get_modpath("default") then
	minetest.register_craft({
		output = "pride_flags:lower_mast 6",
		recipe = {
			{"default:steel_ingot"},
			{"default:steel_ingot"},
			{"default:steel_ingot"},
		},
	})
end
minetest.register_craft({
	output = "pride_flags:upper_mast",
	recipe = {
		{"pride_flags:lower_mast", "group:wool", "group:wool"},
		{"pride_flags:lower_mast", "group:wool", "group:wool"},
	},
})

-- Add 2 hidden upper mast segments to block all the nodes
-- the upper mast occupies. This is also needed to prevent
-- collision issues with overhigh nodes.
-- These nodes will be automatically
-- added/removed when the upper mast is constructed
-- or destructed.
minetest.register_node( "pride_flags:upper_mast_hidden_1", {
	drawtype = "airlike",
	pointable = false,
	paramtype = "light",
	sunlight_propagates = true,
	wield_image = "pride_flags_pole_hidden1_inv.png",
	inventory_image = "pride_flags_pole_hidden1_inv.png",
	groups = { not_in_creative_inventory = 1 },
	sounds = metal_sounds,
        collision_box = {
                type = "fixed",
                fixed = { { -3/32, -1/2, -3/32, 3/32, 1/5, 3/32 } },
        },
	is_ground_content = false,
	on_blast = function() end,
	can_dig = function() return false end,
	drop = "",
	diggable = false,
	floodable = false,
})
minetest.register_node( "pride_flags:upper_mast_hidden_2", {
	drawtype = "airlike",
	pointable = false,
	paramtype = "light",
	sunlight_propagates = true,
	wield_image = "pride_flags_pole_hidden2_inv.png",
	inventory_image = "pride_flags_pole_hidden2_inv.png",
	groups = { not_in_creative_inventory = 1 },
	sounds = metal_sounds,
        collision_box = {
                type = "fixed",
                fixed = { { -3/32, -1/2, -3/32, 3/32, -5/16, 3/32 } },
        },
	is_ground_content = false,

	on_blast = function() end,
	can_dig = function() return false end,
	drop = "",
	diggable = false,
	floodable = false,
})

-- API
pride_flags.add_flag = function( name )
	if flag_exists( name ) then
		return false
	end
	table.insert( flag_list, name )
	update_next_prev_flag_lists()
	return true
end

pride_flags.get_flags = function( )
	return table.copy( flag_list )
end

pride_flags.set_flag_at = function( pos, flag_name )
	local node = minetest.get_node( pos )
	if node.name ~= "pride_flags:upper_mast" then
		return false
	end
	if not flag_exists( flag_name ) then
		return false
	end
	local node_idx = minetest.hash_node_position( pos )
	local aflag = active_flags[ node_idx ]
	local flag
	if aflag then
		flag = aflag:get_luaentity( )
	end
	if flag then
		local set_flag_name = flag:reset_texture( flag_name )
		if set_flag_name == flag_name then
			local meta = minetest.get_meta( pos )
			meta:set_string("flag_name", flag_name)
			return true
		end
	end
	return false
end

pride_flags.get_flag_at = function( pos )
	local node = minetest.get_node( pos )
	if node.name ~= "pride_flags:upper_mast" then
		return nil
	end
	local meta = minetest.get_meta( pos )
	local flag_name = meta:get_string("flag_name")
	if flag_name ~= "" then
		return flag_name
	end
end

-- Returns the wind strength at pos.
-- Can be overwritten by mods.
pride_flags.get_wind = function( pos )
	-- The default wind function ignores pos.
	-- Returns a wind between ca. 0 and 55
	local coords = { x = os.time( ) % 65535, y = 0 }
	local cur_wind
	if old_get2d then
		cur_wind = wind_noise:get2d(coords)
	else
		cur_wind = wind_noise:get_2d(coords)
	end
	cur_wind = cur_wind * 30 + 30
	return cur_wind
end

