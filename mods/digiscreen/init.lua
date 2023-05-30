local function removeEntity(pos)
	local entitiesNearby = minetest.get_objects_inside_radius(pos,0.5)
	for _,i in pairs(entitiesNearby) do
		if i:get_luaentity() and i:get_luaentity().name == "digiscreen:image" then
			i:remove()
		end
	end
end

local function generateTexture(pos,serdata)
	--The data *should* always be valid, but it pays to double-check anyway due to how easily this could crash if something did go wrong
	if type(serdata) ~= "string" then
		minetest.log("error","[digiscreen] Serialized display data appears to be missing at "..minetest.pos_to_string(pos,0))
		return
	end
	local data = minetest.deserialize(serdata)
	if type(data) ~= "table" then
		minetest.log("error","[digiscreen] Failed to deserialize display data at "..minetest.pos_to_string(pos,0))
		return
	end
	for y=1,16,1 do
		if type(data[y]) ~= "table" then
			minetest.log("error","[digiscreen] Invalid row "..y.." at "..minetest.pos_to_string(pos,0))
			return
		end
		for x=1,16,1 do
			if type(data[y][x]) ~= "string" or string.len(data[y][x]) ~= 6 then
				minetest.log("error","[digiscreen] Missing/wrong length display data for X="..x.." Y="..y.." at "..minetest.pos_to_string(pos,0))
				return
			end
			for i=1,6,1 do
				if not tonumber(string.sub(data[y][x],i,i),16) then
					minetest.log("error","[digiscreen] Invalid digit in display data for X="..x.." Y="..y.." at "..minetest.pos_to_string(pos,0))
					return
				end
			end
		end
	end
	
	local ret = "[combine:16x16"
	for y=1,16,1 do
		for x=1,16,1 do
			ret = ret..string.format(":%d,%d=(digiscreen_pixel.png\\^[colorize\\:#%s\\:255)",x-1,y-1,data[y][x])
		end
	end
	return ret
end

local function updateDisplay(pos)
	removeEntity(pos)
	local meta = minetest.get_meta(pos)
	local data = meta:get_string("data")
	local entity = minetest.add_entity(pos,"digiscreen:image")
	local fdir = minetest.facedir_to_dir(minetest.get_node(pos).param2)
	local etex = "digiscreen_pixel.png"
	etex = generateTexture(pos,data) or etex
	entity:set_properties({textures={etex}})
	entity:set_yaw((fdir.x ~= 0) and math.pi/2 or 0)
	entity:set_pos(vector.add(pos,vector.multiply(fdir,0.39)))
end

minetest.register_entity("digiscreen:image",{
	initial_properties = {
		visual = "upright_sprite",
		physical = false,
		collisionbox = {0,0,0,0,0,0,},
		textures = {"digiscreen_pixel.png",},
	},
})

minetest.register_node("digiscreen:digiscreen",{
	description = "Digilines Graphical Display",
	tiles = {"digiscreen_pixel.png",},
	groups = {cracky = 3,},
	paramtype = "light",
	paramtype2 = "facedir",
	on_rotate = minetest.global_exists("screwdriver") and screwdriver.rotate_simple,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.5,-0.5,0.4,0.5,0.5,0.5},
	},
	_digistuff_channelcopier_fieldname = "channel",
	light_source = 10,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec","field[channel;Channel;${channel}]")
		local disp = {}
		for y=1,16,1 do
			disp[y] = {}
			for x=1,16,1 do
				disp[y][x] = "000000"
			end
		end
		meta:set_string("data",minetest.serialize(disp))
		updateDisplay(pos)
	end,
	on_destruct = removeEntity,
	on_receive_fields = function(pos,_,fields,sender)
		local name = sender:get_player_name()
		if not fields.channel then return end
		if minetest.is_protected(pos,name) and not minetest.check_player_privs(name,"protection_bypass") then
			minetest.record_protection_violation(pos,name)
			return
		end
		local meta = minetest.get_meta(pos)
		meta:set_string("channel",fields.channel)
	end,
	on_punch = function(screenpos,_,player)
		if player and not player.is_fake_player then
			local eyepos = vector.add(player:get_pos(),vector.add(player:get_eye_offset(),vector.new(0,1.5,0)))
			local lookdir = player:get_look_dir()
			local distance = vector.distance(eyepos,screenpos)
			local endpos = vector.add(eyepos,vector.multiply(lookdir,distance+1))
			local ray = minetest.raycast(eyepos,endpos,true,false)
			local pointed,screen,hitpos
			repeat
				pointed = ray:next()
				if pointed and pointed.type == "node" then
					local node = minetest.get_node(pointed.under)
					if node.name == "digiscreen:digiscreen" then
						screen = pointed.under
						hitpos = vector.subtract(pointed.intersection_point,screen)
					end
				end
			until screen or not pointed
			if not hitpos then return end
			local facedir = minetest.facedir_to_dir(minetest.get_node(screen).param2)
			if facedir.x > 0 then
				hitpos.x = -1*hitpos.z
			elseif facedir.x < 0 then
				hitpos.x = hitpos.z
			elseif facedir.z < 0 then
				hitpos.x = -1*hitpos.x
			end
			hitpos.y = -1*hitpos.y
			local hitpixel = {}
			hitpixel.x = math.floor((hitpos.x+0.5)*16+0.5)+1
			hitpixel.y = math.floor((hitpos.y+0.5)*16+0.5)+1
			if hitpixel.x < 1 or hitpixel.x > 16 or hitpixel.y < 1 or hitpixel.y > 16 then return end
			local message = {
				x = hitpixel.x,
				y = hitpixel.y,
				player = player:get_player_name(),
			}
			digilines.receptor_send(screenpos,digilines.rules.default,minetest.get_meta(screenpos):get_string("channel"),message)
		end
	end,
	digiline = {
		wire = {
			rules = digiline.rules.default,
		},
		effector = {
			action = function(pos,_,channel,msg)
				local meta = minetest.get_meta(pos)
				local setchan = meta:get_string("channel")
				if type(msg) ~= "table" or setchan ~= channel then return end
				local data = {}
				for y=1,16,1 do
					data[y] = {}
					if type(msg[y]) ~= "table" then msg[y] = {} end
					for x=1,16,1 do
						if type(msg[y][x]) == "string" and string.len(msg[y][x]) == 7 and string.sub(msg[y][x],1,1) == "#" then
							msg[y][x] = string.sub(msg[y][x],2,-1)
						end
						if type(msg[y][x]) ~= "string" or string.len(msg[y][x]) ~= 6 then msg[y][x] = "000000" end
						msg[y][x] = string.upper(msg[y][x])
						for i=1,6,1 do
							if not tonumber(string.sub(msg[y][x],i,i),16) then
								msg[y][x] = "000000"
							end
						end
						data[y][x] = msg[y][x]
					end
				end
				meta:set_string("data",minetest.serialize(data))
				updateDisplay(pos)
			end,
		},
	},
})

minetest.register_lbm({
	name = "digiscreen:respawn",
	label = "Respawn digiscreen entities",
	nodenames = {"digiscreen:digiscreen"},
	run_at_every_load = true,
	action = updateDisplay,
})

minetest.register_craft({
	output = "digiscreen:digiscreen",
	recipe = {
		{"mesecons_luacontroller:luacontroller0000","rgblightstone:rgblightstone_truecolor_0","rgblightstone:rgblightstone_truecolor_0",},
		{"rgblightstone:rgblightstone_truecolor_0","rgblightstone:rgblightstone_truecolor_0","rgblightstone:rgblightstone_truecolor_0",},
		{"rgblightstone:rgblightstone_truecolor_0","rgblightstone:rgblightstone_truecolor_0","rgblightstone:rgblightstone_truecolor_0",},
	},
})
