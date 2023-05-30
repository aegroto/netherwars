local function fixmax(def)
	if def.stack_max == 99 then def.stack_max = 1000 end
end

fixmax(minetest.nodedef_default)
fixmax(minetest.craftitemdef_default)
fixmax(minetest.tooldef_default)
fixmax(minetest.noneitemdef_default)

for k,v in pairs(minetest.registered_items) do
	if v.mod_origin~="*builtin*" then
		minetest.override_item(k,{})
	end
end
