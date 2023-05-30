local utils = ...
local S = utils.S



local crafter_interval = 1.0



local function unit_inventory (pos, owner, inv_list)
	local node = utils.get_far_node (pos)

	if node and (node.name == "lwcomponents:storage_unit" or
					 node.name == "lwcomponents:storage_unit_locked") then

		local meta = minetest.get_meta (pos)
		local uowner = meta:get_string ("owner")

		if meta and (owner == uowner or uowner == "") then
			local inv = meta:get_inventory ()

			if inv then
				local slots = inv:get_size ("main")

				for slot = 1, slots, 1 do
					local stack = inv:get_stack ("main", slot)

					if stack and not stack:is_empty () then
						local copy = ItemStack (stack)
						copy:set_count (1)
						local name = copy:get_name ()
						local item = inv_list[name]

						if not item then
							inv_list[name] = { name = name, count = 0 }
							item = inv_list[name]
						end

						item[#item + 1] =
						{
							pos = vector.new (pos),
							count = stack:get_count (),
							slot = slot
						}

						item.count = item.count + stack:get_count ()
					end
				end
			end

			return true
		end
	end

	return false
end



local function inventory_searcher (pos, owner, coords, inv_list, check_list)
	local spos = minetest.pos_to_string (pos, 0)

	if not check_list[spos] then
		check_list[spos] = true

		if unit_inventory (pos, owner, inv_list) then
			for _, c in ipairs (coords) do
				inventory_searcher (vector.add (pos, c), owner, coords, inv_list, check_list)
			end
		end
	end
end



local function get_inventory_list (pos)
	local inv_list = { }
	local meta = minetest.get_meta (pos)

	if meta then
		local owner = meta:get_string ("owner")
		local check_list = { [minetest.pos_to_string (pos, 0)] = true }
		local coords =
		{
			{ x =  1, y =  0, z =  0 },
			{ x = -1, y =  0, z =  0 },
			{ x =  0, y =  1, z =  0 },
			{ x =  0, y = -1, z =  0 },
			{ x =  0, y =  0, z =  1 },
			{ x =  0, y =  0, z = -1 }
		}

		for _, c in ipairs (coords) do
			inventory_searcher (vector.add (pos, c), owner, coords, inv_list, check_list)
		end

		local inv = meta:get_inventory ()

		if inv then
			local slots = inv:get_size ("main")

			for slot = 1, slots, 1 do
				local stack = inv:get_stack ("main", slot)

				if stack and not stack:is_empty () then
					local copy = ItemStack (stack)
					copy:set_count (1)
					local name = copy:get_name ()
					local item = inv_list[name]

					if not item then
						inv_list[name] = { name = name, count = 0 }
						item = inv_list[name]
					end

					item[#item + 1] =
					{
						pos = vector.new (pos),
						count = stack:get_count (),
						slot = slot
					}

					item.count = item.count + stack:get_count ()
				end
			end
		end
	end

	return inv_list
end



local function get_stock_list (pos)
	local inv_list = get_inventory_list (pos)
	local list = { }

	for k, v in pairs (inv_list) do
		local description = ""
		local def = minetest.registered_items[k]

		if def and (def.short_description or def.description) then
			description = def.short_description or def.description
		end

		list[#list + 1] =
		{
			name = k,
			description = utils.unescape_description (description),
			count = v.count,
		}
	end

	return list
end



local function get_source_item (item, inv_list, used)
	if not item or type (item) ~= "string" or item:len () < 1 then
		return ""
	end

	if item:sub (1, 6) ~= "group:" then
		local name = inv_list[item]

		if name and (name.count - (used[name] or 0)) > 0 then
			if used[name] then
				used[name] = used[name] + 1
			else
				used[name] = 1
			end

			return name.name
		end

		return nil
	end

	local group = item:sub (7)

	for k, v in pairs (inv_list) do
		if minetest.get_item_group (k, group) > 0 then
			if (v.count - (used[k] or 0)) > 0 then
				if used[k] then
					used[k] = used[k] + 1
				else
					used[k] = 1
				end

				return k
			end
		end
	end

	return nil
end



local function get_craft_recipe_items (items, inv_list)
	local recipe = { }
	local valid = false
	local used = { }

	for i = 1, 9, 1 do
		if items[i] then
			recipe[i] = get_source_item (items[i], inv_list, used)

			if not recipe[i] then
				return nil
			end

			valid = true
		end
	end

	if not valid then
		return nil
	end

	return recipe
end



local function get_craft_items (itemname, inv_list)
	local recipes = minetest.get_all_craft_recipes (itemname)

	if recipes then
		for i, recipe in ipairs (recipes) do
			if (recipe.type and recipe.type == "normal") or
					(recipe.method and recipe.method == "normal") then
				local items = get_craft_recipe_items (recipe.items, inv_list)

				if items then
					return items, recipe
				end
			end
		end
	end

	return nil
end



local function get_craftable_list (pos)
	local inv_list = get_inventory_list (pos)
	local list = { }

	for itemname, def in pairs (minetest.registered_items) do
		if (get_craft_items (itemname, inv_list)) then
			local description = def.short_description or def.description

			list[#list + 1] =
			{
				name = itemname,
				description = utils.unescape_description (description or "")
			}
		end
	end

	return list
end



local function remove_input_items (item)
	local meta = minetest.get_meta (item.pos)

	if meta then
		local inv = meta:get_inventory ()

		if inv then
			local stack = inv:get_stack ("main", item.slot)

			if stack and not stack:is_empty () and stack:get_count () >= item.count and
						stack:get_name () == item.name then
				if stack:get_count () > item.count then
					stack:set_count (stack:get_count () - item.count)

					inv:set_stack ("main", item.slot, stack)
				else
					inv:set_stack ("main", item.slot, nil)
				end

				return true
			end
		end
	end

	return false
end



local function return_input_items (item)
	local meta = minetest.get_meta (item.pos)

	if meta then
		local inv = meta:get_inventory ()

		if inv then
			local stack = inv:get_stack ("main", item.slot)

			if not stack or stack:is_empty () then
				inv:set_stack ("main", item.slot, ItemStack (string.format ("%s %d", item.name, item.count)))

				return true
			elseif stack:get_name () == item.name then
				local count = stack:get_count () + item.count

				if stack:get_stack_max () < count then
					count = stack:get_stack_max () - stack:get_count ()
				end

				if count > 0 then
					stack:set_count (count)

					inv:set_stack ("main", item.slot, stack)
				end

				return true
			end
		end
	end

	return false
end



-- tests storage for input items and returns list where they would be taken from or nil
local function check_input_items (items, inv_list)
	local agg = { }
	local input = { }

	for i = 1, #items, 1 do
		if items[i] then
			if items[i]:len () > 0 then
				if agg[items[i]] then
					agg[items[i]] = agg[items[i]] + 1
				else
					agg[items[i]] = 1
				end
			end
		end
	end

	for k, c in pairs (agg) do
		local list = inv_list[k]

		if not list then
			return nil
		end

		if list.count < c then
			return nil
		end

		local count = c

		for i = #list, 1, -1 do
			if list[i].count <= count then
				input[#input + 1] =
				{
					name = k,
					pos = list[i].pos,
					slot = list[i].slot,
					count = list[i].count
				}

				list.count = list.count - list[i].count
				count = count - list[i].count

				table.remove (list, i)
			else
				input[#input + 1] =
				{
					name = k,
					pos = list[i].pos,
					slot = list[i].slot,
					count = count
				}

				list[i].count = list[i].count - count
				list.count = list.count - count

				count = 0
			end


			if count < 1 then
				break
			end
		end
	end

	return input
end



-- removes items from storage and returns input_items or nil
local function get_input_items (input_items)
	if input_items then
		for i = 1, #input_items, 1 do
			if not remove_input_items (input_items[i]) then
				-- put back
				for j = i - 1, 1, -1 do
					return_input_items (input_items[j])
				end

				return nil
			end
		end
	end

	return input_items
end



-- return inv table after add or nil
local function can_fit_output (pos, output)
	local meta = minetest.get_meta (pos)

	if meta then
		local inv = meta:get_inventory ()

		if inv then
			local copy = { }
			local list = { }
			local slots = inv:get_size ("output")

			for i = 1, #output, 1 do
				copy[i] = ItemStack (output[i])
			end

			for i = 1, slots, 1 do
				list[i] = inv:get_stack ("output", i)
			end

			for i = 1, #copy, 1 do
				if copy[i]:get_count () > 0 then
					for j = 1, #list, 1 do
						if utils.is_same_item (list[j], copy[i]) then
							if (list[j]:get_count () + copy[i]:get_count ()) > list[j]:get_stack_max () then
								copy[i]:set_count (copy[i]:get_count () - (list[j]:get_stack_max () - list[j]:get_count ()))
								list[j]:set_count (list[j]:get_stack_max ())
							else
								list[j]:set_count (list[j]:get_count () + copy[i]:get_count ())
								copy[i]:set_count (0)
							end
						end

						if copy[i]:get_count () < 1 then
							break
						end
					end
				end
			end

			for i = 1, #copy, 1 do
				if copy[i]:get_count () > 0 then
					for j = 1, #list, 1 do
						if list[j]:is_empty () then
							list[j] = ItemStack (copy[i])
							copy[i]:set_count (0)
						end

						if copy[i]:get_count () < 1 then
							break
						end
					end
				end
			end

			for i = 1, #copy, 1 do
				if copy[i]:get_count () > 0 then
					return nil
				end
			end

			return list
		end
	end

	return nil
end



local function update_output (pos, list)
	local meta = minetest.get_meta (pos)

	if meta then
		local inv = meta:get_inventory ()

		if inv then
			inv:set_list ("output", list)

			return true
		end
	end

	return false
end



-- items is list of recipe grid
local function craft (pos, items, recipe, qty, inv_list)
	local output, leftover = minetest.get_craft_result (recipe)
	local crafted = 0

	if output and output.item and not output.item:is_empty () then
		for q = 1, qty, 1 do
			local src_items = table.copy (items)

			-- output itemstacks
			local output_items = { ItemStack (output.item) }
			for i = 1, #output.replacements, 1 do
				if output.replacements[i] and not output.replacements[i]:is_empty () then
					output_items[#output_items + 1] = ItemStack (output.replacements[i])
				end
			end

			-- adjust leftovers
			for i = 1, #leftover.items, 1 do
				if leftover.items[i] and not leftover.items[i]:is_empty () then
					local count = leftover.items[i]:get_count ()

					for j = #src_items, 1, -1 do
						if src_items[j] == leftover.items[i]:get_name () then
							table.remove (src_items, j)
							count = count - 1

							if count < 1 then
								break
							end
						end
					end

					if count > 0 then
						output_items[#output_items + 1] = ItemStack (leftover.items[i]:get_name ().." "..tostring (count))
					end
				end
			end

			-- implement crafting_mods.lua
			local mods = utils.get_crafting_mods (output.item:get_name ())
			if mods then
				if mods.add then
					for i = 1, #mods.add do
						output_items[#output_items + 1] = ItemStack (mods.add[i])
					end
				end

				if mods.remove then
					for i = 1, #mods.remove do
						local found = false

						for j = #output_items, 1, -1 do
							if output_items[j]:get_name () == mods.remove[i] then
								if output_items[j]:get_count () > 1 then
									output_items[j]:set_count (output_items[j]:get_count () - 1)
								else
									output_items[j] = nil
								end

								found = true
							end
						end

						if not found then
							src_items[#src_items + 1] = mods.remove[i]
						end
					end
				end
			end

			local input_items = check_input_items (src_items, inv_list)

			if not input_items then
				return crafted
			end

			local output_list = can_fit_output (pos, output_items)

			if not output_list then
				return crafted
			end

			if not get_input_items (input_items) then
				return crafted
			end

			if not update_output (pos, output_list) then
				for j = 1, #input_items, 1 do
					return_input_items (input_items[j])
				end

				return crafted
			end

			crafted = crafted + 1
		end
	end

	return crafted
end



-- items is list of recipe grid
local function can_craft (pos, items, recipe, inv_list)
	local output, leftover = minetest.get_craft_result (recipe)

	if output and output.item and not output.item:is_empty () then
		local src_items = table.copy (items)

		-- output itemstacks
		local output_items = { ItemStack (output.item) }
		for i = 1, #output.replacements, 1 do
			if output.replacements[i] and not output.replacements[i]:is_empty () then
				output_items[#output_items + 1] = ItemStack (output.replacements[i])
			end
		end

		-- adjust leftovers
		for i = 1, #leftover.items, 1 do
			if leftover.items[i] and not leftover.items[i]:is_empty () then
				local count = leftover.items[i]:get_count ()

				for j = #src_items, 1, -1 do
					if src_items[j] == leftover.items[i]:get_name () then
						table.remove (src_items, j)
						count = count - 1

						if count < 1 then
							break
						end
					end
				end

				if count > 0 then
					output_items[#output_items + 1] = ItemStack (leftover.items[i]:get_name ().." "..tostring (count))
				end
			end
		end

		-- implement crafting_mods.lua
		local mods = utils.get_crafting_mods (output.item:get_name ())
		if mods then
			if mods.add then
				for i = 1, #mods.add do
					output_items[#output_items + 1] = ItemStack (mods.add[i])
				end
			end

			if mods.remove then
				for i = 1, #mods.remove do
					local found = false

					for j = #output_items, 1, -1 do
						if output_items[j]:get_name () == mods.remove[i] then
							if output_items[j]:get_count () > 1 then
								output_items[j]:set_count (output_items[j]:get_count () - 1)
							else
								output_items[j] = nil
							end

							found = true
						end
					end

					if not found then
						src_items[#src_items + 1] = mods.remove[i]
					end
				end
			end
		end

		if check_input_items (src_items, inv_list) and
				can_fit_output (pos, output_items) then
			return true
		end
	end

	return false
end



local function get_recipe_grid (pos)
	local meta = minetest.get_meta (pos)

	if meta then
		local inv = meta:get_inventory ()

		if inv then
			local grid = { }
			local slots = inv:get_size ("craft")

			for i = 1, slots, 1 do
				local stack = inv:get_stack ("craft", i)

				if stack then
					grid[i] = stack:get_name ()
				else
					grid[i] = ""
				end
			end

			return grid
		end
	end

	return nil
end



local function craft_recipe (pos, qty)
	local inv_list = get_inventory_list (pos)
	local items = get_recipe_grid (pos)
	local recipe =
	{
		method = "normal",
		width = 3,
		items = get_recipe_grid (pos)
	}

	return craft (pos, items, recipe, qty, inv_list)
end



local function craft_item (pos, itemname, qty)
	local inv_list = get_inventory_list (pos)
	local items, recipe = get_craft_items (itemname, inv_list)

	if items and recipe then
		return craft (pos, items, recipe, qty, inv_list)
	end

	return 0
end



local function craft_item_by_recipe (pos, recipe, items, qty)
	local inv_list = get_inventory_list (pos)

	if items and recipe then
		return craft (pos, items, recipe, qty, inv_list)
	end

	return 0
end



local function can_craft_recipe (pos)
	local inv_list = get_inventory_list (pos)
	local items = get_recipe_grid (pos)
	local recipe =
	{
		method = "normal",
		width = 3,
		items = get_recipe_grid (pos)
	}

	return can_craft (pos, items, recipe, inv_list)
end



local function can_craft_item (pos, itemname)
	local inv_list = get_inventory_list (pos)
	local items, recipe = get_craft_items (itemname, inv_list)

	if items and recipe then
		return can_craft (pos, items, recipe, inv_list)
	end

	return false
end



local function preview_craft (pos)
	local items = get_recipe_grid (pos)
	local	recipe =
	{
		method = "normal",
		width = 3,
		items = table.copy (items)
	}
	local item

	local output = minetest.get_craft_result (recipe)

	if output and output.item and not output.item:is_empty () then
		item = output.item
	end

	local meta = minetest.get_meta (pos)

	if meta then
		local inv = meta:get_inventory ()

		if inv then
			inv:set_stack ("preview", 1, item)
		end
	end
end



local function set_recipe_grid (pos, items)
	local meta = minetest.get_meta (pos)

	if meta then
		local inv = meta:get_inventory ()

		if inv then
			if type (items) ~= "table" then
				items = { }
			end

			for i = 1, 9, 1 do
				if items[i] and minetest.registered_items[items[i]] then
					inv:set_stack ("craft", i, ItemStack (items[i]))
				else
					inv:set_stack ("craft", i, nil)
				end
			end

			preview_craft (pos)
		end
	end
end



local function run_automatic (pos, run)
	local timer = minetest.get_node_timer (pos)
	local meta = minetest.get_meta (pos)

	if timer and meta then
		if run then
			if not timer:is_started () then
				timer:start (crafter_interval)

				meta:set_string ("automatic", "true")
			end
		elseif timer:is_started () then
			timer:stop ()

			meta:set_string ("automatic", "false")
		end
	end
end



local function search_filter (name, terms)
	if terms then
		for _, t in ipairs (terms) do
			if (name:lower ():find (t, 1, true)) then
				return true
			end
		end

		return false
	end

	return true
end



local function filter_craftable_list (list, search)
	if search and tostring (search):len () > 1 then
		local terms = { }
		for w in string.gmatch(search, "[^%s]+") do
			terms[#terms + 1] = string.lower (w)
		end

		if #terms > 0 then
			local filtered = { }

			for i = 1, #list, 1 do
				if search_filter (list[i].description or "", terms) or
						search_filter (list[i].name or "", terms) then
					filtered[#filtered + 1] = list[i]
				end
			end

			return filtered
		end
	end

	return list
end



local function get_item_craft (pos, itemname, index)
	if itemname:len () < 1 or index < 1 then
		return nil
	end

	local inv_list = get_inventory_list (pos)
	local names = { }

	names[itemname] = true
	for alias, name in pairs (minetest.registered_aliases) do
		if alias == itemname then
			names[name] = true
		elseif name == itemname then
			names[alias] = true
		end
	end

	local recipes = { }
	local grid = { }
	for name, _ in pairs (names) do
		local r = minetest.get_all_craft_recipes (name)

		if r then
			for i = 1, #r, 1 do
				local items = get_craft_recipe_items (r[i].items, inv_list)

				if items then
					recipes[#recipes + 1] = r[i]
					grid[#grid + 1] = items
				end
			end
		end
	end

	if recipes and recipes[index] then
		return recipes[index], #recipes, grid[index]
	end

	return nil
end



local function get_craft_items_grid (recipe, items)
	local grid = { "", "", "", "", "", "", "", "", "" }

	if recipe.width == 1 then
		for i = 1, 3, 1 do
			grid[((i - 1) * 3) + 2] = items[i] or ""
		end
	elseif recipe.width == 2 then
		for i = 1, 6, 1 do
			grid[(((i - 1) % 2) * 3) + math.floor ((i - 1) / 2) + 1] = items[i] or ""
		end
	else
		for i = 1, 9, 1 do
			grid[i] = items[i] or ""
		end
	end

	return grid
end



local function get_item_button (item, x, y, element_name)
	local name = item or ""

	return string.format ("item_image_button[%f,%f;1.0,1.0;%s;%s;]",
								 x, y, name, element_name)
end



local function get_formspec (pos, search)
	local spec = ""
	local meta = minetest.get_meta (pos)

	if meta then
		local list = filter_craftable_list (get_craftable_list (pos), search)
		local crafts = ""
		local automatic = (meta:get_string ("automatic") == "true" and "true") or "false"
		local lines = math.ceil (#list / 5)
		local scroll_height = ((lines < 11 and 0) or (lines - 10)) * 10
		local thumb_size = (lines < 11 and 10) or (scroll_height * (10 / lines))

		if thumb_size < (scroll_height / 9) then
			thumb_size = scroll_height / 9
		end

		search = search or ""

		for i, item in pairs (list) do
			crafts = crafts..string.format ("item_image_button[%d,%d;1.0,1.0;%s;ITEM_%s;]",
													  ((i - 1) % 5),
													  math.floor ((i - 1) / 5),
													  item.name,
													  item.name)
		end

		local craft_grid
		local craftitem = meta:get_string ("craftitem")
		local recipe_index = meta:get_int ("recipe_index")
		local item_recipe, recipe_count, item_items = get_item_craft (pos, craftitem, recipe_index)

		if item_recipe and item_items then
			local grid = get_craft_items_grid (item_recipe, item_items)
			local prior_button = ((recipe_index > 1) and "button[15.5,3.9;1.0,0.8;prior_craft;<]") or ""
			local next_button = ((recipe_index < recipe_count) and "button[16.5,3.9;1.0,0.8;next_craft;>]") or ""

			craft_grid = string.format ("%s%s%s%s%s%s%s%s%s"..
												 "button[15.5,2.5;2.0,0.8;close_item_craft;Close]"..
												 "%s%s"..
												 "button[15.5,5.3;2.0,0.8;craft_item;Craft]",
												 get_item_button (grid[1], 11.5, 2.5, "guide_1"),
												 get_item_button (grid[2], 12.75, 2.5, "guide_2"),
												 get_item_button (grid[3], 14.0, 2.5, "guide_3"),
												 get_item_button (grid[4], 11.5, 3.75, "guide_4"),
												 get_item_button (grid[5], 12.75, 3.75, "guide_5"),
												 get_item_button (grid[6], 14.0, 3.75, "guide_6"),
												 get_item_button (grid[7], 11.5, 5.0, "guide_7"),
												 get_item_button (grid[8], 12.75, 5.0, "guide_8"),
												 get_item_button (grid[9], 14.0, 5.0, "guide_9"),
												 prior_button,
												 next_button)
		else
			craft_grid = string.format ("list[context;craft;11.5,2.5;3,3;]"..
												 "checkbox[15.5,2.7;automatic;Automatic;%s]"..
												 "button[15.5,5.3;2.0,0.8;craft;Craft]"..
												 "list[context;preview;16.0,3.75;1,1;]",
												 automatic)
		end


		spec = string.format ("formspec_version[3]"..
									 "size[24.7,13.0,false]"..
									 "set_focus[search_field;true]"..
									 "label[1.0,1.0;Input]"..
									 "list[context;main;1.0,1.25;8,4;]"..
									 "listring[current_player;main]"..
									 "list[current_player;main;1.0,7.2;8,4;]"..
									 "listring[context;main]"..
									 "field[11.5,1.21;3.0,0.8;channel;Channel;${channel}]"..
									 "field_close_on_enter[channel;false]"..
									 "button[14.5,1.21;1.5,0.8;setchannel;Set]"..
									 "%s"..
									 "label[11.5,6.95;Output]"..
									 "list[context;output;11.5,7.2;5,4;]"..
									 "listring[current_player;main]"..
									 "field[16.5,1.21;5.2,0.8;search_field;;%s]"..
									 "field_close_on_enter[search_field;false]"..
									 "button[21.7,1.21;2.0,0.8;search;Search]"..
									 "scrollbaroptions[min=0;max=%d;smallstep=10;largestep=100;thumbsize=%d;arrows=default]"..
									 "scrollbar[23.2,2.0;0.5,10.0;vertical;crafter_scrollbar;0-%d]"..
									 "scroll_container[18.2,2.0;5.0,10.0;crafter_scrollbar;vertical;0.1]"..
									 "%s"..
									 "scroll_container_end[]",
									 craft_grid,
									 search,
									 scroll_height,
									 thumb_size,
									 scroll_height,
									 crafts)
	end

	return spec
end



local function after_place_node (pos, placer, itemstack, pointed_thing)
	local meta = minetest.get_meta (pos)

	meta:set_string ("inventory", "{ main = { }, output = { }, craft = { }, preview = { } }")
	meta:set_string ("automatic", "false")

	local inv = meta:get_inventory ()

	inv:set_size ("main", 32)
	inv:set_width ("main", 8)
	inv:set_size ("output", 20)
	inv:set_width ("output", 5)
	inv:set_size ("craft", 9)
	inv:set_width ("craft", 3)
	inv:set_size ("preview", 1)
	inv:set_width ("preview", 1)

	meta:set_string ("formspec", get_formspec (pos))

	-- If return true no item is taken from itemstack
	return false
end



local function after_place_node_locked (pos, placer, itemstack, pointed_thing)
	after_place_node (pos, placer, itemstack, pointed_thing)

	if placer and placer:is_player () then
		local meta = minetest.get_meta (pos)

		meta:set_string ("owner", placer:get_player_name ())
		meta:set_string ("infotext", "Crafter (owned by "..placer:get_player_name ()..")")
	end

	-- If return true no item is taken from itemstack
	return false
end



local function can_dig (pos, player)
	if not utils.can_interact_with_node (pos, player) then
		return false
	end

	local meta = minetest.get_meta (pos)

	if meta then
		local inv = meta:get_inventory ()

		if inv then
			if not inv:is_empty ("main") or not inv:is_empty ("output") then
				return false
			end
		end
	end

	return true
end



local function on_blast (pos, intensity)
	local meta = minetest.get_meta (pos)

	if meta then
		if intensity >= 1.0 then
			local inv = meta:get_inventory ()

			if inv then
				local slots = inv:get_size ("main")

				for slot = 1, slots do
					local stack = inv:get_stack ("main", slot)

					if stack and not stack:is_empty () then
						if math.floor (math.random (0, 5)) == 3 then
							utils.item_drop (stack, nil, pos)
						else
							utils.on_destroy (stack)
						end
					end
				end

				slots = inv:get_size ("output")

				for slot = 1, slots do
					local stack = inv:get_stack ("output", slot)

					if stack and not stack:is_empty () then
						if math.floor (math.random (0, 5)) == 3 then
							utils.item_drop (stack, nil, pos)
						else
							utils.on_destroy (stack)
						end
					end
				end
			end

			minetest.remove_node (pos)

		else -- intensity < 1.0
			local inv = meta:get_inventory ()

			if inv then
				local slots = inv:get_size ("main")

				for slot = 1, slots do
					local stack = inv:get_stack ("main", slot)

					if stack and not stack:is_empty () then
						utils.item_drop (stack, nil, pos)
					end
				end

				slots = inv:get_size ("output")

				for slot = 1, slots do
					local stack = inv:get_stack ("output", slot)

					if stack and not stack:is_empty () then
						utils.item_drop (stack, nil, pos)
					end
				end
			end

			local node = minetest.get_node_or_nil (pos)
			if node then
				local items = minetest.get_node_drops (node, nil)

				if items and #items > 0 then
					local stack = ItemStack (items[1])

					if stack then
						utils.item_drop (stack, nil, pos)
						minetest.remove_node (pos)
					end
				end
			end
		end
	end
end



local function on_rightclick (pos, node, clicker, itemstack, pointed_thing)
	if not utils.can_interact_with_node (pos, clicker) then
		if clicker and clicker:is_player () then
			local owner = "<unknown>"
			local meta = minetest.get_meta (pos)

			if meta then
				owner = meta:get_string ("owner")
			end

			local spec =
			"formspec_version[3]"..
			"size[8.0,4.0,false]"..
			"label[1.0,1.0;Owned by "..minetest.formspec_escape (owner).."]"..
			"button_exit[3.0,2.0;2.0,1.0;close;Close]"

			minetest.show_formspec (clicker:get_player_name (),
											"lwcomponents:component_privately_owned",
											spec)
		end

	else
		local meta = minetest.get_meta (pos)

		if meta then
			meta:set_string ("craftitem", "")
			meta:set_int ("recipe_index", 0)
			meta:set_string ("formspec", get_formspec (pos))
		end
	end

	return itemstack
end



local function on_receive_fields (pos, formname, fields, sender)
	if not utils.can_interact_with_node (pos, sender) then
		return
	end

	if fields.setchannel or (fields.key_enter_field and
									 fields.key_enter_field == "channel") then
		local meta = minetest.get_meta (pos)

		if meta then
			meta:set_string ("channel", fields.channel)
		end

	elseif fields.automatic then
		local meta = minetest.get_meta (pos)

		if meta then
			meta:set_string ("automatic", fields.automatic)

			run_automatic (pos, fields.automatic == "true")
		end

	elseif fields.search or (fields.key_enter_field and
									 fields.key_enter_field == "search_field") then
		local meta = minetest.get_meta (pos)

		if meta then
			meta:set_string ("craftitem", "")
			meta:set_int ("recipe_index", 0)
			meta:set_string ("formspec", get_formspec (pos, fields.search_field))
		end

	elseif fields.craft then
		craft_recipe (pos, 1)

	elseif fields.prior_craft then
		local meta = minetest.get_meta (pos)

		if meta then
			meta:set_int ("recipe_index", meta:get_int ("recipe_index") - 1)
			meta:set_string ("formspec", get_formspec (pos, fields.search_field))
		end

	elseif fields.next_craft then
		local meta = minetest.get_meta (pos)

		if meta then
			meta:set_int ("recipe_index", meta:get_int ("recipe_index") + 1)
			meta:set_string ("formspec", get_formspec (pos, fields.search_field))
		end

	elseif fields.close_item_craft then
		local meta = minetest.get_meta (pos)

		if meta then
			meta:set_string ("craftitem", "")
			meta:set_int ("recipe_index", 0)
			meta:set_string ("formspec", get_formspec (pos, fields.search_field))
		end

	elseif fields.craft_item then
		local meta = minetest.get_meta (pos)

		if meta then
			local itemname = meta:get_string ("craftitem")
			local index = meta:get_int ("recipe_index")

			if itemname:len () > 0 then
				local recipe, _, items = get_item_craft (pos, itemname, index)

				if recipe then
					craft_item_by_recipe (pos, recipe, items, 1)
				end
			end
		end

	else
		for k, v in pairs (fields) do
			if k:sub (1, 5) == "ITEM_" then
				local itemname = k:sub (6, -1)
				local _, count = get_item_craft (pos, itemname, 1)

				if count and count > 1 then
					local meta = minetest.get_meta (pos)

					if meta then
						meta:set_string ("craftitem", itemname)
						meta:set_int ("recipe_index", 1)
						meta:set_string ("formspec", get_formspec (pos, fields.search_field))
					end
				elseif count == 1 then
					craft_item (pos, itemname, 1)

					local meta = minetest.get_meta (pos)

					if meta and meta:get_string ("craftitem"): len () > 0 then
						meta:set_string ("craftitem", "")
						meta:set_int ("recipe_index", 0)
						meta:set_string ("formspec", get_formspec (pos, fields.search_field))
					end
				end

				break
			end
		end
	end
end



local function allow_metadata_inventory_take (pos, listname, index, stack, player)
	if listname == "preview" then
		return 0
	end

	if listname == "craft" then
		local meta = minetest.get_meta (pos)

		if meta then
			local inv = meta:get_inventory ()

			if inv then
				inv:set_stack ("craft", index, nil)

				preview_craft (pos)
			end
		end

		return 0
	end

	return stack:get_stack_max ()
end



local function allow_metadata_inventory_put (pos, listname, index, stack, player)
	if listname == "preview" then
		return 0
	end

	if listname == "craft" then
		local copy = ItemStack (stack)

		if copy and not copy:is_empty () then
			copy:set_count (1)

			local meta = minetest.get_meta (pos)

			if meta then
				local inv = meta:get_inventory ()

				if inv then
					inv:set_stack ("craft", index, copy)

					preview_craft (pos)
				end
			end
		end

		return 0
	end

	return stack:get_stack_max ()
end



local function allow_metadata_inventory_move (pos, from_list, from_index,
															 to_list, to_index, count, player)
	if from_list == "preview" or to_list == "preview" then
		return 0
	end

	local meta = minetest.get_meta (pos)

	if meta then
		local inv = meta:get_inventory ()

		if inv then
			if from_list == "craft" then
				if to_list == "craft" then
					return 1
				end

				inv:set_stack ("craft", from_index, nil)

				preview_craft (pos)

				return 0

			elseif to_list == "craft" then
				local stack = inv:get_stack (from_list, from_index)

				if stack and not stack:is_empty () then
					inv:set_stack ("craft", to_index, ItemStack (stack:get_name ()))

					preview_craft (pos)
				end

				return 0

			else
				local stack = inv:get_stack (from_list, from_index)

				if stack and not stack:is_empty () then
					return stack:get_stack_max ()
				end
			end
		end
	end

	return utils.settings.default_stack_max
end



local function on_metadata_inventory_take (pos, listname, index, stack, player)
	if listname == "craft" then
		preview_craft (pos)
	end
end



local function on_metadata_inventory_put (pos, listname, index, stack, player)
	if listname == "craft" then
		preview_craft (pos)
	end
end



local function on_metadata_inventory_move (pos, from_list, from_index,
														 to_list, to_index, count, player)
	if from_list == "preview" or to_list == "preview" then
		return
	end

	if from_list == "craft" or to_list == "craft" then
		preview_craft (pos)
	end

	local meta = minetest.get_meta (pos)

	if meta then
		local inv = meta:get_inventory ()

		if inv then
			if from_list == "craft" then
				if to_list ~= "craft" then
					inv:set_stack ("craft", from_index, nil)

					preview_craft (pos)
				end

			elseif to_list == "craft" then
				local stack = inv:get_stack (from_list, from_index)

				if stack and not stack:is_empty () then
					inv:set_stack ("craft", to_index, ItemStack (stack:get_name ()))

					preview_craft (pos)
				end
			end
		end
	end
end



local function on_timer (pos, elapsed)
	craft_recipe (pos, 1)

	return true
end



local function mesecon_support ()
	if utils.mesecon_supported then
		return
		{
			effector =
			{
				rules = utils.mesecon_flat_rules,

				action_on = function (pos, node)
					craft_recipe (pos, 1)
				end
			}
		}
	end

	return nil
end



local function send_stock_message (pos)
	if utils.digilines_supported then
		local meta = minetest.get_meta (pos)

		if meta then
			local channel = meta:get_string ("channel")

			if channel:len () > 0 then
				local msg =
				{
					action = "inventory",
					inventory = get_stock_list (pos)
				}

				utils.digilines_receptor_send (pos,
														 utils.digilines_default_rules,
														 channel,
														 msg)
			end
		end
	end
end



local function send_craftable_message (pos)
	if utils.digilines_supported then
		local meta = minetest.get_meta (pos)

		if meta then
			local channel = meta:get_string ("channel")

			if channel:len () > 0 then
				local msg =
				{
					action = "craftable",
					items = get_craftable_list (pos)
				}

				utils.digilines_receptor_send (pos,
														 utils.digilines_default_rules,
														 channel,
														 msg)
			end
		end
	end
end



local function send_craft_result_message (pos, itemname, qty, crafted)
	if utils.digilines_supported then
		local meta = minetest.get_meta (pos)

		if meta then
			local channel = meta:get_string ("channel")

			if channel:len () > 0 then
				local msg =
				{
					action = "crafted",
					itemname = itemname,
					qty = qty,
					crafted = crafted
				}

				utils.digilines_receptor_send (pos,
														 utils.digilines_default_rules,
														 channel,
														 msg)
			end
		end
	end
end



local function send_can_craft_message (pos, itemname, result)
	if utils.digilines_supported then
		local meta = minetest.get_meta (pos)

		if meta then
			local channel = meta:get_string ("channel")

			if channel:len () > 0 then
				local msg =
				{
					action = "can_craft",
					itemname = itemname,
					result = result
				}

				utils.digilines_receptor_send (pos,
														 utils.digilines_default_rules,
														 channel,
														 msg)
			end
		end
	end
end



local function digilines_support ()
	if utils.digilines_supported then
		return
		{
			wire =
			{
				rules = utils.digilines_default_rules,
			},

			effector =
			{
				action = function (pos, node, channel, msg)
					local meta = minetest.get_meta(pos)

					if meta then
						local this_channel = meta:get_string ("channel")

						if this_channel ~= "" then
							if type (msg) == "string" then
								local m = { }
								for w in string.gmatch(msg, "[^%s]+") do
									m[#m + 1] = w
								end

								if this_channel == channel then
									if m[1] == "craft" then
										local qty = 1

										if m[2] and tonumber (m[2]) then
											qty = math.floor (math.max (math.min (tonumber (m[2]), 10), 1))
										end

										send_craft_result_message (pos, nil, qty, craft_recipe (pos, qty))

									elseif m[1] == "craftitem" then
										local qty = 1

										if m[3] and tonumber (m[3]) then
											qty = math.floor (math.max (math.min (tonumber (m[3]), 10), 1))
										end

										if m[2] and minetest.registered_items[m[2]] then
											send_craft_result_message (pos, m[2], qty, craft_item (pos, m[2], qty))
										else
											send_craft_result_message (pos, m[2] or "", qty, 0)
										end

									elseif m[1] == "can_craft" then
										if m[2] and not minetest.registered_items[m[2]] then
											send_can_craft_message (pos, m[2], false)
										elseif m[2] then
											send_can_craft_message (pos, m[2], can_craft_item (pos, m[2]))
										else
											send_can_craft_message (pos, nil, can_craft_recipe (pos))
										end

									elseif m[1] == "automatic" then
										run_automatic (pos, tostring (m[2]) == "true")

									elseif m[1] == "craftable" then
										send_craftable_message (pos)

									elseif m[1] == "inventory" then
										send_stock_message (pos)

									end
								end

							elseif type (msg) == "table" then
								if this_channel == channel then
									if msg.action and tostring (msg.action) == "recipe" then

										set_recipe_grid (pos, msg.items)
									end
								end

							end
						end
					end
				end,
			}
		}
	end

	return nil
end



local function pipeworks_support ()
	if utils.pipeworks_supported then
		return
		{
			priority = 100,
			input_inventory = "output",
			connect_sides = { left = 1, right = 1, front = 1, back = 1, bottom = 1, top = 1 },

			insert_object = function (pos, node, stack, direction)
				local meta = minetest.get_meta (pos)
				local inv = (meta and meta:get_inventory ()) or nil

				if inv then
					return inv:add_item ("main", stack)
				end

				return stack
			end,

			can_insert = function (pos, node, stack, direction)
				local meta = minetest.get_meta (pos)
				local inv = (meta and meta:get_inventory ()) or nil

				if inv then
					return inv:room_for_item ("main", stack)
				end

				return false
			end,

			can_remove = function (pos, node, stack, dir)
				-- returns the maximum number of items of that stack that can be removed
				local meta = minetest.get_meta (pos)
				local inv = (meta and meta:get_inventory ()) or nil

				if inv then
					local slots = inv:get_size ("output")

					for i = 1, slots, 1 do
						local s = inv:get_stack ("output", i)

						if s and not s:is_empty () and utils.is_same_item (stack, s) then
							return s:get_count ()
						end
					end
				end

				return 0
			end,

			remove_items = function (pos, node, stack, dir, count)
				-- removes count items and returns them
				local meta = minetest.get_meta (pos)
				local inv = (meta and meta:get_inventory ()) or nil
				local left = count

				if inv then
					local slots = inv:get_size ("output")

					for i = 1, slots, 1 do
						local s = inv:get_stack ("output", i)

						if s and not s:is_empty () and utils.is_same_item (s, stack) then
							if s:get_count () > left then
								s:set_count (s:get_count () - left)
								inv:set_stack ("output", i, s)
								left = 0
							else
								left = left - s:get_count ()
								inv:set_stack ("output", i, nil)
							end
						end

						if left == 0 then
							break
						end
					end
				end

				local result = ItemStack (stack)
				result:set_count (count - left)

				return result
			end
		}
	end

	return nil
end



local crafter_groups = { choppy = 2 }
if utils.pipeworks_supported then
	crafter_groups.tubedevice = 1
	crafter_groups.tubedevice_receiver = 1
end



minetest.register_node("lwcomponents:crafter", {
	description = S("Crafter"),
	drawtype = "normal",
	tiles = { "lwcomponents_storage_framed.png", "lwcomponents_storage_framed.png",
				 "lwcomponents_storage_crafter.png", "lwcomponents_storage_crafter.png",
				 "lwcomponents_storage_crafter.png", "lwcomponents_storage_crafter.png" },
	is_ground_content = false,
	groups = table.copy (crafter_groups),
	sounds = default.node_sound_wood_defaults (),
	paramtype = "none",
	param1 = 0,
	paramtype2 = "none",
	param2 = 0,
	floodable = false,
	_digistuff_channelcopier_fieldname = "channel",

	mesecons = mesecon_support (),
	digiline = digilines_support (),
	tube = pipeworks_support (),

	after_place_node = after_place_node,
	can_dig = can_dig,
	on_blast = on_blast,
	on_rightclick = on_rightclick,
	on_receive_fields = on_receive_fields,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	on_metadata_inventory_take = on_metadata_inventory_take,
	on_metadata_inventory_put = on_metadata_inventory_put,
	on_metadata_inventory_move = on_metadata_inventory_move,
	on_timer = on_timer
})



minetest.register_node("lwcomponents:crafter_locked", {
	description = S("Crafter (locked)"),
	drawtype = "normal",
	tiles = { "lwcomponents_storage_framed.png", "lwcomponents_storage_framed.png",
				 "lwcomponents_storage_crafter.png", "lwcomponents_storage_crafter.png",
				 "lwcomponents_storage_crafter.png", "lwcomponents_storage_crafter.png" },
	is_ground_content = false,
	groups = table.copy (crafter_groups),
	sounds = default.node_sound_wood_defaults (),
	paramtype = "none",
	param1 = 0,
	paramtype2 = "none",
	param2 = 0,
	floodable = false,
	_digistuff_channelcopier_fieldname = "channel",

	mesecons = mesecon_support (),
	digiline = digilines_support (),
	tube = pipeworks_support (),

	after_place_node = after_place_node_locked,
	can_dig = can_dig,
	on_blast = on_blast,
	on_rightclick = on_rightclick,
	on_receive_fields = on_receive_fields,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	on_metadata_inventory_take = on_metadata_inventory_take,
	on_metadata_inventory_put = on_metadata_inventory_put,
	on_metadata_inventory_move = on_metadata_inventory_move,
	on_timer = on_timer
})



utils.hopper_add_container({
	{"top", "lwcomponents:crafter", "output"}, -- take items from above into hopper below
	{"bottom", "lwcomponents:crafter", "main"}, -- insert items below from hopper above
	{"side", "lwcomponents:crafter", "main"}, -- insert items from hopper at side
})



utils.hopper_add_container({
	{"top", "lwcomponents:crafter_locked", "output"}, -- take items from above into hopper below
	{"bottom", "lwcomponents:crafter_locked", "main"}, -- insert items below from hopper above
	{"side", "lwcomponents:crafter_locked", "main"}, -- insert items from hopper at side
})



--
