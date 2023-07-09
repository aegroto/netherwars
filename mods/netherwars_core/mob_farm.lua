netherwars.mob_spawn_frequency = 2
netherwars.spawnable_mobs = {
    "livingnether:razorback",
    "livingnether:lavawalker",
    "livingnether:sokaarcher",
    "livingnether:sokameele",
    "livingnether:tardigrade"
}

-- particles
local function mob_spawn_particle_effect(pos)
	minetest.add_particlespawner({
		amount = 10,
		time = 0.3,
		minpos = pos,
		maxpos = pos,
		minvel = {x = -1, y = 2, z = -1},
		maxvel = {x = 1, y = 4, z = 1},
		minacc = {x = -1, y = -1, z = -1},
		maxacc = {x = 1, y = 1, z = 1},
		minexptime = 1,
		maxexptime = 1,
		minsize = 2,
		maxsize = 5,
		texture = "netherwars_mob_spawn_particle.png",
		glow = 5
	})
end

local function try_mob_spawn(itemstack, user, pointed_thing)
    if pointed_thing.type ~= "node" then
        return false
    end

    local pos = pointed_thing.under

    if pos.y > -5000 then
        return false
    end

    local node = minetest.get_node(pos)

    if node.name ~= "nether:rack" then
        return false
    end

    if math.random(netherwars.mob_spawn_frequency) == 1 then
        local mob_name = netherwars.spawnable_mobs[math.random(#netherwars.spawnable_mobs)]
        local spawn_pos = pos
        spawn_pos.y = spawn_pos.y + 1
        mob_spawn_particle_effect(spawn_pos)
		minetest.add_entity(spawn_pos, mob_name)
    end

    return true
end

minetest.register_craftitem("netherwars_core:cursed_fertiliser", {
	description = "Cursed Fertiliser",
	inventory_image = "netherwars_cursed_fertiliser.png",
	on_use = function(itemstack, user, pointed_thing)
        if try_mob_spawn(itemstack, user, pointed_thing) then
		    itemstack:take_item()
        end

		return itemstack
	end
})

technic.register_alloy_recipe({
	input = {"bonemeal:fertiliser 20", "netherwars_core:nether_matter 1"},
	output = "netherwars_core:cursed_fertiliser 20",
	time = 10
})