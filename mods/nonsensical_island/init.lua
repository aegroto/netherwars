local startpos = {x=0,y=0,z=0}
minetest.register_on_generated(function(minp,maxp)
	local x,y,z=startpos.x,startpos.y,startpos.z
	if maxp.x>x and x>minp.x and
	   maxp.y>y and y>minp.y and
	   maxp.z>z and z>minp.z
	then
		minetest.set_node(startpos,{name="default:dirt"})
		local spos=vector.add(startpos,vector.new(0,1,0))
		--minetest.set_node(spos,{name="default:sapling"})
		minetest.after(0,default.grow_new_apple_tree,spos)
	end
end)

local function spawn(player)
	player:set_pos(vector.new(0,15,0))
end

minetest.register_on_newplayer(function(player)
	spawn(player)
end)

minetest.register_on_respawnplayer(function(player)
	spawn(player)
	return true
end)
