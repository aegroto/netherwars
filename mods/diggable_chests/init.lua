local function is_inv_empty(inv)
	local lists=inv:get_lists()
	for k,v in pairs(lists) do
		if not inv:is_empty(k) then
			return false
		end
	end
	return true
end

do
	local oldfd=minetest.node_dig
	minetest.node_dig=function(pos,node,digger,...)
		node = minetest.registered_nodes[node.name]
		if not node then
			return
		end
		local can_dig=node.can_dig
		if not can_dig or can_dig(pos,digger) then
			return oldfd(pos,node,digger)
		end
		local drops={}
		local meta=minetest.get_meta(pos)
		local inv=meta:get_inventory()
		if is_inv_empty(inv) then
			return oldfd(pos,node,digger,...)
		end
		local oldlists=inv:get_lists()
		local lists=inv:get_lists()
		for lname,list in pairs(lists) do
			for idx,itname in ipairs(list) do
				if not itname:is_empty() then
					local amit=minetest.registered_nodes[node.name].allow_metadata_inventory_take
					if amit then
						local count=amit(pos,lname,idx,itname,digger) or 0
						count=math.max(0,count)
						count=math.min(itname:get_count(),count)
						itname:set_count(count)
					end
				end
			end
		end
		for lname,list in pairs(lists) do
			for idx,itname in ipairs(list) do
				if not itname:is_empty() then
					local oldit=oldlists[lname][idx]
					local drop=oldit:take_item(itname:get_count())
					inv:set_lists(oldlists)
					minetest.handle_node_drops(pos,{drop:to_string()},digger)
					local amit=minetest.registered_nodes[node.name].on_metadata_inventory_take
					if amit then
						amit(pos,lname,idx,itname,digger)
					end
					oldlists=inv:get_lists()
				end
			end
		end
		local ret={oldfd(pos,node,digger,...)}
		return unpack(ret)
	end
end
