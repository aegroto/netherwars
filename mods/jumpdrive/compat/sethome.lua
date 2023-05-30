
jumpdrive.register_after_jump(function(from_area, to_area)
	local delta_vector = vector.subtract(to_area.pos1, from_area.pos1)
	local pos1 = from_area.pos1
	local pos2 = from_area.pos2

  -- move /home positions of online players
  for _,player in ipairs(minetest.get_connected_players()) do
    local name = player:get_player_name()

    local home_pos = sethome.get(name)
    if home_pos then
      local xMatch = home_pos.x >= pos1.x and home_pos.x <= pos2.x
      local yMatch = home_pos.y >= pos1.y and home_pos.y <= pos2.y
      local zMatch = home_pos.z >= pos1.z and home_pos.z <= pos2.z

      if xMatch and yMatch and zMatch then
        local new_pos = vector.add(home_pos, delta_vector)
        sethome.set(name, new_pos)
      end
    end
  end
end)
